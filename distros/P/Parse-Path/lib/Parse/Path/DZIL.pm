package Parse::Path::DZIL;

our $VERSION = '0.92'; # VERSION
# ABSTRACT: "dist.ini-style".paths.for.DZIL[0]

#############################################################################
# Modules

use Moo;
use sanity;

use String::Escape;

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Required Methods

with 'Parse::Path::Role::Path';

sub _build_blueprint { {
   hash_step_regexp => qr/
      # Standard character (or a zero-length with a delimiter)
      (?<key>\w+|(?=\.))|

      # Quoted key
      (?<quote>['"])(?<key> (?:

         # The (?!) is a fancy way of saying ([^\"\\]*) with a variable quote character
         (?>(?: (?! \\|\g{quote}). )*) |  # Most stuff (no backtracking)
         \\ \g{quote}                  |  # Escaped quotes
         \\ (?! \g{quote})                # Any other escaped character

      )* )\g{quote}|

      # Zero-length step (with a single blank key)
      (?<key>^$)
   /x,

   array_step_regexp   => qr/\[(?<key>\d{1,5})\]/,
   delimiter_regexp    => qr/(?:\.|(?=\[))/,

   unescape_translation => [
      [qr/\"/ => \&String::Escape::unbackslash],
      [qr/\'/ => sub { my $str = $_[0]; $str =~ s|\\([\'\\])|$1|g; $str; }],
   ],
   pos_translation => [
      [qr/.?/, 'X+1'],
   ],

   delimiter_placement => {
      HH => '.',
      AH => '.',
   },

   array_key_sprintf        => '[%u]',
   hash_key_stringification => [
      [qr/[\x00-\x1f\']/,
                  '"%s"' => \&String::Escape::backslash],
      [qr/\W|^$/, "'%s'" => sub { my $str = $_[0]; $str =~ s|([\'\\])|\\$1|g; $str; }],
      [qr/.?/,    '%s'],
   ],
} }

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Parse::Path::DZIL - "dist.ini-style".paths.for.DZIL[0]

=head1 SYNOPSIS

    use v5.10;
    use Parse::Path;
 
    my $path = Parse::Path->new(
       path  => 'gophers[0].food.count',
       style => 'DZIL',
    );
 
    say $path->as_string;
    $path->push($path, '[2]');
    say $path->as_string;

=head1 DESCRIPTION

This path style is used for advanced L<Dist::Zilla> INI parsing.  It's the reason why this distribution (and related modules) were
created.

Support is available for both hash and array steps, including quoted hash steps.  Some examples:

    gophers[0].food.type
    "Drink more milk".[3][0][0]."and enjoy it!"
    'foo bar baz'[0]."\"Escaping works, too\""

DZIL paths do not have relativity.  They are all relative.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Parse-Path/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Parse::Path/>.

=head1 AUTHOR

Brendan Byrd <bbyrd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
