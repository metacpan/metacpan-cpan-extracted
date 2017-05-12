#!/usr/bin/perl -w

use strict;
use blib;

use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN {
	plan tests => 313;
	use_ok('Search::Estraier');
};

my $debug = shift @ARGV;

# name of node for test
my $test1_node = '_test1_' . $$;
my $test2_node = '_test2_' . $$;

my $estmaster_uri = $ENV{'ESTMASTER_URI'} || 'http://localhost:1978';

ok(my $node = new Search::Estraier::Node( debug => $debug ), 'new');
isa_ok($node, 'Search::Estraier::Node');

ok($node->set_url("$estmaster_uri/node/$test1_node"), "set_url $test1_node");

ok($node->set_proxy('', 8080), 'set_proxy');
throws_ok {$node->set_proxy('proxy.example.com', 'foo') } qr/port/, 'set_proxy port NaN';

ok($node->set_timeout(42), 'set_timeout');
throws_ok {$node->set_timeout('foo') } qr/timeout/, 'set_timeout NaN';

my ($user, $passwd) = (
	$ENV{EST_USER} || 'admin',
	$ENV{EST_PASSWD} || 'admin'
);

ok($node->set_auth($user, $passwd), 'set_auth');

cmp_ok($node->status, '==', -1, 'status');

# test master functionality

