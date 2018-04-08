use Mojo::Base -strict;
use lib 't';
use problem_start;


# test how DESTROY works without throttling

run_tests('no throttle');
is get_warn(), q{};

# test how DESTROY works with default throttling

throttle_it('Mojo::UserAgent::start');
$throttle = Sub::Throttler::Limit->new;
$throttle->apply_to_methods('Mojo::UserAgent');

run_tests('throttle_it');
like get_warn(), qr/\$done.*not called/ms,
    '$done was lost';
ok !$throttle->try_acquire('id','default',1),
    'resource was not released';


done_testing();
