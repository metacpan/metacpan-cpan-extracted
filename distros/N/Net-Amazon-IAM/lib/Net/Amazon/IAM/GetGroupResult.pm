package Net::Amazon::IAM::GetGroupResult;
use Moose;

=head1 NAME

Net::Amazon::IAM::GetGroupResult

=head1 DESCRIPTION

A class representing a get_group response.

=head1 ATTRIBUTES

=over

=item IsTruncated (optional)

A flag that indicates whether there are more user names to list. 
If your results were truncated, you can make a subsequent pagination request 
using the Marker request parameter to retrieve more user names in the list.

=item Marker (optional)

If IsTruncated is true, then this element is present and contains the value 
to use for the Marker parameter in a subsequent pagination request.

=item Users (optional)

Will be list of L<Net::Amazon::IAM::User>.

=item Group (optional)

Will be L<Net::Amazon::IAM::Group>.

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

has 'Group' => (
   is       => 'ro',
   isa      => 'Net::Amazon::IAM::Group',
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
