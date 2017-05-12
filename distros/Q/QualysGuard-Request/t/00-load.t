#!perl -T

use Test::More tests => 26;

BEGIN {
	use_ok( 'QualysGuard::Request' );
	use_ok( 'QualysGuard::Response' );
	use_ok( 'QualysGuard::Response::AssetDataReport' );
	use_ok( 'QualysGuard::Response::AssetDomainList' );
	use_ok( 'QualysGuard::Response::AssetGroupList' );
	use_ok( 'QualysGuard::Response::AssetHostList' );
	use_ok( 'QualysGuard::Response::AssetRangeInfo' );
	use_ok( 'QualysGuard::Response::AssetSearchReport' );
	use_ok( 'QualysGuard::Response::GenericReturn' );
	use_ok( 'QualysGuard::Response::HostInfo' );
	use_ok( 'QualysGuard::Response::IScannerList' );
	use_ok( 'QualysGuard::Response::MapReport' );
	use_ok( 'QualysGuard::Response::MapReport2' );
	use_ok( 'QualysGuard::Response::MapReportList' );
	use_ok( 'QualysGuard::Response::RemediationTickets' );
	use_ok( 'QualysGuard::Response::ReportTemplateList' );
	use_ok( 'QualysGuard::Response::ScanOptions' );
	use_ok( 'QualysGuard::Response::ScanReport' );
	use_ok( 'QualysGuard::Response::ScanReportList' );
	use_ok( 'QualysGuard::Response::ScanRunningList' );
	use_ok( 'QualysGuard::Response::ScanTargetHistory' );
	use_ok( 'QualysGuard::Response::ScheduledScans' );
	use_ok( 'QualysGuard::Response::TicketDelete' );
	use_ok( 'QualysGuard::Response::TicketEdit' );
	use_ok( 'QualysGuard::Response::TicketList' );
	use_ok( 'QualysGuard::Response::TicketListDeleted' );
}

diag( "Testing QualysGuard::Request $QualysGuard::Request::VERSION, Perl $], $^X" );


