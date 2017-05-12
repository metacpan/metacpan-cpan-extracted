use Modern::Perl;
package Net::OpenXchange::Data::TaskAppointment;
BEGIN {
  $Net::OpenXchange::Data::TaskAppointment::VERSION = '0.001';
}

use Moose::Role;
use namespace::autoclean;

# ABSTRACT: OpenXchange detailed task and appointment data

use Moose::Util::TypeConstraints;
use Readonly;

Readonly my $MICROSECOND => 1000;

class_type 'DateTime';

coerce 'DateTime' => from 'Int' =>
  via { DateTime->from_epoch(epoch => $_ / $MICROSECOND) };

has title => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 200,
);

has start_date => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'DateTime',
    ox_id  => 201,
    coerce => 1,
);

has end_date => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'DateTime',
    ox_id  => 202,
    coerce => 1,
);

1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Data::TaskAppointment - OpenXchange detailed task and appointment data

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Data::TaskAppointment is a role providing attributes for
L<Net::OpenXchange::Object|Net::OpenXchange::Object> packages.

=head1 ATTRIBUTES

=head2 title (Str)

Title of this task or appointment

=head2 start_date (DateTime)

Starting date for this tak or appointment

=head2 end_date (DateTime)

Ending date for this tak or appointment

=head1 SEE ALSO

L<http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedTaskAndAppointmentData|http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedTaskAndAppointmentData>

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

