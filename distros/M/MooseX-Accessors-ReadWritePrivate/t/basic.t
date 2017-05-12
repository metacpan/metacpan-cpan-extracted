#!/usr/bin/env perl

use utf8;
use 5.008004;

use strict;
use warnings;

use version; our $VERSION = qv('v1.4.0');


use Test::More tests => 168;


my $TRUE  = 1;
my $FALSE = 0;


## no critic (Modules::ProhibitMultiplePackages)
{
    package Regular;

    # Make sure load order doesn't matter.
    use Moose 2.0;
    use MooseX::Accessors::ReadWritePrivate;

    has 'public_rw'                   => (is => 'rw' );
    has '_private_rw'                 => (is => 'rw' );
    has '__distribution_private_rw'   => (is => 'rw' );

    has 'public_ro'                   => (is => 'ro' );
    has '_private_ro'                 => (is => 'ro' );
    has '__distribution_private_ro'   => (is => 'ro' );

    has 'public_rwp'                  => (is => 'rwp');
    has '_private_rwp'                => (is => 'rwp');
    has '__distribution_private_rwp'  => (is => 'rwp');

    has 'public_rop'                  => (is => 'rop');
    has '_private_rop'                => (is => 'rop');
    has '__distribution_private_rop'  => (is => 'rop');

    has 'public_wop'                  => (is => 'wop');
    has '_private_wop'                => (is => 'wop');
    has '__distribution_private_wop'  => (is => 'wop');

    has 'public_rpw'                  => (is => 'rpw');
    has '_private_rpw'                => (is => 'rpw');
    has '__distribution_private_rpw'  => (is => 'rpw');

    has 'public_rpwp'                 => (is => 'rpwp');
    has '_private_rpwp'               => (is => 'rpwp');
    has '__distribution_private_rpwp' => (is => 'rpwp');

    has 'public_bare'                 => (is => 'bare');
    has '_private_bare'               => (is => 'bare');
    has '__distribution_private_bare' => (is => 'bare');
} # end Regular

{
    package Selector::Overrides;

    use Moose 2.0;
    use MooseX::Accessors::ReadWritePrivate;

    has 'public_rw'                   => (is => 'rw',   reader => 'public_rw_override'                  );
    has '_private_rw'                 => (is => 'rw',   reader => '_private_rw_override'                );
    has '__distribution_private_rw'   => (is => 'rw',   reader => '__distribution_private_rw_override'  );

    has 'public_ro'                   => (is => 'ro',   reader => 'public_ro_override'                  );
    has '_private_ro'                 => (is => 'ro',   reader => '_private_ro_override'                );
    has '__distribution_private_ro'   => (is => 'ro',   reader => '__distribution_private_ro_override'  );

    has 'public_rwp'                  => (is => 'rwp',  reader => 'public_rwp_override'                 );
    has '_private_rwp'                => (is => 'rwp',  reader => '_private_rwp_override'               );
    has '__distribution_private_rwp'  => (is => 'rwp',  reader => '__distribution_private_rwp_override' );

    has 'public_rop'                  => (is => 'rop',  reader => 'public_rop_override'                 );
    has '_private_rop'                => (is => 'rop',  reader => '_private_rop_override'               );
    has '__distribution_private_rop'  => (is => 'rop',  reader => '__distribution_private_rop_override' );

    has 'public_rpw'                  => (is => 'rpw',  reader => 'public_rpw_override'                 );
    has '_private_rpw'                => (is => 'rpw',  reader => '_private_rpw_override'               );
    has '__distribution_private_rpw'  => (is => 'rpw',  reader => '__distribution_private_rpw_override' );

    has 'public_rpwp'                 => (is => 'rpwp', reader => 'public_rpwp_override'                );
    has '_private_rpwp'               => (is => 'rpwp', reader => '_private_rpwp_override'              );
    has '__distribution_private_rpwp' => (is => 'rpwp', reader => '__distribution_private_rpwp_override');

    has 'public_bare'                 => (is => 'bare', reader => 'public_bare_override'                );
    has '_private_bare'               => (is => 'bare', reader => '_private_bare_override'              );
    has '__distribution_private_bare' => (is => 'bare', reader => '__distribution_private_bare_override');
} # end Selector::Overrides

