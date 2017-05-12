package TestArrayAsync;

sub func1_async()
{
	my $cv = AE::cv;
	my $w; $w = AE::timer 0.1, 0, sub { undef $w; $cv->send(1, 2); };
	return $cv;
}

sub func2_async()
{
	my $cv = AE::cv;
	my $w; $w = AE::timer 0.1, 0, sub { undef $w; $cv->send(2, 3, 4); };
	return $cv;
}

use Module::AnyEvent::Helper::Filter -as => TestArrayAsync, -target => TestArray,
	-remove_func => [qw(func1 func2)], -translate_func => [qw(@func3)];

1;
