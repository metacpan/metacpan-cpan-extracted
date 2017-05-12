use Test::More;

    my $path = __FILE__;
    $path =~ s/t\/Router\-PathInfo\.t$//;
    $path ||= '.';

    pass('*' x 10);
    pass('Router::PathInfo');
    pass('Check interface');
    pass('*' x 10);
    
    # use
    use_ok('Router::PathInfo');
    can_ok('Router::PathInfo','new');
    
    my $pi = Router::PathInfo->new(
        static => {
            # describe simple static 
            allready => {
                path => $path,
                first_uri_segment => 'static'
            },
            # describe on demand created static
            on_demand => {
                path => $path.'/t',
                first_uri_segment => 'cached',
            }
        }
    );

    isa_ok($pi, 'Router::PathInfo');
    
    can_ok($pi,'add_rule');
    can_ok($pi,'match');
    
    pass('*' x 10);
    pass('Check controller');
    pass('*' x 10);    
    
    # check added rule interface
    is($pi->add_rule(connect => '/foo/:enum(bar|baz)/:any', action => ['some','bar']), 1, 'check add_rule');
    
    my $res = $pi->match({PATH_INFO => '/foo/baz/bar', REQUEST_METHOD => 'GET'}); 
    
    # check result
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'controller', 'check match type');
    is(ref $res->{action}, 'ARRAY', 'check ref action');
    is($res->{action}->[0], 'some', 'check action content 1');
    is($res->{action}->[1], 'bar', 'check action content 2');
    
    pass('*' x 10);
    pass('Check static');
    pass('*' x 10);
    
    
    $res = $pi->match({PATH_INFO => '/static/t/Router-PathInfo-Static.t'});
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'static', 'check match type');
    is($res->{mime}, 'text/troff', 'check mime');    
    
    $res = $pi->match({PATH_INFO => '/static/t/../any'});
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'error', 'check match type');
    is($res->{code}, 403, 'check another forbidden');
    
    $res = $pi->match({PATH_INFO => '/cached/not_found.txt'});
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'error', 'check match type');
    is($res->{code}, '404', 'check not found');    
    
    $pi->add_rule(connect => '/cached/not_found.txt', action => ['some','bar']);
    $res = $pi->match({PATH_INFO => '/cached/not_found.txt'});
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'controller', 'check match type');
    is(ref $res->{action}, 'ARRAY', 'check ref action');
    is($res->{action}->[0], 'some', 'check action content 1');
    is($res->{action}->[1], 'bar', 'check action content 2');

    # check calback
    $pi->add_rule(
        connect => '/foo/:enum(bar|baz)/:any', 
        action => ['any thing'], 
        methods => ['POST'], 
        match_callback => sub {
            my ($match, $env) = @_;
            return $env->{'psgix.memcache'} ? 
                $match :
                {
                    type  => 'error',
                    value => [403, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['Forbidden']],
                    desc  => 'bla-bla'   
                };
        }
    ); 
    
    $res = $pi->match({PATH_INFO => '/foo/bar/baz', REQUEST_METHOD => 'POST'});    
    is($res->{type}, 'error', 'check callback false psgix.memcache');
    $res = $pi->match({PATH_INFO => '/foo/bar/baz', REQUEST_METHOD => 'POST', 'psgix.memcache' => 1});
    is($res->{action}->[0], 'any thing', 'check callback true psgix.memcache');
    
    
    pass('*' x 10);
    print "\n";
    done_testing;   
    
    