{
    package Mutator::Overrides;

    use Moose 2.0;
    use MooseX::Accessors::ReadWritePrivate;

    has 'public_rw'                   => (is => 'rw',   writer => 'public_rw_override'                  );
    has '_private_rw'                 => (is => 'rw',   writer => '_private_rw_override'                );
    has '__distribution_private_rw'   => (is => 'rw',   writer => '__distribution_private_rw_override'  );

    # Of course this is stupid, but you should still be able to do it.
    has 'public_ro'                   => (is => 'ro',   writer => 'public_ro_override'                  );
    has '_private_ro'                 => (is => 'ro',   writer => '_private_ro_override'                );
    has '__distribution_private_ro'   => (is => 'ro',   writer => '__distribution_private_ro_override'  );

    has 'public_rwp'                  => (is => 'rwp',  writer => 'public_rwp_override'                 );
    has '_private_rwp'                => (is => 'rwp',  writer => '_private_rwp_override'               );
    has '__distribution_private_rwp'  => (is => 'rwp',  writer => '__distribution_private_rwp_override' );

    has 'public_rop'                  => (is => 'rop',  writer => 'public_rop_override'                 );
    has '_private_rop'                => (is => 'rop',  writer => '_private_rop_override'               );
    has '__distribution_private_rop'  => (is => 'rop',  writer => '__distribution_private_rop_override' );

    has 'public_rpw'                  => (is => 'rpw',  writer => 'public_rpw_override'                 );
    has '_private_rpw'                => (is => 'rpw',  writer => '_private_rpw_override'               );
    has '__distribution_private_rpw'  => (is => 'rpw',  writer => '__distribution_private_rpw_override' );

    has 'public_rpwp'                 => (is => 'rpwp', writer => 'public_rpwp_override'                );
    has '_private_rpwp'               => (is => 'rpwp', writer => '_private_rpwp_override'              );
    has '__distribution_private_rpwp' => (is => 'rpwp', writer => '__distribution_private_rpwp_override');

    has 'public_bare'                 => (is => 'bare', writer => 'public_bare_override'                );
    has '_private_bare'               => (is => 'bare', writer => '_private_bare_override'              );
    has '__distribution_private_bare' => (is => 'bare', writer => '__distribution_private_bare_override');
} # end Mutator::Overrides



test_accessor('Regular', $TRUE, 'get_public_rw');
test_accessor('Regular', $TRUE, 'set_public_rw');
test_accessor('Regular', $TRUE, '_get_private_rw');
test_accessor('Regular', $TRUE, '_set_private_rw');
test_accessor('Regular', $TRUE, '__get_distribution_private_rw');
test_accessor('Regular', $TRUE, '__set_distribution_private_rw');

test_accessor('Regular', $TRUE,  'get_public_ro');
test_accessor('Regular', $FALSE, 'set_public_ro');
test_accessor('Regular', $TRUE,  '_get_private_ro');
test_accessor('Regular', $FALSE, '_set_private_ro');
test_accessor('Regular', $TRUE,  '__get_distribution_private_ro');
test_accessor('Regular', $FALSE, '__set_distribution_private_ro');

test_accessor('Regular', $TRUE, 'get_public_rwp');
test_accessor('Regular', $TRUE, '_set_public_rwp');
test_accessor('Regular', $TRUE, '_get_private_rwp');
test_accessor('Regular', $TRUE, '_set_private_rwp');
test_accessor('Regular', $TRUE, '__get_distribution_private_rwp');
test_accessor('Regular', $TRUE, '_set_distribution_private_rwp');

