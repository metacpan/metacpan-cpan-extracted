use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('Parse::IRC') };

my $original = ":test!test\@test.test PRIVMSG #Test :\001ACTION is a test case\001";

# Function Interface

{
  my $irc_event = parse_irc( $original, ctcp => 1 );
  is( $irc_event->{prefix}, 'test!test@test.test', 'Prefix Test Func' );
  is( $irc_event->{params}->[0], '#Test', 'Params Test One Func' );
  is( $irc_event->{params}->[1], 'is a test case', 'Params Test Two Func' );
  is( $irc_event->{command}, 'CTCP_ACTION', 'Command Test Func');
}

{
  my $parser = Parse::IRC->new( ctcp => 1 );
  isa_ok( $parser, 'Parse::IRC' );

  my $irc_event = $parser->parse( $original );
  is( $irc_event->{prefix}, 'test!test@test.test', 'Prefix Test Func' );
  is( $irc_event->{params}->[0], '#Test', 'Params Test One Func' );
  is( $irc_event->{params}->[1], 'is a test case', 'Params Test Two Func' );
  is( $irc_event->{command}, 'CTCP_ACTION', 'Command Test Func');
}

{
  my $parser = Parse::IRC->new();
  isa_ok( $parser, 'Parse::IRC' );

  my $irc_event = $parser->parse( $original );
  is( $irc_event->{prefix}, 'test!test@test.test', 'Prefix Test Func' );
  is( $irc_event->{params}->[0], '#Test', 'Params Test One Func' );
  is( $irc_event->{params}->[1], "\001ACTION is a test case\001", 'Params Test Two Func' );
  is( $irc_event->{command}, 'PRIVMSG', 'Command Test Func');
}
