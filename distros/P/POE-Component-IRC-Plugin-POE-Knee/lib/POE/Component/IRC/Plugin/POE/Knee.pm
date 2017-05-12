package POE::Component::IRC::Plugin::POE::Knee;
$POE::Component::IRC::Plugin::POE::Knee::VERSION = '1.12';
#ABSTRACT: A POE::Component::IRC plugin that runs Acme::POE::Knee races.

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use Math::Random;
use POE;
use POE::Component::IRC::Plugin qw(:ALL);
use POE::Component::IRC::Common qw(:ALL);

sub new {
  my $package = shift;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  $args{stages} = 5 unless $args{stages} and $args{stages} =~ /^\d+$/ and $args{stages} <= 30;
  bless \%args, $package;
}

sub PCI_register {
  my ($self,$irc) = @_;
  die "This plugin must be used with POE::Component::IRC::State or a subclass of that\n"
	  unless $irc->isa('POE::Component::IRC::State');
  $self->{irc} = $irc;
  $irc->plugin_register( $self, 'SERVER', qw(public) );
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => [ qw(_shutdown _start _race_on _run) ],
	],
  )->ID();
  return 1;
}

sub PCI_unregister {
  my ($self,$irc) = splice @_, 0, 2;
  $poe_kernel->call( $self->{session_id} => '_shutdown' );
  delete $self->{irc};
  return 1;
}

sub S_public {
  my ($self,$irc) = splice @_, 0, 2;
  my ($nick,$userhost) = ( split /!/, ${ $_[0] } )[0..1];
  my $channel = ${ $_[1] }->[0];
  my $what = ${ $_[2] };
  my $mapping = $irc->isupport('CASEMAPPING');
  my $mynick = $irc->nick_name();
  my ($command) = $what =~ m/^\s*\Q$mynick\E[\:\,\;\.]?\s*(.*)$/i;
  return PCI_EAT_NONE unless $command;
  my @cmd = split /\s+/, $command;
  return PCI_EAT_NONE unless uc( $cmd[0] ) eq 'POEKNEE';
  if ( $self->{_race_in_progress} ) {
	$irc->yield( privmsg => $channel => "There is already a race in progress" );
	return PCI_EAT_NONE;
  }
  $poe_kernel->post( $self->{session_id}, '_race_on', $channel, $cmd[1] );
  return PCI_EAT_NONE;
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{_race_in_progress} = 0;
  $self->{session_id} = $_[SESSION]->ID();
  $kernel->refcount_increment( $self->{session_id}, __PACKAGE__ );
  undef;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alarm_remove_all();
  $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ );
  undef;
}

sub _race_on {
  my ($kernel,$self,$channel,$stages) = @_[KERNEL,OBJECT,ARG0,ARG1];
  $stages = $self->{stages} unless $stages and $stages =~ /^\d+$/ and $stages <= 30;
  $self->{_race_in_progress} = 1;
  $self->{_distance} = $stages;
  $self->{_progress} = [ ];
  my $irc = $self->{irc};
  my @channel_list = $irc->channel_list($channel);
  my $seed = 5;
  my $start = 'POE::Knee Race is on! ' . scalar @channel_list . ' ponies over ' . $self->{_distance} . ' stages.';
  push @{ $self->{_progress} }, join(' ', _stamp(), $start);
  $irc->yield('ctcp', $channel, 'ACTION ' . $start );
  foreach my $nick ( @channel_list ) {
     #my $nick_modes = $irc->nick_channel_modes($channel,$nick);
     #$seed += rand(3) if $nick_modes =~ /o/;
     #$seed += rand(2) if $nick_modes =~ /h/;
     #$seed += rand(1) if $nick_modes =~ /v/;
     my $delay = random_uniform(1,0,$seed);
     push @{ $self->{_progress} }, join(' ', _stamp(), $nick, "($delay)", "is off!");
     $kernel->delay_add( '_run', $delay, $nick, $channel, $seed, 1 );
  }
  undef;
}

