# A class representing a flights response from the OpenSky Network API

package OpenSky::API::Flights;

our $VERSION = '0.004';
use Moose;
use OpenSky::API::Types qw(InstanceOf);
use OpenSky::API::Core::Flight;
use OpenSky::API::Utils::Iterator;
use experimental qw(signatures);

has flights => (
    is      => 'ro',
    isa     => InstanceOf ['OpenSky::API::Utils::Iterator'],
    handles => [qw(first next reset all count)],
);

around 'BUILDARGS' => sub ( $orig, $class, $response ) {
    my @flights  = map { OpenSky::API::Core::Flight->new($_) } $response->@*;
    my $iterator = OpenSky::API::Utils::Iterator->new( rows => \@flights );

    return $class->$orig( flights => $iterator );
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSky::API::Flights

=head1 VERSION

version 0.004

=head1 METHODS

=head2 flights

Returns an iterator of L<OpenSky::API::Core::Flight> objects.

As a convenience, the following methods are delegated to the iterator:

=over 4

=item * first

=item * next

=item * reset

=item * all

=item * count

=back

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
