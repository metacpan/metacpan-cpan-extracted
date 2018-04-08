package Regexp::Pattern;

our $DATE = '2018-04-03'; # DATE
our $VERSION = '0.2.3'; # VERSION

use strict 'subs', 'vars';
#use warnings;

sub re {
    my $name = shift;

    my ($mod, $patname) = $name =~ /(.+)::(.+)/
        or die "Invalid pattern name '$name', should be 'MODNAME::PATNAME'";

    $mod = "Regexp::Pattern::$mod";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    my $var = \%{"$mod\::RE"};

    exists($var->{$patname})
        or die "No regexp pattern named '$patname' in package '$mod'";

    if ($var->{$patname}{pat}) {
        return $var->{$patname}{pat};
    } elsif ($var->{$patname}{gen}) {
        return $var->{$patname}{gen}->(ref($_[0]) eq 'HASH' ? %{$_[0]} : @_);
    } else {
        die "Bug in module '$mod': pattern '$patname': no pat/gen declared";
    }
}

sub import {
    my $package = shift;

    my $caller = caller();

    my @args = @_;
    @args = ('re') unless @args;

    while (@args) {
        my $arg = shift @args;
        my ($mod, $name0, $as, $prefix, $suffix,
            $has_tag, $lacks_tag, $gen_args);
        if ($arg eq 're') {
            *{"$caller\::re"} = \&re;
            next;
        } elsif ($arg =~ /\A(\w+(?:::\w+)*)::(\w+|\*)\z/) {
            ($mod, $name0) = ($1, $2);
            ($as, $prefix, $suffix, $has_tag, $lacks_tag) =
                (undef, undef, undef, undef, undef);
            $gen_args = {};
            while (@args >= 2 && $args[0] =~ /\A-?\w+\z/) {
                my ($k, $v) = splice @args, 0, 2;
                if ($k eq '-as') {
                    die "Cannot use -as on a wildcard import '$arg'"
                        if $name0 eq '*';
                    die "Please use a simple identifier for value of -as"
                        unless $v =~ /\A\w+\z/;
                    $as = $v;
                } elsif ($k eq '-prefix') {
                    $prefix = $v;
                } elsif ($k eq '-suffix') {
                    $suffix = $v;
                } elsif ($k eq '-has_tag') {
                    $has_tag = $v;
                } elsif ($k eq '-lacks_tag') {
                    $lacks_tag = $v;
                } elsif ($k !~ /\A-/) {
                    $gen_args->{$k} = $v;
                } else {
                    die "Unknown import option '$k'";
                }
            }
        } else {
            die "Invalid import '$arg', either specify 're' or a qualified ".
                "pattern name e.g. 'Foo::bar', which can be followed by ".
                "name-value pairs";
        }

        *{"$caller\::RE"} = \%{"$caller\::RE"};

        my @names;
        if ($name0 eq '*') {
            my $mod = "Regexp::Pattern::$mod";
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            my $var = \%{"$mod\::RE"};
            for my $n (sort keys %$var) {
                my $tags = $var->{$n}{tags} || [];
                if (defined $has_tag) {
                    next unless grep { $_ eq $has_tag } @$tags;
                }
                if (defined $lacks_tag) {
                    next if grep { $_ eq $lacks_tag } @$tags;
                }
                push @names, $n;
            }
            unless (@names) {
                warn "No patterns imported in wildcard import '$mod\::*'";
            }
        } else {
            @names = ($name0);
        }
        for my $n (@names) {
            my $name = defined($as) ? $as :
                (defined $prefix ? $prefix : "") . $n .
                (defined $suffix ? $suffix : "");
            if (exists ${"$caller\::RE"}{$name}) {
                warn "Overwriting pattern '$name' by importing '$mod\::$n'";
            }
            ${"$caller\::RE"}{$name} = re("$mod\::$n", $gen_args);
        }
    }
}

1;
# ABSTRACT: Convention/framework for modules that contain collection of regexes

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern - Convention/framework for modules that contain collection of regexes

=head1 SPECIFICATION VERSION

0.2.0

=head1 VERSION

