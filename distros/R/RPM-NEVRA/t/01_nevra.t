#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use RPM::NEVRA;

subtest 'constructor', sub {
    my $obj = RPM::NEVRA->new();
    isa_ok( $obj, 'RPM::NEVRA', 'got obj back' );
};

subtest 'parse_nevra', sub {
    my $obj  = RPM::NEVRA->new();
    my %info = $obj->parse_nevra('bind-32:9.10.2-2.P1.fc22.x86_64');
    is_deeply( \%info, { name => 'bind', epoch => 32, ver => '9.10.2', rel => '2.P1.fc22', arch => 'x86_64' },
        'nevra parsed' );

    %info = $obj->parse_nevra('bind-9.10.2-2.P1.fc22.x86_64');
    is_deeply( \%info, { name => 'bind', epoch => undef, ver => '9.10.2', rel => '2.P1.fc22', arch => 'x86_64' },
        'no epoch' );
};

subtest 'is_nevra', sub {
    my $obj = RPM::NEVRA->new();
    my ( $ret, undef ) = $obj->is_nevra('bind-32:9.10.2-2.P1.fc22.x86_64');
    is( $ret, 1, 'identified nevra correctly' );

    my ( $ret2, $field ) = $obj->is_nevra('bind-9.10.2-2.P1.fc22.x86_64');
    is( $ret2,  0,       'identified non-nevra' );
    is( $field, 'epoch', 'identified missing field' );
};

subtest 'convert_to_nevra', sub {
    my $obj = RPM::NEVRA->new();
    is(
        $obj->convert_to_nevra('bind-9.10.2-2.P1.fc22.x86_64'),
        'bind-0:9.10.2-2.P1.fc22.x86_64',
        'string converted to nevra'
    );
    is( $obj->convert_to_nevra('bind-32:9.10.2-2.P1.fc22.x86_64'), 'bind-32:9.10.2-2.P1.fc22.x86_64', 'unchanged' );
};

done_testing();
