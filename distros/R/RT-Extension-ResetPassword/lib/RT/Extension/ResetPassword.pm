package RT::Extension::ResetPassword;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);

our $VERSION = '2.00';

sub CreateToken {
    my $user = shift;

    unless ( $user && $user->Id ) {
        RT::Logger->error( "Need to provide a loaded RT::User object for CreateToken" );
        return undef;
    }

    return sha256_hex(
        $user->id,
        $user->__Value('Password'),
        $RT::DatabasePassword,
        $user->LastUpdated,
        @{[$RT::WebPath]} . '/NoAuth/ResetPassword/Reset'
        );
}

sub CreateTokenAndResetPassword {
    my $user = shift;

    # Update the LastUpdated time in the $user so that we can
    # expire the password-change link that gets sent out.  We
    # need to do this before we create the token because $user->LastUpdated
    # is part of the token hash
    $user->_SetLastUpdated();

    my $token = CreateToken($user);
    return unless $token;     # CreateToken will log error

    my %send_options = (
        To        => $user->EmailAddress,
        Template  => 'PasswordReset',
        Arguments => {
            Token => $token,
            User  => $user,
        },
    );

    $send_options{'From'} = RT->Config->Get('ResetPasswordFromAddress')
        if RT->Config->Get('ResetPasswordFromAddress');

    my ($status, $msg) = RT::Interface::Email::SendEmailUsingTemplate(%send_options);

    return ($status, $msg);
}


# Add to RT::User for possible addition to core RT in the future.

package RT::User;

# Set the password for this user back to no value. This is useful for
# features like ResetPassword that might use the existence of a password
# to determine if a user should be allowed to reset. Also possibly useful
# for clearing old passwords after switching to different authentication
# for RT.

sub UnsetPassword {
    my $self     = shift;

    unless ( $self->CurrentUserCanModify('Password') ) {
        return ( 0, $self->loc('Password: Permission Denied') );
    }

    my ( $val, $msg ) = $self->_Set(Field => 'Password', Value => '');
    if ($val) {
        return ( 1, $self->loc("Password unset") );
    }
    else {
        return ( $val, $msg );
    }
}

package RT::Extension::ResetPassword;

=head1 NAME

RT::Extension::ResetPassword - add "forgot your password?" link to RT instance

=head1 DESCRIPTION

This extension for RT adds a new "Forgot your password?" link to the front
of your RT instance. Any user can request that RT send them a password
reset token by email.  RT will send the user a one-time URL which he or
she can use to reset her password.

It also adds a new option to the user admin page in RT for the RT admin
to send a password reset email for new users or users who have forgotten
their passwords. See below for options to enable this admin feature only
and disable self-service features.

=head1 RT VERSION

Works with RT 6.0. For previous versions of RT install the latest 1.* version.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::ResetPassword');

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

This extension resets passwords managed by RT. It cannot reset
passwords for RTs that use any configured external auth such as
SAML, OAuth, LDAP, or Active Directory as RT does not have
password reset connections in those external systems.

The contents of the email sent to users can be found in the global
PasswordReset template (do not confuse this with the core PasswordChange
template).

If you want to prevent unauthorized visitors from determining what user
accounts exist and whether they are disabled, set HidePasswordResetErrors
to 1 in your RT configuration; then any password reset request will
appear to the requestor to have resulted in an email being sent, thus
not revealing the reasons for any failure. All failures will still be
logged with an appropriate diagnostic message.

For an RT open to the internet the most secure configuration is to use the default
configuration ( This means setting no config options from below ). The default
configuration only allows for existing users with an existing password to reset
their password.

If the rights schema for the RT is tight then it could be desirable to allow users
who have a user record in RT ( They have emailed RT before ) but no password to create
a password for themselves by setting $AllowUsersWithoutPassword to 1. This can allow for
any user to access the RT self service pages. This can be dangerous if the RT rights are
not set-up correctly as users could see data they should not be able to.

The $CreateNewUserAndSetPassword and $CreateNewUserAsPrivileged config
options should only be used when access to the RT web UI is limited.
This usually means access to the web UI is restricted so that only users
on the company network can access the UI and create new user records.

=over 4

=item C<$AllowUsersWithoutPassword>

Setting this config option to true will allow existing users who do
not have a password value to send themselves a reset password email
and set a password.

Setting this to false (0) requires a user to already have a password
to use the reset feature. This is useful for managing access and
not automatically allowing new accounts to get a password.

This extension adds a "Password Status" at the bottom of the Access control
section on the user admin page which shows whether the user currently
has a password set. The "Delete password" option allows you to clear
passwords if a user should no longer have access.

For RT 4.4 and 5, this extension also adds a checkbox to the user admin page
that allows you to filter users, displaying only those who have a password
set. If you disable the C<$AllowUsersWithoutPassword> option, this checkbox
allows you to see all users who have an existing password and would
therefore be able to reset their password.

=item C<$CreateNewUserAsPrivileged>

Set this config value to true if users creating a new account should
default to privileged users.

B<WARNING> Setting this to true can be dangerous as it allows anyone to
create a new priviledged user. Usually privlidged users are given rights
to edit and see information not desired to be public.

=item C<$CreateNewUserAndSetPassword>

This configuration option determines if a nonexistant user can create an
new user record.

B<WARNING> See the note about the danger of setting this to true and
setting C<$CreateNewUserAsPrivileged> to true as well.

=item C<$DisableResetPasswordOnLogin>

Set this config value to true if you do not want the "forgot password" option
to display on the login page.

This is useful if you want only the password reset email option on the RT
user admin page, but no self-service options.

=item C<$PasswordChangeLinkExpirySeconds>

Set this config value to the time in seconds before a password-change
link expires.  The default value is 4*60*60, meaning that password-change
links expire after four hours by default.

=item C<$ResetPasswordFromAddress>

By default, the From address in the password reset email is the default
C<$CorrespondAddress> from RT. You can use this option to set a
different From address for the reset email.

=back

=cut

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ResetPassword@rt.cpan.org|mailto:bug-RT-Extension-ResetPassword@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ResetPassword>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2012-2025 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
