package JIRA::API::Group 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

JIRA::API::Group -

=head1 SYNOPSIS

  my $obj = JIRA::API::Group->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< expand >>

Expand options that include additional group details in the response.

=cut

has 'expand' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< groupId >>

The ID of the group, which uniquely identifies the group across all Atlassian products. For example, *952d12c3-5b5b-4d04-bb32-44d383afc4b2*.

=cut

has 'groupId' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< name >>

The name of group.

=cut

has 'name' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< self >>

The URL for these group details.

=cut

has 'self' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< users >>

A paginated list of the users that are members of the group. A maximum of 50 users is returned in the list, to access additional users append `[start-index:end-index]` to the expand request. For example, to access the next 50 users, use`?expand=users[51:100]`.

=cut

has 'users' => (
    is       => 'ro',
);


1;
