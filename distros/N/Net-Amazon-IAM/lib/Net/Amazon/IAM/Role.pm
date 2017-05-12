package Net::Amazon::IAM::Role;
use Moose;

=head1 NAME

Net::Amazon::IAM::Role

=head1 DESCRIPTION

A class representing a IAM role.

=head1 ATTRIBUTES

=over

=item Arn (required)

The Amazon Resource Name (ARN) specifying the role.

=item AssumeRolePolicyDocument (optional)

The policy that grants an entity permission to assume the role
Will be decoded to Hash from json.

=item CreateDate (required)

The date and time, in ISO 8601 date-time format, when the role was created.

=item RoleId (required)

The stable and unique string identifying the role.

=item RoleName (required)

The friendly name that identifies the role.

=item Path (required)

The path to the role. 

=back

=cut

has 'Arn' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'AssumeRolePolicyDocument' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'CreateDate' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'RoleId' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'RoleName' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'Path' => (
   is       => 'ro',
   isa      => 'Str',
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
