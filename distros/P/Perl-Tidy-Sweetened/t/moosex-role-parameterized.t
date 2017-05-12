use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Normal sub usage', '',  );
role {
    method _test => sub { };
};
RAW
role {
    method _test => sub { };
};
TIDIED

done_testing;
