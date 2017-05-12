package Net::Amazon::IAM::Group;
use Moose;

=head1 NAME

Net::Amazon::IAM::Group

=head1 DESCRIPTION

A class representing a IAM Group.

=head1 ATTRIBUTES

=over

=item Arn (required)

The Amazon Resource Name (ARN) specifying the group.

=item CreateDate (required)

The date and time, in ISO 8601 date-time format, when the group was created.

=item GroupId (required)

The stable and unique string identifying the group.

=item GroupName (required)

The friendly name that identifies the group.

=item Path (required)

The path to the group. 

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

has 'GroupId' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'GroupName' => (
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
