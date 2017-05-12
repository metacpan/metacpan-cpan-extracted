#!perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use t::Test;
use Test::Trap;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

{

    package MyTestWithConfig;
    use Moo;
    use MooX::Options with_config_from_file => 1;

    option 'p1' => ( is => 'ro', format => 'i',  required => 1 );
    option 'p2' => ( is => 'ro', format => 'i@', required => 1 );

    1;
}

my $t = MyTestWithConfig->new_with_options();
is $t->p1, 1, 'p1 fetch from config';
is_deeply $t->p2, [ 1, 2, 3 ], '... and also p2';
ok $t->can('config_prefix'), '... config prefix defined';
ok $t->can('config_dirs'),   '... config dirs defined';
ok $t->can('config_files'),  '... config files defined';

{
    local @ARGV = ( '--config_prefix', 'with_config_2.t' );
    my $t = MyTestWithConfig->new_with_options();
    is $t->p1, 2, 'p1 fetch from config';
    is_deeply $t->p2, [ 3, 4, 5 ], '... and also p2';
}

{
    local @ARGV = ( '--p1', '2' );
    my $t = MyTestWithConfig->new_with_options();
    is $t->p1, 2, 'p1 fetch from cmdline';
    is_deeply $t->p2, [ 1, 2, 3 ], '... and p2 from config';
}

{
    local @ARGV = ( '--p1', '2' );
    my $t = MyTestWithConfig->new_with_options( p1 => 3 );
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
