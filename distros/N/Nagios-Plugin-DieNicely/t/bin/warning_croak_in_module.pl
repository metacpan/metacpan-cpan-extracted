#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/WARNING/;

my $obj = MyModule->new();

package MyModule;

use Carp;

sub new{
	croak "croaked and Nagios can detect me";
}

1;
