package POE::Component::Client::Halo;

use strict;

use vars qw($VERSION);
$VERSION = '0.2';

sub DEBUG ()  { 0 };

use Carp qw(croak);
use Socket;
use Data::Dumper;
use POE qw(Session Wheel::SocketFactory);

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS
            $player_flags $game_flags);
@ISA = 'Exporter';
@EXPORT_OK = qw(halo_player_flag halo_game_flag);
%EXPORT_TAGS = (
    'flags' => [qw(halo_player_flag halo_game_flag)],
);

$player_flags = {
    'NumberOfLives'     => ['Infinite', 1, 3, 5],
    'MaximumHealth'     => ['50%', '100%', '150%', '200%', '300%', '400%'],
    'Shields'           => [1, 0],
    'RespawnTime'       => [0, 5, 10, 15],
    'RespawnGrowth'     => [0, 5, 10, 15],
    'OddManOut'         => [0, 1],
    'InvisiblePlayers'  => [0, 1],
    'SuicidePenalty'    => [0, 5, 10, 15],
    'InfiniteGrenades'  => [0, 1],
    'WeaponSet'         => ['Normal', 'Pistols', 'Rifles', 'Plasma', 'Sniper', 
                            'No Sniping', 'Rocket Launchers', 'Shotguns', 
                            'Short Range', 'Human', 'Covenant', 'Classic', 
                            'Heavy Weapons'],
    'StartingEquipment' => ['Custom', 'Generic'],
    'Indicator'         => ['Motion Tracker', 'Nav Points', 'None'],
    'OtherPlayersOnRadar'   => ['No', 'All', undef, 'Friends'],
    'FriendIndicators'  => [0, 1],
    'FriendlyFire'      => ['Off', 'On', 'Shields Only', 'Explosives Only'],
    'FriendlyFirePenalty'   => [0, 5, 10, 15],
    'AutoTeamBalance'   => [0, 1],

    # Team Flags
    'VehicleRespawn'    => [0, 30, 60, 90, 120, 180, 300],
    'RedVehicleSet'     => ['Default', undef, 'Warthogs', 'Ghosts', 
                            'Scorpions', 'Rocket Warthogs', 'Banshees', 
                            'Gun Turrets', 'Custom'],
    'BlueVehicleSet'     => ['Default', undef, 'Warthogs', 'Ghosts', 
                            'Scorpions', 'Rocket Warthogs', 'Banshees', 
                            'Gun Turrets', 'Custom'],
};

$game_flags = {
    'GameType'          => ['Capture the Flag', 'Slayer', 'Oddball', 
                            'King of the Hill', 'Race'],
    # CTF
    'Assault'           => [0, 1],
    'FlagMustReset'     => [0, 1],
    'FlagAtHomeToScore' => [0, 1],
    'SingleFlag'        => [0, 60, 120, 180, 300, 600],
    # Slayer
    'DeathBonus'        => [1, 0],
    'KillPenalty'       => [1, 0],
    'KillInOrder'       => [0, 1],
    # Oddball
    'RandomStart'       => [0, 1],
    'SpeedWithBall'     => ['Slow', 'Normal', 'Fast'],
    'TraitWithBall'     => ['None', 'Invisible', 'Extra Damage', 'Damage Resistant'],
    'TraitWithoutBall'  => ['None', 'Invisible', 'Extra Damage', 'Damage Resistant'],
    'BallType'          => ['Normal', 'Reverse Tag', 'Juggernaut'],
    'BallSpawnCount'    => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
    # King of the Hill
    'MovingHill'        => [0, 1],
    # Race
    'RaceType'          => ['Normal', 'Any Order', 'Rally'],
    'TeamScoring'       => ['Minimum', 'Maximum', 'Sum'],
};

sub new {
    my $type = shift;
    my $self = bless {}, $type;

    croak "$type requires an event number of parameters" if @_ % 2;

    my %params = @_;

    my $alias = delete $params{Alias};
    $alias = 'halo' unless defined $alias;

    my $timeout = delete $params{Timeout};
    $timeout = 15 unless defined $timeout and $timeout >= 0;

    my $retry = delete $params{Retry};
    $retry = 2 unless defined $retry and $retry >= 0;

    croak "$type doesn't know these parameters: ", join(', ', sort(keys(%params))) if scalar(keys(%params));

    POE::Session->create(
        inline_states => {
            _start            => \&_start,
            info            => \&info,
            detail          => \&detail,

            got_socket        => \&got_socket,
            got_response        => \&got_response,
            response_timeout    => \&response_timeout,
            debug_heap        => \&debug_heap,

            got_error        => \&got_error,
        },
        args => [ $timeout, $retry, $alias ],
    );

    return $self;
}

