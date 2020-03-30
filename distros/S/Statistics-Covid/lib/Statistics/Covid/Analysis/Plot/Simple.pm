package Statistics::Covid::Analysis::Plot::Simple;

use 5.006;
use strict;
use warnings;

use Statistics::Covid::Datum;
use Statistics::Covid::Utils;

use Chart::Clicker;
use Chart::Clicker::Axis::DateTime;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Data::Series;

our $VERSION = '0.23';

our $DEBUG = 0;

sub	plot {
	my $params = $_[0];
	# an array of column names to be used for grouping the data
	my $GroupBy = defined($params->{'GroupBy'}) ? $params->{'GroupBy'} : ['name'];
	# and then for all that data groupped, plot just a single variable, the Y
	my $Y = exists($params->{'Y'}) && defined($params->{'Y'}) ? $params->{'Y'} : 'confirmed';

	# optional X, default is time (e.g. datetimeUnixEpoch)
	my $X = exists($params->{'X'}) && defined($params->{'X'}) ? $params->{'X'} : 'datetimeUnixEpoch';

	# optionally specify date-formatting for X-axis (expecting X to be seconds since unix epoch)
	my $dateformatX = (
		   (exists($params->{'date-format-x'}) && defined($params->{'date-format-x'}))
		|| ($X eq 'datetimeUnixEpoch')
	)  ? $params->{'date-format-x'} :
			{ # this is what we expect from 'date-format-x'
				format => '%d/%m',
				position => 'bottom',
				orientation => 'horizontal'
			}
	;
	if( (ref($dateformatX) ne 'HASH') || ! exists($dateformatX->{'format'}) ){ warn "error, something wrong with the specified 'date-format-x'. It must be a hashref and contain at least a 'format' key, see Chart::Clicker::Axis::DateTime for what options the datetime formatting takes."; return undef }

	my $outfile;
	if( ! exists($params->{'outfile'}) || ! defined($outfile=$params->{'outfile'}) ){ warn "error, no output file specified (via '$outfile')."; return undef }

	my $df = undef;
	if( exists($params->{'datum-objs'}) && defined($params->{'datum-objs'}) ){
		# create a data frame to plot those columns with groupby on the same line
		$df = Statistics::Covid::Utils::datums2dataframe({
			'datum-objs' => $params->{'datum-objs'},
			'groupby' => $GroupBy,
			'content' => [$X, $Y],
		});
	} elsif( exists($params->{'dataframe'}) && defined($params->{'dataframe'}) ){
		$df = $params->{'dataframe'};
	} else { warn "error, no data specified (either via 'datum-objs' or 'dataframe')."; return undef }
	if( ! defined $df ){ warn "error, call to ".'Statistics::Covid::Utils::datums2dataframe()'." has failed.\n"; return undef }

	my $numobjs = scalar keys %$df;
	if( $DEBUG > 0 ){ warn "plotting $numobjs datums ...\n" }

	my @series;
	for my $k (sort keys %$df){
		# we have asked to have x-axis as time and y-axis as $Y (user specified)
		my $aseries = Chart::Clicker::Data::Series->new(
			keys   => $df->{$k}->{$X},
			values => $df->{$k}->{$Y},
			name   => $k
		);
		if( ! defined $aseries ){ warn "error, call to ".'Chart::Clicker::Data::Series->new()'." has failed.\n"; return undef }
		push @series, $aseries
	}
	my $dataset = Chart::Clicker::Data::DataSet->new(series => \@series);

	if( ! defined $dataset ){ warn "error, call to ".' Chart::Clicker::Data::DataSet->new()'." has failed.\n"; return undef }

	my $clicker = Chart::Clicker->new(width => 500, height => 400);
	if( ! defined $clicker ){ warn "error, call to ".' Chart::Clicker->new()'." has failed.\n"; return undef }
	$clicker->add_to_datasets($dataset);

	my $context = $clicker->get_context('default');
	if( ! defined $context ){ warn "error, call to get_context() has failed."; return undef }

	$context->domain_axis(Chart::Clicker::Axis::DateTime->new($dateformatX))
		if $dateformatX;
	
	$context->range_axis->format('%.0f');
	#$context->domain_axis->hidden(1);
	#$context->domain_axis->ticks(scalar @{$df->{$_}->{$Y}});
	if( ! $clicker->write_output($outfile) ){ warn "error, call to write_output() has failed for output file '$outfile'.\n"; return undef }
	return $outfile # success, return the output image file
}
1;
__END__
# end program, below is the POD
=pod

=encoding UTF-8

=head1 NAME

Statistics::Covid::Analysis::Plot::Simple - Plots data

=head1 VERSION

Version 0.23

=head1 DESCRIPTION

This package contains routine(s) for plotting a number of
L<Statistics::Covid::Datum> objects using L<Chart::Clicker>.

