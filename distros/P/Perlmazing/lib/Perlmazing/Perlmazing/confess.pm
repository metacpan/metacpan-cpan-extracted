use Carp ();

sub main {
	goto &Carp::confess;
}

1;