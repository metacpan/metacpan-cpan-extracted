package P4::Server::Test::Server::Helper::ExtractFails;

use base qw( P4::Server );

use Class::Std;

{

sub _extract_archive : PROTECTED {
    return ( 0, 'Error injected from ' . __PACKAGE__, [] );
}

}

1;
