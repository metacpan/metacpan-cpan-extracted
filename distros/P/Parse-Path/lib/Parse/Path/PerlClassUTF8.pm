package Parse::Path::PerlClassUTF8;

our $VERSION = '0.92'; # VERSION
# ABSTRACT: Perl::Class::path::support'with'ŮΤᖴ８

#############################################################################
# Modules

use v5.14;

use Moo;
use sanity;

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Required Methods

with 'Parse::Path::Role::Path';

sub _build_blueprint { {
   hash_step_regexp => qr{
      # See http://www.learning-perl.com/2011/07/matching-perl-identifiers-is-a-lot-harder-now/
      (?<key>\p{XID_Start}\p{XID_Continue}*)
   }x,

   array_step_regexp   => qr/\Z.\A/,  # no-op; arrays not supported
   delimiter_regexp    => qr{(?:\:\:|')(?=\p{XID_Start})},  # no dangling delimiters

   # no support for escapes
   unescape_translation => [],

   pos_translation => [
      [qr/.?/, 'X+1'],
   ],

   delimiter_placement => {
      HH => '::',
   },

   array_key_sprintf        => '',
   hash_key_stringification => [
      [qr/.?/, '%s'],
   ],
} }

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Parse::Path::PerlClassUTF8 - Perl::Class::path::support'with'ŮΤᖴ８

=head1 SYNOPSIS

    use v5.14;
    use utf8;
    use Parse::Path;
 
    my $path = Parse::Path->new(
       path  => 'Parse::Path',
       style => 'PerlClassUTF8',
    );
 
    say $path->as_string;
    $path->push($path, qw[ ʻNIGHTMäREʼ::ʺ'ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ ]);
    say $path->as_string;

=head1 DESCRIPTION

This is a path style for Perl classes with full UTF8 support.  Perl 5.14 is required to use this style, as this uses
L<special UTF8 character classes|http://www.learning-perl.com/2011/07/matching-perl-identifiers-is-a-lot-harder-now/>.  Some examples:

    Perl::Class
    overload::pragma
    K2P'Foo'Bar'Baz
    K2P'Class::Fun

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
