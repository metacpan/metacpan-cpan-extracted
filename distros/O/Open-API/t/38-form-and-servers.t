#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;

# Form request bodies, media ranges, allowEmptyValue, and the opt-in server
# prefix. All of these were found by probing rather than by testing, which is
# how the $ref and readOnly bugs survived a release - so what the probes
# showed is pinned here.
#
# The assertions that carry the most weight are the STRUCTURAL ones. A body
# decoder that returned an empty hash would reject a required-field schema
# just as convincingly as one that parsed correctly, so it is not enough to
# check the verdict: the decoded field names and values have to be seen.

my $JSONCT = sub { { 'content-type' => $_[0] } };

sub body_api {
    my ($ctype, $schema, %extra) = @_;
    my %media = (schema => $schema);
    $media{encoding} = $extra{encoding} if $extra{encoding};
    return Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => { post => {
            operationId => 'op',
            requestBody => { required => 1, content => { $ctype => \%media } },
            responses   => { 200 => { description => 'ok' } },
        } } },
    });
}

my $OPEN = { type => 'object' };

# ---- urlencoded -------------------------------------------------------------
{
    my $api = body_api('application/x-www-form-urlencoded', $OPEN);
    my $CT  = $JSONCT->('application/x-www-form-urlencoded');

    my ($ok, $p) = $api->validate_request(op => { header => $CT, body => 'a=1&b=2' });
    ok($ok, 'a urlencoded body is accepted');
    is_deeply($p->{body}, { a => '1', b => '2' },
              '...decoded into fields, not left as one string');

    ($ok, $p) = $api->validate_request(op => { header => $CT, body => 't=x&t=y' });
    is_deeply($p->{body}, { t => [ 'x', 'y' ] },
              'a repeat key becomes a list, as a form naturally carries one');

    ($ok, $p) = $api->validate_request(op => { header => $CT, body => 'a=hello+world' });
    is($p->{body}{a}, 'hello world', '+ decodes to a space');
}

# the schema is now actually applied - this is the silent hole that was closed
{
    my $api = body_api('application/x-www-form-urlencoded',
                       { type => 'object', required => ['a'],
                         properties => { a => { type => 'string' } } });
    my ($ok, $errs) = $api->validate_request(op => {
        header => $JSONCT->('application/x-www-form-urlencoded'),
        body   => 'nope=1' });
    ok(!$ok, 'a urlencoded body violating its schema is REFUSED');
    is(($errs->[0]{keyword} || ''), 'required',
       '...by the schema, which used never to be applied at all');
}

# form values are text on the wire, so they coerce like parameters
{
    my $api = body_api('application/x-www-form-urlencoded',
                       { type => 'object',
                         properties => { n => { type => 'integer' } } });
    my ($ok) = $api->validate_request(op => {
        header => $JSONCT->('application/x-www-form-urlencoded'), body => 'n=3' });
    ok($ok, 'a form value coerces to its declared type');
}

# ---- multipart --------------------------------------------------------------
{
    my $api = body_api('multipart/form-data', $OPEN);
    my $CT  = $JSONCT->('multipart/form-data; boundary=xx');
    my $B   = join '', map { "$_\r\n" }
        '--xx', 'Content-Disposition: form-data; name="a"', '', 'hello',
        '--xx', 'Content-Disposition: form-data; name="b"', '', 'world',
        '--xx--';

    my ($ok, $p) = $api->validate_request(op => { header => $CT, body => $B });
    ok($ok, 'a multipart body is accepted');
    is_deeply($p->{body}, { a => 'hello', b => 'world' },
              '...with the boundary walk yielding real names and values');

    my $R = join '', map { "$_\r\n" }
        '--xx', 'Content-Disposition: form-data; name="t"', '', 'x',
        '--xx', 'Content-Disposition: form-data; name="t"', '', 'y',
        '--xx--';
    (undef, $p) = $api->validate_request(op => { header => $CT, body => $R });
    is_deeply($p->{body}, { t => [ 'x', 'y' ] }, 'a repeat part becomes a list');
}

