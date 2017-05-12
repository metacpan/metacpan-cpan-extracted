use Smart::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $count = 0;

LABEL:

for (1..5) {    ### Simple for loop:===[%]   done (%)
    # nothing
}

like $STDERR, qr/Simple for loop:\[0%\]      done \(0%\)/
                                            => 'First iteration';

like $STDERR, qr/Simple for loop:\[25%\]    done \(25%\)/ 
                                            => 'Second iteration';

like $STDERR, qr/Simple for loop:\[50%\]    done \(50%\)/ 
                                            => 'Third iteration';
  
like $STDERR, qr/Simple for loop:=\[75%\]   done \(75%\)/ 
                                            => 'Fourth iteration';
