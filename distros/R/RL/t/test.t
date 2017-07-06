use strict;
use warnings;
use Test::More;
use RL;

open my $fh, ">", "/dev/null" or die "Can't open /dev/null: $!\n";
RL::outstream($fh);

my ($input, $output);
RL::getc_function(sub {
    my $c = substr($input, 0, 1);
    $input = substr($input, 1);
    return ord($c);
});

$input = "Hello\n";
$output = RL::readline("prompt: ");
ok $output eq "Hello", "readline works";

RL::add_history($output);
my $string = RL::history_get(RL::history_base());
ok $string eq "Hello", "add_history works";

done_testing();

