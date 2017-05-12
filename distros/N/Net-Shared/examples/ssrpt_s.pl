#!perl -w
use strict;
use Net::Shared;

# fire this script up, and then run ssrpt_c.pl in a separate terminal
# type stuff at the prompt that appears from at the terminal ssrpt_s.pl
# is running in and watch it "magically" appear in the terminal where
# ssrpt_c.pl is at :)

my $listen = new Net::Shared::Handler;

my $new_shared = new Net::Shared::Local (name=>"new_shared",port=>9254 );

$listen->add(\$new_shared);
print ">";

$listen->store($new_shared, "");

while (<>)
{
    chomp;
    $listen->store($new_shared, $_);
    last if $_ eq 'c';
    print $_, "\n>";
}
$listen->destroy_all;