use strict;
use warnings;
use Test::More;

use Mojo::Promise::Limiter;
use Mojo::Promise;
use Mojo::IOLoop;

my $limiter = Mojo::Promise::Limiter->new(2);

my @job = 'a' .. 'e';

Mojo::Promise->all(
    map { my $name = $_; $limiter->limit(sub { job($name) }) } @job,
)->then(sub {
    my @result = @_;
    is_deeply \@result, [ map { ["job $_"] } 'a'..'e' ];
})->wait;

sub job {
    my $name = shift;
    my $text = "job $name";
    return Mojo::Promise->new(sub {
        my $resolve = shift;
        Mojo::IOLoop->timer(0.1 => sub {
            $resolve->($text);
        });
    });
}

done_testing;
