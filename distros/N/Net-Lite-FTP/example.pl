#!/usr/bin/perl -w
#
use lib "./lib";
use Net::Lite::FTP;

my $tlsftp=Net::Lite::FTP->new();
$tlsftp->open("ftp.tls.pl","21");
$tlsftp->user("user");
$tlsftp->pass("password");
$tlsftp->list();
$tlsftp->cwd("pub");
my $files=$tlsftp->list("*.exe");
foreach $f (@$files) {
 print "File: $f\n";
};
$tlsftp->get("File.txt");# Will overwrite "File.txt" at local directory
my $slurped=$tlsftp->slurp("Some.file.txt");# Slurp remote file into scalar.
print length($slurped)." bytes slurped\n";
