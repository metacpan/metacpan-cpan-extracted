use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Silki::Test::FakeSchema;

use Silki::Schema::Domain;

{
    my $domain = Silki::Schema::Domain->new(
        domain_id    => 1,
        web_hostname => 'host.example.com',
        requires_ssl => 0,
        _from_query  => 1,
    );

    is(
        $domain->uri( with_host => 1 ), 'http://host.example.com/',
        'uri() for domain'
    );

    is(
        $domain->application_uri(
            with_host => 1, path => '/foo/bar', query => { x => 42 },
        ),
        'http://host.example.com/foo/bar?x=42',
        'application_uri() with path'
    );
}

{
    my $domain = Silki::Schema::Domain->new(
        domain_id    => 1,
        web_hostname => 'host.example.com',
        requires_ssl => 1,
        _from_query  => 1,
    );

    is(
        $domain->uri( with_host => 1 ), 'https://host.example.com/',
        'uri() for domain that requires ssl'
    );
}

done_testing();
