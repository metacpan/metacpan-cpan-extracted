package String::LCSS_XS;
use 5.008;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    lcss lcss_all
);

our $VERSION = '1.2';

require XSLoader;
XSLoader::load( 'String::LCSS_XS', $VERSION );

1;
__END__

=head1 NAME

String::LCSS_XS - Find The Longest Common Substring of Two Strings.

=head1 VERSION

This document describes String::LCSS_XS version 1.2

=head1 SYNOPSIS

  use String::LCSS_XS qw(lcss lcss_all);
  
  my $longest = lcss ( "zyzxx", "abczyzefg" );
  print $longest, "\n";

  my @result = lcss ( "zyzxx", "abczyzefg" );
  print "$result[0] ($result[1],$result[2])\n";

  my @results = lcss_all ( "ABBA", "BABA" );
  for my $result (@results) {
     print "$result->[0] ($result->[1],$result->[2])\n";
  }

  $longest = lcss ( "foobar", "abcxyzefg", 3 ); #undef

=head1 DESCRIPTION

String::LCSS_XS computes the Longest Common Substring of two strings s and t.
It is a C implementation of L<String::LCSS> and uses a dynamic programming 
algorithm with O(mn) runtime and O(min(m,n)) memory usage (m is the length of s 
and n the length of t). 

=head1 EXPORT_OK 

By default String::LCSS_XS does not export any subroutines. The subroutines
defined are
  
=over

=item lcss(s, t, min)

In scalar context, returns the first found longest common substring of s and
t. In array context, it also returns the match positions. Mainly for
compatibility with L<String::LCSS>. The optional argument min defines the
minimum length of a reported substring.

=item lcss_all(s, t, min)

Returns all longest common substrings of s and t including the match positions.  

=back

=head1 PERFORMANCE

  my $s = 'i pushed the lazy dog into a creek, the quick brown fox told me to';
  my $t = 'the quick brown fox jumps over the lazy dog';

                     Rate    String::LCSS String::LCSS_XS
  String::LCSS     60.9/s              --           -100%
  String::LCSS_XS 84746/s         138966%              --
  
=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-string-lcss_xs@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. 

L<String::LCSS> returns C<undef> when the lcss has size 1. String::LCSS_XS
returns this single character. 

=head1 CREDITS

Daniel Yacob has written L<String::LCSS>. I stole his API, test suite and
SYNOPSIS.

=head1 SEE ALSO

L<String::LCSS> - A pure perl implementation (but O(n^3) runtime)

L<Tree::Suffix> - A lcss solution based on Suffix Trees

Gusfield, Dan. I<Algorithms on Strings, Trees and Sequences: Computer Science
and Computational Biology>. USA: Cambridge University Press. 
ISBN 0-521-58519-8. 

=head1 AUTHOR

Markus Riester, E<lt>limaone@cpan.orgE<gt> with lots of help and many
patches from ikegami. 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2010 by Markus Riester.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
