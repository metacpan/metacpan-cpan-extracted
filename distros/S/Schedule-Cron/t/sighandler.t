#!perl -w

# Startup Test:
# $Id: sighandler.t,v 1.2 2006/11/27 13:42:52 roland Exp $

use Schedule::Cron;
use Test::More;

if ($^O =~ /Win32/i) {
    plan skip_all => "Test doesn't work on Win32";
} else {
    plan tests => 1;
}
$| = 1;

SKIP: {
    eval { alarm 0 };
    skip "alarm() not available", 1 if $@;
    
    # Check, whether an already installed signalhandler is called
    $SIG{CHLD} = sub { 
        pass;
        exit 0;
    };
    
    $SIG{ALRM} = sub { 
        fail;
        exit 0;
    };
    
    
    my $cron = new Schedule::Cron(sub { sleep(1); });
    $cron->add_entry("* * * * * *");
    alarm(5);
    $cron->run;
}

