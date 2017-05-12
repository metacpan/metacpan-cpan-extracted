#!/usr/bin/perl

# Copyright 2012 Alexandr Gomoliako

use strict;
use warnings;
no  warnings 'uninitialized';

use Data::Dumper;
use Test::More;
use Nginx::Test;

my $nginx = find_nginx_perl;
my $dir   = "tmp/t02";

mkdir 'tmp'  unless  -d 'tmp';

plan skip_all => "Can't find executable binary ($nginx) to test"
        if  !$nginx    ||  
            !-x $nginx    ;

plan 'no_plan';


{
    my $port = get_unused_port
        or die "Cannot get unused port";

    my $peer  = "127.0.0.1:$port";

    my $incs = join "\n", 
                 map { "perl_inc \"$_\";" } 
                   get_nginx_incs ($nginx, $dir);

    prepare_nginx_dir_die $dir, <<"    ENDCONF", <<'    ENDPKG';

        worker_processes  1;
        daemon            off;
        master_process    off;

        error_log  logs/error.log  debug;

        events {  
            worker_connections  128;  
        }

        http {
            default_type  text/plain;

$incs

            perl_inc  lib;
            perl_inc  ../lib;

            perl_require  NginxPerlTest.pm;

            perl_eval '  \$NginxPerlTest::PEER = "$peer"  ';
            perl_eval '  \$Nginx::HTTP::TIMEOUT = 1       ';

            keepalive_requests  3;
            keepalive_timeout   3;

            server {
                listen  127.0.0.1:$port;

                location / {
                    perl_handler  NginxPerlTest::handler;
                }
            }
        }

    ENDCONF

        package NginxPerlTest;

        use strict;
        use warnings;
        no  warnings 'uninitialized';

        use Nginx;
        use Nginx::HTTP;

        our $PEER;

        sub Nginx::reply_finalize {
            my $r   = shift;
            my $buf = shift || '';
            my $chunked = shift;

            $r->header_out ('x-errno', int ( $! ));
            $r->header_out ('x-errstr', "$!");
            $r->header_out ('Content-Length', length ( $buf ))
                    unless  $chunked;
            $r->send_http_header ('text/html; charset=UTF-8');

            $r->print ($buf)
                    unless  $r->header_only;

            $r->send_special (NGX_HTTP_LAST);
            $r->finalize_request (NGX_OK);
        }


        sub handler {
            my ($r) = @_;

            $r->main_count_inc;

            if ($r->uri eq '/') {

                $r->send_http_header ('text/html; charset=UTF-8');
                $r->print ("foo");
                $r->flush;
                $r->print ("bar");
                $r->flush;
                $r->print ("baz");
                $r->flush;
                $r->send_special (NGX_HTTP_LAST);
                $r->finalize_request (NGX_OK);

           } elsif ($r->uri eq '/unchunked') {

                $r->reply_finalize ("UNCHUNKED");

           } elsif ($r->uri eq '/test1') {

                my $buf = "GET / HTTP/1.1"   . "\x0d\x0a" .
                          "Host: localhost"  . "\x0d\x0a" .
                          ""                 . "\x0d\x0a"   ;

                ngx_http $PEER, $buf, sub {
                    
                    my ($headers, $body_ref) = @_;
                     
                    if ($body_ref) {
                        $r->reply_finalize ($$body_ref);
                    } elsif ($! == NGX_ETIMEDOUT) {
                        $r->reply_finalize ("TIMEDOUT");
                    } else {
                        $r->reply_finalize ("ERROR");
                    }
                };
           } elsif ($r->uri eq '/test2') {

                my $buf = "GET /unchunked HTTP/1.1"   . "\x0d\x0a" .
                          "Host: localhost"           . "\x0d\x0a" .
                          ""                          . "\x0d\x0a"   ;

                ngx_http $PEER, $buf, sub {
                    
                    my ($headers, $body_ref) = @_;
                     
                    if ($body_ref) {
                        $r->reply_finalize ($$body_ref);
                    } elsif ($! == NGX_ETIMEDOUT) {
                        $r->reply_finalize ("TIMEDOUT");
                    } else {
                        $r->reply_finalize ("ERROR");
                    }
                };

            } else {
                $r->finalize_request (500);
            }

            return NGX_DONE;
        }


        1;

    ENDPKG

    my $child = fork_nginx_die $nginx, $dir;
    my $res;

    wait_for_peer $peer, 2;


    TESTS: for (1 .. 3) {

        $res = http_get  $peer, '/test1', 2;

        is $res, 'foobarbaz', "proxy to chunked self"
            or diag (cat_nginx_logs $dir), last TESTS;

        $res = http_get  $peer, '/test2', 2;

        is $res, 'UNCHUNKED', "proxy to unchunked self"
            or diag (cat_nginx_logs $dir), last TESTS;

        $res = http_get  $peer, '/test1', 2;

        is $res, 'foobarbaz', "proxy to chunked self 2"
            or diag (cat_nginx_logs $dir), last TESTS;
    }

    undef $child;
}


