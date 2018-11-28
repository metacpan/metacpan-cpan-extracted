use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Basename;
use Cwd 'abs_path';
use File::Spec;
our $VERSION = 0.07;

print "\nMakefile.PL for TaskPipe version $VERSION\n(c) Virtual Blue LTD 2018\n\n";


my $include_db_tests = prompt("During install, do you wish to run thread-related tests? These tests need a MySQL (or MariaDB) server instance to be running, 2 empty databases, and a username/password with full access to those databases. Testing may take a few minutes", "N") =~ /y/i;

my %dbinfo;

if ( $include_db_tests ){
    $dbinfo{hostname} = prompt("Enter MySQL/MariaDB database host","localhost");
    $dbinfo{port} = prompt("Enter MySQL/MariaDB database port (leave blank for default)","");
    $dbinfo{global_db} = prompt("Enter MySQL/MariaDB test database name (global)","taskpipe");
    $dbinfo{project_db} = prompt("Enter MySQL/MariaDB test database name (project)","taskpipe_project");
    $dbinfo{username} = prompt("Enter MySQL/MariaDB username","");
    $dbinfo{password} = prompt("Enter MySQL/MariaDB password","");

    foreach my $param (keys %dbinfo){
        if ( ! $dbinfo{$param} ){
            $dbinfo{$param} = "''";
        }
    }

    write_threaded_global_conf();
    write_threaded_project_conf();

}




WriteMakefile(
    NAME              => 'TaskPipe',
    VERSION_FROM      => 'lib/TaskPipe/Task.pm',
    PREREQ_PM         => {
        'MooseX::ConfigCascade' => '0.02',
        'Pod::Term' => '0.02',
        'Template::Nest' => '0.03',
        'Log::Log4perl::Layout::ColoredPatternLayout' => '0.01',
        'Fatal' => 0,
        'Selenium::Remote::Driver' => 0,
        'WWW::Mechanize::PhantomJS' => '0.18',
        'Log::Log4perl' => '1.49',
        'Moose' => 0,
        'Module::Runtime' => 0,
        'DateTime' => 0,
        'DateTime::Format::MySQL' => 0,
        'DateTime::Format::SQLite' => 0,
        'DBIx::Class' => 0,
        'Data::Dumper' => 0,
        'Log::Log4perl' => 0,
        'File::Basename' => 0,
        'Web::Scraper' => 0,
        'File::Spec' => 0,
        'DBIx::Class::Schema::Loader' => 0,
        'DBIx::Error' => 0,
        'File::Path' => 0,
        'File::Path::Expand' => 0,
        'File::Slurp' => 0,
        'Try::Tiny' => 0,
        'Digest::MD5' => 0,
        'Time::HiRes' => 0,
        'MooseX::ClassAttribute' => 0,
        'Proc::ProcessTable' => 0,
        'File::Save::Home' => 0,
        'Pod::POM' => 0,
        'LWP::UserAgent' => 0,
        'URI::Escape' => 0,
        'IO::Socket::INET' => 0,
        'Net::EmptyPort' => 0,
        'Path::Tiny' => 0,
        'Proc::Background' => 0,
        'Proc::Exists' => 0,
        'File::Inplace' => 0,
        'Text::Table::TinyColor' => 0,
        'Term::ANSIColor' => 0,
        'Moose::Util::TypeConstraints' => 0,
        'Hash::Merge' => 0,
        'Array::Utils' => 0,
        'String::CamelCase' => 0,
        'Term::ANSIColor' => 0,
        'YAML::XS' => 0,
        'TryCatch' => 0,
        'Carp' => 0,
        'Clone' => 0,
        'Cwd' => 0,
        'POSIX' => 0,
	    'SQL::Translator' => 0
    },
    EXE_FILES => ['scripts/taskpipe', 'scripts/taskpipe-xtask'],
    TEST_REQUIRES => {
        'Test::More' => 0,
	'Data::Dumper' => 0,
	'File::Spec' => 0,
        'File::Basename' => 0,
	'Moose' => 0,
        'MooseX::ConfigCascade' => 0,
        'Proc::ProcessTable' => 0,
        'Try::Tiny' => 0,
	'Time::HiRes' => 0
    },
    ABSTRACT_FROM     => 'lib/TaskPipe.pm',
    AUTHOR            => 'Tom Gracey <tomgracey@gmail.com>',
    LICENSE           => 'gpl_3'
);


sub write_threaded_global_conf{

    my $root_dir = File::Spec->catdir(
        dirname(abs_path(__FILE__)),
        't',
        'threaded'
    );

    my $global_conf_dir = File::Spec->catdir(
        $root_dir,
        'global',
        'conf'
    );

    my $global_base_conf_path = File::Spec->catdir(
        $global_conf_dir,
        'global_base.yml'
    );

    my $global_base_fh;
    open ($global_base_fh,"<",$global_base_conf_path) or die "Could not open $global_base_conf_path: $!";

    my $global_conf_text = '';
    while (my $line = <$global_base_fh>){
        $global_conf_text.=$line."\n";
    }

    $global_conf_text.="\nTaskPipe::SchemaManager::Settings_Global:
  database: $dbinfo{global_db}
  host: $dbinfo{hostname}
  method: dbi
  port: $dbinfo{port}
  module: TaskPipe::GlobalSchema
  password: $dbinfo{password}
  table_prefix: ''
  type: mysql
  username: $dbinfo{username}

";

    close $global_base_fh;
    
    my $global_conf_path = File::Spec->catdir(
        $global_conf_dir,
        "global.yml"
    );

    my $global_conf_fh;
    open ($global_conf_fh,">",$global_conf_path) or die "Could not open $global_conf_path: $!";
    print $global_conf_fh $global_conf_text;
    close $global_conf_fh;

}



sub write_threaded_project_conf{

    my $root_dir = File::Spec->catdir(
        dirname(abs_path(__FILE__)),
        't',
        'threaded'
    );

    my $project_conf_dir = File::Spec->catdir(
        $root_dir,
        'projects',
        'test',
        'conf'
    );

    my $project_base_conf_path = File::Spec->catdir(
        $project_conf_dir,
        'project_base.yml'
    );

    my $project_base_fh;
    open ($project_base_fh,"<",$project_base_conf_path) or die "Could not open $project_base_conf_path: $!";

    my $project_conf_text = '';
    while (my $line = <$project_base_fh>){
        $project_conf_text.=$line."\n";
    }
    
    $project_conf_text.="\nTaskPipe::SchemaManager::Settings_Project:
  database: $dbinfo{project_db}
  host: $dbinfo{hostname}
  method: dbi
  module: TaskPipe::Schema
  port: $dbinfo{port}
  password: $dbinfo{password}
  table_prefix: tp_
  type: mysql
  username: $dbinfo{username}

";

    close $project_base_fh;
    
    my $project_conf_path = File::Spec->catdir(
        $project_conf_dir,
        "project.yml"
    );

    my $project_conf_fh;
    open ($project_conf_fh,">",$project_conf_path) or die "Could not open $project_conf_path: $!";
    print $project_conf_fh $project_conf_text;
    close $project_conf_fh;

}


