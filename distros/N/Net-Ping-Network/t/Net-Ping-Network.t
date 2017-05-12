# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Flowd.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Net::Ping::Network;

my $net = Net::Ping::Network->new("127.0.0.0", 29);
my ($results,$process_time) = $net->doping();

my @keys = keys %$results;
    
foreach my $key ( @keys ) {
    print "$key" . " is ";
    if ( $$results{$key} ) {
        print  "alive. PT: " . $$process_time{$key}  . "\n";
    } else {
        print "unreachable! PT: " . $$process_time{$key}  . "\n";
    }
}

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