# ---- the Encoding Object ----------------------------------------------------
#
# A property whose encoding names a JSON type carries a document in one field.
# The discriminating body is one that only passes WITH the encoding applied:
# a body that failed either way would go green for the wrong reason.
{
    my $api = body_api('application/x-www-form-urlencoded',
        { type => 'object',
          properties => { a => { type => 'object', required => ['n'],
                                 properties => { n => { type => 'string' } } } } },
        encoding => { a => { contentType => 'application/json' } });
    my $CT = $JSONCT->('application/x-www-form-urlencoded');

    my ($ok, $p) = $api->validate_request(op => {
        header => $CT, body => 'a=%7B%22n%22%3A%22x%22%7D' });   # a={"n":"x"}
    ok($ok, 'an encoded JSON property is decoded before its schema is applied');
    is_deeply($p->{body}{a}, { n => 'x' }, '...and arrives as a structure');

    ($ok) = $api->validate_request(op => {
        header => $CT, body => 'a=%7B%7D' });                    # a={}
    ok(!$ok, 'and it is still held to that schema afterwards');
}

# ---- media ranges -----------------------------------------------------------
{
    my $api = body_api('*/*', $OPEN);
    my ($ok, $p) = $api->validate_request(op => {
        header => $JSONCT->('application/json'), body => '{"a":1}' });
    ok($ok, 'a catch-all range admits a JSON request');
    is_deeply($p->{body}, { a => 1 }, '...decoding it as JSON, per the REQUEST type');

    ($ok, $p) = $api->validate_request(op => {
        header => $JSONCT->('application/x-www-form-urlencoded'), body => 'a=1' });
    is_deeply($p->{body}, { a => '1' },
              'and a form request through the same range decodes as a form');
}

# a declared type we cannot decode still passes through untouched
{
    my $api = body_api('text/plain', $OPEN);
    my ($ok, $p) = $api->validate_request(op => {
        header => $JSONCT->('text/plain'), body => 'anything at all' });
    ok($ok, 'an opaque declared type is still accepted');
    is($p->{body}, 'anything at all', '...with its body preserved, as before');
}

# ---- allowEmptyValue --------------------------------------------------------
{
    my $api = Open::API->new(spec => {
        openapi => '3.1.0', info => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => { get => { operationId => 'op',
            parameters => [ { name => 'v', in => 'query', allowEmptyValue => 1,
                              schema => { type => 'string', minLength => 1 } } ],
            responses  => { 200 => { description => 'ok' } } } } },
    });
    my ($ok) = $api->validate_request(op => { query => 'v=' });
    ok($ok, 'allowEmptyValue permits a present-but-empty query parameter');

    my ($ok2) = $api->validate_request(op => { query => 'v=x' });
    ok($ok2, '...and a non-empty one is still checked normally');
}

# ---- the opt-in server prefix ------------------------------------------------
#
# Off by default: honouring a prefix re-routes an application that already
# mounts so PATH_INFO arrives without it, and that shows up as a silent 404.
sub srv_api {
    my ($servers, $optin) = @_;
    my %args = (spec => {
        openapi => '3.1.0', info => { title => 'T', version => '1.0.0' },
        servers => $servers,
        paths   => { '/pets' => { get => { operationId => 'p',
            responses => { 200 => { description => 'ok' } } } } },
    });
    $args{servers} = 1 if $optin;
    return Open::API->new(%args);
}

my $URL = [ { url => 'https://h.test/api/v1' } ];

{
    my $off = srv_api($URL, 0);
    my ($bare) = $off->match(GET => '/pets');
    my ($pre)  = $off->match(GET => '/api/v1/pets');
    is($bare, 'p', 'default: a bare path routes');
    is($pre, undef, 'default: a prefixed path does NOT - the option is off');
}

{
    my $on = srv_api($URL, 1);
    my ($pre)  = $on->match(GET => '/api/v1/pets');
    my ($bare) = $on->match(GET => '/pets');
    is($pre, 'p', 'servers => 1: the prefix is stripped before routing');
    is($bare, 'p', '...and a path already lacking it still routes');

    # the guard that stops a shared prefix SUBSTRING being eaten
    my ($sub) = $on->match(GET => '/api/v1x/pets');
    is($sub, undef, 'a path merely sharing the prefix as a substring is not stripped');
}

