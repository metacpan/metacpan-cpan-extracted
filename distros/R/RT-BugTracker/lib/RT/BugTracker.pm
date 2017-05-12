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

use strict;
use warnings;

package RT::BugTracker;

use 5.008003;
our $VERSION = '5.2';

=head1 NAME

RT::BugTracker - Adds a UI designed for bug-tracking for developers to RT

=head1 DESCRIPTION

This extension changes RT's interface to be more useful when you want to track
bug reports in many distributions. This extension is a start for setups like
L<http://rt.cpan.org>. It's been developed to help authors of Perl modules.

It follows two basic rules to achieve the goal:

=over 4

=item Each queue associated with one package (distribution).

=item Queue's AdminCc list is used for maintainers of the
coresponding distribution.

=back

=cut

RT->AddStyleSheets("bugtracker.css");

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

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RT::BugTracker));

or add C<RT::BugTracker> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

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

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
