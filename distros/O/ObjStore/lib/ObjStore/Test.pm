use strict;
package ObjStore::Test;
use ObjStore;
use base 'Exporter';
use Test;
use Carp;
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(testofy_av testofy_hv testofy_index);

# double check # of tests XXX

sub testofy_av {
    my ($cnt, $mk) = @_;
    carp "testofy_av: please fix test numbering (31 tests)" if $cnt != 31;

    # EASY TESTS
    my $av = $mk->();
    ok $av->os_class, 'ObjStore::AV';

    ok !defined $av->FETCH(-1);
    ok !defined $av->POP;
    ok !defined $av->SHIFT;

    for (1..2) {
	$av->CLEAR;
	ok $av->FETCHSIZE, 0;
	for (0..50) {
	    $av->[$_] = [$_];
	}
	ok $av->FETCHSIZE, 51;
    }
    ok $av->POSH_CD(2)->[0], 2;

    ok $av->PUSH(69,[],1), 3;
    ok $av->FETCH($av->FETCHSIZE - 1), 1;
    for (1..2) { $av->POP; }
    my $e = $av->POP;
    ok $e, 69;
    
    ok $av->UNSHIFT(1,2,[]), 3;
    ok $av->FETCH(0), 1;
    $av->SHIFT;
    $e = $av->SHIFT;
    ok $e, 2;
    $av->SHIFT;
    
    $av->const;

    begin sub { $av->[3] = 100 };
    ok $@, '/READONLY/';

    # NESTED DUSTRUCTION
    my $ary = $mk->();
    $ary->[0] = $mk->();
    for (0..5) {
	$ary->[3][$_] = $_;
	next if $_ == 3;
	$ary->[$_] = $_;
    }
    ok 1;

    # SPLICE
    my $tostr = sub {
	my $av = shift;
	my $s='';
	for (my $x=0; $x < $av->FETCHSIZE; $x++) {
	    $s .= $av->[$x];
	}
	$s
    };

    $av = $mk->();
    $av->SPLICE(0, 0, 1,2,3);
    ok $tostr->($av), '123';
    
    my $shift = $av->SPLICE(0, 1);
    ok $shift, 1;
    ok $tostr->($av), '23';

    my $pop = $av->SPLICE(-1);
    ok $pop, 3;
    ok $tostr->($av), '2';

    $av->SPLICE($av->FETCHSIZE, 0, 3,4,5);
    ok $tostr->($av), '2345';
    
    $av->SPLICE(0, 0, 0,1);
    ok $tostr->($av), '012345';

    $av->SPLICE(0, 4, 2,1,0);
    ok $tostr->($av), '21045';

    my @d = $av->SPLICE(0);
    ok $av->FETCHSIZE, 0;
    ok join('',@d), '21045';

    $av->SPLICE(0,0, [],{},[]);
    ok ref $av->[0], 'ObjStore::AV';
    ok ref $av->[1], 'ObjStore::HV';
    ok ref $av->[2], 'ObjStore::AV';

    $av->SPLICE(20,-1, 1,2);
    ok $av->FETCH(4), 2;
}

sub testofy_hv {
    my ($cnt, $mk) = @_;
    carp "testofy_hv: please fix test numbering (9 tests)" if $cnt != 9;

    my $ah = $mk->();
    ok $ah->os_class, 'ObjStore::HV';
    ok !defined $ah->FIRSTKEY;

    for (1..2) {
	%$ah = ();
	for (1..8) {
	    my $tostore = ObjStore::translate($ah, { at => $_ });
	    my $stored = $ah->{$_} = $tostore;
	    $stored == $tostore or die "$stored != $tostore";
	    my @ks = keys %$ah;
	    $ah->count() == @ks or die "$_ != ".$ah->count;
	    @ks == $_ or die "$_ != ".@ks;
	}
    }

    $ah->{8} = "Replacement Test";
    ok $ah->{8}, '/(?i)replace/';

    ## strings work?
    my $pstr = pack('c4', 65, 66, 0, 67);
    $ah->{packed} = $pstr;
    ok($ah->{packed} eq $pstr) or do {
	print "ObjStore: " . join(' ', unpack("c*", $ah->{packed})) . "\n";
	print "perl:     " . join(' ', unpack("c*", $pstr)) . "\n";
    };
    delete $ah->{packed};

    ok(exists $ah->{1} && !exists $ah->{'not there'}) or warn "exists?";
    ok $ah->POSH_CD('1')->{at}, 1;

    my $ok=1;
    
    my @k = sort keys %$ah;
    @k == 8 or warn "cursors are broken = @k";
    for (my $x=1; $x <= 8; $x++) {
	if ($k[$x-1] != $x) {
	    $ok=0;
	    warn "$k[$x-1] != $x";
	}
    }
    ok $ok;
    
    delete $ah->{3};
    @k = sort keys %$ah;
    for (my $x=0; $x < @k; $x++) {
	my $right = ($x >= 2? $x+2 : $x+1);
	if ($k[$x] != $right) {
	    $ok=0;
	    warn "$k[$x] != $right";
	}
    }
    ok $ok;

    $ah->const;
    begin sub { delete $ah->{1} };
    ok $@, '/READONLY/';
    undef $@;

    delete $ah->{'not there'};
}

my @TOYS = ('Bubble Mower',
	    'Discovery Beads',
	    'Pooh Memory Game',
	    'Hugg America',
	    'Solar System Mobile',
	    'Glow Stickables',
	    'Storytime Finger Puppets',
	    'Goldilocks',
	    'Tickle Me Cookie Monster',
	    'Beanie Babies',
	    'Barbie as Sleeping Beauty',
	   );

