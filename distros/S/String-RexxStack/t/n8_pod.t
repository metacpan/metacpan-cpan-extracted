use Pod::Checker ;
use Test::More;
use IO::File;

my @musthave = ( 
	qw(  NAME SYNOPSIS DESCRIPTION EXPORT AUTHOR ), 
        'SEE ALSO',
);


plan tests=> 1  + @musthave ; 

my $dir   =  ( $0 =~ m!^t/!) ? '.' : '..';
my $file  =  "$dir/lib/String/RexxStack/Named.pm";
my $null  =   new IO::File '/dev/null', '>'   ;
my $c     =   new Pod::Checker  -warnings=>0,  -quiet=>1 ;
$c->parse_from_file($file, $null );
my @nodes =   $c->node() ;



is  $c->num_errors()  =>   0 , 'no pod errors';

foreach my $must (@musthave) {
        ok  +(map {$must =~ /^$_$/ }   @nodes)   , "have $must"  ;
}

