#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;

# Parameters declared with `content` instead of `schema`.
#
# Such a parameter carries a whole document in one value - the `?filter={...}`
# idiom - so the value has to be decoded before its schema means anything.
# Before this it compiled to no handle at all, which is worse than rejecting
# it: the document said what the parameter had to look like and nothing
# checked. The compile side is oa_compile_params, the request side is
# oa_check_param, and the client side is oa_cli_wire / oa_cli_decoded.

my %DOC = (
    openapi => '3.1.0',
    info    => { title => 'T', version => '1.0.0' },
    paths   => { '/s' => { get => {
        operationId => 'search',
        parameters  => [
            { name => 'filter', in => 'query',
              content => { 'application/json' => { schema => {
                  type => 'object', required => ['field'],
                  properties => { field => { type => 'string' },
                                  max   => { type => 'integer' } } } } } },
            { name => 'tags', in => 'query',
              content => { 'application/json' => { schema => {
                  type => 'array', items => { type => 'string' } } } } },
            { name => 'X-Ctx', in => 'header', required => 1,
              content => { 'application/json' => { schema => {
                  type => 'array', items => { type => 'integer' } } } } },
            { name => 'opaque', in => 'query',
              content => { 'application/x-msgpack' => { schema => {
                  type => 'object' } } } },
            { name => 'plain', in => 'query', schema => { type => 'integer' } },
        ],
        responses => { 200 => { description => 'ok' } },
    } } },
);

my $api = Open::API->new(spec => \%DOC);
my $HDR = { 'x-ctx' => '[1,2]' };

sub verdict {
    my (%raw) = @_;
    my ($ok, $res) = $api->validate_request('search', \%raw);
    return $ok ? 'accept' : ($res->[0]{keyword} || '?');
}

# ---- the value is decoded, then validated ----------------------------------

is(verdict(query => 'filter={"field":"name"}', header => $HDR), 'accept',
   'a valid JSON document in a query parameter');
is(verdict(query => 'filter={"field":"name","max":10}', header => $HDR), 'accept',
   'with an optional member too');

is(verdict(query => 'filter={"max":10}', header => $HDR), 'required',
   'the schema is enforced inside the document');
is(verdict(query => 'filter={"field":42}', header => $HDR), 'type',
   'including the types of its members');
is(verdict(query => 'filter=notjson', header => $HDR), 'content',
   'a value that is not the declared media type is rejected, not ignored');

# an array-typed content parameter is one document, not repeated keys
is(verdict(query => 'tags=["a","b"]', header => $HDR), 'accept',
   'an array document');
is(verdict(query => 'tags=[1,2]', header => $HDR), 'type',
   'whose element types are checked');

# ---- other locations -------------------------------------------------------

is(verdict(header => { 'x-ctx' => '[1,2,3]' }), 'accept', 'a header parameter');
is(verdict(header => { 'x-ctx' => '["a"]' }),   'type',   'checked as a document');
is(verdict(), 'required', 'and still required when the document says so');

# ---- no decoder, no opinion ------------------------------------------------
# The same rule a request body follows: a media type we cannot decode is
# passed through rather than guessed at.

is(verdict(query => 'opaque=%01%02', header => $HDR), 'accept',
   'a media type with no decoder is left alone');

# ---- a plain schema parameter is untouched ---------------------------------

is(verdict(query => 'plain=5',   header => $HDR), 'accept', 'a schema parameter');
is(verdict(query => 'plain=abc', header => $HDR), 'type',
   'still coerces from the string form');

# ---- the validated value comes back decoded --------------------------------
{
    my ($ok, $params) = $api->validate_request('search',
        { query => 'filter={"field":"name"}', header => $HDR });
    ok($ok, 'the request validates');
    is(ref $params->{query}{filter}, '', 'the raw query value stays as it arrived');
}

# ---- the document round-trips ----------------------------------------------
{
    my $two = Open::API->new(spec => $api->spec);
    is_deeply($two->spec, $api->spec, 'normalisation leaves content parameters alone');
    my ($ok) = $two->validate_request('search',
        { query => 'filter={"field":"n"}', header => $HDR });
    ok($ok, 'and the reloaded document still validates them');
}

# ---- the client encodes what the server decodes ----------------------------

SKIP: {
    skip 'Hyperman/Fetch not installed', 4
        unless eval { require Hyperman; require Fetch; 1 };
    require IO::Socket::INET;
    require Open::API::Plack;
    require Open::API::Client;

    my $port = do {
        my $s = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
            Listen => 1, ReuseAddr => 1) or die $!;
        my $p = $s->sockport; close $s; $p;
    };

    # the handler echoes the raw query string and header back, so the test can
    # see what actually went on the wire
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDERR, '>', '/dev/null';
        my $srv = Open::API->new(spec => \%DOC);
        my $app = Open::API::Plack->new(api => $srv, handlers => {
            search => sub {
                my ($p, $env) = @_;
                [ 200, ['Content-Type' => 'application/json'],
                  [ sprintf '{"qs":%s,"ctx":%s}',
                    _json_str($env->{QUERY_STRING}),
                    _json_str($env->{HTTP_X_CTX}) ] ];
            },
        })->to_app;
        Hyperman->run(app => $app, host => '127.0.0.1', port => $port,
                      workers => 1);
        exit 0;
    }
    sub _json_str {
        my $s = defined $_[0] ? $_[0] : '';
        $s =~ s/(["\\])/\\$1/g;
        return qq{"$s"};
    }

    for (1 .. 100) {
        last if IO::Socket::INET->new(PeerHost => '127.0.0.1', PeerPort => $port);
        select undef, undef, undef, 0.05;
    }

    my $client = Open::API::Client->new(
        api => Open::API->new(spec => \%DOC),
        base_url => "http://127.0.0.1:$port",
    );

    # a structure goes in; JSON has to come out the other side
    my $res = eval { $client->search(filter => { field => 'name' },
                                     'X-Ctx' => [1, 2])->get };
    is(($res || {})->{status}, 200, 'the client sends a content parameter')
        or diag($@);

    my $qs = $res->{data}{qs} || '';
    $qs =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
    like($qs, qr/\Qfilter={"field":"name"}\E/,
         'the query carries the encoded document, not a stringified ref');

    # the wire spelling of a number is JSON::Schema::Fast's business (it sets
    # NOK on an integer it has validated, so 1 can travel as 1.0); what this
    # asserts is that the header is a document at all, and the right one
    my $ctx = eval { File::Raw::JSON::file_json_decode($res->{data}{ctx} || '') };
    is_deeply($ctx, [1, 2], 'and so does the header')
        or diag("header was: " . ($res->{data}{ctx} || '(none)'));

    # client-side validation still applies, before any I/O
    my $err;
    eval { $client->search(filter => { max => 3 }, 'X-Ctx' => [1])->get } or $err = $@;
    like($err || '', qr/invalid query parameter 'filter'/,
         'an invalid document is caught client-side');

    kill 'TERM', $pid;
    waitpid $pid, 0;
}

done_testing();
