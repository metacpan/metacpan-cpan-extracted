package Net::LimeLight::Purge::Request;
use Moose;

=head1 NAME

Net::LimeLight::Purge::Request - A request to purge a URL

=head1 METHODS

=head1 batch_number

The batch number this request was a part of.

=cut

has 'batch_number' => (
    is => 'rw',
    isa => 'Int',
);


=head1 completed

Flag that indicates if this request has been completed.

=cut

has 'completed' => (
    is => 'rw',
    isa => 'Bool',
    default => sub { 0 }
);

=head1 completed_date

The date which this request was completed, if any.

=cut

has 'completed_date' => (
    is => 'rw',
    isa => 'DateTime',
);

=head1 regex

Flag that indicates if this request's URL should be matched as a regular
expression.

=cut

has 'regex' => (
    is => 'rw',
    isa => 'Bool',
    default => sub { 0 }
);


=head2 shortname

The shortname that identifies the account from which to purge.

=cut

has 'shortname' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

=head2 url

The URL to purge

=cut

has 'url' => (
    is => 'rw',
    isa => 'Str',
    required => 1
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
