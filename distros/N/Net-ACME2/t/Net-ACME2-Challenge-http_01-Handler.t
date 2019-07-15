use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;
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

{
    my $authz = bless [], 'Mock::Authz';

    my $handler = $challenge->create_handler( $authz, $docroot );

    my $contents = File::Slurp::read_file($fs_path);

    is(
        $contents,
        'my_object_key_authz',
        'create_handler() does the right thing with an authz object',
    );
}

#This ensures that there’s no warning or error otherwise
#if the file goes away prematurely.
{
    my $handler = $challenge->create_handler( 'my_key_authz', $docroot );

    my $fs_path = File::Spec->catdir( $docroot, $challenge->path() );

    unlink $fs_path;
}

done_testing();

#----------------------------------------------------------------------

package Mock::Authz;

use Test::More;

sub make_key_authorization {
    my ($self, $challenge) = @_;

    isa_ok( $challenge, 'Net::ACME2::Challenge::http_01', 'challenge given to make_key_authorization()');

    return 'my_object_key_authz';
}