=head1 SYNOPSIS

	use Statistics::Covid;
	use Statistics::Covid::Datum;
	use Statistics::Covid::Utils;
	use Statistics::Covid::Analysis::Plot::Simple;
	
	# read data from db
	$covid = Statistics::Covid->new({   
		'config-file' => 't/config-for-t.json',
		'debug' => 2,
	}) or die "Statistics::Covid->new() failed";
	# retrieve data from DB for selected locations (in the UK)
	# data will come out as an array of Datum objects sorted wrt time
	# (the 'datetimeUnixEpoch' field)
	$objs = $covid->select_datums_from_db_for_specific_location_time_ascending(
		#{'like' => 'Ha%'}, # the location (wildcard)
		['Halton', 'Havering'],
		#{'like' => 'Halton'}, # the location (wildcard)
		#{'like' => 'Havering'}, # the location (wildcard)
		'UK', # the belongsto (could have been wildcarded)
	);
	# create a dataframe
	$df = Statistics::Covid::Utils::datums2dataframe({
		'datum-objs' => $objs,
		# collect data from all those with same 'name' and same 'belongsto'
		# and plot this data as a single curve (or fit or whatever)
		'groupby' => ['name','belongsto'],
		# put only these values of the datum object into the dataframe
		# one of them will be X, another will be Y
		# if you want to plot multiple Y, then add here more dependent columns
		# like ('unconfirmed').
		'content' => ['confirmed', 'unconfirmed', 'datetimeUnixEpoch'],
	});

	# plot confirmed vs time
	$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
		'dataframe' => $df,
		# saves to this file:
		'outfile' => 'confirmed-over-time.png',
		# plot this column against X
		# (which is not present and default is time ('datetimeUnixEpoch')
		'Y' => 'confirmed',
	});

	# plot confirmed vs unconfirmed
	# if you see a vertical line it means that your data has no 'unconfirmed'
	$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
		'dataframe' => $df,
		# saves to this file:
		'outfile' => 'confirmed-vs-unconfirmed.png',
		'X' => 'unconfirmed',
		# plot this column against X
		'Y' => 'confirmed',
	});

	# plot using an array of datum objects as they came
	# out of the DB. A dataframe is created internally to the plot()
	# but this is not recommended if you are going to make several
	# plots because equally many dataframes must be created and destroyed
	# internally instead of recycling them like we do here...
	$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
		'datum-objs' => $objs,
		# saves to this file:
		'outfile' => 'confirmed-over-time.png',
		# plot this column as Y
		'Y' => 'confirmed', 
		# X is not present so default is time ('datetimeUnixEpoch')
		# and make several plots, each group must have 'name' common
		'GroupBy' => ['name', 'belongsto'],
		'date-format-x' => {
			# see Chart::Clicker::Axis::DateTime for all the options:
			format => '%m', ##<<< specify timeformat for X axis, only months
			position => 'bottom',
			orientation => 'horizontal'
		},
	});


	# This is what the dataframe looks like (fictitious data):
	#  {
	#  Halton   => {
	#		confirmed => [0, 0, 3, 4, 4, 5, 7, 7, 7, 8, 8, 8],
	#		unconfirmed => [15, 15, 17, 17, 24, 29, 40, 45, 49, 54, 57, 80],
	#		datetimeUnixEpoch => [
	#		  1584262800,
	#		  1584349200,
	#		  1584435600,
	#		  1584522000,
	#		  1584637200,
	#		  1584694800,
	#		  1584781200,
	#		  1584867600,
	#		  1584954000,
	#		  1585040400,
	#		  1585126800,
	#		  1585213200,
	#		],
	#	      },
	#  Havering => {
	#		confirmed => [5, 5, 7, 7, 14, 19, 30, 35, 39, 44, 47, 70],
	#		unconfirmed => [15, 15, 17, 17, 24, 29, 40, 45, 49, 54, 57, 80],
	#		datetimeUnixEpoch => [
	#		  1584262800,
	#		  1584349200,
	#		  1584435600,
	#		  1584522000,
	#		  1584637200,
	#		  1584694800,
	#		  1584781200,
	#		  1584867600,
	#		  1584954000,
	#		  1585040400,
	#		  1585126800,
	#		  1585213200,
	#		],
	#	      },
	#  }

=head2 plot

Plots data to specified file using L<Chart::Clicker>. The input data
is either an array of L<Statistics::Covid::Datum> objects or
a dataframe (as created by L<Statistics::Covid::Utils::datums2dataframe>
(see the SYNOPSIS for examples).
xxx


	
=head1 AUTHOR
	
Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>, C<< <andreashad2 at gmail.com> >>

=head1 BUGS

This module has been put together very quickly and under pressure.
There are must exist quite a few bugs.

Please report any bugs or feature requests to C<bug-statistics-Covid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Covid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Covid::Analysis::Plot::Simple


You can also look for information at:

=over 4

=item * github L<repository|https://github.com/hadjiprocopis/statistics-covid>  which will host data and alpha releases

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Covid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Covid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Covid>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Covid/>

=item * Information about the basis module DBIx::Class

L<http://search.cpan.org/dist/DBIx-Class/>

=back


=head1 DEDICATIONS

Almaz

=head1 ACKNOWLEDGEMENTS

=over 2

=item L<Perlmonks|https://www.perlmonks.org> for supporting the world with answers and programming enlightment

=item L<DBIx::Class>

=item the data providers:

=over 2

=item L<John Hopkins University|https://www.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6>,

=item L<UK government|https://www.gov.uk/government/publications/covid-19-track-coronavirus-cases>,

=item L<https://www.bbc.co.uk> (for disseminating official results)

=back

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut

