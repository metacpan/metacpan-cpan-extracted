#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;

# The document-structure refusals added alongside the compliance catalogue, and
# - the half that matters more - the values they must NOT refuse.
#
# t/compliance/run.t already pins each refusal, one case per requirement. What
# it cannot pin is the opposite failure: a check that is too strict. The
# contact and xml-namespace rules are deliberately LOOSE (a scheme and no
# whitespace; one @ with something either side) because nothing in this library
# dereferences either field, so the only thing a stricter grammar could buy is
# refusing documents that work. These tests exist so that tightening one of
# them fails here rather than in somebody's gateway.

sub doc {
    my (%o) = @_;
    my %d = (
        openapi => delete $o{openapi} || '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => delete $o{paths} || {},
    );
    $d{$_} = $o{$_} for keys %o;
    return \%d;
}

sub contact { my $d = doc(); $d->{info}{contact} = { @_ }; return $d }

sub body_schema {
    my ($s) = @_;
    return doc(paths => { '/t' => { post => {
        operationId => 'op',
        requestBody => { required => 1,
                         content  => { 'application/json' => { schema => $s } } },
        responses   => { 200 => { description => 'ok' } } } } });
}

sub loads_ok {
    my ($spec, $name) = @_;
    my $ok = eval { Open::API->new(spec => $spec); 1 };
    my $err = $@;
    ok($ok, $name) or diag("  refused: $err");
}

sub refused_like {
    my ($spec, $re, $name) = @_;
    my $ok = eval { Open::API->new(spec => $spec); 1 };
    if ($ok) { fail($name); diag('  loaded, but should have been refused'); return }
    like($@, $re, $name);
}

# ---- Contact: loose on purpose ---------------------------------------------

loads_ok(contact(email => 'a@b.test'),              'a plain address loads');
loads_ok(contact(email => 'a+tag.x@sub.b.test'),    'a tagged address loads');
loads_ok(contact(email => q{"odd..local"@b.test}),  'a quoted local part loads');
loads_ok(contact(email => 'root@localhost'),        'an address with no dot in the domain loads');
loads_ok(contact(url   => 'https://x.test/a?b=c#d'),'a url with query and fragment loads');
loads_ok(contact(url   => 'mailto:a@b.test'),       'a non-http scheme loads');
loads_ok(contact(url   => 'x-corp+internal.v2://h/p'), 'an unusual but legal scheme loads');
loads_ok(contact(name  => 'C'),                     'a contact with neither field loads');
loads_ok(doc(),                                     'no contact at all loads');

refused_like(contact(email => 'not-an-email'), qr/email/,
             'an address with no @ is refused');
refused_like(contact(url   => 'not a url'),    qr/url/,
             'a url with no scheme is refused');

# ---- XML Object -------------------------------------------------------------

loads_ok(body_schema({ type => 'object', xml => { namespace => 'urn:example:ns' },
                       properties => { a => { type => 'string' } } }),
         'a urn namespace loads');
loads_ok(body_schema({ type => 'object', xml => { namespace => 'http://x.test/ns',
                                                  name => 'thing', prefix => 't' },
                       properties => { a => { type => 'string' } } }),
         'a full xml object loads');
refused_like(body_schema({ type => 'object', xml => { namespace => '/relative' },
                           properties => { a => { type => 'string' } } }),
             qr/absolute URI/, 'a relative namespace is refused');

# xml is an annotation: it must not change what validates
{
    my $api = Open::API->new(spec => body_schema({
        type => 'object', required => ['a'],
        xml  => { name => 'thing', wrapped => 1 },
        properties => { a => { type => 'string', xml => { attribute => 1 } } } }));
    my ($ok) = $api->validate_request('op', {
        header => { 'content-type' => 'application/json' },
        body   => '{"a":"v"}' });
    ok($ok, 'xml annotations do not affect JSON validation');
}

# ---- Discriminator ----------------------------------------------------------

refused_like(body_schema({ oneOf => [ { type => 'object' }, { type => 'string' } ],
                           discriminator => { mapping => { x => 'A' } } }),
             qr/propertyName/, 'a discriminator without propertyName is refused');

# an INLINE discriminator that selects nothing is inert and refused ...
refused_like(body_schema({ type => 'object',
                           properties => { petType => { type => 'string' } },
                           discriminator => { propertyName => 'petType' } }),
             qr/selects nothing/, 'an inert inline discriminator is refused');

# ... but a NAMED base is left alone: another document may extend it, and
# t/30-discriminator.t pins it as "a childless base is left as an annotation"
loads_ok(doc(
    paths => { '/t' => { post => {
        operationId => 'op',
        requestBody => { content => { 'application/json' => {
            schema => { '$ref' => '#/components/schemas/Pet' } } } },
        responses   => { 200 => { description => 'ok' } } } } },
    components => { schemas => { Pet => {
        type => 'object', required => ['petType'],
        properties    => { petType => { type => 'string' } },
        discriminator => { propertyName => 'petType' } } } }),
    'a childless NAMED base keeps its discriminator as an annotation');

# ---- Encoding ---------------------------------------------------------------

sub enc_doc {
    my ($ctype, $encoding) = @_;
    return doc(paths => { '/t' => { post => {
        operationId => 'op',
        requestBody => { content => { $ctype => {
            schema   => { type => 'object',
                          properties => { a => { type => 'string' } } },
            encoding => $encoding } } },
        responses   => { 200 => { description => 'ok' } } } } });
}

loads_ok(enc_doc('multipart/form-data', { a => { contentType => 'text/plain' } }),
         'encoding on multipart loads');
loads_ok(enc_doc('application/x-www-form-urlencoded', { a => { style => 'form' } }),
         'encoding on urlencoded loads');
refused_like(enc_doc('application/json', { a => { contentType => 'text/plain' } }),
             qr/only legal for multipart/,
             'encoding on a JSON body is refused');
refused_like(enc_doc('application/x-www-form-urlencoded',
                     { nosuch => { contentType => 'text/plain' } }),
             qr/names no property/,
             'an encoding key naming no property is refused');

# ---- Header Object ----------------------------------------------------------

sub hdr_doc {
    my (%h) = @_;
    return doc(paths => { '/t' => { get => {
        operationId => 'op',
        responses   => { 200 => { description => 'ok',
                                  headers => { 'X-H' => \%h } } } } } });
}

loads_ok(hdr_doc(schema => { type => 'string' }),
         'a header with no style loads');
loads_ok(hdr_doc(style => 'simple', schema => { type => 'string' }),
         'a header with style simple loads');
refused_like(hdr_doc(style => 'form', schema => { type => 'string' }),
             qr/only style defined for a header/,
             'a header with another style is refused');

# ---- Server, External Documentation -----------------------------------------

loads_ok(doc(servers => [ { url => 'https://x.test/v1' } ]), 'a server with a url loads');
refused_like(doc(servers => [ { description => 'none' } ]), qr/no 'url'/,
             'a server without a url is refused');

loads_ok(doc(externalDocs => { url => 'https://x.test/docs' }),
         'root externalDocs with a url loads');
refused_like(doc(externalDocs => { description => 'none' }), qr/externalDocs/,
             'root externalDocs without a url is refused');
refused_like(doc(paths => { '/t' => { get => {
                 operationId  => 'op',
                 externalDocs => { description => 'none' },
                 responses    => { 200 => { description => 'ok' } } } } }),
             qr/operation: externalDocs/,
             'operation externalDocs without a url is refused');

done_testing();
