package MemoryCheck;

use Promise::ES6 ();

use Data::Dumper;

my $MASTER_PID = $$;

BEGIN {
    my $destroy_cr = Promise::ES6->can('DESTROY');

    no warnings 'redefine';
    *Promise::ES6::DESTROY = sub {
        if ($$ == $MASTER_PID && 'DESTRUCT' eq ${^GLOBAL_PHASE}) {
            print STDERR "XXX XXX XXX --- PID $$: DESTROYing Promise::ES6 at DESTRUCT time!$/";
            print STDERR Dumper(@_);

            exit 1;
        }

        return $destroy_cr->(@_);
    };
}

1;
