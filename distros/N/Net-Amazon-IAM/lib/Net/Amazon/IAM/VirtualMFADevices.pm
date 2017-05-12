package Net::Amazon::IAM::VirtualMFADevices;
use Moose;

=head1 NAME

Net::Amazon::IAM::VirtualMFADevices

=head1 DESCRIPTION

A class representing a IAM Virtual MFA Devices list.

=head1 ATTRIBUTES

=over

=item VirtualMFADevices (optional)
   
List of L<Net::Amazon::IAM::VirtualMFADevice> objects.

=item IsTruncated (optional)
   
A flag that indicates whether there are more devices to list. 
If your results were truncated, you can make a subsequent pagination 
request using the Marker request parameter to retrieve more devices in the list.

=item Marker (optional)
   
If IsTruncated is true, this element is present and contains the value to use for the 
Marker parameter in a subsequent pagination request.

=back

=cut

has 'VirtualMFADevices' => (
   is       => 'ro',
   isa      => 'Maybe[ArrayRef[Net::Amazon::IAM::VirtualMFADevice]]',
   required => 0,
);

has 'IsTruncated' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'Marker' => (
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
