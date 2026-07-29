# Proc-ProcessTable-InfoString

Prints a handy info string representing
state and various flags as well as showing
the wait channel in use if there is one.

```
use Proc::ProcessTable::InfoString;
use Proc::ProcessTable;

my $is = Proc::ProcessTable::InfoString->new;

my $p = Proc::ProcessTable->new( 'cache_ttys' => 1 );
my $pt = $p->table;

foreach my $proc ( @{ $pt } ){
    print $proc->pid.' '.$is->info( $proc )."\n";
}
```

results in output like...

```
57255 Rs+
57254 Ss+ zio->io_
57253 Ss+ wait
57252 Ss+ zcw->zcw
57226 Ss+ zio->io_
57224 Ss+ wait
57223 Rs+
57222 Ss+ wait
56824 Ss+ zio->io_
55632 Ss+ zcw->zcw
55631 Ss+ wait
```

# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install
