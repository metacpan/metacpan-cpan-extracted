
package Paws::Greengrass::CreateGroupVersionResponse;
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has CreationTimestamp => (is => 'ro', isa => 'Str');
  has Id => (is => 'ro', isa => 'Str');
  has Version => (is => 'ro', isa => 'Str');

  has _request_id => (is => 'ro', isa => 'Str');
1;

### main pod documentation begin ###

=head1 NAME

Paws::Greengrass::CreateGroupVersionResponse

=head1 ATTRIBUTES


=head2 Arn => Str

The ARN of the version.


=head2 CreationTimestamp => Str

The time, in milliseconds since the epoch, when the version was
created.


=head2 Id => Str

The ID of the parent definition that the version is associated with.


=head2 Version => Str

The ID of the version.


=head2 _request_id => Str


=cut