sub got_error {
    my ($operation, $errnum, $errstr, $wheel_id, $heap) = @_[ARG0..ARG3,HEAP];
    warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
    delete $heap->{w_jobs}->{$wheel_id}; # shut down that wheel
}

sub debug_heap {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    open(F, ">/tmp/halo-debug") || return;
    print F Dumper($heap);
    close(F) || return;
    $kernel->delay('debug_heap', 10);
}

sub _start {
    my ($kernel, $heap, $timeout, $retry, $alias) = @_[KERNEL, HEAP, ARG0..ARG3];
    $heap->{timeout} = $timeout;
    $heap->{retry} = $retry;
    $kernel->alias_set($alias);
    print STDERR "Halo object started.\n" if DEBUG;
    $kernel->yield('debug_heap') if DEBUG;
}

sub info {
    my ($kernel, $heap, $sender, $ip, $port, $postback) = @_[KERNEL, HEAP, SENDER, ARG0..ARG2];
    my ($identifier) = defined($_[ARG3]) ? $_[ARG3] : undef;
    print STDERR "Got request for $ip:$port info with postback $postback\n" if DEBUG;
    croak "IP address required to execute a query" unless defined $ip;
    croak "Port requred to execute a query" if !defined $port || $port !~ /^\d+$/;
    my $wheel = POE::Wheel::SocketFactory->new(
            RemoteAddress    => $ip,
            RemotePort    => $port,
            SocketProtocol    => 'udp',
            SuccessEvent    => 'got_socket',
            FailureEvent    => 'got_error',
    );
    $heap->{w_jobs}->{$wheel->ID()} = {
        ip        => $ip,
        port        => $port,
        postback    => $postback,
        session        => $sender->ID(),
        wheel        => $wheel,
        identifier    => $identifier,
        try        => 1,    # number of tries...
        action        => 'info',
    };
    return undef;
}

sub detail {
    my ($kernel, $heap, $sender, $ip, $port, $postback) = @_[KERNEL, HEAP, SENDER, ARG0..ARG2];
    my ($identifier) = defined($_[ARG3]) ? $_[ARG3] : undef;
    print STDERR "Got request for $ip:$port players with postback $postback\n" if DEBUG;
    croak "IP address required to execute a query" unless defined $ip;
    croak "Port requred to execute a query" if !defined $port || $port !~ /^\d+$/;
    my $wheel = POE::Wheel::SocketFactory->new(
            RemoteAddress    => $ip,
            RemotePort    => $port,
            SocketProtocol    => 'udp',
            SuccessEvent    => 'got_socket',
            FailureEvent    => 'got_error',
    );
    $heap->{w_jobs}->{$wheel->ID()} = {
        ip        => $ip,
        port        => $port,
        postback    => $postback,
        session        => $sender->ID(),
        wheel        => $wheel,
        identifier    => $identifier,
        try        => 1,    # number of tries...
        action        => 'detail',
    };
    return undef;
}

sub got_socket {
    my ($kernel, $heap, $socket, $wheelid) = @_[KERNEL, HEAP, ARG0, ARG3];

    $heap->{jobs}->{$socket} = delete($heap->{w_jobs}->{$wheelid});
    $kernel->select_read($socket, 'got_response');
    my $query = '';
    if($heap->{jobs}->{$socket}->{action} eq 'info') {
        $query = "\x9c\xb7\x70\x02\x0a\x01\x03\x08\x0a\x05\x06\x13\x33\x36\x0c\x00\x00";
    } elsif($heap->{jobs}->{$socket}->{action} eq 'detail') {
        $query = "\x33\x8f\x02\x00\xff\xff\xff";
    } else {
        die("Unknown action!");
    }
    send($socket, "\xFE\xFD\x00" . $query, 0);
    $heap->{jobs}->{$socket}->{timer} = $kernel->delay_set('response_timeout', $heap->{timeout}, $socket);
    print STDERR "Wheel $wheelid got socket and sent request\n" if DEBUG;
}

