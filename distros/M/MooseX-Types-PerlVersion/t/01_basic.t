use warnings;
use strict;

use Test::More;

use Moose::Util::TypeConstraints;
use ok 'MooseX::Types::PerlVersion' => qw(PerlVersion);

{
    package PV;
    use Moose;
    use MooseX::Types::PerlVersion qw(PerlVersion);

    has version => (
        isa    => PerlVersion,
        is     => 'ro',
        coerce => 1,
    );
}

for (1, 1.5, '1.2.3', 'v1.2.3', Perl::Version->new(1.2)) {
    ok my $pv = PV->new(version => $_), "Created object for $_";
    isa_ok $pv, 'PV';
    isa_ok $pv->version, 'Perl::Version';
    is $pv->version->stringify, $_, "$_ stringified eq original";
}

done_testing;
