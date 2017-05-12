package Net::Social::Service::Jabber;

use strict;
use base qw(Net::Social::Service);
use Jabber::NodeFactory;
use Jabber::Connection;
use Net::Social qw(:all);
use Data::Dumper;
use vars qw($VERSION);

$VERSION = "0.1";


my $resource = __PACKAGE__."-".$VERSION;

=head1 NAME

Net::Social::Service::Jabber - a Jabber plugin for Net::Social

=head1 PARAMS

For reading C<Net::Social::Service::Jabber> needs

=over 4

=item username

Your Jabber username in the form <id>@<server>

=item

Your Jabber password. 

=back

=cut

sub params {(
    read => {
        "username" => { required    => 1, 
                        description => "Your Jabber UserName (in the form <name>@<host>",
                    },
        "password" => { required    => 1, 
                        description => "Your Jabber password",
                        sensitive   => 1,
                    },
    },
)}

=head1 METHODS

=head2 friends

Returns your friends. It defines the keys C<id>, C<username>, C<name> and C<type>.

=cut

sub friends {
    my $self = shift;
    return () unless $self->{_logged_in};
    my $user = $self->{_details}->{username};
    my $pass = $self->{_details}->{password};
    my $port = $self->{_details}->{port} || 5222;
    my ($name, $server) = split '@', $user; 

    # Do we want to create a per object jabber connection or per call?
    my $nf       = Jabber::NodeFactory->new;
    my $c        = Jabber::Connection->new(server => $server.':'.$port, log => 0);
    my $running  = 1;
    my @users;

    $c->connect || die $c->lastError;
    $c->register_handler('iq', sub { on_iq_message(\@users, \$running, @_) } );
    $c->auth($name, $pass, $resource);

    my $iq = $nf->newNode('iq');
    $iq->attr('type', Jabber::NS::IQ_GET());
    $iq->attr('id', 'roster_get_id');
    $iq->insertTag('query', Jabber::NS::NS_ROSTER());


    $c->send($iq);

    my $t0 = time;
    while ($running) {
        $c->process(1);
        last if time-$t0 > 10;
    }
    $c->disconnect;
    return @users;
}
my %type_convert = ( 
    to   => FRIENDED, 
    from => FRIENDED_BY,
    both => MUTUAL,
    none => NONE,
);

sub on_iq_message {
    my $users   = shift;
    my $running = shift;
    my $node    = shift;
    return unless $node->attr('id') eq 'roster_get_id';
    my $query = $node->getTag('query');
    foreach my $item ($query->getChildren) {
        my %user = (
            id       => $item->attr('jid'),
            username => $item->attr('name'),
            name     => $item->attr('nickname') || $item->attr('name'),
            type     => $type_convert{$item->attr('subscription')},
        );
        push @$users, \%user;
    }
    $$running = 0;
}

# Not quite ready yet
#sub add_friend {
#    my $self   = shift;
#    my $friend = shift;
#    my $nf     = $self->{_node_factory};
#    my $c      = $self->{_connection};
#
#   my $iq = $nf->newNode('iq');
#   $iq->attr('type', Jabber::NS::IQ_SET());
#   $iq->attr('id', 'roster_set_id');
#
#   my $item = $nf->newNode('item');
#   $item->attr('jid',  $friend);
#   $item->attr('name', $name) if defined $name;
#   $item->insertTag('group')->data('friends');
#
#   $iq->insertTag('query', Jabber::NS::NS_ROSTER())->rawdata($item->toStr);
#
#   die $iq->toStr;
#   $c->send($iq);
#}
# sub DESTROY { $_->{connection}->disconnect }

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright, 2007 - Simon Wistow

Distributed under the same terms as Perl itself

=cut


1;
