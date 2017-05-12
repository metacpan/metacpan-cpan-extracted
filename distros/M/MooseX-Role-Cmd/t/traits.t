use strict;
use warnings;

use Test::More tests => 10;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    use_ok( 'MooseX::Role::Cmd::Meta::Attribute::Trait' );
    use_ok( 'Test::Cmd::Dir' );
    use_ok( 'Test::Cmd::DirWithTraits' );
}

my $cmd;
my @expected_args;
my @cmd_args;

my %args = (
    'b'         => 1, 
    'bool'      => 1, 
    'v'         => 'foo_v', 
    'value'     => 'foo_value', 
    's'         => 'foo_s',
    'short'     => 'foo_short',
    'r'         => 1,
    'rename'    => 1,
);


# without traits
isa_ok( $cmd  = Test::Cmd::Dir->new( %args ), 'Test::Cmd::Dir' );

is( $cmd->bin_name, 'dir' );

use Data::Dumper;

@expected_args = sort qw( -b --bool -v foo_v --value foo_value -s foo_s --short foo_short -r --rename );

@cmd_args = sort $cmd->cmd_args();

# warn "GOT: "     .Dumper( \@cmd_args );
# warn "EXPECTED: ".Dumper( \@expected_args );

is_deeply( \@cmd_args, \@expected_args, 'args look OK' );

# with traits
isa_ok( $cmd = Test::Cmd::DirWithTraits->new( %args, env_test => 'test_value' ), 'Test::Cmd::DirWithTraits' );

is( $cmd->bin_name, 'dir' );

@expected_args = sort qw( -b --bool -v foo_v --value foo_value -s foo_s -short foo_short -a +alt_name );

@cmd_args = sort $cmd->cmd_args();

# warn "GOT: "     .Dumper( \@cmd_args );
# warn "EXPECTED: ".Dumper( \@expected_args );

is ($ENV{'ENV_TEST_KEY'}, 'test_value', 'check cmdopt_env' );

is_deeply( \@cmd_args, \@expected_args, 'trait args look OK' );

