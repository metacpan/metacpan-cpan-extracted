#-- test suite

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

my $debug;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use Time::HiRes;

use TM;
use TM::Literal;

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
                          ( $d < $max_d ? ( map { _mk_taxo ($root . $_, $d+1, $max_d, $max_c, $max_i) } ( 0 .. ($debug ||rand($max_c)))) : () ), # make concepts
                          (                 map { "i$root$_" }                                          ( 0 .. ($debug ||rand($max_i)))       )  # make kids
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
	    $tm->assert (Assertion->new (type => 'isa',            roles => [ 'class', 'instance' ],      players => [ $root, $ch ]));
	    $tm->assert (Assertion->new (type => 'name',       kind=> TM->NAME, roles => [ 'thing', 'value' ], players => [ $ch, new TM::Literal ($ch."_name") ]));
	    $tm->assert (Assertion->new (type => 'occurrence', kind=> TM->OCC,  roles => [ 'thing', 'value' ], players => [ $ch, new TM::Literal ($ch."_occ") ]));
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
		ok ($tm->is_subclass ($tm->tids ($ch, $root)), "$ch (indirect) subclass of $root");
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

}


sub _verify_chars {
    my $tm = shift;
    my $t  = shift;
    foreach ($tm->tids (_flatten_tree ($t))) {
	my @as = $tm->match_forall (char => 1, topic => $_);
	if ( /i\d+/ ) { # an instance got a name and an occurrence
	    die "char for $_: name and occurrence" unless scalar @as == 2;
	} else { # a class only a name
	    die "char for $_: only name" unless scalar @as == 1;
	}
    }
    ok (1, 'chars');
}

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

#== TESTS =====================================================================

use constant DONE => 1;

use TM;

# testing attachment actually

require_ok( 'TM::Index::Match' );

eval {
    my $idx = new TM::Index::Match (42);
}; like ($@, qr/parameter must be an instance/, _chomp ($@));

if (DONE) {
    my $tm = new TM;
    {
	my $idx  = new TM::Index::Match ($tm);
	$idx->detach;
    }
    ok (! defined $tm->{indices}, 'first indexed autoremoved');
    {
	my $idx2 = new TM::Index::Match ($tm);
	ok (1, 'second index implanted');
    }
    {
	my $tm = new TM;
	my $idx  = new TM::Index::Match ($tm);
	my $idx2 = new TM::Index::Match ($tm);
	is (@{ $tm->{indices} }, 2, 'double trouble');
    }
};

my @optimized_keys; # will be determined next

#$debug = 2; # pins down somewhat the tree structure

if (DONE) { # lazy index, built by use, functional test
    my $taxo = mk_taxo (3, 2, 3);
#warn Dumper $taxo;

    my $tm = new TM;
    implant ($tm, $taxo);
#warn Dumper $tm;

    my $idx = new TM::Index::Match ($tm);
    verify ($tm, $taxo, 0); # non-silent mode

    my $stats = $idx->statistics;
    @optimized_keys = @{ $stats->{proposed_keys} };
}

$debug = 2; # pins down somewhat the tree structure

if (DONE) { # lazy index, built by use
    my $taxo = mk_taxo (4, 3, 3);
#warn Dumper $taxo;

    my $tm = new TM;
    implant ($tm, $taxo);
#warn Dumper $tm;

    my $idx = new TM::Index::Match ($tm);

#    warn "\n# verifying first run, testing speed....";

    my $start = Time::HiRes::time;
    verify ($tm, $taxo, 1);
    my $unindexed = (Time::HiRes::time - $start);

#    warn Dumper $idx->{cache};

#    warn "# verifying second run, testing speed....";
    $start = Time::HiRes::time;
    verify ($tm, $taxo, 1);
    my $cached = (Time::HiRes::time - $start);
    ok ($cached < $unindexed / 2, "measurable speedup with lazy index ? ($cached < $unindexed, ".(sprintf "%.2f", $unindexed/$cached).")");

#    warn "# ====== total time =============== ".(Time::HiRes::time - $start);
#warn Dumper $idx->statistics;
    my $stats = $idx->statistics;
    @optimized_keys = @{ $stats->{proposed_keys} };
}

#warn Dumper \  @optimized_keys; exit;

