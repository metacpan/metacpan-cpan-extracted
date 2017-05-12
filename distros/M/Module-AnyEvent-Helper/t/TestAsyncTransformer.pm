use AnyEvent;
package TestAsyncTransformer::Tester;

sub new
{
	return bless {};
}

sub func4_async
{
	my $cv = AE::cv;
	my $w; $w = AE::timer 0.1, 0, sub { undef $w; $cv->send(0); };
	return $cv;
}

package TestAsyncTransformer;

sub new
{
	return bless {
		test => TestAsyncTransformer::Tester->new,
	};
}

sub func1_async
{
	my $cv = AE::cv;
	my $w; $w = AE::timer 0.1, 0, sub { undef $w; $cv->send(2); };
	return $cv;
}

sub func2_async
{
	my $cv = AE::cv;
	my $w; $w = AE::timer 0.1, 0, sub { undef $w; $cv->send(3); };
	return $cv;
}

use Module::AnyEvent::Helper::Filter -as => TestAsyncTransformer, -target => Test,
	-transformer => 'Test',
	-remove_func => [qw(func1 func2)], -translate_func => [qw(func3)],
	-replace_func => [qw(func4)], -delete_func => [qw(new)];

1;
