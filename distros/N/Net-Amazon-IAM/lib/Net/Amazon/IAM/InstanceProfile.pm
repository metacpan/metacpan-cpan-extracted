package Net::Amazon::IAM::InstanceProfile;
use Moose;

=head1 NAME

Net::Amazon::IAM::InstanceProfile

=head1 DESCRIPTION

A class representing a IAM Instance Profile.

=head1 ATTRIBUTES

=over

=item Arn (required)

The Amazon Resource Name (ARN) specifying the instance profile.

=item CreateDate (required)

The date when the instance profile was created.

=item InstanceProfileId (required)

The stable and unique string identifying the instance profile.

=item InstanceProfileName (required)

The name identifying the instance profile.

=item Path (required)

The path to the instance profile.

=item Roles (required)

List of roles associated with the instance profile represented as L<Net::Amazon::IAM::Roles>.

=back

=cut

has 'Arn' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'CreateDate' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'InstanceProfileId' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'InstanceProfileName' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'Path' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'Roles' => (
   is       => 'ro',
   isa      => 'Maybe[Net::Amazon::IAM::Roles]|HashRef',
   required => 1,
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
