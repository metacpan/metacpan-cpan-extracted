package Mojo::Downloader;

# ABSTRACT: a simple download tool
use Momo;

use File::Basename qw(dirname);
use YAML qw(Dump);
use Mojo::UserAgent;
use Coro;
use Coro::Semaphore;
use AnyEvent;
use Storable;

extends 'Mojo::EventEmitter';

our $VERSION = 0.2;

has ua => sub { Mojo::UserAgent->new };
has interval     => 1;
has cv           => sub { 
    my $condvar = AnyEvent->condvar;
    $condvar->cb( sub { shift->recv } );
    $condvar;
};
has max_currency => 10;
has sem          => sub { Coro::Semaphore->new( shift->max_currency ) };
has cookie_file  => sub { $ENV{MOJO_COOKIE_FILE} };

sub new {
    my ( $class, @args ) = @_;
    my $self = $class->SUPER::new(@args);
    if ( $self->cookie_file and -s $self->cookie_file > 0 ) {
        eval { $self->ua->cookie_jar( retrieve $self->cookie_file ) };
        die "cookie_file must save as Storable mode" if $@;
    }
    $self->on(
        download => sub {
            my ( $ua, $tx, $file, $r ) = @_;
            my $url           = $tx->req->url;
            my $content_lenth = $tx->res->headers->content_length;
            if ( $tx->success ) {
                if ( defined $file and -e dirname($file) ) {
                    $tx->res->content->asset->move_to($file);
                    if ( -s $file == $content_lenth ) {
                        print "downloaded $url => $file success!\n";
                        $r->{$file} = 1 if ref $r eq ref {};
                    }
                    else {
                        warn "file => $file not fully downloaded \n";
                    }
                }
            }
            else {
                warn "download url => " . $tx->req->url . " ".$tx->res->code."failed";
            }
        }
    );

    return $self;
}

sub set_max_currency {
    my ( $self, $limit ) = @_;
    $self->sem( Coro::Semaphore->new($limit) );
    $self->max_currency($limit);
}

sub run{
    shift->cv->recv;
}

sub _async_request {
    my ( $self, $url, $options ) = @_;

    $options ||= {};
    my $on_header = delete $options->{on_header};
    my $on_body   = delete $options->{on_body};
    my $cookies   = delete $options->{cookies};
    my $form      = delete $options->{form};
    my $method    = delete $options->{method};
    my $headers   = delete $options->{headers};
    my $file      = delete $options->{file};

    my $results = $options->{results};
    $method  ||= 'get';
    $headers ||= {};
    $form    ||= {};

    if ($url) {
        $self->ua->cookie_jar($cookies) if ref $cookies;
        async_pool {
            $self->sem->down;
            $self->cv->begin;
            $self->ua->$method(
                $url => $headers => form => $form => sub {
                    my ( $ua, $tx ) = @_;
                    Coro::AnyEvent::sleep($self->interval) if $self->interval;
                    $self->emit(
                        download => $ua,
                        $file, $tx, $options->{results}
                    );
                    $self->sem->up;
                    $self->cv->end;
                }
            );
        };
    }
    return sub { $self->cv->recv };
}

sub download {
    my ( $self, $url, $file ) = @_;
    return $self->_async_request( $url, { file => $file } );
}

1;

__END__

=head1 NAME

A simple async-download tool written by mojo and anyevent.Maybe u can download
file by L<Mojo::UserAgent>,but sometimes if you feel lazy ,you can try this module.

=head1 SYNOPSIS

    my $url = 'http://dldir1.qq.com/qqfile/QQforMac/QQ_V3.0.2.dmg';
    my $d   = Mojo::Downloader->new;
    $d->set_max_currency(5); # set this,every time download will be limited 5 files

    for ( 1 .. 50) {
        my $file = "/tmp/macqq_" . $_ . ".dmg";
        $d->download( $url, $file );
    }
    $d->cv->recv;

    # download 1 file
    $d->download($url,$file)->recv;

    # customize your own downloader
    $d->on( download => sub {
        my ($ua,$tx,$file,$options) = @_;

        # do some stuff here 
        },`
    );

=head1 AUTHOR

Copyright (C) <2014>, <niumang>.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

# niumang // vim: ts=4 sw=4 expandtab
# TODO - Edit.
