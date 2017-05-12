#!/usr/bin/perl

use Class::Easy;

BEGIN {
	use Class::Easy;
	logger ('debug')->appender (*STDERR);
	use IO::Easy;
	unshift @INC, dir->current->dir_io('lib')->path;

	use Test::More qw(no_plan);

	use_ok 'Project::Easy::Helper';

}

use Time::Piece;

my $pack = 'Acme::Project::Easy::Test';
my $path = 'Acme/Project/Easy/Test.pm';

my $here = dir->current;

my $project_root = $here->dir_io ('project-root');

if (-d $project_root) {
	$project_root->rm_tree;
}

# SIMULATION: mkdir project-root;

$project_root->create;

# SIMULATION: cd project-root

my $lib = dir->current->dir_io('lib')->path;

chdir $project_root;

`$^X -I$lib -MProject::Easy::Helper -e initialize $pack`;

# SIMULATION: project-easy $pack

# ::initialize ($pack);

# TEST

my $root = dir->current;
ok (-f $root->append ('lib', $path), 'libraries available');

# SIMULATION: bin/status

ok `$^X -I$lib bin/status` =~ /OK/ms;

# ok (Project::Easy::Helper::status);

# SIMULATION: bin/config

my $date = localtime->ymd;

my $schema_file = IO::Easy::File->new ('share/sql/default.sql');
$schema_file->parent->create;
$schema_file->store (
	$schema_file->contents .
	"--- $date.15\ncreate table list (list_id integer primary key, list_title text, list_meta text);\n"
	
);

my $update_status = `$^X -I$lib bin/updatedb`;
ok $update_status =~ /done$/ms;

# Project::Easy::Helper::update_schema;

# check for another datasource adding and query that datasource

$schema_file = file ('share/sql/sqlite.sql');

$update_status = `$^X -I$lib bin/config db.sqlite template db.sqlite`;
$update_status = `$^X -I$lib bin/config db.sqlite.attributes.dbname = $root/var/test2.sqlite`;
$update_status = `$^X -I$lib bin/config db.sqlite.update = $schema_file`;

$schema_file->parent->create;
$schema_file->store (
	"--- $date\ncreate table var (var_name text, var_value text);\n".
	"--- $date.15\ncreate table list (list_id integer primary key, list_title text, list_meta text);\n"
);

$update_status = `$^X -I$lib bin/updatedb --install --datasource=sqlite`;
ok $update_status =~ /done$/ms;

my $test_contents = '
#!/usr/bin/perl

use Project::Easy qw(script);

BEGIN {
	use IO::Easy;
	unshift @INC, dir->current->dir_io("lib")->path;

	use Test::More qw(no_plan);
};

my $list = $::project->entity ("list");

ok $list;

warn $list;

my $list_rec = $list->new;

$list_rec->id (15);
$list_rec->title ("hello, world!");

ok $list_rec->create;

ok $::project->collection ("list")->new->count == 1;

# second datasource

$list = $::project->entity ("sqlite_list");

ok $list;

warn $list;

$list_rec = $list->new;

$list_rec->id (22);
$list_rec->title ("hello, world2!");

ok $list_rec->create;

$list_rec = $list->new;

$list_rec->id (23);
$list_rec->title ("hello, world2!");

ok $list_rec->create;

ok $::project->collection ("sqlite_list")->new->count == 2;
ok $::project->collection ("list")->new->count == 1;
';

$project_root->file_io (qw(t 001.t))->store ($test_contents);

chdir $here;

ok `$^X -I$lib project-root/bin/status` =~ /OK/ms;

$project_root->scan_tree (sub {
	my $f = shift;
	# return 0 if $file->type eq 'dir'
	warn $f->rel_path ($project_root), "\n"
		if $f->type eq 'file';
	return 1;
});

if (eval {`whoami`} ne 'apla') {
	$project_root->rm_tree;
}

exit;

# REMOVING var AND REINITIALIZATION

$root->dir_io ('var')->rm_tree;

warn '!!!!!!!!!!!!!!!', Project::Easy::Helper::status;

# RESTORING

chdir $here;

$project_root->rm_tree;
