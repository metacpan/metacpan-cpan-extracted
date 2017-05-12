use Smart::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $count = 0;

LABEL:

while ($count < 100) {    ### Simple while loop:===|   done
    $count++;
}

like $STDERR, qr/Simple while loop:|                 done\r/
                                            => 'First iteration';

like $STDERR, qr/Simple while loop:=|                done\r/ 
                                            => 'Second iteration';
