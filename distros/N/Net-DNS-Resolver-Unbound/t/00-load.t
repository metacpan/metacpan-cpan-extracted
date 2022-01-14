#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 2;

my @module = qw(
		Net::DNS
		Net::DNS::Resolver::Unbound
		Net::DNS::Resolver::libunbound
		ExtUtils::MakeMaker
		File::Find
		File::Spec
		IO::File
		Test::More
		);


my @diag = "\nThese tests were run using:";
foreach my $module (@module) {
	eval "require $module";		## no critic
	for ( eval { $module->VERSION || () } ) {
		s/^(\d+\.\d)$/${1}0/;
		push @diag, sprintf "%-30s  %s", $module, $_;
	}
}
diag join "\n\t", @diag;


ok( eval { Net::DNS::Resolver::libunbound->VERSION }, 'XS component Unbound.xs loaded' )
		|| BAIL_OUT("Unable to access Unbound library");

use_ok('Net::DNS::Resolver::Unbound');

exit;


END {
	eval { Net::DNS::Resolver::libunbound::croak_memory_wrap() }	# paper over crack in Devel::Cover
}


__END__

