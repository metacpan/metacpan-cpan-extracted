package Miril::App::Cmd::Command::server;

use strict;
use warnings;
use autodie;

use Miril::App::Cmd -command;

use Class::Autouse;
Class::Autouse->autouse('Plack::Loader');
Class::Autouse->autouse('Miril::App::PSGI');

sub opt_spec
{
	return (
		[ 'host|h=s',    "host address to bind to",    { default => 'localhost' }   ],
		[ 'port|p=i',    "port to listen on",          { default => 8080 }          ],
		[ 'dir|d=s',     "miril base dir",             { default => 'example' }     ],
		[ 'site|s=s',    "website",                    { default => 'example.com' } ],
	);
}

sub execute 
{
	my ($self, $opt, $args) = @_;

	print "Miril accepting connections at http://" . $opt->host . ":" . $opt->port ."\n";

	Plack::Loader->auto(
		host => $opt->host,
		port => $opt->port,
	)->run(
		Miril::App::PSGI->app($opt->dir, $opt->site)
	);
}

1;

