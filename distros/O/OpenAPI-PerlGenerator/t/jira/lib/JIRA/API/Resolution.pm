package JIRA::API::Resolution 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

JIRA::API::Resolution -

=head1 SYNOPSIS

  my $obj = JIRA::API::Resolution->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< description >>

The description of the issue resolution.

=cut

has 'description' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< id >>

The ID of the issue resolution.

=cut

has 'id' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< name >>

The name of the issue resolution.

=cut

has 'name' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< self >>

The URL of the issue resolution.

=cut

has 'self' => (
    is       => 'ro',
    isa      => Str,
);


1;
