#!/usr/bin/env perl

use strict;
use warnings;

use Net::Async::MPD;
use Term::ReadLine;
use PerlX::Maybe;
use Data::Printer output => 'stdout';
use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Log::Any::Adapter;
use Try::Tiny;
use File::Share qw( dist_file );
use Pod::Usage;

my $debug = 0;
debug($debug);

my $loop = IO::Async::Loop->new;
my $term = Term::ReadLine->new('MPD REPL');
my $finished = $loop->new_future;

my $mpd = Net::Async::MPD->new(
  maybe host => $ARGV[0],
  auto_connect => 1,
);

print "Connected to MPD (v", $mpd->version, ")\n";
my $prompt = "# ";

# Keep the connection alive
my $timer = IO::Async::Timer::Periodic->new(
  first_interval => 30,
  interval => 30,
  on_tick => sub { $mpd->send( 'ping' ) },
);

$timer->start;
$loop->add( $timer );

# Make readline work with inside the event loop
{
  my $input;
  $term->event_loop(
    # Wait for input
    sub {
      $input = $loop->new_future;
      $input->get;
    },
    # Register input
    sub {
      $loop->watch_io(
        handle => shift,
        on_read_ready => sub { $input->done unless $input->is_ready },
      );
    }
  );
}

$mpd->on( close => sub {
  $finished->done;
  die "Connection terminated. Going away\n";
});

{
  my @commands;
  my $in_list = 0;

  while (
      !$finished->is_ready and
      defined (my $cmd = $term->readline($prompt))
    ) {

    next if $cmd eq q{};
    $finished->done and last if $cmd =~ /^(?:e(?:xit)?|q(?:uit)?)$/;

    if ($cmd =~ /^debug ?(\w+)?$/) {
      debug($1) and next;
    }
    elsif ($cmd =~ /^help ?(.*)?$/) {
      help($1) and next;
    }

    $timer->stop if $cmd =~ /^idle/;

    if    ($cmd =~ /command_list_(?:ok_)?begin/) { $in_list = 1 }
    elsif ($cmd eq 'command_list_end')           { $in_list = 0 }

    push @commands, $cmd;

    unless ($in_list) {
      my $future = $mpd->send( \@commands, sub {
        my @res = @_;
        p @res if !$@ and scalar @res;
      });

      try { $future->get } catch { warn $_ };

      $term->addhistory(shift @commands) while @commands;
    }

    $timer->start unless $timer->is_running
  }
}

sub debug {
  $debug = defined $_[0] ? $_[0] : (1 - $debug);

  if ($debug){
    print "Tracing messages\n";
    Log::Any::Adapter->set( 'Stderr', log_level => 'trace' );
  }
  else {
    print "No message tracing\n";
    Log::Any::Adapter->set( 'Null' );
  }

  return 1;
}

{
  my $usage;
  sub help {
    my ($topic) = @_;

    my $doc = q{};
    use autodie;
    open my $fh, '>', \$doc;

    $usage //= Pod::Usage->new;
    $usage->select('/' . $topic);
    $usage->parse_from_file( dist_file('Net-Async-MPD', 'mpd.pod'), $fh);

    p $doc;

    return 1;
  }
}
