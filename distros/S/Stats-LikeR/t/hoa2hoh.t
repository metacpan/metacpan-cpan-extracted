#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

#--------
# basic conversion
#--------
my %hoa = (
	id => [ qw(a b c) ],
	'x'  => [ 1, 2, 3 ],
	'y'  => [ 4, 5, 6 ],
);
my $hoh = hoa2hoh(\%hoa, 'id');
is(ref $hoh,          'HASH', 'returns a hashref');
is(scalar keys %$hoh, 3,      'three row names');
is($hoh->{a}{x},      1,      'a.x');
is($hoh->{b}{x},      2,      'b.x');
is($hoh->{c}{y},      6,      'c.y');
is($hoh->{c}{id},     'c',    'key column retained in row');

#--------
# inner values are independent copies (newSVsv), not aliases
#--------
$hoa{x}[0] = 999;
is($hoh->{a}{x}, 1, 'inner cell is a copy, not aliased to input');

#--------
# empty (but present) key column -> empty hoh
#--------
my %empty = ( id => [], x => [] );
my $eh = hoa2hoh(\%empty, 'id');
is(scalar keys %$eh, 0, 'empty columns yield empty hoh');

#--------
# die conditions
#--------
my %dup = ( id => [ qw(a a b) ], x => [ 1, 2, 3 ] );
dies_ok { hoa2hoh(\%dup, 'id') } 'dies on duplicate row name';

dies_ok { hoa2hoh(\%hoa, 'nope') } 'dies on missing key column';
dies_ok { hoa2hoh(\%hoa, undef)  } 'dies on undef key argument';
dies_ok { hoa2hoh([ 1, 2, 3 ], 'id') } 'dies on non-hashref first arg';

my %not_aref = ( id => [ qw(a b) ], x => 42 );
dies_ok { hoa2hoh(\%not_aref, 'id') } 'dies when a column is not an arrayref';

my %undef_key = ( id => [ 'a', undef, 'c' ], x => [ 1, 2, 3 ] );
dies_ok { hoa2hoh(\%undef_key, 'id') } 'dies on explicit undef key value';

my %ragged = ( id => [ 'a', 'b' ], x => [ 1, 2, 3 ] );
dies_ok { hoa2hoh(\%ragged, 'id') } 'dies when key column is shorter than widest';

#--------
# no memory leaks (success path + both croak paths)
#--------
no_leaks_ok {
	eval {
		hoa2hoh(\%hoa, 'id')
	}
} 'hoa2hoh(): no leaks on success' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval {
		hoa2hoh(\%dup, 'id')
	}
} 'hoa2hoh(): no leaks on duplicate croak' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval {
		hoa2hoh(\%undef_key, 'id')
	}
} 'hoa2hoh(): no leaks on undef-key croak' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval {
		hoa2hoh(\%hoa, 'nope')
	}
} 'hoa2hoh(): no leaks on missing-column croak' unless $INC{'Devel/Cover.pm'};

done_testing();
