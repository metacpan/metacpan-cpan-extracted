#!perl

use Test::Most;
use Paginator::Lite;

my ( $pag, %args );

%args = (
    base_url   => '/foo/bar',
    curr       => 5,
    frame_size => 5,
    items      => 200,
    page_size  => 10,
    params     => {
        foo => 'abc',
        bar => '123',
    },
);

##############################################################################

$pag = Paginator::Lite->new(%args);

is( $pag->first_url,   '/foo/bar/1',  'First URL with path mode' );
is( $pag->prev_url,    '/foo/bar/4',  'Prev URL with path mode' );
is( $pag->curr_url,    '/foo/bar/5',  'Curr URL with path mode' );
is( $pag->next_url,    '/foo/bar/6',  'Next URL with path mode' );
is( $pag->last_url,    '/foo/bar/20', 'Last URL with path mode' );
is( $pag->page_url(7), '/foo/bar/7',  'URL from givenpage with path mode' );

##############################################################################

$pag = Paginator::Lite->new( %args, mode => 'query' );
my @tests = (
    {
        method   => 'first_url',
        name     => 'First URL with query mode',
        expected => URI->new('/foo/bar?bar=123&foo=abc&page=1'),
    },
    {
        method   => 'prev_url',
        name     => 'Prev URL with query mode',
        expected => URI->new('/foo/bar?bar=123&foo=abc&page=4'),
    },
    {
        method   => 'curr_url',
        name     => 'Curr URL with query mode',
        expected => URI->new('/foo/bar?bar=123&foo=abc&page=5'),
    },
    {
        method   => 'next_url',
        name     => 'Next URL with query mode',
        expected => URI->new('/foo/bar?bar=123&foo=abc&page=6'),
    },
    {
        method   => 'last_url',
        name     => 'Last URL with query mode',
        expected => URI->new('/foo/bar?bar=123&foo=abc&page=20'),
    },
    {
        method   => 'page_url',
        arg      => 7,
        name     => 'URL for given page with query mode',
        expected => URI->new('/foo/bar?bar=123&foo=abc&page=7'),
    },
);

foreach my $test (@tests) {
    my $method   = $test->{method};
    my $arg      = $test->{arg};
    my %got      = URI->new( $pag->$method($arg) )->query_form;
    my %expected = $test->{expected}->query_form;

    is_deeply( \%got, \%expected, $test->{name} );
}

##############################################################################

done_testing;

