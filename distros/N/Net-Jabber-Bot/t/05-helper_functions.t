#!perl

use strict;
use warnings;
use Test::More tests => 127;
use Net::Jabber::Bot;

#InitLog4Perl();

# stuff for mock client object
use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient; # Test object

# Setup 
my $bot_alias = 'make_test_bot';
my $client_alias = 'bot_test_client';
my $server = 'talk.google.com';
my $personal_address = "test_user\@$server/$bot_alias";

my $loop_sleep_time = 5;
my $server_info_timeout = 5;

my %forums_and_responses;
my $forum1 = 'test_forum1';
my $forum2 = 'test_forum2';
$forums_and_responses{$forum1} = ["jbot:", ""];
$forums_and_responses{$forum2} = ["notjbot:"];

my $ignore_server_messages = 1;
my $ignore_self_messages = 1;
my $out_messages_per_second = 5;
my $max_message_size = 800;
my $long_message_test_messages = 6;
my $flood_messages_to_send = 40;
my $max_messages_per_hour = ($flood_messages_to_send*2 
						     + 2
						     + $long_message_test_messages
						     );

# Globals we'll keep track of variables we use each test.
our ($messages_seen, $initial_message_count, $start_time); 
$messages_seen = 0;
$initial_message_count = 0;
$start_time = time;

ok(1, "Creating Net::Jabber::Bot object with Mock client library asserted in place of Net::Jabber::Client");

my $bot = Net::Jabber::Bot->new(
				 server => $server
				 , conference_server => "conference.$server"
				 , port => 5222
				 , username => 'test_username'
				 , password => 'test_pass'
				 , alias => $bot_alias
				 , message_function => \&new_bot_message   # Called if new messages arrive.
				 , background_function => \&background_checks # What the bot does outside jabber.
				 , loop_sleep_time => $loop_sleep_time # Minimum time before doing background function.
				 , process_timeout => $server_info_timeout # Time to wait for new jabber messages before doing background stuff
				 , forums_and_responses => \%forums_and_responses
				 , ignore_server_messages => $ignore_server_messages
				 , ignore_self_messages => $ignore_self_messages
				 , out_messages_per_second => $out_messages_per_second
				 , max_message_size => $max_message_size
				 , max_messages_per_hour => $max_messages_per_hour
				);

is($bot->message_delay, 0.2, "Message delay is set right to .20 seconds");
is($bot->max_messages_per_hour, $max_messages_per_hour, "Max messages per hour ($max_messages_per_hour) didn't get messed with by safeties");

isa_ok($bot, "Net::Jabber::Bot");
ok(1, "Sleeping 12 seconds to make sure we get past initializtion");
ok((sleep 12) > 10, "Making sure the bot get's past login initialization (sleep 12)");
process_bot_messages(); # Clean off the queue before we start?

# continue editing here. Need to next enhance mock object to know jabber bot callbacks.
# Not sure how we're going to chase chicken/egg issue.

start_new_test("Testing Group Message bursting is not possible");
{
    for my $counter (1..$flood_messages_to_send) {
	my $result = $bot->SendGroupMessage($forum1, "Testing message speed $counter");
		diag("got return value $result") if(defined $result);
		ok(!defined $result, "Sent group message $counter");
    }

     my $running_time = time - $start_time;
     my $expected_run_time = $flood_messages_to_send / $out_messages_per_second;
     cmp_ok($running_time, '>=', int($expected_run_time), "group Message burst: \$running_time ($running_time) >= \$expected_run_time ($expected_run_time)");

     process_bot_messages();
     verify_messages_sent($flood_messages_to_send);
     verify_messages_seen(0, "Didn't see the messages I sent to the group");
}


start_new_test("Testing PERSONAL_ADDRESS Message bursting is not possible");
{
     for my $counter (1..$flood_messages_to_send) {
	 my $result =  $bot->SendPersonalMessage($personal_address, "Testing personal_address message speed $counter");
	 diag("got return value $result") if(defined $result);
	 ok(!defined $result, "Sent personal message $counter");
     }

     my $running_time = time - $start_time;
     my $expected_run_time = $flood_messages_to_send / $out_messages_per_second;
     cmp_ok($running_time, '>=', int($expected_run_time), "group Message burst: \$running_time ($running_time) >= \$expected_run_time ($expected_run_time)");

     process_bot_messages();
     verify_messages_sent($flood_messages_to_send);
     verify_messages_seen(0, "Didn't see the messages I sent to myself...");
}

