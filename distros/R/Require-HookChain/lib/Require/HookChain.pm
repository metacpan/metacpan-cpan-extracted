## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookChain;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-05'; # DATE
our $DIST = 'Require-HookChain'; # DIST
our $VERSION = '0.016'; # VERSION

#IFUNBUILT
# use strict;
# use warnings;
#END IFUNBUILT

# be minimalistic, use our own blessed() so we don't have to load any module (in this case, Scalar::Util)
unless (defined &blessed) {
    *blessed = sub { my $arg = shift; my $ref = ref $arg; $ref && $ref !~ /\A(SCALAR|ARRAY|HASH|GLOB|Regexp)\z/ };
}

our $debug;

my $our_hook; $our_hook = sub {
    my ($self, $filename) = @_;

    warn "[Require::HookChain] require($filename) ...\n" if $debug;

    my $r = Require::HookChain::r->new(filename => $filename);

    for my $item (@INC) {
        my $ref = ref $item;

        if (!$ref) {
            # load from ordinary file
            next if defined $r->src;

            my $path = "$item/$filename";
            if (-f $path) {
                warn "[Require::HookChain] Loading $filename from $path ...\n" if $debug;
                open my $fh, "<", $path
                    or die "Can't open $path: $!";
                local $/;
                $r->src(scalar <$fh>);
                close $fh;
                next;
            }
        } elsif ($ref =~ /\ARequire::HookChain::(.+)/) {
            warn "[Require::HookChain] Calling hook $1 ...\n" if $debug;
            # currently return value is ignored
            $item->INC($r);
        }
    }

    my $src = $r->src;
    if (defined $src) {
        return \$src;
    } else {
        die "Can't locate $filename in \@INC";
    }
};

