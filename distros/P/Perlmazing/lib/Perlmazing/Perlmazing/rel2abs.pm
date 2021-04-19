use File::Spec ();

sub main {
	File::Spec->rel2abs(@_);
}

1;