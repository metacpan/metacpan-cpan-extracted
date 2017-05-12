#!/usr/bin/perl
use strict;
use warnings;
use blib;
$ValueObject::ObjectCount = 0;
sub ValueObject::new {
	my $cls = shift;
	my $v = rand();
	$ValueObject::ObjectCount++;
	my $self = \$v;
	bless $self, $cls;
}

sub ValueObject::DESTROY {
	$ValueObject::ObjectCount--;
}

$KeyObject::ObjectCount = 0;
sub KeyObject::new {
	my $cls = shift;
	my $v = rand();
	$KeyObject::ObjectCount++;
	my $self = \$v;
	bless $self, $cls;
}
sub KeyObject::DESTROY { $KeyObject::ObjectCount--; }

package main;
use strict;
use warnings;


use Data::Dumper;
use Getopt::Long;
use Ref::Store::Common;
use Carp::Heavy;

use Log::Fu { level=> "debug", target => \*STDOUT };
use lib "/home/mordy/src/Ref-Store/lib";

use Benchmark qw(:all);
use Module::Stubber 'Memory::Usage' => [],
	will_use => { state => sub { [] } };
	
my $Htype = 'Ref::Store::PP';
GetOptions('x|xs' => \my $use_xs,
	'p|pp' => \my $use_pp,
	'sweeping' => \my $use_sweep,
	'c|count=i' => \my $count,
	'm|mode=s' => \my $Mode,
	'd|dump'	=> \my $Dump,
	'prealloc=i' => \my $Prealloc,
	'cycles=i'	=> \my $Cycles
);

$Cycles ||= 1;
$Prealloc ||= 0;
$count ||= 50;
$Mode ||= 'all';

my $cur_cycle = 0;
my $_mu;

if($^O !~ /linux/i) {
	log_warn("Can't run Memory::Usage on non-linux systems (procfs needed)");
} else {
	$_mu = Memory::Usage->new();
}

sub memusage_log {
	return unless defined $_mu;
	my $label = shift;
	$_mu->record($label);
}

sub memusage_dump {
	return unless defined $_mu;
	#Dump memory usage information:
	log_info("Dumping memory usage statistics");
	my $mpriv = 0;
	printf STDERR ("%-40s %6s\t %6s\n", "State", "RSS", "DIFF");
	foreach my $st (@{$_mu->state()}) {
		my ($msg,$rss) = @{$st}[1,3];
		$rss /= 1024;
		my $diff = $rss - $mpriv;
		printf STDERR ("%-40s %6dMB\t %6d\n", $msg, $rss, $diff);
		$mpriv = $rss;
	}
}