{
    my $tm = srv_api([ { url => 'https://{host}/v1',
                         variables => { host => { default => 'h.test' } } } ], 1);
    my ($ok) = $tm->match(GET => '/v1/pets');
    is($ok, 'p', 'a {variable} in the server URL expands from its default');
}

# ---- allowReserved ----------------------------------------------------------
#
# A CLIENT-side serialization rule: reserved characters MAY go on the wire
# unencoded. Nothing on the validating side can show this - a server decodes
# `a%2Fb` and `a/b` to the same value - so the evidence is the URL the client
# builds, which _request_url exposes without firing a request.
#
# The CONTROL is the assertion that matters. "reserved passed through" and
# "the encoder stopped encoding anything" look identical from the flagged case
# alone; only the unflagged one tells them apart.

SKIP: {
    eval { require Open::API::Client; 1 }
        or skip 'Open::API::Client unavailable', 5;

    my $mk = sub {
        my (%over) = @_;
        my %p = (name => 'v', in => 'query', schema => { type => 'string' }, %over);
        my $api = Open::API->new(spec => {
            openapi => '3.1.0', info => { title => 'T', version => '1.0.0' },
            paths   => { '/t' => { get => { operationId => 'op',
                parameters => [ \%p ],
                responses  => { 200 => { description => 'ok' } } } } },
        });
        return Open::API::Client->new(api => $api, base_url => 'https://h.test');
    };

    my $on  = $mk->(allowReserved => 1)->_request_url('op', { v => 'a/b' });
    my $off = $mk->()->_request_url('op', { v => 'a/b' });

    like($on,  qr{[?&]v=a/b(?:&|$)},   'allowReserved leaves a reserved character unencoded');
    like($off, qr{[?&]v=a%2Fb(?:&|$)}, 'CONTROL: without it the same value is encoded');

    # unreserved characters are untouched either way, and a space still is not
    my $sp = $mk->(allowReserved => 1)->_request_url('op', { v => 'a b' });
    like($sp, qr{v=a%20b}, 'allowReserved does not stop anything else being encoded');

    # the flag governs the VALUE; a name is always encoded, or the separators
    # stop meaning anything
    my $nm = Open::API::Client->new(
        api => Open::API->new(spec => {
            openapi => '3.1.0', info => { title => 'T', version => '1.0.0' },
            paths   => { '/t' => { get => { operationId => 'op',
                parameters => [ { name => 'a&b', in => 'query',
                                  allowReserved => 1,
                                  schema => { type => 'string' } } ],
                responses  => { 200 => { description => 'ok' } } } } } }),
        base_url => 'https://h.test',
    )->_request_url('op', { 'a&b' => 'x' });
    like($nm, qr{[?&]a%26b=x}, '...and a parameter NAME is encoded regardless');

    # a path parameter declaring it is NOT honoured: a reserved character in a
    # segment changes the shape of the path
    my $pathy = Open::API::Client->new(
        api => Open::API->new(spec => {
            openapi => '3.1.0', info => { title => 'T', version => '1.0.0' },
            paths   => { '/t/{v}' => { get => { operationId => 'op',
                parameters => [ { name => 'v', in => 'path', required => 1,
                                  allowReserved => 1,
                                  schema => { type => 'string' } } ],
                responses  => { 200 => { description => 'ok' } } } } } }),
        base_url => 'https://h.test',
    )->_request_url('op', { v => 'a/b' });
    like($pathy, qr{/t/a%2Fb$}, 'a path segment is encoded even when it declares allowReserved');
}

# ---- JSON booleans from a document ------------------------------------------
#
# A document's `false` is not a plain 0. A decoder yields a blessed Boolean,
# and the \0 idiom is a scalar ref - and a reference is TRUE to C's SvTRUE
# whatever it points at. A blessed Boolean overloads bool and so survives
# SvTRUE by accident; \0 does not, and read that way `explode: false` becomes
# `explode: true` silently.
#
# Every other test in this distribution writes booleans as Perl 0 and 1, which
# is exactly why this went unnoticed. These use the other two spellings.

