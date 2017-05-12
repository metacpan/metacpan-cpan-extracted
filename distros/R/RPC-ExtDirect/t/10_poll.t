use strict;
use warnings;

use Test::More tests => 10;

use RPC::ExtDirect::Test::Pkg::PollProvider;

use RPC::ExtDirect::Test::Util qw/ cmp_json /;
use RPC::ExtDirect::Config;

use RPC::ExtDirect::EventProvider;

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: '$@'";

for my $test ( @$tests ) {
    my $name     = $test->{name};
    my $password = $test->{password};
    my $expect   = $test->{result};

    local $RPC::ExtDirect::Test::Pkg::PollProvider::WHAT_YOURE_HAVING
            = $password;

    my $config = RPC::ExtDirect::Config->new(
        debug_serialize => 1,
    );

    my $provider = RPC::ExtDirect::EventProvider->new(
        config => $config,
    );

    my $result = eval { $provider->poll() };

    is       $@,      '',      "$name eval $@";
    cmp_json $result, $expect, "$name result";
};

__DATA__
#line 39
[
    { name   => 'Two events', password => 'Usual, please',
      result => q|[{"data":["foo"],|.
                q|  "name":"foo_event",|.
                q|  "type":"event"},|.
                q| {"data":{"foo":"bar"},|.
                q|  "name":"bar_event",|.
                q|  "type":"event"}]|,
    },
    { name   => 'One event', password => 'Ein kaffe bitte',
      result => q|{"data":"Uno cappuccino, presto!",|.
                q| "name":"coffee",|.
                q| "type":"event"}|,
    },
    { name   => 'Failed method', password => 'Whiskey, straight away!',
      result => q|{"data":"","name":"__NONE__","type":"event"}|,
    },
    { name     => 'No events at all',
      password => "But that's not on the menu!",
      result   => q|{"data":"","name":"__NONE__","type":"event"}|,
    },
    { name     => 'Invalid Event provider output',
      password => "Hey man! There's a roach in my soup!",
      result   => q|{"data":"","name":"__NONE__","type":"event"}|,
    },
]
