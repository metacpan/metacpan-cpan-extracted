#!perl
use 5.020;
use Term::Output::List;
use Test2::V0;

open my $fh, '>:raw', \my $buffer;
my $t = Term::Output::List->new(
    fh => $fh,
);

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

is $buffer, join( "\n",
    "# Permanent message 1",
    "# Permanent message 2",
    "# Permanent message 3",
    "# Permanent message 4",
    "# Permanent message 5 (clearing running list)",
    ) . "\n", "Non-interactive output has only the permanent messages";
done_testing();