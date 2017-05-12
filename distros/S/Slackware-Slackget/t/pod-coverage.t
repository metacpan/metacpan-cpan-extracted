#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan tests => 22;
#all_pod_coverage_ok();

pod_coverage_ok( "Slackware::Slackget" );
pod_coverage_ok( "Slackware::Slackget::Base" );
pod_coverage_ok( "Slackware::Slackget::Config" );
pod_coverage_ok( "Slackware::Slackget::Date" );
pod_coverage_ok( "Slackware::Slackget::File" );
pod_coverage_ok( "Slackware::Slackget::List" );
#pod_coverage_ok( "Slackware::Slackget::Local" ); # Pending deletion....
pod_coverage_ok( "Slackware::Slackget::Network" );
pod_coverage_ok( "Slackware::Slackget::Network::Auth" );
pod_coverage_ok( "Slackware::Slackget::Network::Connection" );
pod_coverage_ok( "Slackware::Slackget::Network::Connection::FTP" );
pod_coverage_ok( "Slackware::Slackget::Network::Connection::HTTP" );
pod_coverage_ok( "Slackware::Slackget::Network::Message" );
pod_coverage_ok( "Slackware::Slackget::Package" );
pod_coverage_ok( "Slackware::Slackget::PackageList" );
pod_coverage_ok( "Slackware::Slackget::PkgTools" );
pod_coverage_ok( "Slackware::Slackget::Search" );
pod_coverage_ok( "Slackware::Slackget::SpecialFileContainer" );
pod_coverage_ok( "Slackware::Slackget::SpecialFileContainerList" );
pod_coverage_ok( "Slackware::Slackget::SpecialFiles::CHECKSUMS" );
pod_coverage_ok( "Slackware::Slackget::SpecialFiles::FILELIST" );
pod_coverage_ok( "Slackware::Slackget::SpecialFiles::PACKAGES" );
pod_coverage_ok( "Slackware::Slackget::Status" );