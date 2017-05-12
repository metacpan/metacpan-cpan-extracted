use strict;
use warnings;
no  warnings 'once';

use JSON;
use Test::More;

use RPC::ExtDirect::Test::Util;

if ( $ENV{REGRESSION_TESTS} ) {
    plan tests => 10;
}
else {
    plan skip_all => 'Regression tests are not enabled.';
}

# We will test deprecated API and don't want the warnings
# cluttering STDERR
$SIG{__WARN__} = sub {};

use lib 't/lib2';
use RPC::ExtDirect::Test::PollProvider;

use RPC::ExtDirect::EventProvider;

local $RPC::ExtDirect::EventProvider::DEBUG = 1;

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: '$@'";

for my $test ( @$tests ) {
    my $name     = $test->{name};
    my $password = $test->{password};
    my $expect   = from_json $test->{result};

    local $RPC::ExtDirect::Test::PollProvider::WHAT_YOURE_HAVING
            = $password;

    my $result = from_json eval { RPC::ExtDirect::EventProvider->poll() };

    is      $@,      '',      "$name eval $@";
    is_deep $result, $expect, "$name result";
};


__DATA__
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
