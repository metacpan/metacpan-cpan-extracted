package Perl::Metrics::Plugin;

=pod

=head1 NAME

Perl::Metrics::Plugin - Base class for Perl::Metrics Plugins

=head1 SYNOPSIS

  # Implement a simple metrics package which counts up the
  # use of each type of magic variable.
  package Perl::Metrics::Plugin::Magic;
  
  use base 'Perl::Metrics::Plugin';
  
  # Creates the metric 'all_magic'.
  # The total number of magic variables. 
  sub metric_all_magic {
      my ($self, $Document) = @_;
      return scalar grep { $_->isa('PPI::Token::Magic') }
                    $Document->tokens;
  }
  
  # The number of $_ "scalar_it" magic vars
  sub metric_scalar_it {
      my ($self, $Document) = @_;
      return scalar grep { $_->content eq '$_' }
                    grep { $_->isa('PPI::Token::Magic') }
                    $Document->tokens;
  }
  
  # ... and so on, and so forth.
  
  1;

=head1 DESCRIPTION

The L<Perl::Metrics> system does not in and of itself generate any actual
metrics data, it merely acts as a processing and storage engine.

The generation of the actual metrics data is done via metrics packages,
which as implemented as C<Perl::Metrics::Plugin> sub-classes.

=head2 Implementing Your Own Metrics Package

Implementing a metrics package is pretty easy.

First, create a Perl::Metrics::Plugin::Something package, inheriting
from C<Perl::Metrics::Plugin>.

The create a subroutine for each metric, named metric_$name.

For each subroutine, you will be passed the plugin object itself, and the
L<PPI::Document> object to generate the metric for.

Return the metric value from the subroutine. And add as many metric_
methods as you wish. Methods not matching the pattern /^metric_(.+)$/
will be ignored, and you may use them for whatever support methods you
wish.

=head1 METHODS

=cut

use strict;
use Carp             ();
use Class::Inspector ();
use Params::Util     '_IDENTIFIER',
                     '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.09';
}





#####################################################################
# Constructor

=pod

=head2 new

The C<new> constructor is quite trivial at this point, and is provided
merely as a convenience. You don't really need to think about this.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $self  = bless {}, $class;
	$self;
}

=pod

=head2 class

A convenience method to get the class for the plugin object,
to avoid having to use ref directly (and making the intent of
any code a little clearer).

=cut

sub class { ref $_[0] || $_[0] }





#####################################################################
# Perl::Metrics::Plugin API

=pod

=head2 metrics

The C<metrics> method provides the list of metrics that are provided
by the metrics package. By default, this list is automatically
generated for you scanning for C<metric_$name> methods that reside
in the immediate package namespace.

Returns a reference to a C<HASH> where the keys are the metric names,
and the values are the "version" of the metric (for versioned metrics),
or C<undef> if the metric is not versioned.

=cut

sub metrics {
	my $self = shift;
	$self->{_metrics} or
	$self->{_metrics} = $self->_metrics;	
}

sub _metrics {
	my $self    = shift;
	my $class   = ref $self;
	my $funcs   = Class::Inspector->functions($class)
		or Carp::croak("Failed to get method list for '$class'");
	my %metrics = map  { $_ => undef     }
	              grep { _IDENTIFIER($_) }
	              grep { s/^metric_//s   }
	              @$funcs;
	\%metrics;
}

sub _metric {
	my ($self, $Document, $name) = @_;
	my $method = "metric_$name";
	$self->can($method) or Carp::croak("Bad metric name '$name'");
	scalar($self->$method($Document));
}

=pod

=head2 process_index

The C<process_index> method will cause the metrics plugin to scan every
single file entry in the database, and run any an all metrics required to
bring to the database up to complete coverage for that plugin.

This process may take some time for large indexes.

=cut

sub process_index {
	my $self  = shift;
	my @files = Perl::Metrics::File->retrieve_all;
	@files = sort { $a->path cmp $b->path } @files;
	while ( my $file = shift @files ) {
		Perl::Metrics->_trace("Processing $file... ");
		if ( $self->process_file($file) ) {
			Perl::Metrics->_trace("done.\n");
		} else {
			Perl::Metrics->_trace("error.\n");
		}
	}
	1;
}

=pod

=head2 process_file $File

The C<process_file> method takes as argument a single
L<Perl::Metrics::File> and run any and all metrics required
to bring that file up to complete coverage for the plugin.

=cut

sub process_file {
	my $self = shift;
	my $file = _INSTANCE(shift, 'Perl::Metrics::File')
		or Carp::croak("Did not pass a Perl::Metrics::File to process_file");

	# Has the file been removed since the last run
	unless ( -f $file->path ) {
		# Delete the file entry
		$file->delete;
		return 1;
	}

	# Get the metric list for the plugin, and the
	# database Metric data for this file.
	my %metrics = %{$self->metrics}; # Copy so we can destroy
	my @objects = $file->metrics(
		'package' => $self->class,
		);

	# Deal with the existing metrics objects that do not
	# require the Document in order to be processed.
	my @todo = ();
	foreach my $object ( @objects ) {
		my $name = $object->name;

		# Remove any redundant metrics
		if ( ! exists $metrics{$name} ) {
			$object->delete;
			delete $metrics{$name};
			next;
		}

		# If the metric is unversioned, we don't need to rerun
		if ( ! defined $metrics{$name} and
		     ! defined $object->version
		) {
			delete $metrics{$name};
			next;
		}

		# Must be versioned. If plugin equals stored version,
		# then no need to rerun the metric.
		if ( defined $metrics{$name}  and
		     defined $object->version and
		     $object->version == $metrics{$name}
		) {
			delete $metrics{$name};
			next;
		}

		# To do in the next pass
		push @todo, $object;
	}

	# Shortcut return now if nothing left to do
	unless ( @todo or keys %metrics ) {
		return 1;
	}

	# Any further metrics will need the document
	my $Document = eval { $file->Document };
	if ( $@ or ! $Document ) {
		# The document has gone unparsable. If this
		# is due to a PPI upgrade breaking something, we 
		# need to flush out any existing metrics for the
		# document, then skip on to the next file
		$file->metrics->delete_all;
		return 0;
	}

	# Now we have the document, update the remaining metrics
	foreach my $object ( @todo ) {
		my $name = $object->name;

		# Versions differ, or it has changed from defined to
		# not, or back the front.
		$object->version($metrics{$name});
		my $value = $self->_metric($Document, $name);
		$object->value($value);
		$object->update;
		delete $metrics{$name};
	}

	# With the existing ones out the way, generate the new ones
	foreach my $name ( sort keys %metrics ) {
		my $value = $self->_metric($Document, $name);
		Perl::Metrics::Metric->insert( {
			hex_id  => $file->hex_id,
			package => $self->class,
			name    => $name,
			version => $metrics{$name},
			value   => $value,
			} );
	}

	1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Metrics>, L<PPI>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
