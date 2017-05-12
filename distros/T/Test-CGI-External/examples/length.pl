#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $stuff = 'ばびぶべぼ';
note (length ($stuff));
use Test::CGI::External;
my %options;
$options{input} = $stuff;
my $tester = Test::CGI::External->new ();
$tester->set_cgi_executable ("$Bin/../t/test.cgi");
$tester->run (\%options);
note ($options{content_length});
$tester->plan ();
