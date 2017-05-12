#!/usr/bin/perl	

# Copyright (c) 2000  Josiah Bryan  USA
#
# See AUTHOR section in pod text below for usage and distribution rights.   
#

BEGIN {
	 $System::Index::VERSION = "0.1";
	 $System::Index::ID = 
'$Id: System::Index.pm, v'.$System::Index::VERSION.' 2000/04/09 12:27:05 josiah Exp $';
}

package System::Index;

	require 5.005_62;
	use strict;
	use warnings;
	use Benchmark;
	
	require Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw(cpu_index hd_index mem_index);

	sub cpu_index {
		my $timelen=($_[0])?$_[0]:2;
		my $debug=($_[1])?$_[1]:0;
		my (@vals,$len);
	    my $a=new Benchmark;
	    $len=0;
		while($len<$timelen) {
			my $_tmp = timeit(10000, '$x=500;$y=12.451252;$z=$x/$y;$z+=$y/$z*$z;');
			push @vals, (@$_tmp)[1];
		    my $b=new Benchmark;
			my $t=timediff($b,$a);
			$len+=(@$t)[1];
			print "Count:$len\r" if($debug);
		}
		
		my $sum=0;
		for my $z (0..$#vals-1) {
			$sum+=$vals[$z];
		}
		return sprintf('%.03f',$sum/$len);
	}
		
	sub hd_index {
		my $timelen=($_[0])?$_[0]:2;
		my $debug=($_[1])?$_[1]:0;
		my $file=($_[2])?$_[2]:'.hd_index.~$$';
		my (@vals,$len);
	    my $a=new Benchmark;
	    $len=0;
		while($len<$timelen) {
			my $_tmp = timeit(100, q{
				open(FILE,">$file");for(0..10) { print FILE "$_:" } close(FILE);
				open(FILE,"$file");my @lines=<FILE>;close(FILE);
				unlink(">$file"); 
			});
			push @vals, (@$_tmp)[1];
			my $b=new Benchmark;
			my $t=timediff($b,$a);
			$len+=(@$t)[1];
			print "Count:$len\r" if($debug);
		}
		
		my $sum=0;
		for my $z (0..$#vals-1) {
			$sum+=$vals[$z];
		}
		return sprintf('%.03f',$sum/$len);
	}
	
	sub mem_index {
		my $timelen=($_[0])?$_[0]:2;
		my $debug=($_[1])?$_[1]:0;
		my (@vals,$len);
	    my $a=new Benchmark;
	    $len=0;
		while($len<$timelen) {
			my $_tmp = timeit(1000, q{
				my @array = [ 777 x 777 ];
				my $hash = { a=> $array[0..100], b=> $array[101..200], c=> $array[201..300] };
				my @tmp;
				for my $x (0..$#array-1) {$tmp[$x]=$array[$x]}
				my $hash2=$hash;
			});
			push @vals, (@$_tmp)[1];
			my $b=new Benchmark;
			my $t=timediff($b,$a);
			$len+=(@$t)[1];
			print "Count:$len\r" if($debug);
		}
		
		my $sum=0;
		for my $z (0..$#vals-1) {
			$sum+=$vals[$z];
		}
		return sprintf('%.03f',$sum/$len);
	}


__END__



=head1 NAME

System::Index - A collection of three load-indexing	functions for memory, CPU, and HD.

=head1 SYNOPSIS

	use System::Index;
	my $cpu_load = cpu_index();    # Averages 0.120 on my system, 'light' load
	my $mem_load = mem_index();    # Averages 0.88 on my system, 'light' load
	my $hd_load = hd_index();      # Averages 0.250 on my system, 'light' load
	
=head1 VERSION

This is Version 0.1 ($Id: System::Index.pm, v0.1 2000/04/09 12:27:05 josiah Exp $).

=head1 DESCRIPTION

This is a simple load-measure for memory, CPU, and hard-disk access. It requires
Benchmark and Export. It measures the load with a simple timethis() benchmark loop
with a few stat functions thrown in for good measure. 

System::Index exports three functions by default to the callers namespace. These three
functions are listed below.

Each of the functions take two optional parameters, $timelen and $debug (in that order).

$timelen specifies the length of the indexing loop in seconds. $timelen defaults to 2 
seconds if $timelen is not given, or if it is 0. 

$debug is a simple boolean flag to display the index counts for each internal index loop.
$debug defaults to 0 if $debug is not given, or if it is 0.

=head1 FUNCTIONS

=item cpu_index($timelen, $debug);

Returns a decimal string with three significant digits after the decimal (remember sig-figs
from highschool chemistry? :-) All three functions return the same format string.

This uses a simple inner loop of complex multiplication, division, and additions to measure
the load of the CPU at that point in time. It measures the time it takes to complete
the inner loop and stores this in an array. It repeats the inner loop until the total 
time of all the inner loops has taken more than $timelen. Then it averages the sum of the
inner loops by the total time of all loops and returns that number through sprintf() to format
the number.

=item mem_index($timelen, $debug);

This uses a simple inner loop of large array ( 777 x 777 ) creation and copying to index
the load of the memory at that point in time. It measures the time it takes to complete
the inner loop and stores this in an array. It repeats the inner loop until the total 
time of all the inner loops has taken more than $timelen. Then it averages the sum of the
inner loops by the total time of all loops and returns that number through sprintf() to format
the number.

=item hd_index($timelen, $debug, $file);

This uses a simple inner loop of simple file access by creating a file, writing 10 integers to
the file, closing and re-opening, then deleting the file. This loop is used to index the
load of the hard disk at that point in time. It measures the time it takes to complete
the inner loop and stores this in an array. It repeats the inner loop until the total 
time of all the inner loops has taken more than $timelen. Then it averages the sum of the
inner loops by the total time of all loops and returns that number through sprintf() to format
the number.

This has a third optional parameter, $file. The default file name that hd_index() uses to
index the HD with is '.hd_index.~$$'. If you wish to use another file name, you may pass the
file name in the third argument to hd_index(). Remember, whatever file used is automatically
removed with unlink() before returning.


=head1 BUGS

This is a beta release of C<System::Index>, and that holding true, I am sure 
there are probably bugs in here which I just have not found yet. If you find bugs in this module, I would 
appreciate it greatly if you could report them to me at F<E<lt>jdb@wcoil.comE<gt>>,
or, even better, try to patch them yourself and figure out why the bug is being buggy, and
send me the patched code, again at F<E<lt>jdb@wcoil.comE<gt>>. 



=head1 AUTHOR

Josiah Bryan F<E<lt>jdb@wcoil.comE<gt>>

Copyright (c) 2000 Josiah Bryan. All rights reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself.

C<System::Index> is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 DOWNLOAD

You can always download the latest copy of System::Index
from http://www.josiah.countystart.com/modules/get.pl?sysidx:pod


