use File::Spec ();

sub main {
	File::Spec->devnull(@_);
}

1;