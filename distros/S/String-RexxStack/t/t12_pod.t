use Pod::Checker ;
use Data::Dumper;
use Test::More;
use IO::File;

our @musthave = ( qw(  NAME SYNOPSIS DESCRIPTION EXPORT AUTHOR), 'SEE ALSO');

BEGIN {
	eval 'require Pod::Checker' ;
	if ($@) {
		plan (skip_all => 'skipping: Pod::Checker not installed');
		Posix::_exit(0) ;
	}else{
	     plan (tests => 1 + 6) ;
	     import Pod::Checker;
	}
}


my $dir   =  ( $0 =~ m!^t/!) ? '.' : '..';
my $file  =  "$dir/lib/String/TieStack.pm";
my $null  =   new IO::File '/dev/null', '>'   ;
my $c     =   new Pod::Checker  -warnings=>0,  -quiet=>1 ;
$c->parse_from_file($file, $null );
my @nodes =   $c->node() ;



is  $c->num_errors()  =>   0 , 'no pod errors';

foreach my $must (@musthave) {
        ok  +(map {$must =~ /^$_$/ }   @nodes)   , "have $must"  ;
}

