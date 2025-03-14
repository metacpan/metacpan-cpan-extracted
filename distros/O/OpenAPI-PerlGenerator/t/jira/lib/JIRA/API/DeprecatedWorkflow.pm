package JIRA::API::DeprecatedWorkflow 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

JIRA::API::DeprecatedWorkflow -

=head1 SYNOPSIS

  my $obj = JIRA::API::DeprecatedWorkflow->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< default >>

=cut

has 'default' => (
    is       => 'ro',
);

=head2 C<< description >>

The description of the workflow.

=cut

has 'description' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< lastModifiedDate >>

The datetime the workflow was last modified.

=cut

has 'lastModifiedDate' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< lastModifiedUser >>

This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details.

=cut

has 'lastModifiedUser' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< lastModifiedUserAccountId >>

The account ID of the user that last modified the workflow.

=cut

has 'lastModifiedUserAccountId' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< name >>

The name of the workflow.

=cut

has 'name' => (
    is       => 'ro',
    isa      => Str,
);

=head2 C<< scope >>

The scope where this workflow applies

=cut

has 'scope' => (
    is       => 'ro',
);

=head2 C<< steps >>

The number of steps included in the workflow.

=cut

has 'steps' => (
    is       => 'ro',
    isa      => Int,
);


1;
