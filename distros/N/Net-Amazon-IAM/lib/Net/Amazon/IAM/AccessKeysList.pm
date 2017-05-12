package Net::Amazon::IAM::AccessKeysList;
use Moose;

=head1 NAME

Net::Amazon::IAM::AccessKeysList

=head1 DESCRIPTION

A class representing a IAM Access Keys List

=head1 ATTRIBUTES

=over

=item Keys (required)

Array of L<Net::Amazon::IAM::AccessKeyMetadata>

=back

=cut

has 'Keys' => (
   is       => 'ro',
   isa      => 'Maybe[ArrayRef[Net::Amazon::IAM::AccessKeyMetadata]]',
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
