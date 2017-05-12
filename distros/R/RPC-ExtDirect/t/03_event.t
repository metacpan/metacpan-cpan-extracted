use strict;
use warnings;

use Test::More tests => 31;

use RPC::ExtDirect::Test::Util;

use RPC::ExtDirect::Event;
use RPC::ExtDirect::NoEvents;

# Test Events with data

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: '$@'";

for my $test ( @$tests ) {
    my $name = $test->{name};
    my @arg  = @{ $test->{arg} };
    my $exp  = $test->{res};
    
    my $event = eval { RPC::ExtDirect::Event->new(@arg) };

    is     $@, '', "$name event new() eval $@";
    ok     $event, "$name event object created";
    ref_ok $event, 'RPC::ExtDirect::Event';
    
    my $result = eval { $event->result() };

    is      $@,      '',   "$name event result() eval $@";
    ok      $result,       "$name event result() not empty";
    is_deep $result, $exp, "$name event result() deep";
}

# Test argument checking

my $event = eval { RPC::ExtDirect::Event->new() };

like $@, qr/^Ext.Direct Event name is required/, "Argument check";

# Test the stub

my $no_events = eval { RPC::ExtDirect::NoEvents->new() };

is     $@, '',     "NoEvents new() eval $@";
ok     $no_events, "NoEvents new() object created";
ref_ok $no_events, 'RPC::ExtDirect::NoEvents';

my $expected_result = {
    type => 'event',
    name => '__NONE__',
    data => '',
};

my $real_result = eval { $no_events->result() };

is      $@, '',                         "NoEvents result() eval $@";
ok      $real_result,                   "NoEvents result() not empty";
is_deep $real_result, $expected_result, "NoEvents result() deep";

__DATA__
#line 61
[
    {
        name => 'ordered',
        arg  => ['foo', 'bar'],
        res  => {
            type => 'event',
            name => 'foo',
            data => 'bar',
        },
    },
    {
        name => 'hashref',
        arg  => [{ name => 'bar', data => 'baz' }],
        res  => {
            type => 'event',
            name => 'bar',
            data => 'baz',
        },
    },
    {
        name => 'hash',
        arg  => [name => 'baz', data => 'qux'],
        res  => {
            type => 'event',
            name => 'baz',
            data => 'qux',
        },
    },
    {
        name => 'w/o data',
        arg  => ['burr'],
        res  => {
            type => 'event',
            name => 'burr',
            data => undef,
        },
    }
]
