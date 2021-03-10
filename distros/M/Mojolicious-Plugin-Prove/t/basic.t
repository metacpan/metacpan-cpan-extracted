#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use Test::LongString;

use Mojo::File qw(curfile);

use lib 'lib';
use lib '../lib';

diag( Mojolicious->VERSION );

## Webapp START

my $testdir = curfile->dirname->child( '..', 'test' )->to_string;

plugin('Prove' => {
  tests => {
    base => $testdir,
  }
});

## Webapp END

my $t = Test::Mojo->new;

$t->get_ok( '/prove' )->status_is( 200 )->content_is( <<"HTML" );
<h2>Tests</h2>

<ul>
    <li><a href="/prove/test/base">base</a></li>
</ul>
HTML

$t->get_ok( '/prove/test/base' )->status_is( 200 );
is_string $t->tx->res->body, <<"HTML";
<h2>Tests</h2>
<a href="/prove/test/base/run">run all tests</a>
<ul>
    <li><a href="/prove/test/base/file/01_success.t">01_success.t</a></li>
    <li><a href="/prove/test/base/file/02_fail.t">02_fail.t</a></li>
</ul>

HTML

my $close = Mojolicious->VERSION >= 5.73 ? '' : ' /';

$t->get_ok( '/prove/test/base/file/01_success.t' )->status_is( 200 );
is_string $t->tx->res->body, <<"HTML";
<link href="/ppi.css" rel="stylesheet"$close>
<script src="/jquery-3.3.1.min.js"></script>
<script src="/ppi.js"></script>
<script src="/prove_funcs.js"></script>
  <script src="/ppi_js.js"></script>

<code class="ppi-code ppi-inline" id="ppi0" ondblclick="ppi_toggleLineNumbers(&#39;ppi0&#39;)"><span class="line_number"> 1: </span><span class="comment">#!/usr/bin/env perl<br>
</span><span class="line_number"> 2: </span><br>
<span class="line_number"> 3: </span><span class="keyword">use</span> <span class="pragma">strict</span><span class="structure">;</span><br>
<span class="line_number"> 4: </span><span class="keyword">use</span> <span class="pragma">warnings</span><span class="structure">;</span><br>
<span class="line_number"> 5: </span><br>
<span class="line_number"> 6: </span><span class="keyword">use</span> <span class="word">Test::More</span><span class="structure">;</span><br>
<span class="line_number"> 7: </span><br>
<span class="line_number"> 8: </span><span class="word">is</span> <span class="number">1</span><span class="operator">,</span> <span class="number">1</span><span class="structure">;</span><br>
<span class="line_number"> 9: </span><br>
<span class="line_number">10: </span><span class="word">done_testing</span><span class="structure">();</span><br>
<span class="line_number">11: </span></code>

<br /><br />
<div id="test"></div>
<div id="test_01_success.t"><button onclick="prove( 'base', '01_success.t', 'prove' );" value="Run tests">Run tests</button></div>
HTML

$t->get_ok( '/prove/test/base/file/02_fail.t' )->status_is( 200 );
is_string $t->tx->res->body, <<"HTML";
<link href="/ppi.css" rel="stylesheet"$close>
<script src="/jquery-3.3.1.min.js"></script>
<script src="/ppi.js"></script>
<script src="/prove_funcs.js"></script>
  <script src="/ppi_js.js"></script>

<code class="ppi-code ppi-inline" id="ppi0" ondblclick="ppi_toggleLineNumbers(&#39;ppi0&#39;)"><span class="line_number"> 1: </span><span class="comment">#!/usr/bin/env perl<br>
</span><span class="line_number"> 2: </span><br>
<span class="line_number"> 3: </span><span class="keyword">use</span> <span class="pragma">strict</span><span class="structure">;</span><br>
<span class="line_number"> 4: </span><span class="keyword">use</span> <span class="pragma">warnings</span><span class="structure">;</span><br>
<span class="line_number"> 5: </span><br>
<span class="line_number"> 6: </span><span class="keyword">use</span> <span class="word">Test::More</span><span class="structure">;</span><br>
<span class="line_number"> 7: </span><br>
<span class="line_number"> 8: </span><span class="word">is</span> <span class="number">1</span><span class="operator">,</span> <span class="number">2</span><span class="structure">;</span><br>
<span class="line_number"> 9: </span><br>
<span class="line_number">10: </span><span class="word">done_testing</span><span class="structure">();</span><br>
<span class="line_number">11: </span></code>

<br /><br />
<div id="test"></div>
<div id="test_02_fail.t"><button onclick="prove( 'base', '02_fail.t', 'prove' );" value="Run tests">Run tests</button></div>
HTML

$t->get_ok( '/prove/test/base/file/01_success.t/run?format=text' )->status_is( 200 );

my $content_success = $t->tx->res->body;
my $regex_success   = qr!01_success.t .. ok\s+All tests successful.\s+Files=1, Tests=1, .*\s+Result: PASS!;

like_string $content_success, $regex_success;
if ( $content_success !~ $regex_success ) {
  diag $content_success;
}

$t->get_ok( '/prove/test/base/file/02_fail.t/run?format=text' )->status_is( 200 );
my $content_fail = $t->tx->res->body;
like_string $content_fail, qr!02_fail.t ..\s+Dubious, test returned 1 \(wstat 256, 0x100\)\s+Failed 1/1 subtests!;
like_string $content_fail, qr!Test Summary Report\s+-------------------\s+.*?02_fail.t \(Wstat: 256 Tests: 1 Failed: 1\)\s+  Failed test:  1\s+  Non-zero exit status: 1\s+Files=1, Tests=1, .*\s+Result: FAIL!;

done_testing();

