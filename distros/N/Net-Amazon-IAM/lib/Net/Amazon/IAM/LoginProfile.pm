package Net::Amazon::IAM::LoginProfile;
use Moose;

=head1 NAME

Net::Amazon::IAM::LoginProfile

=head1 DESCRIPTION

A class representing a IAM login profile.

=head1 ATTRIBUTES

=over

=item CreateDate (required)

The date when the password for the user was created.

=item PasswordResetRequired (optional)

Specifies whether the user is required to set a new password on next sign-in.

=item UserName (required)

The name of the user, which can be used for signing in to the AWS Management Console.

=back

=cut

has 'CreateDate' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
);

has 'PasswordResetRequired' => (
   is       => 'ro',
   isa      => 'Maybe[Str]',
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
