use File::Spec ();

sub main {
	File::Spec->catfile(@_);
}

1;