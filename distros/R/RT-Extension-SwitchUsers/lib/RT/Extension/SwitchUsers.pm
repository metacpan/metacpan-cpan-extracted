use strict;
use warnings;

package RT::Extension::SwitchUsers;

our $VERSION = '0.08';

use RT::User;
use RT::SwitchedUserRealActor;
use RT::SwitchedUserRealActors;

if ( my @fields = grep { $_ } RT->Config->Get( 'SwitchUsersSharedFields' ) ) {

    no warnings 'redefine';
    my $orig = \&RT::User::_Value;
    *RT::User::_Value = sub {
        my $self         = shift;
        my $field        = shift;
        my $base_user_id = $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'};
        if (   $base_user_id
            && $self->id
            && $base_user_id != $self->id
            && $HTML::Mason::Commands::session{CurrentUser}
            && $self->id == $HTML::Mason::Commands::session{CurrentUser}->id
            && grep { $field eq $_ } @fields )
        {
            my $user = RT::User->new( RT->SystemUser );
            $user->Load( $base_user_id );
            if ( $user->id ) {
                return $user->_Value( $field );
            }
            else {
                RT->Logger->error( "Failed to load user $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'}" );
                return;
            }
        }
        return $orig->( $self, $field );
    };
}

{
    use RT::Interface::Web;
    no warnings 'redefine';
    my $orig = \&RT::Interface::Web::AttemptExternalAuth;
    *RT::Interface::Web::AttemptExternalAuth = sub {
        return if $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'};
        return $orig->(@_);
    };
}

sub GetUsersToSwitch {
    my $self = shift;
    my $base_user_id =
      $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'} || $HTML::Mason::Commands::session{CurrentUser}->id;

    my $group_name = RT->Config->Get( 'SwitchUsersGroup' );

    unless ( defined $group_name ) {
        RT->Logger->warning( "SwitchUsersGroup config is not defined, skipping" );
        return;
    }

    my $group = RT::Group->new( RT->SystemUser );
    $group->LoadUserDefinedGroup( $group_name );
    unless ( $group->id ) {
        RT->Logger->warning( "Failed to load user defined group '$group_name', skipping" );
        return;
    }

    my $base_user = RT::User->new( RT->SystemUser );
    $base_user->Load( $base_user_id );
    unless ( $base_user->id ) {
        RT->Logger->warning( "Failed to load user $base_user_id, skipping" );
        return;
    }

    unless ( $group->HasMemberRecursively( $base_user->PrincipalObj ) ) {
        RT->Logger->debug( "User #$base_user_id doesn't belong to group '$group_name', skipping" );
        return;
    }

    my @users = $base_user;

    my $ocfvs = $base_user->CustomFieldValues( 'Switch Users Accounts' );
    while ( my $ocfv = $ocfvs->Next ) {
        my $user = RT::User->new( RT->SystemUser );
        $user->Load( $ocfv->Content );
        if ( $user->id ) {
            push @users, $user;
        }
        else {
            RT->Logger->warning( "Failed to load user " . $ocfv->Content );
        }
    }

    return @users;
}

{
    use RT::Record;
    no warnings 'redefine';
    my $orig_create = \&RT::Record::Create;
    *RT::Record::Create = sub {
        my $self = shift;
        my ( $id, $msg ) = $orig_create->( $self, @_ );

        if (   $id
            && $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'}
            && !$self->isa('RT::SwitchedUserRealActor')
            && $self->_Accessible( 'Creator', 'read' )
            && $self->__Value('Creator') != RT->SystemUser->Id )
        {
            my $record = RT::SwitchedUserRealActor->new( $self->CurrentUser );
            my ( $ret, $msg ) = $record->Create(
                ObjectType    => ref $self,
                ObjectId      => $id,
                Creator       => $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'},
                LastUpdatedBy => $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'},
            );
            if ( !$ret ) {
                RT->Logger->error( "Couldn't create SwitchedUserRealActor record for " . ref($self) . "#$id: $msg" );
            }
        }
        return wantarray ? ( $id, $msg ) : $id;
    };

    my $orig_set = \&RT::Record::_Set;
    *RT::Record::_Set = sub {
        my $self = shift;
        my $ret  = $orig_set->( $self, @_ );
        if (   $ret
            && $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'}
            && !$self->isa('RT::SwitchedUserRealActor')
            && $self->_Accessible( 'LastUpdatedBy', 'read' )
            && $self->__Value('LastUpdatedBy') != RT->SystemUser->Id )
        {
            my $record = RT::SwitchedUserRealActor->new( $self->CurrentUser );
            $record->LoadByCols( ObjectType => ref $self, ObjectId => $self->Id );
            if ( $record->Id ) {
                if ( $record->LastUpdatedBy != $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'} ) {
                    my ( $ret, $msg ) = $record->__Set(
                        Field => 'LastUpdatedBy',
                        Value => $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'},
                    );
                    if ( !$ret ) {
                        RT->Logger->error(
                            "Couldn't update SwitchedUserRealActor for " . ref($self) . "#" . $self->Id . ": $msg" );
                    }
                }
            }
            else {
                # Old record that doesn't have related RT::SwitchedUserRealActor yet
                my ( $ret, $msg ) = $record->Create(
                    ObjectType    => ref $self,
                    ObjectId      => $self->Id,
                    Creator       => $self->Creator,
                    LastUpdatedBy => $HTML::Mason::Commands::session{'SwitchUsers-BaseUser'},
                );
                if ( !$ret ) {
                    RT->Logger->error(
                        "Couldn't create SwitchedUserRealActor for " . ref($self) . "#" . $self->Id . ": $msg" );
                }
            }
        }
        return wantarray ? ( $ret->as_array ) : $ret;
    };
}

=head1 NAME

RT-Extension-SwitchUsers - Switch current logged in user to others

=head1 DESCRIPTION

This extension provides a way to switch current logged in user to others
defined in user custom field "Switch Users Accounts", which contains a list
of user names (one name per line) that can be modified on admin user or
"About me" pages.

=head1 RT VERSION

Works with RT 5

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

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::SwitchUsers');

Set the group which users belong to can switch users. 

    Set($SwitchUsersGroup, 'Core Team');

Set fields all the switched users can share:

    Set(@SwitchUsersSharedFields, qw/EmailAddress SMIMECertificate/);

CAVEAT: please don't share C<Name> field as it's been used to distinguish
switched users.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-SwitchUsers@rt.cpan.org">bug-RT-Extension-SwitchUsers@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-SwitchUsers">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-SwitchUsers@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-SwitchUsers

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2018-2025 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
