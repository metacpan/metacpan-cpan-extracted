use Test::More tests => 14;

use Protocol::Yadis::Document::Service;
use Protocol::Yadis::Document::Service::Element;

my $s = Protocol::Yadis::Document::Service->new;

is("$s", '<Service></Service>');

$s->attrs([priority => 10]);
is($s->attr('priority'), 10);
is("$s", '<Service priority="10"></Service>');

$s->attr(priority => 4);
is("$s", '<Service priority="4"></Service>');
$s->attr(priority => undef);

$s->elements(
    [   Protocol::Yadis::Document::Service::Element->new(
            name    => 'URI',
            content => 'foo'
        ),
        Protocol::Yadis::Document::Service::Element->new(
            name    => 'Type',
            content => 'bar'
        ),
        Protocol::Yadis::Document::Service::Element->new(
            name    => 'URI',
            content => 'baz'
        )
    ]
);
is($s->elements->[0]->name, 'Type');
is($s->elements->[1]->name, 'URI');
is($s->elements->[2]->name, 'URI');

is($s->element('Type')->[0]->content, 'bar');
is($s->element('URI')->[0]->content, 'foo');
is($s->element('URI')->[1]->content, 'baz');

is($s->Type->[0]->content, 'bar');
is($s->URI->[0]->content, 'foo');
is($s->URI->[1]->content, 'baz');

$s->elements(
    [   Protocol::Yadis::Document::Service::Element->new(
            attrs   => [priority => 4],
            name    => 'URI',
            content => 'foo'
        ),
        Protocol::Yadis::Document::Service::Element->new(
            name    => 'Type',
            content => 'foo'
        ),
        Protocol::Yadis::Document::Service::Element->new(
            name    => 'URI',
            content => 'foo'
        ),
        Protocol::Yadis::Document::Service::Element->new(
            attrs   => [priority => 0],
            name    => 'URI',
            content => 'foo'
        ),
        Protocol::Yadis::Document::Service::Element->new(
            name    => 'URI',
            content => 'bar'
        )
    ]
);
is("$s", qq|<Service>\n <Type>foo</Type>\n <URI priority="0">foo</URI>\n <URI priority="4">foo</URI>\n <URI>foo</URI>\n <URI>bar</URI>\n</Service>|);

