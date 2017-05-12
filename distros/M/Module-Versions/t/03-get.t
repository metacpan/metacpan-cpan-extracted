# ==============================================================================
# $Id: 03-get.t 17 2006-09-18 20:29:37Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Module Extended Test of Module::Versions
# ==============================================================================

  # Before `make install' is performed this script should be runnable with
  # `make test'. After `make install' it should work as `perl Module-Versions.t'

#########################

    # -- Module Extended Test 'get'
    #    Module::Versions

    #use Test::More 'no_plan';
    use Test::More tests => 30;
    BEGIN { use_ok('Module::Versions') }

#########################

    # -- No parameter, default
    ok( ref get Module::Versions, 'get Module::Versions' );
    ok( ref Module::Versions->get, 'Module::Versions->get' );

    # -- Parameter, single
    ok( ref get Module::Versions 'oldver', 'get Module::Versions \'oldver\'' );
    ok( ref Module::Versions->get('oldver'),
        'Module::Versions->get(\'oldver\')'
    );
    ok( ref get Module::Versions 'notme', 'get Module::Versions \'notme\'' );
    ok( ref Module::Versions->get('notme'),
        'Module::Versions->get(\'notme\')' );
    ok( ref get Module::Versions 'all', 'get Module::Versions \'all\'' );
    ok( ref Module::Versions->get('all'), 'Module::Versions->get(\'all\')' );
    ok( ref get Module::Versions 'version',
        'get Module::Versions \'version\'' );
    ok( ref Module::Versions->get('version'),
        'Module::Versions->get(\'version\')'
    );

    ok( ref get Module::Versions ['oldver'],
        'get Module::Versions [\'oldver\']'
    );
    ok( ref Module::Versions->get( ['oldver'] ),
        'Module::Versions->get([\'oldver\'])'
    );
    ok( ref get Module::Versions ['notme'],
        'get Module::Versions [\'notme\']' );
    ok( ref Module::Versions->get( ['notme'] ),
        'Module::Versions->get([\'notme\'])'
    );
    ok( ref get Module::Versions ['all'], 'get Module::Versions [\'all\']' );
    ok( ref Module::Versions->get( ['all'] ),
        'Module::Versions->get([\'all\'])'
    );
    ok( ref get Module::Versions ['version'],
        'get Module::Versions [\'version\']'
    );
    ok( ref Module::Versions->get( ['version'] ),
        'Module::Versions->get([\'version\'])'
    );

    # -- Parameter, mixed
    ok( ref get Module::Versions [ 'oldver', 'notme' ],
        'get Module::Versions [\'oldver\',\'notme\']'
    );
    ok( ref get Module::Versions [ 'oldver', 'all' ],
        'get Module::Versions [\'oldver\',\'all\']'
    );
    ok( ref get Module::Versions [ 'oldver', 'version' ],
        'get Module::Versions [\'oldver\',\'version\']'
    );
    ok( ref Module::Versions::new( [ 'notme', 'all' ] ),
        'Module::Versions::new([\'notme\',\'all\'])'
    );
    ok( ref Module::Versions::new( [ 'notme', 'version' ] ),
        'Module::Versions::new([\'notme\',\'version\'])'
    );
    ok( ref Module::Versions->new( [ 'all', 'version' ] ),
        'Module::Versions->new([\'all\',\'version\'])'
    );

    ok( ref Module::Versions->new( [ 'oldver', 'notme', 'all' ] ),
        'Module::Versions->new([\'oldver\',\'version\',\'all\'])'
    );
    ok( ref Module::Versions->new( [ 'oldver', 'all', 'version' ] ),
        'Module::Versions->new([\'oldver\',\'all\',\'version\'])'
    );
    ok( ref Module::Versions->new( [ 'oldver', 'notme', 'version' ] ),
        'Module::Versions->new([\'oldver\',\'notme\',\'version\'])'
    );
    ok( ref Module::Versions->new( [ 'notme', 'all', 'version' ] ),
        'Module::Versions->new([\'notme\',\'all\',\'version\'])'
    );

    ok( ref new Module::Versions( [ 'oldver', 'notme', 'all', 'version' ] ),
        'new Module::Versions ( [\'oldver\', \'notme\', \'all\'], \'version\' )'
    );

#########################
