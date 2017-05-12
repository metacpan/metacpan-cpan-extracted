# Roku::RCP.pm
#
# Copyright (c) 2007 Robert J Powers <batman@cpan.org>. All rights reserved.
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.

package Roku::RCP;

use strict;

use Net::Cmd;
use IO::Socket::INET;
use vars qw(@ISA $VERSION);

$VERSION = '0.08';
@ISA = qw(Net::Cmd IO::Socket::INET);

our %MetaData = ('TransactionInitiated' => 1, #Start of results
		 'ListResultSize'       => 1,
		 'ListResultEnd'        => 2, #End of results
		 'TransactionComplete'  => 2,
		 );
sub new
{
 my $self = shift;
 my $class = ref($self) || $self;
 my ($host, %args);
 $host = shift if (scalar(@_) % 2);
 %args = @_;

 $args{Host} = $host if $host;
 $args{Timeout} = 60 unless defined $args{Timeout};

 return undef unless $args{Host};

 $self = $class->SUPER::new(PeerAddr => $args{Host},
			    PeerPort => $args{Port} || '5555',
			    Proto    => 'tcp',
			    Timeout  => $args{Timeout});
 
 return undef unless defined $self;
 $self->debug($args{Debug});
 ${*$self}{'_RawResults'} = $args{RawResults};

 $self->autoflush(1);

 if (!$self->response("ready")) {
   $self->close();
   return undef;
 }

### if ($args{AutoRPC} && !$self->command('rcp')->response("ready")) {

 return bless $self, $class;
}

sub unRaw
{
  my $self = shift;
  my $raw = ${*$self}{'_RawResults'};
  ${*$self}{'_RawResults'} = 0;
  return $raw;
}

sub ServerConnectByName
{
    my ($self, $name) = @_;
    my (@servers, $i, $raw);
    return undef unless $name;
    $self->ServerDisconnect();

    $raw = $self->unRaw();
    @servers = $self->ListServers();
    ${*$self}{'_RawResults'} = $raw;
    
    foreach $i (0..$#servers) {
	if ($servers[$i] =~ m/$name/i) {
	    $self->myLog("Attempting to connect to $servers[$i]: $i");
	    return ($self->ServerConnect($i));
	    return undef;
	}
    }
    $self->myLog("No matching server found for $name");
    return undef;
}

sub PlayPlaylist
{
    my ($self, $name) = @_;
    my $raw = $self->unRaw();
    my @plists = $self->ListPlaylists();
    my $i;
    ${*$self}{'_RawResults'} = $raw;
    foreach $i (0..$#plists) {
	if ($plists[$i] =~ m/$name/i) {
	    $self->myLog("Attempting to queue and play $plists[$i]: $i");
	    $self->SetListResultType("partial");
	    $self->ListPlaylistSongs($i);
	    return $self->QueueAndPlay(0);
	}
    }
    $self->myLog("No matching playlist found for $name");
    return undef;
}

sub Standby
{
  my $self = shift;
  return $self->IrDispatchCommand('CK_POWER_OFF');
}

sub PlayArtist
{
    my ($self, $name) = @_;

    $self->myLog("Attempting to queue and play artist $name");
    $self->SetListResultType("partial") or return undef;
    $self->SetBrowseFilterArtist($name) or return undef;
    $self->ListSongs() or return undef;
    return $self->QueueAndPlay(0);
}

sub PlayAlbum
{
    my ($self, $name) = @_;

    $self->myLog("Attempting to queue and play album $name");
    $self->SetListResultType("partial") or return undef;
    $self->SetBrowseFilterAlbum($name) or return undef;
    $self->ListSongs() or return undef;
    return $self->QueueAndPlay(0);
}

sub PlaySong
{
    my ($self, $name) = @_;

    $self->myLog("Attempting to queue and play song $name");
    $self->SetListResultType("partial") or return undef;
    $self->SearchSongs($name) or return undef;
    return $self->QueueAndPlay(0);
}

sub InsertSong
{
    my ($self, $name, $position) = @_;
    $position = 1 unless defined $position;

    $self->myLog("Attempting to search for songs matching $name and insert them into Queue at position $position");
    $self->SearchSongs($name) or return undef;
    return $self->NowPlayingInsert("all", $position);
}

