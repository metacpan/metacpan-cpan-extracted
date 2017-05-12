#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use Test::CGI::External;
my %options;
$options{REQUEST_METHOD} = 'GET';
$options{QUERY_STRING} = "q=rupert+the+bear";
my $tester = Test::CGI::External->new ();
$tester->set_cgi_executable ("$Bin/rupert.cgi");
$tester->run (\%options);
like ($options{body}, qr/everyone/i);
done_testing ();
