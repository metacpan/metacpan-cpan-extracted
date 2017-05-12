use 5.014;
*STDOUT->autoflush(1);

use Running::Commentary;
run_with -nocolour;

run sub { say "1..5" };

run sub { say "ok 1 - can simulate system" };

run '# Trying echo'
 => sub { say "\nok 2 - can simulate system with desc" };

run '# Trying slow system'
 => sub { sleep 2 }
    and say     'ok 3 - can simulate failed system with unknown command'
     or say 'not ok 3 - can simulate failed system with unknown command';

run '# Trying slow echo'
 => sub { sleep 2; say "\nok 4 - can simulate slow system with desc" };

run '# Trying to fail'
 => sub { die 'I cannot go on' }
    and say 'not ok 5 - can simulate failed system with unknown command'
     or say     'ok 5 - can simulate failed system with unknown command';
