my ($tmp);
use IO::File;
use POSIX qw(tmpnam);
do { $tmp = tmpnam() ;  } until IO::File->new ($tmp, O_RDWR|O_CREAT|O_EXCL);

END { unlink ($tmp) || warn "cannot unlink tmp file '$tmp'"; }

{
    use TM::Materialized::MLDBM;
    my $tm = new TM::Materialized::MLDBM (file => $tmp);
    
    $tm->assert (Assertion->new (
				 type => 'isa',
				 roles => [ 'instance', 'class' ],
				 players => [ 'sacklpicka', 'cat' ]));
    $tm->sync_out;
}

utime time + 1, time + 1, $tmp; # lets pretend that the file has been changed

{
    use TM::Materialized::MLDBM;
    my $tm = new TM::Materialized::MLDBM (file => $tmp);

    use Data::Dumper;
    warn Dumper [ $tm->tids ('cat') ]; # nothing there

    $tm->sync_in;
    warn Dumper [ $tm->instances ($tm->tids ('cat')) ]; # sacklpicka is back!
}