sub enc_api {
    my ($explode) = @_;
    return Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => { post => {
            operationId => 'op',
            requestBody => { required => 1, content => {
                'application/x-www-form-urlencoded' => {
                    schema   => { type => 'object', properties => {
                                   a => { type => 'array',
                                          items => { type => 'string' } } } },
                    encoding => { a => { style => 'form',
                                         explode => $explode } } } } },
            responses   => { 200 => { description => 'ok' } },
        } } },
    });
}

for my $c ( [ \0, 'the \\0 JSON-false idiom' ], [ 0, 'a bare 0' ] ) {
    my ($false, $label) = @$c;
    my ($ok, $res) = enc_api($false)->validate_request(op => {
        header => { 'content-type' => 'application/x-www-form-urlencoded' },
        body   => 'a=x,y' });
    ok($ok, "explode false written as $label is accepted") or next;
    is_deeply($res->{body}{a}, [ 'x', 'y' ],
              "...and read as FALSE, so the value is split ($label)");
}

# and a JSON document, where the decoder's own Boolean is what arrives
{
    my $json = '{"openapi":"3.1.0","info":{"title":"T","version":"1.0.0"},'
             . '"paths":{"/t":{"post":{"operationId":"op",'
             . '"requestBody":{"required":true,"content":'
             . '{"application/x-www-form-urlencoded":{'
             . '"schema":{"type":"object","properties":'
             . '{"a":{"type":"array","items":{"type":"string"}}}},'
             . '"encoding":{"a":{"style":"form","explode":false}}}}},'
             . '"responses":{"200":{"description":"ok"}}}}}}';
    my ($ok, $res) = Open::API->new(spec => $json)->validate_request(op => {
        header => { 'content-type' => 'application/x-www-form-urlencoded' },
        body   => 'a=x,y' });
    ok($ok, 'a real JSON document with explode:false is accepted');
    is_deeply($res->{body}{a}, [ 'x', 'y' ],
              '...and its decoder Boolean is read as false too');
}

# ---- Encoding headers on a multipart part -----------------------------------
#
# An Encoding Object may declare `headers` for a part, and a required one that
# the part does not carry is a bad request. Nothing else would report it: a
# part's headers are not part of the value the schema sees, and the decoder
# used to discard every header but Content-Disposition's `name`.
#
# The ACCEPT case is the one that matters. A decoder that collected no part
# headers at all would refuse the missing-header body just as convincingly as
# a working one - only the carrying case tells them apart.

{
    my $api = Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => { post => {
            operationId => 'op',
            requestBody => { required => 1, content => { 'multipart/form-data' => {
                schema   => { type => 'object',
                              properties => { a => { type => 'string' } } },
                encoding => { a => { headers => { 'X-P' => {
                                required => 1,
                                schema   => { type => 'string' } } } } } } } },
            responses   => { 200 => { description => 'ok' } },
        } } },
    });
    my $CT = { 'content-type' => 'multipart/form-data; boundary=xx' };
    my $part = sub {
        join '', map { "$_\r\n" } '--xx',
            'Content-Disposition: form-data; name="a"', @_, '', 'val', '--xx--';
    };

    my ($ok) = $api->validate_request(op => { header => $CT,
                                              body => $part->('X-P: v') });
    ok($ok, 'a part carrying its declared encoding header is accepted');

    my ($bad, $errs) = $api->validate_request(op => { header => $CT,
                                                      body => $part->() });
    ok(!$bad, 'a part missing a required encoding header is refused');
    is(($errs->[0]{name} || ''), 'X-P', '...naming the header that was missing');

    my ($lc) = $api->validate_request(op => { header => $CT,
                                              body => $part->('x-p: v') });
    ok($lc, 'the header name is matched case-insensitively, per RFC 7231');
}

done_testing;
