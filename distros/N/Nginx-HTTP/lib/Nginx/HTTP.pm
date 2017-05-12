package Nginx::HTTP;

use strict;
use warnings;
no  warnings 'uninitialized';
use bytes;

require Exporter;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(ngx_http_client ngx_http);
our $VERSION = '0.04';

use Nginx;
# use Nginx::Verbose;
use HTTP::Parser2::XS;

sub CRLF { "\x0d\x0a" }
sub ngx_http_client ($$$$);

our $TIMEOUT = 5;
my  %CLIENTS;


sub ngx_http_client ($$$$) {
    my ($ip, $port, $timeout, $ssl) = @_;

    my ($error, $connect, $readwrite, $push, $enqueue, 
        $read, $read_header, $read_identity, $read_chunked, $read_tileof,
        $c, @queue, $active, %headers, $keepalive, $min, $max);

    my $buf         = '';
    my $decoded_buf = '';


    $push = sub {

        return 0 
             if  @queue == 0 || 
                 $active ;

        $active = shift @queue;

        $buf = ref $active->[0] eq 'SCALAR' 
                    ? ${$active->[0]} 
                    : $active->[0];

        delete $active->[0];    #  saving memory

        &$connect (),
          return 0
                unless  $c;

        return 1;
    };


    $enqueue = sub {

        push @queue, \@_;

        &$push ()  &&
          ngx_write $c;
    };


    $error = sub {

        undef $c;

        if ($active) {
            my $cb = $active->[1];

            &$cb (undef);

            undef $active;
        }
        
        $buf         = '';
        $decoded_buf = '';

        &$push ()  &&
          ngx_write $c;
    };


    $connect = sub {

        ngx_connector $ip, $port, $timeout, sub {

            &$error (),
              return NGX_CLOSE
                    if  $!;

            $c = shift;

            if ($ssl) {

                ngx_ssl_handshaker $c, $timeout, sub {

                    &$error (),
                      return NGX_CLOSE
                            if  $!;

                    &$readwrite ();

                    return NGX_WRITE;
                };

                return NGX_SSL_HANDSHAKE;

            } else {

                &$readwrite ();

                return NGX_WRITE;
            }
        };
    };
 

    $readwrite = sub {

        ngx_writer $c, $buf, $timeout, sub {

            &$error (),
              return NGX_CLOSE
                    if  $!;

            $buf         = '';
            $decoded_buf = '';

            $read = $read_header;

            $min = 
            $max = 0;

            return NGX_READ;
        };

        ngx_reader $c, $buf, $min, $max, $timeout, sub { 

            return &$read;
        };
    };
 

    $read_header = sub {

        &$error (),
          return NGX_CLOSE
                if  $!;

        %headers = ();
        my $len = parse_http_response $buf, \%headers;

        &$error (),                     #  error
          return NGX_CLOSE              #  and closing connection
                if  !defined $len ||    #  if parser fails
                    $len == -1    ||
                    ( $len == -2 &&
                      length($buf) > 4096 )  ; 

        return NGX_READ
              if  $len == -2;

        $buf = substr $buf, $len;

        $keepalive = $headers{'_keepalive'}  && 
                     ( !exists $headers{'connection'} ||
                        $headers{'connection'}->[0] !~ /^close$/i );

        if ($headers{'_status'} == 304) {

            $read = $read_identity;
            return &$read ();
        } elsif ($headers{'_content_length'}) {

            if (length($buf) < $headers{'_content_length'}) {
                $min = $max = $headers{'_content_length'};
                $read = $read_identity;
                return NGX_READ;
            } else {
                $read = $read_identity;
                return &$read ();
            }
        } else {
            if ($headers{'transfer-encoding'} && 
                $headers{'transfer-encoding'}->[0] =~ /^chunked$/i) 
            {
                $read = $read_chunked;

                return &$read ()
                      if  length($buf) > 0;

                return NGX_READ;

            } else {

                $read = $read_tileof;
                $keepalive = 0;

                return &$read ()
                      if  length($buf) > 0;

                return NGX_READ;
            }
        }
    };
 

    $read_identity = sub {

        &$error (),
          return NGX_CLOSE
                if  $!;


        my $cb = $active->[1];

        &$cb (\%headers, \$buf);

        undef $active;
        %headers = ();
        $buf = '';


        &$error (),
          return NGX_CLOSE
                unless  $keepalive;

        &$push ()  &&
          return NGX_WRITE;

        $read = $read_header,
          return NGX_READ;
    };
 
    
    $read_tileof = sub {

        &$error (),
          return NGX_CLOSE
                if  $! && $! != NGX_EOF;

        return NGX_READ
              unless  $! == NGX_EOF;


        my $cb = $active->[1];

        &$cb (\%headers, \$buf);

        undef $active;
        %headers = ();
        $buf = '';
       

        &$error (),
          return NGX_CLOSE;
    };


    $read_chunked = sub {

        &$error (),
          return NGX_CLOSE
                if  $!;

        my $done;

        while ( $buf =~ / ^  ( [0-9a-fA-F]{1,8} )  \x0d\x0a /sx ) {

            my $len = hex $1;

            if ($len && length($buf) < length($&) + $len + 2 + 5) {

                $min = length($&) + $len + 2 + 5; 
                $max = 0; 
                return NGX_READ;

            } elsif ($len) {

                $decoded_buf .= substr $buf, length($&), $len;
                $buf          = substr $buf, length($&) + $len + 2;

            } else {

                if (length($buf) < length($&) + 2) {
                    $min = 
                    $max = length($&) + 2;
                    return NGX_READ;
                } 

                $buf = substr $buf, length($&) + 2;
                $done = 1;
                last;
            }
        }

        if (!$done && $buf && length($buf) < 12) {

            $min = 
            $max = 0;
            return NGX_READ;
        }


        my $cb = $active->[1];

        &$cb (\%headers, \$decoded_buf);

        undef $active;
        %headers = ();
        $buf = '';
        $decoded_buf = '';


        &$error (),
          return NGX_CLOSE
                if  !$done || !$keepalive;

        &$push ()  &&
          return NGX_WRITE;

        $read = $read_header,
          return NGX_READ;
    };


    return $enqueue;
}


