#!/usr/bin/perl

print "1..$tests\n";

our $_pos = 1;

require PAB3;
import PAB3;

# testing class

$pab = PAB3->new();
&_check( $pab );

$ret = $out = '';

# testing parser

$tmp = $pab->parse_template( '<* $ret = 123 *>' );
&_check( $tmp );

# testing execution

eval( $tmp );
&_check( $ret == 123 );

# testing PRINT

open $prv_stdout, ">&STDOUT" or die "can't dup STDOUT: $!";
close STDOUT;
open STDOUT, '>', \$out or die "can't open STDOUT: $!";

$tmp = $pab->parse_template( '<*= $ret *>' );
eval( $tmp );

close STDOUT;
open STDOUT, ">&", $prv_stdout or die "can't dup previous STDOUT: $!";

&_check( $out == $ret );

BEGIN {
	$tests = 4;
	#push @INC, 'blib/lib', 'blib/arch';
}

sub _check {
	my( $val ) = @_;
	print "" . ( $val ? "ok" : "fail" ) . " $_pos\n";
	$_pos ++;
}
