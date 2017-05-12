#!/usr/bin/env perl

use utf8;
use 5.008004;

use strict;
use warnings;

use version; our $VERSION = qv('v1.4.0');


use Test::More;
use Moose 2.0 ();

plan tests => 42;

my $TRUE  = 1;
my $FALSE = 0;


## no critic (Modules::ProhibitMultiplePackages)
{
    package Role;

    use Moose::Role 2.0;
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
    package Regular;

    use Moose 2.0;
    with 'Role';
}

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
