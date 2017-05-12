#!/usr/local/bin/perl -w

use Test;
use strict;
use vars qw($loaded);

BEGIN { plan tests => 10,
	onfail => sub { print "\n*** Tests failed! ***\n" } };
END   { print "not ok 1\n" unless $loaded }

use SWF::Search;

$loaded = 1;
print "...loading\n";
ok(1); 

my $s = SWF::Search->new(File=>"_testswf/test1.swf");

my $jtext  = "test text one:test text two:test text three";
my $jlabel = "frame label foo:frame label bar:frame label baz";

print "...checking search\n";
ok(join(":",$s->search),"$jtext:$jlabel");
ok(join(":",$s->search('text')),$jtext);
ok(join(":",$s->search('label')),$jlabel);
ok($s->search('LABEL', CaseSensitive => 1), 0);
ok($s->search('text', Type=>'Label'), 0);
ok(join(":",$s->search('baz', Type=>'Label')),'frame label baz');
ok(join(":",$s->search('two', Type=>'EditText')),'test text two');

#  editText and label searches

my @str = $s->strings;
print "...text strings\n";

ok(join(":",@str),
   "test text one:test text two:test text three");
my @lab = $s->labels;
print "...frame labels\n";
ok(join(":",@lab),
   "frame label foo:frame label bar:frame label baz");

