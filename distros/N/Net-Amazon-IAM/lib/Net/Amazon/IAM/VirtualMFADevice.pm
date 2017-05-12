package Net::Amazon::IAM::VirtualMFADevice;
use Moose;

=head1 NAME

Net::Amazon::IAM::VirtualMFADevice

=head1 DESCRIPTION

Contains information about a virtual MFA device.

=head1 ATTRIBUTES

=over

=item Base32StringSeed (optional)

The Base32 seed defined as specified in RFC3548. The Base32StringSeed is Base64-encoded.

=item EnableDate (optional)

The date and time on which the virtual MFA device was enabled.

=item QRCodePNG (optional)

A QR code PNG image that encodes 
otpauth://totp/$virtualMFADeviceName@$AccountName?secret=$Base32String 
where $virtualMFADeviceName is one of the create call arguments, 
AccountName is the user name if set (otherwise, the account ID otherwise), 
and Base32String is the seed in Base32 format. The Base32String value is Base64-encoded.

=item SerialNumber (required)

The serial number associated with VirtualMFADevice.

=item User (required)

Contains information about an IAM user entity. 

=back

=cut

has 'Base32StringSeed' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'EnableDate' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'QRCodePNG' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'SerialNumber' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'User' => (
   is       => 'ro',
   isa      => 'Maybe[Net::Amazon::IAM::User]',
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
