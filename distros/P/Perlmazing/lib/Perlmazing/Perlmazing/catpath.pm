use File::Spec ();

sub main {
	File::Spec->catpath(@_);
}

1;