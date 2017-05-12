package Regexp::Pattern;

our $DATE = '2016-12-31'; # DATE
our $VERSION = '0.1.4'; # VERSION

use strict 'subs', 'vars';
#use warnings;

use Exporter qw(import);
our @EXPORT = qw(re);

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

1;
# ABSTRACT: Collection of regexp patterns

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern - Collection of regexp patterns

=head1 SPECIFICATION VERSION

0.1.0

=head1 VERSION

This document describes version 0.1.4 of Regexp::Pattern (from Perl distribution Regexp-Pattern), released on 2016-12-31.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()

 my $re = re('YouTube::video_id');
 say "ID does not look like a YouTube video ID" unless $id =~ /\A$re\z/;

 # a dynamic pattern (generated on-demand) with generator arguments
 my $re2 = re('Example::re3', {variant=>"B"});

=head1 DESCRIPTION

Regexp::Pattern is a convention for organizing reusable regexp patterns in
modules.

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
     },
 );

A Regexp::Pattern::* module must declare a package global hash variable named
C<%RE>. Hash keys are pattern names, hash values are defhashes (see L<DefHash>).
At the minimum, it should be:

 { pat => qr/.../ },

Regexp pattern should be written as C<qr//> literal, or (less desirable) as a
string literal. Regexp should not be anchored (C<qr/^...$/>) unless necessary.
Regexp should not contain capture groups unless necessary.

=head2 Using a Regexp::Pattern::* module

A C<Regexp::Pattern::*> module can be used manually by itself, as it contains
simply data that can be grabbed using a normal means, e.g.:

 use Regexp::Pattern::Example;

 say "Input does not match blah"
     unless $input =~ /\A$Regexp::Pattern::Example::RE{re1}{pat}\z/;

C<Regexp::Pattern> (this module) also provides C<re()> function to help retrieve
the regexp pattern.

=head1 FUNCTIONS

=head2 re

Exported by default. Get a regexp pattern by name from a C<Regexp::Pattern::*>
module.

Syntax:

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
provided C<re()> function.

L<Regexp::Common::RegexpPattern>, a bridge module to use patterns in
C<Regexp::Pattern::*> modules via Regexp::Common.

L<Regexp::Pattern::RegexpCommon>, a bridge module to use patterns in
C<Regexp::Common::*> modules via Regexp::Pattern.

L<App::RegexpPatternUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
