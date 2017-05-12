package Perl::Metrics2::Plugin;

=pod

=head1 NAME

Perl::Metrics2::Plugin - Base class for Perl::Metrics Plugins

=head1 SYNOPSIS

  # Implement a simple metrics package which counts up the
  # use of each type of magic variable.
  package Perl::Metrics2::Plugin::Magic;
  
  use base 'Perl::Metrics2::Plugin';
  
  # Creates the metric 'all_magic'.
  # The total number of magic variables. 
  sub metric_all_magic {
      my ($self, $document) = @_;
      return scalar grep { $_->isa('PPI::Token::Magic') }
                    $document->tokens;
  }
  
  # The number of $_ "scalar_it" magic vars
  sub metric_scalar_it {
      my ($self, $document) = @_;
      return scalar grep { $_->content eq '$_' }
                    grep { $_->isa('PPI::Token::Magic') }
                    $document->tokens;
  }
  
  # ... and so on, and so forth.
  
  1;

=head1 DESCRIPTION

The L<Perl::Metrics> system does not in and of itself generate any actual
metrics data, it merely acts as a processing and storage engine.

The generation of the actual metrics data is done via metrics packages,
which as implemented as C<Perl::Metrics2::Plugin> sub-classes.

=head2 Implementing Your Own Metrics Package

Implementing a metrics package is pretty easy.

First, create a Perl::Metrics2::Plugin::Something package, inheriting
from C<Perl::Metrics2::Plugin>.

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
use Params::Util     qw{ _IDENTIFIER _INSTANCE };
use Perl::Metrics2   ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.06';
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
	my $self  = bless { }, $class;
	return $self;
}

=pod

=head2 class

A convenience method to get the class for the plugin object,
to avoid having to use ref directly (and making the intent of
any code a little clearer).

=cut

sub class { ref $_[0] || $_[0] }

=pod

=head2 destructive

The destructive method is used by the plugin to indicate that the PPI
document passed in will be altered during the metric generation.

The value is used by the metrics engine to optimise document cloning and
reduce the number of expensive cloning to a minimum.

This value defaults to true for safety reasons, and should be overridden
in your subclass if your metrics are not destructive.

=cut

sub destructive { 1 }





#####################################################################
# Perl::Metrics2::Plugin API

# Flush out old records
sub flush {
	my $self    = shift;
	my $class   = $self->class;
	my $version = $class->VERSION;
	Perl::Metrics2->do(
		'delete from file_metric where package = ? and version = ?',
		{}, $class, $version,
	);
}

sub process_document {
	my $self     = shift;
	my $class    = ref $self;
	my %params   = @_;
	my $document = $params{document};
	my $md5      = $params{md5};
	my $hintsafe = $params{hintsafe};
	unless ( _INSTANCE($document, 'PPI::Document') ) {
		Carp::croak("Did not provide a PPI::Document object");
	}

	# Generate the new metrics values
	my %metric = $self->process_metrics($document);

	# Flush out the old records and write the new metrics
	unless ( $hintsafe ) {
		# This can be an expensive call.
		# The hintsafe optional param lets the parent
		# indicate that this check is not required.
		Perl::Metrics2::FileMetric->delete(
			'where md5 = ? and package = ?',
			$md5, $class,
		);
	}

	# Temporary accelerate version
	SCOPE: {
		my $sth = Perl::Metrics2->dbh->prepare(
			'INSERT INTO file_metric ( md5, package, version, name, value ) VALUES ( ?, ?, ?, ?, ? )'
		);
		foreach my $name ( sort keys %metric ) {
			$sth->execute( $md5, $class, $class->VERSION, $name, $metric{$name} );
		}
		$sth->finish;
	}

	return 1;
}

sub process_metrics {
	my $class = ref($_[0]) || $_[0];
	die "Plugin $class does not implement process_metrics";
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics2>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Metrics>, L<PPI>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
