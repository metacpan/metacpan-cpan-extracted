use strict;
use warnings;
package RT::Extension::QuickReassign;

our $VERSION = '0.03';

package RT::Ticket;

BEGIN {
    *SUPER_SetOwner = \&SetOwner;
}

no warnings qw(redefine);

sub SetOwner {
    my $self = shift;
    my $NewOwner = shift;
    my $Type = shift;

    my $OldOwnerObj = $self->OwnerObj;
    my $NewOwnerObj = RT::User->new( $self->CurrentUser );
    $NewOwnerObj->Load($NewOwner);

    # We're reassigning a ticket
    if ($OldOwnerObj->Id != $RT::Nobody->Id         and 
        $OldOwnerObj->Id != $self->CurrentUser->Id  and
        $NewOwnerObj->Id != $self->CurrentUser->Id      )
    {
        my $group_name = RT->Config->Get('QuickReassignGroup');

        if (defined $group_name) {
            my $group = RT::Group->new( RT->SystemUser );
            $group->LoadUserDefinedGroup($group_name);

            if ($group->Id) {
                if ($group->HasMemberRecursively($self->CurrentUser->id)) {
                    # Force so the owner reassignment goes through in the original method
                    $Type = 'Force';

                    RT->Logger->info("Setting owner change (@{[$OldOwnerObj->Name]} -> @{[$NewOwnerObj->Name]}) by @{[$self->CurrentUser->Name]} to Type => Force due to QuickReassign");
                }
            } else {
                RT->Logger->warning("QuickReassign is configured with an invalid group name ($group_name)");
            }
        }
    }

    return $self->SUPER_SetOwner($NewOwner, $Type, @_);
}

=head1 NAME

RT-Extension-QuickReassign - Allow members of a specified group to reassign
ticket owners without stealing the ticket first

=head1 INSTALLATION 

=over

=item perl Makefile.PL

=item make

=item make install

May need root permissions

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Set(@Plugins, qw(RT::Extension::QuickReassign));

or add C<RT::Extension::QuickReassign> to your existing C<@Plugins> line.

Configure the group you wish to let quickly reassign tickets:

    Set($QuickReassignGroup, 'My Group Name');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Thomas Sibley <trs@bestpractical.com>

=head1 LICENCE AND COPYRIGHT

This software is copyright (c) 2011 by Best Practical Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