sub testofy_index {
    my ($cnt, $mk) = @_;
    carp "testofy_index: please fix test numbering (29 tests)" if $cnt != 29;

    do { # numeric comparisons
	my $nums = $mk->();
	ok $nums->os_class, 'ObjStore::Index';
	$nums->configure(path => 'num', unique => 0);
	for (1..5) {
	    $nums->add({num => $_});
	    $nums->add({num => .5 * $_});
	    $nums->add({num => -80000 + $_ * 40000 });
	    $nums->add({typo => 20 * $_});
	}
	my $e = ObjStore::HV->new($nums, { typo => 20 });
#	$nums->remove($e);
#	for (.0005, .5, $nums->[$nums->FETCHSIZE()-1]->{num}) {
#	    $e->{num} = $_;
#	    $nums->remove($e);
#	}
	my $n = $nums->[0];
	begin sub { $n->{num} *= 2 };
	ok $@, '/READONLY/';
	ok(($n->{'notnum'}=1), 1);
	begin sub { $n->{num} = 0; };
	ok $@, '/READONLY/';

	my @nums;
	$nums->map(sub { push(@nums, shift->{num}) });
	
	my @sorted = sort { $a <=> $b } @nums;
	my $ok=1;
	for (my $x=0; $x < @nums; $x++) { $ok=0, last if $nums[$x] != $sorted[$x] }
	ok($ok);

	my $c = $nums->new_cursor;
	begin sub { $c->each('bogus'); };
	ok $@, '/integer/';

	my $total=0;
	while (my $n = $c->each(1)) { $total+= $n->{num}; }
	ok $total, 200022.5;

	begin sub { $c->store([]); };
	ok $@, '/unavailable/';

	ok !$nums->add($nums->[0]), 1;
	begin sub { $n->{num} = 0; };
	ok $@, '/READONLY/';

	my $numsdup = $mk->();
	$numsdup->configure(path => 'num', unique => 0);
	$ok = begin sub { $numsdup->add($nums->[0]); 1; };
	ok $@, '/multiple/';

	$n->HOLD;
	$nums->CLEAR();
	ok($n->{num} = 42,42);
    };

    #---------------------

    my $nx = $mk->();
    $nx->configure(path=>"name");
    $nx->configure(path=>"name");
    
    my $ax = $mk->();
    ok(!defined $ax->[0]);
    $ax->configure(unique => 0, path=>"age/0");

    my $j = $ax->segment_of;
    my @ages;
    push(@ages, 
	 new Toy::AgeGrp($j, [1,3]),
	 new Toy::AgeGrp($j, [2,4]),
	 new Toy::AgeGrp($j, [2,7]),
	 new Toy::AgeGrp($j, [6,12]),
	 new Toy::AgeGrp($j, [5,32]),
	);

    srand(0);
    for my $n (@TOYS) {
	my $t = new Toy($j, { 
			     name => $n,
			     age => $ages[int(rand(@ages))],
			    });
	$t->{age}->const;
	$nx->add($t);
	$ax->add($t);
    }
    ok $nx->FETCHSIZE, 11;

    $nx->map(sub { my $t=shift; $ax->add($t) });  #test non-unique add

    $ax->map(sub { my $t=shift; $nx->add($t) });  #test unique add

    # READONLY
    begin sub { $ages[0][0] = 0; };
    ok $@, '/READONLY/';
    $@=undef;

    $nx->[0]{age}[3] = 3;
    $nx->[0]{'ok'} = 1;  #should allow writes
    $nx->add($nx->[0]);  #re-add is ok

#    ok(readonly($nx->[0]{age}));  not yet

    eval { $nx->[0]{age}[0] = 3; };
    ok $@, '/READONLY/';

    # cursors
    my $c = $ax->new_cursor;
#    ok(! $c->deleted);
#    ok($c->get_database->get_id eq $db->get_id);
    ok($c->focus() == $ax) or warn $c->focus;
#    ObjStore::debug qw(assign);
    ok $c->seek($ax->[0]{age}[0], $ax->[0]{age}[1]);
    {
	local $SIG{__WARN__} = sub {};
	ok(! $c->seek());
    }
    ok(! $c->seek(4));
    $c->step(-1);
    ok join('', $c->keys()), '2';
    my $at = $c->at;
    ok $at->{age}->[0], 2;
    ok $at->{age}->[1], 7;
    $c->moveto($c->pos);
    ok $c->at == $at;

    # readonly flags again
    my $decoy = $ax->add(new Toy($j, {name => 'Decoy',
				      age => bless [1,3], 'Toy::AgeGrp'}));
    ok $decoy->{name}, 'Decoy';
    $ax->remove($ax->[1]); #will seek to [0] first
    $ax->CLEAR();
    ok(!defined $ax->[0]);

    begin sub { $nx->[0]{age}[0] = 3; };
    ok $@, '/READONLY/';

    $nx->map(sub { my $r = shift; ok(0) if $ax->add($r) != $r; });
    ok(1);

    begin sub {$nx->add(bless {name=>'Goldilocks'}, 'Toy'); };
    ok $@, '/Goldilocks/';

    $nx->remove($nx->[0]); #hit coverage case
}

# Here are some packages that are used in the tests!

package Toy;
use base 'ObjStore::HV';

package Toy::AgeGrp;
use base 'ObjStore::AV';

1;
