# ==============================================================================
# $Id: 02-new.t 17 2006-09-18 20:29:37Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Module Extended Test of Module::Versions
# ==============================================================================

  # Before `make install' is performed this script should be runnable with
  # `make test'. After `make install' it should work as `perl Module-Versions.t'

#########################

    # -- Module Extended Test 'new'
    #    Module::Versions

    #use Test::More 'no_plan';
    use Test::More tests => 22;
    BEGIN { use_ok('Module::Versions') }

#########################

    # -- No parameter, default
    ok( ref new Module::Versions,    'new Module::Versions' );
    ok( ref Module::Versions::new(), 'Module::Versions::new()' );
    ok( ref Module::Versions->new,   'Module::Versions->new' );

    # -- Parameter, single
    ok( ref new Module::Versions 'module', 'new Module::Versions \'module\'' );
    ok( ref Module::Versions::new('module'),
        'Module::Versions::new(\'module\')'
    );
    ok( ref Module::Versions->new('module'),
        'Module::Versions->new(\'module\')'
    );

    # -- Parameter, mixed
    ok( ref new Module::Versions [ 'm1', 'm2' ],
        'new Module::Versions [\'m1\',\'m2\']'
    );
    ok( ref Module::Versions::new( [ 'm1', 'm2' ] ),
        'Module::Versions::new([\'m1\',\'m2\'])'
    );
    ok( ref Module::Versions->new( [ 'm1', 'm2' ] ),
        'Module::Versions->new([\'m1\',\'m2\'])'
    );

    ok( ref new Module::Versions( 'module', 'var' ),
        'new Module::Versions ( \'module\', \'var\' )'
    );
    ok( ref Module::Versions::new( 'module', 'var' ),
        'Module::Versions::new( \'module\', \'var\' )'
    );
    ok( ref Module::Versions->new( 'module', 'var' ),
        'Module::Versions->new( \'module\', \'var\' )'
    );

    ok( ref new Module::Versions( [ 'm1', 'm2' ], 'var' ),
        'new Module::Versions ( [\'m1\',\'m2\'], \'var\' )'
    );
    ok( ref Module::Versions::new( [ 'm1', 'm2' ], 'var' ),
        'Module::Versions::new( [\'m1\',\'m2\'], \'var\' )'
    );
    ok( ref Module::Versions->new( [ 'm1', 'm2' ], 'var' ),
        'Module::Versions->new( [\'m1\',\'m2\'], \'var\' )'
    );

    ok( ref new Module::Versions( 'module', [ 'v1', 'v2' ] ),
        'new Module::Versions ( \'module\', [\'v1\',\'v2\'] )'
    );
    ok( ref Module::Versions::new( 'module', [ 'v1', 'v2' ] ),
        'Module::Versions::new( \'module\', [\'v1\',\'v2\'] )'
    );
    ok( ref Module::Versions->new( 'module', [ 'v1', 'v2' ] ),
        'Module::Versions->new( \'module\', [\'v1\',\'v2\'] )'
    );

    ok( ref new Module::Versions( [ 'm1', 'm2' ], [ 'v1', 'v2' ] ),
        'new Module::Versions ( [\'m1\',\'m2\'], [\'v1\',\'v2\'] )'
    );
    ok( ref Module::Versions::new( [ 'm1', 'm2' ], [ 'v1', 'v2' ] ),
        'Module::Versions::new( [\'m1\',\'m2\'], [\'v1\',\'v2\'] )'
    );
    ok( ref Module::Versions->new( [ 'm1', 'm2' ], [ 'v1', 'v2' ] ),
        'Module::Versions->new( [\'m1\',\'m2\'], [\'v1\',\'v2\'] )'
    );

#########################
