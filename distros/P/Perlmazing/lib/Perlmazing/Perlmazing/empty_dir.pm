use Perlmazing;
use File::Path 'remove_tree';

sub main {
	remove_tree $_[0], {keep_root => 1};
}

1;
