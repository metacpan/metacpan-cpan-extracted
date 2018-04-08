use Mojo::Base -strict;
use lib 't';
use problem_start;
use MojoX::UserAgent::Throttler;


# test how DESTROY works with MojoX::UserAgent::Throttler

$throttle = Sub::Throttler::Limit->new;
$throttle->apply_to_methods('Mojo::UserAgent');

run_tests('custom wrapper');
is get_warn(), q{},
    '$done was not lost';
ok $throttle->try_acquire('id','default',1),
    'resource was released';


done_testing();
