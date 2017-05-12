# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2014 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

use 5.008003;
use strict;
use warnings;

package RT::BugTracker::Public;
use URI::Escape qw/ uri_escape /;

our $VERSION = '1.05';

RT->AddJavaScript("bugtracker-public.js");
RT->AddStyleSheets("bugtracker-public.css");

=head1 NAME

RT::BugTracker::Public - Adds a public, (hopefully) userfriendly bug tracking UI to RT

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RT::BugTracker::Public));

or add C<RT::BugTracker::Public> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

You can find F<local/etc/BugTracker-Public/RT_SiteConfig.pm> with example of
configuration and sane defaults. Add require in the main F<RT_SiteConfig.pm> or
define options there.

=head2 WebPublicUser

Make sure to create the public user in your RT system and add the line below
to your F<RT_SiteConfig.pm>.

    Set( $WebPublicUser, 'guest' );

If you didn't name your public user 'guest', then change accordingly.

The public user should probably be unprivileged and have the following rights

    CreateTicket
    ModifyCustomField
    ReplyToTicket
    SeeCustomField
    SeeQueue
    ShowTicket

If you want the public UI to do anything useful. It should NOT have the
ModifySelf right.

=cut

sub IsPublicUser {
    my $self = shift;

    my $session = \%HTML::Mason::Commands::session;
    # XXX: Not sure when it happens
    return 1 unless $session->{'CurrentUser'} && $session->{'CurrentUser'}->id;
    return 1 if $session->{'CurrentUser'}->Name eq ($RT::WebPublicUser||'');
    return 1 if defined $session->{'BitcardUser'};
    return 1 if defined $session->{'CurrentUser'}->{'OpenID'};
    return 0;
}

sub RedirectToPublic {
    my $self = shift;
    my %args = @_;
    my ($path, $ARGS) = @args{"Path", "ARGS"};

    # The following logic is very similar to the default priv/unpriv logic for
    # self service, which is disabled.

    if ( $path =~ '^(/+)Ticket/Display.html' and $ARGS->{'id'} ) {
        return "/Public/Bug/Display.html?id="
                    . uri_escape($ARGS->{'id'});
    }
    elsif ( $path =~ '^(/+)Dist/Display.html' and ($ARGS->{'Name'} or $ARGS->{'Queue'}) ) {
        return "/Public/Dist/Display.html?Name="
                    . uri_escape($ARGS->{'Name'} || $ARGS->{'Queue'});
    }
    elsif ( $path =~ '^(/+)Dist/ByMaintainer.html' and $ARGS->{'Name'} ) {
        return "/Public/Dist/ByMaintainer.html?Name="
                    . uri_escape($ARGS->{'Name'});
    }
    elsif ( $path =~ '^(/+)Ticket/Attachment/' ) {
        # Proxying through a /Public/ url lets us auto-login users
        return "/Public$path";
    }

    # otherwise, drop the user at the Public default page
    elsif (    $path !~ '^(/+)Public/'
           and $path !~ RT->Config->Get('WebNoAuthRegex')
           and $path !~ '^/+Helpers/Autocomplete/Queues' ) {
        return "/Public/";
    }
    return undef;
}

require RT::Interface::Web;
%RT::Interface::Web::is_whitelisted_component = (
    %RT::Interface::Web::is_whitelisted_component,
    "/Public/Browse.html"            => 1,
    "/Public/Dist/BeginsWith.html"   => 1,
    "/Public/Dist/Browse.html"       => 1,
    "/Public/Dist/ByMaintainer.html" => 1,
    "/Public/Dist/Display.html"      => 1,
    "/Public/Dist/bugs.tsv"          => 1,
    "/Public/Search/Results.html"    => 1,
    "/Public/Search/Simple.html"     => 1,
    "/Public/index.html"             => 1,
);

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-BugTracker-Public@rt.cpan.org|mailto:bug-RT-BugTracker-Public@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-BugTracker-Public>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
