package RT::Extension::Captcha;

use 5.008003;
use strict;
use warnings;

our $VERSION = '2.00';

=head1 NAME

RT::Extension::Captcha - use Google reCAPTCHA v3 to verify users before some actions in RT

=head1 DESCRIPTION

This extension uses Google reCAPTCHA v3 for user verification when a user
creates a ticket (using either regular interface or quick create) and on
replies/comments (updates).

Previous 1.* versions of this extension generated a captcha image for the user
to solve. With the switch to Google reCAPTCHA v3 the user will no longer be
interrupted by a captcha image.

=head1 RT VERSION

Works with RT 6.0.0 and newer. Install the latest 1.* version for older RTs.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::Captcha');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=head2 No CAPTCHA rights

Users who have right 'NoCaptchaOnCreate' or 'NoCaptchaOnUpdate' will not have
any user verification done on corresponding actions.

=head2 Create Google reCAPTCHA key

To create a reCAPTCHA key see L<here|https://cloud.google.com/recaptcha/docs/create-key-website>

=head2 $CaptchaSiteKey

Set your Google reCAPTCHA site key. This is required.

    Set( $CaptchaSiteKey, '...' );

=head2 $CaptchaSecret

Set your Google reCAPTCHA secret key. This is required.

    Set( $CaptchaSecret, '...' );

=head2 $CaptchaScore

Set the minimum score to verify a user. This is optional and must be a value
between 0 and 1. It defaults to 0.5.

The higher the score the more likely the user is real. Setting a higher value
for CaptchaScore means it is harder for robots to fool the verification but
also makes it more possible a real user might fail verification.

    Set( $CaptchaScore, 0.4 );

=cut

RT->AddStyleSheets( 'rt-extension-captcha.css' );

require RT::Queue;
RT::Queue->AddRight( Staff => NoCaptchaOnCreate => "Don't ask user to solve a CAPTCHA on ticket create" ); #loc_pair
RT::Queue->AddRight( Staff => NoCaptchaOnUpdate => "Don't ask user to solve a CAPTCHA on ticket reply or comment" ); #loc_pair

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-Captcha@rt.cpan.org|mailto:bug-RT-Extension-Captcha@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-Captcha>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014-2025 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