sub got_response {
    my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

    my $action = $heap->{jobs}->{$socket}->{action};

    $kernel->select_read($socket);
    $kernel->alarm_remove($heap->{jobs}->{$socket}->{timer}) if defined $heap->{jobs}->{$socket}->{timer};
    delete $heap->{jobs}->{$socket}->{timer};
    my $rsock = recv($socket, my $response = '', 16384, 0);

    my %data;
    if($response eq '') {
        $data{ERROR} = 'DOWN';
    } elsif($action eq 'info') {
        $response = substr($response, 5);
        my @parts = split(/\x00/, $response);
        $data{'Hostname'} = $parts[0];
        $data{'Version'} = $parts[1];
        $data{'Players'} = $parts[2];
        $data{'MaxPlayers'} = $parts[3];
        $data{'Map'} = $parts[4];
        $data{'Mode'} = $parts[5];
        $data{'Password'} = $parts[6];
        $data{'Dedicated'} = $parts[7];
        $data{'Classic'} = $parts[8];
        $data{'Teamplay'} = $parts[9];
    } elsif($action eq 'detail') {
        $response =~ s/\x00+$//;
        my ($rules, $players, $score) = ($response =~ /^.{5}(.+?)\x00{3}[\x00-\x10](.+)\x00{2}[\x02\x00](.+$)/);
        my @parts = split(/\x00/, $response);
        %{$data{'Rules'}} = split(/\x00/, $rules);
        $data{'PlayerFlags'} = decode_player_flags($data{'Rules'}{'player_flags'});
        $data{'GameFlags'} = decode_game_flags($data{'Rules'}{'game_flags'});
        $data{'Players'} = process_segment($players);
        $data{'Score'} = process_segment($score);
    } else {
        die("Unknown request!");
    }

    $kernel->post($heap->{jobs}->{$socket}->{session}, 
              $heap->{jobs}->{$socket}->{postback}, 
              $heap->{jobs}->{$socket}->{ip},
              $heap->{jobs}->{$socket}->{port},
              $heap->{jobs}->{$socket}->{action},
              $heap->{jobs}->{$socket}->{identifier},
              \%data);
    delete($heap->{jobs}->{$socket});
}

sub decode_player_flags {
    my $str = shift;
    my $flags = { };
    return $flags if $str eq '' || $str !~ /^\d+\,\d+$/;

    my ($player, $vehicle) = split(/\,/, $str);

    $flags->{'Player'}->{'NumberOfLives'} = $player & 3;
    $flags->{'Player'}->{'MaximumHealth'} = ($player >> 2) & 7;
    $flags->{'Player'}->{'Shields'} = ($player >> 5) & 1;
    $flags->{'Player'}->{'RespawnTime'} = ($player >> 6) & 3;
    $flags->{'Player'}->{'RespawnGrowth'} = ($player >> 8) & 3;
    $flags->{'Player'}->{'OddManOut'} = ($player >> 10) & 1;
    $flags->{'Player'}->{'InvisiblePlayers'} = ($player >> 11) & 1;
    $flags->{'Player'}->{'SuicidePenalty'} = ($player >> 12) & 3;
    $flags->{'Player'}->{'InfiniteGrenades'} = ($player >> 14) & 1;
    $flags->{'Player'}->{'WeaponSet'} = ($player >> 15) & 15;
    $flags->{'Player'}->{'StartingEquipment'} = ($player >> 19) & 1;
    $flags->{'Player'}->{'Indicator'} = ($player >> 20) & 3;
    $flags->{'Player'}->{'OtherPlayersOnRadar'} = ($player >> 22) & 3;
    $flags->{'Player'}->{'FriendIndicators'} = ($player >> 24) & 1;
    $flags->{'Player'}->{'FriendlyFire'} = ($player >> 25) & 3;
    $flags->{'Player'}->{'FriendlyFirePenalty'} = ($player >> 27) & 3;
    $flags->{'Player'}->{'AutoTeamBalance'} = ($player >> 29) & 1;

    $flags->{'Team'}->{'VehicleRespawn'} = ($vehicle & 7);
    $flags->{'Team'}->{'RedVehicleSet'} = ($vehicle >> 3) & 15;
    $flags->{'Team'}->{'BlueVehicleSet'} = ($vehicle >> 7) & 15;

    return $flags;
}

