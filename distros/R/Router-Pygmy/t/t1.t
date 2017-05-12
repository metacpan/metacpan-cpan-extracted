use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('Router::Pygmy');

sub new_router {
    Router::Pygmy->new(@_);
}

{
    my $router = new_router;
    $router->add_route( 'basic', 'x.name' );
    throws_ok {
        $router->add_route( 'basic/:id', 'x.name'  );
    }
    qr{^\QDuplicit routes for 'x.name' ('basic', 'basic/:id')},
      "No routes with same name";

    $router->add_route( 'basic/:id', 'x.entity' );
    throws_ok {
        $router->add_route( 'basic/:z', 'x.entity' );
    }
    qr{^\QDuplicit routes for 'x.entity' ('basic/:id', 'basic/:z')},
      "Duplicit routes";

    $router->add_route( 'tree/:species/branches',    'tree.branches' );
    $router->add_route( 'tree/:species/:branch',     'tree.branch' );
    $router->add_route( 'tree/:species/:branch/nut', 'tree.nut' );

    is_deeply(
        [ $router->match('tree/oak/branches') ],
        [ 'tree.branches', ['oak'] ],
    );
    is_deeply(
        [ $router->match_named('tree/oak/branches') ],
        [ 'tree.branches', [species=>'oak'] ],
    );
    is_deeply(
        [ $router->match('tree/oak/12') ],
        [ 'tree.branch', [ 'oak', 12 ] ],
    );
    is_deeply(
        [ $router->match_named('tree/oak/12') ],
        [ 'tree.branch', [ species=> 'oak', branch => 12 ] ],
    );
    is_deeply( [ $router->match('tree/oak/12/ut') ], [], );

    # branches cannot serve as a value for :branch parameter
    is_deeply( [ $router->match('tree/oak/branches/nut') ], [], );

    is( $router->path_for( 'tree.branches', 'ash' ), 'tree/ash/branches' );
    is( $router->path_for( 'tree.branches', { species => 'ash' } ),
        'tree/ash/branches' );

    is( $router->path_for( 'tree.branches', ['ash'] ), 'tree/ash/branches' );

    throws_ok {
        $router->path_for( 'tree.branches', { pecies => 'ash' } );
    }
qr{^\QInvalid args for route 'tree/:species/branches', got ('pecies') expected ('species')};

    throws_ok {
        $router->path_for( 'tree.branches',
            { species => 'ash', area => 'palearctic' } );
    }
qr{^\QInvalid args for route 'tree/:species/branches', got ('area', 'species') expected ('species')};

    throws_ok {
        $router->path_for( 'tree.branches', [] );
    }
qr{^\QInvalid arg count for route 'tree/:species/branches', got 0 args, expected 1};

    throws_ok {
        $router->path_for( 'tree.branches', [ 'ash', 'platanus' ] );
    }
qr{^\QInvalid arg count for route 'tree/:species/branches', got 2 args, expected 1},
	'too many named args';

    is( $router->path_for( 'tree.branch', [ 'acer', 23 ] ),
        'tree/acer/23', 'two args positionally' );

    is(
        $router->path_for( 'tree.branch', { species => 'acer', branch => 12 } ),
        'tree/acer/12',
        'two args by name'
    );
    throws_ok {
        $router->path_for( 'tree.branch', { species => 'ash' } );
    }
qr{^\QInvalid args for route 'tree/:species/:branch', got ('species') expected ('species', 'branch')},
      'missing named arg';

    throws_ok {
        $router->path_for( 'tree.branch',
            { species => 'ash', branch => '17', xyz => 2 } );
    }
qr{^\QInvalid args for route 'tree/:species/:branch', got ('branch', 'species', 'xyz') expected ('species', 'branch')},
      'too many named args';

    throws_ok {
        $router->path_for( 'tree.branch', ['ash'] );
    }
qr{^\QInvalid arg count for route 'tree/:species/:branch', got 1 args, expected 2},
	'missing positional arg';

    throws_ok {
        $router->path_for( 'tree.branch', [ 'ash', 12, 3 ] );
    }
qr{^\QInvalid arg count for route 'tree/:species/:branch', got 3 args, expected 2},
	'too many positional args';

    throws_ok {
        $router->path_for( 'tree.root', [ 'ash', 12, 3 ] );
    } qr{^\QNo route 'tree.root'},
    'unknown route';
}

# constructor args
{
    my $router = new_router(
        routes => {
            'tree/:species/branches'    => 'tree.branches',
            'tree/:species/:branch'     => 'tree.branch',
            'tree/:species/:branch/nut' => 'tree.nut'
        }
    );

    is_deeply(
        [ $router->match('tree/oak/branches') ],
        [ 'tree.branches', ['oak'] ],
        'routes could be supplied as key => value too',
    );
}

{
    my $router = new_router({
        routes => {
            'tree/:species/branches'    => 'tree.branches',
            'tree/:species/:branch'     => 'tree.branch',
            'tree/:species/:branch/nut' => 'tree.nut'
        }
    });

    is_deeply(
        [ $router->match('tree/oak/branches') ],
        [ 'tree.branches', ['oak'] ],
        'routes could be supplied as \%args too',
    );
}

done_testing();

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 
