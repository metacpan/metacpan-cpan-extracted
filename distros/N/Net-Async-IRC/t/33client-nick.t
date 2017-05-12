#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::Stream;

use Net::Async::IRC;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $in_use = 0;
my $err_nick = 0;
my $irc = Net::Async::IRC->new(
   handle => $S1,

   user => "defaultuser",
   realname => "Default Real name",

   nick => "AlreadyUsedNick",

   on_message_ERR_NICKNAMEINUSE => sub { shift->change_nick( "1stNick" ); $in_use = 1; },
   on_message_ERR_ERRONEUSNICKNAME => sub { shift->change_nick( "FirstNickTOOLONG" ); $err_nick = 1; },
   on_message => sub { "IGNORE" },
);

$loop->add( $irc );

is( $irc->nick, "AlreadyUsedNick", 'Initial nick is set' );

ok( $irc->is_nick_me( "AlreadyUsedNick" ), 'Client recognises initial nick' );
ok( !$irc->is_nick_me( "SomeoneElse" ), 'Client does not recognise other nick' );

my $login_f = $irc->login;

my $serverstream = "";

wait_for_stream { $serverstream =~ m/$CRLF.*$CRLF/ } $S2 => $serverstream;

is( $serverstream, "USER defaultuser 0 * :Default Real name$CRLF" . 
                   "NICK AlreadyUsedNick$CRLF", 'Server stream after attempt to login with nick already in use' );

$S2->syswrite( ":irc.example.com 433 * AlreadyUsedNick :Nickname is already in use$CRLF" );

wait_for { $in_use };

ok( $in_use, 'Client recieves ERR_NICKNAMEINUSE error' );

$S2->syswrite( ":irc.example.com 432 * 1stNick :Erroneous nickname$CRLF" );

wait_for { $err_nick };

ok( $err_nick, 'Client recieves ERR_ERRONEUSNICK error' );

$S2->syswrite( ":irc.example.com 001 FirstNick :Welcome to IRC FirstNick!defaultuser\@your.host.here$CRLF" );

wait_for { $login_f->is_ready };
$login_f->get;

is( $irc->nick, "FirstNick", 'Nick was updated correctly even after multiple errors' );

$serverstream = "";

wait_for_stream { $serverstream =~ m/$CRLF/ } $S2 => $serverstream;

is( $serverstream, "NICK 1stNick$CRLF" .
                   "NICK FirstNickTOOLONG$CRLF", 'Server stream after login' );

$irc->change_nick( "SecondNick" );

is( $irc->nick, "FirstNick", 'Nick still old until server confirms' );

ok( $irc->is_nick_me( "FirstNick" ), 'Client recognises still old nick' );
ok( !$irc->is_nick_me( "SecondNick" ), 'Client does not recognise new nick' );

$serverstream = "";

wait_for_stream { $serverstream =~ m/$CRLF/ } $S2 => $serverstream;

is( $serverstream, "NICK SecondNick$CRLF", 'Server stream after NICK command' );

$S2->syswrite( ":FirstNick!defaultuser\@your.host.here NICK SecondNick$CRLF" );

wait_for { not $irc->is_nick_me( "FirstNick" ) };

is( $irc->nick, "SecondNick", 'Object now confirms new nick' );

ok( !$irc->is_nick_me( "FirstNick" ), 'Client no longer recognises old nick' );
ok( $irc->is_nick_me( "SecondNick" ), 'Client now recognises new nick' );

done_testing;
