#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/OK/;

my $obj = MyModule->new();

package MyModule;

sub new{
	die "died and Nagios can detect me";
}

1;
