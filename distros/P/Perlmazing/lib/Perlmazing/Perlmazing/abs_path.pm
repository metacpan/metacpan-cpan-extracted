use Cwd ();

sub main {
	Cwd::abs_path(@_);
}

1;