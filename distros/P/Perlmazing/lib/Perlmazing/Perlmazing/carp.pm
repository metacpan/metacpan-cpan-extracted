use Carp ();

sub main {
	goto &Carp::carp;
}

1;