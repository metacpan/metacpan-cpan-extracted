use strict;
use warnings;
use Test::More;
use Test::Moose;

{
	package Test;
	use Moose;
	use MooseX::RemoteHelper;

	has attr => (
		remote_name => 'attribute',
		isa         => 'Str',
		is          => 'ro',
		required    => 1,
	);
	__PACKAGE__->meta->make_immutable;
}

my $t0 = Test->new({ attr => 'foo' });

isa_ok $t0, 'Test';
can_ok $t0, 'attr';
can_ok $t0, 'meta';

isa_ok my $attr0 = $t0->meta->get_attribute('attr'), 'Class::MOP::Attribute';

does_ok $attr0, 'MooseX::RemoteHelper::Meta::Trait::Attribute';

can_ok $attr0, 'has_remote_name';
can_ok $attr0, 'remote_name';

ok $attr0->has_remote_name, 'has remote_name';
is $attr0->remote_name, 'attribute', 'remote_name is attribute';

my $t1 = Test->new({ attribute => 'foo' });

is $t1->attr, 'foo', 'attr matches';

done_testing;