test_accessor('Regular', $TRUE,  '_get_public_rop');
test_accessor('Regular', $FALSE, 'set_public_rop');
test_accessor('Regular', $TRUE,  '_get_private_rop');
test_accessor('Regular', $FALSE, '_set_private_rop');
test_accessor('Regular', $TRUE,  '_get_distribution_private_rop');
test_accessor('Regular', $FALSE, '__set_distribution_private_rop');

test_accessor('Regular', $TRUE, '_get_public_rpw');
test_accessor('Regular', $TRUE, 'set_public_rpw');
test_accessor('Regular', $TRUE, '_get_private_rpw');
test_accessor('Regular', $TRUE, '_set_private_rpw');
test_accessor('Regular', $TRUE, '_get_distribution_private_rpw');
test_accessor('Regular', $TRUE, '__set_distribution_private_rpw');

test_accessor('Regular', $TRUE, '_get_public_rpwp');
test_accessor('Regular', $TRUE, '_set_public_rpwp');
test_accessor('Regular', $TRUE, '_get_private_rpwp');
test_accessor('Regular', $TRUE, '_set_private_rpwp');
test_accessor('Regular', $TRUE, '_get_distribution_private_rpwp');
test_accessor('Regular', $TRUE, '_set_distribution_private_rpwp');

test_accessor('Regular', $FALSE, 'get_public_bare');
test_accessor('Regular', $FALSE, '_set_public_bare');
test_accessor('Regular', $FALSE, '_get_private_bare');
test_accessor('Regular', $FALSE, '_set_private_bare');
test_accessor('Regular', $FALSE, '__get_distribution_private_bare');
test_accessor('Regular', $FALSE, '_set_distribution_private_bare');


test_accessor('Selector::Overrides', $TRUE,  'public_rw_override');
test_accessor('Selector::Overrides', $FALSE, 'get_public_rw');
test_accessor('Selector::Overrides', $TRUE,  'set_public_rw');
test_accessor('Selector::Overrides', $TRUE,  '_private_rw_override');
test_accessor('Selector::Overrides', $FALSE, '_get_private_rw');
test_accessor('Selector::Overrides', $TRUE,  '_set_private_rw');
test_accessor('Selector::Overrides', $TRUE,  '__distribution_private_rw_override');
test_accessor('Selector::Overrides', $FALSE, '__get_distribution_private_rw');
test_accessor('Selector::Overrides', $TRUE,  '__set_distribution_private_rw');

test_accessor('Selector::Overrides', $TRUE,  'public_ro_override');
test_accessor('Selector::Overrides', $FALSE, 'get_public_ro');
test_accessor('Selector::Overrides', $FALSE, 'set_public_ro');
test_accessor('Selector::Overrides', $TRUE,  '_private_ro_override');
test_accessor('Selector::Overrides', $FALSE, '_get_private_ro');
test_accessor('Selector::Overrides', $FALSE, '_set_private_ro');
test_accessor('Selector::Overrides', $TRUE,  '__distribution_private_ro_override');
test_accessor('Selector::Overrides', $FALSE, '__get_distribution_private_ro');
test_accessor('Selector::Overrides', $FALSE, '__set_distribution_private_ro');

test_accessor('Selector::Overrides', $TRUE,  'public_rwp_override');
test_accessor('Selector::Overrides', $FALSE, 'get_public_rwp');
test_accessor('Selector::Overrides', $TRUE,  '_set_public_rwp');
test_accessor('Selector::Overrides', $TRUE,  '_private_rwp_override');
test_accessor('Selector::Overrides', $FALSE, '_get_private_rwp');
test_accessor('Selector::Overrides', $TRUE,  '_set_private_rwp');
test_accessor('Selector::Overrides', $TRUE,  '__distribution_private_rwp_override');
test_accessor('Selector::Overrides', $FALSE, '__get_distribution_private_rwp');
test_accessor('Selector::Overrides', $TRUE,  '_set_distribution_private_rwp');

