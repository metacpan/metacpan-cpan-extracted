use Smart::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $count = 0;

LABEL:

for (my $count=0;$count < 100;$count++) {    ### C-like for loop:===|   done
    # nothing
}

like $STDERR, qr/C-like for loop:|                   done\r/
                                            => 'First iteration';

like $STDERR, qr/C-like for loop:=|                  done\r/ 
                                            => 'Second iteration';
