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
use warnings; no warnings qw(redefine);

# Explicitly load Shredder here so we can override RT::User::BeforeWipeout
use RT::Shredder;

package RT::Extension::MergeUsers;

our $VERSION = '1.03';

=head1 NAME

RT::Extension::MergeUsers - Merges two users into the same effective user
 
=head1 RT VERSION

Works with RT 4.0, 4.2 and 4.4.

=head1 DESCRIPTION

This RT extension adds a "Merge Users" box to the User Administration page,
which allows you to merge the user you are currently viewing with another
user on your RT instance.

It also adds L</MergeInto> and L</UnMerge> functions to the L<RT::User> class,
which allow you to programmatically accomplish the same thing from your code.

It also provides a version of L<CanonicalizeEmailAddress>, which means that
all e-mail sent from secondary users is displayed as coming from the primary
user.

=head1 INSTALLATION

Be sure to also read L</UPGRADING> if you are upgrading.

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::MergeUsers');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::MergeUsers));

or add C<RT::Extension::MergeUsers> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 UPGRADING

If you are upgrading from 0.03_01 or earlier, you must run
F<bin/rt-update-merged-users>.  This script will create MergedUsers
Attributes so RT can know when you're looking at a user that other users
have been merged into. If you don't run this script, you'll have issues
unmerging users. It can be safely run multiple times, it will only
create Attributes as needed.

=head1 UTILITIES

=head2 rt-clean-merged-users

When a user with another user merged into it is shredded,
the attributes on that user are also shredded, but the
merged user will remain, along with attributes that may point
to the now missing user id. This script cleans up attributes
if the merged-into user record is now gone. These users will then be
converted back to regular unmerged users.

=head2 rt-merge-users

A command-line tool to merge one user into another

=head1 CAVEATS

=head2 RT::Shredder and Merged Users

Merging a user effectively makes it impossible to load the merged user
directly. Attempting to access the old user resolves to the merged-into user.
Because of this, MergeUsers has some extra code to help L<RT::Shredder>
clean up these merged records to avoid leaving merged user records in the DB
while removing the user they were merged into.

When running L<RT::Shredder> on a user record with other users merged into it,
the merged users are Unmerged before the initial user record is shredded.
There are two options to handle these newly unmerged users:

=over

=item 1.

Re-run your shredder command with the same or similar options. The unmerged
user records will now be accessible and, depending on your shredder options,
they will likely be shredded on the second run. If you have multiple
layers of merged users, you may need to run shredder multiple times.

=item 2.

MergeUsers will log the unmerged users at the C<info> level so you can pull
the user ids from the log and shred them manually. This is most likely to
be useful if you are shredding one specific user (and all merged accounts).

=back

=cut

package RT::User;

our %EFFECTIVE_ID_CACHE;

use RT::Interface::Web::Handler;

{
    my $i = 0;

    my $old_cleanup = \&RT::Interface::Web::Handler::CleanupRequest;
    no warnings 'redefine';
    *RT::Interface::Web::Handler::CleanupRequest = sub {
        $old_cleanup->(@_);
        return if ++$i % 100; # flush cache every N requests
        %EFFECTIVE_ID_CACHE = ();
    };
}

sub CanonicalizeEmailAddress {
    my $self = shift;
    my $address = shift;

    if ($RT::CanonicalizeEmailAddressMatch && $RT::CanonicalizeEmailAddressReplace ) {
        $address =~ s/$RT::CanonicalizeEmailAddressMatch/$RT::CanonicalizeEmailAddressReplace/gi;
    }

    # get the user whose email address this is
    my $canonical_user = RT::User->new( $RT::SystemUser );
    $canonical_user->LoadByCols( EmailAddress => $address );
    return $address unless $canonical_user->id;
    return $address unless $canonical_user->EmailAddress && $canonical_user->EmailAddress ne $address;
    return $canonical_user->CanonicalizeEmailAddress(
        $canonical_user->EmailAddress
    );
}

