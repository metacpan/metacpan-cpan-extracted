#!/usr/bin/perl

# Copyright 2012 Alexandr Gomoliako

use strict;
use warnings;
no  warnings 'uninitialized';

use Data::Dumper;
use Test::More;
use Nginx::Test;
use Socket;


my $nginx = find_nginx_perl;
my $dir   = "tmp/t03";

mkdir 'tmp'  unless  -d 'tmp';

plan skip_all => "Can't find executable binary ($nginx) to test"
        if  !$nginx    ||  
            !-x $nginx    ;


# SSL support is required for this test

my %CONFARGS = get_nginx_conf_args_die $nginx;

plan skip_all => "$nginx built without SSL support" 
    unless  $CONFARGS{'--with-http_ssl_module'};


# making sure we can successfully 
# connect to remote hosts  

my $ip = inet_ntoa (inet_aton ("www.google.com"));

wait_for_peer "$ip:443", 1
    or  plan skip_all => "Cannot connect to $ip:443";


plan 'no_plan';


{
    my ($child, $peer) = fork_nginx_handler_die  $nginx, $dir, '',<<'    END';

        use Nginx::HTTP;

        sub CRLF { "\x0d\x0a" }

        sub Nginx::reply_finalize {
            my $r   = shift;
            my $buf = shift || '';

            $r->header_out ('x-errno', int ( $! ));
            $r->header_out ('x-errstr', "$!");
            $r->header_out ('Content-Length', length ( $buf ));
            $r->send_http_header ('text/html; charset=UTF-8');

            $r->print ($buf)
                    unless  $r->header_only;

            $r->send_special (NGX_HTTP_LAST);
            $r->finalize_request (NGX_OK);
        }


        sub handler {
            my ($r) = @_;

            $r->main_count_inc;

            
            my ($ip, $port, $timeout) = split ':', $r->args, 3;

            my $buf = "GET / HTTP/1.1"        . CRLF .
                      "Host: www.google.com"  . CRLF .
                                                CRLF  ;

            ngx_http "$ip:$port:timeout=$timeout;ssl=1", $buf, sub {

                my ($headers, $buf_ref) = @_;
                
                if ($headers && $buf_ref) {
                    $r->reply_finalize ($$buf_ref),
                } else {
                    $r->reply_finalize ('ERROR'),
                }
            };


            return NGX_DONE;
        }

    END


    wait_for_peer $peer, 2;


    for my $i (1 .. 2) {
        my ($body, $headers) = http_get $peer, "/?$ip:443:4", 6;

        ok $body =~ /Google/i, "google over SSL $i"
            or  diag ($body, Dumper ($headers), cat_nginx_logs $dir),
                  last;

        ok $body =~ />\s*$/is, "reponse ends with angle bracket $i"
            or  diag ($body, Dumper ($headers), cat_nginx_logs $dir),
                  last;

        is $headers->{'x-errno'}->[0], 0, "clean errno"
            or  diag ("errno = $headers->{'x-errno'}");
    }


    undef $child;
}



