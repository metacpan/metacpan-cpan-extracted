
use Test2::V0;
use Test2::Tools::Exception qw/lives/;

ok(lives {
    require Perl::Critic::TooMuchCode;  
    require Perl::Critic::Policy::TooMuchCode::ProhibitLargeTryBlock;
    require Perl::Critic::Policy::TooMuchCode::ProhibitUnnecessaryUTF8Pragma;
    require Perl::Critic::Policy::TooMuchCode::ProhibitUnusedConstant;
    require Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport;
});

done_testing;
