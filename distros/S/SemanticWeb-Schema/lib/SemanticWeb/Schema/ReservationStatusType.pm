package SemanticWeb::Schema::ReservationStatusType;

# ABSTRACT: Enumerated status values for Reservation.

use Moo;

extends qw/ SemanticWeb::Schema::Enumeration /;


use MooX::JSON_LD 'ReservationStatusType';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ReservationStatusType - Enumerated status values for Reservation.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

Enumerated status values for Reservation.

=head1 SEE ALSO

L<SemanticWeb::Schema::Enumeration>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
