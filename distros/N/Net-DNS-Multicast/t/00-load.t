#!/usr/bin/perl
#

use strict;
use warnings;
use IO::File;
use Test::More;

my @module = qw(Net::DNS::Multicast Net::DNS);

my %metadata;
my $handle = IO::File->new('MYMETA.json') || IO::File->new('META.json');
if ($handle) {
	my $json = join '', (<$handle>);
	for ($json) {
		s/\s:\s/ => /g;					# Perl? en voilà!
		my $hashref = eval $_;	## no critic
		%metadata = %$hashref;
	}
	close $handle;
}

my %prerequisite;
foreach ( values %{$metadata{prereqs}} ) {			# build, runtime, etc.
	foreach ( values %$_ ) {				# requires
		$prerequisite{$_}++ for keys %$_;
	}
	delete @prerequisite{@module};
	delete $prerequisite{perl};
}

my @diag;
foreach my $module ( @module, sort keys %prerequisite ) {
	eval "require $module";		## no critic
	for ( eval { $module->VERSION || () } ) {
		s/^(\d+\.\d)$/${1}0/;
		push @diag, sprintf "%-25s  %s", $module, $_;
	}
}
diag join "\n\t", "\nThese tests were run using:", @diag;


plan tests => 1 + scalar(@Net::DNS::EXPORT);


use_ok('Net::DNS::Multicast');

#
# Check that Net::DNS symbol table was imported correctly
foreach my $sym (@Net::DNS::EXPORT) {
	ok( defined &{$sym}, "$sym is imported" );
}


exit;

__END__

