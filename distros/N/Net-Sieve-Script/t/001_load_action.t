use Test::More tests => 10;
use strict;

use lib qw(lib);

BEGIN { use_ok( 'Net::Sieve::Script::Action' ); }

my $command = ' fileinto "INBOX.spam" ';

my $action = Net::Sieve::Script::Action->new($command);

is ( $action->command, 'fileinto', "command fileinto");
is ( $action->param, '"INBOX.spam"', "param INBOX.spam");

$action = Net::Sieve::Script::Action->new('stop');
is ( $action->command, 'stop', "command stop");

$action = Net::Sieve::Script::Action->new('redirect "bart@example.edu"');
is ( $action->command, 'redirect', "command redirect");
is ( $action->param, '"bart@example.edu"', 'param bart@example.edu');

$action = Net::Sieve::Script::Action->new('nimp "bart@example.edu"');
is ( $action->command, undef, "undef for command nimp");

$action = Net::Sieve::Script::Action->new('vacation "I am away this week.";');
is ( $action->command, 'vacation' , "vacation command");
is ( $action->param, '"I am away this week."' , "vacation param");

my $multi_line_param = 'text: some text 
on multi-line 
.';

my $command2 = ' reject '.$multi_line_param; 
my $action2 = Net::Sieve::Script::Action->new($command2);
is ( $action2->param, $multi_line_param , "match mult-line param");
