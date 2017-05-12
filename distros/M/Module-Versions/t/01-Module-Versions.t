# ==============================================================================
# $Id: 01-Module-Versions.t 17 2006-09-18 20:29:37Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Module Basic Test of Module::Versions
# ==============================================================================

  # Before `make install' is performed this script should be runnable with
  # `make test'. After `make install' it should work as `perl Module-Versions.t'

#########################

    # -- Module Basic Test
    #    Module::Versions

    #use Test::More 'no_plan';
    use Test::More tests => 24;
    BEGIN { use_ok('Module::Versions') }

#########################

    # -- Constructor, no parameter, default
    ok( ref new Module::Versions,    'new Module::Versions' );
    ok( ref Module::Versions->new,   'Module::Versions->new' );
    ok( ref Module::Versions::new(), 'Module::Versions::new()' );

    # -- Methods, no parameter, default
    ok( ref get Module::Versions,   'get Module::Versions' );
    ok( ref Module::Versions->get,  'Module::Versions->get' );
    ok( ref list Module::Versions,  'list Module::Versions' );
    ok( ref Module::Versions->list, 'Module::Versions->list' );
    ok( data Module::Versions,      'data Module::Versions' );
    ok( Module::Versions->data,     'Module::Versions->data' );
    ok( ARRAY Module::Versions,     'ARRAY Module::Versions' );
    ok( Module::Versions->ARRAY,    'Module::Versions->ARRAY' );
    ok( HASH Module::Versions,      'HASH Module::Versions' );
    ok( Module::Versions->HASH,     'Module::Versions->HASH' );
    ok( SCALAR Module::Versions,    'SCALAR Module::Versions' );
    ok( Module::Versions->SCALAR,   'Module::Versions->SCALAR' );
    ok( CSV Module::Versions,       'CSV Module::Versions' );
    ok( Module::Versions->CSV,      'Module::Versions->CSV' );
    ok( XML Module::Versions,       'XML Module::Versions' );
    ok( Module::Versions->XML,      'Module::Versions->XML' );
    ok( XSD Module::Versions,       'XSD Module::Versions' );
    ok( Module::Versions->XSD,      'Module::Versions->XSD' );
    ok( DTD Module::Versions,       'DTD Module::Versions' );
    ok( Module::Versions->DTD,      'Module::Versions->DTD' );

#########################