SKIP: {

skip "can't find estmaster at $estmaster_uri", ( 313 - 10 ) if (! eval { $node->master( action => 'nodelist' ) } );

diag "using $estmaster_uri";
diag("node->master shutdown not tested");

diag("node->master backup not tested");

ok(my @users = $node->master( action => 'userlist' ), 'userlist');

#diag "users: ", Dumper( \@users );
diag "found ", $#users + 1, " users";

my $user = {
	name => '_test_' . $$,
	flags => 'b',
	fname => 'Search::Estraier',
	misc => 'test user',
};

my $msg;
ok($msg = $node->master(
	action => 'useradd',
	%{ $user },
	passwd => 'test1234',
), "useradd: $msg");

ok(my @users2 = $node->master( action => 'userlist' ), 'userlist');
cmp_ok($#users2, '==', $#users + 1, 'added user');

while (my $row = shift @users2) {
	next unless ($row->{name} eq $user);
	map {
		cmp_ok($user->{$_}, 'eq', $row->{$_}, "$_");
	} keys %{ $user };
}

ok($msg = $node->master(
	action => 'userdel',
	name => $user->{name},
), "userdel: $msg");

ok(@users2 = $node->master( action => 'userlist' ), 'userlist');
cmp_ok($#users2, '==', $#users, 'removed user');

ok(my @nodes = $node->master( action => 'nodelist' ), 'nodelist' );
#diag "nodelist: ", Dumper( \@nodes );
diag "found ", $#nodes + 1, " nodes";

if ($#nodes > 42) {
	diag <<'_END_OF_WARNING_';

This tests create three nodes in your Hyper Estraier.

Since you have more than 43 modes, and Hyper Estraier needs more than
1024 file descriptors for more than 46 nodes, expect tests to fail.

If tests do fail, you can try to add

ulimit -n 2048

before staring estmaster, which will increase number of available nodes
to 96 before estmaster runs out of file descriptors.

_END_OF_WARNING_
}

my $temp_node = "_test_temp_$$";

foreach my $node_name ( $test1_node , $test2_node, $temp_node ) {
	ok($msg = $node->master(
		action => 'nodeadd',
		name => $node_name,
		label => "$node_name label",
	), "nodeadd $node_name: $msg");
}

ok($msg = $node->master(
	action => 'nodedel',
	name => $temp_node,
), "nodedel $temp_node: $msg");

#diag "not testing logrtt\n";

# test document creation

my $draft = <<'_END_OF_DRAFT_';
@uri=data0
@title=Material Girl

Living in a material world
And I am a material girl
You know that we are living in a material world
And I am a material girl
_END_OF_DRAFT_

#diag "draft:\n$draft";
ok(my $doc = new Search::Estraier::Document($draft), 'new doc from draft');

ok( $node->put_doc($doc), "put_doc data001");

for ( 1 .. 17 ) {
	$doc->add_attr('@uri', 'test' . $_);
	$doc->set_score( $_ * 10000 );
	ok( $node->put_doc($doc), "put_doc test$_");
	#diag $doc->dump_draft;
	cmp_ok( $node->doc_num, '==', ($_ + 1), "node->doc_num " . ($_ + 1));
}

ok(! $node->uri_to_id( 'does-not-exists' ), "non-existant uri_to_id");

my $id;
ok($id = $node->uri_to_id( 'data0' ), "uri_to_id(data0)");

throws_ok { $node->get_doc( 'foo') } qr/id must be number/, 'croak on non-number';

ok($doc = $node->get_doc( $id ), "get_doc($id) for edit");
$doc->add_attr('foo', 'bar');
#diag Dumper($doc);
ok( $node->edit_doc( $doc ), 'edit_doc');

my $doc_num;
ok( $doc_num = $node->doc_num, "node->doc_num $doc_num");

ok( $node->out_doc( $id ), "out_doc($id)");

cmp_ok( $node->doc_num, '==', --$doc_num, "node->doc_num " . $doc_num);

ok( ! $node->edit_doc( $doc ), "edit_doc of removed doc");

my $cache;
ok($cache = $node->cacheusage, "cacheusage: $cache");

my $delete_num = 5;

for ( 1 .. $delete_num ) {
	ok( $node->out_doc_by_uri( 'test' . $_ ), "out_doc_by_uri test$_");
	cmp_ok( $node->doc_num, '==', $doc_num - $_, "node->doc_num " . ($doc_num - $_));
}

my $doc_num2 = $doc_num - $delete_num;
cmp_ok($node->doc_num, '==', $doc_num2, "node->doc_num $doc_num2");

my $max = int($doc_num2 / 2);

ok(my $cond = new Search::Estraier::Condition, 'new cond');
ok($cond->set_phrase('girl'), 'cond set_phrase');
ok($cond->set_max($max), "cond set_max($max)");
ok($cond->set_order('@uri ASCD'), 'cond set_order');
ok($cond->add_attr('@title STRINC Material'), 'cond add_attr');
ok($cond->set_mask(qw/1 2/), 'cond set_mask');

cmp_ok($node->cond_to_query( $cond ), 'eq' , 'phrase=girl&attr1=%40title%20STRINC%20Material&order=%40uri%20ASCD&max='.$max.'&wwidth=480&hwidth=96&awidth=96&mask=6', 'cond_to_query');

ok( my $nres = $node->search( $cond, 0 ), 'search');

isa_ok( $nres, 'Search::Estraier::NodeResult' );

cmp_ok($nres->doc_num, '==', $max, "nres->doc_num $max");

cmp_ok($nres->hits, '==', $doc_num2, "nres->hits $doc_num2");

# upper limit is $nres->hits and not $nres->doc_num because we
# check all documents, not just results!
for my $i ( 0 .. ($nres->hits - 1) ) {
	my $num = $i + $delete_num + 1;
	my $uri = 'test' . $num;

	if ($i < $nres->doc_num) {
		ok( my $rdoc = $nres->get_doc( $i ), "nres->get_doc $i");

		cmp_ok( $rdoc->attr('@uri'), 'eq', $uri, "\@uri = $uri");
		cmp_ok( $node->uri_to_id( $uri ), '==', $num + 1, "uri_to_id($uri)");

		ok( my $k = $rdoc->keywords( $id ), "rdoc keywords");
	} else {
		ok( ! $nres->get_doc( $i ), "nres->get_doc doesn't exist");
	}

	ok( my $id = $node->uri_to_id( $uri ), "uri_to_id($uri)");
	my $doc;
	my $score = $num * 10000;
	ok( $doc = $node->get_doc( $id ), "get_doc($id)");
	cmp_ok( $doc->score, '==', $score, "score $score");
	ok( $doc = $node->get_doc_by_uri( $uri ), "get_doc_by_uri($uri)");
	cmp_ok( $doc->score, '==', $score, "score $score");
	cmp_ok( $node->get_doc_attr( $id, '@uri' ), 'eq', $uri, "get_doc_attr $id");
	cmp_ok( $node->get_doc_attr_by_uri( $uri, '@uri' ), 'eq', $uri, "get_doc_attr $id");
	ok( my $k1 = $node->etch_doc( $id ), "etch_doc_by_uri $uri");
	ok( my $k2 = $node->etch_doc_by_uri( $uri ), "etch_doc_by_uri $uri");
	#diag Dumper($k, $k2);
	ok( eq_hash( $k1, $k2 ), "keywords");
}

ok(my $hints = $nres->hints, 'hints');
diag Dumper($hints) if ($debug);
foreach my $h (qw/TIME DOCNUM VERSION NODE HIT WORDNUM/) {
	ok(defined( $nres->hint($h) ), "have hint $h");
}

ok($node->_set_info, "refresh _set_info");

my $v;
ok($v = $node->name, "name: $v");
ok($v = $node->label, "label: $v");
ok($v = $node->doc_num, "doc_num: $v");
ok(defined($v = $node->word_num), "word_num: $v");
ok($v = $node->size, "size: $v");

ok($node->set_snippet_width( 100, 10, 10 ), "set_snippet_width");

# test skip
my $skip = int($max / 2) || die "skip is zero, can't test";
ok($cond->set_skip( $skip ), "cond set_skip($skip)");
cmp_ok($cond->skip, '==', $skip, "skip is $skip");

like($node->cond_to_query( $cond ), qr/skip=$skip/, 'cond_to_query have skip');

ok( $nres = $node->search( $cond, 0 ), 'search');
isa_ok( $nres, 'Search::Estraier::NodeResult' );
cmp_ok($nres->doc_num, '==', $max, "nres->doc_num " . ($max - $skip));
cmp_ok($nres->hits, '==', $doc_num2, "nres->hits $doc_num2");

for my $i ( 0 .. ($nres->doc_num - 1) ) {
	my $uri = 'test' . ($i + $delete_num + $skip + 1);
	ok( my $rdoc = $nres->get_doc( $i ), "nres->get_doc $i");
	if ($rdoc) {
		cmp_ok( $rdoc->attr('@uri'), 'eq', $uri, "\@uri = $uri");
	} else {
		fail('no rdoc');
	}
}

# test distinct
ok($cond = new Search::Estraier::Condition, 'new cond');
ok($cond->set_phrase('girl'), 'cond set_phrase');
my $distinct = '@title';
ok($cond->set_distinct( $distinct ), "cond set_distinct($distinct)");
cmp_ok($cond->distinct, 'eq', $distinct, "distinct is $distinct");
like($node->cond_to_query( $cond ), qr/distinct=%40title/, 'cond_to_query have distinct');
ok( $nres = $node->search( $cond, 0 ), 'search with distinct');
cmp_ok($nres->doc_num, '==', 1, "nres->doc_num");
cmp_ok($nres->hits, '==', 1, "nres->hits");
diag "nres = ", Dumper( $nres ) if ($debug);

# user doesn't exist
ok($node->set_user('foobar', 1), 'set_user');

ok(my $node2 = new Search::Estraier::Node( "$estmaster_uri/node/$test2_node" ), "new $test2_node");
ok($node2->set_auth('admin','admin'), "set_auth $test2_node");

# croak_on_error

ok($node = new Search::Estraier::Node( url => "$estmaster_uri/non-existant", croak_on_error => 1 ), "new non-existant");
throws_ok { $node->name } qr/404/, 'croak on error';

# croak_on_error
ok($node = new Search::Estraier::Node( url => "$estmaster_uri/node/$test1_node", croak_on_error => 1, user => $user, passwd => $passwd, debug => $debug ), "new $test1_node");

ok(! $node->uri_to_id('foobar'), 'uri_to_id without croak');


# test users
ok($node->admins, 'have admins');
ok(! $node->guests, 'no guests');


# test search without results
ok($cond = new Search::Estraier::Condition, 'new cond');
ok($cond->set_phrase('this_is_phrase_which_does_not_exits'), 'cond set_phrase');

ok($nres = $node->search( $cond, 0 ), 'search');

# now, test links
my $test2_label = "$test2_node label";
my $link_url = "$estmaster_uri/node/$test2_node";
ok($node->set_link( $link_url, $test2_label, 42), "set_link $test2_node ($test2_label) 42");
ok(my $links = $node->links, 'links');
cmp_ok($#{$links}, '==', 0, 'one link');
like($links->[0], qr/^$link_url/, 'link correct');
ok($node->set_link("$estmaster_uri/node/$test2_node", $test2_label, 0), "set_link $test2_node ($test2_label) delete");

ok($msg = $node->master(
	action => 'nodeclr',
	name => $node->name,
), "nodeclr " . $node->name . ": $msg");

cmp_ok($node->doc_num, '==', 0, 'no documents');

# cleanup test nodes
foreach my $node_name ( $test1_node , $test2_node ) {
	ok($msg = $node->master(
		action => 'nodedel',
		name => $node_name,
	), "nodedel $node_name: $msg");
}

# test create
my $node_name = '_test_create_' . $$;
my $node_label = "test $$ label";

ok($node = new Search::Estraier::Node(
	url => "$estmaster_uri/node/$node_name",
	create => 1,
	label => $node_label,
	croak_on_error => 1
), "new create+croak");

cmp_ok($node->name, 'eq', $node_name, "node $node_name exists");
cmp_ok($node->label, 'eq', $node_label, "node label: $node_label");

ok($node = new Search::Estraier::Node(
	url => "$estmaster_uri/node/$node_name",
	create => 1,
	label => $node_label,
	croak_on_error => 0
), "new create existing");

ok($node = new Search::Estraier::Node(
	url => "$estmaster_uri/node/$node_name",
	create => 1,
	label => $node_label,
	croak_on_error => 1
), "new create+croak existing");

# cleanup
ok($msg = $node->master(
	action => 'nodedel',
	name => $node_name,
), "nodedel $node_name: $msg");

# and again, this time without node
ok($node = new Search::Estraier::Node(
	url => "$estmaster_uri/node/$node_name",
	create => 1,
	label => $node_label,
	croak_on_error => 0
), "new create non-existing");

cmp_ok($node->name, 'eq', $node_name, "node $node_name exists");
cmp_ok($node->label, 'eq', $node_label, "node label: $node_label");

# cleanup
ok($msg = $node->master(
	action => 'nodedel',
	name => $node_name,
), "nodedel $node_name: $msg");

ok($msg = $node->master( action => 'sync' ), "sync: $msg");

} # SKIP

diag "over";
