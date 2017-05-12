#!/usr/bin/perl

use lib 'lib', '../lib';

use Symbol::Util ':all';

$\ = "\n";

print '=== Simple undef destroys all slots';
eval {
    our $FOO = 42;
    sub FOO { 666 };

    print "*** Before:";
    print $FOO;
    print FOO();
    
    undef *FOO;
    
    print "*** After:";
    print $FOO;
    print FOO();
};

print '=== delete_glob() can remove just CODE slot';
eval {
    our $BAR = 42;
    sub BAR { 666 };
    
    print "*** Before:";
    print $BAR;
    print BAR();

    delete_glob("BAR", "CODE");
    
    print "*** After:";
    print $BAR;
    print BAR();
};
