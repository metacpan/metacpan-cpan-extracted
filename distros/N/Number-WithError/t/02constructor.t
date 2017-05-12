#!/usr/bin/perl -w
# Tests for Number::WithError
use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			'lib',
			);
	}
}

use Test::More tests => 612;


#####################################################################

use Number::WithError qw/:all/;

my @test_args = (
	{
		name => 'integer',
		args => [qw(5)],
		obj  => { num => '5', errors => [] },
	},
	{
		name => 'decimal',
		args => [qw(0.1)],
		obj  => { num => '0.1', errors => [] },
	},
	{
		name => 'scientific',
		args => [qw(0.001e-15)],
		obj  => { num => '0.001e-15', errors => [] },
	},
	{
		name => 'scientific with error',
		args => [qw(155e2 12)],
		obj  => { num => '155e2', errors => [12] },
	},
	{
		name => 'integer with 3 errors',
		args => [qw(5 0 3 1.2)],
		obj  => { num => '5', errors => [0, 3, 1.2] },
	},
	{
		name => 'decimal with 4 errors',
		args => [qw(0.1 0.1 0.1 0.1 0.1)],
		obj  => { num => '0.1', errors => [0.1, 0.1, 0.1, 0.1] },
	},
	{
		name => 'scientific with 3 errors incl unbalanced',
		args => [qw(3.4e5 2), [0.3, 0.5], 2],
		obj  => { num => '3.4e5', errors => [2, [0.3,0.5], 2] },
	},
	{
		name => 'decimal with undef error and 1 error',
		args => [qw(.4), undef, 0.1],
		obj  => { num => '0.4', errors => [undef, 0.1] },
	},
	{
		name => 'string with 1 error',
		args => ['2.0e-3 +/- 0.1e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3] },
	},
	{
		name => 'string with 1 error (2)',
		args => ['2.0e-3+/-0.1e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3] },
	},
	{
		name => 'string with 1 error (3)',
		args => ['2.0e-3+ /-0.1e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3] },
	},
	{
		name => 'string with 1 error (4)',
		args => ['2.0e-3+/- 0.1e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3] },
	},
	{
		name => 'string with 2 errors',
		args => ['2.0e-3 +/-0.1e-3+/--0.3e+1'],
		obj  => { num => '2.0e-3', errors => [0.1e-3, 0.3e+1] },
	},
	{
		name => 'string with 2 errors incl unbalanced',
		args => ['2.0e-3 +/- 0.1e-3 +0.15e-3 -0.01e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3, [0.15e-3, 0.01e-3]]},
	},
	{
		name => 'string with 2 errors incl unbalanced (2)',
		args => ['2.0e-3 +/- 0.1e-3 -0.15e-3+0.01e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3, [0.01e-3, 0.15e-3]]},
	},
	{
		name => 'string with 2 errors incl unbalanced (3)',
		args => ['2.0e-3+/-0.1e-3+0.15e-3-0.01e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3, [0.15e-3, 0.01e-3]]},
	},
);

# simple cases
ok( not defined Number::WithError->new() );
ok( not defined Number::WithError->new(undef) );
ok( not defined Number::WithError->new_big() );
ok( not defined Number::WithError->new_big(undef) );
ok( not defined witherror() );
ok( not defined witherror(undef) );
ok( not defined witherror_big() );
ok( not defined witherror_big(undef) );

sub test_construction_method {
    my $name = shift;
    my $is_big = shift;
    my $constructor = shift;
    my $cloner = shift;
    my $test_args = shift;

    foreach (@$test_args) {
        print "Testing $name with $_->{name}.\n";
    	my $o = $_->{obj};
	    my $args = $_->{args};
    	my $name = $_->{name};

    	my $num = $constructor->(@$args);

	    isa_ok($num, 'Number::WithError');
	    isa_ok($num->{num}, 'Math::BigFloat') if $is_big;
    	ok(abs($num->{num}-$o->{num})<1e-24, $name);
    	ok(@{$num->{errors}} == @{$o->{errors}}, $name. '; number of errors');
    	foreach (0..$#{$o->{errors}}) {
	    	my $err = $o->{errors}[$_];
    		if (ref($err) eq 'ARRAY') {
			    if ($is_big) {
			        my $errno = $_;
                    isa_ok($num->{errors}[$errno][$_], 'Math::BigFloat') for 0..$#{$num->{errors}[$errno]};
                }
	    		ok(abs($err->[0]-$num->{errors}[$_][0])<1e-24, $name.'; error '.$_.'-1');
    			ok(abs($err->[1]-$num->{errors}[$_][1])<1e-24, $name.'; error '.$_.'-2');
	    	}
    		else {
	    		if (not defined $err) {
		    		ok(not(defined $num->{errors}[$_])||abs($num->{errors}[$_])<1e-24, $name.'; error '.$_);
    			}
	    		else {
				    isa_ok($num->{errors}[$_], 'Math::BigFloat') if $is_big;
		    		ok(abs($err-$num->{errors}[$_])<1e-24, $name.'; error '.$_);
    			}
		    }
	    }
    	# test cloning:
	    my $copy = $cloner->($num);
    	is($copy, $num, $name . '; cloning');
	    ok( overload::StrVal($copy) ne overload::StrVal($num), '; ref not equal after cloning');
    	ok( ''.$copy->{errors} ne ''.$num->{errors}, '; {error} ref not equal after cloning');
	    foreach (0..$#{$num->{errors}}) {
		    next if not ref($num->{errors}[$_]) eq 'ARRAY';
    		ok($num->{errors}[$_] ne $copy->{errors}[$_], $name . "; Error no. $_, reference not equal after cloning");
	    }
    }

}

# test new()
test_construction_method(
    "->new()",
    0, # not a big variant
    sub {Number::WithError->new(@_)},  # const
    sub {my $self = shift; $self->new(@_)}, # clone
    \@test_args
);

# test witherror()
test_construction_method(
    "witherror()",
    0, # not a big variant
    sub {witherror(@_)},  # const
    sub {my $self = shift; $self->new(@_);}, # clone
    \@test_args
);

# test new_big()
test_construction_method(
    "->new_big()",
    1, # is big
    sub {Number::WithError->new_big(@_)},  # const
    sub {my $self = shift; $self->new_big(@_);}, # clone
    \@test_args
);

# test witherror_big()
test_construction_method(
    "witherror_big()",
    1, # is big
    sub {witherror_big(@_)},  # const
    sub {my $self = shift; $self->new_big(@_);}, # clone
    \@test_args
);






1;
