use strict;
use warnings;
package RTx::RemoteLinks;

our $VERSION = '1.00';

use List::Util 'first';

=head1 NAME

RTx-RemoteLinks - Conveniently create links to ticket IDs in other RT instances

=head1 DESCRIPTION

With a small amount of configuration, this extension lets you enter new ticket
links as C<foo:123> which are then displayed in the Links box as "Foo ticket
#123" with a link to the remote RT instance.

Currently remote ticket subjects are not fetched due to authentication
complications, but this could be added in the future.

=head1 CONFIGURATION

    Set(%RemoteLinks,
        Foo => 'example.com',               # assumes http:// and RT at the top-level path
        Bar => 'https://example.net/rt',    # specifies https and a subpath for RT
    );

Prefixes are case insensitive, so both "Foo" and "foo" and "fOo" will work.

Once you create links in the system using a prefix, you should leave it
configured.

Make sure to add this plugin to C<@Plugins> as well, as described in
L</INSTALLATION>.

=cut

require RT::Config;
$RT::Config::META{RemoteLinks} = { Type => 'HASH' };

sub LookupRemote {
    my $class = shift;
    my $alias = $class->CanonicalizeAlias(shift)
        or return;

    my $remote = (RT->Config->Get("RemoteLinks") || {})->{$alias};
       $remote = "http://$remote" unless $remote =~ m{^https?://}i;

    return wantarray ? ($alias, $remote) : $remote;
}

sub CanonicalizeAlias {
    my $class   = shift;
    my $alias   = shift or return;
    my %remotes = RT->Config->Get("RemoteLinks");
    return first { lc $_ eq lc $alias }
           sort keys %remotes;
}

{
    require RT::URI;
    no warnings 'redefine';

    my $_GetResolver = RT::URI->can("_GetResolver")
        or die "No RT::URI::_GetResolver()?";

    *RT::URI::_GetResolver = sub {
        my $self   = shift;
        my $scheme = shift;

        if (RTx::RemoteLinks->CanonicalizeAlias($scheme)) {
            $scheme = "remote-rt";
        }

        return $_GetResolver->($self, $scheme, @_);
    };
}

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RTx::RemoteLinks');

For 4.0, add this line:

    Set(@Plugins, qw(RTx::RemoteLinks));

or add C<RTx::RemoteLinks> to your existing C<@Plugins> line.

Configure your remote RT instances per L</CONFIGURATION> above.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RTx-RemoteLinks@rt.cpan.org|mailto:bug-RTx-RemoteLinks@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RTx-RemoteLinks>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2013-2014 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
