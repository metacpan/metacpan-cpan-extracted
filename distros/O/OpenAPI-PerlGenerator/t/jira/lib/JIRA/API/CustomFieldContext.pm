package JIRA::API::CustomFieldContext 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

JIRA::API::CustomFieldContext -

=head1 SYNOPSIS

  my $obj = JIRA::API::CustomFieldContext->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< description >>

The description of the context.

=cut

has 'description' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 C<< id >>

The ID of the context.

=cut

has 'id' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 C<< isAnyIssueType >>

Whether the context apply to all issue types.

=cut

has 'isAnyIssueType' => (
    is       => 'ro',
    required => 1,
);

=head2 C<< isGlobalContext >>

Whether the context is global.

=cut

has 'isGlobalContext' => (
    is       => 'ro',
    required => 1,
);

=head2 C<< name >>

The name of the context.

=cut

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


1;
