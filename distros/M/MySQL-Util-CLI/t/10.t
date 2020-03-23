#!/usr/bin/env perl

# vim: tabstop=4 expandtab

###### PACKAGES ######

use Modern::Perl;
use Data::Printer alias => 'pdump';
use Test::More;
use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');

use MySQL::Util::CLI;

###### CONSTANTS ######

###### GLOBALS ######

###### MAIN ######

my $cli = MySQL::Util::CLI->new;
ok($cli);

done_testing();

###### END MAIN ######

