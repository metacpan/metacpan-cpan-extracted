use Test::More tests => 3;

BEGIN { use_ok('Module::AnyEvent::Helper::PPI::Transform'); }

my $target = <<'EOF';
package TestMethod;

use strict;
use warnings;

sub new
{
	return bless {};
}

sub func1
{
	return 1;
}

sub func2
{
	return 2;
}

sub func3
{
	my ($self, $arg) = @_;
	$self->func1 (0) if $arg == 1;
	return $self->func2() if $arg == 2;
	return 0;
}
1;
EOF

my $result = <<'EOF';
use AnyEvent;use Module::AnyEvent::Helper;package TestMethod;

use strict;
use warnings;

sub new
{
	return bless {};
}





sub func3_async
{my $___cv___ = AE::cv;
	my ($self, $arg) = @_;
	Module::AnyEvent::Helper::bind_scalar($___cv___, $self->func1_async(0), sub {
 shift->recv() if $arg == 1;
	Module::AnyEvent::Helper::bind_scalar($___cv___, $self->func2_async(), sub {
return shift->recv() if $arg == 2;
	return 0;
});});return $___cv___;}
1;Module::AnyEvent::Helper::strip_async_all(-exclude => [qw()]);1;
EOF

my $trans = Module::AnyEvent::Helper::PPI::Transform->new(
	-remove_func => [qw(func1 func2)],
	-translate_func => [qw(func3)],
);
ok($trans->apply(\$target));
# TODO: Maybe it is adequate to check significant elements only
is($target, $result);
