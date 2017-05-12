#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use Test::CGI::External;
my $tester = Test::CGI::External->new ();
$tester->set_cgi_executable ("$Bin/never-modified.cgi");
$tester->do_caching_test (1);
my %options = (
    REQUEST_METHOD => 'GET',
);
$tester->run (\%options);
note ("The output is the output from the non-cached version.");
like ($options{body}, qr/Columbus/, "Body is from non-cached version");
done_testing ();

