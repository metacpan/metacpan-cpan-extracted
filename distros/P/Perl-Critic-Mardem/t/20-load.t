#!perl

use utf8;

use 5.010;

use strict;
use warnings;

use Test::More;

plan 'tests' => 10;

BEGIN {
    my $error_txt = "Bail out!\n";

    use_ok( 'Perl::Critic::Mardem' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Mardem::Util' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitBlockComplexity' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitConditionComplexity' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitFileSize' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitLargeBlock' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitLargeFile' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitLargeSub' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt' )
        || print $error_txt;
}

diag(
    "\n",
    "\n --",
    "\nPerl $], $^X",
    "\nTesting Perl::Critic::Mardem $Perl::Critic::Mardem::VERSION",
    "\nTesting Perl::Critic::Mardem::Utily $Perl::Critic::Mardem::Util::VERSION",
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitBlockComplexity $Perl::Critic::Policy::Mardem::ProhibitBlockComplexity::VERSION",
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitConditionComplexity $Perl::Critic::Policy::Mardem::ProhibitConditionComplexity::VERSION",
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitFileSize $Perl::Critic::Policy::Mardem::ProhibitFileSize::VERSION",
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitLargeBlock $Perl::Critic::Policy::Mardem::ProhibitLargeBlock::VERSION",
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitLargeFile $Perl::Critic::Policy::Mardem::ProhibitLargeFile::VERSION",
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitLargeSub $Perl::Critic::Policy::Mardem::ProhibitLargeSub::VERSION",
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub $Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub::VERSION",
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt $Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt::VERSION",
    "\n --",
    "\n",
    "\n",
);

done_testing();

__END__

#-----------------------------------------------------------------------------
