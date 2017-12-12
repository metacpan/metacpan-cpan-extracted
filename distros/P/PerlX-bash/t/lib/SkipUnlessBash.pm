use Test::More;
use File::Spec;

{
	my $devnull = File::Spec->devnull;
	my $msg = 'successful';
	`bash -c "echo $msg" 2>$devnull` eq "$msg\n" or plan skip_all => "no bash available!";
}