sub decode_game_flags {
    my $str = shift;
    my $flags = { };
    return $flags if $str eq '' || $str !~ /^\d+$/;

    $flags->{'GameType'} = $str & 7;
    if($flags->{'GameType'} == 1) { # CTF
        $flags->{'Assault'} = ($str >> 3) && 1;
        $flags->{'FlagMustReset'} = ($str >> 5) && 1;
        $flags->{'FlagAtHomeToScore'} = ($str >> 6) && 1;
        $flags->{'SingleFlag'} = ($str >> 7) && 7;
    } elsif($flags->{'GameType'} == 2) {    # Slayer
        $flags->{'DeathBonus'} = ($str >> 3) && 1;
        $flags->{'KillPenalty'} = ($str >> 5) && 1;
        $flags->{'KillInOrder'} = ($str >> 6) && 1;
    } elsif($flags->{'GameType'} == 3) {    # Oddball
        $flags->{'RandomStart'} = ($str >> 3) && 1;
        $flags->{'SpeedWithBall'} = ($str >> 5) && 3;
        $flags->{'TraitWithBall'} = ($str >> 7) && 3;
        $flags->{'TraitWithoutBall'} = ($str >> 9) && 3;
        $flags->{'BallType'} = ($str >> 11) && 3;
        $flags->{'BallSpawnCount'} = ($str >> 13) && 31;
    } elsif($flags->{'GameType'} == 4) {    # Hill
        $flags->{'MovingHill'} = ($str >> 3) && 1;
    } elsif($flags->{'GameType'} == 5) {    # Race
        $flags->{'RaceType'} = ($str >> 3) && 3;
        $flags->{'TeamScoring'} = ($str >> 5) && 3;
    }

    return $flags;
}

sub halo_player_flag {
    my ($flag_name, $flag_value) = (shift, shift);

    if(defined($player_flags->{$flag_name}) && 
       defined($player_flags->{$flag_name}->[$flag_value])) {
        return $player_flags->{$flag_name}->[$flag_value];
    } else {
        return undef;
    }
}

sub halo_game_flag {
    my ($flag_name, $flag_value) = (shift, shift);

    if(defined($game_flags->{$flag_name}) && 
       defined($game_flags->{$flag_name}->[$flag_value])) {
        return $game_flags->{$flag_name}->[$flag_value];
    } else {
        return undef;
    }
}

sub response_timeout {
    my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
    if($heap->{jobs}->{$socket}->{try} > ($heap->{retry} + 1)) {
        $kernel->post($heap->{jobs}->{$socket}->{session}, $heap->{jobs}->{$socket}->{postback},
                $heap->{jobs}->{$socket}->{ip},
                $heap->{jobs}->{$socket}->{port},
                $heap->{jobs}->{$socket}->{action},
                $heap->{jobs}->{$socket}->{identifier},
                { 'ERROR' => 'Timed out waiting for a response.'});
        delete($heap->{jobs}->{$socket});
    } else {
        print STDERR "Query timed out for $socket.  Retrying.\n" if DEBUG;
        my $query = '';
        if($heap->{jobs}->{$socket}->{action} eq 'info') {
            $query = "\x9c\xb7\x70\x02\x0a\x01\x03\x08\x0a\x05\x06\x13\x33\x36\x0c\x00\x00";
        } elsif($heap->{jobs}->{$socket}->{action} eq 'detail') {
            $query = "\x33\x8f\x02\x00\xff\xff\xff";
        } else {
            die("Unknown action!");
        }
        send($socket, "\xFE\xFD\x00" . $query, 0);
        $heap->{jobs}->{$socket}->{timer} = $kernel->delay_set('response_timeout', $heap->{timeout}, $socket);
        $heap->{jobs}->{$socket}->{try}++;
    }
}

sub process_segment {
    my $str = shift;

    my @parts = split(/\x00/, $str);
    my @fields = ();
    foreach(@parts) {
        last if $_ eq '';
        s/_.*$//;
        push(@fields, $_);
    }
    my $info = {};
    my $ctr = 0;
    my $cur_item = '';
    foreach(splice(@parts, scalar(@fields) + 1)) {
        if($ctr % scalar(@fields) == 0) {
            $cur_item = $_;
            $info->{$cur_item}->{$fields[0]} = $cur_item;
        } else {
            $info->{$cur_item}->{$fields[$ctr % scalar(@fields)]} = $_;
        }
        $ctr++;
    }
    return $info;
}

1;

__END__

=head1 NAME

  POE::Component::Client::Halo -- an implementation of the Halo query 
  protocol.

=head1 SYNOPSIS

  use Data::Dumper; # for the sample below
  use POE qw(Component::Client::Halo);

  my $halo = new POE::Component::Client::Halo(
        Alias => 'halo',
        Timeout => 15,
        Retry => 2,
  );

  $kernel->post('halo', 'info', '127.0.0.1', 2302, 'pbhandler', 'ident');

  $kernel->post('halo', 'detail', '127.0.0.1', 2302, 'pbhandler', 'ident');

  sub postback_handler {
      my ($ip, $port, $command, $identifier, $response) = @_;
      print "Halo query $command_executed on ";
      print " at $ip:$port";
      print " had a identifier of $identifier" if defined $identifier;
      print " returned from the server with:";
      print Dumper($response), "\n\n";
  }

