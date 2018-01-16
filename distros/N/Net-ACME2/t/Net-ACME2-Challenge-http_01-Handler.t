use strict;
use warnings;
use autodie;

use Test::More tests => 1 + 3;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use File::Spec ();
use File::Slurp ();
use File::Temp ();

use Net::ACME2::Challenge::http_01 ();

use Net::ACME2::Challenge::http_01::Handler ();

#----------------------------------------------------------------------

my $challenge = Net::ACME2::Challenge::http_01->new(
    token => 'my_token',
);

my $docroot = File::Temp::tempdir( CLEANUP => 1 );

my $fs_path;

{
    my $handler = $challenge->create_handler( 'my_key_authz', $docroot );

    $fs_path = File::Spec->catdir( $docroot, $challenge->path() );

    ok(
        ( -e $fs_path ),
        'challenge path is created',
    );

    my $contents = File::Slurp::read_file($fs_path);

    is(
        $contents,
        'my_key_authz',
        '… and the contents match expectations',
    );
}

ok(
    !( -e $fs_path ),
    'challenge path is removed on DESTROY',
);

#This ensures that there’s no warning or error otherwise
#if the file goes away prematurely.
{
    my $handler = $challenge->create_handler( 'my_key_authz', $docroot );

    my $fs_path = File::Spec->catdir( $docroot, $challenge->path() );

    unlink $fs_path;
}
