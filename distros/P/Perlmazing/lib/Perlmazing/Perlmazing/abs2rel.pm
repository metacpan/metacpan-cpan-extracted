use File::Spec ();

sub main {
	File::Spec->abs2rel(@_);
}

1;