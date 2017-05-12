#!/usr/bin/perl

use Plack::Middleware::Session::Cookie;

Plack::Middleware::Session::Cookie->new->wrap( sub {
    my $env = shift;
    my $session = $env->{'psgix.session'} ||= {};
    my $req = Plack::Request->new($env);

    $session->{name} ||= 'Guest';
    my $new_name = $req->param('name');

    if( defined($new_name) && $new_name ne $session->{name} ) {
	$session->{name} = $new_name;
	$session->{visit} = 0;
    }
    ++$session->{visit};

    print "Hi $session->{name}!<br>You've visited here $session->{visit} time(s).\n";
    return [200, ['content-type'=>'text/html;charset=UTF-8'], ["Hi $session->{name}!<br>You've visited here $session->{visit} time(s)."]];
} )
