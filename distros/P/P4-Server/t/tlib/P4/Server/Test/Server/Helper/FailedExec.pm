package P4::Server::Test::Server::Helper::FailedExec;

use base qw( P4::Server );

use Class::Std;

{

sub _spawn_p4d : PROTECTED {
    die "open3: Fake exception from " . __PACKAGE__;
}

}

1;
