@rem = '--*-Perl-*--
@echo off
perl -x -S %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';
#!perl
#line 8
use Config;

use File::Copy;

my $destdir=$Config{"installsitearch"};

copy ("pdf.pm",$destdir);

mkdir ("$destdir\\PDF",777);

foreach ( <pdf/*.pm>) {
  copy ( $_,$destdir . "\\$_" );
}
__END__
:endofperl
