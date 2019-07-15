use utf8;

package SemanticWeb::Schema::TrainTrip;

# ABSTRACT: A trip on a commercial train line.

use Moo;

extends qw/ SemanticWeb::Schema::Trip /;


use MooX::JSON_LD 'TrainTrip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has arrival_platform => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'arrivalPlatform',
);



has arrival_station => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'arrivalStation',
);



has departure_platform => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'departurePlatform',
);



has departure_station => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'departureStation',
);



has train_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'trainName',
);



has train_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'trainNumber',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TrainTrip - A trip on a commercial train line.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A trip on a commercial train line.

=head1 ATTRIBUTES

=head2 C<arrival_platform>

C<arrivalPlatform>

The platform where the train arrives.

A arrival_platform should be one of the following types:

=over

=item C<Str>

=back

=head2 C<arrival_station>

C<arrivalStation>

The station where the train trip ends.

A arrival_station should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::TrainStation']>

=back

=head2 C<departure_platform>

C<departurePlatform>

The platform from which the train departs.

A departure_platform should be one of the following types:

=over

=item C<Str>

=back

=head2 C<departure_station>

C<departureStation>

The station from which the train departs.

A departure_station should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::TrainStation']>

=back

=head2 C<train_name>

C<trainName>

The name of the train (e.g. The Orient Express).

A train_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<train_number>

C<trainNumber>

The unique identifier for the train.

A train_number should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Trip>

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
