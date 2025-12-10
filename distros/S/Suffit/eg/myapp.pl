#!/usr/bin/perl -w
package MyApp;
our $VERSION = '0.01';
use parent 'Suffit';
sub init { shift->routes->any('/' => {text => 'Hello World!'}) }
1;

package main;
use Mojo::Server;
Mojo::Server->new->build_app('MyApp', datadir => '/tmp')->start();

# Now try to run it:
#
# perl myapp.pl daemon -l http://*:8080

# Check:
#
# curl -v http://localhost:8080
# > GET / HTTP/1.1
# > Host: localhost:8080
# > User-Agent: curl/8.5.0
# > Accept: */*
# >
# < HTTP/1.1 200 OK
# < Content-Length: 12
# < Content-Type: text/html;charset=UTF-8
# < Date: Tue, 09 Dec 2025 13:15:33 GMT
# < Server: MyApp/0.01
# <
# Hello World!
