package Net::Twitter::Stream;
use strict;
use warnings;
use IO::Socket;
use MIME::Base64;
use JSON;
use IO::Socket::SSL;

our $VERSION = '0.28';
1;

=head1 NAME

Using Twitter's streaming api.

=head1 SYNOPSIS

  use Net::Twitter::Stream;

  Net::Twitter::Stream->new ( user => $username, pass => $password,
                              callback => \&got_tweet,
                              track => 'perl,tinychat,emacs',
                              follow => '27712481,14252288,972651' );

     sub got_tweet {
	 my ( $tweet, $json ) = @_;   # a hash containing the tweet
                                      # and the original json
	 print "By: $tweet->{user}{screen_name}\n";
	 print "Message: $tweet->{text}\n";
     }

=head1 DESCRIPTION

The Streaming verson of the Twitter API allows near-realtime access to
various subsets of Twitter public statuses.

The /1/status/filter.json api call can be use to track up to 200 keywords
and to follow 200 users.

HTTP Basic authentication is supported (no OAuth yet) so you will need
a twitter account to connect.

JSON format is only supported. Twitter may depreciate XML.


More details at: http://dev.twitter.com/pages/streaming_api

Options 
  user, pass: required, twitter account user/password
  callback: required, a subroutine called on each received tweet
  

perl@redmond5.com
@martinredmond

=head1 UPDATES

https fix: iwan standley <iwan@slebog.net>

=cut


sub new {
  my $class = shift;
  my %args = @_;
  die "Usage: Net::Twitter::Stream->new ( user => 'user', pass => 'pass', callback => \&got_tweet_cb )" unless
    $args{user} && $args{pass} && $args{callback};
  my $self = bless {};
  $self->{user} = $args{user};
  $self->{pass} = $args{pass};
  $self->{got_tweet} = $args{callback};
  $self->{connection_closed} = $args{connection_closed_cb} if
    $args{connection_closed_cb};
  
  my $content = "follow=$args{follow}" if $args{follow};
  $content = "track=$args{track}" if $args{track};
  $content = "follow=$args{follow}&track=$args{track}\r\n" if $args{track} && $args{follow};
  
  my $auth = encode_base64 ( "$args{user}:$args{pass}" );
  chomp $auth;
  
  my $cl = length $content;
  my $req = <<EOF;
POST /1/statuses/filter.json HTTP/1.1\r
Authorization: Basic $auth\r
Host: stream.twitter.com\r
User-Agent: net-twitter-stream/0.1\r
Content-Type: application/x-www-form-urlencoded\r
Content-Length: $cl\r
\r
EOF
  
  my $sock = IO::Socket::SSL->new ( PeerAddr => 'stream.twitter.com:https' );
  $sock->print ( "$req$content" );
  while ( my $l = $sock->getline ) {
    last if $l =~ /^\s*$/;
  }
  while ( my $l = $sock->getline ) {
    next if $l =~ /^\s*$/;           # skip empty lines
    $l =~ s/[^a-fA-F0-9]//g;         # stop hex from compaining about \r
    my $jsonlen = hex ( $l );
    last if $jsonlen == 0;
    eval {
	my $json;
	my $len = $sock->read ( $json, $jsonlen );
	my $o = from_json ( $json );
	$self->{got_tweet} ( $o, $json );
    };
  }
  $self->{connection_closed} ( $sock ) if $self->{connection_closed};
}


