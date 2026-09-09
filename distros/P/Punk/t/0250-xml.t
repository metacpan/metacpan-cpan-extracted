#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;
use File::Raw::XML ();

# The XML body path: a request body parsed into a File::Raw::XML::Document,
# and a Document or Node handed back as a response.
#
# Punk maps nothing between XML and Perl data - there is no canonical mapping
# and every convention is wrong for somebody's schema - so what is asserted
# here is the two ends only: bytes in to a tree, a tree out to bytes.
#
# The one thing in this file that is a security property rather than a
# feature is the DOCTYPE refusal. It is what removes XXE and the billion
# laughs, it holds because the parse is strict and takes no options, and the
# test for it is here so that a later `profile => full` cannot arrive quietly.

my $DOC = "<order id='7'><item sku='a'>one</item><item sku='b'>two</item></order>";

{
    package XApp;
    use Punk;
    use File::Raw::XML ();

    post '/parse' => sub {
        my ($c) = @_;
        my $d = $c->req->xml;
        return {
            root  => $d->root->name,
            id    => $d->root->attr('id'),
            items => scalar(() = $d->root->elements),
            first => ($d->root->elements)[0]->text,
        };
    };

    # two calls, one document: asserted by identity, not by equal content
    post '/cached' => sub {
        my ($c) = @_;
        my $a = $c->req->xml;
        my $b = $c->req->xml;
        # `both` guards the assertion: two undefs would compare equal and
        # report a cache that was never exercised
        return { both => (($a && $b) ? 1 : 0),
                 same => (($a && $b && $a == $b) ? 1 : 0) };
    };

    post '/defined' => sub {
        my ($c) = @_;
        my $d = $c->req->xml;
        return { defined => (defined $d ? 1 : 0) };
    };

    # the JSON twin of /parse, so the two bodies' refusals can be compared
    # rather than a status being asserted from memory
    post '/json' => sub { my ($c) = @_; { got => $c->req->json } };

    post '/stream-then-xml' => sub {
        my ($c) = @_;
        my $n = 0;
        $c->req->body_each(sub { $n += length $_[0] });
        my $err = '';
        eval { $c->req->xml; 1 } or $err = "$@";
        return { read => $n, err => $err };
    };

    # ---- the response side --------------------------------------------------

    sub _built {
        my $d = File::Raw::XML->new_document;
        my $r = $d->new_element('', 'reply');
        $d->document->append($r);
        $r->set_attr('', 'ok', '1');
        return ($d, $r);
    }

    get '/return-doc'  => sub { (_built())[0] };                  # punk_coerce
    get '/call-doc'    => sub { my ($c) = @_; $c->xml((_built())[0]) };
    get '/call-node'   => sub { my ($c) = @_; $c->xml((_built())[1]) };
    get '/call-string' => sub { my ($c) = @_; $c->xml('<raw/>') };
    get '/call-status' => sub { my ($c) = @_; $c->xml((_built())[0], 201) };
    get '/call-bad'    => sub { my ($c) = @_; $c->xml({ not => 'xml' }) };

    get '/res-body'    => sub {
        my ($c) = @_;
        $c->res->body((_built())[0]);
        return $c->res;
    };
    get '/res-typed'   => sub {
        my ($c) = @_;
        $c->res->type('application/atom+xml')->body((_built())[0]);
        return $c->res;
    };

    get '/negotiated' => sub {
        my ($c) = @_;
        $c->respond_to(
            json => sub { $c->json({ shape => 'json' }) },
            xml  => sub { (_built())[0] },
        );
    };

    package main;
}

my $t = Punk::Test->new(XApp->to_app);

# ---- the request side --------------------------------------------------------

$t->post_ok('/parse', xml => $DOC)->status_is(200);
is_deeply($t->json,
          { root => 'order', id => '7', items => 2, first => 'one' },
          'req->xml parses the body into a walkable tree');

$t->post_ok('/cached', xml => $DOC)->status_is(200);
is($t->json->{both}, 1, 'both calls returned a document');
is($t->json->{same}, 1,
   'and parses it once: two calls in one request are one document, which is '
 . 'what makes a node\'s ->doc and a by_id result name the same tree');

# An empty body is undef and stays undef - the slot's presence is what says
# the body was parsed, so this must not re-parse (or, worse, report a parse
# error for the empty string) on the second call.
$t->post_ok('/defined', body => '', type => 'application/xml')->status_is(200);
is($t->json->{defined}, 0, 'an empty body is undef, not an error');

