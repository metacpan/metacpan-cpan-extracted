use strict;
use warnings;
package RT::Extension::PermissiveHTMLMail;

use HTML::Scrubber;
our $VERSION = '1.00';

RT->Config->Set( PreferRichText => 1 );
RT->Config->Set( ShowTransactionImages => 1);

push @HTML::Mason::Commands::SCRUBBER_ALLOWED_TAGS,
    qw(TABLE THEAD TBODY TFOOT TR TD TH);
$HTML::Mason::Commands::SCRUBBER_ALLOWED_ATTRIBUTES{$_} = 1
    for qw(style class id colspan rowspan align valign cellspacing cellpadding border width height);

if ( RT->Config->Get( 'AllowDangerousHTML' ) ) {
    no warnings 'redefine';
    *HTML::Mason::Commands::_NewScrubber = sub {
        return HTML::Scrubber->new(
            default => [1, {
                '*'           => 1,
                'href'        => qr{^(?!(?:java)?script)}i,
                'src'         => qr{^(?!(?:java)?script)}i,
                'cite'        => qr{^(?!(?:java)?script)}i,
                (map {+("on$_" => 0)}
                     qw/ blur change click dblclick error focus
                         keydown keypress keyup load mousedown
                         mousemove mouseout mouseover mouseup reset
                         select submit unload / ),
            } ],
            rules => [
                script => 0,
                html   => 0,
                head   => 0,
                body   => 0,
                meta   => 0,
                base   => 0,
            ],
            comment => 0,
        );
    }
}

=head1 NAME

RT-Extension-PermissiveHTMLMail - Allows a greater range of HTML in RT, at the cost of security

=head1 RT VERSION

Works with RT 4.0 and RT 4.2.

=head1 SUMMARY

By default, RT displays HTML mail; however, due to security concerns, by
default it does not allow the full range of HTML to be used.
Specifically, it prevents:

=over

=item Tables

Because RT cannot ensure that HTML in email is balanced, malicious email
messages can use tables to mimic or mask parts of the standard RT UI.
This opens RT to a broad range of "phishing attacks," wherein the user
believes they are clicking a benign RT link, which actually is
controlled by the originator of the email.  This can allow attackers to
steal passwords and compromise RT, and possibly other servers.

=item Many text styles

CSS is a powerful tool; it can also be used to mimic or mask parts of
the standard RT UI.  By default, RT thus only allows a small subset of
CSS properties, which are sufficient for simple styling.  Allowing
arbitrary styles could lead to effective "phishing attacks,"
compromising passwords.

=back

Installing this extension loosens the above restrictions; this should be
sufficient for most needs.  However, RT will still only allow HTML tags
that it recognizes.


Installing this extension also additionally provides a
C<$AllowDangerousHTML> configuration option.  Setting this alters RT
from using a whitelist (allowing only HTML tags and attributes which it
knows to be safe) to using a blacklist (skip tags and attributes which are
unsafe).  This is B<unsafe> and B<dangerous>, as there are guaranteedly
further unsafe tags which RT does not know to prevent.  B<Enabling this
feature allows your RT account to be compromised by a malicious email>.
Do not enable it (via C<Set( $AllowDangerousHTML, 1 )>) unless you
understand the consequences.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::PermissiveHTMLMail');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::PermissiveHTMLMail));

or add C<RT::Extension::PermissiveHTMLMail> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-PermissiveHTMLMail@rt.cpan.org|mailto:bug-RT-Extension-PermissiveHTMLMail@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-PermissiveHTMLMail>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
