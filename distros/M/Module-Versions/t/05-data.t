# ==============================================================================
# $Id: 05-data.t 11 2006-09-17 19:04:25Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Module Extended Test of Module::Versions
# ==============================================================================

  # Before `make install' is performed this script should be runnable with
  # `make test'. After `make install' it should work as `perl Module-Versions.t'

#########################

    # -- Module Extended Test 'data'
    #    Module::Versions

    #use Test::More 'no_plan';
    use Test::More tests => 5;
    BEGIN { use_ok('Module::Versions') }

#########################

    # -- No parameter, default
    ok( data Module::Versions, 'data Module::Versions' );
    ok( Module::Versions->data, 'Module::Versions->data' );

    # -- Parameter, callback
    ok( data Module::Versions \&test, 'data Module::Versions  \&test' );
    ok( Module::Versions->data( \&test ), 'Module::Versions->data( \&test)' );

    # -- Test callback routine
    sub test { $_[1] }

#########################
