package Mojolicious::Command::migration;

BEGIN {
	$ENV{MOJO_MIGRATION_TMP  } ||= 'tmp';
	$ENV{MOJO_MIGRATION_SHARE} ||= 'share';
};

use common::sense;
use Mojo::Base 'Mojolicious::Command';
use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use File::Basename;
use File::Path qw(make_path remove_tree);
use Storable qw/nstore retrieve/;
use SQL::Translator;
use SQL::Translator::Diff;
no warnings;
use Data::Dumper;

our $VERSION = 0.15;

has description => 'MySQL migration tool';
has usage       => sub { shift->extract_usage };
has config      => sub { shift->app->config->{db}->{mysql} };
has paths       => sub {+{
	deploy_status => "$ENV{MOJO_MIGRATION_TMP}/.deploy_status",
	source_deploy => "$ENV{MOJO_MIGRATION_SHARE}/migrations/_source/deploy",
	db_deploy     => "$ENV{MOJO_MIGRATION_SHARE}/migrations/MySQL/deploy",
	db_upgrade    => "$ENV{MOJO_MIGRATION_SHARE}/migrations/MySQL/upgrade",
	db_downgrade  => "$ENV{MOJO_MIGRATION_SHARE}/migrations/MySQL/downgrade",
}};
has deployed => sub {
	my $self = shift;
	return {} unless -e $self->paths->{deploy_status};
	return retrieve $self->paths->{deploy_status};
};
has db => sub {
	my $self = shift;
	return $self->app->db if $self->app->can('db');
	DBI->connect('dbi:mysql:'.$self->config->{datasource}->{database},
		$self->config->{user    },
		$self->config->{password},
	);
};
has params => sub {{}};

sub run {
	my $self = shift;
	my @args = @_;

	die $self->usage unless my $action = shift @args;
	die $self->usage unless $action ~~ [qw/status prepare install upgrade downgrade/];

	GetOptionsFromArray \@args,
		'to-version=s' => sub { $self->params->{'to-version'} = $_[1] },
		'force'        => sub { $self->params->{force       } = 1     },
	;

	$self->$action;

	$self->params({});
}

sub install {
	my $self  = shift;
	my $paths = $self->paths;

	my $last_version = $self->get_last_version;

	unless ($last_version) {
		say "Migration dont initialized. Please run <migration prepare>";

		return;
	}

	say "Schema version: $last_version";

	if (my $version = $self->deployed->{version}) {
		say "Deployed database is $version";
		say "A versioned schema has already been deployed, try upgrade instead.";

		return;
	}

	if (!$self->params->{force} && !$self->db_is_empty) {
		say "Database is not empty. Installing is dangerous. Try --force to skip installation";

		return;
	}

	$last_version = $self->params->{'to-version'} if $self->params->{'to-version'};

	unless (-s "$paths->{source_deploy}/$last_version/001_auto.yml") {
		say "Schema $last_version not exists";

		return;
	}

	if ($self->db_is_empty) {
		say "Deploy database to $last_version";

		my $source = $self->deployment_statements(
			type    => 'install',
			version => $last_version,
		);

		for my $line(@$source) {
			eval { $self->db->do($line) };

			if ($@) {
				die "Deploy failed: $@";
			}
		}

		$self->deployed->{version} = $last_version;
		$self->save_deployed;

		return;
	} else {
		say "Force deploy to $last_version";
		$self->deployed->{version} = $last_version;
		$self->save_deployed;

		return;
	}
}

sub upgrade {
	my $self  = shift;
	my $paths = $self->paths;

	my $to_version = $self->get_last_version;

	unless ($to_version) {
		say "Migration dont initialized. Please run <migration prepare>";

		return;
	}

	say "Schema version: $to_version";

	unless ($self->deployed->{version}) {
		say "Database is not installed. Please run <migration install>";

		return;
	}

	if ($self->deployed->{version} == $to_version) {
		say "Database is already up-to-date.";

		return;
	}

	if ($self->params->{'to-version'} && $self->params->{'to-version'} > $to_version) {
		say "Schema not exists.";

		return;
	}

	$to_version = $self->params->{'to-version'} if $self->params->{'to-version'};

	if ($self->deployed->{version} == $to_version) {
		say "Database is already deployed to $to_version";

		return;
	}

	say "Database version: ".$self->deployed->{version};

	if ($self->params->{force}) {
		say "Force upgrade to $to_version";
		$self->deployed->{version} = $to_version;
		$self->save_deployed;
		return;
	}

	my $current = $self->deployed->{version};
	for my $upgrade ($self->deployed->{version} + 1 .. $to_version) {
		say "Upgrade to $upgrade";
		say "+++++++++ "."$paths->{db_upgrade}/$current-$upgrade/*";
		my @files = sort {$a cmp $b} glob("$paths->{db_upgrade}/$current-$upgrade/*");
		say "Upgrade is empty" unless @files;

		for my $file (@files) {
			next unless -s $file;
			say "Exec file: $file";

			my $source = $self->deployment_statements(
				filename => $file,
			);

			for my $line(@$source) {
				next unless $line;

				say "Exec SQL: $line";

				eval { $self->db->do($line) };

				if ($@) {
					die "SQL failed: $@";
				}
			}
		}

		$self->deployed->{version} = $upgrade;
		$self->save_deployed;
		++$current;
	}
}

