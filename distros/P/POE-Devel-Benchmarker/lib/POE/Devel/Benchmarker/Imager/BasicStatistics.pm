# Declare our package
package POE::Devel::Benchmarker::Imager::BasicStatistics;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.05';

# the GD stuff
use GD::Graph::lines;
use GD::Graph::colour qw( :lists );

# import some stuff
use POE::Devel::Benchmarker::Utils qw( currentMetrics );

# creates a new instance
sub new {
	my $class = shift;
	my $opts = shift;

	# instantitate ourself
	my $self = {
		'opts' => $opts,
	};
	return bless $self, $class;
}

# actually generates the graphs!
sub imager {
	my $self = shift;
	$self->{'imager'} = shift;

	# generate the loops vs each other graphs
	$self->generate_loopwars;

	# generate the single loop performance
	$self->generate_loopperf;

	# generate the loop assert/xsqueue ( 4 lines ) per metric
	$self->generate_loopoptions;

	return;
}

# charts a single loop's progress over POE versions
sub generate_loopoptions {
	my $self = shift;

	if ( ! $self->{'imager'}->quiet ) {
		print "[BasicStatistics] Generating the Loop-Options graphs...\n";
	}

	# go through all the loops we want
	foreach my $loop ( keys %{ $self->{'imager'}->poe_loops } ) {
		foreach my $metric ( @{ currentMetrics() } ) {
			my %data;

			# organize data by POE version
			foreach my $poe ( @{ $self->{'imager'}->poe_versions_sorted } ) {
				# go through the combo of assert/xsqueue
				foreach my $assert ( qw( assert noassert ) ) {
					if ( ! exists $self->{'imager'}->data->{ $assert } ) {
						next;
					}
					foreach my $xsqueue ( qw( xsqueue noxsqueue ) ) {
						if ( ! exists $self->{'imager'}->data->{ $assert }->{ $xsqueue } ) {
							next;
						}

						# sometimes we cannot test a metric
						if ( exists $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }
							and exists $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }->{'i'}
							and defined $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }->{'i'}
							) {
							push( @{ $data{ $assert . '_' . $xsqueue } }, $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }->{'i'} );
						} else {
							push( @{ $data{ $assert . '_' . $xsqueue } }, 0 );
						}
					}
				}
			}

			# it's possible for us to do runs without assert/xsqueue
			if ( scalar keys %data > 0 ) {
				# transform %data into something GD likes
				my @data_for_gd;
				foreach my $m ( sort keys %data ) {
					push( @data_for_gd, $data{ $m } );
				}

				# send it to GD!
				$self->make_gdgraph(	'Options_' . $loop . '_' . $metric,
							[ sort keys %data ],
							\@data_for_gd,
				);
			}
		}
	}

	return;
}

# charts a single loop's progress over POE versions
sub generate_loopperf {
	my $self = shift;

	if ( ! $self->{'imager'}->quiet ) {
		print "[BasicStatistics] Generating the Loop-Performance graphs...\n";
	}

	# go through all the loops we want
	foreach my $loop ( keys %{ $self->{'imager'}->poe_loops } ) {
		# go through the combo of assert/xsqueue
		foreach my $assert ( qw( assert noassert ) ) {
			if ( ! exists $self->{'imager'}->data->{ $assert } ) {
				next;
			}
			foreach my $xsqueue ( qw( xsqueue noxsqueue ) ) {
				if ( ! exists $self->{'imager'}->data->{ $assert }->{ $xsqueue } ) {
					next;
				}
				my %data;

				# organize data by POE version
				foreach my $poe ( @{ $self->{'imager'}->poe_versions_sorted } ) {
					foreach my $metric ( @{ currentMetrics() } ) {
						# sometimes we cannot test a metric
						if ( exists $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }
							and exists $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }->{'i'}
							and defined $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }->{'i'}
							) {
							push( @{ $data{ $metric } }, $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }->{'i'} );
						} else {
							push( @{ $data{ $metric } }, 0 );
						}
					}
				}

				# transform %data into something GD likes
				my @data_for_gd;
				foreach my $m ( sort keys %data ) {
					push( @data_for_gd, $data{ $m } );
				}

				# send it to GD!
				$self->make_gdgraph(	'Bench_' . $loop,
							[ sort keys %data ],
							\@data_for_gd,
							$assert,
							$xsqueue,
				);
			}
		}
	}

	return;
}

