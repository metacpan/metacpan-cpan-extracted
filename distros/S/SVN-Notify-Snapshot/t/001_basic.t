#!/usr/bin/perl 
require SVN::Notify;
use Test::More;
require "t/coretests.pm";

SKIP: {
    my $SVNNOTIFY = $ENV{'SVNNOTIFY'} || SVN::Notify->find_exe('svnnotify');
    skip "Cannot locate svnnotify binary!", 54
    	unless defined($SVNNOTIFY);

    reset_all_tests();
    run_tests($SVNNOTIFY);
}
