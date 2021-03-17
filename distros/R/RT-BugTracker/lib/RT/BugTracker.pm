
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

use strict;
use warnings;

package RT::BugTracker;

use 5.008003;
our $VERSION = '5.6';

=head1 NAME

RT::BugTracker - Adds a UI designed for bug-tracking for developers to RT

=head1 DESCRIPTION

This extension changes RT's interface to be more useful when you want
to track bug reports in many distributions. This extension is a start
for setups like L<http://rt.cpan.org>. It's been developed to help
authors of Perl modules.

In RT::BugTracker, every queue is a software "distribution".
RT::BugTracker adds a new F<Distribution> menu with options to search
and browse distributions. User and group rights apply normally to
queues through the Distribution menu search options.

Users can search distributions by maintainer through F<Distribution >
Search>. Maintainers are the AdminCc users and groups for
the distribution.

The search functions under the F<Distribution> menu return lists of
matching distributions. List items include a link to the bug list for
the distribution.

Bug list search results include columns for C<Severity>, C<Broken in>,
and C<Fixed in> custom fields. The C<Configuration> section, below,
describes how BugTracker administrators can configure these custom
fields.

The bug list search result page includes a link to the distribution's
C<Manage> page. Distribution maintainers and BugTracker admins can set
various attributes of the distribution here.

=head2 Distribution notes

These notes appear at the top of the distribution's bug list.

=head2 Additional addresses RT should notify

RT::BugTracker installs a new Scrip, C<On create and corresponds
notify additonal addresses>, that fires on distribution ticket
creation and comment transactions. This Scrip sets the C<To:> header
to the email addresses configured here.

=head2 Subject tag in addition to default

STUB: The additional subject tag is currently broken in 4.2/4.4. BPS will document this functionality when it is fixed.

=cut

require RT::Queue;
package RT::Queue;

sub DistributionBugtracker {
    return (shift)->_AttributeBasedField(
        DistributionBugtracker => @_
    );
}


sub SetDistributionBugtracker {
    my ($self, $value) = (shift, shift);

    my $bugtracker = {};
    my $update = 0;

    # Validate and set the mail to - we don't care if this is rt.cpan.org
    if(defined($value->{mailto}) && !($value->{mailto} =~  m/rt\.cpan\.org/)) {
        if(Email::Address->parse($value->{mailto})) {
            $bugtracker->{mailto} = $value->{mailto};
            $update = 1;
        }
    }

    # Hash of supported URI schemes for validation
    my $supported_schemes = {
        http    => 1,
        https   => 1,
    };

    # Validate and set the web - we don't care if this is rt.cpan.org
    if(defined($value->{web}) && !($value->{web} =~ m/rt\.cpan\.org/)) {
        if(my $uri = URI->new($value->{web})) {

            # Check that this is a supported scheme
            if(defined($supported_schemes->{$uri->scheme()})) {
                $bugtracker->{web} = $value->{web};
                $update = 1;
            }

            else {
                my $error_msg = "Refused to set external bugtracker website";
                $error_msg   .= " on distribution (" . $self->Name() .  ").";
                $error_msg   .= " Unsupported scheme (" . $uri->scheme() . ").";
                $RT::Logger->info($error_msg);
            }
        }
        else {
            my $error_msg = "Failed to set external bugtracker website";
            $error_msg   .= " on distribution (" . $self->Name() .  ")";
            $error_msg   .= " Unable to parse (" . $value->{web} . ") with URI.";
            $RT::Logger->error($error_msg);
        }
    }

    if($update) {
        return $self->_SetAttributeBasedField( DistributionBugtracker => $bugtracker );
    }

    else {
        return $self->_SetAttributeBasedField( DistributionBugtracker => undef );
    }
}

sub DistributionNotes {
    return (shift)->_AttributeBasedField(
        DistributionNotes => @_
    );
}

sub SetDistributionNotes {
    return (shift)->_SetAttributeBasedField(
        DistributionNotes => @_
    );
}

sub NotifyAddresses {
    return (shift)->_AttributeBasedField(
        NotifyAddresses => @_
    ) || [];
}

sub SetNotifyAddresses {
    return (shift)->_SetAttributeBasedField(
        NotifyAddresses => @_
    );
}