# ---- refusals ----------------------------------------------------------------
#
# The contract is "whatever ->json does", so the two are run side by side and
# compared. Asserting a remembered status here would pass just as happily if
# both had changed.
{
    $t->post_ok('/json', body => '{"a":', type => 'application/json');
    my $json_status = $t->status;

    $t->post_ok('/parse', xml => '<order><item>');
    is($t->status, $json_status,
       'a body that is not well-formed answers exactly as a malformed JSON '
     . 'body does');
    like($t->body, qr/File::Raw::XML/,
         'and the parser names itself, with its offset, in the message');
}

# The security property. A document type declaration is refused wherever it
# stands, which is what takes external entities, parameter entities, the
# external DTD fetch, XXE and the billion laughs off the table as a class.
{
    my $bomb = '<!DOCTYPE o [<!ENTITY x "boom">]><order>&x;</order>';
    $t->post_ok('/parse', xml => $bomb);
    isnt($t->status, 200, 'a DOCTYPE in a request body is refused');
    like($t->body, qr/DOCTYPE/i,
         'and says so - the parse is strict and takes no options, so no '
       . 'route can turn entity expansion back on');
}

# A body is read once, whichever way it is read.
$t->post_ok('/stream-then-xml', xml => $DOC)->status_is(200);
ok($t->json->{read} > 0, 'body_each read the body');
like($t->json->{err}, qr/streamed and is gone/,
     'and ->xml then croaks rather than parsing nothing, as ->json does');

# ---- the response side -------------------------------------------------------

$t->get_ok('/return-doc')->status_is(200)
  ->header_is('Content-Type', 'application/xml; charset=utf-8');
like($t->body, qr/^<\?xml version="1\.0" encoding="UTF-8"\?>/,
     'a document returned from a handler is written as markup, with its '
   . 'declaration - before this it was a blessed reference and went to the '
   . 'JSON encoder');
like($t->body, qr/<reply ok="1"\/>/, 'and the tree is what was built');

$t->get_ok('/call-doc')
  ->header_is('Content-Type', 'application/xml; charset=utf-8');
like($t->body, qr/<reply ok="1"\/>/, '$c->xml writes a document');

$t->get_ok('/call-node')
  ->header_is('Content-Type', 'application/xml; charset=utf-8');
is($t->body, '<reply ok="1"/>',
   'a node is a fragment: no XML declaration, which is why the content type '
 . 'carries the charset');

$t->get_ok('/call-string')
  ->header_is('Content-Type', 'application/xml; charset=utf-8')
  ->content_is('<raw/>', 'a string is markup the caller built, passed through');

$t->get_ok('/call-status')->status_is(201, 'the status argument is honoured');

$t->get_ok('/call-bad')->status_is(500);
like($t->body, qr/takes a File::Raw::XML::Document/,
     'any other reference is refused by name rather than stringified into '
   . 'the body as HASH(0x...)');

$t->get_ok('/res-body')
  ->header_is('Content-Type', 'application/xml; charset=utf-8',
              'the same rule in Punk::Response::finalize');
$t->get_ok('/res-typed')
  ->header_is('Content-Type', 'application/atom+xml',
              'and an explicit ->type still wins there');

# Content-Length is the byte count. to_string hands back bytes with no
# character flag, so this holds without anything encoding on the way out.
$t->get_ok('/call-node');
is($t->header('Content-Length'), length($t->body),
   'Content-Length is the body\'s byte count');

# HEAD: the body is blanked, the headers are not.
$t->head_ok('/call-doc')
  ->header_is('Content-Type', 'application/xml; charset=utf-8');
is($t->body, '', 'HEAD has no body');
ok($t->header('Content-Length') > 0, 'but keeps the length it would have had');

# ---- negotiation -------------------------------------------------------------
#
# pa_fmt_mime has mapped the `xml` shorthand to application/xml since it was
# written, and nothing exercised it. respond_to sets no content type of its
# own - it returns whatever its branch returned - so this passes only because
# a document coerces.
$t->get_ok('/negotiated', headers => { Accept => 'application/xml' })
  ->header_is('Content-Type', 'application/xml; charset=utf-8',
              'respond_to(xml => ...) negotiates, and a document returned '
            . 'from the branch is what makes it application/xml');
like($t->body, qr/<reply/, 'with the document as the body');

$t->get_ok('/negotiated', headers => { Accept => 'application/json' })
  ->header_is('Content-Type', 'application/json', 'the json branch still wins '
            . 'when it is the one asked for');

$t->get_ok('/negotiated', headers => { Accept => 'application/xml' })
  ->header_like('Vary', qr/\bAccept\b/, 'and Vary: Accept is set either way');

done_testing;
