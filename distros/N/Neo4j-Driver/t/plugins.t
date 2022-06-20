#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings qw(warning);


# Unit tests for Neo4j::Driver::PluginManager

plan tests => 9 + 1;

use Neo4j::Driver;
use Neo4j::Driver::PluginManager;


my ($m, $p);


subtest 'new' => sub {
	plan tests => 2;
	lives_and { ok $m = Neo4j::Driver::PluginManager->new() } 'new';
	isa_ok $m, Neo4j::Driver::PluginManager::, 'PluginManager';
};


{
	package Neo4j_Test::Plugin::NoNew;
	use parent 'Neo4j::Driver::Plugin';
	sub register { die }
	
	package Neo4j_Test::Plugin::NoRegister;
	use parent 'Neo4j::Driver::Plugin';
	sub new { bless [], shift }
	
	package Neo4j_Test::Plugin::RegisterFoo;
	use parent 'Neo4j::Driver::Plugin';
	sub new { bless [], shift }
	sub register {
		my ($self, $manager) = @_;
		die unless $manager->isa( Neo4j::Driver::PluginManager:: );
		$manager->{_foo} = 'foo';
	}
}


subtest 'register' => sub {
	plan tests => 8;
	lives_and { ok $m = Neo4j::Driver::PluginManager->new() } 'new';
	throws_ok { $m->_register_plugin( Neo4j_Test::Plugin::NoNew:: ) }
		qr/\bCan't locate\b.*\bmethod new\b.*\bNeo4j_Test::Plugin::NoNew\b/i, 'no new';
	throws_ok { $m->_register_plugin( Neo4j_Test::Plugin::NoRegister:: ) }
		qr/\bMethod register\b.*\bnot implemented\b.*\bNeo4j_Test::Plugin::NoRegister\b/i, 'no register';
	lives_ok { $m->_register_plugin( Neo4j_Test::Plugin::RegisterFoo:: ) } 'register foo';
	is $m->{_foo}, 'foo', 'register set _foo';
	lives_and { ok $m = Neo4j::Driver::PluginManager->new() } 'new 2';
	lives_ok { $m->_register_plugin( Neo4j_Test::Plugin::RegisterFoo->new ) } 'register foo 2';
	is $m->{_foo}, 'foo', 'register set _foo 2';
};


{
	package Neo4j_Test::Plugin::SimpleReturns;
	use parent 'Neo4j::Driver::Plugin';
	sub new { bless [], shift }
	sub register {
		my ($self, $manager) = @_;
		$manager->add_event_handler( foo => sub { 'foofoo' } );
		$manager->add_event_handler( foo => sub { 'foobar' } );
		$manager->add_event_handler( x_foo => sub { 'bar' } );
		$manager->add_event_handler( empty => sub {} );
		my $push = sub { push @$self, 1 };  # yields array length after push
		$manager->add_event_handler( single => $push );
		$manager->add_event_handler( single => $push );
		# the first arg to a handler is always the $continue code ref, which we ignore here
		$manager->add_event_handler( first_arg => sub { shift; shift } );
		$manager->add_event_handler( all_args => sub { shift; \@_ } );
	}
}


subtest 'simple returns' => sub {
	plan tests => 14;
	lives_and { ok $m = Neo4j::Driver::PluginManager->new() } 'new';
	lives_ok { $m->_register_plugin( Neo4j_Test::Plugin::SimpleReturns:: ) } 'register';
	lives_and { is $m->trigger_event('x_foo'), 'bar' } 'x_foo';
	lives_and { like $m->trigger_event('foo'), qr/^foofoo$|^foobar$/ } 'foo';
	lives_and { is $m->trigger_event('empty'), undef } 'empty';
	is scalar(@{$m->{handlers}{single}}), 2, 'registered two handlers for single';
	lives_and { is $m->trigger_event('single'), 1 } 'single 1';
	lives_and { is $m->trigger_event('single'), 2 } 'only one handler was executed for single 1';
	lives_and { is $m->trigger_event('first_arg'), undef } 'first_arg undef';
	lives_and { is $m->trigger_event('first_arg', 0), 0 } 'first_arg 0';
	lives_and { is $m->trigger_event('first_arg', 1..4), 1 } 'first_arg 1';
	lives_and { is_deeply $m->trigger_event('all_args'), [] } 'args []';
	lives_and { is_deeply $m->trigger_event('all_args', 0), [0] } 'args [0]';
	lives_and { is_deeply $m->trigger_event('all_args', 1..4), [1..4] } 'args [1..4]';
};


