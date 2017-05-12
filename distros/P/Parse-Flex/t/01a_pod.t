use Pod::Checker;
use Test::More;

my @musthave = ( 
	qw(  NAME SYNOPSIS DESCRIPTION EXPORT AUTHOR ), 
        'SEE ALSO',
);

my $num = (1 + @musthave) * 2;
plan tests=>  $num ;

my $nochecker = (eval 'use Pod::Checker' , $@ );

SKIP: { 
		skip 'no Pod::Checker', $num  if  $nochecker;


	##### Flex.pm
	my $dir   =  ( $0 =~ m!^t/!) ? '.' : '..';
	my $file  =  "$dir/lib/Parse/Flex.pm";
	my $c     =   new Pod::Checker  -warnings=>0,  -quiet=>1 ;
	$c->parse_from_file($file, \*STDERR );
	my @nodes =   $c->node() ;

	is  $c->num_errors()  =>   0 , "$file is fine:";

	foreach my $must (@musthave) {
		ok  +(map {$must =~ /^$_$/ }   @nodes)   , "have $must"  ;
	}

	$file  =  "$dir/lib/Parse/Flex/Generate.pm";
	$c->parse_from_file($file, \*STDERR );
	@nodes =   $c->node() ;

	is  $c->num_errors()  =>   0 , "$file is fine:";

	foreach my $must (@musthave) {
		ok  +(map {$must =~ /^$_$/ }   @nodes)   , "have $must"  ;
	}

};
