use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Normal sub usage', '',  );
sub name1 {
}
sub name2 {
}
RAW
sub name1 {
}

sub name2 {
}
TIDIED

done_testing;
