# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;
use Test::More qw(no_plan);
use Palm::PDB;

BEGIN { use_ok('Palm::DiabetesPilot' ); }

my $pdb = new Palm::PDB;
ok( defined $pdb );

ok( defined $pdb->Load( "DiabetesPilotData.pdb" ) );

for( @{$pdb->{records}} ) {
	ok( defined $_ );
	printf "%04d-%02d-%02d %02d:%02d %-17s ",
		$_->{'year'}, $_->{'month'}, $_->{'day'}, $_->{'hour'}, $_->{'minute'},
		$pdb->{appinfo}{categories}[$_->{category}]{name};
	print $_->{'type'}, "\n";
}

undef $pdb;
ok(1);

exit 0;
