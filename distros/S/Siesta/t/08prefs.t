#!perl -w
use strict;
use Test::More tests => 10;
use lib qw(t/lib);
use Siesta::Test;
use Siesta;

my $siesta = new Siesta;
my $list = Siesta::List->load('dealers');
my $plugin = Siesta::Plugin::Test->create({ queue => 'test',
                                            name => 'Test',
                                            list => $list });

ok($plugin, "have a plugin");
ok($plugin->list, "with a list");
is($plugin->pref('foo'), 'foo', "default option");

ok($plugin->pref('foo', 'bar'), "set foo for a list");
is($plugin->pref('foo'), 'bar');

my $user = Siesta::Member->load('jay@front-of.quick-stop');
ok($user, "loaded jay");
$plugin->member($user);

is($plugin->pref('foo'), 'bar', "user defaults to list pref");

ok($plugin->pref('foo', 'baz'), "user set a pref");
is($plugin->pref('foo'), 'baz');

$plugin->member(undef);

is($plugin->pref('foo'), 'bar', "with no user, list pref is back");

$plugin->delete;

# XXX this doesn't test deletions

package Siesta::Plugin::Test;
use base 'Siesta::Plugin';

sub options {
    +{
      foo => { default => 'foo' },
     };
}