sub LoadByCols {
    my $self = shift;
    $self->SUPER::LoadByCols(@_);
    return $self->id unless my $oid = $self->id;

    unless ( exists $EFFECTIVE_ID_CACHE{ $oid } ) {
        my $effective_id = RT::Attribute->new( $RT::SystemUser );
        $effective_id->LoadByCols(
            Name       => 'EffectiveId',
            ObjectType => __PACKAGE__,
            ObjectId   => $oid,
        );
        if ( $effective_id->id && $effective_id->Content && $effective_id->Content != $oid ) {
            $self->LoadByCols( id => $effective_id->Content );
            $EFFECTIVE_ID_CACHE{ $oid } = $self->id
                if $self->Id;
        } else {
            $EFFECTIVE_ID_CACHE{ $oid } = undef;
        }
    }
    elsif ( defined $EFFECTIVE_ID_CACHE{ $oid } ) {
        $self->LoadByCols( id => $EFFECTIVE_ID_CACHE{ $oid } );
    }

    if ( not $self->Id ){
        # Unable to load the effective user, so return actual user
        RT::Logger->warning("Unable to load user by effective id. "
            . "You may need to run rt-clean-merged-users if some users have been "
            . "deleted or shredded.");
        $self->SUPER::LoadByCols( Id => $oid );
    }
    return $self->id;
}

sub LoadOriginal {
    my $self = shift;
    return $self->SUPER::LoadByCols( @_ );
}

sub GetMergedUsers {
    my $self = shift;

    my $merged_users = $self->FirstAttribute('MergedUsers');
    unless ($merged_users) {
        $self->SetAttribute(
            Name => 'MergedUsers',
            Description => 'Users that have been merged into this user',
            Content => [] );
        $merged_users = $self->FirstAttribute('MergedUsers');
    };
    return $merged_users;
}

sub MergeInto {
    my $self = shift;
    my $user = shift;

    # Load the user objects we were called with
    my $merge;
    if (ref $user) {
        return (0, "User is not loaded") unless $user->id;

        $merge = RT::User->new( $self->CurrentUser );
        $merge->Load($user->id);
        return (0, "Could not reload user #". $user->id)
            unless $merge->id;
    } else {
        $merge = RT::User->new( $self->CurrentUser );
        $merge->Load($user);
        return (0, "Could not load user '$user'") unless $merge->id;
    }
    return (0, "Could not load user to be merged") unless $merge->id;

    # Get copies of the canonicalized users
    my $email;

    my $canonical_self = RT::User->new( $self->CurrentUser );
    $canonical_self->Load($self->id);
    return (0, "Could not load user to merge into") unless $canonical_self->id;

    # No merging into yourself!
    return (0, "Could not merge @{[$merge->Name]} into itself")
           if $merge->id == $canonical_self->id;

    # No merging if the user you're merging into was merged into you
    # (ie. you're the primary address for this user)
    my ($new) = $merge->Attributes->Named("EffectiveId");
    return (0, "User @{[$canonical_self->Name]} has already been merged")
           if defined $new and $new->Content == $canonical_self->id;

    # clean the cache
    delete $EFFECTIVE_ID_CACHE{$self->id};

    # do the merge
    $canonical_self->SetAttribute(
        Name => "EffectiveId",
        Description => "Primary ID of this email address",
        Content => $merge->id,
    );

    my $merged_users = $merge->GetMergedUsers;
    $merged_users->SetContent( [$canonical_self->Id, @{$merged_users->Content}] );

    $merge->SetComments(join "\n", grep /\S/,
        $merge->Comments||'',
        ($canonical_self->EmailAddress || $canonical_self->Name)." (".$canonical_self->id.") merged into this user",
    );

    $canonical_self->SetComments( join "\n", grep /\S/,
        $canonical_self->Comments||'',
        "Merged into ". ($merge->EmailAddress || $merge->Name)." (". $merge->id .")",
    );
    return (1, "Merged users successfuly");
}

