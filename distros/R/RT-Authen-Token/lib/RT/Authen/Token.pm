package RT::Authen::Token;
use strict;
use warnings;

our $VERSION = '0.02';

RT::System->AddRight(Staff => ManageAuthTokens => 'Manage authentication tokens');

use RT::AuthToken;
use RT::AuthTokens;

RT->AddStyleSheets("rt-authen-token.css");
RT->AddJavaScript("rt-authen-token.js");

sub UserForAuthString {
    my $self = shift;
    my $authstring = shift;
    my $user = shift;

    my ($user_id, $cleartext_token) = RT::AuthToken->ParseAuthString($authstring);
    return unless $user_id;

    my $user_obj = RT::CurrentUser->new;
    $user_obj->Load($user_id);
    return if !$user_obj->Id || $user_obj->Disabled;

    if (length $user) {
        my $check_user = RT::CurrentUser->new;
        $check_user->Load($user);
        return unless $check_user->Id && $user_obj->Id == $check_user->Id;
    }

    my $tokens = RT::AuthTokens->new(RT->SystemUser);
    $tokens->LimitOwner(VALUE => $user_id);
    while (my $token = $tokens->Next) {
        if ($token->IsToken($cleartext_token)) {
            $token->UpdateLastUsed;
            return ($user_obj, $token);
        }
    }

    return;
}

=head1 NAME

RT-Authen-Token - token-based authentication

=head1 DESCRIPTION

This module adds the ability for users to generate and login with
authentication tokens. Users with the C<ManageAuthTokens> permission
will see a new "Auth Tokens" menu item under "Logged in as ____" ->
Settings. On that page they will be able to generate new tokens and
modify or revoke existing tokens.

Once you have an authentication token, you may use it in place of a
password to log into RT. (Additionally, L<RT::Extension::REST2> allows
for using auth tokens with the C<Authorization: token> HTTP header.) One
common use case is to use an authentication token as an
application-specific password, so that you may revoke that application's
access without disturbing other applications. You also need not change
your password, since the application never received it.

If you have the C<AdminUsers> permission, along with
C<ManageAuthTokens>, you may generate, modify, and revoke tokens for
other users as well by visiting Admin -> Users -> Select -> (user) ->
Auth Tokens.

Authentication tokens are stored securely (hashed and salted) in the
database just like passwords, and so cannot be recovered after they are
generated.

=head1 INSTALLATION

RT-Authen-Token requires version RT 4.2.5 or later.

=over

=item perl Makefile.PL

=item make

=item make install

This step may require root permissions.

=item make initdb

Only run this the first time you install this module.

If you run this twice, you will end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Plugin( "RT::Authen::Token" );

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Authen-Token@rt.cpan.org|mailto:bug-RT-Authen-Token@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Authen-Token>.

=head1 COPYRIGHT

This extension is Copyright (C) 2017 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
