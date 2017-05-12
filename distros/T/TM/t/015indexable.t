use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use Time::HiRes;

use TM;

use Test::More qw(no_plan);



my $debug;


sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}


sub mk_taxo {
    my $max_d = shift;
    my $max_c = shift;
    my $max_i = shift;

    return _mk_taxo ('0', 0, $max_d, $max_c, $max_i);

sub _mk_taxo {
    my $root  = shift;
    my $d     = shift;
    my $max_d = shift;
    my $max_c = shift;
    my $max_i = shift;

    return { "C$root" => [
                          ( $d < $max_d ? ( map { _mk_taxo ($root . $_, $d+1, $max_d, $max_c, $max_i) } ( 0 .. ($debug ||1+rand($max_c)))) : () ), # make concepts
                          (                 map { "i$root$_" }                                          ( 0 .. ($debug ||2+rand($max_i)))       )  # make kids
                          ] };
}
}

sub implant {
    my $tm = shift;
    my $ta = shift;

    my ($root) = keys %$ta;

    $tm->assert (Assertion->new (type => 'name',       kind=> TM->NAME, roles => [ 'thing', 'value' ], players => [ $root, new TM::Literal ($root."_name") ]));

    foreach my $ch (@{$ta->{$root}}) {
	if (ref ($ch)) { # this is a subtree
	    $tm->assert (Assertion->new (type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ (keys %$ch)[0], $root ]));
	    implant ($tm, $ch);
	} else { # this is just an instance
	    $tm->assert (Assertion->new (type => 'isa',                         roles => [ 'class', 'instance' ],      players => [ $root, $ch ]));
	    $tm->assert (Assertion->new (type => 'name',       kind=> TM->NAME, roles => [ 'thing', 'value' ], players => [ $ch, new TM::Literal ($ch."_name") ]));
	    my ($a) = $tm->assert (Assertion->new (type => 'occurrence', kind=> TM->OCC,  roles => [ 'thing', 'value' ], players => [ $ch, new TM::Literal ($ch."_occ") ]));
	    $tm->internalize (undef, $a->[TM->LID]);
	}
    }
}

sub verify {
    my $tm = shift;
    my $ta = shift;
    my $si = shift; # silencio?

    my ($root) = keys %$ta;

    foreach my $ch (_flatten_tree ($ta)) {
#warn "for $root finding child $ch";
	if ($ch =~ /C/) { # this is a subtree node
	    if ($si) {
		die "fail $ch (indirect) subclass of $root" unless $tm->is_subclass ($tm->tids ($ch, $root));
	    } else {
#warn "$ch is subclass $root ?";
		ok ($tm->is_subclass   ($tm->tids ($ch, $root)),                             "$ch (indirect) subclass of $root");
#		ok ((grep { $_ eq $tm->tids ($root) } $tm->superclassesT ($tm->tids ($ch))), 'superclassesT root');
	    }
	} else { # this is just an instance
	    if ($si) {
		die "fail $ch (indirect) instance of $root" unless $tm->is_a ($tm->tids ($ch, $root));
	    } else {
#warn "$ch isa $root ?";
		ok ($tm->is_a ($tm->tids ($ch, $root)),        "$ch (indirect) instance of $root");
	    }
	}
    }

    foreach my $ch (@{$ta->{$root}}) {
	if (ref ($ch)) { # this is a subtree
	    verify ($tm, $ch, $si);
	}
    }
sub _flatten_tree {
    my $ta     = shift;
    my ($root) = keys %$ta;
    my @kids;

    push @kids, $root;
    foreach my $ch (@{$ta->{$root}}) {
	push @kids, ref ($ch) ? _flatten_tree ($ch) : $ch;
    }
    return @kids;
}

#ok (1, 'survived taxo verify');

}



sub _verify_chars {
    my $tm = shift;
    my $t  = shift;
    my $si = shift; # silencio?

    foreach ($tm->tids (_flatten_tree ($t))) {
	my @as = $tm->match_forall (char => 1, topic => $_);
	if ( /i\d+/ ) { # an instance got a name and an occurrence
	    if ($si) {
		die "char for $_: name and occurrence" unless scalar @as == 2;
	    } else {
		is ((scalar @as), 2, "$_");
	    }
	} else { # a class only a name
	    if ($si) {
		die "char for $_: only name" unless scalar @as == 1;
	    } else {
		is ((scalar @as), 1, "$_");
	    }
	}
    }
#    ok (1, 'chars');
}

