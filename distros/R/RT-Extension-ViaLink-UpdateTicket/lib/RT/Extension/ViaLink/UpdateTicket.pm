use 5.008003;
use strict;
use warnings;

=head1 NAME

RT::Extension::ViaLink::UpdateTicket - update tickets without credentials using a link

=head1 DESCRIPTION

This extension allow you to generate a link with arguments that can be used to update
a ticket without credentials. For example:

http://rt.example.com/NoAuth/ViaLink/UpdateTicket/12/075f0ac5681a0b8d?Status=resolved&id=1

This link set status of ticket #1 to resolved using user #12's identity (usually 'root').
Any person can use this link, but link can do only what's encoded in its content. Any
changes in this link will prohibited and ignored.

To generate a link use L</Generate> method described below.

=head1 INSTALLATION

This extension works with RT 3.8.1 or newer, to install it use the following commands:

    perl Makefile.PL
    make
    make install

In the RT_SiteConfig.pm update @Plugins option:

    Set( @Plugins, qw(RT::Extension::ViaLink::UpdateTicket ...other extensions...) );

=cut

package RT::Extension::ViaLink::UpdateTicket;

our $VERSION = '0.02';

=head1 METHODS

=head2 Generate

To generate a link use the following code or similar:

    my $link = RT::Extension::ViaLink::UpdateTicket->Generate(
        $session{'CurrentUser'}, id => $TicketObj->id, Status => 'resolved',
    );

First argument is L<RT::User> object everything else are names arguments. id of
a ticket you want to update is mandatory, everything else is optional. Arguments
and names are the same as in /Ticket/Display.html and handled by Process* methods
in L<RT::Interface::Web>. Simple operations are simple, you can cahnge Status, Queue,
Owner, dates and other fields, but you can change CFs, links and watchers as well.

User object you provide should be loaded and exist in the DB, all actions stored
in the link will be done using odentity of this user.

=cut

sub Generate {
    my $self = shift;
    my $user = shift;
    my %args = @_;

    my $qs = $self->QueryString( \%args );

    my $res = RT->Config->Get('WebBaseURL');
    $res .= '/NoAuth/ViaLink/UpdateTicket/'
        . $user->id .'/'. $user->GenerateAuthString($qs)
        .'?'. $qs;
    return $res;
}

sub Check {
    my $self = shift;
    my $user = shift;
    my $token = shift;
    my %args = @_;

    return $user->ValidateAuthString(
        $token => $self->QueryString( \%args )
    );
}

require RT::Interface::Web;
sub QueryString {
    my $self = shift;
    my $args = shift;

    my $qs = '';
    foreach my $key ( sort keys %$args ) {
        my $value = $args->{ $key };
        next unless defined $value;

        RT::Interface::Web::EscapeUTF8(\$key);
        if( UNIVERSAL::isa( $value, 'ARRAY' ) ) {
            my @values = @$value;
            foreach (@values) {
                RT::Interface::Web::EscapeUTF8(\$_);
                $qs .= '&'. $key .'='. $_;
            }
        } else {
            RT::Interface::Web::EscapeUTF8(\$value);
            $qs .= '&'. $key ."=". $value;
        }
    }
    $qs =~ s/^&//;
    return $qs;
}

1;

=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut
