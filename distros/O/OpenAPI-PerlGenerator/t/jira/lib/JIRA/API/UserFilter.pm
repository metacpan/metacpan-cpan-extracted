package JIRA::API::UserFilter 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

JIRA::API::UserFilter -

=head1 SYNOPSIS

  my $obj = JIRA::API::UserFilter->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< enabled >>

Whether the filter is enabled.

=cut

has 'enabled' => (
    is       => 'ro',
    required => 1,
);

=head2 C<< groups >>

User groups autocomplete suggestion users must belong to. If not provided, the default values are used. A maximum of 10 groups can be provided.

=cut

has 'groups' => (
    is       => 'ro',
    isa      => ArrayRef[Str],
);

=head2 C<< roleIds >>

Roles that autocomplete suggestion users must belong to. If not provided, the default values are used. A maximum of 10 roles can be provided.

=cut

has 'roleIds' => (
    is       => 'ro',
    isa      => ArrayRef[Int],
);


1;
