#!/usr/bin/perl -w
use strict;
use SVK::Util qw( catdir tmpdir );
use File::Spec;
use SVK::Test;
plan tests => 18;

our ($answer, $output, @TOCLEAN);
my $xd = SVK::XD->new (depotmap => {},
		       checkout => Data::Hierarchy->new);
my $svk = SVK->new (xd => $xd, output => \$output);
push @TOCLEAN, [$xd, $svk];

my $repospath = catdir(tmpdir(), "svk-$$-".int(rand(1000)));
my $quoted = quotemeta($repospath);

set_editor(<< "TMP");
\$_ = shift;
open _, ">\$_" or die \$!;
print _ << "EOF";
'': '$quoted/'

===edit the above depot map===

EOF

TMP

$answer = 'n';
$svk->depotmap;
ok (!-e $repospath, '... did not initialize a repospath');

$answer = 'y';
$svk->depotmap ('--init');
ok (-d $repospath);
is_output_like ($svk, 'depotmap', ['--list'],
	       qr"//.*\Q$repospath\E", 'depotpath - list');
is_output ($svk, 'depotmap', ['--detach', '//'],
	   ["Depot '' detached."], 'depotpath - detach');
is_output ($svk, 'depotmap', ['--detach', '//'],
	   ["Depot '' does not exist in the depot map."], 'depotpath - detach again');
is_output ($svk, 'depotmap', ['//', $repospath],
	   ['New depot map saved.'], 'depotpath - add');
is_output ($svk, 'depotmap', ['--detach', $repospath],
	   ["Depot '' detached."], 'depotpath - detach with repospath');
is_output_like ($svk, 'depotmap', ['--detach', $repospath],
           qr/Depot '.+' does not exist in the depot map/,
           'depotpath - detach with repospath again');
is_output ($svk, 'depotmap', ['//', $repospath],
	   ['New depot map saved.'], 'depotpath - add again');
is_output ($svk, 'depotmap', ['//', $repospath],
	   ["Depot '' already exists; use 'svk depotmap --detach' to remove it first."], 'depotpath - add again');

is_output ($svk, 'depotmap', ['--relocate', '//'],
	   ["Need to specify a path name for depot."]);

$answer = 'n';
is_output ($svk, 'depotmap', ['--relocate', '//', "$repospath.new"],
	   [__("Depot '' relocated to '$repospath.new'.")], 'depotpath - relocate');
ok (!-e "$repospath.new", '... did not create a new repospath');
is_output ($svk, 'depotmap', ['--relocate', '//', $repospath],
	   [__("Depot '' relocated to '$repospath'.")], 'depotpath - relocate back');

is_output ($svk, 'depotmap', ['--relocate', $repospath => "$repospath.new"],
	   [__("Depot '' relocated to '$repospath.new'.")], 'depotpath - relocate from path');
ok (-e "$repospath.new", '... did create a new repospath');
is_output ($svk, 'depotmap', ['--relocate', "$repospath.new" => $repospath],
	   [__("Depot '' relocated to '$repospath'.")], 'depotpath - relocate back');
is_output ($svk, 'depotmap', ['--relocate', $repospath => catdir($repospath, 'db')], [
            __("Cannot rename $repospath to $repospath/db; please move it manually."),
            __("Depot '' relocated to '$repospath/db'."),
           ], 'depotpath - relocate impossibly');

rmtree [$repospath];
rmtree ["$repospath.new"];
