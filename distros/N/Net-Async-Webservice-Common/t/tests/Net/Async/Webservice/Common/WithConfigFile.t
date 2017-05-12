#!perl
use strict;
use warnings;
use 5.010;
use Test::Most;

{package TestPkg;
    use Moo;
    with 'Net::Async::Webservice::Common::WithConfigFile';
    has param => ( is => 'ro', required => 1 );
};

my $t;
lives_ok { $t=TestPkg->new({config_file=>'t/lib/NaWsCwCF.pl'}) }
    'required param satisfied by config';
is($t->param,'some value','with correct value');

done_testing;

