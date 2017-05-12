#!perl -T

use Test::More tests => 5;

BEGIN { use_ok(Net::Bot::IRC::Message); }

my $in;
my $out;
my ($prefix, $command, $params);
my $compiled_message;
my $raw_message = qq{:irc.blah.com 332 yournick #channame :Welcome to #channame | We're here, just idling...};

# Test the "incoming message" usage of the constructor.
ok($in = Net::Bot::IRC::Message->new(unparsed => $raw_message), "new(unparsed)");

# Test parsing of incoming message.
($prefix, $command, $params) = $in->parse();
ok( #That parse() is returning what it should   
      defined $prefix
   && defined $command
   && defined $params
   # And that it's also setting it's member variables properly.
   && exists $in->{prefix}
   && exists $in->{command}
   && exists $in->{params}, "parse()");

# Test "outgoing message" constructor.
ok($out = Net::Bot::IRC::Message->new(prefix  => $prefix,
                                      command => $command,
                                      params  => $params),
   "new(prefix, command, params)");

# Test compiling of outgoing message.
$compiled_message = $out->compile();
ok(   $compiled_message eq $raw_message
   && $out->{unparsed}  eq $raw_message, "compile()");
