use strict;
use warnings;

#use lib 't/lib';

use Data::Dumper;

use Test::More qw(no_plan);

use_ok 'Parallel::MapReduce';
use_ok 'Parallel::MapReduce::Sequential';
use_ok 'Parallel::MapReduce::Testing';

use constant SERVERS => ['127.0.0.1:11211'];
#use constant WORKERS => ['127.0.0.1', '127.0.0.1', '127.0.0.1'];
use constant WORKERS => ['127.0.0.1', '127.0.0.1'];
#use constant WORKERS => ['127.0.0.1'];
#use constant WORKERS => ['192.168.0.12'];

{
    my $mri = new Parallel::MapReduce::Testing;
    my $A = {1 => 'this is something ',
	     2 => 'this is something else',
	     3 => 'something else completely'};
    my $B = $mri->mapreduce (
			     sub {
				 my ($k, $v) = (shift, shift);
				 return map { $_ => 1 } split /\s+/, $v;
			     },
			     sub {
				 my ($k, $v) = (shift, shift);
				 my $sum = 0;
				 map { $sum += $_ } @$v;
				 return $sum;
			     },
			     $A
			     );
#warn Dumper $B;
    is_deeply ($B, {
	'completely' => 1,
	'else' => 2,
	'is' => 2,
	'this' => 2,
	'something' => 3
	}, "Testing standalone");
}

#-- the rest only works in the presence of memcacheds

my $online = 1 if $ENV{MR_ONLINE};
#$online = 0;
exit unless $online;

{
    my $mri = new Parallel::MapReduce (MemCacheds => SERVERS,
				       Workers => WORKERS);
    isa_ok ($mri, 'Parallel::MapReduce');
}

{
    my $mri = new Parallel::MapReduce (MemCacheds => SERVERS, Workers => WORKERS);

    my $A = {1 => 'this is something ',
	     2 => 'this is something else',
	     3 => 'something else completely'};

    my $B = $mri->mapreduce (
			     sub {
				 my ($k, $v) = (shift, shift);
				 return map { $_ => 1 } split /\s+/, $v;
			     },
			     sub {
				 my ($k, $v) = (shift, shift);
				 my $sum = 0;
				 map { $sum += $_ } @$v;
				 return $sum;
			     },
			     $A
			     );
#    warn Dumper \%B;
    is_deeply ($B, {
	              'completely' => 1,
		      'else' => 2,
		      'is' => 2,
		      'this' => 2,
		      'something' => 3
		      }, 'local serial');

    $mri->shutdown;
}

foreach my $mr (
		'Parallel::MapReduce',
		'Parallel::MapReduce::Sequential',
		'Parallel::MapReduce::Testing'
		) {
    foreach my $w (
		   'Parallel::MapReduce::Worker',
		   'Parallel::MapReduce::Worker::FakeRemote',
		   'Parallel::MapReduce::Worker::SSH'
		   ) {
	my $mri = new $mr (MemCacheds => SERVERS,
			   Workers => WORKERS,
			   WorkerClass => $w,
			   );
	my $A = {1 => 'this is something ',
		 2 => 'this is something else',
		 3 => 'something else completely'};
	my $B = $mri->mapreduce (
				 sub {
				     my ($k, $v) = (shift, shift);
				     return map { $_ => 1 } split /\s+/, $v;
				 },
				 sub {
				     my ($k, $v) = (shift, shift);
				     my $sum = 0;
				     map { $sum += $_ } @$v;
				     return $sum;
				 },
				 $A
				 );
#warn Dumper $B;
	is_deeply ($B, {
	              'completely' => 1,
		      'else' => 2,
		      'is' => 2,
		      'this' => 2,
		      'something' => 3
		      }, "$mr -> $w");
    $mri->shutdown;
    }
}

__END__


    my %A = $mri->hash; # eigener prefix
#    tie %A, 'Hash::Tie::Memcached', prefix => 'aaa:', servers => SERVERS;

# TESTS
    %A = (1 => 'this is something
this is something else
something else completely');
# TESTS

}

{
    my $mri = new Parallel::MapReduce (memcacheds => SERVERS, workers => WORKERS);
    my %A = $mr->hash;

    %A = (1 => 'this is something
this is something else
something else completely');

    # macht automagisch eigenen hash
# tests
}

