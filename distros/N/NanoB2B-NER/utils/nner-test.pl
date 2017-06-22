use NanoB2B::UniversalRoutines;

my %params = ();
$params{"debug"} = 1;
my $uniSub = NanoB2B::UniversalRoutines->new(\%params);


$uniSub->printColorDebug("black on_white", "Hello World!");
$uniSub->printColorDebug("red", "Greetings Programs!\n");

my @arr = ("a", "b", "c");

$uniSub->printArr("\n", \@arr);