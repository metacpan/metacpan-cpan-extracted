use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;

use_ok ('TM::ResourceAble::BDB');

my ($tmp);
use IO::File;
use POSIX qw(tmpnam);
do { $tmp = tmpnam() ;  } until IO::File->new ($tmp, O_RDWR|O_CREAT|O_EXCL);

END { unlink ("${tmp}.main", "${tmp}.assertions", "${tmp}.toplets", $tmp ) || warn "cannot unlink tmp file '$tmp'"; }


use constant DONE => 1;

my $STATEMENTS = 100;

if (DONE) {
    my $bdb = new TM::ResourceAble::BDB (file => $tmp);

#warn Dumper $bdb;
#warn "tied at ".$bdb->{baseuri};
    ok ($bdb->baseuri, 'baseuri method');

    is ($bdb->url, "file:$tmp", 'url method');

    ok ($bdb->{mid2iid}->{isa},                                   'mid2iid direct access');
    ok ($bdb->{assertions}->{'97b634a43b47218b9970e86f61671ce9'}, 'assertions direct access');

    ok ((scalar $bdb->match_forall (nochar => 1)), 'match_forall over infrastructure');

    diag ('populating map ...');
    use TM::Literal;
    $bdb->assert (
	map { Assertion->new (kind => TM->NAME, type => 'name', scope => 'us', roles => [ 'thing', 'value' ], players => [ 'aaa', new TM::Literal ("AAA$_") ]) }
	   (1..$STATEMENTS)
	    );
    diag ('...done');

    ok ($bdb->{last_mod} > 0, 'last_mod');
}

my $ITERATIONS = 100;

my $lm;
if (DONE) { # DEPENDS on above!
    my $bdb2 = new TM::ResourceAble::BDB (file => $tmp);

    $lm = $bdb2->{last_mod};
    ok ($lm > 0, 'last_mod (revived)');

    if (0) {
	use Benchmark qw(:hireswallclock) ;
	timethis ($ITERATIONS, sub {
	    my @as = $bdb2->match_forall (char => 1, topic => 'tm://nirvana/aaa');
	    ok (@as == $STATEMENTS, 'found all inserted');
	    });
    } else {
	foreach (1..$ITERATIONS) {
	    my @as = $bdb2->match_forall (char => 1, topic => 'tm://nirvana/aaa');
	    ok (@as == $STATEMENTS, 'found all inserted');
	}
    }

    $bdb2->assert (
	map { Assertion->new (kind => TM->NAME, type => 'name', scope => 'us', roles => [ 'thing', 'value' ], players => [ 'bbb', new TM::Literal ("BBB$_") ]) }
	   (1..$STATEMENTS)
	    );

    use TM;
    my $tm = new TM;
    $tm->assert (
	map { Assertion->new (kind => TM->NAME, type => 'name', scope => 'us', roles => [ 'thing', 'value' ], players => [ 'ccc', new TM::Literal ("CCC$_") ]) }
	   (1..$STATEMENTS)
	    );
    $bdb2->add ($tm);
}

if (DONE) {
    my $bdb3 = new TM::ResourceAble::BDB (file => $tmp);

    ok ($lm < $bdb3->{last_mod}, 'last_mod (revived again)');

    my @as = $bdb3->match_forall (char => 1, topic => 'tm://nirvana/bbb');
    ok (@as == $STATEMENTS, 'found all inserted');

       @as = $bdb3->match_forall (char => 1, topic => 'tm://nirvana/ccc');
    ok (@as == $STATEMENTS, 'found all inserted');
}

__END__

