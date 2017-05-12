use strict;
use warnings;

use Test::More;
use RPC::ExtDirect::Test::Util;

if ( $ENV{REGRESSION_TESTS} ) {
    plan tests => 24;
}
else {
    plan skip_all => 'Regression tests are not enabled.';
}

# We will test deprecated API and don't want the warnings
# cluttering STDERR
$SIG{__WARN__} = sub {};

use RPC::ExtDirect::Exception;

package RPC::ExtDirect::Test;

use RPC::ExtDirect::Exception;

sub foo {
    return RPC::ExtDirect::Exception->new({ debug   => 0,
                                            action  => 'Test',
                                            method  => 'foo',
                                            tid     => 1,
                                            message => 'new fail' });
}

sub bar {
    return RPC::ExtDirect::Exception->new({ debug   => 1,
                                            action  => 'Test',
                                            method  => 'bar',
                                            tid     => 2,
                                            message => 'bar fail' });
}

sub qux {
    return RPC::ExtDirect::Exception->new({ debug   => 1,
                                            action  => 'Test',
                                            method  => 'qux',
                                            tid     => 3,
                                            message => 'qux fail',
                                            where => 'X->qux' });
}

package main;

my $tests = [
    { method  => 'foo',
      ex => { type    => 'exception',
              action  => 'Test',
              method  => 'foo',
              tid     => 1,
              where   => 'ExtDirect',
              message => 'An error has occured while processing request',
      },
    },
    { method  => 'bar',
      ex => { type    => 'exception',
              action  => 'Test',
              method  => 'bar',
              tid     => 2,
              where   => 'RPC::ExtDirect::Test->bar',
              message => 'bar fail',
      },
    },
    { method  => 'qux',
      ex => { type    => 'exception',
              action  => 'Test',
              method  => 'qux',
              tid     => 3,
              where   => 'X->qux',
              message => 'qux fail',
      },
    },
];

for my $test ( @$tests ) {
    my $method = $test->{method};
    my $expect = $test->{ex};

    my $ex  = eval { RPC::ExtDirect::Test->$method() };

    is     $@,   '', "$method() new eval $@";
    ok     $ex,      "$method() exception not null";
    ref_ok $ex,  'RPC::ExtDirect::Exception';

    my $run = eval { $ex->run() };

    is  $@,   '', "$method() run eval $@";
    ok !$run,     "$method() run error returned";

    my $result = eval { $ex->result() };

    is      $@,      '',      "$method() result eval $@";
    ok      $result,          "$method() result not empty";
    is_deep $result, $expect, "$method() exception deep";
};

