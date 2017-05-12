use Test::More;
use Data::OptList;
use MooseX::ClassCompositor;

my $monkey_is_fed = undef;

BEGIN {
	package Local::My::Monkey;
	use Moose;
	sub feed {
		$monkey_is_fed = pop;
	}
}

BEGIN {
	package Local::My::MonkeyFeeding;
	use Moose::Role;
	requires qw(monkey);
	requires qw(food);
	sub feed_monkey {
		my $self = shift;
		$self->monkey->feed( $self->food );
	}
}

sub methods {
	my $r = Moose::Meta::Role->create_anon_role();
	while (@_) {
		my $name = shift;
		my $code = ref $_[0] ? shift : sub { +return };
		$r->add_method($name, $code);
	}
	return $r;
}

sub attributes {
	my $r = Moose::Meta::Role->create_anon_role();
	while (@_) {
		my $name = shift;
		my $opts = ref $_[0] ? shift : +{ is => 'ro' };
		$r->add_attribute($name, %$opts);
		$r->add_method($name, sub { +return });  # why needed??
	}
	return $r;
}

my $comp = MooseX::ClassCompositor->new(
	class_basename => 'Local::My',
	fixed_roles    => [ methods(quux => sub { 999 }) ],
);

my @roles = (
	methods( answer => sub { 42 } ),
	attributes(qw( food monkey )),
	'Local::My::MonkeyFeeding'->meta,
);
my $class = $comp->class_for(@roles);

my $obj = $class->new(
	food   => 'bananas',
	monkey => Local::My::Monkey->new,
);

can_ok($obj, qw( food monkey feed_monkey answer quux ));

isa_ok($obj->monkey, 'Local::My::Monkey', '$obj->monkey');
$obj->feed_monkey;
is($monkey_is_fed, $obj->food, 'interaction between composed roles works');

is($obj->answer, 42, '$obj->answer == 42');
is($obj->quux,  999, '$obj->quux == 999 (via fixed role)');

done_testing();
