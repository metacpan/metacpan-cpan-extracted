use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = sub { [200, ['Content-Type' => 'text/plain'], [$_[0]->{'QUERY_STRING'}]] };

sub test_app(@) { ##no critique
    my ($app, $query, $expect, $msg) = @_;

    test_psgi app => $app, client => sub {
        my $cb = shift;
        my $res = $cb->(GET "/$query");
        is $res->content, $expect, $msg;
    };
}

my $rebuild = builder {
    enable 'Rewrite::Query', modify => sub { };
    $app;
};

test_app $rebuild, '?a=x&a= &b', 'a=x&a=%20&b=';
test_app $rebuild, '?foo+bar', 'foo=&bar=';

my $modify = builder {
    # rename all 'foo' paramaters to 'bar'
    enable 'Rewrite::Query', map => sub {
        my ($key, $value) = @_;
        (($key eq 'foo' ? 'bar' : $key), $value);
    };
    # add a query parameter 'doz' with value '1'
    enable 'Rewrite::Query', modify => sub {
        $_->add('doz', 1);
    };
    $app;
};

test_app $modify, '?foo=baz&foo=doz&doz=0', 'bar=baz&bar=doz&doz=0&doz=1';

$modify = builder {
    enable 'Rewrite::Query', 
        map => sub {
            my ($key, $value) = @_;
            (($key eq 'foo' ? 'bar' : $key), $value);
        },
        modify => sub {
            $_->add('doz', 1);
        };
    $app;
};

test_app $modify, '?foo=baz&foo=doz&doz=0', 'bar=baz&bar=doz&doz=0&doz=1';

done_testing;
