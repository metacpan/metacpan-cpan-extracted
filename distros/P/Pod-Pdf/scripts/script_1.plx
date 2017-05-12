#!usr/bin/perl -w

use Pod::Pdf;
push @ARGV, qw(--paper usletter --verbose 1);
push @ARGV, 'podfilename';
pod2pdf(@ARGV);

exit 0;
