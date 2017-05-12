use 5.014;
*STDOUT->autoflush(1);

use Running::Commentary;
run_with -nocolour;

run 'echo "1..5"';

run 'echo "ok 1 - can simulate system"';

run '# Trying echo'
 => 'echo "ok 2 - can simulate system with desc"';

run '# Trying slow system'
 => 'sleep 2'
    and say 'ok 3 - can simulate failed system with unknown command'
     or say 'not ok 3 - can simulate failed system with unknown command';

run '# Trying slow echo' 
 => 'sleep 2; echo "ok 4 - can simulate slow system with desc"';

run '# Trying unknown command'
 => 'djsksdjalaksjdjkds'
    and say 'not ok 5 - can simulate failed system with unknown command'
     or say 'ok 5 - can simulate failed system with unknown command';
