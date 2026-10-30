#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPOA;

my $t = oa_app(q{openapi => '*'});

# ---- every location arrives -------------------------------------------------------

my $r = oa_call($t, 'listbooks', { q => 'sand & spice', limit => 3, tags => ['sf', 'classic'],
                                   'X-Trace' => 't-9' })->{result};
is_deeply({ %{ $PMCPOA::SEEN{listBooks} }{qw(q limit trace)} },
    { q => 'sand & spice', limit => 3, trace => 't-9' },
    'query and header arguments arrive, percent-encoded on the way and decoded by the app');
is_deeply($PMCPOA::SEEN{listBooks}{tags}, ['sf', 'classic'], 'an array query argument repeats the key');
is($r->{content}[0]{text}, '[{"title":"Dune"}]', 'a JSON array answer is the text');
ok(!exists $r->{structuredContent}, 'and not structuredContent, which is an object');
is($r->{_meta}{status}, 200, 'the status is in _meta');

$r = oa_call($t, 'getbook', { id => 'a/b c' })->{result};
is_deeply($r->{structuredContent}, { id => 'a/b c' },
    'a path argument is percent-encoded into its segment, so a slash stays in it');

$r = oa_call($t, 'add_book', { body => { title => 'Emma' } })->{result};
is_deeply($r->{structuredContent}, { made => 'Emma' }, 'the body argument is the JSON body');
is($r->{_meta}{status}, 201, 'with the status the app gave');

$r = oa_call($t, 'replacebook', { id => '7', body => {} })->{result};
is_deeply($r->{structuredContent}, { replaced => 7 }, 'a path argument and a body together');

$r = oa_call($t, 'deletebook', { id => '7' })->{result};
is($r->{_meta}{status}, 204, 'a 204 is answered');
ok(!$r->{isError}, 'and is no error');

$r = oa_call($t, 'getbook', { id => 'later' })->{result};
is_deeply($r->{structuredContent}, { id => 'from a future' },
    'an operation that answers with a Future is awaited');

# ---- the app's answers become tool results -------------------------------------------

$r = oa_call($t, 'getbook', { id => 'missing' })->{result};
ok($r->{isError}, 'a 404 is a tool error');
is($r->{_meta}{status}, 404, 'with its status');
is($r->{content}[0]{text}, '{"error":"no such book"}', 'and its body');

# The tool's schema refuses a bad argument before the app is asked, 2025-11-25.
$r = oa_call($t, 'listbooks', { limit => 500 })->{result};
ok($r->{isError}, 'an argument the schema refuses is a tool error');
like($r->{content}[0]{text}, qr/invalid arguments/, 'from the tool\'s own validation');

$r = oa_call($t, 'add_book', { body => { title => '' } })->{result};
ok($r->{isError}, 'a body the schema refuses too');

my $v1 = oa_app(q{openapi => '/v1'}, under => '/v1');
$r = oa_call($v1, 'getbook', { id => 'p' })->{result};
is_deeply($r->{structuredContent}, { id => 'p' },
    'a mount under a prefix: the call goes to the prefixed path');

# ---- the inner request is marked -------------------------------------------------------

oa_call($t, 'listbooks', {});
is($PMCPOA::SEEN{listBooks}{inner}, 1, 'the inner request carries pmcp.inner');
is($PMCPOA::SEEN{listBooks}{tool}, 'listbooks', 'and pmcp.tool');

done_testing;
