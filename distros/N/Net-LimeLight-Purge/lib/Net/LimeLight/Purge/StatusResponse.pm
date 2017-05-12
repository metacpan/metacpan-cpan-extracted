package Net::LimeLight::Purge::StatusResponse;
use Moose;
use MooseX::AttributeHelpers;

=head1 NAME

Net::LimeLight::Purge::StatusResponse - Results of Purge Status Request

=head1 METHODS

=head2 completed_entries

Get the number of completed purge entries.

=cut

has 'completed_entries' => (
    is => 'rw',
    isa => 'Int',
    default => sub { 0 }
);

has 'statuses' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef[Net::LimeLight::Purge::Request]',
    default => sub { [] },
    provides => {
        push => 'add_request'
    }
);

=head2 total_entries

Get the total number of purge entries.

=cut

has 'total_entries' => (
    is => 'rw',
    isa => 'Int',
    default => sub { 0 }
);

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cory G Watson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