This document describes version 0.2.3 of Regexp::Pattern (from Perl distribution Regexp-Pattern), released on 2018-04-03.

=head1 SYNOPSIS

Subroutine interface:

 use Regexp::Pattern; # exports re()

 my $re = re('YouTube::video_id');
 say "ID does not look like a YouTube video ID" unless $id =~ /\A$re\z/;

 # a dynamic pattern (generated on-demand) with generator arguments
 my $re2 = re('Example::re3', {variant=>"B"});

Hash interface (a la L<Regexp::Common> but simpler with regular/non-magical hash
that is only 1-level deep):

 use Regexp::Pattern 'YouTube::video_id';
 say "ID does not look like a YouTube video ID"
     unless $id =~ /\A$RE{video_id}\z/;

 # more complex example

 use Regexp::Pattern (
     're',                                # we still want the re() function
     'Foo::bar' => (-as => 'qux'),        # the pattern will be in your $RE{qux}
     'YouTube::*',                        # wildcard import
     'Example::re3' => (variant => 'B'),  # supply generator arguments
     'JSON::*' => (-prefix => 'json_'),   # add prefix
     'License::*' => (
       -has_tag    => 'family:cc',        # select by tag
       -lacks_tag  => 'type:unversioned', #   also select by lack of tag
       -suffix     => '_license',         #   also add suffix
     ),
 );

=head1 DESCRIPTION

Regexp::Pattern is a convention for organizing reusable regexp patterns in
modules, as well as framework to provide convenience in using those patterns in
your program.

=head2 Structure of an example Regexp::Pattern::* module

 package Regexp::Pattern::Example;

 
 our %RE = (
     # the minimum spec
     re1 => { pat => qr/\d{3}-\d{4}/ },
 
     # more complete spec
     re2 => {
         summary => 'This is regexp for blah',
         description => <<'_',
 
 A longer description.
 
 _
         pat => qr/.../,
         tags => ['A','B'],
     },
 
     # dynamic (regexp generator)
     re3 => {
         summary => 'This is a regexp for blah blah',
         description => <<'_',
 
 ...
 
 _
         gen => sub {
             my %args = @_;
             my $variant = $args{variant} || 'A';
             if ($variant eq 'A') {
                 return qr/\d{3}-\d{3}/;
             } else { # B
                 return qr/\d{3}-\d{2}-\d{5}/;
             }
         },
         gen_args => {
             variant => {
                 summary => 'Choose variant',
                 schema => ['str*', in=>['A','B']],
                 default => 'A',
                 req => 1,
             },
         },
         tags => ['B','C'],
     },
 );

A Regexp::Pattern::* module must declare a package global hash variable named
C<%RE>. Hash keys are pattern names, hash values are pattern definitions in the
form of defhashes (see L<DefHash>).

Pattern name should be a simple identifier that matches this regexp: C<<
/\A[A-Za-z_][A-Za-z_0-9]*\z/ >>. The definition for the qualified pattern name
C<Foo::Bar::baz> can then be located in C<%Regexp::Pattern::Foo::Bar::RE> under
the hash key C<baz>.

Pattern definition hash should at the minimum be:

 { pat => qr/.../ }

You can add more stuffs from the defhash specification, e.g. summary,
description, tags, and so on, for example (taken from L<Regexp::Pattern::CPAN>):

 {
     summary     => 'PAUSE author ID, or PAUSE ID for short',
     pat         => qr/[A-Z][A-Z0-9]{1,8}/,
     description => <<~HERE,
     I'm not sure whether PAUSE allows digit for the first letter. For safety
     I'm assuming no.
     HERE
 }

=head2 Using a Regexp::Pattern::* module

=head3 Standalone

A Regexp::Pattern::* module can be used in a standalone way (i.e. no need to use
via the Regexp::Pattern framework), as it simply contains data that can be
grabbed using a normal means, e.g.:

 use Regexp::Pattern::Example;

 say "Input does not match blah"
     unless $input =~ /\A$Regexp::Pattern::Example::RE{re1}{pat}\z/;

=head3 Via Regexp::Pattern, sub interface

Regexp::Pattern (this module) also provides C<re()> function to help retrieve
the regexp pattern. See L</"re"> for more details.

