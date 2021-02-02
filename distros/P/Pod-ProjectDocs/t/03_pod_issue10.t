#!/usr/bin/env perl
# Test of https://github.com/mgruner/p5-pod-projectdocs/issues/10

use strict;
use warnings;
use utf8;

use FindBin;
use Test::More tests => 1;
use File::Path qw( remove_tree );

use lib '../lib';
use Pod::ProjectDocs;

Pod::ProjectDocs->new(
    outroot  => "$FindBin::Bin/03_pod_issue10_output",
    libroot  => "$FindBin::Bin/sample/lib3",
    forcegen => 1,
)->gen();

# using XML::XPath might be better
open my $fh, "<:encoding(utf-8)",
  "$FindBin::Bin/03_pod_issue10_output/Sample/Module.pm.html";
my $html = join '', <$fh>;
close $fh;

# link to Sample/Doc.pod, not to metacpan
like $html, qr!<a href="[^"]*?\bDoc\.pod\.html">Sample::Doc</a>!;

remove_tree("$FindBin::Bin/03_pod_issue10_output");
