use Perlmazing;
use Carp ();

sub main {
	goto &Carp::croak;
}

1;