sub _run {
  my ($kernel,$self,$nick,$channel,$seed,$stage) = @_[KERNEL,OBJECT,ARG0..ARG3];
  push @{ $self->{_progress} }, _stamp() . " $nick reached stage " . ++$stage;
  if ( $stage > $self->{_distance} ) {
	# Stop the race
	$kernel->alarm_remove_all();
	my $result = "$nick! Won the POE::Knee race!";
	$self->{irc}->yield( 'privmsg', $channel, $result );
	push @{ $self->{_progress} }, _stamp() . " " . $result;
	my $race_result = delete $self->{_progress};
	$self->{irc}->yield( '__send_event', 'irc_poeknee_results', $channel, $race_result );
	  $self->{_race_in_progress} = 0;
	return;
  }
  if ( $stage > $self->{_race_in_progress} ) {
	$self->{irc}->yield( 'ctcp', $channel, "ACTION $nick! leads at stage $stage" );
	$self->{_race_in_progress}++;
  }
  $kernel->delay_add( '_run', random_uniform(1,0,$seed), $nick, $channel, $seed, $stage );
  undef;
}

sub _stamp {
  return join('.', gettimeofday);
}

qq[Ride the ponies];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::IRC::Plugin::POE::Knee - A POE::Component::IRC plugin that runs Acme::POE::Knee races.

=head1 VERSION

version 1.12

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE qw(Component::IRC::State Component::IRC::Plugin::POE::Knee);

  my $nickname = 'PoeKnee' . $$;
  my $ircname = 'PoeKnee the Sailor Bot';
  my $ircserver = 'irc.blah.org';
  my $port = 6667;
  my $channel = '#IRC.pm';

  my $irc = POE::Component::IRC::State->spawn(
        nick => $nickname,
        server => $ircserver,
        port => $port,
        ircname => $ircname,
        debug => 0,
        plugin_debug => 1,
        options => { trace => 0 },
  ) or die "Oh noooo! $!";

  POE::Session->create(
        package_states => [
                'main' => [ qw(_start irc_001 irc_poeknee_results) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    # Create and load our CTCP plugin
    $irc->plugin_add( 'PoeKnee' =>
        POE::Component::IRC::Plugin::POE::Knee->new( stages => 8 ) );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    undef;
  }

  sub irc_001 {
    $irc->yield( join => $channel );
    undef;
  }

  sub irc_poeknee_results {
    my ($channel,$results) = @_[ARG0,ARG1];
    print "$channel\n";
    print "$_\n" for @{ $results };
    undef;
  }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::POE::Knee, is a L<POE::Component::IRC> plugin that runs L<Acme::POE::Knee> style
horse races on IRC channels using the channel member list to generate the POE::Knees. >:)

=for Pod::Coverage PCI_register PCI_unregister S_public

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new plugin object. You may specify the following optional parameters:

  'stages' => the number of stages involved in the race, default is 5;

=back

=head1 IRC INPUT

=over

=item C<POEKNEE>

If your bot is addressed by name with the command 'POEKNEE' (case doesn't matter), with optional number of stages,
a POE::Knee race is started.

  GumbyBRAIN: POEKNEE 10

=back

=head1 OUTPUT

Apart from the output seen on the IRC channel where a POE::Knee race is currently underway, at the end of a race
the following 'irc' event is generated.

=over

=item C<irc_poeknee_results>

Generated each time a POE::Knee race finishes.

  ARG0, the channel where the race was run;
  ARG1, an arrayref containing lots of potentially uninteresting data;

=back

=head1 SEE ALSO

L<POE::Component::IRC>

L<Acme::POE::Knee>

=head1 AUTHORS

=over 4

=item *

Chris Williams

=item *

Jos Boumans

=item *

Rocco Caputo

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams, Jos Boumans and Rocco Caputo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
