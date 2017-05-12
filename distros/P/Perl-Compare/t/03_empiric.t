#!/usr/bin/perl

# Empiric testing for the Perl::Compare module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use Perl::Compare    ();
use File::Find::Rule ();
use constant FFR => 'File::Find::Rule';





#####################################################################
# Prepare

# Build the file filter
my $Rule = FFR->or(
	FFR->name('.svn')->directory->prune->discard,
	FFR->new,
	);
$Rule->name('*.pm');
isa_ok( $Rule, 'File::Find::Rule' );

my $from = catfile( 't', 'data', '03_empiric', 'from' );
my $to   = catfile( 't', 'data', '03_empiric', 'to'   );
ok( -d $from, 'from directory exists' );
ok( -d $to,   'to directory exists'   );





#####################################################################
# Tests

# Create the test object
my $Compare = Perl::Compare->new(
	from   => $from,
	layer  => 1,
	filter => $Rule,
	);
isa_ok( $Compare, 'Perl::Compare' );

# Do the normal compare
my $result = $Compare->compare( $to );
is( ref($result), 'HASH', '->compare returns a hash' );
is_deeply( $result, {
	'added.pm'   => 'added',
	'removed.pm' => 'removed',
	'changed.pm' => 'changed',
}, '->compare returns the expected result' );

# Now repeat in report mode
my $report = $Compare->compare_report( $to );
is( $report, <<END_REPORT, '->compare_report returns as expected' );
+ added.pm
! changed.pm
- removed.pm
END_REPORT
