# ==============================================================================
# $Id: 06-preform.t 17 2006-09-18 20:29:37Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Module Extended Test of Module::Versions
# ==============================================================================

  # Before `make install' is performed this script should be runnable with
  # `make test'. After `make install' it should work as `perl Module-Versions.t'

#########################

    # -- Module Extended Test 'preform'
    #    Module::Versions

    #use Test::More 'no_plan';
    use Test::More tests => 15;
    BEGIN { use_ok('Module::Versions') }

#########################

    # -- ARRAY
    ok( ARRAY Module::Versions, 'ARRAY Module::Versions' );
    ok( Module::Versions->ARRAY, 'Module::Versions->ARRAY' );

    # -- HASH
    ok( HASH Module::Versions, 'HASH Module::Versions' );
    ok( Module::Versions->HASH, 'Module::Versions->HASH' );

    # -- SCALAR
    ok( SCALAR Module::Versions, 'SCALAR Module::Versions' );
    ok( Module::Versions->SCALAR, 'Module::Versions->SCALAR' );

    # -- CSV
    ok( CSV Module::Versions, 'CSV Module::Versions' );
    ok( Module::Versions->CSV, 'Module::Versions->CSV' );

    # -- XML, XSD, DTD
    ok( XML Module::Versions,  'XML Module::Versions' );
    ok( Module::Versions->XML, 'Module::Versions->XML' );
    ok( XSD Module::Versions,  'XSD Module::Versions' );
    ok( Module::Versions->XSD, 'Module::Versions->XSD' );
    ok( DTD Module::Versions,  'DTD Module::Versions' );
    ok( Module::Versions->DTD, 'Module::Versions->DTD' );

#########################
