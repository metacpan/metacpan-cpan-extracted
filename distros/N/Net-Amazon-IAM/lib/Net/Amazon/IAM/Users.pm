package Net::Amazon::IAM::Users;
use Moose;

=head1 NAME

Net::Amazon::IAM::Users

=head1 DESCRIPTION

A class representing a IAM Users list.

=head1 ATTRIBUTES

=over

=item IsTruncated (optional)

A flag that indicates whether there are more users to list. 

=item Marker (optional)

If IsTruncated is true, this element is present and contains the value to use for the 
Marker parameter in a subsequent pagination request.

=item Users (optional)

List of L<Net::Amazon::IAM::Users> objects.

=back

=cut

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

has 'Users' => (
   is       => 'ro',
   isa      => 'Maybe[ArrayRef[Net::Amazon::IAM::User]]',
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
