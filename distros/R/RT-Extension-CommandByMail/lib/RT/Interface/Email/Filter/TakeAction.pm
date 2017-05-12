package RT::Interface::Email::Filter::TakeAction;

use warnings;
use strict;

use RT::Extension::CommandByMail;

=head1 NAME

RT::Interface::Email::Filter::TakeAction - Change metadata of ticket via email

=head1 DESCRIPTION

This filter action is built to work with the email plugin interface for
RT 4.2 and earlier. As such, it implements the C<GetCurrentUser> method
and provides all functionality via that plugin hook.

The email plugin interface is changed in RT 4.4. For details on the
implementation for RT 4.4 and later, see
L<RT::Interface::Email::Action::CommandByMail>.

=head1 METHODS

=head2 GetCurrentUser

Returns a CurrentUser object and an appropriate AuthLevel code to be
interpreted by RT's email gateway.

=cut

sub GetCurrentUser {
    my %args = (
        Message       => undef,
        RawMessageRef => undef,
        CurrentUser   => undef,
        AuthLevel     => undef,
        Action        => undef,
        Ticket        => undef,
        Queue         => undef,
        @_
    );

    unless ( $args{'CurrentUser'} && $args{'CurrentUser'}->Id ) {
        $RT::Logger->error(
            "Filter::TakeAction executed when "
            ."CurrentUser (actor) is not authorized. "
            ."Most probably you want to add Auth::MailFrom plugin before "
            ."Filter::TakeAction in the \@MailPlugins config."
        );
        return ( $args{'CurrentUser'}, $args{'AuthLevel'} );
    }

    # If the user isn't asking for a comment or a correspond,
    # bail out
    unless ( $args{'Action'} =~ /^(?:comment|correspond)$/i ) {
        return ( $args{'CurrentUser'}, $args{'AuthLevel'} );
    }

    # If only a particular group may perform commands by mail,
    # bail out
    my $new_config = RT->can('Config') && RT->Config->can('Get');
    my $group_id = $new_config
                 ? RT->Config->Get('CommandByMailGroup')
                 : $RT::CommandByMailGroup;

    if (defined $group_id) {
        my $group = RT::Group->new($args{'CurrentUser'});
        $group->Load($group_id);

        if (!$group->HasMemberRecursively($args{'CurrentUser'}->PrincipalObj)) {
            $RT::Logger->debug("CurrentUser not in CommandByMailGroup");
            return ($args{'CurrentUser'}, $args{'AuthLevel'});
        }
    }

    my $return_ref = RT::Extension::CommandByMail::ProcessCommands(%args);

    # make sure ticket is loaded
    $args{'Ticket'}->Load( $return_ref->{'Transaction'}->ObjectId );

    if ( ref $return_ref eq 'HASH' ) {
        # ProcessCommands returned with values, use them in the return code
        return ( $return_ref->{'CurrentUser'}, $return_ref->{'AuthLevel'} );
    }

}

1;
