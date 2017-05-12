#!/usr/bin/perl

use strict;
use warnings;

use DBIx::Class::Schema::Loader;
use Module::Runtime;

use Path::Class qw(file dir);

use FindBin;
use lib "$FindBin::Bin/../lib";

my $approot = "$FindBin::Bin/..";
my $applib = "$approot/lib";
my $ddl = "$approot/sql/crudmodes.sql";

my $data_dir = dir($approot,'crudmodes_data');
$data_dir->mkpath(1) unless (-d $data_dir);
my $sqlt = $data_dir->file('crudmodes.db')->stringify;

my $model_class = 'Rapi::Demo::CrudModes::Model::DB';
Module::Runtime::require_module($model_class);
my $schema_class = $model_class->config->{schema_class};

my $cmd = "sqlite3 $sqlt < $ddl";
print "$cmd\n";
qx{$cmd};
die "\n  --> Non-zero (" . ($? >> 8) . ') exit!! ' if ($?);

print "\nDumping schema '$schema_class' to '$applib'";


DBIx::Class::Schema::Loader::make_schema_at(
  $schema_class, 
  {
    debug => 1,
    dump_directory => $applib,
    use_moose	=> 1, generate_pod => 0,
    components => ["InflateColumn::DateTime"],
  },
  [ 
    "dbi:SQLite:$sqlt",'','',
    { loader_class => 'RapidApp::Util::MetaKeys::Loader' }
  ]
);

print "\n";

