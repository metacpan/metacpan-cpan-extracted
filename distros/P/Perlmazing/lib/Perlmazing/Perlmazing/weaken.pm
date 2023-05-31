use Scalar::Util 'weaken';

sub main {
	weaken $_[0];
}

1;