=head3 Via Regexp::Pattern, hash interface

Additionally, Regexp::Pattern (since v0.2.0) lets you import regexp patterns
into your C<%RE> package hash variable, a la L<Regexp::Common> (but simpler
because the hash is just a regular hash, only 1-level deep, and not magical).

To import, you specify qualified pattern names as the import arguments:

 use Regexp::Pattern 'Q::pat1', 'Q::pat2', ...;

Each qualified pattern name can optionally be followed by a list of name-value
pairs. A pair name can be an option name (which is dash followed by a word, e.g.
C<-as>, C<-prefix>) or a generator argument name for dynamic pattern.

B<Wildcard import.> Instead of a qualified pattern name, you can use
'Module::SubModule::*' wildcard syntax to import all patterns from a pattern
module.

B<Importing into a different name.> You can add the import option C<-as> to
import into a different name, for example:

 use Regexp::Pattern 'YouTube::video_id' => (-as => 'yt_id');

B<Prefix and suffix.> You can also add a prefix and/or suffix to the imported
name:

 use Regexp::Pattern 'Example::*' => (-prefix => 'example_');
 use Regexp::Pattern 'Example::*' => (-suffix => '_sample');

B<Filtering.> When wildcard-importing, you can select the patterns you want
using a combination of these options: C<-has_tag> (only select patterns that
have a specified tag), C<-lacks_tag> (only select patterns that do not have a
specified tag).

=head2 Recommendations for writing the regex patterns

=over

=item * Regexp pattern should be written as a C<qr//> literal

Using a string literal is less desirable. That is:

 pat => qr/foo[abc]+/,

is preferred over:

 pat => 'foo[abc]+',

=item * Regexp pattern should not be anchored (unless really necessary)

That is:

 pat => qr/foo/,

is preferred over:

 pat => qr/^foo/, # or qr/foo$/, or qr/\Afoo\z/

Adding anchors limits the reusability of the pattern. When composing pattern,
user can add anchors herself if needed.

When you define an anchored pattern, adding tag C<anchored> is recommended:

 tags => ['anchored'],

=item * Regexp pattern should not contain capture groups (unless really necessary)

Adding capture groups limits the reusability of the pattern because it can
affect the groups of the composed pattern. When composing pattern, user can add
captures herself if needed.

When you define an anchored pattern, adding tag C<capturing> is recommended:

 tags => ['capturing'],

=back

=head1 FUNCTIONS

=head2 re

Exported by default. Get a regexp pattern by name from a C<Regexp::Pattern::*>
module.

Usage:

 re($name[, \%args ]) => $re

C<$name> is I<MODULE_NAME::PATTERN_NAME> where I<MODULE_NAME> is name of a
C<Regexp::Pattern::*> module without the C<Regexp::Pattern::> prefix and
I<PATTERN_NAME> is a key to the C<%RE> package global hash in the module. A
dynamic pattern can accept arguments for its generator, and you can pass it as
hashref in the second argument of C<re()>.

Die when pattern by name C<$name> cannot be found (either the module cannot be
loaded or the pattern with that name is not found in the module).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Common>. Regexp::Pattern is an alternative to Regexp::Common.
Regexp::Pattern offers simplicity and lower startup overhead. Instead of a magic
hash, you retrieve available regexes from normal data structure or via the
provided C<re()> function. Regexp::Pattern also provides a hash interface,
albeit the hash is not magic.

L<Regexp::Common::RegexpPattern>, a bridge module to use patterns in
C<Regexp::Pattern::*> modules via Regexp::Common.

L<Regexp::Pattern::RegexpCommon>, a bridge module to use patterns in
C<Regexp::Common::*> modules via Regexp::Pattern.

L<App::RegexpPatternUtils>

If you use L<Dist::Zilla>: L<Dist::Zilla::Plugin::Regexp::Pattern>,
L<Pod::Weaver::Plugin::Regexp::Pattern>,
L<Dist::Zilla::Plugin::AddModule::RegexpCommon::FromRegexpPattern>,
L<Dist::Zilla::Plugin::AddModule::RegexpPattern::FromRegexpCommon>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
