package Net::Amazon::IAM::AccessKeyMetadata;
use Moose;

=head1 NAME

Net::Amazon::IAM::AccessKeyMetadata

=head1 DESCRIPTION

A class representing a IAM Access Key metadata

=head1 ATTRIBUTES

=over

=item AccessKeyId (optional)

The ID for this access key.

=item CreateDate (optional)

The date when the access key was created.

=item Status (optional)

The status of the access key. Active means the key is valid for API calls, while Inactive means it is not.

=item UserName (optional)

The name of the IAM user that the access key is associated with.

=back

=cut

has 'AccessKeyId' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'CreateDate' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'Status' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'UserName' => (
   is       => 'ro',
   isa      => 'Str',
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
