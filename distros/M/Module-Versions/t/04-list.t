# ==============================================================================
# $Id: 04-list.t 17 2006-09-18 20:29:37Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Module Extended Test of Module::Versions
# ==============================================================================

  # Before `make install' is performed this script should be runnable with
  # `make test'. After `make install' it should work as `perl Module-Versions.t'

#########################

    # -- Module Extended Test 'list'
    #    Module::Versions

    #use Test::More 'no_plan';
    use Test::More tests => 35;
    BEGIN { use_ok('Module::Versions') }

#########################

    # -- Test output file
    $^O eq 'Win32' ? open LOG, "> NUL" : open LOG, "> /dev/null";
    *STDOUT = *LOG;    # avoid dubious results during test modus

    # -- No parameter, default
    ok( ref list Module::Versions, 'list Module::Versions' );
    ok( ref Module::Versions->list, 'Module::Versions->list' );

    # -- Parameter
    ok( ref list Module::Versions * LOG,   'list Module::Versions *LOG' );
    ok( ref Module::Versions->list(*LOG),  'Module::Versions->list(*LOG)' );
    ok( ref list Module::Versions undef,   'list Module::Versions undef' );
    ok( ref Module::Versions->list(undef), 'Module::Versions->list(undef)' );

    ok( ref list Module::Versions( *LOG, '%d %s %s %s %s' ),
        'list Module::Versions( *LOG,\'%d %s %s %s %s\')'
    );
    ok( ref Module::Versions->list( *LOG, '%d %s %s %s %s' ),
        'Module::Versions->list( *LOG,\'%d %s %s %s %s\')'
    );
    ok( ref list Module::Versions( undef, '%d %s %s %s %s' ),
        'list Module::Versions( undef,\'%d %s %s %s %s\')'
    );
    ok( ref Module::Versions->list( undef, '%d %s %s %s %s' ),
        'Module::Versions->list( undef,\'%d %s %s %s %s\')'
    );

    # -- Parameter, pre-form
    ok( ref list Module::Versions( *LOG, 'ARRAY' ),
        'list Module::Versions( *LOG,\'ARRAY\')'
    );
    ok( ref Module::Versions->list( *LOG, 'ARRAY' ),
        'Module::Versions->list( *LOG,\'ARRAY\')'
    );
    ok( ref list Module::Versions( undef, 'ARRAY' ),
        'list Module::Versions( undef,\'ARRAY\')'
    );
    ok( ref Module::Versions->list( undef, 'ARRAY' ),
        'Module::Versions->list( undef,\'ARRAY\')'
    );

    ok( ref list Module::Versions( *LOG, 'HASH' ),
        'list Module::Versions( *LOG,\'HASH\')'
    );
    ok( ref Module::Versions->list( *LOG, 'HASH' ),
        'Module::Versions->list( *LOG,\'HASH\')'
    );
    ok( ref list Module::Versions( undef, 'HASH' ),
        'list Module::Versions( undef,\'HASH\')'
    );
    ok( ref Module::Versions->list( undef, 'HASH' ),
        'Module::Versions->list( undef,\'HASH\')'
    );

    ok( ref list Module::Versions( *LOG, 'SCALAR' ),
        'list Module::Versions( *LOG,\'SCALAR\')'
    );
    ok( ref Module::Versions->list( *LOG, 'SCALAR' ),
        'Module::Versions->list( *LOG,\'SCALAR\')'
    );
    ok( ref list Module::Versions( undef, 'SCALAR' ),
        'list Module::Versions( undef,\'SCALAR\')'
    );
    ok( ref Module::Versions->list( undef, 'SCALAR' ),
        'Module::Versions->list( undef,\'SCALAR\')'
    );

    ok( ref list Module::Versions( *LOG, 'CSV' ),
        'list Module::Versions( *LOG,\'CSV\')'
    );
    ok( ref Module::Versions->list( *LOG, 'CSV' ),
        'Module::Versions->list( *LOG,\'CSV\')'
    );
    ok( ref list Module::Versions( undef, 'CSV' ),
        'list Module::Versions( undef,\'CSV\')'
    );
    ok( ref Module::Versions->list( undef, 'CSV' ),
        'Module::Versions->list( undef,\'CSV\')'
    );

    ok( ref list Module::Versions( *LOG, 'XML' ),
        'list Module::Versions( *LOG,\'XML\')'
    );
    ok( ref Module::Versions->list( *LOG, 'XML' ),
        'Module::Versions->list( *LOG,\'XML\')'
    );
    ok( ref list Module::Versions( undef, 'XML' ),
        'list Module::Versions( undef,\'XML\')'
    );
    ok( ref Module::Versions->list( undef, 'XML' ),
        'Module::Versions->list( undef,\'XML\')'
    );

    # -- Parameter, ballback
    ok( ref list Module::Versions( *LOG, \&test ),
        'list Module::Versions (*LOG,\&test)'
    );
    ok( ref Module::Versions->list( *LOG, \&test ),
        'Module::Versions->list(*LOG,\&test)'
    );
    ok( ref list Module::Versions( undef, \&test ),
        'list Module::Versions (undef,\&test)'
    );
    ok( ref Module::Versions->list( undef, \&test ),
        'Module::Versions->list(undef,\&test)'
    );

    # -- Test callback routine
    sub test { $_[1] }

#########################
