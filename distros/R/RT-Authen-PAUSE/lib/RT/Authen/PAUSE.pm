=head1 NAME

RT::Authen::PAUSE - authenticate RT users against PAUSE

=head1 DESCRIPTION

This RT extension allows people to login into RT using their CPAN ID and
passwords by proxing requests to PAUSE.  This extension doesn't import user
entries from CPAN or other Perl related sources, so you have to do it yourself.

People still can change their passwords in RT, if they have the ModifySelf
right.  They will be able to use the new password in RT, however we don't push
changes back to PAUSE.

=cut

package RT::Authen::PAUSE;

our $VERSION = '0.11';

1;

=head1 COPYRIGHT

This extension is Copyright (C) 2005-2013 Best Practical Solutions, LLC.

It is freely redistributable under the terms of version 2 of the GNU GPL.

=cut

