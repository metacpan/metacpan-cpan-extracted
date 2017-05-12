#!/usr/bin/perl

use strict;

BEGIN {
	$^W = 1;
}

use Test::More;
use Test::Differences;

use PPI;

BEGIN {
	if ( $PPI::VERSION =~ /_/ ) {
		plan skip_all => "Need released version of PPI. You have $PPI::VERSION";
		exit 0;
	}
}

use PPIx::EditorTools::RenameVariable;



my @to_camel_tests = (

	# test expected ucfirst
	[qw(abc abc 0)],
	[qw(abc Abc 1)],
	[qw(Abc Abc 0)],
	[qw(Abc Abc 1)],
	[qw(abc_def abcDef 0)],
	[qw(abc_def AbcDef 1)],
	[qw(a_b_c_D_E aBCDE 0)],
	[qw(a_b_c_D_E ABCDE 1)],
	[qw(A_b_c_D_E ABCDE 1)],
	[qw(A_b_c_D_E ABCDE 0)],
	[qw(_this_is_a_var _thisIsAVar 0)],
	[qw(_this_is_a_var _ThisIsAVar 1)],
);

my @from_camel_tests = (

	# test expected ucfirst
	[qw(abc abc 0)],
	[qw(abc Abc 1)],
	[qw(Abc abc 0)],
	[qw(Abc Abc 1)],
	[qw(abcDef abc_def 0)],
	[qw(abcDef Abc_Def 1)],
	[qw(AbcDef abc_def 0)],
	[qw(AbcDef Abc_Def 1)],
	[qw(aBCDE a_b_c_d_e 0)],
	[qw(aBCDE A_B_C_D_E 1)],
	[qw(ABCDE a_b_c_d_e 0)],
	[qw(ABCDE A_B_C_D_E 1)],
	[qw(_abc _abc 0)],
	[qw(_abc _Abc 1)],
	[qw(_thisIsAVar _this_is_a_var 0)],
	[qw(_thisIsAVar _This_Is_A_Var 1)],
	[qw(_ThisIsAVar _this_is_a_var 0)],
	[qw(_ThisIsAVar _This_Is_A_Var 1)],
);


plan tests => @to_camel_tests * 3 + @from_camel_tests * 3;

foreach my $test (@to_camel_tests) {
	my ( $src, $exp, $ucfirst ) = @$test;
	is( PPIx::EditorTools::RenameVariable::_to_camel_case( $src, $ucfirst ), $exp,
		"to-camel-case '$src' with ucfirst=$ucfirst"
	);
	$_ = '$' . $_ for ( $src, $exp );
	is( PPIx::EditorTools::RenameVariable::_to_camel_case( $src, $ucfirst ), $exp,
		"to-camel-case '$src' with ucfirst=$ucfirst"
	);
	s/^\$/\$#/ for ( $src, $exp );
	is( PPIx::EditorTools::RenameVariable::_to_camel_case( $src, $ucfirst ), $exp,
		"to-camel-case '$src' with ucfirst=$ucfirst"
	);
}

foreach my $test (@from_camel_tests) {
	my ( $src, $exp, $ucfirst ) = @$test;
	is( PPIx::EditorTools::RenameVariable::_from_camel_case( $src, $ucfirst ), $exp,
		"from-camel-case '$src' with ucfirst=$ucfirst"
	);
	$_ = '$' . $_ for ( $src, $exp );
	is( PPIx::EditorTools::RenameVariable::_from_camel_case( $src, $ucfirst ), $exp,
		"from-camel-case '$src' with ucfirst=$ucfirst"
	);
	s/^\$/\$#/ for ( $src, $exp );
	is( PPIx::EditorTools::RenameVariable::_from_camel_case( $src, $ucfirst ), $exp,
		"from-camel-case '$src' with ucfirst=$ucfirst"
	);
}