TODO: { # Need a way to test for historical - up top or in diff code?
;#    cmp_ok($messages_seen, '==', 0, "Didn't see any historical messages...");
}

cmp_ok($bot->respond_to_self_messages( ), '==', 1, "no pass to respond_to_self_messages is 1");
cmp_ok($bot->respond_to_self_messages(0), '==', 0, "Ignore Self Messages");
cmp_ok($bot->respond_to_self_messages(2), '==', 1, "Respond to Self Messages");

start_new_test("Test a successful message");
ok(!defined $bot->SendPersonalMessage($personal_address, "Testing message to myself"), "Testing message to myself");
process_bot_messages();
verify_messages_sent(1);
verify_messages_seen(1, "Got it!");

# Setup a really long message and make sure it's longer than 1 message.
my $repeating_string = 'Now is the time for all good men to come to the aide of their country ';
my $message_repeats = int( # Make it a whole number
			   ($max_message_size # Maximum size of 1 message
			    * $long_message_test_messages # How many messages we want to produce
			    - $max_message_size / 2) # Shorten it a little.
			   / length $repeating_string  # Length of our string we're going to repeat
			   );
my $long_message = $repeating_string x $message_repeats;
my $long_message_length = length $long_message;

cmp_ok(length($long_message), '>=' , $max_message_size , "Length of message is greater than 1 message chunk ($long_message_length bytes)");


ok(1, "Testing messages that will be split:");
{
    start_new_test("Send to self");
    cmp_ok($bot->respond_to_self_messages( ), '==', 1, "Make sure I'm responding to self messages.");

    # Group Test.
    ok(1, "Sending long message of " . length($long_message) . " bytes to forum");
    my $result = $bot->SendGroupMessage($forum1, $long_message);
    diag("got return value $result\nWhile trying to send: $long_message") if(defined $result);
    ok(!defined $result, "Sent long message.");
    process_bot_messages();
    cmp_ok($messages_seen, '>=',$long_message_test_messages, "Saw $long_message_test_messages messages so we know it was chunked into messages smaller than $max_message_size");

    start_new_test("Set long subject in forum (illegal)");
    my $subject_change_result = $bot->SetForumSubject($forum1, $long_message);
    is($subject_change_result, "Subject is too long!", 'Verify long subject changes are rejected.');
    verify_messages_sent(0);
    verify_messages_seen(0, "Bot should not have sent anything to the server.");
}

DEBUG("Finished with first burst");

start_new_test("Test a successful message with a panic");
ok(!defined $bot->SendPersonalMessage($personal_address, "Testing message to myself"), "Testing message to myself");
process_bot_messages();
verify_messages_sent(1);
verify_messages_seen(2, "With Panic");


start_new_test("Test message limits");
my $failure_message = $bot->SendPersonalMessage($personal_address, "Testing message to myself that should fail");
ok(defined $failure_message, "Testing hourly message limits (failure to send)");
process_bot_messages();
verify_messages_seen(0, "Should be not have been sent to server");
verify_messages_seen(0, "Rejected by bot");

exit;

sub new_bot_message {
    $messages_seen += 1;
}
sub background_checks {}

sub verify_messages_sent {
    my $expected_messages = shift;

    my $messages_sent = $bot->get_messages_this_hour() - $initial_message_count;
    cmp_ok($messages_sent, '==', $expected_messages, "Verify that $expected_messages were sent");
}

sub verify_messages_seen {
    my $expected_messages = shift;
    my $comment = shift;
    if(!defined $comment) {
	$comment = "";
    } else {
	$comment = "($comment)";
    }
    
    cmp_ok($messages_seen, '==', $expected_messages, "Verify that $expected_messages were seen $comment");
}

sub start_new_test {
    my $comment = shift;
    $comment = "no description" if(!defined $comment);
    ok(1, "****** New test: $comment ******");  
    
    $initial_message_count = $bot->get_messages_this_hour();
    $messages_seen = 0;
    $start_time = time;
}


sub process_bot_messages {
	DEBUG("Processing bot messages from test file ($0)");
    ok(defined $bot->Process(5), "Processed new messages and didn't lose connection.");
}

sub InitLog4Perl {
	use Log::Log4perl qw(:easy);
	my $config_file .= <<'CONFIG_DATA';
# Regular Screen Appender
log4perl.appender.Screen           = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr    = 0
log4perl.appender.Screen.layout    = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %p (%L): %m%n
log4perl.category = ALL, Screen
CONFIG_DATA

	Log::Log4perl->init(\$config_file);
    $| = 1; #unbuffer stdout!
}
