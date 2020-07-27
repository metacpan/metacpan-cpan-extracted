package RT::Extension::Captcha;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.21';

use GD::SecurityImage;

=head1 NAME

RT::Extension::Captcha - solve a CAPTCHA before some actions in RT

=head1 DESCRIPTION

This extension is for RT 4.2 or newer.  It requires solving captchas
when a user creates a ticket (using either regular interface or quick
create) and on replies/comments (updates).

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

Users who have right 'NoCaptchaOnCreate' or 'NoCaptchaOnUpdate'
will see no captchas on corresponding actions.

=head2 Font

As GD's builtin font is kinda small. A ttf font is used instead.
By default font defined by ChartFont option (RT's option to set
fonts for charts) is used for CAPTCHA images.

As well, you can set font for cpatchas only using L</%Captcha option>
described below.

=head2 %Captcha option

See F<etc/Captcha_Config.pm> for defaults and example. C<%Captcha>
option is a hash. Now, only ImageProperties key has meaning:

    Set(%Captcha,
        ImageProperties => {
            option => value,
            option => value,
            ...
        },
    );

ImageProperties are passed into L<GD::SecurityImage/new>. Read documentation
for the module for full list of options.

=cut

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

This software is Copyright (c) 2014-2020 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
