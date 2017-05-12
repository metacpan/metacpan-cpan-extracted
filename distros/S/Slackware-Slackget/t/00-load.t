use Test::More tests => 25;

BEGIN {
use_ok( 'Slackware::Slackget' );
use_ok( 'Slackware::Slackget::Base' );
use_ok( 'Slackware::Slackget::Config' );
use_ok( 'Slackware::Slackget::Date' );
use_ok( 'Slackware::Slackget::File' );
use_ok( 'Slackware::Slackget::List' );
use_ok( 'Slackware::Slackget::Local' );
use_ok( 'Slackware::Slackget::Media' );
use_ok( 'Slackware::Slackget::MediaList' );
use_ok( 'Slackware::Slackget::Network' );
use_ok( 'Slackware::Slackget::Network::Auth' );
use_ok( 'Slackware::Slackget::Network::Connection' );
use_ok( 'Slackware::Slackget::Network::Connection::FTP' );
use_ok( 'Slackware::Slackget::Network::Connection::HTTP' );
use_ok( 'Slackware::Slackget::Network::Message' );
use_ok( 'Slackware::Slackget::Package' );
use_ok( 'Slackware::Slackget::PackageList' );
use_ok( 'Slackware::Slackget::PkgTools' );
use_ok( 'Slackware::Slackget::Search' );
use_ok( 'Slackware::Slackget::SpecialFileContainer' );
use_ok( 'Slackware::Slackget::SpecialFileContainerList' );
use_ok( 'Slackware::Slackget::SpecialFiles::CHECKSUMS' );
use_ok( 'Slackware::Slackget::SpecialFiles::FILELIST' );
use_ok( 'Slackware::Slackget::SpecialFiles::PACKAGES' );
use_ok( 'Slackware::Slackget::Status' );
}

diag( "Testing Slackware::Slackget $Slackware::Slackget::VERSION, Perl $], $^X" );
