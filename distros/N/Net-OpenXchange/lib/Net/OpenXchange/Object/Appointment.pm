use Modern::Perl;
package Net::OpenXchange::Object::Appointment;
BEGIN {
  $Net::OpenXchange::Object::Appointment::VERSION = '0.001';
}

use Moose;
use namespace::autoclean;

# ABSTRACT: OpenXchange appointment object

with qw(
  Net::OpenXchange::Object
  Net::OpenXchange::Data::Common
  Net::OpenXchange::Data::TaskAppointment
);

# Seperated in two blocks because Data::Appointment requires
# an attribute that is defined by Data::TaskAppointment

with 'Net::OpenXchange::Data::Appointment';

__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Object::Appointment - OpenXchange appointment object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Object::User consumes the following roles. Look at their
documentation for provided methods and attributes.

=over 4

=item *

L<Net::OpenXchange::Object|Net::OpenXchange::Object>

=item *

L<Net::OpenXchange::Data::Common|Net::OpenXchange::Data::Common>

=item *

L<Net::OpenXchange::Data::TaskAppointment|Net::OpenXchange::Data::TaskAppointment>

=back

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

