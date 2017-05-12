#!/usr/bin/perl

# Test Perl 5.10 features

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 0.47 tests => 10;
use Perl::MinimumVersion;

# Perl 5.10 operators
SCOPE: {
	my $p = Perl::MinimumVersion->new(\'$foo = 1 // 2');
	is( $p->minimum_version, '5.010', '->minimum_version ok' );
	my $m = $p->minimum_syntax_reason;
	is( $m->element->content, '//', 'Matched correct element' );
	is( $m->rule, '_perl_5010_operators', 'Matched correct rule' );
}

# Perl 5.10 magic variables
SCOPE: {
	my $p = Perl::MinimumVersion->new(\'%+ = ();');
	is( $p->minimum_version, '5.010', '->minimum_version ok' );
	my $m = $p->minimum_syntax_reason;
	is( $m->element->content, '%+', 'Matched correct element' );
	is( $m->rule, '_perl_5010_magic', 'Matched correct rule' );
}

SCOPE: {
	my $p = Perl::MinimumVersion->new(\'$+{foo} = 1;');
	is( $p->minimum_version, '5.010', '->minimum_version ok' );
	my $m = $p->minimum_syntax_reason;
	is( $m->element->content, '$+', 'Matched correct element' );
	is( $m->element->symbol,  '%+', 'Symbol matches expected' );
	is( $m->rule, '_perl_5010_magic', 'Matched correct rule' );
}
