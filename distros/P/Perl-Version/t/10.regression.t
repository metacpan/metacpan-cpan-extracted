#!/usr/bin/perl

use strict;
use warnings;
use Perl::Version;
use Data::Dumper;

my @tests;

BEGIN {
  @tests = (

    # Tests that peform no modification - just check that the components
    # have the correct values
    {
      name        => 'Single component',
      new_arg     => '1',
      components  => 1,
      component_0 => 1,
      component_1 => undef,
      alpha       => 0,
      normal      => 'v1.0.0',
      numify      => '1.000',
    },
    {
      name        => 'Two components',
      new_arg     => '1.2',
      components  => 2,
      component_0 => 1,
      component_1 => 2,
      component_2 => undef,
      alpha       => 0,
      normal      => 'v1.2.0',
      numify      => '1.002',
    },
    {
      name        => 'Three components',
      new_arg     => '1.2.3',
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 0,
      normal      => 'v1.2.3',
      numify      => '1.002003',
    },
    {
      name                 => 'Three components, named components',
      new_arg              => '1.2.3',
      components           => 3,
      component_revision   => 1,
      component_version    => 2,
      component_subversion => 3,
      component_3          => undef,
      alpha                => 0,
      normal               => 'v1.2.3',
      numify               => '1.002003',
    },
    {
      name        => 'Four components',
      new_arg     => '1.2.3.4',
      components  => 4,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => 4,
      component_4 => undef,
      alpha       => 0,
      normal      => 'v1.2.3.4',
      numify      => '1.002003004',
    },
    {
      name        => 'Perl style, three components',
      new_arg     => '1.002030',
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 30,
      component_3 => undef,
      alpha       => 0,
      normal      => 'v1.2.30',
      numify      => '1.002030',
    },
    {
      name        => 'Single component, v prefix',
      new_arg     => 'v1',
      components  => 1,
      component_0 => 1,
      component_1 => undef,
      alpha       => 0,
      normal      => 'v1.0.0',
      numify      => '1.000',
    },
    {
      name        => 'Two components, v prefix',
      new_arg     => 'v1.2',
      components  => 2,
      component_0 => 1,
      component_1 => 2,
      component_2 => undef,
      alpha       => 0,
      normal      => 'v1.2.0',
      numify      => '1.002',
    },
    {
      name        => 'Three components, v prefix',
      new_arg     => 'v1.2.3',
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 0,
      normal      => 'v1.2.3',
      numify      => '1.002003',
    },
    {
      name        => 'Four components, v prefix',
      new_arg     => 'v1.2.3.4',
      components  => 4,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => 4,
      component_4 => undef,
      alpha       => 0,
      normal      => 'v1.2.3.4',
      numify      => '1.002003004',
    },
    {
      name        => 'Two components, alpha',
      new_arg     => '1.2_1',
      components  => 2,
      component_0 => 1,
      component_1 => 2,
      component_2 => undef,
      alpha       => 1,
      normal      => 'v1.2.0_01',
      numify      => '1.002_01',
    },
    {
      name        => 'Three components, alpha',
      new_arg     => '1.2.3_1',
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 1,
      normal      => 'v1.2.3_01',
      numify      => '1.002003_01',
    },
    {
      name        => 'Four components, alpha',
      new_arg     => '1.2.3.4_1',
      components  => 4,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => 4,
      component_4 => undef,
      alpha       => 1,
      normal      => 'v1.2.3.4_01',
      numify      => '1.002003004_01',
    },
    {
      name        => 'Two components, v prefix, alpha',
      new_arg     => 'v1.2_1',
      components  => 2,
      component_0 => 1,
      component_1 => 2,
      component_2 => undef,
      alpha       => 1,
      normal      => 'v1.2.0_01',
      numify      => '1.002_01',
    },
    {
      name        => 'Three components, v prefix, alpha',
      new_arg     => 'v1.2.3_1',
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 1,
      normal      => 'v1.2.3_01',
      numify      => '1.002003_01',
    },
    {
      name        => 'Four components, v prefix, alpha',
      new_arg     => 'v1.2.3.4_1',
      components  => 4,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => 4,
      component_4 => undef,
      alpha       => 1,
      normal      => 'v1.2.3.4_01',
      numify      => '1.002003004_01',
    },

    # Tests that modify various values
    {
      name    => 'Single component, modify it',
      new_arg => '1',
      action  => sub {
        $_->component( 0, 2 );
      },
      components  => 1,
      component_0 => 2,
      component_1 => undef,
      alpha       => 0,
      stringify   => '2',
      normal      => 'v2.0.0',
      numify      => '2.000',
    },
    {
      name    => 'Single component, add component',
      new_arg => '1',
      action  => sub {
        $_->component( 1, 2 );
      },
      components  => 2,
      component_0 => 1,
      component_1 => 2,
      component_2 => undef,
      alpha       => 0,
      stringify   => '1.2',
      normal      => 'v1.2.0',
      numify      => '1.002',
    },
    {
      name    => 'Single component, add gap, component',
      new_arg => '1',
      action  => sub {
        $_->component( 2, 2 );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 0,
      component_2 => 2,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.0.2',
      normal      => 'v1.0.2',
      numify      => '1.000002',
    },
    {
      name    => 'Single component, attempt to set components to 0',
      new_arg => '1',
      action  => sub {
        $_->components( 0 );
      },
      act_err     => { error => qr/set the number of components to 0/ },
      components  => 1,
      component_0 => 1,
      component_1 => undef,
      alpha       => 0,
      stringify   => '1',
      normal => 'v1.0.0',
      numify => '1.000',
    },
    {
      name    => 'Single component, attempt to set components to 1',
      new_arg => '1',
      action  => sub {
        $_->components( 1 );
      },
      components  => 1,
      component_0 => 1,
      component_1 => undef,
      alpha       => 0,
      stringify   => '1',
      normal      => 'v1.0.0',
      numify      => '1.000',
    },
    {
      name    => 'Two components, set components to 1',
      new_arg => '1.2',
      action  => sub {
        $_->components( 1 );
      },
      components  => 1,
      component_0 => 1,
      component_1 => undef,
      alpha       => 0,
      stringify   => '1',
      normal      => 'v1.0.0',
      numify      => '1.000',
    },
    {
      name    => 'Two components, set components to 3',
      new_arg => '1.2',
      action  => sub {
        $_->components( 3 );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 0,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.0',
      normal      => 'v1.2.0',
      numify      => '1.002000',
    },
    {
      name    => 'Three components, set alpha',
      new_arg => '1.2.3',
      action  => sub {
        $_->alpha( 4 );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 4,
      stringify   => '1.2.3_04',
      normal      => 'v1.2.3_04',
      numify      => '1.002003_04',
    },
    {
      name    => 'Three components, clear alpha',
      new_arg => '1.2.3_4',
      action  => sub {
        $_->alpha( 0 );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.3',
      normal      => 'v1.2.3',
      numify      => '1.002003',
    },
    {
      name    => 'Three components, inc revision',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 0 );
      },
      components  => 3,
      component_0 => 2,
      component_1 => 0,
      component_2 => 0,
      component_3 => undef,
      alpha       => 0,
      stringify   => '2.0.0',
      normal      => 'v2.0.0',
      numify      => '2.000000',
    },
    {
      name    => 'Three components, inc version',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 1 );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 3,
      component_2 => 0,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.3.0',
      normal      => 'v1.3.0',
      numify      => '1.003000',
    },
    {
      name    => 'Three components, inc subversion',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 2 );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 4,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.4',
      normal      => 'v1.2.4',
      numify      => '1.002004',
    },
    {
      name    => 'Three components, no alpha, inc alpha',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 'alpha' );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 1,
      stringify   => '1.2.3_01',
      normal      => 'v1.2.3_01',
      numify      => '1.002003_01',
    },
    {
      name    => 'Three components, no alpha, inc alpha (caps)',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 'AlphA' );
      },
      components      => 3,
      component_0     => 1,
      component_1     => 2,
      component_2     => 3,
      component_3     => undef,
      component_alpha => 1,
      stringify       => '1.2.3_01',
      normal          => 'v1.2.3_01',
      numify          => '1.002003_01',
    },
    {
      name    => 'Three components, alpha, inc alpha',
      new_arg => '1.2.3_4',
      action  => sub {
        $_->increment( 'alpha' );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 5,
      stringify   => '1.2.3_5',
      normal      => 'v1.2.3_05',
      numify      => '1.002003_05',
    },
    {
      name    => 'Two components, inc revision',
      new_arg => '1.2',
      action  => sub {
        $_->increment( 0 );
      },
      components  => 2,
      component_0 => 2,
      component_1 => 0,
      component_2 => undef,
      alpha       => 0,
      stringify   => '2.0',
      normal      => 'v2.0.0',
      numify      => '2.000',
    },
    {
      name    => 'Two components, inc version',
      new_arg => '1.2',
      action  => sub {
        $_->increment( 1 );
      },
      components  => 2,
      component_0 => 1,
      component_1 => 3,
      component_2 => undef,
      alpha       => 0,
      stringify   => '1.3',
      normal      => 'v1.3.0',
      numify      => '1.003',
    },
    {
      name    => 'Two components, inc alpha',
      new_arg => '1.2',
      action  => sub {
        $_->increment( 'alpha' );
      },
      components  => 2,
      component_0 => 1,
      component_1 => 2,
      component_2 => undef,
      alpha       => 1,
      stringify   => '1.2_01',
      normal      => 'v1.2.0_01',
      numify      => '1.002_01',
    },
    {
      name    => 'Three components, inc revision by name',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 'revision' );
      },
      components  => 3,
      component_0 => 2,
      component_1 => 0,
      component_2 => 0,
      component_3 => undef,
      alpha       => 0,
      stringify   => '2.0.0',
      normal      => 'v2.0.0',
      numify      => '2.000000',
    },
    {
      name    => 'Three components, inc revision by name (caps)',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 'Revision' );
      },
      components  => 3,
      component_0 => 2,
      component_1 => 0,
      component_2 => 0,
      component_3 => undef,
      alpha       => 0,
      stringify   => '2.0.0',
      normal      => 'v2.0.0',
      numify      => '2.000000',
    },
    {
      name    => 'Three components, inc version by name',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 'version' );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 3,
      component_2 => 0,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.3.0',
      normal      => 'v1.3.0',
      numify      => '1.003000',
    },
    {
      name    => 'Three components, inc subversion by name',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 'subversion' );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 4,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.4',
      normal      => 'v1.2.4',
      numify      => '1.002004',
    },
    {
      name    => 'Three components, inc subversion by name (caps)',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 'SuBversion' );
      },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 4,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.4',
      normal      => 'v1.2.4',
      numify      => '1.002004',
    },
    {
      name    => 'Three components, inc illegal name',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( 'major' );
      },
      act_err     => { error => qr/Unknown component name: major/ },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.3',
      normal      => 'v1.2.3',
      numify      => '1.002003',
    },
    {
      name    => 'Three components, negative index (-1)',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( -1 );
      },
      components      => 3,
      component_0     => 1,
      component_1     => 2,
      component_2     => 4,
      component_3     => undef,
      component_alpha => 0,
      stringify       => '1.2.4',
      normal          => 'v1.2.4',
      numify          => '1.002004',
    },
    {
      name    => 'Three components, negative index (-2)',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( -2 );
      },
      components      => 3,
      component_0     => 1,
      component_1     => 3,
      component_2     => 0,
      component_3     => undef,
      component_alpha => 0,
      stringify       => '1.3.0',
      normal          => 'v1.3.0',
      numify          => '1.003000',
    },
    {
      name    => 'Three components, negative index (-3)',
      new_arg => '1.2.3',
      action  => sub {
        $_->increment( -3 );
      },
      components      => 3,
      component_0     => 2,
      component_1     => 0,
      component_2     => 0,
      component_3     => undef,
      component_alpha => 0,
      stringify       => '2.0.0',
      normal          => 'v2.0.0',
      numify          => '2.000000',
    },
    {
      name    => 'Three components, negative index (-1)',
      new_arg => '1.2.3',
      action  => sub {
        $_->component( -1, 5 );
      },
      components      => 3,
      component_0     => 1,
      component_1     => 2,
      component_2     => 5,
      component_3     => undef,
      component_alpha => 0,
      stringify       => '1.2.5',
      normal          => 'v1.2.5',
      numify          => '1.002005',
    },
    {
      name    => 'Three components, set illegal name',
      new_arg => '1.2.3',
      action  => sub {
        $_->component( 'major', 99 );
      },
      act_err     => { error => qr/Unknown component name: major/ },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 3,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.3',
      normal      => 'v1.2.3',
      numify      => '1.002003',
    },
    {
      name        => 'Three components, named accessors',
      new_arg     => '1.2.3',
      components  => 3,
      revision    => 1,
      version     => 2,
      subversion  => 3,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.3',
      normal      => 'v1.2.3',
      numify      => '1.002003',
    },
    {
      name    => 'Three components, set revision by name',
      new_arg => '1.2.3',
      action  => sub {
        $_->revision( 2 );
      },
      components  => 3,
      revision    => 2,
      version     => 2,
      subversion  => 3,
      component_3 => undef,
      alpha       => 0,
      stringify   => '2.2.3',
      normal      => 'v2.2.3',
      numify      => '2.002003',
    },
    {
      name    => 'Three components, set version by name',
      new_arg => '1.2.3',
      action  => sub {
        $_->version( 3 );
      },
      components  => 3,
      revision    => 1,
      version     => 3,
      subversion  => 3,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.3.3',
      normal      => 'v1.3.3',
      numify      => '1.003003',
    },
    {
      name    => 'Three components, set subversion by name',
      new_arg => '1.2.3',
      action  => sub {
        $_->subversion( 4 );
      },
      components  => 3,
      revision    => 1,
      version     => 2,
      subversion  => 4,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.4',
      normal      => 'v1.2.4',
      numify      => '1.002004',
    },
    {
      name    => 'Three components, inc_revision',
      new_arg => '1.2.3',
      action  => sub {
        $_->inc_revision;
      },
      components  => 3,
      component_0 => 2,
      component_1 => 0,
      component_2 => 0,
      component_3 => undef,
      alpha       => 0,
      stringify   => '2.0.0',
      normal      => 'v2.0.0',
      numify      => '2.000000',
    },
    {
      name    => 'Three components, inc_version',
      new_arg => '1.2.3',
      action  => sub {
        $_->inc_version;
      },
      components  => 3,
      component_0 => 1,
      component_1 => 3,
      component_2 => 0,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.3.0',
      normal      => 'v1.3.0',
      numify      => '1.003000',
    },
    {
      name    => 'Numeric, inc_version',
      new_arg => '0.09',
      action  => sub {
        $_->inc_version;
      },
      components  => 2,
      component_0 => 0,
      component_1 => 10,
      component_2 => undef,
      component_3 => undef,
      alpha       => 0,
      stringify   => '0.10',
      normal      => 'v0.10.0',
      numify      => '0.010',
    },
    {
      name    => 'Numeric, inc_version (2)',
      new_arg => '0.19',
      action  => sub {
        $_->inc_version;
      },
      components  => 2,
      component_0 => 0,
      component_1 => 20,
      component_2 => undef,
      component_3 => undef,
      alpha       => 0,
      stringify   => '0.20',
      normal      => 'v0.20.0',
      numify      => '0.020',
    },
    {
      name    => 'Three components, inc_subversion',
      new_arg => '1.2.3',
      action  => sub {
        $_->inc_subversion;
      },
      components  => 3,
      component_0 => 1,
      component_1 => 2,
      component_2 => 4,
      component_3 => undef,
      alpha       => 0,
      stringify   => '1.2.4',
      normal      => 'v1.2.4',
      numify      => '1.002004',
    },

    # Various tests that the format preservation works as expected
    {
      name    => 'Three components, two digits, long alpha',
      new_arg => 'v1.02.34_00056',
      action  => sub {
        $_->inc_revision;
      },
      stringify => 'v2.00.00',
      normal    => 'v2.0.0',
      numify    => '2.000000',
    },
    {
      name    => 'Three components, eight digits, long alpha',
      new_arg => 'v1.00000002.00000034_00056',
      action  => sub {
        $_->inc_revision;
      },
      stringify => 'v2.00000000.00000000',
      normal    => 'v2.0.0',
      numify    => '2.000000',
    },
    {
      name    => 'Four components, two digits',
      new_arg => 'v1.23.45.00',
      action  => sub {
        $_->inc_revision;
      },
      stringify => 'v2.00.00.00',
      normal    => 'v2.0.0.0',
      numify    => '2.000000000',
    },
    {
      name =>
       'Three components, last padded to three digits, long alpha',
      new_arg => 'v1.2.034',
      action  => sub {
        $_->inc_revision;
      },
      stringify => 'v2.0.000',
      normal    => 'v2.0.0',
      numify    => '2.000000',
    },

    # Setting value
    {
      name =>
       'Three components, last padded to three digits, long alpha, set',
      new_arg => 'v1.2.034',
      action  => sub {
        $_->set( '2.0.0' );
      },
      stringify => 'v2.0.000',
      normal    => 'v2.0.0',
      numify    => '2.000000',
    },
    {
      name =>
       'Three components, last padded to three digits, long alpha, set to another version',
      new_arg => 'v1.2.034',
      action  => sub {
        $_->set( Perl::Version->new( '2.3.4' ) );
      },
      stringify => 'v2.3.004',
      normal    => 'v2.3.4',
      numify    => '2.003004',
    },

    # Misc formatting
    {
      name    => 'CVS revision',
      new_arg => 'Revision: 1.2.3',
      normal  => 'v1.2.3',
    },
    {
      name    => 'CVS revision, mixed case',
      new_arg => 'revisioN: 1.2.3',
      normal  => 'v1.2.3',
    },
    {
      name    => 'Leading spaces',
      new_arg => '   v1.2.3',
      numify  => '1.002003',
    },
    {
      name    => 'Trailing spaces',
      new_arg => 'v1.2.3   ',
      numify  => '1.002003',
    },
    {
      name    => 'Leading and trailing spaces',
      new_arg => '        v1.2.3   ',
      numify  => '1.002003',
    },
    {
      name    => 'CVS revision, increment',
      new_arg => 'Revision: 1.2.3',
      action  => sub {
        $_->inc_version;
      },
      stringify => 'Revision: 1.3.0',
    },
    {
      name    => 'Leading spaces, increment',
      new_arg => '   v1.2.3',
      action  => sub {
        $_->inc_version;
      },
      stringify => '   v1.3.0',
    },
    {
      name    => 'Trailing spaces, increment',
      new_arg => 'v1.2.3   ',
      action  => sub {
        $_->inc_version;
      },
      stringify => 'v1.3.0   ',
    },
    {
      name    => 'Leading and trailing spaces, increment',
      new_arg => '        v1.2.3   ',
      action  => sub {
        $_->inc_version;
      },
      stringify => '        v1.3.0   ',
    },

    # Some errors
    {
      name    => 'Trailing decimal',
      new_arg => '1.1.',
      new_err => { error => qr/Illegal version string/i },
    },

    # Versions used in documentation
    {
      name    => 'Round trip 1.3.0 OK',
      new_arg => '1.3.0'
    },
    {
      name    => 'Round trip v1.03.00 OK',
      new_arg => 'v1.03.00'
    },
    {
      name    => 'Round trip 1.10.03 OK',
      new_arg => '1.10.03'
    },
    {
      name    => 'Round trip 2.00.00 OK',
      new_arg => '2.00.00'
    },
    {
      name    => 'Round trip 1.2 OK',
      new_arg => '1.2'
    },
    {
      name    => 'Round trip v1.2.3.4.5.6 OK',
      new_arg => 'v1.2.3.4.5.6'
    },
    {
      name    => 'Round trip v1.2 OK',
      new_arg => 'v1.2'
    },
    {
      name    => 'Round trip Revision: 3.0 OK',
      new_arg => 'Revision: 3.0'
    },
    {
      name    => 'Round trip 1.001001 OK',
      new_arg => '1.001001'
    },
    {
      name    => 'Round trip 1.001_001 OK',
      new_arg => '1.001_001'
    },
    {
      name    => 'Round trip 3.0.4_001 OK',
      new_arg => '3.0.4_001'
    },

    # Tests added in response to specific bugs
    {
      name    => 'Looks like a number with alpha',
      new_arg => '1.001_001',
    },
    {
      name    => 'Zero alpha',
      new_arg => '9.8.7_000',
    },
  );
}

