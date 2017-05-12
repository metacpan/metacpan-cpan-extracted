use Test::Pod::Coverage tests=>3;
pod_coverage_ok( "Money::ChangeMaker",               "Money::ChangeMaker is covered" );
pod_coverage_ok( "Money::ChangeMaker::Denomination", "Money::ChangeMaker::Denomination is covered" );
pod_coverage_ok( "Money::ChangeMaker::Presets",      "Money::ChangeMaker::Presets is covered" );