sub import {
    my $class = shift;

    # get early options first (-debug)
    {
        my $i = -1;
        while ($i < @_) {
            $i++;
            if ($_[$i] eq '-debug') {
                $debug = $_[$i+1];
                $i++;
                next;
            } elsif ($_[$i] =~ /\A-/) {
                $i++;
                next;
            } else {
                last;
            }
        }
    }

    warn "[Require::HookChain] (Re-)installing our own hook at the beginning of \@INC ...\n"
        if $debug;
    unless (@INC && blessed($INC[0]) && $INC[0] == $our_hook) {
        @INC = ($our_hook, grep { !(blessed($_) && $_ == $our_hook) } @INC);
    }

    # get the rest of the options and hook
    my $end;
    while (@_) {
        my $el = shift @_;
        if ($el eq '-end') {
            $end = shift @_;
            next;
        } elsif ($el eq '-debug') {
            # we've processed this
            shift @_;
            next;
        } else {
            my $pkg = "Require::HookChain::$el";
            (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
            warn "[Require::HookChain] Installing hook $el to the ".($end ? "end":"beginning")." of \@INC, args (".join(",", @_).") ...\n"
                if $debug;
            require $pkg_pm;
            my $c_hook = $pkg->new(@_);
            if ($end) {
                push @INC, $c_hook;
            } else {
                # install the hook after uss
                splice @INC, 1, 0, $c_hook;
            }
            last;
        }
    }
}

package Require::HookChain::r;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub filename {
    my $self = shift;
    $self->{filename};
}

sub src {
    my $self = shift;
    if (@_) {
        my $old = $self->{src};
        $self->{src} = shift;
        return $old;
    } else {
        return $self->{src};
    }
}

1;
# ABSTRACT: Chainable require hooks

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::HookChain - Chainable require hooks

=head1 VERSION

This document describes version 0.016 of Require::HookChain (from Perl distribution Require-HookChain), released on 2023-12-05.

=head1 SYNOPSIS

B<NOTE:> Please see L<Require::HookPlugin> instead which will supersede this
project.

Say you want to create a require hook to prepend some code to the module source
code that is loaded. In your hook source, in
F<Require/HookChain/munge/prepend.pm>:

 package Require::HookChain::munge::prepend;

 sub new {

     # our hook accepts one argument: preamble (the string to be prepended)
     my ($class, $preamble) = @_;

     bless { preamble => $preamble }, $class;
 }

 sub Require::HookChain::munge::prepend::INC {

     # instead a filename like a reguler hook, an hook's INC is called by
     # Require::HookChain's main INC and will be passed $r stash
     my ($self, $r) = @_;

     # safety, in case we are not called by Require::HookChain
     return () unless ref $r;

     my $src = $r->src;

     # we only munge source code, when source code has not been loaded by other
     # hooks, we decline.
     return unless defined $src;

     $src = "$self->{preamble};\n$src";
     $r->src($src);
 }

 1;

In a code to use this hook:

 use Require::HookChain -end=>1, 'munge::prepend' => 'use strict';
 use Foo::Bar; # Foo/Bar.pm will be loaded with added 'use strict;' at the start

Install other hooks, but put it at the end of C<@INC> instead of at the
beginning:

 use Require::HookChain -end=>1, 'munge::append' => 'some code';
 use Require::HookChain 'log::stderr'; # log each loading of module to stderr

=head1 DESCRIPTION

This module lets you create chainable require hooks. As one already understands,
Perl lets you put a coderef or object in C<@INC>. In the case of object, its
C<INC> method will be called by Perl:

 package My::INCHandler;
 sub new { ... }
 sub My::INCHandler::INC {
     my ($self, $filename) = @_;
     ...
 }

The method is passed itself then filename (which is what is passed to
C<require()>) and is expected to return nothing or a list of up to four values:
a scalar reference containing source code, filehandle, reference to subroutine,
optional state for subroutine (more information can be read from the L<perlfunc>
manpage). As soon as the first hook in C<@INC> returns non-empty value then the
search for source code is stopped.

With C<Require::HookChain>, you can put multiple hooks in C<@INC> that all get
executed. When C<use>'d, C<Require::HookChain> will install its own hook at the
beginning of C<@INC> which will search for source code in C<@INC> as well as
execute C<INC> method of all the other hooks which are instances of
C<Require::HookChain::*> class. Instead of filename, the method is passed a
C<Require::HookChain::r> object (C<$r>). The method can do things on C<$r>, for
example retrieve source code via C<< $r->src >> or modify source code via C<<
$r->src($new_content) >>. After the method returns, the next
C<Require::HookChain::*> hook is executed, and so on. The final source code will
be retrieved from C<< $r->src >> and returned for Perl.

This lets one chainable hook munge the result of the previous chainable hook.

To create your own chainable require hook, see example in L</"SYNOPSIS">. First
you create a module under the C<Require::HookChain::*> namespace, then create a
constructor as well as C<INC> handler.

=head2 Import options

Options must be specified at the beginning, before specifying

=over

=item * -end

Bool. If set to true, then hooks will be put at the end of C<@INC> instead of at
the beginning (after Require::HookChain's own hook). Regardless,
Require::HookChain's own hook will be put at the beginning to allow executing
all the other hooks.

=item * -debug

Bool. If set to true, then debug messages will be printed to stderr.

=back

=head2 Hook ordering

The order of execution of hooks by Require::HookChain is by their order in
C<@INC>, so you should set the ordering yourself by way of the (reverse)
ordering of C<< use Require::HookChain >> statements. Each time you do this:

 use Require::HookChain 'hook1';

then Require::HookChain will (re)install its own hook to the beginning of
C<@INC>, then insert C<hook1> as the second element in C<@INC>. Then when you
load another hook:

 use Require::HookChain 'hook2';

then Require::HookChain will (re)install its own hook to the beginning of
C<@INC>, then insert C<hook2> as the second element in C<@INC>, while C<hook1>
will be at the third element of C<@INC>. So the order of hook execution will be:
C<< hook2, hook1 >>. When another hook, C<hook3>, is loaded afterwards, the
order of execution will be C<< hook3, hook2, hook1 >>.

Some hooks should be loaded at the end of other hooks (and sources), e.g.
L<debug::dump_source::stderr|Require::HookChain::debug::dump_source::stderr>, so
you should install such hooks using something like:

 use Require::HookChain -end=>1, 'hook4';

in which case Require::HookChain will again (re)install its own hook to the
beginning of C<@INC>, then insert C<hook4> as the last element in C<@INC>. The
order of execution of hooks will then be: C<< hook3, hook2, hook1, hook4 >>. If
you install another hook at the end:

 use Require::HookChain -end=>1, 'hook5';

then the order of execution of hooks will then be: C<< hook3, hook2, hook1,
hook4, hook5 >>.

=head2 Subnamespace organization

=over

=item * Require::HookChain::debug::

Hooks that do debugging-related stuffs. See also: C<log::> subnamespace,
C<timestamp::> subnamespace.

=item * Require::HookChain::log::

Hooks that add logging to module loading process. See also: C<debug::>
subnamespace.

=item * Require::HookChain::munge::

Hooks that modify source code.

=item * Require::HookChain::postcheck::

Hooks that perform checks after the source code is loaded (eval-ed). See also
C<precheck::> subnamespace.

=item * Require::HookChain::precheck::

Hooks that perform checks before the source code is loaded (eval-ed).
See also C<postcheck::> subnamespace.

=item * Require::HookChain::source::

Hooks that allow loading module source from alternative sources.

=item * Require::HookChain::test::

Testing-related, particularly testing the Require::HookCHain hook module itself.

=item * Require::HookChain::timestamp::

Hooks that add timestamps during module loading process.

=back

=for Pod::Coverage ^(blessed)$

=head1 Require::HookChain::r OBJECT

=head2 Methods

=head3 filename

Usage:

 my $filename = $r->filename;

=head3 src

Usage:

 my $src = $r->src;
 $r->src($new_src);

Get or set source code content. Will return undef if source code has not been
found or set.

=head1 FAQ

=head2 Loading a hook does nothing!

Make sure you use a hook this way:

 use Require::HookChain 'hookname'; # correct

instead of:

 use Require::HookChain::hookname; # INCORRECT, this does not install the hook to @INC

=head2 The order of execution of hooks is incorrect!

You control the ordering by putting the hooks in C<@INC> in your preferred
order. See L</"Hook ordering"> for more details.

=head2 What are the differences between Require::HookChain and Require::HookPlugin?

=begin BEGIN_BLOCK:rhc_vs_rhp




=end BEGIN_BLOCK:rhc_vs_rhp

Require::HookChain (RHC) and Require::HookPlugin (RHP) are both frameworks to
add custom behavior to the module loading process. The following are the
comparison between the two:

RHC and RHP both work by installing its own handler (a coderef) at the beginning
of C<@INC>. They then evaluate the rest of C<@INC> like Perl does, with some
differences.

Perl stops at the first C<@INC> element where it finds the source code, while
RHC's handler evaluates all the entries of C<@INC> looking for hooks in the form
of objects of the class under the C<Require::HookChain::> namespace.

RHP's plugins, on the other hand, are not installed directly in C<@INC> but at
another array (C<@Require::HookPlugin::Plugin_Instances>), so the only entry
installed in C<@INC> is RHP's own handler.

RHC evaluates hooks in C<@INC> in order, so you have to install the hooks in the
right order to get the correct behavior. On the other hand, RHP evaluates
plugins based on events, plugins' priority, and activation order. Plugins have a
default priority value (though you can override it). In general you can activate
plugins in whatever order and generally they will do the right thing. RHP is
more flexible and powerful than RHC, but is slightly more complex.

Writing hooks for RHC (or plugins for RHP) are roughly equally easy.

=begin END_BLOCK:rhc_vs_rhp




=end END_BLOCK:rhc_vs_rhp

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 SEE ALSO

L<RHC> for convenience of using on the command-line or one-liners.

L<Require::Hook> (RH) is an older framework and is superseded by
Require::HookChain (RHC).

L<Require::HookPlugin> (RHP) is a newer framework that aims to be more flexible
and comes with sensible default of ordering, to avoid the trap of installing
hooks at the wrong order. RHP might supersede RHC in the future.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2020, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-HookChain>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
