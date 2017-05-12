#!/usr/bin/perl

use strict;
use warnings;
use inc::Module::Install 0.77;

use ExtUtils::Liblist;
use Config;
use File::Spec::Functions;

my @inc = map { split } @Config{qw(usrinc incpath locincpth)};

sub has_lib { can_cc() and scalar grep { length } ExtUtils::Liblist->ext("-l$_[0]") }

sub has_bdb {
	can_use("BerkeleyDB")
		or
	can_cc() && (
		exists $ENV{BERKELEYDB_LIB}
			or
		-e '/usr/local/BerkeleyDB'
			or
		has_lib("db") or has_lib("libdb")
	);
}

sub has_uuid {
	return 0 unless can_cc();

	foreach my $inc ( @inc ) {
		return 1 if -e catfile($inc, qw(uuid uuid.h));
	}

	return 0;
}

sub has_dbd {
	can_use("DBD::SQLite")
		or
	can_use("DBD::Pg"),
		or
	scalar(can_use("DBD::mysql")),
}

sub has_couchdb {
	scalar can_use("AnyEvent::CouchDB"),
}

name 'Task-KiokuDB';
all_from 'lib/Task/KiokuDB.pm';

requires 'Test::use::ok';
requires 'KiokuDB';

feature 'CLI',
  -default       => 1,
  'KiokuDB::Cmd' => 0;

# feature 'Files backend',
#   -default                  => 1,
#   'KiokuDB::Backend::Files' => 0;

feature 'XS acceleration for JSON',
  -default   => scalar(can_cc()),
  'JSON::XS' => 0;

feature 'YAML::XS for dump/load & MooseX::YAML',
  -default   => scalar(can_cc()),
  'YAML::XS' => 0;

feature 'MooseX::Storage integration',
  -default          => 0,
  'MooseX::Storage' => 0;

feature 'Berkeley DB backend',
  -default                => has_bdb(),
  'BerkeleyDB::Manager'   => 0,
  'KiokuDB::Backend::BDB' => 0;

feature 'DBI backend',
  -default                => has_dbd(),
  'KiokuDB::Backend::DBI' => 0;

feature 'CouchDB backend',
  -default                    => has_couchdb(),
  'KiokuDB::Backend::CouchDB' => 0;

feature 'libuuid based UUIDs',
  -default              => scalar( can_cc() && has_uuid() ),
  'Data::UUID::LibUUID' => 0;

feature 'generic user object',
	-default       => 0,
	'KiokuX::User' => 0;

feature 'generic model wrapper',
	-default        => 0,
	'KiokuX::Model' => 0;

feature 'Catalyst integration',
	-default                   => 0,
	'Catalyst::Model::KiokuDB' => 0;

auto_install;
WriteAll;
