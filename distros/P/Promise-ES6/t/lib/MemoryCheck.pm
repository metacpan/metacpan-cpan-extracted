package MemoryCheck;

use strict;
use warnings;

use Test::More;

use Promise::ES6 ();

use Data::Dumper;

my $MASTER_PID = $$;

my $has_devel_gd;

BEGIN {
    if ( $has_devel_gd = eval { require Devel::GlobalDestruction; 1 } ) {
        diag "Devel::GlobalDestruction is available and loaded.";
    }
    elsif (${^GLOBAL_PHASE}) {
        diag "Devel::GlobalDestruction isn’t available, but \${^GLOBAL_PHASE} exists.";
    }
    else {
        diag "XXX WARNING: Devel::GlobalDestruction isn’t available, and this perl ($^V) predates \${^GLOBAL_PHASE}. Thus, this test can’t detect memory leaks.";
    }

    my $destroy_cr = Promise::ES6->can('DESTROY');

    no warnings 'redefine';
    *Promise::ES6::DESTROY = sub {
        my ($self) = @_;

        my $warn_gd = ($$ == $MASTER_PID);

        $warn_gd &&= $has_devel_gd ? Devel::GlobalDestruction::in_global_destruction() : (${^GLOBAL_PHASE} && ('DESTRUCT' eq ${^GLOBAL_PHASE}));

        if ($warn_gd) {
            print STDERR "XXX XXX XXX --- PID $$: DESTROYing $self at DESTRUCT time!$/";
            print STDERR Dumper($self);

            # Avoid exit() so that we’ll see all possible problems.
            $? = 1;
        }

        return $destroy_cr->(@_);
    };
}

1;