sub downgrade {
	my $self  = shift;
	my $paths = $self->paths;

	my $last_version = $self->get_last_version;

	unless ($last_version) {
		say "Migration dont initialized. Please run <migration prepare>";

		return;
	}

	say "Schema version: $last_version";

	unless ($self->deployed->{version}) {
		say "Database is not installed. Please run <migration install>";

		return;
	}

	if ($self->params->{'to-version'} && $self->params->{'to-version'} > $last_version) {
		say "Schema not exists.";

		return;
	}

	my $to_version = $self->params->{'to-version'} || $self->deployed->{version} - 1;

	unless ($to_version > 0) {
		say "Nothing to downgrade.";

		return;
	}

	if ($self->deployed->{version} == $to_version) {
		say "Database is already deployed to $to_version";

		return;
	}

	say "Database version: ".$self->deployed->{version};

	if ($self->params->{force}) {
		say "Force downgrade to $to_version";
		$self->deployed->{version} = $to_version;
		$self->save_deployed;
		return;
	}

	my $current = $self->deployed->{version};
	for my $downgrade ($self->deployed->{version} - 1 .. $to_version) {
		say "Downgrade to $downgrade";
		my @files = sort {$a cmp $b} glob("$paths->{db_downgrade}/$current-$downgrade/*");
		say "Downgrade is empty" unless @files;

		for my $file (@files) {
			next unless -s $file;
			say "Exec file: $file";

			my $source = $self->deployment_statements(
				filename    => $file,
			);

			for my $line(@$source) {
				next unless $line;

				say "Exec SQL: $line";

				eval { $self->db->do($line) };

				if ($@) {
					die "SQL failed: $@";
				}
			}
		}

		$self->deployed->{version} = $downgrade;
		$self->save_deployed;
	}
}

sub status {
	my $self = shift;

	my $last_version = $self->get_last_version;

	unless ($last_version) {
		say "Migration dont initialized. Please run <migration prepare>";

		return;
	}
	say "Schema version: $last_version";

	if (my $version = $self->deployed->{version}) {
		say "Deployed database is $version";
	} else {
		say "Database is not deployed";
	}

}

sub save_deployed {
	my $self = shift;
	nstore $self->deployed, $self->paths->{deploy_status};
}

