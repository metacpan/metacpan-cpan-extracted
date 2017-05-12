package Test::Cmd::DirWithTraits;

use Moose;

with 'MooseX::Role::Cmd';

has 'b'         => ( traits => [ 'CmdOpt' ], isa => 'Bool', is => 'rw' );
has 'bool'      => ( traits => [ 'CmdOpt' ], isa => 'Bool', is => 'rw' );
has 'v'         => ( traits => [ 'CmdOpt' ], isa => 'Str',  is => 'rw' );
has 'value'     => ( traits => [ 'CmdOpt' ], isa => 'Str',  is => 'rw' );
has 's'         => ( traits => [ 'CmdOpt' ], isa => 'Str',  is => 'rw', cmdopt_prefix => '-' );
has 'short'     => ( traits => [ 'CmdOpt' ], isa => 'Str',  is => 'rw', cmdopt_prefix => '-' );
has 'r'         => ( traits => [ 'CmdOpt' ], isa => 'Bool', is => 'rw', cmdopt_name   => '-a' );
has 'rename'    => ( traits => [ 'CmdOpt' ], isa => 'Bool', is => 'rw', cmdopt_name   => '+alt_name' );
has 'u'         => ( traits => [ 'CmdOpt' ], isa => 'Bool', is => 'rw' );
has 'undef'     => ( traits => [ 'CmdOpt' ], isa => 'Bool', is => 'rw' );
has 'undef_str' => ( traits => [ 'CmdOpt' ], isa => 'Str',  is => 'rw' );

has 'env_test'  => ( traits => [ 'CmdOpt' ], isa => 'Str',  is => 'rw', cmdopt_env => 'ENV_TEST_KEY' );

sub build_bin_name { 'dir' };

1;
