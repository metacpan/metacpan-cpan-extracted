#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/WARNING/;

my $obj = MyModule->new();

package MyModule;

sub new{
	die "died and Nagios can detect me";
}

1;
