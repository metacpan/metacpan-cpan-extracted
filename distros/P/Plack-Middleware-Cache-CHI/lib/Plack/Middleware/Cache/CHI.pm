use strict;
package Plack::Middleware::Cache::CHI;
our $AUTHORITY = 'cpan:PNU';
# ABSTRACT: Caching Reverse Proxy for Plack

use warnings;
use parent qw/Plack::Middleware/;

use Plack::Util::Accessor qw( chi rules scrub cachequeries trace );
use Data::Dumper;
use Plack::Request;
use Plack::Response;
use Time::HiRes qw( gettimeofday );

our $VERSION = '0.102'; # VERSION

our @trace;
our $timer_call;
our $timer_pass;

sub _uinterval {
    my ( $t0, $t1 ) = ( @_, [gettimeofday] );
    ($t1->[0] - $t0->[0]) * 1_000_000 + $t1->[1] - $t0->[1];
}

sub call {
    my ($self,$env) = @_;

    ## Pass-thru streaming responses
    return $self->app->($env)
        if ( ref $env eq 'CODE' );

    ## Localize trace for this request
    local @trace = ();
    local $timer_pass = undef;
    local $timer_call = [gettimeofday];

    my $req = Plack::Request->new($env);
    my $r = $self->handle($req);
    my $res = Plack::Response->new(@$r);

    ## Add trace and cache key to response headers
    $timer_call = _uinterval($timer_call);
    my $trace = join q{, }, @trace;
    my $key = $self->cachekey($req);

    ## The subrequest is timed separately
    if ( $timer_pass ) {
        $timer_call -= $timer_pass;
        $res->headers->push_header(
            'X-Plack-Cache-Time-Pass' => "$timer_pass us",
        );
    }

    $res->headers->push_header(
        'X-Plack-Cache' => $trace,
        'X-Plack-Cache-Key' => $key,
        'X-Plack-Cache-Time' => "$timer_call us",
    );

    $res->finalize;
}

sub handle {
    my ($self,$req) = @_;

    if ( $req->method eq 'GET' or $req->method eq 'HEAD' ) {
        if ( $req->headers->header('Expect') ) {
            push @trace, 'expect';
            $self->pass($req);
        } else {
            $self->lookup($req);
        }
    } else {
        $self->invalidate($req);
    }
}

sub pass {
    my ($self,$req) = @_;
    push @trace, 'pass';
    $timer_pass = [gettimeofday];

    my $res = $self->app->($req->env);

    $timer_pass = _uinterval($timer_pass);
    return $res;
}

sub invalidate {
    my ($self,$req) = @_;
    push @trace, 'invalidate';
    $self->chi->remove( $self->cachekey($req) );
    $self->pass($req);
}

sub match {
    my ($self, $req) = @_;

    my $path;
    my $opts;

    my @rules = @{ $self->rules || [] };
    while ( @rules || return ) {
        my $match = shift @rules;
        $opts = shift @rules;
        $path = $req->path_info;
        last if 'CODE' eq ref $match ? $match->($path) : $path =~ $match;
    }
    return $opts;
}

sub lookup {
    my ($self, $req) = @_;
    push @trace, 'lookup';

    my $opts = $self->match($req);

    return $self->pass($req)
        if not defined $opts;

    return $self->invalidate($req)
        if ( $req->param and not $self->cachequeries );

    my $entry = $self->fetch( $req );
    my $res = [ 500, ['Content-Type','text/plain'], ['ISE'] ];

    if ( defined $entry ) {
        push @trace, 'hit';
        $res = $entry->[1];
        return $self->invalidate($req)
            if not $self->valid($req,$res);
    } else {
        push @trace, 'miss';
        $res = $self->delegate($req);
        $self->store($req,$res,$opts)
            if $self->valid($req,$res);
    }
    return $res;
}

sub valid {
    my ($self, $req, $res) = @_;

    my $res_status = $res->[0];

    return
        unless (
            $res_status == 200 or
            $res_status == 203 or
            $res_status == 300 or
            $res_status == 301 or
            $res_status == 302 or
            $res_status == 404 or
            $res_status == 410
        );

    return 1;
}

sub cachekey {
    my ($self, $req) = @_;

    my $uri = $req->uri->canonical;

    $uri->query(undef)
        if not $self->cachequeries;

    $uri->as_string;
}

sub fetch {
    my ($self, $req) = @_;
    push @trace, 'fetch';

    my $key = $self->cachekey($req);
    $self->chi->get( $key );
}

sub store {
    my ($self, $req, $res, $opts) = @_;
    push @trace, 'store';

    my $key = $self->cachekey($req);
    $self->chi->set( $key, [$req->headers,$res], $opts );
}

sub delegate {
    my ($self, $req, $opts) = @_;
    push @trace, 'delegate';

    my $res = $self->pass($req);
    foreach ( @{ $self->scrub || [] } ) {
        Plack::Util::header_remove( $res->[1], $_ );
    }

    my $body;
    Plack::Util::foreach( $res->[2], sub {
        $body .= $_[0] if $_[0];
    });

    return [ $res->[0], $res->[1], [$body] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Cache::CHI - Caching Reverse Proxy for Plack

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    my $chi = CHI->new(
        driver => 'File',
        root_dir => 'common/cache',
    );

    enable 'Cache::CHI', chi => $chi, rules => [
        qr{^/api/}          => undef,
        qr{\.(jpg|png)$}    => { expires_in => '5 min' },
    ], scrub => [ 'Set-Cookie' ], cachequeries => 1;

=head1 DESCRIPTION

Enable HTTP caching for Plack-based applications.

Mathing URI's (rules) are cached with the specified
expiry time / ttl value to the CHI cache.

Current implementation (on master branch) does not
support cache validation. See devel branch for work in
progress towards this.

=for test_synopsis use Plack::Builder;

=head1 SEE ALSO

This module is largely based on Rack::Cache by Ryan Tomayko.
See http://rtomayko.github.com/rack-cache/ for more information.

This module was earlier called Plack::Middleware::Cache and available
only thru github because of name conflict with another similar CPAN module.

=head1 AUTHOR

Panu Ervamaa <pnu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2015 by Panu Ervamaa.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
