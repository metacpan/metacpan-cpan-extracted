#!perl -w
use strict;
use Net::Shared;

# first run ssrpt_s.pl in a separate terminal, and then run ssrpt_c.pl
# type stuff at the prompt that appears from at the terminal ssrpt_s.pl
# is running in and watch it "magically" appear in the terminal where
# ssrpt_c.pl is at :)

my $listen = new Net::Shared::Handler;

my $remote_shared = new Net::Shared::Remote(name=>"remote_shared",ref=>"new_shared",port=>9254,address=>'127.0.0.1');
$listen->add(\$remote_shared);

while ()
{
    my $var = $listen->retrieve($remote_shared);
    last if $var eq 'c';
    print $var,"\n" if $var;
    sleep 3;
}
$listen->destroy_all;