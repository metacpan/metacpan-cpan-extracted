package SolarBeam::Util;
use Mojo::Base -strict;

use Exporter 'import';

our @EXPORT_OK = qw(escape escape_chars unescape_chars);

my $all   = quotemeta('+-&|!(){}[]^~:\\"*?');
my $chars = quotemeta('+-&|!(){}[]^"~*?:\\');
my $wilds = quotemeta('+-&|!(){}[]^~:\\');

sub escape {
  my $s = shift;
  my $chars;

  if (ref $s) {
    $s = $$s;
    $s =~ s{([$all])}{\\$1}g;
  }
  else {
    $s =~ s{([$wilds])}{\\$1}g;
  }

  return $s;
}

sub escape_chars {
  my $s = shift;
  $s =~ s{([$chars])}{\\$1}g;
  $s;
}

sub unescape_chars {
  my $s = shift;
  $s =~ s{\\([$chars])}{$1}g;
  $s;
}

1;

=encoding utf8

=head1 NAME

SolarBeam::Util - Utility functions for SolarBeam

=head1 SYNOPSIS

    use SolarBeam::Util qw(escape escape_chars unescape_chars);
    say escape_chars "foo?*";

=head1 DESCRIPTION

L<SolarBeam::Util> contains utility functions for L<SolarBeam>.

=head1 FUNCTIONS

=head2 escape

  $str = escape $str;

=head2 escape_chars

  $str = escape_chars $str;

The following values must be escaped in a search value:

  + - & | ! ( ) { } [ ] ^ " ~ * ? : \

B<NB:> Values sent to L<SolarBeam::Query/new> are automatically escaped for you.

=head2 unescape_chars

  $str = unescape_chars $str;

Unescapes values escaped in L</escape_chars>.

=head1 SEE ALSO

L<SolarBeam>.

=cut
