use Test::More;

    my $path = __FILE__;
    $path =~ s/t\/Router\-PathInfo\-Static\.t$//;
    $path ||= '.';

    pass('*' x 10);
    pass('Router::PathInfo::Static');
    pass('Check interface');
    pass('*' x 10);
    
    # use
    use_ok('Router::PathInfo::Static');
    can_ok('Router::PathInfo::Static','new');
    
    # create instance
	my $s = Router::PathInfo::Static->new(
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
    );
    isa_ok($s, 'Router::PathInfo::Static');

    can_ok($s,'match');

    
    pass('*' x 10);
    pass('Check already static');
    pass('*' x 10);
    
    # check success match
    my $env = {PATH_INFO => '/static/t/Router-PathInfo-Static.t'};
    my @segment = split '/', $env->{PATH_INFO}, -1; 
    shift @segment;
    $env->{'psgix.tmp.RouterPathInfo'} = {
        segments => [@segment],
        depth => scalar @segment 
    };

    my $res = $s->match($env);
    
    # check result
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'static', 'check match type');
    is($res->{mime}, 'text/troff', 'check mime');
    
    # path with file with /.name
    $env = {PATH_INFO => '/static/t/.any'};
    @segment = split '/', $env->{PATH_INFO}, -1; 
    shift @segment;
    $env->{'psgix.tmp.RouterPathInfo'} = {
        segments => [@segment],
        depth => scalar @segment 
    };
    $res = $s->match($env);
    
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'error', 'check match type');
    is($res->{code}, 403, 'check forbidden');
    
    # path with /../
    $env = {PATH_INFO => '/static/t/../any'};
    @segment = split '/', $env->{PATH_INFO}, -1; 
    shift @segment;
    $env->{'psgix.tmp.RouterPathInfo'} = {
        segments => [@segment],
        depth => scalar @segment 
    };
    $res = $s->match($env);
    
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'error', 'check match type');
    is($res->{code}, 403, 'check another forbidden');
    
    # not found
    $env = {PATH_INFO => '/static/t/not_found.txt'};
    @segment = split '/', $env->{PATH_INFO}, -1; 
    shift @segment;
    $env->{'psgix.tmp.RouterPathInfo'} = {
        segments => [@segment],
        depth => scalar @segment 
    };
    $res = $s->match($env);
    
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'error', 'check match type');
    is($res->{code}, 404, 'check not found');

    pass('*' x 10);
    pass('Check on_demand static');
    pass('*' x 10);
    
    # check already exists static with type 'on_demand'
    $env = {PATH_INFO => '/cached/Router-PathInfo-Static.t'};
    @segment = split '/', $env->{PATH_INFO}, -1; 
    shift @segment;
    $env->{'psgix.tmp.RouterPathInfo'} = {
        segments => [@segment],
        depth => scalar @segment 
    };
    $res = $s->match($env);
    
    is(ref $res, 'HASH', 'check ref match');
    is($res->{type}, 'static', 'check match type');
    is($res->{mime}, 'text/troff', 'check mime');   
    
    # check not exists static with type 'on_demand'
    $env = {PATH_INFO => '/cached/not_found.txt'};
    @segment = split '/', $env->{PATH_INFO}, -1; 
    shift @segment;
    $env->{'psgix.tmp.RouterPathInfo'} = {
        segments => [@segment],
        depth => scalar @segment 
    };
    $res = $s->match($env);
    
    is($res, undef, 'check match');
    
    pass('*' x 10);
    print "\n";
    done_testing;
