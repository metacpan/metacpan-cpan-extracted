#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

BEGIN {
    chdir 't' if -d 't';
}
use lib '../lib';
use Pod::WikiText;

my $wiki = <<ENDWIKI;
##format:html
##infile:test1.wiki
##outfile:test1.html
##title:test1
##author:John Adams
=begin wiki

!1 Lorem Ipsum 1

Lorem ipsum.

!2 Lorem Ipsum 2

Lorem ipsum.

!3 Lorem Ipsum 3

Lorem ipsum.

!4 Lorem Ipsum 4

Lorem ipsum.

----
ENDWIKI

my ($fh,$text);

# create some html
open($fh,'>','test1.wiki') or die "unable to create test1.wiki";
print $fh $wiki;
close($fh);
my $formatter = Pod::WikiText->new(infile=>'test1.wiki',outfile=>'test1.html');
$formatter->format();

# now read in the html
open($fh,'<','test1.html') or die "unable to open test1.html";
while (<$fh>) {
    $text .= $_;
}
close($fh);

# test data
my $tstr1 = '<meta name="author" content="John Adams">';
my $tstr2 = '<title>test1<\/title>';
my $tstr3 = '  <li><a href="#LoremIpsum1">Lorem Ipsum 1<\/a><\/li>';
my $tstr4 = '    <li><a href="#LoremIpsum2">Lorem Ipsum 2<\/a><\/li>';
my $tstr5 = '      <li><a href="#LoremIpsum3">Lorem Ipsum 3<\/a><\/li>';
my $tstr6 = '        <li><a href="#LoremIpsum4">Lorem Ipsum 4<\/a><\/li>';
my $tstr7 = '<hr \/><h1><a id="LoremIpsum1"><\/a>Lorem Ipsum 1<\/h1>';
my $tstr8 = '<h2><a id="LoremIpsum2"><\/a>Lorem Ipsum 2<\/h2>';
my $tstr9 = '<h3><a id="LoremIpsum3"><\/a>Lorem Ipsum 3<\/h3>';
my $tstr10 = '<h4><a id="LoremIpsum4"><\/a>Lorem Ipsum 4<\/h4>';
my $tstr11 = '<hr \/><p><em>Created using WikiText, Version ';

# begin tests
ok($text =~ /^$tstr1$/m,'author');
ok($text =~ /^$tstr2$/m,'title');
ok($text =~ /^$tstr3$/m,'index entry 1');
ok($text =~ /^$tstr4$/m,'index entry 2');
ok($text =~ /^$tstr5$/m,'index entry 3');
ok($text =~ /^$tstr6$/m,'index entry 4');
ok($text =~ /^$tstr7$/m,'<h1>');
ok($text =~ /^$tstr8$/m,'<h2>');
ok($text =~ /^$tstr9$/m,'<h3>');
ok($text =~ /^$tstr10$/m,'<h4>');
ok($text =~ /^$tstr11/m,'footer');

END {
    unlink 'test1.wiki';
    unlink 'test1.html';
}

exit 0;
