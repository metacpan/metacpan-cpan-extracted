package Net::Amazon::IAM::Policy;
use Moose;

=head1 NAME

Net::Amazon::IAM::Policy

=head1 DESCRIPTION

A class representing a IAM Policy

=head1 ATTRIBUTES

=over

=item Arn (optional)

The Amazon Resource Name (ARN) that identifies the user.
See http://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html

=item AttachmentCount (optional)

The number of entities (users, groups, and roles) that the policy is attached to.

=item CreateDate (optional)

The date and time, in ISO 8601 date-time format, when the policy was created.

=item DefaultVersionId (optional)

The identifier for the version of the policy that is set as the default version.

=item Description (optional)

A friendly description of the policy.

=item IsAttachable (optional)

Specifies whether the policy can be attached to an IAM user, group, or role.

=item Path (optional)

The path to the policy.

=item PolicyId (optional)

The stable and unique string identifying the policy.

=item PolicyName (optional)

The friendly name (not ARN) identifying the policy.

=item UpdateDate (optional)

The date and time, in ISO 8601 date-time format, when the policy was last updated.

=back

=cut

has 'Arn' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'AttachmentCount' => (
   is       => 'ro',
   isa      => 'Int',
   required => 0,
);

has 'CreateDate' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'DefaultVersionId' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'Description' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'IsAttachable' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'Path' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'PolicyId' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'PolicyName' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'UpdateDate' => (
   is       => 'ro',
   isa      => 'Maybe[Str]',
   required => 0,
);

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Igor Tsigankov <tsiganenok@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2015 Igor Tsigankov . This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;
