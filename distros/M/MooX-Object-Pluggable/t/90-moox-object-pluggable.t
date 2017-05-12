use Modern::Perl;
use Test::More;
my $module = 'MooX::Object::Pluggable';
use_ok($module);

package main;
{ package CC; use Moo; use namespace::clean; with 'MooX::Object::Pluggable'; }
{ package CC::Plugin::Aisarole; use Moo::Role; }
{ package CC::Plugin::Cisarole; use Moo::Role; }
{ package CC::Plugin::Bnotarole; } # this is not a plugin.
{ package CC::Other::Plugin; use Role::Tiny; }

my @plugins = ('CC::Plugin::Aisarole', 'CC::Plugin::Cisarole');
can_ok('CC', 'does');
ok(CC->does('MooX::Object::Pluggable'), "CC does role MooX::Object::Pluggable");
ok(!CC->does('CC::Plugin::Aisarole'), "The role CC::Plugin::Aisarole haven't apply to object");

is(CC->_pluggable_object, CC->_pluggable_object, "Directly called _pluggable_object should be equal");
is(CC->new->_pluggable_object, CC->_pluggable_object, "New object with common options called_pluggable_object should be equal");

# plugins list
is_deeply([CC->plugins], [@plugins], "Called ->plugins with array rerurn");

# load_plugins
my $o = CC->new;
my $po1 = $o->_pluggable_object;
$o->load_plugins('Aisarole');
my $po2 = $o->_pluggable_object;
is($po1, $po2, "The pluggable object before and after loaded Should be the same");
$o->load_plugins(qr/::C/);
ok($o->does("CC::Plugin::Cisarole"), "Load plugins with Regexp");
my $n = CC->new->load_plugins("Aisarole", qr/::C/);
ok( ($n->does("CC::Plugin::Cisarole") and $n->does('CC::Plugin::Aisarole')),"Load plugins with Array");
$n = CC->new->load_plugins(["Aisarole", qr/::C/]);
ok( ($n->does("CC::Plugin::Cisarole") and $n->does('CC::Plugin::Aisarole')),"Load plugins with ArrayRef");
$n = CC->new->load_plugins('+CC::Other::Plugin');
ok($n->does('CC::Other::Plugin'), "Load plugins with '+' sign");

# new with pluggable options.
my $a = CC->new(load_plugins => '-all');
ok($a->does($_), "new with load_plugins -all: plugin $_ loaded") for @plugins;
ok(!$a->does('CC::Plugin::Bnotarole'), "A plugin must be a role");
my $b = CC->new(load_plugins => ['Aisarole']);
ok($b->does('CC::Plugin::Aisarole'), "new with load_plugins as ArrayRef");
is($b->_pluggable_object, CC->_pluggable_object, "Share a single pluggable object with one class");
is($a->_pluggable_object, $b->_pluggable_object, ", so the pluggable object from diffent objects should be equal");
my $c = CC->new(pluggable_options => { search_path => 'CC::Plugin' }, load_plugins => ['Aisarole']);
my $d = CC->new(pluggable_options => { search_path => 'CC::Plugin' }, load_plugins => [qr/Ais/]);
isnt($a->_pluggable_object, $c->_pluggable_object, ", expect objects newed with specific pluggable options");

done_testing;