test_accessor('Selector::Overrides', $TRUE,  'public_rop_override');
test_accessor('Selector::Overrides', $FALSE, '_get_public_rop');
test_accessor('Selector::Overrides', $FALSE, 'set_public_rop');
test_accessor('Selector::Overrides', $TRUE,  '_private_rop_override');
test_accessor('Selector::Overrides', $FALSE, '_get_private_rop');
test_accessor('Selector::Overrides', $FALSE, '_set_private_rop');
test_accessor('Selector::Overrides', $TRUE,  '__distribution_private_rop_override');
test_accessor('Selector::Overrides', $FALSE, '_get_distribution_private_rop');
test_accessor('Selector::Overrides', $FALSE, '__set_distribution_private_rop');

test_accessor('Selector::Overrides', $TRUE,  'public_rpw_override');
test_accessor('Selector::Overrides', $FALSE, '_get_public_rpw');
test_accessor('Selector::Overrides', $TRUE,  'set_public_rpw');
test_accessor('Selector::Overrides', $TRUE,  '_private_rpw_override');
test_accessor('Selector::Overrides', $FALSE, '_get_private_rpw');
test_accessor('Selector::Overrides', $TRUE,  '_set_private_rpw');
test_accessor('Selector::Overrides', $TRUE,  '__distribution_private_rpw_override');
test_accessor('Selector::Overrides', $FALSE, '_get_distribution_private_rpw');
test_accessor('Selector::Overrides', $TRUE,  '__set_distribution_private_rpw');

test_accessor('Selector::Overrides', $TRUE,  'public_rpwp_override');
test_accessor('Selector::Overrides', $FALSE, '_get_public_rpwp');
test_accessor('Selector::Overrides', $TRUE,  '_set_public_rpwp');
test_accessor('Selector::Overrides', $TRUE,  '_private_rpwp_override');
test_accessor('Selector::Overrides', $FALSE, '_get_private_rpwp');
test_accessor('Selector::Overrides', $TRUE,  '_set_private_rpwp');
test_accessor('Selector::Overrides', $TRUE,  '__distribution_private_rpwp_override');
test_accessor('Selector::Overrides', $FALSE, '_get_distribution_private_rpwp');
test_accessor('Selector::Overrides', $TRUE,  '_set_distribution_private_rpwp');

test_accessor('Selector::Overrides', $TRUE,  'public_bare_override');
test_accessor('Selector::Overrides', $FALSE, 'get_public_bare');
test_accessor('Selector::Overrides', $FALSE, 'set_public_bare');
test_accessor('Selector::Overrides', $TRUE,  '_private_bare_override');
test_accessor('Selector::Overrides', $FALSE, '_get_private_bare');
test_accessor('Selector::Overrides', $FALSE, '_set_private_bare');
test_accessor('Selector::Overrides', $TRUE,  '__distribution_private_bare_override');
test_accessor('Selector::Overrides', $FALSE, '__get_distribution_private_bare');
test_accessor('Selector::Overrides', $FALSE, '__set_distribution_private_bare');


test_accessor('Mutator::Overrides', $TRUE,  'get_public_rw');
test_accessor('Mutator::Overrides', $TRUE,  'public_rw_override');
test_accessor('Mutator::Overrides', $FALSE, 'set_public_rw');
test_accessor('Mutator::Overrides', $TRUE,  '_get_private_rw');
test_accessor('Mutator::Overrides', $TRUE,  '_private_rw_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_private_rw');
test_accessor('Mutator::Overrides', $TRUE,  '__get_distribution_private_rw');
test_accessor('Mutator::Overrides', $TRUE,  '__distribution_private_rw_override');
test_accessor('Mutator::Overrides', $FALSE, '__set_distribution_private_rw');

test_accessor('Mutator::Overrides', $TRUE,  'get_public_ro');
test_accessor('Mutator::Overrides', $TRUE,  'public_ro_override');
test_accessor('Mutator::Overrides', $FALSE, 'set_public_ro');
test_accessor('Mutator::Overrides', $TRUE,  '_get_private_ro');
test_accessor('Mutator::Overrides', $TRUE,  '_private_ro_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_private_ro');
test_accessor('Mutator::Overrides', $TRUE,  '__get_distribution_private_ro');
test_accessor('Mutator::Overrides', $TRUE,  '__distribution_private_ro_override');
test_accessor('Mutator::Overrides', $FALSE, '__set_distribution_private_ro');

