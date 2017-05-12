#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 14;

use POE qw(Component::Archive::Any);

my $poco = POE::Component::Archive::Any->spawn(debug=>1);

isa_ok( $poco, 'POE::Component::Archive::Any' );
can_ok( $poco, qw(spawn session_id shutdown extract) );

POE::Session->create(
    package_states => [
        main => [ qw( _start  extracted ) ],
    ],
);

$poe_kernel->run;

sub _start {
    $poco->extract( {
            event => 'extracted',
            file  => 't/test_archive.zip',
            dir   => 't/',
            _user => 'random',
        }
    );
}

sub extracted {
    my $in = $_[ARG0];

    is(
        ref $in,
        'HASH',
        '$_[ARG0] must contain a hash',
    );

    SKIP: {
        if ( $in->{error} ) {
            skip "Got error `$in->{error}`", 11;
        }
        else {
            ok( exists $in->{is_naughty}, '{is_naughty} must exist');
            ok( exists $in->{is_impolite}, '{is_impolite} must exist');
            ok( (not $in->{is_naughty}), '{is_naughty} must be false');
            ok( (not $in->{is_impolite}), '{is_impolite} must be false');
            is(
                ref $in->{files},
                'ARRAY',
                '{files} must contain an arrayref',
            );
            is(
                @{ $in->{files} },
                4,
                '{files} arrayref must have 4 items',
            );
            is(
                (scalar grep {
                    $_ ne 'test_archive/'
                    and $_ ne 'test_archive/test1'
                    and $_ ne 'test_archive/test2'
                    and $_ ne 'test_archive/test3'
                } @{ $in->{files} }),
                0,
                '{files} must contain 3 test files and a dir',
            );
            is( $in->{dir}, 't/', '{dir} must be the same as passed' );
            is(
                $in->{file},
                't/test_archive.zip',
                '{file} must be the same as passed',
            );
            is(
                $in->{type},
                'application/x-zip',
                '{type} must be of a zip archive',
            );
            is(
                $in->{_user},
                'random',
                'user defined args must be intact',
            );
        }
    }

    $poco->shutdown;
}
