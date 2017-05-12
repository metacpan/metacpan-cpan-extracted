use Test::More;
use OS::Package::System;
use Config;
use POSIX qw( uname );

my @uname = uname();

my $system =
    OS::Package::System->new();

isa_ok( $system, 'OS::Package::System' );

is( $system->os,  $Config{osname}, 'os name matches $Config{osname}'  );
is( $system->version, $uname[2], 'system version matches $uname[2]' );
is( $system->type, $uname[4], 'system type match $uname[4]' );


done_testing;
