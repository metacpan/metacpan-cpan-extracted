#!/usr/bin/env perl

=head1 DESCRIPTION

Check that incomplete resource definitions do not work.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

subtest "just forward" => sub {
    throws_ok {
        package My::Pkg1;
        use Resource::Silo;
        resource config =>
            dependencies => ['config_file'],
            init => sub {};

        silo();
    } qr/dependencies.*declared|unsatisfied/i, "declaring forward dependency without fulfilling is forbidden";
};

done_testing;

