#!/usr/bin/perl

##
## Tests for Pangloss::Term::Status
##

use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More 'no_plan';

BEGIN { use_ok("Pangloss::Term::Status") }

my $stat = new Pangloss::Term::Status;
ok( $stat, 'new' ) || die "cannot proceed\n";

isa_ok( $stat->status_codes, 'HASH', 'status_codes' );

is( $stat->code(1), $stat, 'code(set)' );
is( $stat->code, 1,        'code(get)' );

is( $stat->notes(1), $stat, 'notes(set)' );
is( $stat->notes, 1,        'notes(get)' );

is( $stat->date(1), $stat, 'date(set)' );
is( $stat->date, 1,        'date(get)' );

is( $stat->pending, $stat, 'pending' );
ok( $stat->is_pending,     'is_pending' );

is( $stat->approved, $stat, 'approved' );
ok( $stat->is_approved,     'is_approved' );

is( $stat->rejected, $stat, 'rejected' );
ok( $stat->is_rejected,     'is_rejected' );

is( $stat->deprecated, $stat, 'deprecated' );
ok( $stat->is_deprecated,     'is_deprecated' );

my $stat2 = $stat->new;
if (ok( $stat2->copy( $stat ), 'copy' )) {
    ok( $stat2->is_deprecated, 'copy code' );
    ok( $stat2->notes,         'copy notes' );
    ok( $stat2->date,          'copy date' );
}

ok( $stat->clone(), 'clone' );

TODO: {
    local $TODO = 'implement validation!';
    try { is( $stat->validate, $stat, 'validate' ); }
    catch Error with { my $e=shift; fail("$e"); };

    {
	my $e;
	try { Pangloss::Term::Status->new->validate; }
	catch Error with { $e = shift; };

	if (isa_ok( $e, 'Pangloss::Term::Error', 'validate error' )) {
	    ; # ...
	}
    }
}

