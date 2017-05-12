#!/usr/bin/perl

use Nagios::Plugin::DieNicely;

eval {
   my $obj = MyModule->new();
};

print "OK";
exit 0;

package MyModule;

sub new{
	die "died and Nagios can detect me";
}

1;
