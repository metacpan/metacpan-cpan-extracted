# Start all Simplemock tests with these 4 lines!
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Most;
use SimpleMock qw(register_mocks clear_mocks);
# and then write your test as normal

use TestModule;

dies_ok { register_mocks(bad_model => {}); } "register mocks bad model";

################################################################################
# SUBS - see test for SimpleMock::Model::SUBS for more examples
################################################################################
my $r1 = TestModule::sub_one();
is $r1, 'one', 'Original test module return value';

lives_ok { register_mocks(
    SUBS => {
        'TestModule' => {
            'sub_three' => [
                { returns => 'default' },
                { args => [1], returns => 'one' },
            ]
        }
    }
); } "register mocks good model";

my $r2 = TestModule::sub_two();
is $r2, 'mocked', 'SimpleMock::Mocks::TestModule mock sub';

my $r3a = TestModule::sub_three(1);
is $r3a, 'one', 'register_mocks: test module return value for matched args';

my $r3b = TestModule::sub_three(2);
is $r3b, 'default', 'register_mocks: test module returns default value for no matched args';

my $r3c = TestModule::sub_three();
is $r3c, 'default', 'register_mocks: test module returns default value for no args';


################################################################################
# DBI - see test for SimpleMock::Model::DBI for more examples
################################################################################
my $d1 = [
    [ 'Clive', 'Clive@testme.com' ],
    [ 'Colin', 'Colin@testme.com' ],
];

my $d2 = [
    [ 'Jack', 'jack@testme.com' ],
    [ 'Jill', 'jill@testme.com' ],
]; 

register_mocks(
    DBI => {
        QUERIES => [
            {
                sql => 'SELECT name, email FROM user where name like=?',
                results => [
                    # for specific args
                    { args => [ 'C%' ], data => $d1 },
                    # default data to return
                    { data => $d2 },
                ],
            },
        ]
    }
);

my $data1 = TestModule::run_db_query('C%');
is_deeply $data1, $d1, 'DBI mock query with args';

# arg not found? use default
my $data2 = TestModule::run_db_query('J%');
is_deeply $data2, $d2, 'DBI mock query with no args';

################################################################################
# LWP::UserAgent - see test for SimpleMock::Model::LWP_UA for more examples
################################################################################

register_mocks(
    LWP_UA => {
        'http://example.com' => {
            GET => [
                { response => 'Example Content' },
            ],
        },
        'http://test.com' => {
            GET => [
                { response => {
                      content => 'Test Content',
                      code => 404,
                  }
                },
            ],
        },
    }
);

my $response1 = TestModule::fetch_url('http://example.com');
is $response1->content, 'Example Content', 'LWP mock request for example.com';
my $response2 = TestModule::fetch_url('http://test.com');
is $response2->content, 'Test Content', 'LWP mock request for test.com';
is $response2->code, 404, 'LWP mock request for test.com returns 404';



################################################################################
# register_mocks called twice for the same key overwrites (merge precedence)
################################################################################
register_mocks(
    SUBS => {
        TestModule => {
            sub_three => [ { returns => 'overwritten' } ],
        },
    },
);
is TestModule::sub_three(), 'overwritten',
    'register_mocks called twice for same key overwrites previous value';
# original arg-specific mock is preserved (only the _default was overwritten)
is TestModule::sub_three(1), 'one', 'arg-specific mock survives overwrite of default';

################################################################################
# _register_into_current_scope writes to top layer (not base layer)
################################################################################
{
    my $guard = SimpleMock::register_mocks_scoped(
        SUBS => { TestModule => { sub_three => [{ returns => 'layer1' }] } }
    );
    SimpleMock::_register_into_current_scope(
        SUBS => { TestModule => { sub_three => [{ returns => 'current_scope' }] } }
    );
    is TestModule::sub_three(), 'current_scope',
        '_register_into_current_scope writes to the current top layer';
    # guard destroyed here, scoped layer removed
}

################################################################################
# DEBUG_SIMPLEMOCK env var triggers _debug path
################################################################################
{
    local $ENV{DEBUG_SIMPLEMOCK} = 1;
    lives_ok {
        register_mocks(
            SUBS => { TestModule => { sub_three => [{ returns => 'debug_test' }] } }
        );
    } 'register_mocks with DEBUG_SIMPLEMOCK set does not die';
}

################################################################################
# require without .pm extension triggers filename conversion in override
################################################################################
lives_ok { require 'TestModule' } 'require string without .pm extension lives';

# ALWAYS LEAVE THESE TESTS AT THE END
# can clear one or all set mocks
is scalar(keys %{$SimpleMock::MOCK_STACK[0]}), 3, "mock type count";
clear_mocks('LWP_UA');
is scalar(keys %{$SimpleMock::MOCK_STACK[0]}), 2, "clear a class of mocks";
clear_mocks();
is_deeply $SimpleMock::MOCK_STACK[0], {}, "clear all mocks";


done_testing();