# loop wars!
sub generate_loopwars {
	my $self = shift;

	if ( ! $self->{'imager'}->quiet ) {
		print "[BasicStatistics] Generating the LoopWars graphs...\n";
	}

	# go through all the metrics we want
	foreach my $metric ( @{ currentMetrics() } ) {
		# go through the combo of assert/xsqueue
		foreach my $assert ( qw( assert noassert ) ) {
			if ( ! exists $self->{'imager'}->data->{ $assert } ) {
				next;
			}
			foreach my $xsqueue ( qw( xsqueue noxsqueue ) ) {
				if ( ! exists $self->{'imager'}->data->{ $assert }->{ $xsqueue } ) {
					next;
				}
				my %data;

				# organize data by POE version
				foreach my $poe ( @{ $self->{'imager'}->poe_versions_sorted } ) {
					foreach my $loop ( keys %{ $self->{'imager'}->poe_loops } ) {
						# sometimes we cannot test a metric
						if ( exists $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }
							and exists $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }->{'i'}
							and defined $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }->{'i'}
							) {
							push( @{ $data{ $loop } }, $self->{'imager'}->data->{ $assert }->{ $xsqueue }->{ $poe }->{ $loop }->{'metrics'}->{ $metric }->{'i'} );
						} else {
							push( @{ $data{ $loop } }, 0 );
						}
					}
				}

				# transform %data into something GD likes
				my @data_for_gd;
				foreach my $m ( sort keys %data ) {
					push( @data_for_gd, $data{ $m } );
				}

				# send it to GD!
				$self->make_gdgraph(	"LoopWar_$metric",
							[ sort keys %{ $self->{'imager'}->poe_loops } ],
							\@data_for_gd,
							$assert,
							$xsqueue,
				);
			}
		}
	}

	return;
}

sub make_gdgraph {
	my $self = shift;
	my $metric = shift;
	my $legend = shift;
	my $data = shift;
	my $assert = shift;
	my $xsqueue = shift;

	# build the title
	my $title = $metric;
	if ( defined $assert ) {
		$title .= ' (';
		if ( defined $xsqueue ) {
			$title .= $assert . ' ' . $xsqueue;
		} else {
			$title .= $assert;
		}
		$title .= ')';
	} else {
		if ( defined $xsqueue ) {
			$title .= ' (' . $xsqueue . ')';
		}
	}

	# Get the graph object
	my $graph = new GD::Graph::lines( 800, 600 );

	# Set some stuff
	$graph->set(
		'title'			=> $title,
		'line_width'		=> 1,
		'boxclr'		=> 'black',
		'overwrite'		=> 0,
		'x_labels_vertical'	=> 1,
		'x_all_ticks'		=> 1,
		'legend_placement'	=> 'BL',
		'y_label'		=> 'iterations/sec',
		'transparent'		=> 0,
		'long_ticks'		=> 1,
	) or die $graph->error;

	# Set the legend
	$graph->set_legend( @$legend );

	# Set Font stuff
	$graph->set_legend_font( GD::gdMediumBoldFont );
	$graph->set_x_axis_font( GD::gdMediumBoldFont );
	$graph->set_y_axis_font( GD::gdMediumBoldFont );
	$graph->set_y_label_font( GD::gdMediumBoldFont );
	$graph->set_title_font( GD::gdGiantFont );

	# set the line colors
	$graph->set( 'dclrs' => [ grep { $_ ne 'black' and $_ ne 'white' } sorted_colour_list() ] );

	# Manufacture the data
	my $readydata = [
		[ map { 'POE-' . $_ } @{ $self->{'imager'}->poe_versions_sorted } ],
		@$data,
	];

	# Plot it!
	$graph->plot( $readydata ) or die $graph->error;

	# Print it!
	my $filename = $self->{'opts'}->{'dir'} . $metric . '_' .
		( $self->{'imager'}->litetests ? 'lite' : 'heavy' ) .
		( defined $xsqueue ? '_' . $assert . '_' . $xsqueue : '' ) .
		'.png';
	open( my $fh, '>', $filename ) or die 'Cannot open graph file!';
	binmode( $fh );
	print $fh $graph->gd->png();
	close( $fh );

	return;
}

1;
__END__
=head1 NAME

POE::Devel::Benchmarker::Imager::BasicStatistics - Plugin to generates basic statistics graphs

=head1 SYNOPSIS

	apoc@apoc-x300:~$ cd poe-benchmarker
	apoc@apoc-x300:~/poe-benchmarker$ perl -MPOE::Devel::Benchmarker::Imager -e 'imager( { type => "BasicStatistics" } )'

=head1 ABSTRACT

This plugin for Imager generates some kinds of graphs from the benchmark tests.

=head1 DESCRIPTION

This package generates some basic graphs from the statistics output. Since the POE::Loop::* modules really are responsible
for the backend logic of POE, it makes sense to graph all related metrics of a single loop across POE versions to see if
it performs differently.

This will generate some types of graphs:

=over 4

=item Loops against each other

Each metric will have a picture for itself, showing how each loop compare against each other with the POE versions.

file: BasicStatistics/LoopWar_$metric_$lite_$assert_$xsqueue.png

=item Single Loop over POE versions

Each Loop will have a picture for itself, showing how each metric performs over POE versions.

file: BasicStatistics/Bench_$loop_$lite_$assert_$xsqueue.png

=item Single Loop over POE versions with assert/xsqueue

Each Loop will have a picture for itself, showing how each metric is affected by the assert/xsqueue options.

file: BasicStatistics/Options_$loop_$metric_$lite.png

=back

=head1 EXPORT

Nothing.

=head1 SEE ALSO

L<POE::Devel::Benchmarker>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

