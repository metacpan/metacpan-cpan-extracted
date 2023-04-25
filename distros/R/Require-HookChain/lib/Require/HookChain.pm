## no critic: TestingAndDebugging::RequireUseStrict
package Require::HookChain;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-08'; # DATE
our $DIST = 'Require-HookChain'; # DIST
our $VERSION = '0.008'; # VERSION

#IFUNBUILT
# use strict;
# use warnings;
# use Scalar::Util qw(blessed);
#END IFUNBUILT

# be minimalistic, to avoid loading any module
#IFBUILT
unless (defined &blessed) {
    *blessed = sub { my $arg = shift; my $ref = ref $arg; $ref && $ref !~ /\A(SCALAR|ARRAY|HASH|GLOB|Regexp)\z/ };
}
#END IFBUILT

my $our_hook; $our_hook = sub {
    my ($self, $filename) = @_;

    my $r = Require::HookChain::r->new(filename => $filename);
    # find source code first
    for my $item (@INC) {
        next if ref $item;
        my $path = "$item/$filename";
        if (-f $path) {
            open my $fh, "<", $path
                or die "Can't open $path: $!";
            local $/;
            $r->src(scalar <$fh>);
            last;
        }
    }

    my $after_us;
    for my $item (@INC) {
        if (!$after_us) {
            # start searching after ourself
            if (ref($item) && $item == $our_hook) {
                $after_us++;
                next;
            }
        } else {
            if (blessed($item) && ref($item) =~ /\ARequire::HookChain::/) {
                $item->INC($r);
            }
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

    # install our own hook
    unless (@INC && blessed($INC[0]) && $INC[0] == $our_hook) {
        @INC = ($our_hook, grep { !(blessed($_) && $_ == $our_hook) } @INC);
    }

    # get options first
    my $end;
    while (@_) {
        my $el = shift @_;
        if ($el eq '-end') {
            $end = shift @_;
            next;
        } else {
            my $pkg = "Require::HookChain::$el";
            (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
            require $pkg_pm;
            my $c_hook = $pkg->new(@_);
            if ($end) {
                push @INC, $c_hook;
            } else {
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
# ABSTRACT: Chainable require hook

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::HookChain - Chainable require hook

=head1 VERSION

This document describes version 0.008 of Require::HookChain (from Perl distribution Require-HookChain), released on 2023-02-08.

=head1 SYNOPSIS

Say you want to create a require hook to prepend some code to the module source
code that is loaded. In your hook source, in
F<Require/HookChain/munge/prepend.pm>:

 package Require::HookChain::munge::prepend;

 sub new {
     my ($class, $preamble) = @_;
     bless { preamble => $preamble }, $class;
 }

 sub Require::HookChain::munge::prepend::INC {
     my ($self, $r) = @_;

     # safety, in case we are not called by Require::HookChain
     return () unless ref $r;

     my $src = $r->src;
     return unless defined $src;
     $src = "$self->{preamble};\n$src";
     $r->src($src);
 }

 1;

In a code to use this hook:

 use Require::HookChain 'munge::prepend' => 'use strict';
 use Foo::Bar; # Foo/Bar.pm will be loaded with added 'use strict;' at the start

Install another hook, but put it at the end of C<@INC> instead of at the
beginning:

 use Require::HookChain -end => 1, append => 'some code';

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

 use Require::HookChain::hookname; # INCORRECT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 SEE ALSO

L<RHC> for convenience of using on the command-line or one-liners.

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
