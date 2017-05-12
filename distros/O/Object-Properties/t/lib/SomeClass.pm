package # hide from PAUSE
	SomeClass;

use Object::Properties qw( +rw ro ),
	'+rw_die'    => \&_refuse,
	'ro_die'     => \&_refuse,
	'+rw_munged' => \&_lc,
	'ro_munged'  => \&_lc,
	'+bitbucket' => sub {};

use Carp ();
sub _refuse { Carp::croak($_[1]) }

sub _lc { lc $_[1] }

1;
