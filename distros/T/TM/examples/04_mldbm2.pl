my ($tmp);
use IO::File;
use POSIX qw(tmpnam);
do { $tmp = tmpnam() ;  } until IO::File->new ($tmp, O_RDWR|O_CREAT|O_EXCL);

END { unlink ($tmp) || warn "cannot unlink tmp file '$tmp'"; }

use Data::Dumper;

# look ma, no hands!

warn "file $tmp";

unlink $tmp;

{
    use TM::Materialized::MLDBM2;
    my $tm = new TM::Materialized::MLDBM2 (file => $tmp);

    $tm->assert (Assertion->new (
				 type => 'owns',
				 roles => [ 'owner', 'object' ],
				 players => [ 'rho', 'sacklpicka' ]));

    warn Dumper [ $tm->tids ('rho') ];
}

sleep 3;

{
    use TM::Materialized::MLDBM2;
    my $tm = new TM::Materialized::MLDBM2 (file => $tmp);

    warn Dumper [ $tm->tids ('rho') ];
}


