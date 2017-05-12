package POE::Component::IRC::Plugin::MultiProxy;
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::IRC::Plugin::MultiProxy::VERSION = '0.01';
}

use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use Digest::MD5 qw(md5_hex);
use POE;
use POE::Component::IRC::Plugin::MultiProxy::Away;
use POE::Component::IRC::Plugin::MultiProxy::ClientManager;
use POE::Component::IRC::Plugin::MultiProxy::Recall;
use POE::Component::IRC::Plugin::MultiProxy::State;
use POE::Filter::IRCD;
use POE::Filter::Line;
use POE::Filter::Stackable;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;
use Socket qw(inet_ntoa);

my $CRYPT_SALT = 'erxpnUyerCerugbaNgfhW';

sub new {
    my ($package, %params) = @_;
    my $self = bless \%params, $package;

    if (!defined $self->{Password}) {
        croak __PACKAGE__.' requires a Password argument';
    }
    if (!defined $self->{Listen_port}) {
        croak __PACKAGE__.' requires a Listen_port argument';
    }
    return $self;
}

sub PCI_register {
    my ($self, $irc, %args) = @_;
    $self->{net2irc}{$args{network}} = $irc;
    $self->{irc2net}{$irc} = $args{network};

    $self->{plugins}{ $args{network} } = [
        [MultiProxyState => POE::Component::IRC::Plugin::MultiProxy::State->new()],
        [MultiProxyAway  => POE::Component::IRC::Plugin::MultiProxy::Away->new(
            Message => $self->{Away_msg}
        )],
        [MultiProxyRecall => POE::Component::IRC::Plugin::MultiProxy::Recall->new(
            Mode => $self->{Recall_mode},
        )],
        [MultiProxyClientManager => POE::Component::IRC::Plugin::MultiProxy::ClientManager->new()],
    ];

    for my $plugin (@{ $self->{plugins}{ $args{network} } }) {
        my ($name, $object) = @$plugin;
        $irc->plugin_add($name, $object);
    }

    if (!$self->{registered}) {
        POE::Session->create(
            object_states => [
                $self => [qw(
                    _start
                    _client_error
                    _client_input
                    _listener_accept
                    _listener_failed
                    _shutdown
                )],
            ],
        );
    }

    $self->{registered}++;

    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = @_;
    my $network = delete $self->{irc2net}{$irc};

    $self->{registered}--;
    $poe_kernel->call($self->{session_id}, '_shutdown') if !$self->{registered};

    for my $plugin (@{ $self->{plugins}{$network} }) {
        $irc->plugin_del($plugin->[1]);
    }
    delete $self->{net2irc}{$network};

    return 1;
}

sub _start {
    my ($self) = $_[OBJECT];

    $self->{session_id} = $_[SESSION]->ID;
    $self->{filter} = POE::Filter::Stackable->new(
        Filters => [
            POE::Filter::Line->new(),
            POE::Filter::IRCD->new(),
        ],
    ) if !defined $self->{filter};

    $self->{listener} = POE::Wheel::SocketFactory->new(
        BindAddress  => $self->{Listen_host},
        BindPort     => $self->{Listen_port},
        SuccessEvent => '_listener_accept',
        FailureEvent => '_listener_failed',
        Reuse        => 'yes',
    );

    if (defined $self->{SSL_key} && defined $self->{SSL_cert}) {
        require POE::Component::SSLify;
        POE::Component::SSLify->import(qw(Server_SSLify SSLify_Options));

        eval { SSLify_Options($self->{SSL_key}, $self->{SSL_cert}) };
        chomp $@;
        die "Unable to load SSL key ($self->{SSL_key}) or certificate ($self->{SSL_cert}): $@\n" if $@;

        eval { $self->{listener} = Server_SSLify($self->{listener}) };
        chomp $@;
        die "Unable to SSLify the listener: $@\n" if $@;
    }

    return;
}

sub _shutdown {
    my ($self) = $_[OBJECT];
    delete $self->{$_} for qw(wheels listener session_id);
    return;
}

sub _client_error {
    my ($self, $id) = @_[OBJECT, ARG3];
    delete $self->{wheels}{$id};
    return;
}

