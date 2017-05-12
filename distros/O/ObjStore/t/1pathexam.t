# path to -*-perl-*-
use Test; plan tests => 15;
use ObjStore;
require ObjStore::PathExam::Path;

my $rand=0;
sub get1($) {
    use integer;
    my $l = shift;
    $rand = ($rand+1) % $l
}

my @C = ('a'..'z');
sub dolevel {
    my ($level, $obj) = @_;
    $obj ||= ObjStore::AV->new('transient');
    for my $at (0..8) {
	if ($level and $at == 0) {
	    my $below = dolevel($level-1, ObjStore::AV->new($obj));
	    $obj->STORE($at, $below);
	} elsif ($level and $at == 1) {
	    $obj->STORE($at, dolevel($level-1, ObjStore::HV->new($obj)));
	} else {
	    $obj->STORE($at, $C[get1 @C].$C[get1 @C]);
	}
    }
    $obj;
}
my $junk = dolevel(8);

my $tests=q[
			/invalid/
4			4=fg		fg
9			9
1/4			1/4=rs		rs
2, 3, 4,5	2=bc, 3=de, 4=fg, 5=hi	bcdefghi
0/1/2, 1/5		0/1/2=za, 1/5=tu	zatu
0/1/2, 3/5,5		0/1/2=za, 3/5, 5	za
1/bar/snark		1/bar/snark
2,2,2,2,2		/Path has/
0/0/0/0/0/0/0/0/0	/too long/
];

#ObjStore::debug('txn');
my $exam = ObjStore::PathExam->new();

for my $test (split /\n/, $tests) {
    next if !$test;
    my ($path, $expect, $keys) = split /\t+/, $test;
#    begin sub {
    eval {
#	warn scalar @ObjStore::Transaction::Stack;
	my $p = ObjStore::PathExam::Path->new('transient', $path);
	$exam->load_path($p);
	$exam->load_target($junk);
    };
    ok $@? $@ : $exam->stringify(), $expect, $path;
    if (!$@) {
	my $kx = join '', $exam->keys();
	ok $kx, $keys if $kx;
    }
}
