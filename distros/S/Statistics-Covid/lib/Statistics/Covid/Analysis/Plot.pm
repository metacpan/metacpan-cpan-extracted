package Statistics::Covid::Analysis::Plot;

use 5.006;
use strict;
use warnings;

use Statistics::Covid::Datum;

use Chart::Clicker;
use Chart::Clicker::Axis::DateTime;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Data::Series;

use GD::Graph::lines;

our $VERSION = '0.21';

sub	plot_with_chartclicker {
	my $params = $_[0];
	# an array of column names to be used for grouping the data
	my $GroupBy = defined($params->{'GroupBy'}) ? $params->{'GroupBy'} : ['name'];
	# and then for all that data groupped, plot just a single variable, the Y
	my $Y = defined($params->{'Y'}) ? $params->{'Y'} : 'confirmed';

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $outfile;
	if( ! exists($params->{'outfile'}) || ! defined($outfile=$params->{'outfile'}) ){ print STDERR "$whoami (via $parent) : no output file specified (via '$outfile')."; return undef }

	my $objs;
	if( ! exists($params->{'datum-objs'}) || ! defined($objs=$params->{'datum-objs'}) ){ print STDERR "$whoami (via $parent) : no data specified (via 'datum-objs')."; return undef }
	my $numobjs = scalar @$objs;
	#print "$whoami (via $parent) : plotting $numobjs datums...\n";

	# create a data frame to plot those columns with groupby on the same line
	my $df = Statistics::Covid::Utils::datums2dataframe($objs, $GroupBy, ['datetimeUnixEpoch',$Y]);
	if( ! defined $df ){ print STDERR "$whoami (via $parent) : call to ".'Statistics::Covid::Utils::datums2dataframe()'." has failed.\n"; return undef }

	my @series;
	for (sort keys %$df){
		my $aseries = Chart::Clicker::Data::Series->new(
			keys => $df->{$_}->{'datetimeUnixEpoch'},
			values => $df->{$_}->{$Y},
			name => $_
		);
		if( ! defined $aseries ){ print STDERR "$whoami (via $parent) : call to ".'Chart::Clicker::Data::Series->new()'." has failed.\n"; return undef }
		push @series, $aseries
	}
	my $dataset = Chart::Clicker::Data::DataSet->new(series => \@series);

	if( ! defined $dataset ){ print STDERR "$whoami (via $parent) : call to ".' Chart::Clicker::Data::DataSet->new()'." has failed.\n"; return undef }

	my $clicker = Chart::Clicker->new(width => 500, height => 400);
	if( ! defined $clicker ){ print STDERR "$whoami (via $parent) : call to ".' Chart::Clicker->new()'." has failed.\n"; return undef }
	$clicker->add_to_datasets($dataset);

	my $dtaxis = Chart::Clicker::Axis::DateTime->new(
		format => '%d/%m',
		position => 'bottom',
		orientation => 'horizontal'
	);

	my $context = $clicker->get_context('default');
	
	$context->range_axis->format('%.0f');
	$context->domain_axis($dtaxis);
	#$context->domain_axis->hidden(1);
	#$context->domain_axis->ticks(scalar @{$df->{$_}->{$Y}});
	if( ! $clicker->write_output($outfile) ){ print STDERR "$whoami (via $parent) : call to write_output() has failed for output file '$outfile'.\n"; return undef }
	return $outfile
}
sub	plot_with_gd {
	my $params = $_[0];

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $outfile;
	if( ! exists($params->{'outfile'}) || ! defined($outfile=$params->{'outfile'}) ){ print STDERR "$whoami (via $parent) : no output file specified (via '$outfile')."; return undef }

	my $objs;
	if( ! exists($params->{'datum-objs'}) || ! defined($objs=$params->{'datum-objs'}) ){ print STDERR "$whoami (via $parent) : no data specified (via 'datum-objs')."; return undef }

	my $numobjs = scalar @$objs;
	#print "$whoami (via $parent) : plotting $numobjs datums...\n";

	my @dates;
	my @confirmed;
	for (@$objs){
		#push @dates, $_->date_unixepoch();
		push @dates, $_->date_iso8601();
		push @confirmed, $_->confirmed();
	}
	my $df = GD::Graph::Data->new([\@dates, \@confirmed]);
	if( ! defined $df ){ print STDERR "$whoami (via $parent) : call to ".' GD::Graph::Data->new()'." has failed: ".GD::Graph::Data->error."\n"; return undef }

	my $graph = GD::Graph::lines->new();
	if( ! defined $graph ){ print STDERR "$whoami (via $parent) : call to ".' GD::Graph::lines->new()'." has failed: ".GD::Graph::lines->error."\n"; return undef }

	$graph->set(
		title => 'abc',
		x_label => 'Time',
		y_label => 'Confirmed',
		y_max_value       => 80,
		y_tick_number     => 8,
		x_all_ticks       => 1,
		y_all_ticks       => 1,
		x_label_skip      => 3,
	);
	my $gd = $graph->plot($df);
	if( ! defined $gd ){ print STDERR "$whoami (via $parent) : call to plot() has failed: ".$graph->error.".\n"; return undef }
	if( ! open(OUT, '>', $outfile) ){ print STDERR "$whoami (via $parent) : error, failed to open file '$outfile' for writing: $!\n"; return undef }
	binmode(OUT); print OUT $gd->png(); close OUT;
	return $outfile
}
1;
__END__
# end program, below is the POD
=pod

=encoding UTF-8

=head1 NAME

Statistics::Covid::Analysis::Plot - Plots the data

=head1 VERSION

Version 0.20

=head1 DESCRIPTION

This package contains routines for plotting L<Statistics::Covid::Datum> objects.

=head1 SYNOPSIS

	use Statistics::Covid;
	use Statistics::Covid::Analysis::Plot;
	
	$covid = Statistics::Covid->new({   
		'config-file' => 't/example-config.json',
		'providers' => ['UK::BBC', 'UK::GOVUK', 'World::JHU'],
		'save-to-file' => 1,
		'save-to-db' => 1,
		'debug' => 2,
	}) or die "Statistics::Covid->new() failed";
	# fetch all the data available (posibly json), process it,
	# create Datum objects, store it in DB and return an array 
	# of the Datum objects just fetched  (and not what is already in DB).
	my $newobjs = $covid->fetch_and_store();
	
	# plot something
	my $objs = $covid->db_select({
		conditions => {belongsto=>'UK', name=>{'like' => 'Ha%'}}
	});
	my $outfile = 'chartclicker.png';
	my $ret = Statistics::Covid::Analysis::Plot::plot_with_chartclicker({
        	'datum-objs' => $objs,
		# saves to this file:
	        'outfile' => $outfile,
		# plot this column (x-axis is time always)
        	'Y' => 'confirmed', 
		# and make several plots, each group must have 'name' common
	        'GroupBy' => ['name']
	});
	
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

    perldoc Statistics::Covid::Analysis::Plot


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