my $i_BEGIN = 1;
my $i_END = $count;
memusage_log("Begin");
sub single_pass {
	my $Hash = $Htype->new();
	my ($impl_s) = (split(/::/, $Htype))[-1];
	my $mu_prefix = "$cur_cycle: [$impl_s]";
	my @olist;
	#Create object list..
	timethis(1, sub {
		@olist = map { ValueObject->new() } ($i_BEGIN..$i_END);
	}, "Object Creation");
	
	memusage_log("$mu_prefix Objects Created");
	
	if($Mode =~ /key|all/i ) {
		timethis(1, sub {
			foreach my $i ($i_BEGIN..$i_END) {
				my $obj = $olist[$i-1];
				$Hash->store($i, $obj);
				$Hash->store(-$i, $obj);
				push @olist, $obj;
			}
		}, "String Key (STORE)");
		
		log_infof("Created %d objects\n", $ValueObject::ObjectCount);
		
		log_infof("Have %d objects now", $ValueObject::ObjectCount);
		
		memusage_log("$mu_prefix Key storage");
		
		timethis(1, sub {
			foreach my $i($i_BEGIN..$i_END) {
				eval {
					my $obj1 = $Hash->fetch($i) or die "POSITIVE KEY FAIL!";
					my $obj2 = $Hash->fetch(-$i) or die "GAH!";
					$obj1->isa('ValueObject') &&
					$obj2->isa('ValueObject') &&
					$obj1 == $obj2
						or die
					"Soemthing happen!";
					#log_info($obj1);
				}; if($@) {
					#print Dumper($Hash);
					die $@;
				}
			}
		}, "String Key (FETCH)");
	}
	
	my (@klist,@klist2);
	if($Mode =~ /objk|all/i) {
		@klist = map { KeyObject->new() } (0..$i_END-1);
		@klist2 = map { KeyObject->new() } (0..$i_END-1);
		memusage_log("$mu_prefix ObjK created");
		
		timethis(1, sub {
			foreach my $i (0..$i_END-1) {
				$Hash->store($klist[$i], $olist[$i]);
				$Hash->store($klist2[$i], $olist[$i]);
			}
		}, "Object Key (STORE)");
		memusage_log("$mu_prefix ObjK Store");
		
		timethis(1, sub {
			foreach my $i (0..$i_END-1) {
				my $res1 = $Hash->fetch($klist[$i]);
				my $res2 = $Hash->fetch($klist2[$i]);
				if(!$res1 || !$res2 || $res1 != $res2 || $res1 != $olist[$i]) {
					die("Object key mismatch!");
				}
			}
		}, "Object Key (FETCH)");
	}
	
	if($Mode =~ m/attr|all/i) {
		my $ATTRTYPE = 42;
		my $ATTRTYPE_ALT = "ALLYOURBASE";
		$Hash->register_kt($ATTRTYPE, "TESTATTR");
		$Hash->register_kt($ATTRTYPE_ALT, "ALTATTR");
		my @attrpairs = (
			[43, $ATTRTYPE],
			[666, $ATTRTYPE],
			[770, $ATTRTYPE],
			[1, $ATTRTYPE_ALT]
		);
		
		timethis(1, sub {
			foreach my $o (@olist) {
				$Hash->store_a(@$_, $o) foreach @attrpairs;
			}
		}, "Attribute (STORE)");
		memusage_log("$mu_prefix Attribtue Storage");
		
		my $result_count = 0;
		timethis(1, sub {
			foreach my $apair (@attrpairs) {
				my @tmp = $Hash->fetch_a(@$apair);
				$result_count += scalar @tmp;
			}
		}, "Attribute (FETCH)");
		log_info("Got total $result_count entries");
		
	}
	
	if($Dump) {
		$Hash->dump();
	}
	
	log_infof("FORWARD=%d, REVERSE=%d, KEYS=%d, ATTRS=%d",
		scalar values %{$Hash->forward},
		scalar values %{$Hash->reverse},
		scalar values %{$Hash->scalar_lookup},
		scalar values %{$Hash->attr_lookup});

	
	#print Dumper($Hash);
	
	timethis(1, sub {
		@olist = ();
		@klist = ();
		@klist2 = ();
	}, "Delete");
	
	if($Hash->isa('Ref::Store::Sweeping')) {
		log_warn("Sweeping..");
		$Hash->sweep();
	}
	

	log_debug("Everything should be cleared");
	log_infof("Have %d objects now", $ValueObject::ObjectCount);
	log_infof("FORWARD: %d, REVERSE=%d",
		scalar values %{$Hash->forward},
		scalar values %{$Hash->reverse}
	);
	if(!$Hash->is_empty) {
		print Dumper($Hash);
	}
	#$Hash->dump();
	#print Dumper($Hash);
}

my $use_all = !($use_xs||$use_pp||$use_sweep);
my @impl_map = (
	$use_xs, 'XS',
	$use_pp, 'PP',
	$use_sweep, 'Sweeping'
);

my @EnabledImplementations;
while (@impl_map) {
	my ($enabled,$backend) = splice(@impl_map, 0, 2);
	if(!$enabled && !$use_all) {
		next;
	}
	push @EnabledImplementations, 'Ref::Store::'.$backend;
}

foreach (1..$Cycles) {
	$cur_cycle = $_;
	log_info("Cycle: $cur_cycle");
	foreach my $impl (@EnabledImplementations) {
		$Htype = $impl;
		eval "require $Htype";
		log_warn("Using $Htype");
		
		single_pass();
	}
}

memusage_dump();

use Scalar::Util qw(weaken);

sub compare_simple {
	my %simplehash;
	my @vals;
	foreach ($i_BEGIN..$i_END) {
		push @vals, ValueObject->new();
	}
	timethis(1, sub {
		foreach my $i ($i_BEGIN..$i_END) {
			$simplehash{$i} = $vals[$i];
			$simplehash{-$i} = $vals[$i];
		}
	}, "Normal hash: STORE");
	timethis(1, sub {
		foreach my $i ($i_BEGIN..$i_END) {
			my $copy;
			$copy = $simplehash{$i};
			$copy = $simplehash{-$i};
		}
	}, "Normal hash: FETCH");
	timethis(1, sub {
		%simplehash = ();
	}, "Normal hash: DELETE");
	
	%simplehash = ();
	timethis(1, sub {
		foreach my $i (0..$i_END-1) {
			foreach my $a (qw(attr1 att2 att3 attr4)) {
				weaken($simplehash{$a}->{$vals[$i]+0} = $vals[$i]);
			}
		}
	}, "Normal Hash, ATTR STORE");
}

compare_simple();
log_info("Exiting..");
