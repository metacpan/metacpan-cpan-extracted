use File::Spec ();

sub main {
	File::Spec->splitdir(@_);
}

1;