sub _verify_reif {
    my $tm = shift;
    my $as = shift;
    my $si = shift; # silencio?

    foreach my $a (@$as) {
	my ($tid) = $tm->is_reified ($a);
	if ($si) {
#	    die "reification failed" unless $tm->reifies ($tid)->[TM->LID] eq $a->[TM->LID];
	} else {
	    is ($tm->reifies ($tid)->[TM->LID], $a->[TM->LID], "reification $tid");
	}
    }
    return;

#     my ($root) = keys %$ta;

#     foreach my $ch (@{$ta->{$root}}) {
# 	if (ref ($ch)) { # this is a subtree
# 	    _verify_reif ($tm, $ch, $si);
# 	} else { # this is just an instance
# 	    my ($a) = $tm->match_forall (char => 1, type => 'occurrence', topic => $tm->tids ($ch));
# #warn Dumper $a;
# #	    my ($a) = $tm->assert (Assertion->new (type => 'occurrence', kind=> TM->OCC,  roles => [ 'thing', 'value' ], players => [ $ch, new TM::Literal ($ch."_occ") ]));
# 	    my ($tid) = $tm->is_reified ($a);
# #warn $a->[TM->LID], $tid;
# #warn Dumper $tm->toplets ($tid);
# #warn Dumper $tm->reifies ($tid);
# 	    next;
# 	    if ($si) {
# 		die "reification failed" unless $tm->reifies ($tid)->[TM->LID] eq $a->[TM->LID];
# 	    } else {
# 		is ($tm->reifies ($tid)->[TM->LID], $a->[TM->LID], "reification $tid");
# 	    }
# 	}
#     }
}

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

#== TESTS =====================================================================

use constant DONE => 1;
use constant INTENSITY => 3; # 4 for real testing

use TM;
use TM::Literal

require_ok( 'TM::IndexAble' );


if (DONE) {
    my $tm = new TM;
    use Class::Trait;
    Class::Trait->apply ($tm, "TM::IndexAble");
    ok ($tm->does ('TM::IndexAble'), 'index trait');
    can_ok ($tm, 'index', 'deindex');
};


#$debug = 3; # pins down somewhat the tree structure

if (DONE) { # lazy index, built by use, purely functional test
    my $taxo = mk_taxo (3, 2, 3);
#    my $taxo = mk_taxo (1, 1, 1);

    my $tm = new TM;
    implant ($tm, $taxo);

    verify ($tm, $taxo, 0);  # functional test without cache

    Class::Trait->apply ($tm, "TM::IndexAble");
    my %s = $tm->index ({ axis => 'taxo' });
#    warn Dumper \%s;

    ok (eq_set ([ qw(superclass.type class.type instance.type subclass.type) ],
                [ keys %s ]), 'axes');

    map { ok ($_->{hits}     == 0, 'stat hits') 
       && ok ($_->{requests} == 0, 'stat requests') }
    values %s;

    verify ($tm, $taxo, 0); # non-silent mode
    verify ($tm, $taxo, 0); # non-silent mode, here everything must be already cached

    %s = $tm->index;
#warn Dumper \%s; exit;

    ok ($s{'instance.type'}->{hits}     > 0, 'instance.type hits');
    ok ($s{'instance.type'}->{requests} > 0, 'instance.type requests');

    ok ($s{'subclass.type'}->{hits}     > 0, 'subclass.type hits');
    ok ($s{'subclass.type'}->{requests} > 0, 'subclass.type requests');
#    warn Dumper \%s;
}

sub _speedo {
    my $tm = shift;
    my $taxo = shift;

#    diag ('speed testing for taxonomy ...');
    my $start = Time::HiRes::time;
    verify ($tm, $taxo, 1) for 1..5;  # speed test
#    diag ('... done');
    return (Time::HiRes::time - $start);
}

#-- taxo axes

if (DONE) {                          # lazy index, built by use
    my $taxo = mk_taxo (INTENSITY, 2, 2);

    my $tm = new TM;
    implant ($tm, $taxo);

    my $unindexed = _speedo ($tm, $taxo);

    Class::Trait->apply ($tm, "TM::IndexAble");
    $tm->index ({ axis => 'taxo', closed => 0});  # make a cache on that axes

    my $cached = _speedo ($tm, $taxo);
    diag ($unindexed / $cached > 2, "measurable speedup (taxo) with lazy index ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");

#    warn Dumper $tm->index;

}

if (DONE) { # eager index
    my $taxo = mk_taxo (INTENSITY, 3, 3);

    my $tm = new TM;
    implant ($tm, $taxo);

    my $unindexed = _speedo ($tm, $taxo);

    Class::Trait->apply ($tm, "TM::IndexAble");
    $tm->index ({ axis => 'taxo', closed => 1});

    my $indexed = _speedo ($tm, $taxo);
    diag ($unindexed / $indexed > 2, "measurable speedup (taxo) with eager index ? ($indexed < $unindexed, ".(sprintf "%.2f", $unindexed/$indexed).")");
}

