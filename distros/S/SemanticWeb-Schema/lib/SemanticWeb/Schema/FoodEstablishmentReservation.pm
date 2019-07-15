use utf8;

package SemanticWeb::Schema::FoodEstablishmentReservation;

# ABSTRACT: A reservation to dine at a food-related business

use Moo;

extends qw/ SemanticWeb::Schema::Reservation /;


use MooX::JSON_LD 'FoodEstablishmentReservation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has end_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'endTime',
);



has party_size => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'partySize',
);



has start_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'startTime',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::FoodEstablishmentReservation - A reservation to dine at a food-related business

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A reservation to dine at a food-related business.<br/><br/> Note: This type
is for information about actual reservations, e.g. in confirmation emails
or HTML pages with individual confirmations of reservations.

=head1 ATTRIBUTES

=head2 C<end_time>

C<endTime>

=for html The endTime of something. For a reserved event or service (e.g.
FoodEstablishmentReservation), the time that it is expected to end. For
actions that span a period of time, when the action was performed. e.g.
John wrote a book from January to <em>December</em>. For media, including
audio and video, it's the time offset of the end of a clip within a larger
file.<br/><br/> Note that Event uses startDate/endDate instead of
startTime/endTime, even when describing dates with times. This situation
may be clarified in future revisions.

A end_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<party_size>

C<partySize>

Number of people the reservation should accommodate.

A party_size should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<start_time>

C<startTime>

=for html The startTime of something. For a reserved event or service (e.g.
FoodEstablishmentReservation), the time that it is expected to start. For
actions that span a period of time, when the action was performed. e.g.
John wrote a book from <em>January</em> to December. For media, including
audio and video, it's the time offset of the start of a clip within a
larger file.<br/><br/> Note that Event uses startDate/endDate instead of
startTime/endTime, even when describing dates with times. This situation
may be clarified in future revisions.

A start_time should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Reservation>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
