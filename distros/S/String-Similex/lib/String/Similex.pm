package String::Similex;

BEGIN {
  require 5.006;
}
use strict;
use warnings;

require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT = qw(&similex $similex_nocode);

$VERSION = '0.01';

our $similex_nocode = undef;

sub similex {
  my (@str,$char,$previous,$code) = @_;

  foreach (@str) {
    $_ = lc($_);

    if ($_ eq '') {
      $_ = $similex_nocode;
    } else {
      tr/hcfjkrwxyz2689a41|liou0mn\-_t7s5\$e3bdgqpuv/0111111111111122333344455667788899AABBBCC/;
      tr///cs;
      tr/0//d;
      tr/0-9ABC//cd;
    }
  }

  wantarray ? @str : shift @str;
}

1;
__END__

=head1 NAME

String::Similex - gives a code to compare similar "visual" strings

=head1 SYNOPSIS

  use String::Similex;

  $code  = similex($string);
  @codes = similex(@strings);

  # set value to be returned for strings without a similex code

  $similex_code = ' ';

=head1 DESCRIPTION

The similex code is used to compare strings that are visually
equivalent, character sequences that resemble each other.

=head1 EXAMPLES

Using in your code:

 $code  = similex('Novis');          # $code contains '54C38'
 @codes = similex(qw(Linux MacOSX)); # @codes contains '3541', '521481'

Similar strings:

  linux, |imux                 ->  3541
  CISCO, C15CO, ciscu          ->  13814
  gandalf, ganda1f, gggandalf  ->  B25A231

=head1 TODO

Probably two things:

  o Define a fixed code length as of Soundex. Which value should be
    confortable ?

  o More study of the algorithm. Should 's' be equivalent to 'z' ?
    But 'z' is not like '5'. :/ Different behaviour with upper and
    lower case letters.

=head1 SEE ALSO

Of course Text::Soundex.
The String::Similarity calculates a similarity fuzzy value of two strings.
The String::Approx let's you match and substitute strings approximately.

=head1 AUTHOR

Paulo A Ferreira <biafra@cpan.org>

Please send any suggestion.
This implementation follow the structure of Text::Soundex. It sounded nice.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Paulo A Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