{
	package Neo4j_Test::Plugin::Countdown;
	use parent 'Neo4j::Driver::Plugin';
	sub new { bless [], shift }
	sub register {
		my ($self, $manager) = @_;
		$manager->add_event_handler( x_countdown => sub {
			my ($continue, $count) = @_;
			return [0] if $count <= 0;
			my $more = $manager->trigger_event('x_countdown', $count - 1);
			return [$count, @$more];
		});
	}
}


subtest 'custom event recursive countdown' => sub {
	plan tests => 3;
	lives_and { ok $m = Neo4j::Driver::PluginManager->new() } 'new';
	lives_ok { $m->_register_plugin( Neo4j_Test::Plugin::Countdown:: ) } 'register';
	lives_and { is_deeply $m->trigger_event('x_countdown', 10), [reverse 0..10] } 'countdown 10';
};


{
	package Neo4j_Test::Plugin::MultiHandler;
	use parent 'Neo4j::Driver::Plugin';
	sub new { bless [0, 0], shift }
	sub register {
		my ($self, $manager) = @_;
		$manager->add_event_handler( plugin_ref => sub { $self } );
		$manager->add_event_handler( once => sub { $self->[0]++; shift->() } );
		$manager->add_event_handler( thrice => sub { $self->[1] += 1; shift->() } );
		$manager->add_event_handler( thrice => sub { $self->[1] += 2; shift->() } );
		$manager->add_event_handler( thrice => sub { $self->[1] += 4; shift->() } );
		$manager->add_event_handler( retval => sub { my $x = shift->() // 0; $x + 1 } );
		$manager->add_event_handler( retval => sub { my $x = shift->() // 0; $x + 2 } );
	}
}


subtest 'multiple handlers for an event' => sub {
	plan tests => 8;
	lives_and { ok $m = Neo4j::Driver::PluginManager->new() } 'new';
	lives_ok { $m->_register_plugin( Neo4j_Test::Plugin::MultiHandler:: ) } 'register';
	lives_and { ok $p = $m->trigger_event('plugin_ref') } 'plugin_ref';
	lives_and { is $m->trigger_event('once'), undef } 'fallthrough once undef';
	lives_and { is $m->trigger_event('thrice'), undef } 'fallthrough thrice undef';
	is $p->[0], 1, '1 once';
	is $p->[1], 7, '3 thrice';
	lives_and { is $m->trigger_event('retval'), 3 } 'return values';
};


{
	package Neo4j_Test::Plugin::DefaultHandler;
	use parent 'Neo4j::Driver::Plugin';
	sub new { bless [], shift }
	sub register {
		my ($self, $manager) = @_;
		$manager->add_event_handler( 1 => sub { shift->() . 'one' } );
		$manager->add_event_handler( 2 => sub { shift->() . 'two' } );
		$manager->add_event_handler( 2 => sub { shift->() . 'two' } );
		$manager->add_event_handler( 8 => sub { shift->() . 'eight' } );
	}
}


subtest 'default handlers' => sub {
	plan tests => 10;
	lives_and { ok $m = Neo4j::Driver::PluginManager->new() } 'new';
	lives_ok { $m->{default_handlers}->{0} = sub { 'nada' } } 'add default handler zero';
	lives_ok { $m->{default_handlers}->{1} = sub { 'una' } } 'add default handler one';
	lives_ok { $m->{default_handlers}->{2} = sub { 'bisso' } } 'add default handler two';
	lives_ok { $m->_register_plugin( Neo4j_Test::Plugin::DefaultHandler:: ) } 'register';
	lives_ok { $m->{default_handlers}->{8} = sub { 'okto' } } 'add default handler eight';
	lives_and { is $m->trigger_event(0), 'nada' } 'zero default handler';
	lives_and { is $m->trigger_event(1), 'unaone' } 'one';
	lives_and { is $m->trigger_event(2), 'bissotwotwo' } 'two';
	lives_and { is $m->trigger_event(8), 'oktoeight' } 'eight';
};


subtest 'trigger unhandled' => sub {
	plan tests => 10;
	lives_and { ok $m = Neo4j::Driver::PluginManager->new() } 'new';
	lives_ok { $m->trigger_event( 'foo' ) } 'unhandled lives';
	lives_ok { $m->trigger_event( 'foo', 'bar' ) } 'unhandled w/ param lives';
	lives_ok { $m->trigger_event( 'x_foo' ) } 'unhandled x lives';
	lives_ok { scalar $m->trigger_event( 'bar' ) } 'unhandled scalar lives';
	lives_ok { ( $m->trigger_event( 'bar' ) ) } 'unhandled list lives';
	lives_ok { $m->add_event_handler( 'foobar' => sub { 'xxx' } ) } 'add_event_handler';
	lives_and { is $m->trigger_event( 'foo' ), undef } 'shorter is unhandled';
	lives_and { is $m->trigger_event( 'foobar ' ), undef } 'longer is unhandled';
	lives_and { is $m->trigger_event( 'foobar' ), 'xxx' } 'late added handler';
};


subtest 'errors' => sub {
	plan tests => 10;
	lives_and { ok $m = Neo4j::Driver::PluginManager->new() } 'new';
	throws_ok { $m->add_event_handler( event => sub {}, event2 => sub {} ) }
		qr/\badd_event_handler\b.*\bmore than one\b.*\bunsupported\b/i, 'two events';
	throws_ok { $m->add_event_handler( event => sub {}, sub {} ) }
		qr/\badd_event_handler\b.*\bmore than one\b.*\bunsupported\b/i, 'odd number of args';
	throws_ok { $m->add_event_handler( event => 'sub_name' ) }
		qr/\bhandler\b.*\bmust be\b.*\bsubroutine reference\b/i, 'handler by sub name';
	throws_ok { $m->add_event_handler( event => [] ) }
		qr/\bhandler\b.*\bmust be\b.*\bsubroutine reference\b/i, 'array as handler';
	throws_ok { $m->add_event_handler( 'event' ) }
		qr/\bhandler\b.*\bmust be\b.*\bsubroutine reference\b/i, 'no handler';
	throws_ok { $m->add_event_handler( undef, sub {} ) }
		qr/\bEvent name\b.*defined\b/i, 'no event name';
	throws_ok { $m->_register_plugin( 'Neo4j::Driver' ) }
		qr/\bnot\b.*\bNeo4j::Driver::Plugin\b/i, 'register non-plugin package';
	throws_ok { $m->_register_plugin( Neo4j::Driver->new ) }
		qr/\bnot\b.*\bNeo4j::Driver::Plugin\b/i, 'register non-plugin object';
	dies_ok { $m->_register_plugin( undef ) } 'register undef';
};


subtest 'register via driver' => sub {
	my $d;
	plan skip_all => '(driver constructor failed)' unless eval { $d = Neo4j::Driver->new };
	plan tests => 5;
	lives_ok { $d->plugin( 'Neo4j_Test::Plugin::RegisterFoo' ) } 'plugin with package';
	is $d->{plugins}->{_foo}, 'foo', 'package set _foo';
	throws_ok { $d->plugin( 'Neo4j_Test::Plugin::RegisterFoo', 1 ) }
		qr/\bplugin\b.*\bmore than one argument\b.*\bunsupported\b/i, 'extra';
	$d->{plugins}->{_foo} = '';
	lives_ok { $d->plugin( Neo4j_Test::Plugin::RegisterFoo->new ) } 'plugin with instance';
	is $d->{plugins}->{_foo}, 'foo', 'instance set _foo';
};


done_testing;
