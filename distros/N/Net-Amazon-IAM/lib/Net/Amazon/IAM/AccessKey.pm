package Net::Amazon::IAM::AccessKey;
use Moose;
extends 'Net::Amazon::IAM::AccessKeyMetadata';

=head1 NAME

Net::Amazon::IAM::AccessKey 

=head1 DESCRIPTION

A class representing a IAM AccessKey
This class extends L<Net::Amazon::IAM::AccessKeyMetadata>

=head1 ATTRIBUTES

=over

=item SecretAccessKey (required)

The secret key used to sign requests.

=back

=cut

has 'SecretAccessKey' => (
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
