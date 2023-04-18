use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Annonymouns function', '',  );
my $code = async sub { return 456 };
RAW
my $code = async sub { return 456 };
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Async function', '',  );
async sub  do_a_thing
{
  my $first =  await  do_first_thing();
    return $first;
}
RAW
async sub do_a_thing {
    my $first = await do_first_thing();
    return $first;
}
TIDIED

done_testing;
