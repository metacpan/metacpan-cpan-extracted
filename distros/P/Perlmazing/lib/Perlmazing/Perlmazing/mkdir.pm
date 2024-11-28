use Perlmazing;
use File::Path 'make_path';

sub main {
	if (@_ == 1) {
		make_path $_[0];
	} else {
		make_path $_[0], {mode => $_[1]};
	}
}

1;
