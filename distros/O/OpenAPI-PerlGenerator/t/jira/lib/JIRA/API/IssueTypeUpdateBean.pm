package JIRA::API::IssueTypeUpdateBean 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

JIRA::API::IssueTypeUpdateBean -

=head1 SYNOPSIS

  my $obj = JIRA::API::IssueTypeUpdateBean->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< avatarId >>

The ID of an issue type avatar.

=cut

has 'avatarId' => (
    is       => 'ro',
    isa      => Int,
);

=head2 C<< description >>

The description of the issue type.

=cut

has 'description' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< name >>

The unique name for the issue type. The maximum length is 60 characters.

=cut

has 'name' => (
    is       => 'ro',
    isa      => Str,
);


1;
