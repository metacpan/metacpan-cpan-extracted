#
# This file is part of Test-Apocalypse
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Test::Apocalypse::PerlMetrics;
$Test::Apocalypse::PerlMetrics::VERSION = '1.006';
BEGIN {
  $Test::Apocalypse::PerlMetrics::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: Plugin for Perl::Metrics::Simple

use Test::More;
use Perl::Metrics::Simple 0.13;

sub do_test {
	plan tests => 1;
	my $analzyer = Perl::Metrics::Simple->new;
	my $analysis = $analzyer->analyze_files( 'lib/' );
	my $numdisplay = 10;

	if ( ok( $analysis->file_count(), 'Analyzed at least one file' ) ) {
		# only print extra stuff if necessary
		if ( $ENV{TEST_VERBOSE} ) {
			diag( '-- Perl Metrics Summary --' );
			diag( ' File Count: ' . $analysis->file_count );
			diag( ' Package Count: ' . $analysis->package_count );
			diag( ' Subroutine Count: ' . $analysis->sub_count );
			diag( ' Total Code Lines: ' . $analysis->lines );
			diag( ' Non-Sub Lines: ' . $analysis->main_stats->{'lines'} );

			diag( '-- Subrotuine Metrics Summary --' );
			my $summary_stats = $analysis->summary_stats;
			diag( ' Min: lines(' . $summary_stats->{sub_length}->{min} . ') McCabe(' . $summary_stats->{sub_complexity}->{min} . ')' );
			diag( ' Max: lines(' . $summary_stats->{sub_length}->{max} . ') McCabe(' . $summary_stats->{sub_complexity}->{max} . ')' );
			diag( ' Mean: lines(' . $summary_stats->{sub_length}->{mean} . ') McCabe(' . $summary_stats->{sub_complexity}->{mean} . ')' );
			diag( ' Standard Deviation: lines(' . $summary_stats->{sub_length}->{standard_deviation} . ') McCabe(' . $summary_stats->{sub_complexity}->{standard_deviation} . ')' );
			diag( ' Median: lines(' . $summary_stats->{sub_length}->{median} . ') McCabe(' . $summary_stats->{sub_complexity}->{median} . ')' );

			diag( "-- Top$numdisplay subroutines by McCabe Complexity --" );
			my @sorted_subs = reverse sort { $a->{'mccabe_complexity'} <=> $b->{'mccabe_complexity'} } @{ $analysis->subs };
			foreach my $i ( 0 .. ( $numdisplay - 1 ) ) {
				last if ! defined $sorted_subs[$i];

				diag( ' ' . $sorted_subs[$i]->{'path'} . ':' . $sorted_subs[$i]->{'name'} . ' ->' .
					' McCabe(' . $sorted_subs[$i]->{'mccabe_complexity'} . ')' .
					' lines(' . $sorted_subs[$i]->{'lines'} . ')'
				);
			}

			diag( "-- Top$numdisplay subroutines by lines --" );
			@sorted_subs = reverse sort { $a->{'lines'} <=> $b->{'lines'} } @sorted_subs;
			foreach my $i ( 0 .. ( $numdisplay - 1 ) ) {
				last if ! defined $sorted_subs[$i];

				diag( ' ' . $sorted_subs[$i]->{'path'} . ':' . $sorted_subs[$i]->{'name'} . ' ->' .
					' lines(' . $sorted_subs[$i]->{'lines'} . ')' .
					' McCabe(' . $sorted_subs[$i]->{'mccabe_complexity'} . ')'
				);
			}

			#require Data::Dumper;
			#diag( 'Summary Stats: ' . Data::Dumper::Dumper( $analysis->summary_stats ) );
			#diag( 'File Stats: ' . Data::Dumper::Dumper( $analysis->file_stats ) );
		}
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse Niebur Ryan

=for Pod::Coverage do_test

=head1 NAME

Test::Apocalypse::PerlMetrics - Plugin for Perl::Metrics::Simple

=head1 VERSION

  This document describes v1.006 of Test::Apocalypse::PerlMetrics - released October 25, 2014 as part of Test-Apocalypse.

=head1 DESCRIPTION

Encapsulates L<Perl::Metrics::Simple> functionality. Enable TEST_VERBOSE to get a diag() output of some metrics.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Test::Apocalypse|Test::Apocalypse>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
