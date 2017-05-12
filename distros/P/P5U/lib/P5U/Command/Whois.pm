package P5U::Command::Whois;

use 5.010;
use strict;
use utf8;
use P5U-command;

BEGIN {
	$P5U::Command::Whois::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::Whois::VERSION   = '0.100';
};

use constant {
	abstract    => q[whois for CPAN authors],
	usage_desc  => q[%c whois CPANID],
};

sub command_names {qw{ whois w }}

sub opt_spec
{
	return (
		[ 'verbose|v' => 'show extra information' ],
	);
}

sub execute
{
	require P5U::Lib::Whois;
	my ($self, $opt, $args) = @_;
	
	while (@$args)
	{
		print P5U::Lib::Whois
			-> new(cpanid => shift @$args)
			-> report($opt->{verbose});
		print "\n" if @$args;
	}
}

1;
