#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Protocol::IRC::Message;

sub test_line
{
   my $testname = shift;
   my $line = shift;
   my %asserts = @_;

   my $msg = Protocol::IRC::Message->new_from_line( $line );

   exists $asserts{command} and
      is( $msg->command, $asserts{command}, "$testname command" );

   exists $asserts{prefix} and
      is( $msg->prefix, $asserts{prefix}, "$testname prefix" );

   exists $asserts{args} and
      is_deeply( [ $msg->args ], $asserts{args}, "$testname args" );

   exists $asserts{stream} and
      is( $msg->stream_to_line, $asserts{stream}, "$testname restream" );

   exists $asserts{tags} and
      is_deeply( $msg->tags, $asserts{tags}, "$testname tags" );
}

my $msg = Protocol::IRC::Message->new( "command", "prefix", "arg1", "arg2" );

ok( defined $msg, 'defined $msg' );
isa_ok( $msg, "Protocol::IRC::Message", '$msg isa Protocol::IRC::Message' );

is( $msg->command, "COMMAND", '$msg->command' );
is( $msg->prefix,  "prefix",  '$msg->prefix' );
is( $msg->arg(0),  "arg1",    '$msg->arg(0)' );
is( $msg->arg(1),  "arg2",    '$msg->arg(1)' );
is_deeply( [ $msg->args ], [qw( arg1 arg2 )], '$msg->args' );

is( $msg->stream_to_line, ":prefix COMMAND arg1 arg2", '$msg->stream_to_line' );

$msg = Protocol::IRC::Message->new( "001", undef, ":Welcome to IRC User!ident\@host" );
is( $msg->command, "001", '$msg->command for 001' );
is( $msg->command_name, "RPL_WELCOME", '$msg->command_name for 001' );

$msg = Protocol::IRC::Message->new_with_tags( "PRIVMSG", { intent => "ACTION" }, undef, "#example", "throws a rock" );
is_deeply( $msg->tags, { intent => "ACTION" }, '$msg->tags' );

is( $msg->stream_to_line, "\@intent=ACTION PRIVMSG #example :throws a rock" );

test_line "Basic",
   "COMMAND",
   command => "COMMAND",
   prefix  => "",
   args    => [],
   stream  => "COMMAND";

test_line "Prefixed",
   ":someprefix COMMAND",
   command => "COMMAND",
   prefix  => "someprefix",
   args    => [],
   stream  => ":someprefix COMMAND";

test_line "With one arg",
   "JOIN #channel",
   command => "JOIN",
   prefix  => "",
   args    => [ "#channel" ],
   stream  => "JOIN #channel";

test_line "With one arg as :final",
   "WHOIS :Someone",
   command => "WHOIS",
   prefix  => "",
   args    => [ "Someone" ],
   stream  => "WHOIS Someone";

test_line "With two args",
   "JOIN #foo somekey",
   command => "JOIN",
   prefix  => "",
   args    => [ "#foo", "somekey" ],
   stream  => "JOIN #foo somekey";

test_line "With long final",
   "MESSAGE :Here is a long message to say",
   command => "MESSAGE",
   prefix  => "",
   args    => [ "Here is a long message to say" ],
   stream  => "MESSAGE :Here is a long message to say";

test_line "With :final",
   "MESSAGE ::final",
   command => "MESSAGE",
   prefix  => "",
   args    => [ ":final" ],
   stream  => "MESSAGE ::final";

test_line "With \@tags",
   "\@intent=ACTION;znc.in/extension=value;foo PRIVMSG #example :throws a rock",
   command => "PRIVMSG",
   prefix  => "",
   args    => [ "#example", "throws a rock" ],
   tags    => {
      intent             => "ACTION",
      'znc.in/extension' => "value",
      foo                => undef,
   };

like( exception { Protocol::IRC::Message->new( "some command" ) },
      qr/^Command must be just letters or three digits/,
      'Command with spaces fails' );

like( exception { Protocol::IRC::Message->new( "cmd", "prefix with spaces" ) },
     qr/^Prefix must not contain whitespace/,
     'Command with spaces fails' );

like( exception { Protocol::IRC::Message->new( "cmd", undef, "foo\x0d\x{0d}bar" ) },
     qr/^Final argument must not contain a linefeed/,
     'Final with linefeed fails' );

like( exception { Protocol::IRC::Message->new( "cmd", undef, undef ) },
     qr/^Final argument must be defined/,
     'Final undef fails' );

like( exception { Protocol::IRC::Message->new( "cmd", undef, "foo bar", "splot wibble" ) },
     qr/^Argument must not contain whitespace/,
     'Argument with whitespace fails' );

like( exception { Protocol::IRC::Message->new( "cmd", undef, undef, "last" ) },
     qr/^Argument must be defined/,
     'Argument undef fails' );

like( exception { Protocol::IRC::Message->new_with_tags( "command", { 'invalid_key' => 1 }, undef ) },
    qr/^Tag key 'invalid_key' is invalid/,
    'attempt to add invalid key fails');

like( exception { Protocol::IRC::Message->new_with_tags( "command", { 'valid-key' => 'invalid;value' }, undef ) },
    qr/^Tag value 'invalid;value' for key 'valid-key' is invalid/,
    'attempt to add key with invalid value fails');

done_testing;
