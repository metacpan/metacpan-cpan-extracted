package Net::Amazon::IAM::MFADevice;
use Moose;

=head1 NAME

Net::Amazon::IAM::MFADevice

=head1 DESCRIPTION

Contains information about an MFA device.

=head1 ATTRIBUTES

=over

=item EnableDate (optional)

The date when the MFA device was enabled for the user.

=item SerialNumber (required)

The serial number that uniquely identifies the MFA device. 
For virtual MFA devices, the serial number is the device ARN.

=item UserName (required)

The user with whom the MFA device is associated.

=back

=cut

has 'EnableDate' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'SerialNumber' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'UserName' => (
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
