package LongRunning;
use Moose;
use 5.010;

with 'MooseX::Runnable';

# I use this to test the +Restart plugins

sub run {
    say "[$$] App is starting";
    while(1){
        sleep 86400;
    }
}

1;
