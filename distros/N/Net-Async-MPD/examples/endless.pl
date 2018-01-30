#!/usr/bin/env perl

use strict;
use warnings;

use List::Util qw( shuffle );
use Array::Utils qw( array_minus );
use Net::Async::MPD;
use IO::Async::Loop;
use PerlX::Maybe;
use Future::Utils qw( repeat );

my $loop = IO::Async::Loop->new;
my $mpd = Net::Async::MPD->new(
  maybe host => $ARGV[0],
  auto_connect => 1,
);

# use Log::Any::Adapter;
# Log::Any::Adapter->set( 'Stderr', log_level => 'trace' );

my @all_files;
$mpd->send( { parser => 'none' }, 'list_all', sub {
  @all_files = map { (split /:\s+/, $_, 2)[1] }
    grep { /^file:/ }
    @{shift->[0]};
})->get;

my $total_length = 21;
my $songs_to_add = 1;
my $previous;
my $status;
my $repeat = 1;
my @new_songs;

$mpd->on( close => sub { $repeat = 0 });

my $endless = repeat {
  $mpd->send( idle => 'player' )
    ->then( sub {
      return $mpd->send( 'status' );
    })
    ->then( sub {
      $status = shift;
      my $current = $status->{songid};
      return $loop->new_future->fail(1) unless $current;

      $previous = $current unless defined $previous;
      if ($current ne $previous) {
        $previous = $current;
        return $mpd->send( 'playlist' );
      }
      else {
        return $loop->new_future->fail(1);
      }
    })
    ->then( sub {
      my @playlist = @{ shift() };

      my $all_new = 1;
      foreach (0..100) {
        my @indeces = shuffle( 0..$#all_files );
        @new_songs = @all_files[ @indeces[ 0 .. $songs_to_add-1 ] ];

        my @diff = array_minus( @new_songs, @playlist );
        if (scalar @diff eq $songs_to_add) { last }
        else { $all_new = 0 }
      }

      warn 'Some of the added songs already exist in the playlist!'
        unless $all_new;

      my $end = scalar @playlist;
      my @commands = map { [ addid => $_, $end++ ] } @new_songs;

      {
        my $n = ($status->{song} >= $songs_to_add)
          ? $songs_to_add : $status->{song};
        push @commands, [ delete => "0:$n" ] if $n > 0;
      }

      return $mpd->send( \@commands );
    })
    ->then( sub {
      $mpd->send( { list_ok => 0 }, [ map { "lsinfo $_" } @new_songs ]);
    })
    ->then( sub {
      my $info = shift;
      foreach (@{$info}) {
        my $artist = $_->{AlbumArtist} // $_->{Artist} // '[Unknown Artist]';
        my $title  = $_->{Title} // '[Unknown Title]';

        if ($artist =~ /^\[unknown/ and $title =~ /^\[unknown/) {
          print "+ $_->{file}\n";
        }
        else {
          print "+ $artist - $title\n";
        }
      }

      return $mpd->loop->done;
    })
    ->catch(sub {
      $loop->new_future->done
    });
} while => sub { $repeat };

$endless->get;