sub ngx_http {
    my $dest    = shift;
    my $enqueue = $CLIENTS{$dest};

    &$enqueue,
      return
            if defined $enqueue;

    my ($ip, $port, $rest) = split ':', $dest;

    unless ($ip =~ /^ \d{1,3} (?: \. \d{1,3} ){3} $/x) {
        my $cb = pop;
        $! = NGX_EINVAL;
        &$cb ();
        return;
    }

    my %args = map { split /\s*=\s*/, $_, 2 } split /\s*[:;]\s*/, $rest;

    $args{'ssl'}     = 0           unless  $args{'ssl'};
    $args{'timeout'} = $TIMEOUT    unless  $args{'timeout'};

    $enqueue = ngx_http_client $ip, $port, $args{'timeout'}, $args{'ssl'};

    $CLIENTS{$dest} = $enqueue;

    &$enqueue,
      return;
}


1;
__END__

=head1 NAME

Nginx::HTTP - asynchronous http client for nginx-perl

=head1 SYNOPSIS

    use Nginx;
    use Nginx::HTTP;
    
    ngx_http "1.2.3.4:80", "GET / HTTP/1.1"   . "\x0d\x0a" .
                           "Host: localhost"  . "\x0d\x0a" .
                           ""                 . "\x0d\x0a"   , sub {
        
        my ($headers, $buf_ref) = @_;
        
        unless ($headers) {
            ngx_log_error $!, "error";
            return;
        }
        
        ngx_log_notice 0, "got $headers->{'_status'}";
        ...
    };

=head1 DESCRIPTION

Fast and simple asynchronous http client for B<nginx-perl>. 
Supports keepalive.

=head1 EXPORT

    ngx_http
    ngx_http_client

=head1 FUNCTIONS

=head3 C<ngx_http "$ip:$port:key=value;key=value...", $request, sub { }>

Establishes new connection with C<$ip:$port> and sends raw HTTP 
request. C<$request> should be either scalar or scalar reference. 
Additionally there are two options available: C<timeout> and C<ssl>. E.g.:

    ngx_http "1.2.3.4:443:ssl=1;timeout=15", ...
    ngx_http "1.2.3.4:80:timeout=15", ...
    ngx_http "1.2.3.4:80", ...

Calls back with parsed response header in C<$_[0]> and scalar reference to 
the body in C<$_[1]>. 

    $headers =  {  _status        => 503,
                   content-type   => ['text/html'],
                   content-length => [1234],
                   ...                              };
    
    $body = \"foobar";

C<$body> is cleared right after the callback, so you have to copy its
content if you want to use it later.

On error calls back without any arguments. Tries to reconnect on the
next request.

For now every connection is cached forever. But you can use C<ngx_http_client>
to create desired caching behaviour. 

    ngx_http "1.2.3.4:80", "GET / HTTP/1.1"   . "\x0d\x0a" .
                           "Host: localhost"  . "\x0d\x0a" .
                           ""                 . "\x0d\x0a"   , sub {
        
        my ($headers, $body_ref) = @_;
        
        unless ($headers) {
            ngx_log_error $!, "error";
            return;
        }
        
        ngx_log_notice 0, "got $headers->{'_status'}";
        ...
    };

=head1 SEE ALSO

L<Nginx>, L<HTTP::Parser2::XS>

=head1 AUTHOR

Alexandr Gomoliako <zzz@zzz.org.ua>

=head1 LICENSE

Copyright 2012 Alexandr Gomoliako. All rights reserved.

This module is free software. It may be used, redistributed and/or modified 
under the same terms as Perl itself.

=cut