test_accessor('Mutator::Overrides', $TRUE,  'get_public_rwp');
test_accessor('Mutator::Overrides', $TRUE,  'public_rwp_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_public_rwp');
test_accessor('Mutator::Overrides', $TRUE,  '_get_private_rwp');
test_accessor('Mutator::Overrides', $TRUE,  '_private_rwp_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_private_rwp');
test_accessor('Mutator::Overrides', $TRUE,  '__get_distribution_private_rwp');
test_accessor('Mutator::Overrides', $TRUE,  '__distribution_private_rwp_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_distribution_private_rwp');

test_accessor('Mutator::Overrides', $TRUE,  '_get_public_rop');
test_accessor('Mutator::Overrides', $TRUE,  'public_rop_override');
test_accessor('Mutator::Overrides', $FALSE, 'set_public_rop');
test_accessor('Mutator::Overrides', $TRUE,  '_get_private_rop');
test_accessor('Mutator::Overrides', $TRUE,  '_private_rop_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_private_rop');
test_accessor('Mutator::Overrides', $TRUE,  '_get_distribution_private_rop');
test_accessor('Mutator::Overrides', $TRUE,  '__distribution_private_rop_override');
test_accessor('Mutator::Overrides', $FALSE, '__set_distribution_private_rop');

test_accessor('Mutator::Overrides', $TRUE,  '_get_public_rpw');
test_accessor('Mutator::Overrides', $TRUE,  'public_rpw_override');
test_accessor('Mutator::Overrides', $FALSE, 'set_public_rpw');
test_accessor('Mutator::Overrides', $TRUE,  '_get_private_rpw');
test_accessor('Mutator::Overrides', $TRUE,  '_private_rpw_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_private_rpw');
test_accessor('Mutator::Overrides', $TRUE,  '_get_distribution_private_rpw');
test_accessor('Mutator::Overrides', $TRUE,  '__distribution_private_rpw_override');
test_accessor('Mutator::Overrides', $FALSE, '__set_distribution_private_rpw');

test_accessor('Mutator::Overrides', $TRUE,  '_get_public_rpwp');
test_accessor('Mutator::Overrides', $TRUE,  'public_rpwp_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_public_rpwp');
test_accessor('Mutator::Overrides', $TRUE,  '_get_private_rpwp');
test_accessor('Mutator::Overrides', $TRUE,  '_private_rpwp_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_private_rpwp');
test_accessor('Mutator::Overrides', $TRUE,  '_get_distribution_private_rpwp');
test_accessor('Mutator::Overrides', $TRUE,  '__distribution_private_rpwp_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_distribution_private_rpwp');

test_accessor('Mutator::Overrides', $FALSE, 'get_public_bare');
test_accessor('Mutator::Overrides', $TRUE,  'public_bare_override');
test_accessor('Mutator::Overrides', $FALSE, 'set_public_bare');
test_accessor('Mutator::Overrides', $FALSE, '_get_private_bare');
test_accessor('Mutator::Overrides', $TRUE,  '_private_bare_override');
test_accessor('Mutator::Overrides', $FALSE, '_set_private_bare');
test_accessor('Mutator::Overrides', $FALSE, '__get_distribution_private_bare');
test_accessor('Mutator::Overrides', $TRUE,  '__distribution_private_bare_override');
test_accessor('Mutator::Overrides', $FALSE, '__set_distribution_private_bare');


sub test_accessor {
    my ($class, $should_exist, $accessor_name) = @_;

    if ($should_exist) {
        ok($class->can($accessor_name), "$class->$accessor_name() exists.");
    } else {
        ok(! $class->can($accessor_name), "$class->$accessor_name() doesn't exist.");
    } # end if

    return;
} # end test_accessor()


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