#-- char axes

sub _speedo_char {
    my $tm = shift;
    my $taxo = shift;

    my $start = Time::HiRes::time;
    (_verify_chars ($tm, $taxo, 1) ) for 1..5;
#    (_verify_chars ($tm, $taxo, 1)  || diag ('... run')) for 1..5;
    return (Time::HiRes::time - $start);
}

if (DONE) { # lazy first
    my $taxo = mk_taxo (INTENSITY, 3, 3);

    my $tm = new TM;
    implant ($tm, $taxo);

    _verify_chars ($tm, $taxo, 0);
    my $unindexed = _speedo_char ($tm, $taxo);

    Class::Trait->apply ($tm, "TM::IndexAble");
    $tm->index ({ axis => 'char', closed => 0});  # make a cache on that axes

    my $cached = _speedo_char ($tm, $taxo);
    diag ($unindexed / $cached > 2, "measurable speedup (char) with lazy index ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");

#    warn Dumper $tm->index;
}

if (DONE) { # eager
    my $taxo = mk_taxo (INTENSITY, 3, 3);

    my $tm = new TM;
    implant ($tm, $taxo);

    _verify_chars ($tm, $taxo, 0);
    my $unindexed = _speedo_char ($tm, $taxo);

    Class::Trait->apply ($tm, "TM::IndexAble");
    $tm->index ({ axis => 'char', closed => 1 });  # make a cache on that axes

    my $cached = _speedo_char ($tm, $taxo);
    ok ($unindexed / $cached > 2, "measurable speedup (char) with lazy index ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");

#    warn Dumper $tm->index;
}

#-- reification axes

sub _speedo_reif {
    my $tm = shift;
    my $taxo = shift;

    my $start = Time::HiRes::time;
    (_verify_reif ($tm, $taxo, 1)) for 1..5;
#    (_verify_reif ($tm, $taxo, 1) || diag ('... run')) for 1..5;
    return (Time::HiRes::time - $start);
}

if (DONE) {
    my $taxo = mk_taxo (INTENSITY, 3, 3);
    my $tm = new TM;
    implant ($tm, $taxo);

    my @as = $tm->match_forall (char => 1, type => 'occurrence');  # need to have this outside the speed test
    _verify_reif ($tm, \@as, 0);
    my $unindexed = _speedo_reif ($tm, \@as);

    Class::Trait->apply ($tm, "TM::IndexAble");

    $tm->index ({ axis => 'reify', closed => 0});  # make a cache on that axes
    _verify_reif ($tm, \@as, 0);

    my $cached = _speedo_reif ($tm, \@as);
    ok ($unindexed / $cached > 2, "measurable speedup (reify) with lazy index ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");
}

if (DONE) {
    my $taxo = mk_taxo (INTENSITY, 3, 3);
    my $tm = new TM;
    implant ($tm, $taxo);

    my @as = $tm->match_forall (char => 1, type => 'occurrence');  # need to have this outside the speed test
    my $unindexed = _speedo_reif ($tm, \@as);

    Class::Trait->apply ($tm, "TM::IndexAble");
    $tm->index ({ axis => 'reify', closed => 1});

    my $cached = _speedo_reif ($tm, \@as);
    ok ($unindexed / $cached > 2, "measurable speedup (reify) with lazy index ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");

}


sub _mktmp {
    my $tmp;

    use IO::File;
    use POSIX qw(tmpnam);
    do { $tmp = tmpnam() ;  } until IO::File->new ($tmp, O_RDWR|O_CREAT|O_EXCL);
    return $tmp;
}

if (DONE) { # does it work together with a MLDBM backed map?
    my $tmp = _mktmp;
    my $taxo = mk_taxo (INTENSITY, 2, 3);

    use TM::ResourceAble::MLDBM;
    my $tm = new TM::ResourceAble::MLDBM (file => $tmp);
#    diag ('populate map...');
    implant ($tm, $taxo);
#    diag ('... done');

    my @as = $tm->match_forall (char => 1, type => 'occurrence');  # need to have this outside the speed test
    my $unindexed = _speedo_reif ($tm, \@as);

    Class::Trait->apply ($tm, "TM::IndexAble");
    $tm->index ({ axis => 'reify', closed => 0});  # make a cache on that axes

    _verify_reif ($tm, \@as, 0);
#    warn Dumper $TM::IndexAble::index;exit;
    my %s = $tm->index; # let's see what we have

    my $reqs = $s{reify}->{requests};
    is ($s{reify}->{hits}, 0, 'open => no hits');

    my $cached = _speedo_reif ($tm, \@as);
    %s = $tm->index; # let's see what we have
    is ($s{reify}->{requests} - $s{reify}->{hits}, $reqs, 'open, but fully cached => hits');

    diag ($unindexed / $cached > 2, "no measurable speedup (reify) with lazy index + MLDBM ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");
    unlink <"$tmp*">;
}