if (DONE) { # prepopulated
    my $taxo = mk_taxo (2, 1, 1);
    my $tm = new TM;
    implant ($tm, $taxo);

    my $idx = new TM::Index::Match ($tm);

    my $start = Time::HiRes::time;
#    warn "\n# verifying first run, should be medium fast";
    verify ($tm, $taxo, 1) for 0..4;
    my $unindexed = (Time::HiRes::time - $start);

    $idx->detach;

    $idx = new TM::Index::Match ($tm, closed => 1);
#    warn "# prepopulating, takes time";
    $idx->discard and $idx->populate (@optimized_keys);
#    warn Dumper $idx->{cache}; exit;

    $start = Time::HiRes::time;
#    warn "# verifying second run, should be faster";
#warn Dumper $taxo;
    verify ($tm, $taxo, 1) for 0..4;

    my $indexed = (Time::HiRes::time - $start);
    ok (1, "measurable speedup with eager (populated) index ?? ($indexed < $unindexed, ".(sprintf "%.2f", $unindexed/$indexed).")");
#  TODO: {
#      local $TODO = "systematic speed test";
#      ok ($indexed < $unindexed, "measurable speedup with eager (populated) index ($indexed < $unindexed)");
#  }
}

if (DONE) {
    require_ok( 'TM::Index::Characteristics' );

    my $taxo = mk_taxo (4, 4, 4);
#warn Dumper $taxo;
    my $tm = new TM;
    implant ($tm, $taxo);

    my $start = Time::HiRes::time;
    _verify_chars ($tm, $taxo) for 0..4;
    my $unindexed = (Time::HiRes::time - $start);

    my $idx = new TM::Index::Characteristics ($tm, closed => 1);

#    warn Dumper $idx->{cache}; exit;
    $start = Time::HiRes::time;
    _verify_chars ($tm, $taxo) for 0..4;
    my $indexed = (Time::HiRes::time - $start);

    ok ($indexed < $unindexed / 2, "measurable speedup with eager char index ($indexed < $unindexed)");

}

require_ok ( 'TM::Index::Reified');


if (DONE) {
    require_ok ( 'TM::Index::Taxonomy');

    my $taxo = mk_taxo (4, 4, 4);
#warn Dumper $taxo;
    my $tm = new TM;
    implant ($tm, $taxo);

    my $start = Time::HiRes::time;
    verify ($tm, $taxo, 1) for 0..4;
    my $unindexed = (Time::HiRes::time - $start);

    my $idx = new TM::Index::Taxonomy ($tm, closed => 1);

#    use Data::Dumper;
#    warn Dumper $idx->{cache}; exit;
#    warn  Dumper  $idx->{cache}->{'superclass.type:1.tm://nirvana/C0'};

#    warn  Dumper [
#	map { $tm->{assertions}->{$_} }
#@{   $idx->{cache}->{'superclass.type:1.tm://nirvana/C0'} } ];

    $start = Time::HiRes::time;
    verify ($tm, $taxo, 1) for 0..4;
    my $indexed = (Time::HiRes::time - $start);

    ok ($indexed < $unindexed / 2, "measurable speedup with eager taxo index ($indexed < $unindexed)");
}



#-- persistent indices

my @tmp;

sub _mktmps {
    foreach (qw(0)) {
	use IO::File;
	use POSIX qw(tmpnam);
	do { $tmp[$_] = tmpnam() ;  } until IO::File->new ($tmp[$_], O_RDWR|O_CREAT|O_EXCL);
    }
}

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
	verify ($tm, $taxo, 1) for 0..4;
	$unindexed = (Time::HiRes::time - $start);

#	warn "# ====== total time =============== ".(Time::HiRes::time - $start);

#	warn "# verifying second run, should be faster";
	$start = Time::HiRes::time;
	verify ($tm, $taxo, 1) for 0..4;
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
	verify ($tm, $taxo, 1) for 0..4;
	my $indexed = (Time::HiRes::time - $start);
	ok ($indexed < $unindexed, "measurable speedup with persistent index ($indexed < $unindexed)");

#	warn "# ====== total time =============== ".(Time::HiRes::time - $start);
	
	untie %cache;
    }

}


__END__

