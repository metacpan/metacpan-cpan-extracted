#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

    pass('*' x 10);
    
use Router::PathInfo::Controller;
use Router::Simple;
use Benchmark qw(:all);
my $res;

    my $router = Router::Simple->new();
    $router->connect('/foo/bar/:int', {controller => '1', action => '11'});
    $router->connect('/foo/baz/:sd', {controller => '2', action => '22'});    
    
    my $r = Router::PathInfo::Controller->new();
    $r->add_rule(connect => '/foo/bar/:any', action => ['1','11']);    
    $r->add_rule(connect => '/foo/baz/:any', action => ['2','2']);
    
    my @env = map { {PATH_INFO => $_, REQUEST_METHOD => 'GET'} } ('/foo/bar/200', '/foo/baz/400') x 4;

	for (@env) {
	    my @segment = split '/', $_->{PATH_INFO}, -1; 
	    shift @segment;
	    $_->{'psgix.tmp.RouterPathInfo'} = {
	        segments => [@segment],
	        depth => scalar @segment 
	    };
	}
    
    pass('test resolve exactly match');
    
    $res = $r->match($env[0]);
    is($res->{action}->[0], '1', 'check Router::PathInfo::Controller');
    $res = $router->match($env[0]);
    is($res->{controller}, '1', 'check Router::Simple');
    pass('*' x 10);
    
    pass('Benchmark exactly match');
    cmpthese timethese(
     -1, 
        { 
            'Router::PathInfo::Controller' => sub {$r->match($_) for @env}, 
            'Router::Simple' => sub {$router->match($_) for @env} 
        } 
     );
    pass('*' x 10);
    
    my @env404 = map { {PATH_INFO => $_, REQUEST_METHOD => 'GET'} } ('/','/foo/main/moi/red/grep') x 4;

    for (@env404) {
        my @segment = split '/', $_->{PATH_INFO}, -1; 
        shift @segment;
        $_->{'psgix.tmp.RouterPathInfo'} = {
            segments => [@segment],
            depth => scalar @segment 
        };
    }     
      
    pass('test resolve 404');
    
    $res = $r->match($env404[0]);
    is($res, undef, 'check Router::PathInfo::Controller');
    $res = $router->match($env404[0]);
    is($res, undef, 'check Router::Simple');
    pass('*' x 10);
    
    pass('Benchmark only 404 match');
    cmpthese timethese(
     -1, 
        { 
            'Router::PathInfo::Controller' => sub {$r->match($_) for @env404}, 
            'Router::Simple' => sub {$router->match($_) for @env404} 
        } 
     );
     pass('*' x 10);
     
     pass('added more rules');
     $r->add_rule(connect => '/foo/bar/fun/more/rules', action => ['3','33']);
     $r->add_rule(connect => '/foo/bar/fun/more/rules/', action => ['4','44']);
     $r->add_rule(connect => '/foo/bar/fun/more/rules/for/test', action => ['5','55']);
     
     $router->connect('/foo/bar/fun/more/rules', {controller => '3', action => '33'});
     $router->connect('/foo/bar/fun/more/rules/', {controller => '4', action => '44'});
     $router->connect('/foo/bar/fun/more/rules/for/test', {controller => '5', action => '55'});

    @env = map { {PATH_INFO => $_, REQUEST_METHOD => 'GET'} } ('/foo/bar/200', '/foo/baz/400', '/', '/foo/bar/fun/more/rules/for/test', '/foo/bar/fun/more/rules/');

    for (@env) {
        my @segment = split '/', $_->{PATH_INFO}, -1; 
        shift @segment;
        $_->{'psgix.tmp.RouterPathInfo'} = {
            segments => [@segment],
            depth => scalar @segment 
        };
    }     
     
     pass('Benchmark more rules');
     
    cmpthese timethese(
     -1, 
        { 
            'Router::PathInfo::Controller' => sub {$r->match($_) for @env404}, 
            'Router::Simple' => sub {$router->match($_) for @env404} 
        } 
     );     
     
    pass('*' x 10);
    print "\n";
    done_testing;
