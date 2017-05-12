#!perl
use lib 't/lib';
use Test::Sietima;
use Email::Address;
use URI;
use Sietima::HeaderURI;

subtest 'new' => sub {
    is(
        Sietima::HeaderURI->new({
            uri => 'http://foo/',
            comment => 'a thing',
        })->as_header_raw,
        '<http://foo/> (a thing)',
        'normal constructor call',
    );

    is(
        Sietima::HeaderURI->new(
            '(comment) address@example.com',
        )->as_header_raw,
        '<mailto:address@example.com> (comment)',
        'string, address+comment',
    );

    is(
        Sietima::HeaderURI->new(
            'http://some/url'
        )->as_header_raw,
        '<http://some/url>',
        'string, URI',
    );

    is(
        Sietima::HeaderURI->new(
            { scheme => 'https', host => 'foo', path => [1,2,3] }
        )->as_header_raw,
        '<https://foo/1/2/3>',
        'hashref, URI::FromHash',
    );

    is(
        Sietima::HeaderURI->new(
            URI->new('http://bar')
        )->as_header_raw,
        '<http://bar>',
        'URI object',
    );

    is(
        Sietima::HeaderURI->new(
            Email::Address->parse('(comment) address@example.com'),
        )->as_header_raw,
        '<mailto:address@example.com> (comment)',
        'Email::Address object',
    );
};


subtest 'new_from_address' => sub {

    is(
        Sietima::HeaderURI->new_from_address(
            '(comment) address@example.com',
        )->as_header_raw,
        '<mailto:address@example.com> (comment)',
        'string',
    );

    is(
        Sietima::HeaderURI->new_from_address(
            '(comment) address@example.com',
            { subject => 'test me' },
        )->as_header_raw,
        '<mailto:address@example.com?subject=test+me> (comment)',
        'string and hashref',
    );
};

done_testing;
