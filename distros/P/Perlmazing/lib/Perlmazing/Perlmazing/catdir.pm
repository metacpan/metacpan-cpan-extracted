use File::Spec ();

sub main {
	File::Spec->catdir(@_);
}

1;