sub UnMerge {
    my $self = shift;

    my ($current) = $self->Attributes->Named("EffectiveId");
    return (0, "Not a merged user") unless $current;

    # flush the cache, or the Sets below will
    # clobber $self
    delete $EFFECTIVE_ID_CACHE{$self->id};

    my $merge = RT::User->new( $self->CurrentUser );
    $merge->Load( $current->Content );

    $current->Delete;
    $self->SetComments( join "\n", grep /\S/,
        $self->Comments||'',
        "Unmerged from ". ($merge->EmailAddress || $merge->Name) ." (".$merge->id.")",
    );

    $merge->SetComments(join "\n", grep /\S/,
        $merge->Comments,
        ($self->EmailAddress || $self->Name) ." (". $self->id .") unmerged from this user",
    );

    my $merged_users = $merge->GetMergedUsers;
    my @remaining_users = grep { $_ != $self->Id } @{$merged_users->Content};
    if (@remaining_users) {
        $merged_users->SetContent(\@remaining_users);
    } else {
        $merged_users->Delete;
    }

    return ($merge->id, "Unmerged @{[$self->NameAndEmail]} from @{[$merge->NameAndEmail]}");
}

sub SetEmailAddress {
    my $self = shift;
    my $value = shift;

    my ( $val, $msg ) = $self->ValidateEmailAddress($value);
    return ( 0, $msg || $self->loc('Email address in use') ) unless $val;

    # if value is valid then either there is no user or
    # user is merged into this one
    my $tmp = RT::User->new( $self->CurrentUser );
    $tmp->LoadOriginal( EmailAddress => $value );
    if ( $tmp->id && $tmp->id != $self->id ) {
        # there is a different user record
        $tmp->_Set( Field => 'EmailAddress', Value => "" );
    }

    return $self->_Set( Field => 'EmailAddress', Value => $value );
}

sub NameAndEmail {
    my $self = shift;
    my $name = $self->Name;
    my $email = $self->EmailAddress;

    if ($name eq $email) {
        return $email;
    } else {
        return "$name <$email>";
    }
}

{
    my $orig = RT::User->can('BeforeWipeout');
    *RT::User::BeforeWipeout = sub {
        my $self = shift;

        # Check to see if this user has any other users merged into it
        # Unmerge any merged users to break the connection to this
        # soon-to-be-shredded user.
        # The MergedUsers attribute on this user will be removed by Shredder.

        my $merged_users = $self->GetMergedUsers;
        foreach my $user_id ( @{$merged_users->Content} ){
            my $merged_user = RT::User->new(RT->SystemUser);
            $merged_user->LoadOriginal( id => $user_id );
            my ($id, $result) = $merged_user->UnMerge();
            RT::Logger->info($result);
        }

        return $orig->($self, @_);
    };
}

package RT::Users;
use RT::Users;

sub Next {
    my $self = shift;

    my $user = $self->SUPER::Next(@_);
    unless ($user and $user->id) {
        $self->{seen_users} = undef;
        return undef;
    }



    my ($effective_id) = $user->Attributes->Named("EffectiveId");
    my $original_id = $user->Id;
    if ($effective_id && $effective_id->Content && $effective_id->Content != $user->id) {
        $user->LoadByCols(id =>$effective_id->Content);
    }
    return $self->Next() if ($user->Id and $self->{seen_users}->{$user->id}++);

    # Failed to load the effective user record for some reason, so expose
    # this user again.
    $user->LoadByCols( Id => $original_id )
        unless $user->Id;

    return $user;
}

sub GotoFirstItem {
    my $self = shift;
    $self->{seen_users} = undef;
    $self->GotoItem(0);
}


package RT::Principal;

sub SetDisabled {
    my $self = shift;
    my $value = shift;

    my ($ret, $msg) = $self->_Set( Field => "Disabled", Value => $value );
    return ($ret, $msg) unless $ret;

    return ($ret, $msg) unless $self->IsUser;

    for my $id (@{$self->Object->GetMergedUsers->Content}) {
        my $user = RT::User->new( $self->CurrentUser );
        $user->LoadOriginal( id => $id );
        $user->PrincipalObj->_Set( Field => "Disabled", Value => $value );
    }

    return ($ret, $msg);
}

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-MergeUsers@rt.cpan.org|mailto:bug-RT-Extension-MergeUsers@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-MergeUsers>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