if (DONE) { # MLDBM + detached
    my $tmp = _mktmp;
    my $taxo = mk_taxo (INTENSITY, 2, 3);

    use TM::ResourceAble::MLDBM;
    my $tm = new TM::ResourceAble::MLDBM (file => $tmp);
#    diag ('populate map...');
    implant ($tm, $taxo);
#    diag ('... done');

    my @as = $tm->match_forall (char => 1, type => 'occurrence');  # need to have this outside the speed test
    my $unindexed = _speedo_reif ($tm, \@as);

    Class::Trait->apply ($tm, "TM::IndexAble");
    $tm->index ({ axis => 'reify', closed => 0, detached => {} });

    _verify_reif ($tm, \@as, 0);
    my %s = $tm->index; # let's see what we have
#warn " after one run ".Dumper \%s;

    my $reqs = $s{reify}->{requests};
    is ($s{reify}->{hits}, 0, 'open => no hits');

    my $cached = _speedo_reif ($tm, \@as);
    %s = $tm->index; # let's see what we have
#warn " after second run ".Dumper \%s;

    is ($s{reify}->{requests} - $s{reify}->{hits}, $reqs, 'open, but fully cached => hits');

    ok ($unindexed / $cached > 2, "measurable speedup (reify) with lazy,detached index + MLDBM ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");

    $tm->deindex ('reify');
    %s = $tm->index;
    ok (! $s{reify}, 'no more reification axis index');

    $tm->index ({ axis => 'reify', closed => 1, detached => {} });
#    warn Dumper $TM::IndexAble::cachesets{ $tm->{index}->{reify} }; exit;
       $cached = _speedo_reif ($tm, \@as);
    ok ($unindexed / $cached > 2, "measurable speedup (reify) with eager,detached index + MLDBM ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");

    %s = $tm->index; # let's see what we have
    is ($s{reify}->{requests}, $s{reify}->{hits}, 'closed & each exactly once => reqs == hits');

    $tm->deindex ('reify');
#    warn Dumper \%TM::IndexAble::cachesets;
    ok (! keys %TM::IndexAble::cachesets, 'no more detached' );
    %s = $tm->index;
    ok (! $s{reify}, 'no more reification axis index');

    unlink <"$tmp*">;
}

#sleep 60;
__END__




#-- persistent indices


_mktmps;
#warn Dumper \@tmp;

END { map { unlink <$_*> } @tmp; };

if (DONE) {
    use BerkeleyDB ;
    use MLDBM qw(BerkeleyDB::Hash) ;
    use Fcntl;

    my $taxo = mk_taxo (4, 3, 3);

    my $unindexed;

    {
	my %cache;
	tie %cache, 'MLDBM', -Filename => $tmp[0], -Flags    => DB_CREATE
	    or die ( "Cannot create DBM file '$tmp[0]: $!");

	my $tm   = new TM;
	implant ($tm, $taxo);

	my $idx = new TM::Index::Match ($tm, cache => \%cache);
    
#	warn "\n# verifying first run, should be medium fast";
	my $start = Time::HiRes::time;
	verify ($tm, $taxo, 1);
	$unindexed = (Time::HiRes::time - $start);

#	warn "# ====== total time =============== ".(Time::HiRes::time - $start);

#	warn "# verifying second run, should be faster";
	$start = Time::HiRes::time;
	verify ($tm, $taxo, 1);
	my $indexed = (Time::HiRes::time - $start);
	ok ($indexed < $unindexed, "measurable speedup with persistent index ($indexed < $unindexed)");

#	warn "# ====== total time =============== ".(Time::HiRes::time - $start);
	
	untie %cache;
    }

    {
	my %cache;
	tie %cache, 'MLDBM', -Filename => $tmp[0], -Flags => DB_CREATE
	    or die ( "Cannot open DBM file '$tmp[0]: $!");

#	warn Dumper \%cache; exit;

	my $tm   = new TM;
	implant ($tm, $taxo);

	my $idx = new TM::Index::Match ($tm, cache => \%cache);
    
#	warn "\n# re-verifying second run, should be as fast";
	my $start = Time::HiRes::time;
	verify ($tm, $taxo, 1);
	my $indexed = (Time::HiRes::time - $start);
	ok ($indexed < $unindexed, "measurable speedup with persistent index ($indexed < $unindexed)");

#	warn "# ====== total time =============== ".(Time::HiRes::time - $start);
	
	untie %cache;
    }

}


__END__

