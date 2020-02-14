package RT::Extension::ResetPassword;

use strict;
use warnings;

our $VERSION = '1.05';

=head1 NAME

RT::Extension::ResetPassword - add "forgot your password?" link to RT instance

=head1 DESCRIPTION

This extension for RT adds a new "Forgot your password?" link to the front
of your RT instance. Any user can request that RT send them a password
reset token by email.  RT will send the user a one-time URL which he or
she can use to reset her password. This extension allows only users that
already have passwords reset their passwords by email.
There isn't yet an option to only allow privileged or unpriviliged users
to reset their passwords.

=head1 RT VERSION

Works with RT 4.0, 4.2, 4.4

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

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::ResetPassword');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ResetPassword));

or add C<RT::Extension::ResetPassword> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 UPGRADING

If you are upgrading from version 0.05, you will need to run C<make
initdb> as documented in L<INSTALLATION> to install the Template used by
this Extension.

To run on RT 4.0 or 4.2, replace this line in the template:

    { RT::Interface::Web::RequestENV('REMOTE_ADDR') }

with this:

    { $ENV{'REMOTE_ADDR'} }

=head1 CONFIGURATION

The contents of the email sent to users can be found in the global
PasswordReset template (do not confuse this with the core PasswordChange
template).

If you want to prevent unauthorised visitors from determining what user
accounts exist and whether they are disabled, set HidePasswordResetErrors
to 1 in your RT configuration; then any password reset request will
appear to the requestor to have resulted in an email being sent, thus
not revealing the reasons for any failure. All failures will still be
logged with an appropriate diagnostic message.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ResetPassword@rt.cpan.org|mailto:bug-RT-Extension-ResetPassword@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ResetPassword>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2012-2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
