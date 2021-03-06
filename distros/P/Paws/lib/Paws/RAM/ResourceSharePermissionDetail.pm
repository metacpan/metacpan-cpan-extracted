package Paws::RAM::ResourceSharePermissionDetail;
  use Moose;
  has Arn => (is => 'ro', isa => 'Str', request_name => 'arn', traits => ['NameInRequest']);
  has CreationTime => (is => 'ro', isa => 'Str', request_name => 'creationTime', traits => ['NameInRequest']);
  has DefaultVersion => (is => 'ro', isa => 'Bool', request_name => 'defaultVersion', traits => ['NameInRequest']);
  has LastUpdatedTime => (is => 'ro', isa => 'Str', request_name => 'lastUpdatedTime', traits => ['NameInRequest']);
  has Name => (is => 'ro', isa => 'Str', request_name => 'name', traits => ['NameInRequest']);
  has Permission => (is => 'ro', isa => 'Str', request_name => 'permission', traits => ['NameInRequest']);
  has ResourceType => (is => 'ro', isa => 'Str', request_name => 'resourceType', traits => ['NameInRequest']);
  has Version => (is => 'ro', isa => 'Str', request_name => 'version', traits => ['NameInRequest']);
1;

### main pod documentation begin ###

=head1 NAME

Paws::RAM::ResourceSharePermissionDetail

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::RAM::ResourceSharePermissionDetail object:

  $service_obj->Method(Att1 => { Arn => $value, ..., Version => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::RAM::ResourceSharePermissionDetail object:

  $result = $service_obj->Method(...);
  $result->Att1->Arn

=head1 DESCRIPTION

Information about an AWS RAM permission.

=head1 ATTRIBUTES


=head2 Arn => Str

  The ARN of the permission.


=head2 CreationTime => Str

  The date and time when the permission was created.


=head2 DefaultVersion => Bool

  The identifier for the version of the permission that is set as the
default version.


=head2 LastUpdatedTime => Str

  The date and time when the permission was last updated.


=head2 Name => Str

  The name of the permission.


=head2 Permission => Str

  The permission's effect and actions in JSON format. The C<effect>
indicates whether the actions are allowed or denied. The C<actions>
list the API actions to which the principal is granted or denied
access.


=head2 ResourceType => Str

  The resource type to which the permission applies.


=head2 Version => Str

  The identifier for the version of the permission.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::RAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

