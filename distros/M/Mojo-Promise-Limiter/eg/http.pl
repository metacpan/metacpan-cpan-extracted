#!/usr/bin/env perl

package Mojo::Promise::Limiter::UserAgent {
    use Mojo::Base 'Mojo::EventEmitter', -signatures;

    use Mojo::Promise::Limiter;
    use Mojo::URL;
    use Mojo::UserAgent;
    use Scalar::Util 'blessed';

    has concurrency => 0;
    has limiters => sub { +{} };
    has http => sub { Mojo::UserAgent->new(max_connections => 0) };

    sub new ($class, $concurrency) {
        $class->SUPER::new(concurrency => $concurrency);
    }

    sub _limiter ($self, $url) {
        my $key;
        if (blessed $url && $url->isa('Mojo::URL')) {
            $key = $url->host_port;
        } else {
            $key = Mojo::URL->new($url)->host_port;
        }
        $self->{limiters}{$key} ||= do {
            my $limiter = Mojo::Promise::Limiter->new($self->concurrency);
            for my $event (qw(error run remove queue dequeue)) {
                $limiter->on($event => sub ($, $name) { $self->emit($event => $name) });
            }
            $limiter;
        };
    }

    sub get_p ($self, $url, @argv) {
        $self->_limiter($url)->limit(sub () { $self->http->get_p($url, @argv) }, $url);
    }
}

use Mojo::Base -signatures;
use Mojo::Promise;

# limit concurrent http connection; max 3 connections per host
my $http = Mojo::Promise::Limiter::UserAgent->new(3);
$http->on(run    => sub ($, $url) { warn "---> Doing $url\n"});
$http->on(remove => sub ($, $url) { warn "---> Done  $url\n"});

Mojo::Promise->all_settled(
    $http->get_p("https://metacpan.org/release/App-cpm"),
    $http->get_p("https://metacpan.org/release/Minilla"),
    $http->get_p("https://metacpan.org/release/Mouse"),
    $http->get_p("https://metacpan.org/release/Perl6-Build"),
    $http->get_p("https://metacpan.org/release/Test-CI"),
    $http->get_p("https://www.cpan.org/"),
)->wait;
