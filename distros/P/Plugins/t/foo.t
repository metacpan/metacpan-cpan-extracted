
package FooTest;

use strict;
use warnings;
use Cwd;
use Plugins::Style1;
use Plugins::SimpleConfig;
use Plugins::API;
use Test::More tests => 24;

my $configfile = cwd()."/t/config";

my $global1 = 7;
my $global2 = 8;

my %config_items = (
	item1	=> '',
	item2	=> 2,
	item3	=> \$global1,
	item4	=> \$global2,
);

sub config_prefix { return '' };

sub parse_config_line { simple_config_line(\%config_items, @_); }

sub new { bless {} };

sub preconfig
{
	my $self = shift;
	$self->{api} = Plugins::API->new({ autoregister => $self },
		apinormal	=> {},
		apifirst	=> { first_defined => 1 },
		apicombine	=> { combine_returns => 1 },
		apiarray	=> { array_return => 1, },
		apitest		=> { exit_test => sub { my $r = shift; $r->[0] > 2 } },
	);

	delete $self->{plugins};
	$self->{plugins} = Plugins::Style1->new(api => $self->{api});
	$self->{plugins}->readconfig($configfile, self => $self);
	$self->{plugins}->initialize();
	$self->{plugins}->invoke('preconfig', $self->{configfile});
}


my $self = new();
$self->preconfig();
$self->{plugins}->invoke('nameis', 'foo');
for my $plugin ($self->{plugins}->plugins) {
	if ($plugin->invoke('nameis', 'foo')) {
		$self->{nameFoo} = $plugin;
	} elsif ($plugin->invoke('nameis', 'bar')) {
		$self->{nameBar} = $plugin;
	} elsif ($plugin->invoke('nameis', 'baz')) {
		$self->{nameBaz} = $plugin;
	}
}
is($self->{nameFoo}->invoke('getval', 'name'), 'foo', "yes, the names match (foo)");
is($self->{nameBar}->invoke('getval', 'name'), 'bar', "yes, the names match (bar)");
is($self->{nameBaz}->invoke('getval', 'name'), 'baz', "yes, the names match (baz)");

is($self->{nameBar}->invoke('getval', 'hasplugins'), 1, "yes, hasplugins (bar)");
is($self->{nameFoo}->invoke('getval', 'hasplugins'), 0, "no, hasplugins (foo)");

is($self->{nameFoo}->invoke('getval', 'c2'), 'blaf', "yes, the names match (foo)");
is($self->{nameBar}->invoke('getval', 'c2'), '38x', "yes, the names match (bar)");
is($self->{nameBaz}->invoke('getval', 'c2'), 'blorf', "yes, the names match (baz)");

is($self->{api}->invoke('apifirst', 'c2'), 'blaf', "api first");

my @c = $self->{api}->invoke('apicombine', 'c2');
is($c[0], 'blaf', 'abicombine 0');
is($c[1], '38x', 'abicombine 1');
is($c[2], 'blorf', 'abicombine 2');
is(scalar(@c), 3, 'abicombine length');

# test autoload
my @d = $self->{api}->apicombine('c2');
is($d[0], 'blaf', 'd abicombine 0');
is($d[1], '38x', 'd abicombine 1');
is($d[2], 'blorf', 'd abicombine 2');
is(scalar(@d), 3, 'd abicombine length');

$self->{api}->disable($self->{nameBaz});
my @e = $self->{api}->apicombine('c2');
is($e[0], 'blaf', 'e abicombine 0');
is($e[1], '38x', 'e abicombine 1');
is(scalar(@e), 2, "e abicombine length: @d");

