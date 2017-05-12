#!perl -w

# Startup Test:
# $Id: startup.t,v 1.7 2006/11/27 13:42:52 roland Exp $

use Schedule::Cron;
use Test::More tests => 1;

our %SKIP;

$| = 1;
#print STDERR " (may take a minute) ";

SKIP: {
    eval { alarm 0 };
    skip "alarm() not available", 1 if $@;
    $SIG{QUIT} = sub { 
        alarm(0);
        pass;
        exit;
    };
    
    $SIG{ALRM} = sub { 
        fail;
        exit;
    };
    
    $cron = new Schedule::Cron(sub { kill QUIT, shift; alarm 1; });
    $cron->add_entry("* * * * * */2",$$);
    
    alarm(6);
    $cron->run;
}


