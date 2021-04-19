use File::Spec ();

sub main {
	File::Spec->splitpath(@_);
}

1;