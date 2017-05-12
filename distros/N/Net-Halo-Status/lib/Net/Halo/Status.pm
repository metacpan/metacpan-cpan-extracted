package Net::Halo::Status;

use strict;
use warnings;
use Carp qw(croak);
use IO::Socket::INET;
use Data::Dumper;
use Encode;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw();
our %EXPORT_TAGS = (all => []);
our @EXPORT_OK = (@{$EXPORT_TAGS{all}});

our $VERSION = '0.02';

our $player_flags = {
  'NumberOfLives'       => ['Infinite', 1, 3, 5],
  'MaximumHealth'       => ['50%', '100%', '150%', '200%', '300%', '400%'],
  'Shields'             => [1, 0],
  'RespawnTime'         => [0, 5, 10, 15],
  'RespawnGrowth'       => [0, 5, 10, 15],
  'OddManOut'           => [0, 1],
  'InvisiblePlayers'    => [0, 1],
  'SuicidePenalty'      => [0, 5, 10, 15],
  'InfiniteGrenades'    => [0, 1],
  'WeaponSet'           => [
    'Normal', 'Pistols', 'Rifles', 'Plasma', 'Sniper', 'No Sniping',
    'Rocket Launchers', 'Shotguns', 'Short Range', 'Human', 'Covenant',
    'Classic', 'Heavy Weapons'
  ],
  'StartingEquipment'   => ['Custom', 'Generic'],
  'Indicator'           => ['Motion Tracker', 'Nav Points', 'None'],
  'OtherPlayersOnRadar' => ['No', 'All', undef, 'Friends'],
  'FriendIndicators'    => [0, 1],
  'FriendlyFire'        => ['Off', 'On', 'Shields Only', 'Explosives Only'],
  'FriendlyFirePenalty' => [0, 5, 10, 15],
  'AutoTeamBalance'     => [0, 1],

  # Team Flags
  'VehicleRespawn'      => [0, 30, 60, 90, 120, 180, 300],
  'RedVehicleSet'       => [
    'Default', undef, 'Warthogs', 'Ghosts', 'Scorpions', 'Rocket Warthogs',
    'Banshees', 'Gun Turrets', 'Custom'
  ],
  'BlueVehicleSet'      => [
    'Default', undef, 'Warthogs', 'Ghosts', 'Scorpions', 'Rocket Warthogs',
    'Banshees', 'Gun Turrets', 'Custom'
  ],
};

our $game_flags = {
  'GameType'          => [
    'Capture the Flag', 'Slayer', 'Oddball', 'King of the Hill', 'Race'
  ],
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
  my $class = shift;
  my $self = bless {}, $class;

  croak "$class requires an even number of parameters" if @_ % 2;

  my %params = @_;

  my $timeout = delete $params{Timeout};
  $timeout = 15 unless defined $timeout and $timeout >= 0;

  my $retry = delete $params{Retry};
  $retry = 2 unless defined $retry and $retry >= 0;

  my $server = delete $params{Server};
  $self->server($server) if defined $server;

  my $port = delete $params{Port};
  $self->port(2302) unless defined $port; # Default to 2302.
  $self->port($port) if defined $port;

  croak "$class doesn't know these parameters: ",
    join(', ', sort(keys(%params))) if scalar(keys(%params));

  return $self;
}

sub server ($) {
  my $self = shift;
  if (@_) { $self->{Server} = shift };
  return $self->{Server};
}

sub port ($) {
  my $self = shift;
  if (@_) { $self->{Port} = shift };
  return $self->{Port};
}


sub query () {
  my $self = shift;
  my $data = ''; # Receiving data buffer.
  my %data = ();

  eval {
    local $SIG{ALRM} = sub { die "Timed Out\n" };
    alarm 1;
    my $sock = new IO::Socket::INET (
      PeerAddr  => $self->server(),
      PeerPort  => $self->port(),
      Proto     => 'udp',
      Type      => SOCK_DGRAM,
      ReuseAddr => 1,
      Blocking  => 1,
    ) or croak "IO::Socket::INET->new() failed to bind: $@\n";

    $sock->send("\xFE\xFD\x00\x33\x8f\x02\x00\xff\xff\xff");
    $sock->recv($data, 16384);

    alarm 0;
  };
  alarm 0;

  if ($@) {
    $data{ERROR} = $@;
    return \%data;
  }

  if ($data eq '') {
    $data{ERROR} = 'DOWN';
  } else {
    $data =~ s/\x00+$//;
    my ($rules, $players, $score) = ($data =~ /^.{5}(.+?)\x00{3}[\x00-\x10](.+)\x00{2}[\x02\x00](.+$)/);
    my @parts = split(/\x00/, $data);
    %{$data{'Rules'}} = split(/\x00/, $rules);
    $data{'PlayerFlags'} = $self->decode_player_flags($data{'Rules'}{'player_flags'});
    $data{'GameFlags'} = $self->decode_game_flags($data{'Rules'}{'game_flags'});
    $data{'Players'} = $self->process_segment($players);
    $data{'Score'} = $self->process_segment($score);
  }

  foreach my $_Pflag (keys %{$data{PlayerFlags}->{Player}}) {
    $data{PlayerFlags}->{Player}->{$_Pflag} = $self->halo_player_flag($_Pflag, $data{PlayerFlags}->{Player}->{$_Pflag});
  }
  foreach my $_Tflag (keys %{$data{PlayerFlags}->{Team}}) {
    $data{PlayerFlags}->{Player}->{$_Tflag} = $self->halo_player_flag($_Tflag, $data{PlayerFlags}->{Team}->{$_Tflag});
  }
  foreach my $_Gflag (keys %{$data{GameFlags}}) {
    $data{GameFlags}->{$_Gflag} = $self->halo_game_flag($_Gflag, $data{GameFlags}->{$_Gflag});
  }

  return \%data;
}

