use strict;
use warnings;
use Data::Dumper;

use Test::More qw(no_plan);
use Parallel::MapReduce::Utils;

use Storable;
$Storable::Deparse = 1;
$Storable::Eval = 1;

# suppress silly warning about $Storable only used once
my $dummy = $Storable::Deparse;
   $dummy = $Storable::Eval;

use_ok 'Parallel::MapReduce::Worker';
use_ok 'Parallel::MapReduce::Worker::FakeRemote';
use_ok 'Parallel::MapReduce::Worker::SSH';

if (1) {
    my $w = new Parallel::MapReduce::Worker;
    isa_ok ($w, 'Parallel::MapReduce::Worker');
}

if (1) {
    my $w = new Parallel::MapReduce::Worker::FakeRemote;
    isa_ok ($w, 'Parallel::MapReduce::Worker::FakeRemote');
    isa_ok ($w, 'Parallel::MapReduce::Worker');
}

my $online = 1 if $ENV{MR_ONLINE};
#$online = 0;
exit unless $online;

if (1) {
    my $w = new Parallel::MapReduce::Worker::SSH (host => 'localhost');
    isa_ok ($w, 'Parallel::MapReduce::Worker::SSH');
    isa_ok ($w, 'Parallel::MapReduce::Worker');

    $w->shutdown;
}

use constant SERVERS => ['127.0.0.1:11211'];
my $job = 'job1:';
my $memd = new Cache::Memcached {'servers' => SERVERS, namespace => $job };

my $A = {1 => 'this is something ',
	 2 => 'this is something else',
	 3 => 'something else completely'};

{
    $memd->set ($job.'map',  sub {
				    my ($k, $v) = (shift, shift);
				    return map { $_ => 1 } split /\s+/, $v;
				});
    $memd->set ($job.'reduce', sub {
				    my ($k, $v) = (shift, shift);
				    my $sum = 0;
				    map { $sum += $_ } @$v;
				    return $sum;
				});

    foreach my $w (
		   new Parallel::MapReduce::Worker ,
		   new Parallel::MapReduce::Worker::FakeRemote ,
		   new Parallel::MapReduce::Worker::SSH (host => 'localhost'),
		   ) {

	my @chunks = chunk_n_store ($memd, $A, $job, 1000);
	my $cs = $w->map (\@chunks, 'slice1:', SERVERS, $job);
#warn Dumper $cs;

	ok (eq_set ($cs, [
			  'slice1:completely',
			  'slice1:else',
			  'slice1:is',
			  'slice1:this',
			  'slice1:something'
			  ]), ref ($w).': map alone, return keys');
	
	my $ks = $w->reduce ($cs, SERVERS, $job);
#warn Dumper $ks;
	
	ok (eq_set ($ks, [
			  'job1:96d418adfc70469380a11aaadcaf4f3e'
			  ]), ref ($w).': reducer alone, return keys');

#     my $B = fetch_n_unchunk ($memd, $ks);

#     is_deeply ($B, {
# 	              'completely' => 1,
# 		      'else' => 2,
# 		      'is' => 2,
# 		      'this' => 2,
# 		      'something' => 3
# 		      }, 'local: reduce alone, return keys');

	$w->shutdown;

    }
}

__END__




use constant WORKERS => ['127.0.0.1', '192.168.0.12'];

if (0) {
    my $mri = new Parallel::MapReduce (memcacheds => SERVERS,
				       workers => WORKERS,
				       test_memcacheds => 0,
				       farm_workers => 0);
    isa_ok($mri, 'Parallel::MapReduce');
}

if (0) {
    my $mri = new Parallel::MapReduce (policy => Parallel::MapReduce->LOCAL);

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
		      }, 'LOCAL_SERIAL');
}

foreach my $p (
#	       Parallel::MapReduce->LOCAL, 
#	       Parallel::MapReduce->FAKE_REMOTE,
	       Parallel::MapReduce->SSH_REMOTE
	       ) {
    my $mri = new Parallel::MapReduce (memcacheds => SERVERS,
				       workers => WORKERS,
				       test_memcacheds => 0,
				       farm_workers => 0,
				       policy => Parallel::MapReduce->MEMCACHED.'&'.$p);

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
		      }, 'REMOTE_SERIAL');

    $mri->shutdown;
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

