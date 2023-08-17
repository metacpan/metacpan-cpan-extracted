#!perl
use 5.020;
use Term::Output::List;
use Test::More;

my $t = Term::Output::List->new();

my @running = map { sprintf "# Task %d",$_ } 1..3;

$t->output_permanent("# Permanent message 1");
$t->output_permanent("# Permanent message 2");

$t->output_list(@running);

push @running, "# Task 4";

$t->output_list(@running);

$t->output_permanent("# Permanent message 3");
$t->output_permanent("# Permanent message 4");
$t->output_list(@running);

$t->output_permanent("# Permanent message 5 (clearing running list)");

# Now clear the list
$t->output_list();

note "The output should now be:";
note "Permanent message 1";
note "Permanent message 2";
note "Permanent message 3";
note "Permanent message 4";
note "Permanent message 5 (clearing running list)";

ok 1;
done_testing();