sub _client_input {
    my ($self, $input, $id) = @_[OBJECT, ARG0, ARG1];
    my $info = $self->{wheels}{$id};

    if ($input->{command} =~ /(PASS)/) {
        $info->{lc $1} = $input->{params}[0];
    }
    elsif ($input->{command} =~ /(NICK|USER)/) {
        $info->{lc $1} = $input->{params}[0];
        $info->{registered}++;
    }

    if ($info->{registered} == 2) {
        AUTH: {
            last AUTH if !defined $info->{pass};
            $info->{pass} = md5_hex($info->{pass}, $CRYPT_SALT) if length $self->{Password} == 32;
            last AUTH unless $info->{pass} eq $self->{Password};
            last AUTH unless my $irc = $self->{net2irc}{ $info->{nick} };

            $info->{wheel}->put("$info->{nick} NICK :".$irc->nick_name);
            my $clients = $self->{plugins}{ $info->{nick} }[-1][1];
            $clients->add_client($info->{socket});
            $irc->send_event(irc_proxy_authed => $id);
            delete $self->{wheels}{$id};
            return;
        }

        # wrong password or nick (network), dump the client
        $info->{wheel}->put('ERROR :Closing Link: * [' . ( $info->{user} || 'unknown' ) . '@' . $info->{ip} . '] (Unauthorised connection)' );
        delete $self->{wheels}{$id};
    }

    return;
}

sub _listener_failed {
    my ($self, $error) = @_[OBJECT, ARG2];
    warn "Failed to spawn listener: $error; aborted\n";
    $poe_kernel->call($self->{session_id}, '_shutdown');
    return;
}

sub _listener_accept {
    my ($self, $socket, $peer_addr) = @_[OBJECT, ARG0, ARG1];

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle       => $socket,
        InputFilter  => $self->{filter},
        OutputFilter => POE::Filter::Line->new(),
        InputEvent   => '_client_input',
        ErrorEvent   => '_client_error',
    );

    my $id = $wheel->ID();
    $self->{wheels}{$id}{wheel} = $wheel;
    $self->{wheels}{$id}{ip} = inet_ntoa($peer_addr);
    $self->{wheels}{$id}{registered} = 0;
    $self->{wheels}{$id}{socket} = $socket;

    return;
}

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::MultiProxy - A multi-server IRC proxy

=head1 SYNOPSIS

 use POE::Component::IRC::Plugin::MultiProxy;

 my $proxy = POE::Component::IRC::Plugin::MultiProxy->new(
     Listen_port = 12345,
     Password    = 'foobar',
 );

 $irc->plugin_add(
     MultiProxy => $proxy,
     network    => 'freenode',
 );

=head1 METHODS

=head2 C<new>

Creates a new MultiProxy plugin object. Takes the following arguments:

B<'Password'> (required), the password you will use when connecting to the
proxy.

B<'Listen_port'> (required), the port you want the proxy to listen on.

B<'Listen_host'> (optional), the host you want the proxy to listen on.
Defaults to '0.0.0.0'.

B<'Away_msg'> (optional), the away message you want to use when no clients
are connected.

B<'SSL_key'>, the name of a file containing an SSL key for the listener to
use, if you want to enable SSL.

B<'SSL_cert'>, the name of a file containing an SSL certificate for the
listener to use, if you want to enable SSL.

B<'Recall_mode'>, how you want messages to be recalled. Available modes are:

=over 4

=item B<'missed'> (the default): MultiProxy will only recall the channel
messages you missed since the last time you detached from MultiProxy.

=item B<'none'>: MultiProxy will not recall any channel messages.

=item B<'all'>: MultiProxy will recall all channel messages.

=back

B<Note>: MultiProxy will always recall I<private messages> that you missed while
you were away, regardless of this option.

=head1 TODO

Look into using L<POE::Component::Server::IRC|POE::Component::Server::IRC> as
an intermediary for multiple clients.

Keep recall messages away from prying eyes, instead of in F</tmp>.

Add proper tests.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Other useful IRC bouncers:

=over

=item L<http://miau.sourceforge.net>

=item L<http://znc.sourceforge.net>

=item L<http://code.google.com/p/dircproxy/>

=item L<http://www.ctrlproxy.org>

=item L<http://www.psybnc.at>

=item L<http://irssi.org/documentation/proxy>

=item L<http://freshmeat.net/projects/bip>

=back

=cut
