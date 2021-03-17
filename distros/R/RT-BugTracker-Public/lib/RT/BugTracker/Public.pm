# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2021 Best Practical Solutions, LLC
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

our $VERSION = '1.09';

RT->AddJavaScript("bugtracker-public.js");
RT->AddStyleSheets("bugtracker-public.css");

=head1 NAME

RT::BugTracker::Public - Adds a public, user-friendly bug tracking and
reporting UI to RT

=head1 DESCRIPTION

RT::BugTracker::Public depends on RT::BugTracker.

RT::BugTracker::Public depends on RT::Authen::Bitcard and
Authen::Bitcard for external authentication through Bitcard.

NB: External authentication through Bitcard is broken in RT 4.2 and
4.4. The authors may eventually deprecate this functionality.

This extension adds a public interface for searching and reporting
bugs through an RT with RT::BugTracker installed. The public reporting
UI is disabled, by default.

The public interface entrypoint is on the RT login page. Click the
C<public interface> link to access the public bug search page. The
public search functionality is identical to the private interface in
RT::BugTracker.

To enable public bug reporting, follow the documentation for
C<WebPublicUserReporting>, in the C<CONFIGURATION> section, below. To
report bugs, public users must create a new ticket using the C<New
ticket in> button, or click C<Report a new bug> from the bug list page
for a distribution.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::BugTracker::Public');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

You can find F<local/etc/BugTracker-Public/RT_SiteConfig.pm> with example of
configuration and sane defaults. Add require in the main F<RT_SiteConfig.pm> or
define options there.

=head2 WebPublicUser

Create the public user in your RT system through F<Admin \> Users \>
Create> in RT. The public user must be able to access RT, and it must
be privileged so it can have rights. Do not enter an email address for
the public user.

Add the line below to F<RT_SiteConfig.pm> and replace 'guest' with the
name of the RT user you just created.

    Set( $WebPublicUser, 'guest' );

The public user needs the following rights on public distribution
queues to search bugs:

    SeeCustomField
    SeeQueue
    ShowTicket

The pubic user needs the following rights on public distribution
queues to report bugs:

    CreateTicket
    ModifyCustomField
    ReplyToTicket

=head2 WebPublicUserReporting

By default, the web public user cannot create bug reports through the
web UI. To allow this, add this line:

    Set($WebPublicUserReporting, 1);

=head2 WebPublicUserQueryBuilder

By default, the web public user cannot use RT's fully-featured query builder
and is limited instead to simple search. To allow access to the query
builder, add this line:

    Set($WebPublicUserQueryBuilder, 1);

=head2 WebPublicUserSortResults

By default, the web public user cannot click column headers to re-sort search
results due to performance implications. To permit this, add this line:

    Set($WebPublicUserSortResults, 1);

=head2 ScrubInlineArticleContent

By default, inline articles such as AfterLoginForm are scrubbed for unsafe
HTML tags just like ticket correspondence. If your articles are modifiable
only by trusted users, you may set this to 0 to pass through article content
unscrubbed.

See the documentation below for L</GetArticleContent> for more information.

    Set($ScrubInlineArticleContent, 0);

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

    elsif ( RT->Config->Get('WebPublicUserQueryBuilder')) {
        return undef if $path =~ '^/+Search/Build.html'
                     || $path =~ '^/+Search/Results.html'
    }

    # otherwise, drop the user at the Public default page
    if (       $path !~ '^(/+)Public/'
           and $path !~ RT->Config->Get('WebNoAuthRegex')
           and $path !~ '^/+Helpers/Autocomplete/Queues' ) {
        return "/Public/";
    }
    return undef;
}

require RT::Interface::Web;
%RT::Interface::Web::IS_WHITELISTED_COMPONENT = (
    %RT::Interface::Web::IS_WHITELISTED_COMPONENT,
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

=head2 GetArticleContent

Searches in articles for content for various configurable pages in the BugTracker
interface. The article names are available for adding custom
content in the listed locations. To customize, create or edit the article with the
listed name.

=over

=item * AfterLoginForm

Location: Login page, below username/password fields

=back

=cut

sub GetArticleContent {
    my $article_name = shift;

    my $Class = RT::Class->new( RT->SystemUser );
    my ($ret, $msg) = $Class->Load('BugTracker Pages');

    unless ( $ret and $Class->Id ){
        RT::Logger->warning('Unable to load BugTracker Pages class for articles');
        return '';
    }

    my $Article = RT::Article->new( RT->SystemUser );
    ($ret, $msg) = $Article->LoadByCols( Name => $article_name, Class => $Class->Id );

    unless ($ret and $Article->id){
        RT::Logger->debug("No article found for " . $article_name);
        return '';
    }

    RT::Logger->debug("Found article id: " . $Article->Id);
    my $class = $Article->ClassObj;
    my $cfs = $class->ArticleCustomFields;

    while (my $cf = $cfs->Next) {
        my $values = $Article->CustomFieldValues($cf->Id);
        my $value = $values->First;
        return $value->Content;
    }
    return;
}

# "public" UsernameFormat
package RT::User;

sub _FormatUserPublic
{
    my $self = shift;
    my %args = @_;
    my $session = \%HTML::Mason::Commands::session;

    if (!$args{User} && $args{Address}) {
        $args{User} = RT::User->new( $session->{'CurrentUser'} );
        $args{User}->LoadByEmail($args{Address}->address);
        if ($args{User}->Id) {
            $args{Address} = '';
        } else {
            $args{Address} = $args{Address}->address;
        }
    } else {
        $args{Address} = $args{User}->EmailAddress;
    }
    if ( $args{Address} && RT::BugTracker::Public->IsPublicUser ) {
        $args{Address} =~ s/@/ [...] /;
    }

    return $args{Address} || $args{User}->RealName || $args{User}->Name;
}

# Switch back to original package
package RT::BugTracker::Public;

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-BugTracker-Public@rt.cpan.org|mailto:bug-RT-BugTracker-Public@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-BugTracker-Public>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
