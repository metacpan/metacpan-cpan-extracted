=head1 NAME

Probe::MachineInfo::Metric - Base clas for metric collectors

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 PUBLIC INTERFACE

=cut

package Probe::MachineInfo::Metric;


# pragmata
use overload '""' => 'print';
use strict;
use warnings;


# Standard Perl Library and CPAN modules
use Log::Log4perl;

#
# CLASS ATTRIBUTES
#

#
# CONSTRUCTOR
#

=head2 new

 new(%options)

=cut

sub new {
    my ($class, %options) = @_;

    my $self = {
			log => Log::Log4perl->get_logger($class),
		};

    bless $self, $class;
		return $self->_init(%options) if($self->can('_init'));
		return $self;
}

=head2 get

 get()

Proceeds to collect information about the machine by calling the _get_*_info methods.

=cut

sub get {
	my ($self) = @_;

	die("Abstract Method\n");
}

=head2 log

 log()

=cut

sub log {
	my($self) = @_;

	return $self->{log};
}

=head2 print

 print()

Returns a string representing the metric. This is the metric name plus any units if specified by the subclass.

This method does not need to be called directly as the stringification operator is overloaded by this method.

=cut

sub print {
	my ($self) = @_;

	my $value = $self->get();
	my $units = $self->units();
	return ($units) ? "$value $units" : $value;
}

=head2 units

 units()

Returns the units in which the metric is in

=cut

sub units {
	my ($self) = @_;

	return '';
}

1;

=head1 AUTHOR

Sagar R. Shah

=cut
