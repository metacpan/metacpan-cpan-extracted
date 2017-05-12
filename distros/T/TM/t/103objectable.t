package Storage3;

require Tie::Hash;
our @ISA = 'Tie::StdHash';

sub TIEHASH  {
    my $storage = bless {}, shift;
    $storage
}
sub STORE    {
    return undef if $_[2] eq 'whatever';
    $_[0]{$_[1]} = $_[2]
}

1;

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use TM;
use Test::More qw(no_plan);


#== TESTS =====================================================================

use constant DONE => 0;

use TM;
use TM::Literal

require_ok( 'TM::ObjectAble' );

if (1||DONE) {
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (baseuri => 'tm:',
					  inline => qq{
xxx (yyy)

zzz (yyy)

aaa (bbb)

})->sync_in;

    use Class::Trait;
    Class::Trait->apply ($tm, "TM::ObjectAble");

    ok (scalar @{ $tm->storages } == 0, 'have no store');

    use Test::Exception;

    throws_ok {
	$tm->objectify ('tm:xxx', "whatever");
    } qr/no storage/, 'undefined storage';

    my %store1; # a simple hash
    push @{ $tm->storages }, \%store1;
    ok (scalar @{ $tm->storages } == 1, 'have one store');

    my %store2; # a simple hash
    push @{ $tm->storages }, \%store2;
    ok (scalar @{ $tm->storages } == 2, 'have two stores');

    $tm->objectify ('tm:xxx', "whatever");
    is ($store1{'tm:xxx'}, 'whatever', 'first store hit');
    is ($store2{'tm:xxx'}, undef,      'second store nohit');

    my %store0;
    tie %store0, 'Storage3';
    unshift @{ $tm->storages }, \%store0;
    $tm->objectify ('tm:yyy', "whatever");
    is ($store0{'tm:yyy'}, undef,      '0-store nohit');
    is ($store1{'tm:yyy'}, 'whatever', 'first store hit');
    is ($store2{'tm:yyy'}, undef,      'second store hit');

    $tm->objectify ('tm:zzz', "whoever");
    is ($store0{'tm:zzz'}, 'whoever',  '0-store hit');
    is ($store1{'tm:zzz'}, undef,      'first store nohit');
    is ($store2{'tm:zzz'}, undef,      'second store nohit');
#    warn Dumper \%store0;

    my @os = $tm->object ('tm:xxx', 'tm:zzz', 'tm:uuu', 'tm:yyy');
#    warn Dumper \@os;
    ok (eq_array (\@os,
	[
	 'whatever',
	 'whoever',
	 undef,
	 'whatever',
	]), 'rendering objects');

    throws_ok {
	$tm->deobjectify ('tm:uuu');
    } qr/no storage/, 'undefined storage for deleting';

    $tm->deobjectify ('tm:zzz');
#    warn Dumper \%store0;
    is ($store0{'tm:zzz'}, undef,      '0-store nohit');
    is ($store1{'tm:zzz'}, undef,      'first store nohit');
    is ($store2{'tm:zzz'}, undef,      'second store nohit');

    $tm->deobjectify ('tm:xxx');
#    warn Dumper \%store0;
    is ($store0{'tm:xxx'}, undef,      '0-store nohit');
    is ($store1{'tm:xxx'}, undef,      'first store nohit');
    is ($store2{'tm:xxx'}, undef,      'second store nohit');

}


__END__

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
    ok ($unindexed / $cached > 2, "measurable speedup (taxo) with lazy index ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");

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
    ok ($unindexed / $indexed > 2, "measurable speedup (taxo) with eager index ? ($indexed < $unindexed, ".(sprintf "%.2f", $unindexed/$indexed).")");
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
    ok ($unindexed / $cached > 2, "measurable speedup (char) with lazy index ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");

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

