use strict;
use warnings;
package RT::Extension::DynamicWebPath;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-DynamicWebPath - Dynamic WebPath

=head1 DESCRIPTION

This extension adds dynamic C<WebPath> support to RT, each C<WebPath> can
have its own configurations.

This can be used to support different auth methods, e.g. "" for SSO and
"/rt" for RT internal login.

=head1 RT VERSION

Works with RT 5

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::DynamicWebPath');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 Configuration

Assuming "" is to use SSO, "/rt" is to use RT internal login:

    Set( %DynamicWebPath,
        '' => {
            WebRemoteUserAuth    => 1,
            WebFallbackToRTLogin => 0,
        },
        '/rt' => {
            WebRemoteUserAuth    => 0,
            WebFallbackToRTLogin => 1,
        },
    );

The corresponding configs are set automatically when RT detects C<WebPath>
changes by checking HTTP request URL.

In apache config, add the following directive before normal setup:

    ScriptAlias /rt /opt/rt5/sbin/rt-server.fcgi/

Also remember to turn off SSO for /rt, e.g.

    <LocationMatch "^/(rt|REST)(/|$)">
        MellonEnable off
        Require all granted
    </LocationMatch>

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-DynamicWebPath@rt.cpan.org">bug-RT-Extension-DynamicWebPath@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-DynamicWebPath">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-DynamicWebPath@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-DynamicWebPath

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022-2023 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