=head1 DESCRIPTION

POE::Component::Client::Halo is an implementation of the Halo query 
protocol.  It was reverse engineered with a sniffer and two cups of 
coffee.  This is a preliminary release, based version 1.00.01.0580
of the dedicated server (the first public release).  It is capable
of handling multiple requests of different types in parallel.

PoCo::Client::Halo C<new> can take a few parameters:

=over 4

=item Alias => $alias_name

C<Alias> sets the name of the Halo component with which you will post events to.  By
default, this is 'halo'.

=item Timeout => $timeout_in_seconds

C<Timeout> specifies the number of seconds to wait for each step of the query procedure.
The number of steps varies depending on the server being accessed.

=item Retry => $number_of_times_to_retry

C<Retry> sets the number of times PoCo::Client::Halo should retry query requests.  Since
queries are UDP based, there is always the chance of your packets being dropped or lost.
After the number of retries has been exceeded, an error is posted back to the session
you specified to accept postbacks.

=back

=head1 METHODS

There are two methods that can be exported through the tag ':flags' -- C<halo_player_flag()>
and C<halo_game_flag()>.  They can be used to translate a specific game flag into its
English equivalent.

  $english_value = halo_player_flag($flag_name, $flag_value);
  $english_value = halo_game_flag($flag_name, $flag_value);

=head1 EVENTS

You can send two types of events to PoCo::Client::Halo.

=over 4

=item info

This will request the basic info block from the Halo server.  In the 
postback, you will get 4 or 5 arguments, depending on whether or not
you had a postback.  ARG0 is the IP, ARG1 is the port, ARG3 is the
command (for info queries, this will always be 'info'), ARG4 is a
hashref with the returned data, and ARG5 is your unique identifier
as set during your original post.  Here are the fields you'll get 
back in ARG4:

=over 4

=item * Map

=item * Teamplay

=item * Classic

=item * Mode

=item * MaxPlayers

=item * Hostname

=item * Password

=item * Version

=item * Dedicated

=item * Players

=back


=item detail

This request more detailed information about the server, as well as
its rules, player information, and team score.  Like 'info', you'll 
get 4-5 arguments passed to your postback function.  ARG4 contains 
a HoHoH's:
  {
      'Score' => {
          'Red' => {
              'team' => 'Red',
              'score' => '17'
          },
          'Blue' => {
              'team' => 'Blue',
              'score' => '17'
          }
      },
      'Players' => {
          'ZETA' => {
              'score' => '0',
              'team' => '0',
              'ping' => '',
              'player' => 'ZETA'
          },
          'badmofo' => {
              'score' => '3',
              'team' => '0',
              'ping' => '',
              'player' => 'badmofo'
          },
      },
      'Rules' => {
          'gametype' => 'Slayer',
          'hostport' => '',
          'fraglimit' => '50',
          'mapname' => 'dangercanyon',
          'gamever' => '01.00.01.0580',
          'teamplay' => '1',
          'password' => '0',
          'game_flags' => '26',
          'player_flags' => '1941966980,2',
          'game_classic' => '0',
          'gamevariant' => 'Team Slayer',
          'gamemode' => 'openplaying',
          'hostname' => 'DivoNetworks',
          'maxplayers' => '16',
          'dedicated' => '1',
          'numplayers' => '2'
      }
  };

At the time of this module's release, ping information was not
available within the info packets.  They might be made public
later on, so I left them in the response.

You can translate the player and game flags with the two methods
mentioned above.  Take a look at the sample program to see how
it's done.

=head1 ERRORS

The errors listed below are ones that will be posted back to you 
in the 'response' field.

=over 4

=item * ERROR: Timed out waiting for response

Even after retrying, there was no response to your request command.

=item There are other fatal errors that are handled with croak().

=back

=head1 BUGS

=item
No tests are distributed with the module yet.  There is a sample,
though.

=head1 ACKNOWLEDGEMENTS

=item Rocco Caputo

Yay!

=item Divo Networks

Thanks for loaning me servers to test against.

=item Brian Hurley

He decoded all the player and game flags after several long 
nights.  Thanks.

=head1 AUTHOR & COPYRIGHTS

POE::Component::Client::Halo is Copyright 2001-2003 by Andrew A. Chen 
<achen-poe-halo@divo.net>.  All rights are reserved.  
POE::Component::Client::Halo is free software; you may redistribute it 
and/or modify it under the same terms as Perl itself.

=cut
