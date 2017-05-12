#! /usr/bin/perl

use Test::More tests => 18;
use FindBin;

use Sphinx::Config;

my $filename = $FindBin::Bin . "/sphinx.conf.dist";
my $c = Sphinx::Config->new;
ok($c, "new");
$c->parse($filename);
ok($c->config, "parse");

is($c->get("source", "src1", "type"), "mysql", "get single var");
is_deeply($c->get("indexer"), { mem_limit => "32M"}, "get complex var");
$c->set("source", "src1", "type", "pgsql");
is($c->get("source", "src1", "type"), "pgsql", "set single var");
$c->set("indexer", undef, { mem_limit => "16M"});
is_deeply($c->get("indexer"), { mem_limit => "16M"}, "set complex var");

my $outfile = $FindBin::Bin . "/sphinx.conf.test";
END { unlink $outfile if $outfile }
$c->save($outfile); #, "# Test output file");

my $c2 = Sphinx::Config->new;
$c2->parse($outfile);
is_deeply($c->config, $c2->config, "save");

$c->preserve_inheritance(0);
$c->set("source", "src1", "type", "mysql");
is($c->get("source", "src1", "type"), "mysql", "set single var no inheritance, parent");
is($c->get("source", "src1stripped", "type"), "pgsql", "set single var no inheritance, child");
$c->set("source", "src1", "sql_attr_timestamp", [ qw/birthday anniversary/ ]);
is_deeply($c->get("source", "src1", "sql_attr_timestamp"), [ qw/birthday anniversary/ ], 'multi-key');

$c->save($outfile, "# Test output file");
$c2->parse($outfile);
is($c2->get("source", "src1", "type"), "mysql", "save, no inheritance, parent");
is($c2->get("source", "src1stripped", "type"), "pgsql", "save, no inheritance, child");
is_deeply($c2->get("source", "src1", "sql_attr_timestamp"), [ qw/birthday anniversary/ ], 'save, multi-key');

# delete
$c->preserve_inheritance(1);
$c->set("source", "src1", "sql_db", undef);
ok(! defined($c->get("source", "src1", "sql_db")), "delete");
ok(! defined($c->get("source", "src1stripped", "sql_db")), "delete inherited");
$c->set("source", "src1stripped", undef);
ok(! defined($c->get("source", "src1stripped")), "delete block");
$c->save($outfile, "# Test output file");
$c2->parse($outfile);
ok(! defined($c2->get("source", "src1", "sql_db")), "save, deleted");
ok(! defined($c2->get("source", "src1stripped")), "save, deleted block");
