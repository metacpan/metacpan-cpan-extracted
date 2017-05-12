use Modern::Perl;
package Net::OpenXchange::Data::Appointment;
BEGIN {
  $Net::OpenXchange::Data::Appointment::VERSION = '0.001';
}

use Moose::Role;
use namespace::autoclean;

# ABSTRACT: OpenXchange detailed appointment data

use Net::OpenXchange::Types;

has location => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 400,
);

has full_time => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Bool',
    coerce => 1,
    ox_id  => 401,
);

requires qw(start_date end_date);

sub BUILD {
    my ($self) = @_;
    if ($self->full_time) {
        $self->start_date->truncate(to => 'day');
        $self->end_date->truncate(to => 'day');
    }
    return;
}

1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Data::Appointment - OpenXchange detailed appointment data

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Data::Appointment is a role providing attributes for
L<Net::OpenXchange::Object|Net::OpenXchange::Object> packages.

=head1 ATTRIBUTES

=head2 location (Str)

Location of the appointment.

=head2 full_time (Bool)

Indicates if the appointment takes the whole day or has a start and end time. If full_time is true
on object creation, start_date and end_date will be truncated to their date value.

=for Pod::Coverage BUILD

=head1 SEE ALSO

L<http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedAppointmentData|http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedAppointmentData>

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

