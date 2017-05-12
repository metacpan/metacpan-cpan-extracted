package MyObject;
# For testing purposes

use base 'RT::Client::REST::Object';
use Params::Validate qw(:types);

sub rt_type { 'myobject' }

sub _attributes {{
    id => {},
    abc => {
        validation => {
            type => SCALAR,
        },
    },
}}

sub retrieve {
    my $self = shift;
    $self->abc($self->id);
    $self->{__dirty} = {};
    return $self;
}

my $i = 0;
sub store {
    my $self = shift;
    $::STORED = ++$i;
}

__PACKAGE__->_generate_methods;

package main;

use strict;
use warnings;

use vars qw($STORED);

use Test::More tests => 20;
use Test::Exception;

my $obj = MyObject->new(id => 1);
ok(!defined($obj->abc), "retrieve has not been called");

$obj->retrieve;
ok(defined($obj->abc), "retrieve has been called");

$obj->abc(1);
ok(1 == $obj->abc, "attribute 'abc' set correctly");
ok(1 == $obj->_dirty, "one dirty attribute");
ok('abc' eq ($obj->_dirty)[0], "and that attribute is 'abc'");

ok(!defined(MyObject->autostore), "autostore is disabled by default");
ok(!defined(MyObject->autosync), "autosync is disabled by default");
ok(!defined(MyObject->autoget), "autoget is disabled by default");

throws_ok {
    MyObject->be_transparent(3);
} 'RT::Client::REST::Object::InvalidValueException';

use RT::Client::REST;
my $rt = RT::Client::REST->new;

lives_ok {
    MyObject->be_transparent($rt);
} "made MyObject transparent";

ok(!defined(MyObject->autostore), "autostore is still disabled");
ok(MyObject->autosync, "autosync is now enabled");
ok(MyObject->autoget, "autoget is now enabled");
ok($rt == MyObject->rt, "the class keeps track of rt object");

ok(!defined(RT::Client::REST::Object->autostore),
    "autostore is disabled in the parent class");
ok(!defined(RT::Client::REST::Object->autosync),
    "autosync is disabled in the parent class");
ok(!defined(RT::Client::REST::Object->autoget),
    "autoget is disabled in the parent class");

$obj = MyObject->new(id => 4);
ok($obj->abc == 4, "object auto-retrieved");
my $stored = $STORED;
$obj->abc(5);
ok($stored + 1 == $STORED, "object is stored");
$stored = $STORED;
$obj->id(10);
ok($stored == $STORED, "modifying 'id' did not trigger a store");

# vim:ft=perl:
