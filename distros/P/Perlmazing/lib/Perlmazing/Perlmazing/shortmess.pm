use Carp ();

sub main {
	goto &Carp::shortmess;
}

1;