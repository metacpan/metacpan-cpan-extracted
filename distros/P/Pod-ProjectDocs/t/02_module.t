#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use Test::More tests => 9;
use File::Path qw( remove_tree );

use lib '../lib';
use Pod::ProjectDocs;

Pod::ProjectDocs->new(
    outroot      => "$FindBin::Bin/02_module_output",
    libroot      => "$FindBin::Bin/sample/lib2",
    forcegen     => 1,
    nosourcecode => 1,
)->gen();

# using XML::XPath might be better
open my $fh, "<:encoding(utf-8)",
  "$FindBin::Bin/02_module_output/Module.pm.html";
my $html = join '', <$fh>;
close $fh;

like $html, qr!foo foo foo!;
like $html, qr!bar bar bar!;
like $html, qr!>\$foo = foo\(\@_\)<!s;
like $html, qr!>bar<!;

# Source code is not generated
ok( !-f "$FindBin::Bin/02_module_output/src/Module.pm" );

# Source code link is not present
unlike $html, qr!>Source<!;

# character escapes
like $html, qr!&lt; &gt; \| / é „ = µ!;

# links
like $html, qr!<h1 id="content-get">&quot;\$content = get\( ... \)&quot;!;
like $html, qr!<a href="#content-get">get</a> function does foo!;

remove_tree("$FindBin::Bin/02_module_output");