sub AUTOLOAD
{
  my $self = shift;
  my $rcp_cmd;
  use vars qw($AUTOLOAD);
  if ($AUTOLOAD =~ m/::([^:]+)$/o) {
    $rcp_cmd = $1;
    $self->myLog("Issuing: $AUTOLOAD @_");
    return $self->command($rcp_cmd,@_)->response(undef, $AUTOLOAD);
  }
  return undef;
}

sub Quit
{
 my $self = shift;
 $self->command("exit");
 $self->close;
}

sub DESTROY
{
 my $self = shift;

 $self->Quit if (defined fileno($self));
}

sub isMeta
{
    my ($self, $line) = @_;
    return 0 unless $line;
    return 0 unless $line =~ m/^(\S+)/o;
    $line = $1;
    return 1 if $MetaData{$line};
    return 0;
}

sub myLog
{
    my $self = shift;
    return unless ($self->debug);
    $self->debug_print(0, join("\n", @_) . "\n");
}

sub response
{
  my $self  = shift;
  my $prompt = shift;
  my $cmd = shift || "";
  my (@result, $line, $async, $nResults);

  $self->timeout(0.65);
  $async = 0;

  while (1) {
      $line = $self->getline();
      $line =~ s/[\r\n]//og;

      if (index($line, "TransactionInitiated") >= 0) {
	  $async = 1;
	  $self->myLog("Setting async to true");
      }

      if (!$line && ${*$self}{'net_cmd_partial'}) {
          $line = ${*$self}{'net_cmd_partial'};
          ${*$self}{'net_cmd_partial'} = "";
      }
      $nResults = $1 if ($line =~ m/ListResultSize (\d+)/o);

      $self->myLog("Disconnected"), return undef if (!$line && !defined(fileno($self)));
      $line =~ s/^[^:]+: //om;
      push @result, $line if ($line && (${*$self}{'_RawResults'} || !$self->isMeta($line)));
      #$self->debug_print(0, "From wire: $line\n") if ($self->debug);
      last if ((!defined $line && !$async && scalar @result) ||
               ($prompt && index($line, $prompt) >= 0) ||
               (index($line, "TransactionComplete") == 0));
  }

  $self->myLog("For cmd $cmd: got: ", @result);

  if (defined $nResults && $nResults == 0) {
    $self->myLog("Got back empty list");
    return undef;
  }

  if (index($result[$#result], "Error") < 0 &&
     index($result[$#result], "UnknownCommand") < 0) {
#index($result[$#result], $prompt) >= 0 ||
#      index($result[$#result], "TransactionComplete") >= 0) { 
      push @result, "OK" unless scalar @result;
      $self->myLog("For cmd $cmd: returning: ", @result);
      return wantarray ? @result : join("\n", @result);
  }
  $self->myLog("Returning undef because of result: $result[$#result]");
  return undef;
}

1;

__END__

=head1 NAME

Roku::RCP - Object approach to controlling RCP enabled Roku products, such as the Roku SoundBridge.

=head1 SYNOPSIS

    use Roku::RCP;

    # Connect to the sleeping Roku, wake him up and tell him to play
    # the All_Dynamic playlist
    my $rcp = new Roku::RCP('192.168.0.102');

    # You can leave out this whole if-statement if your Roku is already
    # connected to a media server (and thus not in standby mode).
    if (!$rcp->GetConnectedServer()) {
      print "Not connected to firefly. Connecting ...\n";
      die "Couldn't connect to Firefly\n" unless $rcp->ServerConnectByName("Firefly");
    }
    $rcp->PlayPlaylist("All_Dynamic") or die "No Can Do\n";
    $rcp->Shuffle("on");
    $rcp->Quit();

=head1 DESCRIPTION

C<Roku::RCP> Gives you an object through which you can communicate with your Roku Control Protocol-enabled Roku product. For the most part, the commands are merely passed through onto the connection and the results are parsed and returned to you either in an array in list context, or a giant string in scalar context. Should the command fail, undef is returned.

You'll want to familiarize yourself with the Roku Control Protocol (RCP) by visting the Roku Labs site http://www.rokulabs.com and reading the RCP spec. Although this module provides some convenience functions, you'll need to have an understanding of the basic commands if you'd like to do anything more fancy. If you're not into reading, you can telnet to port 5555 on your Roku yourself and type "help".

=head1 METHODS

=over 4

=item C<my $rcp = new Roku::RCP($hostname, %options)>

Construct a new object.

    $rcp = new Roku::RCP('192.168.0.102', Debug=>0, RawResults=>0, Port=>5555, Timeout=>50);

If RawResults is set, you'll get back everything Roku sends back. If it's not set, you'll just get back the data without any metadata. Be careful with RawResults because the data and metadata will be intermixed so if you have code expecting just the results, you'll be in for an unpleasant surprise. Everything after the hostname is optional. The proper defaults will be chosen.

See the System Commands section for how to use Roku::RCP to send system-type commands instead of media playback-type commands.

=item C<$rcp-E<gt>ServerConnectByName($server_name)>

C<ServerConnectByName()> Is a convenience function that takes a partial or complete media server name and tries to connect to it. An example of such would be "FireFly";

=item C<$rcp-E<gt>PlayPlayList($playlist_name)>

A convenience function that takes a partial or complete playlist name and tries to start playing it.

=item C<$rcp-E<gt>PlayArtist($artist_name)>

A convenience function that takes an exact, case-sensitive artist name and tries to play all the songs by that artist. Note that if you'd like to do partial matching, you'll have to first call $rcp->SearchArtists("vast"), get the resulting list back, pick one and then call PlayArtist() with that string.

=item C<$rcp-E<gt>PlayAlbum($album_name)>

A convenience function that takes an exact, case-sensitive album name and tries to play all the songs on that album. Note that if you'd like to do partial matching, you'll have to first call $rcp->SearchAlbums("visual audio sensory theat"), get the resulting list back, pick one and then call PlayAlbum() with that string.

=item C<$rcp-E<gt>PlaySong($song_name)>

A convenience function that takes a partial, case insensitive song name and tries to play all the songs matching that string. 

=item C<$rcp-E<gt>InsertSong($song_name)>

A convenience function that takes a partial, case insensitive song name and tries to insert all matching songs into the queue and play them. Note that if the song/s is/are already in your queue, the position won't change and the next song in your queue will start playing.

=item C<$rcp-E<gt>Standby()>

Put the Roku into standby as if you pressed the Power button on the remote control.

=item C<$rcp-E<gt>Quit()>

Cleanly close the connection. This will get called automatically when the object is destroyed.

=item C<$rcp-E<gt>ROKU_RCP_COMMAND($arg1, $arg2, ...)>

Any commands not specifically listed here are considered to be RCP commands and sent along down the connection. Here are a few to wet your whistle: Next, Previous, Reboot, QueueAndPlay, GetTimeZone, ListServers, ListPlaylists. Generally the paradigm is that you connect to Roku, issue a command that lists out songs and then you QueueAndPlay. Roku assumes you mean the last listing of songs. Unless you want to wait for thousands and thousands of song titles to come back, you generally want to tell Roku to forgo sending you the entire list and just send you the total number. $rcp->SetListResultType("partial") is your friend. Take a look at how I did the PlayArtist() convenience function as a good starting place.

=back

=head1 System Commands

Port 5555 deals with media playback and control thereof. If you'd like to use Roku::RCP to send system-type commands to the 4444 control port, you should use the command() call. For example, if you wanted to create a script that notifies you of some event:

    my $msg = 'Hey, look over here';
    my @slides = (5, -5, 10, -5, -5);

    $rcp = new Roku::RCP('192.168.0.102', Port=>4444);
    $rcp->command('attract') foreach (1..5);
    $rcp->command('sketch');
    $rcp->command('font 14');
    $rcp->command('clear');
    $rcp->command("text 0 0 \"$msg\"");
    foreach $slide (@slides) {
      sleep 2;
      $rcp->command("slide $slide 20");
    }
    sleep(4);
    $rcp->Quit();

=head1 LEGALESE

Copyright 2007 by Robert Powers,
all rights reserved. This program is free
software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Robert Powers <batman@cpan.org>
