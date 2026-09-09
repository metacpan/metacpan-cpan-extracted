#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;
use File::Raw::XML ();

# The test client's XML end: `xml => ...` as a request body, and ->xml as a
# response accessor. Both mirror what the client already does for JSON.

{
    package TXApp;
    use Punk;
    use File::Raw::XML ();

    post '/echo' => sub {
        my ($c) = @_;
        my $in = $c->req->xml;
        my $d  = File::Raw::XML->new_document;
        my $r  = $d->new_element('', 'echo');
        $d->document->append($r);
        $r->set_attr('', 'root', $in->root->name);
        $r->set_attr('', 'id',   $in->root->attr('id') // '');
        return $d;
    };
    get '/two' => sub {
        my ($c) = @_;
        my $d = File::Raw::XML->new_document;
        my $r = $d->new_element('', 'n');
        $d->document->append($r);
        $r->set_attr('', 'v', $c->param('v') // '0');
        return $d;
    };
    get '/json' => sub { { kind => 'json' } };
    package main;
}

my $t = Punk::Test->new('TXApp');

# a string body, which is also how a test sends markup it wants refused
$t->post_ok('/echo', xml => "<order id='9'/>")->status_is(200)
  ->header_is('Content-Type', 'application/xml; charset=utf-8');
is($t->xml->root->attr('root'), 'order', '->xml parses the response body');
is($t->xml->root->attr('id'), '9',
   'and `xml => $string` sent the body with application/xml');

# a Document as the request body serialises itself
{
    my $d = File::Raw::XML->new_document;
    my $r = $d->new_element('', 'built');
    $d->document->append($r);
    $r->set_attr('', 'id', '4');
    $t->post_ok('/echo', xml => $d)->status_is(200);
    is($t->xml->root->attr('root'), 'built',
       '`xml => $document` serialises the document into the request');
    is($t->xml->root->attr('id'), '4', 'with its attributes intact');
}

# The accessor memoises, and the memo is dropped with the response it came
# from - a document left behind would be asserted against the next request.
{
    $t->get_ok('/two?v=1');
    my $first = $t->xml;
    is($first->root->attr('v'), '1', 'the first response');
    ok($t->xml == $first, 'the accessor memoises within one response');

    $t->get_ok('/two?v=2');
    is($t->xml->root->attr('v'), '2',
       'and the memo is cleared on the next request rather than answering '
     . 'with the last one');
}

# a response that is not XML gives undef rather than dying
$t->get_ok('/json');
is($t->xml, undef, '->xml on a JSON response is undef, not an exception');

# xml and upload do not combine, the way json and upload do not
{
    my $err = '';
    eval { $t->post_ok('/echo', upload => { f => 'x' }, xml => '<a/>'); 1 }
        or $err = "$@";
    like($err, qr/upload and xml do not combine/,
         'upload and xml are refused together - an upload is '
       . 'multipart/form-data, so the XML would have been dropped silently');
}

done_testing;
