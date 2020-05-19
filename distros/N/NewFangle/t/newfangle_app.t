use Test2::V0 -no_srand => 1;
use lib 't/lib';
use LiveTest;
use NewFangle qw( newrelic_configure_log );

my $app = NewFangle::App->new;
isa_ok $app, 'NewFangle::App';

done_testing;
