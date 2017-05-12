package Net::Amazon::IAM::User;
use Moose;

=head1 NAME

Net::Amazon::IAM::User

=head1 DESCRIPTION

A class representing a IAM User

=head1 ATTRIBUTES

=over

=item Arn (optional)

The Amazon Resource Name (ARN) that identifies the user.
See http://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html

=item CreateDate (optional)

User creation date and time

=item PasswordLastUsed (optional)

When user last time used his password (if used).

=item Path (optional)

Where User was placed.

=item UserId (optional)

IAM user ID.

=item UserName (required)

Just a user name.

=back

=cut

has 'Arn' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'CreateDate' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'PasswordLastUsed' => (
   is       => 'ro',
   isa      => 'Maybe[Str]',
   required => 0,
);

has 'Path' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'UserId' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
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