use Test::More tests => @tests * 7;

for my $test ( @tests ) {
  my $name    = delete $test->{name};
  my $version = delete $test->{new_arg};
  my $new_err = delete $test->{new_err};
  my $act_err = delete $test->{act_err};

  my $safe = sub {
    my ( $err, $arg, $code ) = @_;
    my $warned;

    # Promote warnings to errors
    local $SIG{__WARN__} = sub { $warned = $_[0] };

    my $result = eval { $code->( @$arg ) };

    for my $diag ( [ 'error', $@ ], [ 'warning', $warned ] ) {
      my ( $key, $val ) = @$diag;
      like $val || '', $err->{$key} || qr{^$}, "$name: warning OK";
    }

    return $result;
  };

  my $obj = $safe->(
    $new_err,
    [$version],
    sub {
      return Perl::Version->new( @_ );
    },
  );

  if ( $new_err->{error} ) {
    ok !$obj, "$name: object creation failed as expected";
    pass "$name: no object created" for 1 .. 4;
  }
  else {
    isa_ok $obj, 'Perl::Version';

    is $obj->stringify, $version,
     "$name: stringify round trips correctly";

    if ( my $action = delete $test->{action} ) {
      $safe->(
        $act_err,
        [$obj],
        sub {
          local $_ = shift;
          $action->();
        }
      );
    }
    else {
      pass "$name: no action defined" for 1 .. 2;
    }

    verify( $name, $obj, $test );
  }
}

sub verify {
  my ( $test, $obj, $ref ) = @_;
  my $got        = {};
  my @components = sort keys %$ref;
  for my $component ( @components ) {
    my ( $method, @args ) = split( /_/, $component );
    $got->{$component} = $obj->$method( @args );
  }
  my $test_name = "$test: " . join( ', ', @components ) . ' match';
  $test_name .= 'es' if @components = 1;

  unless ( is_deeply $got, $ref, $test_name ) {
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Quotekeys = 0;
    warn Data::Dumper->Dump( [$got], ['$got'] );
    warn Data::Dumper->Dump( [$ref], ['$ref'] );
    warn Data::Dumper->Dump( [$obj], ['$obj'] );
  }
}