{ no warnings 'redefine';
sub SetSubjectTag {
    my ($self, $value) = (shift, shift);
    if ( defined $value and length $value ) {
        $value =~ s/(^\s+|\s+$)//g;

        unless ($value =~ /^\Q$RT::rtname\E\b/) {
            # Prepend the $rtname before we get into the database so we don't
            # have to munge it on the way out.
            $value = "$RT::rtname $value";
        }

        # We just prepended the $rtname if necessary, so the full subject tag
        # regex should match.  If it doesn't, the subject tag contains
        # prohibited characters (or we have a bug, but catching that is good so
        # we don't mishandle incoming mail).
        my $re = RT->Config->Get("EmailSubjectTagRegex");
        unless ($value =~ /^$re$/) {
            RT->Logger->warning("Subject tag for queue @{[$self->Name]} contains prohibited characters: '$value'");
            return (0, $self->loc("Subject tag contains prohibited characters"));
        }
    }
    return $self->_Set( Field => 'SubjectTag', Value => $value );
}}

sub _AttributeBasedField {
    my $self = shift;
    my $name = shift;

    return undef unless $self->CurrentUserHasRight('SeeQueue');

    my $attr = $self->FirstAttribute( $name )
        or return undef;
    return $attr->Content;
}

sub _SetAttributeBasedField {
    my $self = shift;
    my $name = shift;
    my $value = shift;

#    return ( 0, $self->loc('Permission Denied') )
#        unless $self->CurrentUserHasRight('AdminQueue');

    my ($status, $msg);
    if ( defined $value && length $value ) {
        ($status, $msg) = $self->SetAttribute(
            Name    => $name,
            Content => $value,
        );
    } else {
        return (1, $self->loc("[_1] changed", $self->loc($name)))
            unless $self->FirstAttribute( $name );
        ($status, $msg) = $self->DeleteAttribute( $name );
    }
    unless ( $status ) {
        $RT::Logger->error( "Couldn't change attribute '$name': $msg");
        return (0, $self->loc("System error. Couldn't change [_1].", $self->loc($name)));
    }
    return ( 1, $self->loc("[_1] changed", $self->loc($name)) );
}

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

RT::BugTracker creates several custom fields for tracking bugs; you may skip
this step if you intend to use different custom fields. See the section below
on L<Custom Fields>.

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::BugTracker');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=head2 DistributionToQueueRegex

Some programming languages use characters in package names that may
not work well in email addresses. Perl modules use double colons,
'::', to separate package parents from children. BugTracker
administrators could name a distribution queue using these characters,
like 'Data::Dumper', for example. But the resulting public email
address for bug reports would be bugs-Data::Dumper@example.com.

While some characters may not be unallowed in email addresses,
BugTracker administrators may want to name their distribution queues
so that resulting public bug report addresses are more likely to get
through spam and other filters.

However, users want to search software distributions by the canonical
name of the package, like under Distributions > Search and
Distributions > Browse. Users expect to type "Data::Dumper" and find
the distribution queue named "Data-Dumper".

Use this config variable to define the character translation between
distribution search strings and distribution queue names. BugTracker
will use 'Pattern' and 'Substitution' in a subsitution regex
match. BugTracker will use this value:

Set(%DistributionToQueueRegex,
    'Pattern' => '::',
    'Substitution' => '-'
);

like this:

s/::/-/g

The values above translate Perl module names into their email-friendly
counterpart queue names.

=head2 BugTracker_CustomFieldsOnUpdate

Use this config variable to specify a list of custom field names to
display on the ticket reply page for privileged users. By default it
displays "Fixed in" to help maintainers quickly close out issues as the
fixes are released.

=head2 BugTracker_SearchResultFormat

Use this config variable to specify the search result format for a
distribution's list of tickets, much like C<DefaultSearchResultFormat>
in core RT.

=head2 BugTracker_HideBrowseDistributions

Use this config variable to suppress the alphabetical distribution browser
UI, for users with fewer than tens of thousands of queues. :)

=head2 BugTracker_ShowAllDistributions

Use this config variable to always display all distributions, for users
with fewer than hundreds of queues. :)

=head2 Custom Fields

By default, when you run C<make initdb>, RT::BugTracker creates three
custom fields on queues, globally, with empty values.

=over 4

=item Severity

Bug severity levels, like 'Low', 'Medium', and 'High'.

=item Broken in

The distribution version where the bug in the ticket first
appeared. Since each distribution will have different release
versions, the BugTracker admin will need top populate these values for
each distribution.

=item Fixed in

The distribution version where the bug in the ticket was fixed. Since
each distribution will have different release versions, the BugTracker
admin will need top populate these values for each distribution.

=back

You may choose to skip creation of these custom fields by skipping the
C<make initdb> step. If you would like to use your own custom fields,
you should investigate setting the C<BugTracker_CustomFieldsOnUpdate>
and C<BugTracker_SearchResultFormat> config options documented above.

=head1 SEE ALSO

L<RT::BugTracker::Public>, L<RT::Extension::rt_cpan_org>

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-BugTracker@rt.cpan.org|mailto:bug-RT-BugTracker@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-BugTracker>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
