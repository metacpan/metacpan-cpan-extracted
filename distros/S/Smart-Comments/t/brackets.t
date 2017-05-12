use Smart::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $count = 0;
for my $ivar (1..20) {    ### Simple for loop:[][]   done
    $count++;
    is $ivar, $count                        => "Iteration $count";
}

like $STDERR, qr/Simple for loop:\[              done\r/
                                            => 'First iteration';

like $STDERR, qr/Simple for loop:\[\]             done\r/
                                            => 'Second iteration';

like $STDERR, qr/Simple for loop:\[\]\[            done\r/
                                            => 'Thiird iteration';
