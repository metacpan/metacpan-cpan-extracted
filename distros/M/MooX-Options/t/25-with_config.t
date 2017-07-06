#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;
use Test::Trap;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

BEGIN {
    use Module::Runtime qw(use_module);
    eval { use_module("MooX::ConfigFromFile::Role") }
        or plan skip_all => "This test needs MooX::ConfigFromFile";
}

{

    package MyTestWithConfig;
    use Moo;
    use MooX::Options with_config_from_file => 1;

    option 'p1' => ( is => 'ro', format => 'i',  required => 1 );
    option 'p2' => ( is => 'ro', format => 'i@', required => 1 );

    1;
}

SKIP: {
    my $t = trap { MyTestWithConfig->new_with_options() };
    isa_ok( $t, "MyTestWithConfig" )
        or skip "MyTestWithConfig Instantiation failure", 4;
    is $t->p1, 1, 'p1 fetch from config';
    is_deeply $t->p2, [ 1, 2, 3 ], '... and also p2';
    ok $t->can('config_prefix'), '... config prefix defined';
    ok $t->can('config_dirs'),   '... config dirs defined';
    ok $t->can('config_files'),  '... config files defined';
}

SKIP: {
    local @ARGV = ( '--config_prefix', '25-with_config_2.t' );
    my $t = trap { MyTestWithConfig->new_with_options() };
    isa_ok( $t, "MyTestWithConfig" )
        or skip "MyTestWithConfig Instantiation failure", 2;
    is $t->p1, 2, 'p1 fetch from config';
    is_deeply $t->p2, [ 3, 4, 5 ], '... and also p2';
}

SKIP: {
    local @ARGV = ( '--p1', '2' );
    my $t = trap { MyTestWithConfig->new_with_options() };
    isa_ok( $t, "MyTestWithConfig" )
        or skip "MyTestWithConfig Instantiation failure", 2;
    is $t->p1, 2, 'p1 fetch from cmdline';
    is_deeply $t->p2, [ 1, 2, 3 ], '... and p2 from config';
}

SKIP: {
    local @ARGV = ( '--p1', '2' );
    my $t = trap { MyTestWithConfig->new_with_options( p1 => 3 ) };
    isa_ok( $t, "MyTestWithConfig" )
        or skip "MyTestWithConfig Instantiation failure", 2;
    is $t->p1, 3, 'p1 fetch from params';
    is_deeply $t->p2, [ 1, 2, 3 ], '... and p2 from config';
}

eval <<EOF
    package MyTestWithConfigRole;
    use Moo::Role;
    use MooX::Options with_config_from_file => 1;

    option 'p1' => (is => 'ro', format => 'i', required => 1);
    option 'p2' => (is => 'ro', format => 'i\@', required => 1);

    1;
EOF
    ;
like $@,
    qr/\QPlease, don't use the option <with_config_from_file> into a role.\E/x,
    'error when try to include with_config_from_file into a role';

eval <<EOF
    package MyTestWithConfigFail;
    use Moo;
    use MooX::Options with_config_from_file => 1;

    option 'p1' => (is => 'ro', format => 'i', required => 1);
    option 'p2' => (is => 'ro', format => 'i\@', required => 1);
    option 'config_files' => (is => 'ro');

    1;
EOF
    ;
like $@,
    qr/\QYou cannot use an option with the name 'config_files', it is implied by MooX::Options\E/x,
    'keywords when we use config is bannish';
eval <<EOF
    package MyTestWithConfigSuccess;
    use Moo;
    use MooX::Options with_config_from_file => 0;

    option 'p1' => (is => 'ro', format => 'i', required => 1);
    option 'p2' => (is => 'ro', format => 'i\@', required => 1);
    option 'config_files' => (is => 'ro');

    1;
EOF
    ;
ok !$@, '... and not without the config option';

done_testing;