sub decode_player_flags {
  my $self = shift;
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
  my $self = shift;
  my $str = shift;
  my $flags = { };
  return $flags if $str eq '' || $str !~ /^\d+$/;

  $flags->{'GameType'} = $str & 7;
  if ($flags->{'GameType'} == 1) { # CTF
    $flags->{'Assault'}           = ($str >> 3)  && 1;
    $flags->{'FlagMustReset'}     = ($str >> 5)  && 1;
    $flags->{'FlagAtHomeToScore'} = ($str >> 6)  && 1;
    $flags->{'SingleFlag'}        = ($str >> 7)  && 7;
  } elsif ($flags->{'GameType'} == 2) { # Slayer
    $flags->{'DeathBonus'}        = ($str >> 3)  && 1;
    $flags->{'KillPenalty'}       = ($str >> 5)  && 1;
    $flags->{'KillInOrder'}       = ($str >> 6)  && 1;
  } elsif ($flags->{'GameType'} == 3) { # Oddball
    $flags->{'RandomStart'}       = ($str >> 3)  && 1;
    $flags->{'SpeedWithBall'}     = ($str >> 5)  && 3;
    $flags->{'TraitWithBall'}     = ($str >> 7)  && 3;
    $flags->{'TraitWithoutBall'}  = ($str >> 9)  && 3;
    $flags->{'BallType'}          = ($str >> 11) && 3;
    $flags->{'BallSpawnCount'}    = ($str >> 13) && 31;
  } elsif ($flags->{'GameType'} == 4) { # Hill
    $flags->{'MovingHill'}        = ($str >> 3)  && 1;
  } elsif ($flags->{'GameType'} == 5) { # Race
    $flags->{'RaceType'}          = ($str >> 3)  && 3;
    $flags->{'TeamScoring'}       = ($str >> 5)  && 3;
  }

  return $flags;
}

sub halo_player_flag {
  my $self = shift;
  my $flag_name  = shift;
  my $flag_value = shift;

  if (defined($player_flags->{$flag_name}) && 
    defined($player_flags->{$flag_name}->[$flag_value])) {
    return $player_flags->{$flag_name}->[$flag_value];
  } else {
    return $flag_value;
  }
}

sub halo_game_flag {
  my $self = shift;
  my $flag_name  = shift;
  my $flag_value = shift;

  if(defined($game_flags->{$flag_name}) && 
    defined($game_flags->{$flag_name}->[$flag_value])) {
    return $game_flags->{$flag_name}->[$flag_value];
  } else {
    return $flag_value;
  }
}

sub process_segment {
  my $self = shift;
  my $str  = shift;

  my @parts = split(/\x00/, $str);
  my @fields = ();
  foreach (@parts) {
    last if $_ eq '';
    s/_.*$//;
    push @fields, $_;
  }

  my $info = {};
  my $ctr = 0;
  my $cur_item = '';
  foreach (splice(@parts, scalar(@fields) + (scalar(@parts) == scalar(@fields) ? 0 : 1))) {
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

Net::Halo::Status - Query Halo game servers for status.

=head1 SYNOPSIS

  use Net::Halo::Status;

  my $q = Net::Halo::Status->new(
    Server => '127.0.0.1',
    Port => '2302',
    Timeout => '3',
  );

  ...or...

  my $q = new Net::Halo::Status;
  $q->server('127.0.0.1');
  $q->port('2302');
  $q->timeout('3');

  my $status = $q->query(); # Sends query and returns result.

=head1 DESCRIPTION

Net::Halo::Status implements the Halo server status protcol; the same protocol
used when you click on a server in the network lobby in the Halo client. This
is a different protocol from the Halo client/server protocol, so, sadly, no
scripted rcon access or similar.


=head1 SEE ALSO

POE::Component::Client::Halo, from which most of the protocol code came.


=head1 AUTHOR

Terje Bless, E<lt>link@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Terje Bless

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
