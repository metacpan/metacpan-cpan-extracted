#!perl
############ STANDARD Perl::Critic TEST - DO NOT EDIT ##################
use strict;
use File::Spec::Functions;
use FindBin;
use Test::More;
unless (require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for complaining compliance"
    );
}
Test::Perl::Critic->import( -profile => catfile( $FindBin::Bin, "anyperlperlcriticrc" ) );
Test::Perl::Critic::all_critic_ok();
