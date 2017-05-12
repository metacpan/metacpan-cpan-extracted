package Project::Easy::Helper;

use Data::Dumper;
use Class::Easy;
use IO::Easy;

use Time::Piece;

require Project::Easy;

use Project::Easy::Config;

use Project::Easy::Helper::DB;
use Project::Easy::Helper::Status;
use Project::Easy::Helper::Config;
use Project::Easy::Helper::Console;

our @scriptable = (qw(status config updatedb console));

my $is_colored = 0;

$is_colored = 1
	if try_to_use ('Term::ANSIColor');

sub ::initialize {
	my $params = \@_;
	$params = \@ARGV
		unless scalar @$params;
	
	my $namespace = shift @$params;

	my @path = ('lib', split '::', $namespace);
	my $last = pop @path;

	my $project_id = shift @ARGV || lc ($last);
	
	debug "initialization of $namespace, project id is: $project_id";
	
	unless ($namespace) {
		die "please specify package namespace";
	}
	
	my $data_files = file->__data__files;
	
	my $data = {
		namespace => $namespace,
		project_id => $project_id,
	};
	
	my $project_pm = Project::Easy::Config::string_from_template (
		$data_files->{'Project.pm'},
		$data
	);

	my $login = eval {scalar getpwuid ($<)};

	my $instance = 'local' . (defined $login ? ".$login" : '');
	
	my $root = dir->current;
	
	my $lib_dir = $root->append (@path)->as_dir;
	$lib_dir->create; # recursive directory creation	
	
	$last .= '.pm';
	my $class_file = $lib_dir->append ($last)->as_file;
	$class_file->store_if_empty ($project_pm);
	
	# ok, project skeleton created. now we need to create 'bin' dir
	$root->dir_io ('bin')->create;
	
	# now we create several perl scripts to complete installation 
	create_scripts ($root, $data_files);
	
	# ok, project skeleton created. now we need to create config
	my $etc = $root->append ('etc')->as_dir;
	$etc->append ($instance)->as_dir->create;
	
	# TODO: store database config
	$etc->append ("$project_id.json")->as_file->store_if_empty ('{}');
	$etc->append ($instance, "$project_id.json")->as_file->store_if_empty ('{}');
	
	$etc->append ('project-easy')->as_file->store_if_empty ("#!/usr/bin/perl
package LocalConf;
our \$pack = '$namespace';

our \@paths = qw(
);

1;
");
	
	my $var = create_var ($root);
	
	my $instance_file = $var->append ('instance')->as_file;
	$instance_file->store_if_empty ($instance);

	my $t = $root->append ('t')->as_dir;
	$t->create;
	
	create_entity ($namespace, $root, 'default');
	
	# adding sqlite database (sqlite is dependency for dbi::easy)
	
	debug "file contents saving done";
	
	$0 = dir->current->append (qw(etc project-easy))->path;
	
	my $date = localtime->ymd;
	
	my $schema_file = file ('share/sql/default.sql');
	$schema_file->parent->create;
	$schema_file->store (
		"--- $date\ncreate table var (var_name text, var_value text);\n"
	);

	config (qw(db.default template db.sqlite));
	config (qw(db.default.attributes.dbname = ), '{$root}/var/test.sqlite');
	config (qw(db.default.update =), "$schema_file");
	
	$namespace->config ($instance);
	
	update_schema (
		mode => 'install'
	);
	
	# TODO: be more user-friendly: show help after finish
	
	
}

sub create_scripts {
	my $root       = shift;
	my $data_files = shift;

	foreach (@scriptable) {
		my $script = $root->file_io ('bin', $_);

		my $script_contents = Project::Easy::Config::string_from_template (
			$data_files->{'script.template'},
			{script_name => $_}
		);

		$script->store_if_empty ($script_contents);
		
		warn  "can't chmod " . $script->path
			unless chmod 0755, $script->path;
		
	}

}

sub helping_hand {
	
}

sub create_entity {
	my $namespace = shift;
	my $root       = shift;
	my $datasource = shift;
	
	if (defined $::project) {
		$namespace = $::project;
	}

	my @namespace_chunks = split /\:\:/, $namespace;
	
	# here we must create default entity classes
	my $project_lib = $root->dir_io ('lib', @namespace_chunks, 'Entity');
	$project_lib->create;
	
	my $scope_prefix = '';
	if ($datasource ne 'default') {
		$scope_prefix = ($namespace->_detect_entity ("${datasource}_test"))[2];
	}
	
	my $data_files = file->__data__files;

	my $entity_template = $data_files->{'Entity.pm'};

	my $entity_pm = Project::Easy::Config::string_from_template (
		$entity_template,
		{
			namespace => $namespace,
			scope => $scope_prefix.'Record', # 
			dbi_easy_scope => 'Record',
			datasource => $datasource
		}
	);

	$project_lib->append ("${scope_prefix}Record.pm")->as_file->store_if_empty ($entity_pm);

	$entity_pm = Project::Easy::Config::string_from_template (
		$entity_template,
		{
			namespace => $namespace,
			scope => $scope_prefix.'Collection', #
			dbi_easy_scope => 'Record::Collection',
			datasource => $datasource
		}
	);

	$project_lib->append ("${scope_prefix}Collection.pm")->as_file->store_if_empty ($entity_pm);

}

sub create_var {
	my $root = shift;
	my $var = $root->dir_io ('var');
	foreach (qw(db lock log run)) {
		$var->dir_io ($_)->create;
	}
	
	return $var;
}

sub shell {
	my ($pack, $libs) = &_script_wrapper;
	
	my $core = $pack->singleton;
	
	my $instance = $ARGV[0];
	
	my $conf  = $core->config ($instance);
	my $sconf = $conf->{shell};
	
	unless (try_to_use 'Net::SSH::Perl' and try_to_use 'Term::ReadKey') {
		die "for remote shell you must install Net::SSH::Perl and Term::ReadKey packages";
	}
	
	my %args = ();
	foreach (qw(compression cipher port debug identity_files use_pty options protocol)) {
		$args{$_} = $sconf->{$_}
			if $sconf->{$_};
	}
	
	$args{interactive} = 1;
	
	my $ssh = Net::SSH::Perl->new ($conf->{host}, %args);
	$ssh->login ($sconf->{user});
	
	ReadMode('raw');
	eval "END { ReadMode('restore') };";
	$ssh->shell;

}

sub _script_wrapper {
	# because some calls dispatched to external scripts, but called from project dir
	my $local_conf = shift || $0;
	my $importing  = shift ||  0;
	my $lib_path;
	
	return ($::project, $::libs)
		if defined $::project;

	debug "called from $local_conf";
	
	$local_conf = dir ($local_conf);
	
	my $root;
	
	if (exists $ENV{'MOD_PERL'}) {
		
		my $server_root;
		
		if (
			exists $ENV{MOD_PERL_API_VERSION}
			and $ENV{MOD_PERL_API_VERSION} >= 2
			and try_to_use_inc ('Apache2::ServerUtil')
		) {
			
			$server_root = Apache2::ServerUtil::server_root();
			
		} elsif (try_to_use_inc ('Apache')) {
			
			$server_root = Apache::server_root_relative('');
			
		} else {
			die "you try to run project::easy under mod_perl, but we cannot work with your version. if you have mod_perl-1.99, use solution from CGI::minimal or upgrade your mod_perl";
		}
		
		$root = dir ($server_root);
		$local_conf = $root->dir_io (qw(etc project-easy));
		$lib_path   = $root->dir_io ("lib");
		
	} elsif ($local_conf->name eq 'project-easy' and $local_conf->parent->name eq 'etc') {
		# TODO: use etc method from project package
		$root = $local_conf->parent->parent;
		$lib_path = $local_conf->parent->parent->dir_io ('lib');
	} else {
		
		my $parent = $local_conf;
		PROJECT_ROOT: while ($parent = $parent->parent) {
			
			foreach (qw(t cgi-bin tools bin)) {
				if ($parent->name eq $_) {
					$root = $parent->parent;
					$local_conf = $root->file_io (qw(etc project-easy));
					$lib_path = $root->dir_io ('lib');
					last PROJECT_ROOT;
				}
			}
			
			last if ($parent->path eq $parent->parent->path);
			
		}
		die unless defined $root;
	}
	
	$lib_path = $lib_path->abs_path;
	
	debug "local conf is: $local_conf, lib path is: ",
		join (', ', @LocalConf::paths, $lib_path), "\n";
	
	require $local_conf;

	push @INC, @LocalConf::paths, $lib_path->path;
	
	my $pack = $LocalConf::pack;
	
	debug "main project module is: $pack";

	#use Carp;
	#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };
	
	# check for required directories, create if necessary
	if (! -d $root->dir_io ('var')) {
		create_var ($root);
	}
	
	# here we check for real package availability
	
	eval "use Class::Easy; use IO::Easy; use DBI::Easy; " . ($importing ? '' : "use $pack;");
	if ($@) {
		die 'base modules fails: ', $@;
	}

	my @result = ($::project, $::libs) = ($pack, [@LocalConf::paths, $lib_path->path]);
	
	return @result;
}

sub table_from_package {
	my $entity = shift;
	
	lc join ('_', split /(?=\p{IsUpper}\p{IsLower})/, $entity);
}

sub package_from_table {
	my $table = shift;
	
	join '', map {ucfirst} split /_/, $table;
}

1;


__DATA__

########################################
# IO::Easy::File Project.pm
########################################

package {$namespace};

use Class::Easy;

use base qw(Project::Easy);

has id => '{$project_id}';
has conf_format => 'json';

my $class = __PACKAGE__;

has entity_prefix => join '::', $class, 'Entity', '';

$class->init;
$class->instantiate;

1;

########################################
# IO::Easy::File script.template
########################################

#!/usr/bin/env perl
use Class::Easy;
use Project::Easy::Helper;
&Project::Easy::Helper::{$script_name};

########################################
# IO::Easy::File Entity.pm
########################################

package {$namespace}::Entity::{$scope};

use Class::Easy;

use base qw(DBI::Easy::{$dbi_easy_scope});

our $wrapper = 1;

sub _init_db {
	my $self = shift;
	
	$self->dbh ($::project->can ('db_{$datasource}'));
}

1;

########################################
# IO::Easy::File template
########################################

########################################
# IO::Easy::File config-usage
########################################

Usage:  db.<database_id> template db.<template_name>	OR
		db.<database_id>.username set "<password>"	  OR
		db.<database_id>.username

Example (add new database config "local_test_db_id" with mysql template) :
bin/config db.local_test_db_id template db.mysql

########################################
# IO::Easy::File template-db.sqlite
########################################

{
	"driver_name": "SQLite",
	"attributes": {
		"dbname" : null
	},
	"options": {
		"RaiseError": 1,
		"AutoCommit": 1,
		"ShowErrorStatement": 1
	}
}


########################################
# IO::Easy::File template-db.mysql
########################################

{
	"user": null,
	"pass": null,
	"driver_name": "mysql",
	"attributes": {
		"database" : null,
		"mysql_multi_statements": 0,
		"mysql_enable_utf8": 1,
		"mysql_auto_reconnect": 1,
		"mysql_read_default_group": "perl",
		"mysql_read_default_file": "{$root}/etc/my.cnf"
	},
	"options": {
		"RaiseError": 1,
		"AutoCommit": 1,
		"ShowErrorStatement": 1
	}
}

########################################
# IO::Easy::File template-db.oracle
########################################

{
	"user": null,
	"pass": null,
	"driver_name": "oracle",
	"options" : {
		"AutoCommit" : 1,
		"ShowErrorStatement" : 0,
		"RaiseError" : 1,
		"PrintError" : 0,
		"LongReadLen" : 1024288,
		"LongTruncOk" : 1,
		"ora_charset" : "AL32UTF8"
	},
	"do_after_connect" : [
		"alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'"
	]
}

########################################
# IO::Easy::File template-db.default
########################################
{
	"user": null,
	"pass": null,
	"driver_name": null, // mysql, oracle, pg, …
	"attributes": {
		"database" : null
	},
	"options": {
		"RaiseError": 1,
		"AutoCommit": 1,
		"ShowErrorStatement": 1
	}
}

