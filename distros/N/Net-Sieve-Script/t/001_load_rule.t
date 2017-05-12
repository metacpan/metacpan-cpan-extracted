use Test::More tests => 2;
use strict;

use lib qw(lib);

BEGIN { use_ok( 'Net::Sieve::Script::Rule' ); }

my $command = ' fileinto "INBOX.spam" ';

# test case on keywords
my $rule = Net::Sieve::Script::Rule->new(
    ctrl => 'iF',
    block => 'Fileinto "spam"; 
    stop;',
    test_list => 'anYof (NOT Address :aLl :contains ["To", "Cc", "Bcc"] "me@example.com", 
                        heaDer :Matches "subject" ["*make*money*fast*", "*university*dipl*mas*"])',
    order => 1
    );

my $waiting_res = 'if  anyof ( 
   not address :all :contains ["To", "Cc", "Bcc"] "me@example.com",
   header :matches "subject" ["*make*money*fast*", "*university*dipl*mas*"] )
    {
    fileinto "spam";
    stop;
    } ';

is ($rule->write,$waiting_res,"good writing");

#print $rule->write_action."\n";
#print $rule->write_condition."\n";
#print "======\n";
#print $rule->write."\n";
