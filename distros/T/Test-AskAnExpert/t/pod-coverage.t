use Test::More;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 5;
pod_coverage_ok( "Test::AskAnExpert" );
pod_coverage_ok( "Test::AskAnExpert::Question" );
pod_coverage_ok( "Test::AskAnExpert::Interface" );
$trustparents = { coverage_class => "Pod::Coverage::CountParents" };
pod_coverage_ok( "Test::AskAnExpert::Interface::File" , $trustparents);
pod_coverage_ok( "Test::AskAnExpert::Interface::Mock" , $trustparents);
