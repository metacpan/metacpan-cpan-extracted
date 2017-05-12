#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::Matrix;
use Net::Netrc;

use Getopt::Long;

use JSON::MaybeXS;

my $JSON = JSON::MaybeXS->new( pretty => 1 );
STDOUT->binmode( ":encoding(UTF-8)" );

sub print_event
{
   my ( $category, $event ) = @_;

   print "$category:\n";
   print $JSON->encode( $event ) =~ s/^/ | /mgr;
}

my %NO;
GetOptions(
   'server=s' => \my $SERVER,
   'SSL'      => \my $SSL,
   'user=s'   => \my $USER,
   'pass=s'   => \my $PASS,

   'no-presence' => \$NO{presence},
   'no-receipt'  => \$NO{receipt},
   'no-typing'   => \$NO{typing},
) or exit 1;

die "Require --server\n" unless defined $SERVER;

if( !defined $PASS ) {
   my $ent = Net::Netrc->lookup( $SERVER, $USER ) or
      die "No --pass given and not found in .netrc\n";

   $USER //= $ent->login;
   $PASS //= $ent->password;
}

my $loop = IO::Async::Loop->new;

my $matrix = Net::Async::Matrix->new(
   server          => $SERVER,
   SSL             => $SSL,
   SSL_verify_mode => 0,

   on_presence => sub {
      my ( undef, $user, %changes ) = @_;
      return if $NO{presence}; ## TODO filter
      print_event( presence => { user_id => $user->user_id, changes => \%changes } );
   },

   on_room_new => sub {
      my ( undef, $room ) = @_;

      $room->configure(
         on_message => sub {
            my ( $room, $member, $content, $event ) = @_;
            print_event( message => {
               %$event,
               room_id => $room->room_id,
            } );
         },
         on_membership => sub {
            my ( $room, $member, $event, $subject, %changes ) = @_;
            print_event( membership => $event );
         },
         on_state_changed => sub {
            my ( $room, $member, $event, %changes ) = @_;
            print_event( state => $event );
         },
         on_typing => sub {
            my ( $room, $member, $is_typing ) = @_;
            return if $NO{typing}; ## TODO: filter
            print_event( typing => {
               room_id => $room->room_id,
               user_id => $member->user->user_id,
               typing  => $is_typing,
            } );
         },
         on_read_receipt => sub {
            my ( $room, $member, $event_id, $content ) = @_;
            return if $NO{receipt};
            print_event( read_receipt => {
               room_id  => $room->room_id,
               user_id  => $member->user->user_id,
               event_id => $event_id,
               ts       => $content->{ts},
            } );
         },
      );
   },
);
$loop->add( $matrix );

print STDERR "Logging in to $SERVER as $USER...\n";

$matrix->login(
   user_id  => $USER,
   password => $PASS,
)->get;

my %filter;
$filter{presence} = { types => [] } if $NO{presence};
push @{ $filter{room}{ephemeral}{not_types} }, "m.receipt" if $NO{receipt};
push @{ $filter{room}{ephemeral}{not_types} }, "m.typing"  if $NO{typing};

my $filter_json = JSON::MaybeXS->new->encode( \%filter );

print STDERR "Event stream started\n";

$loop->run;
