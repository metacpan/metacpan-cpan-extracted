use strict;
use warnings;
package RTx::QuickUpdateUserComments;

our $VERSION = '0.03';

RT::System->AddRight( Staff => ModifyUserComments => 'Update the Comments field on any user' );
RT::System->AddRight( Staff => SeeUserComments    => 'Read the Comments field on any user' );

package RT::User {
    no warnings 'redefine';
    my $original_modify = \&CurrentUserCanModify;
    *CurrentUserCanModify = sub {
        my ($self, $field) = @_;
        return 1 if $field eq 'Comments'
                and $self->CurrentUserHasRight('ModifyUserComments');
        return $original_modify->(@_);
    };

    my $original_see = \&CurrentUserCanSee;
    *CurrentUserCanSee = sub {
        my ($self, $field) = @_;
        return 1 if $field eq 'Comments'
                and $self->CurrentUserHasRight('SeeUserComments');
        return $original_see->(@_);
    };
}

=encoding utf-8

=head1 NAME

RTx::QuickUpdateUserComments - Adds a quick-update comments portlet for the user summary and the rights ModifyUserComments and SeeUserComments

=head1 INSTALLATION 

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add these lines:

    Plugin("RTx::QuickUpdateUserComments");

    # Adds the comment edit box to the default user info portlets
    Set( @UserSummaryPortlets, qw/ExtraInfo EditComments CreateTicket ActiveTickets InactiveTickets/ );

    # Grant folks ModifyUserComments and/or SeeUserComments

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Thomas Sibley <trsibley@uw.edu>

=head1 BUGS

All bugs should be reported via email to
L<bug-RTx-QuickUpdateUserComments@rt.cpan.org|mailto:bug-RTx-QuickUpdateUserComments@rt.cpan.org>
or via the web at
L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RTx-QuickUpdateUserComments>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Thomas Sibley

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
