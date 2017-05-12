package Miril::App::Cmd::Command::publish;

use strict;
use warnings;
use autodie;

use Miril::App::Cmd -command;

use Class::Autouse;
Class::Autouse->autouse('Miril');

sub opt_spec
{
	return (
		[ 'dir|d=s',     "miril base dir",             { default => 'example' }     ],
		[ 'site|s=s',    "website",                    { default => 'example.com' } ],
	);
}

sub execute 
{
	my ($self, $opt, $args) = @_;
	
	my $miril = Miril->new($opt->dir, $opt->site);
	$miril->publish;
}

1;
