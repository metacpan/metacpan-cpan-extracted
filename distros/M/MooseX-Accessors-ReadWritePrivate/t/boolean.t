#!/usr/bin/env perl

use utf8;
use 5.008004;

use strict;
use warnings;

use version; our $VERSION = qv('v1.4.0');


use Test::More tests => 18;


{
    package Regular;

    use Moose 2.0;
    use MooseX::Accessors::ReadWritePrivate;

    has 'public_rw'                  => (is => 'rw',  isa => 'Bool');
    has '_private_rw'                => (is => 'rw',  isa => 'Bool');
    has '__distribution_private_rw'  => (is => 'rw',  isa => 'Bool');

    has 'public_ro'                  => (is => 'ro',  isa => 'Bool');
    has '_private_ro'                => (is => 'ro',  isa => 'Bool');
    has '__distribution_private_ro'  => (is => 'ro',  isa => 'Bool');

    has 'public_rwp'                 => (is => 'rwp', isa => 'Bool');
    has '_private_rwp'               => (is => 'rwp', isa => 'Bool');
    has '__distribution_private_rwp' => (is => 'rwp', isa => 'Bool');
} # end Regular


foreach my $package ( qw< Regular > ) {
    ok($package->can('public_rw'),                     "$package->public_rw() exists."                    );
    ok($package->can('set_public_rw'),                 "$package->set_public_rw() exists."                );
    ok($package->can('_private_rw'),                   "$package->_private_rw() exists."                  );
    ok($package->can('_set_private_rw'),               "$package->_set_private_rw() exists."              );
    ok($package->can('__distribution_private_rw'),     "$package->__distribution_private_rw() exists."    );
    ok($package->can('__set_distribution_private_rw'), "$package->__set_distribution_private_rw() exists.");

    ok(  $package->can('public_ro'),                     "$package->public_ro() exists."                           );
    ok(! $package->can('set_public_ro'),                 "$package->set_public_ro() doesn't exist."                );
    ok(  $package->can('_private_ro'),                   "$package->_private_ro() exists."                         );
    ok(! $package->can('_set_private_ro'),               "$package->_set_private_ro() doesn't exist."              );
    ok(  $package->can('__distribution_private_ro'),     "$package->__distribution_private_ro() exists."           );
    ok(! $package->can('__set_distribution_private_ro'), "$package->__set_distribution_private_ro() doesn't exist.");

    ok($package->can('public_rwp'),                     "$package->public_rwp() exists."                    );
    ok($package->can('_set_public_rwp'),                "$package->_set_public_rwp() exists."               );
    ok($package->can('_private_rwp'),                   "$package->_private_rwp() exists."                  );
    ok($package->can('_set_private_rwp'),               "$package->_set_private_rwp() exists."              );
    ok($package->can('__distribution_private_rwp'),     "$package->__distribution_private_rwp() exists."    );
    ok($package->can('_set_distribution_private_rwp'),  "$package->_set_distribution_private_rwp() exists." );
} # end foreach


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
