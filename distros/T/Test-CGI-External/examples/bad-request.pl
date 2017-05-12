#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use Test::CGI::External;
my $tester = Test::CGI::External->new ();
$tester->set_cgi_executable ("$Bin/../examples/bad-method.cgi");
$tester->test_not_implemented ();
$tester->test_method_not_allowed ('POST');
done_testing ();