sub prepare {
	my $self  = shift;
	my $paths = $self->paths;

	my $last_version = $self->get_last_version;
	my $new_version  = $last_version ? $last_version + 1 : 1;

	if ($new_version == 1) {
		say "Initialization";
	} else {
		say "Schema version: $last_version";
	}

	if (my $version = $self->deployed->{version}) {
		say "Deployed database is $version";
	}

	if ($self->db_is_empty) {
		say "Nothing to prepare. Database is empty.";

		return;
	}

	my $deploy = $self->get_schema(to => 'MySQL');
	my $error = $self->save_migration(
		path => "$paths->{db_deploy}/$new_version/001_auto.sql",
		data => join '', @{ $deploy->{data} },
	);
	die "Cant create MySQL deploy: $error" if $error;

	my $deploy = $self->get_schema(to => 'YAML');
	my $error = $self->save_migration(
		path => "$paths->{source_deploy}/$new_version/001_auto.yml",
		data => join '', @{ $deploy->{data} },
	);
	die "Cant create YML deploy: $error" if $error;

	$deploy->{schema}->name("$paths->{source_deploy}/$new_version/001_auto.yml");

	if ($new_version > 1) {
		my $target_schema = $deploy->{schema};
		my $source_schema = $self->get_schema(
			from     => 'YAML',
			filename => "$paths->{source_deploy}/$last_version/001_auto.yml",
		)->{schema};

		for ($source_schema->get_tables) {
			$_->{options} = [grep {!$_->{'AUTO_INCREMENT'}} @{ $_->{options} }];
		}
		for ($target_schema->get_tables) {
			$_->{options} = [grep {!$_->{'AUTO_INCREMENT'}} @{ $_->{options} }];
		}
		my $diff = SQL::Translator::Diff->new({
			output_db               => 'MySQL',
			source_schema           => $source_schema,
			target_schema           => $target_schema,
			ignore_index_names      => 1,
			ignore_constraint_names => 1,
			caseopt                 => 1
		})->compute_differences;

		my $h = {};
		for my $table(keys %{ $diff->{table_diff_hash} || {} }) {
			for my $field (@{$diff->{table_diff_hash}->{$table}->{fields_to_create}}) {
				$h->{$table}->{$field->name} = [grep {$_->order == $field->{order} - 1} $field->table->get_fields]->[0]->{name};
			}
		}
		$diff = $diff->produce_diff_sql;

		if (%$h) {
			my @res = split "\n\n", $diff;
			for my $s (@res) {
				my ($t, $a) = $s =~ /ALTER TABLE ([^\s]+) ([^;]+)/;

				for ($a =~ /ADD COLUMN ([^\s]+) /g) {
					$s =~ s/ADD COLUMN $_ (.*)([\,\;])/ADD COLUMN $_ $1 AFTER $h->{$t}->{$_}$2/g;
				}
			}

			$diff = join "\n\n", @res;
		}

		if ($diff =~ /No differences/) {
			say "Nothing to upgrade. Exit";

			remove_tree "$paths->{source_deploy}/$new_version";
			remove_tree "$paths->{db_deploy}/$new_version";

			return;
		} else {
			my $error = $self->save_migration(
				path => "$paths->{db_upgrade}/$last_version-$new_version/001_auto.sql",
				data => $diff,
			);
			die "Cant create MySQL upgrade: $error" if $error;

			my $diff = SQL::Translator::Diff->new({
				output_db               => 'MySQL',
				source_schema           => $target_schema,
				target_schema           => $source_schema,
				ignore_index_names      => 1,
				ignore_constraint_names => 1,
				caseopt                 => 1,
			})->compute_differences->produce_diff_sql;

			my $error = $self->save_migration(
				path => "$paths->{db_downgrade}/$new_version-$last_version/001_auto.sql",
				data => $diff,
			);
			die "Cant create MySQL downgrade: $error" if $error;
		}
	}

	say "New schema version: $new_version";
	say "Deploy to $new_version";
	$self->deployed->{version} = $new_version;
	$self->save_deployed;

	say "Done";
}

sub get_last_version {
	my $self = shift;

	my $path = $self->paths->{source_deploy};

	my $last_version;
	if (-e $path) {
		opendir my $dh, $path or die "can't opendir $path: $!";
		($last_version) = sort {$b <=> $a} readdir $dh;
		closedir $dh;
	}

	return $last_version;
}

sub db_is_empty { @{ shift->db->selectall_arrayref('show tables', { Slice => {} }) } ? 0 : 1 }

sub save_migration {
	my $self = shift;
	my $p    = {@_};

	my $dir = dirname $p->{path};
	make_path $dir unless -d $dir;

	open my $fh, '>', $p->{path} or return $!;
	print $fh $p->{data};
	close $fh;

	return;
}

sub get_schema {
	my $self = shift;
	my $p    = {@_};

	my $translator = SQL::Translator->new(
		debug => 1,
		no_comments => $p->{no_comments} || 0,
		$p->{filename}
		?
			()
		:
			(
				parser_args     => {
					dsn         => 'dbi:mysql:'.$self->config->{datasource}->{database},
					db_user     => $self->config->{user    },
					db_password => $self->config->{password},
				},
			)
	);
	$translator->parser($p->{from} || 'DBI');

	my @output = $translator->translate(
		producer => $p->{to},
		$p->{filename}
		?
			(filename => $p->{filename})
		:
			()
	) or die "Error: " . $translator->error;

	my $schema = $translator->schema;
	if ($p->{filename}) {
		$schema->name($p->{filename});
	}

	return {
		schema => $schema,
		data   => \@output,
	};
}

