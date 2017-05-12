
package Rex::WebUI;

use strict;

use Mojo::Base "Mojolicious";

use Mojo::Log;
use Mojolicious::Plugin::Database;

use Rex::WebUI::Model::LogBook;
use Rex::WebUI::Model::RexInterface;

use Cwd qw(abs_path);

use DBIx::Foo qw(:all);
use Data::Dumper;

use File::Basename 'dirname';
use File::Copy;
use File::Spec::Functions 'catdir';

our $VERSION = '0.01';

# This method will run once at server start
sub startup {
	my $self = shift;

    # Switch to installable home directory
    $self->home->parse(catdir(dirname(__FILE__), 'WebUI'));
    $self->static->paths->[0] = $self->home->rel_dir('public');
    $self->renderer->paths->[0] = $self->home->rel_dir('templates');

	if (my $cfg = $self->_locate_config_file) {
		$self->plugin('Config', file => "$cfg");
	} else {
		# config should always be found because we ship a default config file, but best to check
		die "Config file not found" unless $cfg;
	}

	if (my $secret = $self->config->{secret_passphrase}) {
		$self->secret($secret);
	}

	my $db_config = $self->config->{db_config} || [ dsn => 'dbi:SQLite:dbname=webui.db', username => '', password => '' ];

	$self->plugin('database', {
		@$db_config,
		helper		=> 'dbh',
	});

	$self->check_db_config($db_config);

	$self->helper(rex => sub { state $rex = Rex::WebUI::Model::RexInterface->new });
	$self->helper(logbook => sub { state $rex = Rex::WebUI::Model::LogBook->new($self->dbh) });

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->get("/")->to("dashboard#index");
	$r->get("/dashboard")->to("dashboard#index");
	$r->get("/notification_message")->to("dashboard#notification_message");

	$r->get("/project/:id")->to("project#index");
	$r->get("/project/:id/task/view/:name")->to("task#view");
	$r->post("/project/:id/task/run/:name")->to("task#run");
	$r->websocket("/project/:id/task/tail_ws/:jobid")->to("task#tail_ws")->name('tail_ws');
}

sub check_db_config {
	my ($self, $db_config) = @_;

	my $check = $self->selectrow_array("select userid from users order by userid limit 1");

	if ($check) {
		warn "Database OK: $check";
		return 1;
	}
	elsif ($db_config->[1] =~ /^dbi:SQLite/) {
		return 	$self->_init_sqllite_db;
	}
	else {
		die "Database is not initialised - check your setup";
	}
}

sub _init_sqllite_db {
	my $self = shift;

	# This is a very simple SQLite database template to allow us to ship the app via cpan / github and have a ready to go data store.
	# Optionally the app can be configured to use MySQL etc.
	# Hopefully we can maintain compatibility by using standard sql syntax.
	# TODO: Create setup scripts for other db types

	warn "Setting up SQLite Database";

	$self->dbh_do("create table users (userid INTEGER PRIMARY KEY AUTOINCREMENT, username varchar(20))");
	$self->dbh_do("insert into users (userid, username) values (1, 'admin')");

	$self->dbh_do("create table status (statusid INTEGER PRIMARY KEY AUTOINCREMENT, status varchar(20))");
	$self->dbh_do("insert into status (statusid, status) values (0, 'Starting')");
	$self->dbh_do("insert into status (statusid, status) values (1, 'Running')");
	$self->dbh_do("insert into status (statusid, status) values (2, 'Completed')");
	$self->dbh_do("insert into status (statusid, status) values (3, 'Died')");

	$self->dbh_do("create table logbook (jobid INTEGER PRIMARY KEY AUTOINCREMENT, userid int not null, task_name varchar(100), server varchar(100), statusid int, pid int)");
	return 1;
}

sub _locate_config_file
{
	my $self = shift;

	# check optional locations for config file, inc current directory
	my @cfg = ("/etc/rex/webui.conf", "/usr/local/etc/rex/webui.conf", abs_path("webui.conf"));

	my $cfg;
	for my $file (@cfg) {
		if(-f $file) {
			return $file;
			last;
		}
	}

	# finally if no config file is found, copy the template and the SampleRexfile from the mojo home dir
	foreach my $file (qw(webui.conf SampleRexfile)) {
		copy(abs_path($self->home->rel_file($file)), abs_path($file)) or die "No config file found, and unable to copy $file to current directory";
	}

	return abs_path("webui.conf");
}

1;


__END__

=head1 NAME

Rex::WebUI - Simple web frontend for rex (Remote Execution), using Mojolicious.  Easily deploy or manage servers via a web interface.

=head1 SYNOPSIS

  rex-webui daemon

  # or if you prefer using hypnotoad
  hypnotoad bin/rex-webui

and point your browser at http://localhost:3000

=head1 DESCRIPTION

This is an installable web application that provides a front end to Rex projects (see http://rexify.org)

Almost unlimited functionality is available via Rex, perfect for deploying servers and managing clusters, or anything you can automate via ssh.

Build multiple Rexfiles (one per project) and register them in webui.conf

The web interface allows to you browse and run tasks, and records a history of running and completed tasks.

A small SQLite db is used to store the history.


=head1 EXAMPLE CONFIG

  {
     name 				=> 'Rex Web Delopyment Console',
     secret_passphrase 	=> 'rex-webui',
     projects 				=> [
        {
           name        => 'SampleRexfile',
           rexfile     => "SampleRexfile",
           description => "This is a sample Project. With a few tasks.",
        },
     ],
     db_config 			=> [ dsn => 'dbi:SQLite:dbname=webui.db', username => '', password => '' ],
  };

=head1 SampleRexfile

 # Sample Rexfile

  desc "Show Unix version";
  task uname => sub {
      my $uname = run "uname -a";

      Rex::Logger::info("uname: $uname");

      return $uname;
  };

  desc "Show Uptime";
  task uptime => sub {
      my $uptime = run "uptime";

      Rex::Logger::info("uptime: $uptime");

      return $uptime;
  };

=cut
