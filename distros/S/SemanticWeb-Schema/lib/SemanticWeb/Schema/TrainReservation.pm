package SemanticWeb::Schema::TrainReservation;

# ABSTRACT: A reservation for train travel

use Moo;

extends qw/ SemanticWeb::Schema::Reservation /;


use MooX::JSON_LD 'TrainReservation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TrainReservation - A reservation for train travel

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html A reservation for train travel.</p> <p>Note: This type is for information
about actual reservations, e.g. in confirmation emails or HTML pages with
individual confirmations of reservations. For offers of tickets, use <a
class="localLink" href="http://schema.org/Offer">Offer</a>.

=head1 SEE ALSO

L<SemanticWeb::Schema::Reservation>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
