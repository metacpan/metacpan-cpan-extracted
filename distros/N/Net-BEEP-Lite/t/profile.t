# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 4.t'

#########################

use Test::More tests => 16;
#use Test::More qw(no_plan);

BEGIN { use_ok('Net::BEEP::Lite::BaseProfile');
        use_ok('Net::BEEP::Lite::Message');
        use_ok('Net::BEEP::Lite::Session'); };

#########################

# Testing Net::BEEP::Lite::BaseProfile

# the constructor:
my $profile = Net::BEEP::Lite::BaseProfile->new;
ok(defined $profile, 'constructor works');
isa_ok($profile, 'Net::BEEP::Lite::BaseProfile');

my $prof_uri = "http://foo.bar/profiles/MYPROFILE";
is($profile->uri($prof_uri), $prof_uri, 'profile->uri($val)');
is($profile->uri(), $prof_uri, '$profile->uri()');

my $session = Net::BEEP::Lite::Session->new;

eval { $profile->MSG($session, "blah"); };
like($@, qr/MSG/, 'profile->MSG() croaks');

my @res = $profile->start_channel_request($session, undef, "blah");
is(@res, 1, 'startChannelRequest returned one thing');
is($session->{start_channel_data}, "blah", 'startChannelData stowed the data');

for my $type ('MSG', 'RPY', 'ERR', 'ANS', 'NUL') {
  my $message = new Net::BEEP::Lite::Message(Type => $type,
					   Channel => 1,
					   Payload => "some payload");
  eval { $profile->handle_message($session, $message); };
  like($@, qr/$type/, "profile->handle_message($type)");
}

my $message =  new Net::BEEP::Lite::Message(Type => 'UNK',
					   Channel => 1,
					   Payload => "some payload");
eval { $profile->handle_message($session, $message); };
like($@, qr/unknown/, 'profile->handle_message(UNK)');
