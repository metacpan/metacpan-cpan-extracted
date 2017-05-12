use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'RT#102815 - ignores -sbl', '', -sbl );
sub name1 () {
}
sub name2()
{
}
RAW
sub name1 ()
{
}

sub name2 ()
{
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'what if indented', '', -sbl );
sub name1 () {
sub name2()
{
}
}
RAW
sub name1 ()
{

    sub name2 ()
    {
    }
}
TIDIED

done_testing;