sub deployment_statements {
	my $self  = shift;
	my $p     = {@_};
	my $paths = $self->paths;

	if ($p->{type} eq 'install') {
		return $self->get_schema(
			from        => 'YAML',
			to          => 'MySQL',
			filename    => "$paths->{source_deploy}/$p->{version}/001_auto.yml",
			no_comments => 1,
		)->{data};
	} else {
		my $filename = $p->{filename} || "$paths->{db_$p->{type}}/$p->{from}-$p->{to}/001_auto.sql";
		if(-f $filename) {
			my $file;
			open $file, "<$filename" or die "Can't open $filename ($!)";
			my @rows = <$file>;
			close $file;

			return [
				grep {
					s/\n//g;
					/(^--|^BEGIN|^COMMIT|^\s*$)/ ? 0 : 1
				}
				split
					/\s*--.*\n|;\n/,
					join '', @rows
			];
		}
	}

	return [];
}

1;

=pod

=encoding utf8
 
=head1 NAME
 
Mojolicious::Command::migration — MySQL migration tool for Mojolicious

=head1 VERSION

version 0.15

=head1 SYNOPSIS
 
  Usage: APPLICATION migration [COMMAND] [OPTIONS]
 
    mojo migration prepare
  
  Commands:
    status     : Current database and schema version
    install    : Install a version to the database.
    prepare    : Makes deployment files for your database
    upgrade    : Upgrade the database.
    downgrade  : Downgrade the database.
 
=head1 DESCRIPTION
 
L<Mojolicious::Command::migration> MySQL migration tool.
 

=head1 USAGE

L<Mojolicious::Command::migration> uses app->db for mysql connection and following configuration:

  {
    'user'       => 'USER',
    'password'   => 'PASSWORD',
    'datasource' => { 'database' => 'DB_NAME'},
  }

from

  $ app->config->{db}->{mysql}

All deploy files saves to relative directory 'share/'. You can change it with 'MOJO_MIGRATION_SHARE' environment.
Current project state saves to 'tmp/.deploy_status' file. You can change directory with 'MOJO_MIGRATION_TMP' environment.

Note: we create directories automatically

=head1 COMMANDS
 
=head2 status
 
  $ app migration status
  Schema version: 21
  Deployed database is 20

Returns the state of the deployed database (if it is deployed) and the state of the current schema version. Sends this as a string to STDOUT

=head2 prepare

Makes deployment files for the current schema. If deployment files exist, will fail unless you "overwrite_migrations".

  # have changes
  $ app migration prepare
  Schema version: 21
  New version is 22
  Deploy to 22
  
  # no changes
  $ app migration prepare
  Schema version: 21
  Nothing to upgrade. Exit

=head2 install

Installs either the current schema version (if already prepared) or the target version specified via any to_version flags.

If you try to install to a database that has already been installed (not empty), you'll get an error. Use flag force to set current database to schema version without changes database.

  # last
  $ app migration install
  Schema version: 21
  Deploy database to 21
  
  # target version
  $ app migration install --to-version 10
  Schema version: 21
  Deploy database to 10

  # force install
  $ app migration install --force
  Schema version: 21
  Force deploy to 21

=head2 upgrade


Use flag --force to set current database to schema version without changes database.

  # last
  $ app migration upgrade
  Schema version: 21
  Database version: 20
  Upgrade to 21
  
  # target version
  $ app migration upgrade --to-version 10
  Schema version: 21
  Database version: 8
  Upgrade to 10

  # force upgrade
  $ app migration upgrade --force
  Schema version: 21
  Database version: 8
  Force upgrade to 21

=head2 downgrade


Use flag --force to set current database to schema version without changes database.

  # last
  $ app migration downgrade
  Schema version: 21
  Database version: 20
  Downgrade to 21
  
  # target version
  $ app migration downgrade --to-version 10
  Schema version: 21
  Database version: 8
  Downgrade to 10

  # force downgrade
  $ app migration downgrade --force
  Schema version: 21
  Database version: 8
  Force downgrade to 21

=head1 Custom upgrade and downgrade

You can customize upgrade and downgrade by adding additional SQL scripts to path of action. All scripts will be executed in alphabetical order.

  # share/migration/MySQL/upgrade/10-11/001_auto.sql is automatic
  # share/migration/MySQL/upgrade/10-11/002_some_script.sql is additional sctipt
  $ app migration upgrade
  Schema version: 11
  Database version: 10
  Upgrade to 11
  Exec file: share/migrations/MySQL/upgrade/10-11/001_auto.sql
  Exec file: share/migrations/MySQL/upgrade/10-11/002_some_script.sql

=head1 SOURCE REPOSITORY

L<https://github.com/likhatskiy/Mojolicious-Command-migration>

=head1 AUTHOR

Alexey Likhatskiy, <likhatskiy@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 "Alexey Likhatskiy"

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
