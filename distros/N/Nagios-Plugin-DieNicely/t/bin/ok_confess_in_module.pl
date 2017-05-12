#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/OK/;

my $obj = MyModule->new();

package MyModule;
use Carp;

sub new{
	confess "confessed and Nagios can detect me";
}

1;
