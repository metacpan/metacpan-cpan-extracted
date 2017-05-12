package String::Ediff;
require Exporter;
require DynaLoader;
use vars qw($VERSION);
@ISA = qw(Exporter DynaLoader);
package String::Ediff;
bootstrap String::Ediff;
package String::Ediff;
@EXPORT = qw( );
$VERSION = sprintf('%d.%02d', (q$Revision: 0.09 $ =~ /\d+/g));
1;
__END__

=head1 NAME

String::Ediff - Produce common sub-string indices for two strings

=head1 SYNOPSIS

  use String::Ediff;
  my $s1 = "hello world";
  my $s2 = "hxello worlyd";

  my $indices = String::Ediff::ediff($s1, $s2);
  print $indices, "\n"; #1 10 0 0 2 11 0 0

  #                           0         1         2        0         1         2
  #                           01234567890123456789012345   012345678901234567890123
  print String::Ediff::ediff("hello world a hello world", "hxello worlyd xyz hello");
  # 1 10 0 0 2 11 0 0 13 20 0 0 17 23 0 0

=head1 DESCRIPTION

This module uses suffix tree algorithm to determine the common substrings.

=head2 ediff()

  $common_sub_string_indices = ediff($s1, $s2);

The ediff method takes two strings and returns the common sub-string indices
between the two strings.  The returned indices consists of records separated
by a space.  Each record, representing one common sub-string, consists of
8 numbers in the following format:

  bc1 ec1 bl1 el1 bc2 ec2 bl2 el2

bc1 - begin char in s1

ec1 - end char in s1

bl1 - begin line in s1

el1 - end line in s1

bc2 - begin char in s2

ec2 - end char in s2

bl2 - begin line in s2

el2 - end line in s2

=head1 LIMITATIONS

  1. white spaces are ignored.
  2. because of white spaces are ignored, the end char index of a previous
     record and the begin char index of a next record might overlap.
  3. the interval is right open-ended, i.e. [1, 4) means char 1, 2, and 3
     are in the common string.  char 4 is not.
  4. only sub-string with size >= 4 are recorded.

=head1 AUTHOR

Bo Zou, boxzou@yahoo.com

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2003-2005 Bo Zou

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

