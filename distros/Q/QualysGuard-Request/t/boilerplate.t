#!perl -T

use strict;
use warnings;
use Test::More tests => 28;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

TODO: {
  local $TODO = "Need to replace the boilerplate text";

  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );

  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

  module_boilerplate_ok('lib/QualysGuard/Request.pm');
  module_boilerplate_ok('lib/QualysGuard/Response.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/AssetDataReport.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/AssetDomainList.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/AssetGroupList.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/AssetHostList.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/AssetRangeInfo.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/AssetSearchReport.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/GenericReturn.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/HostInfo.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/IScannerList.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/MapReport.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/MapReport2.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/MapReportList.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/RemediationTickets.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/ReportTemplateList.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/ScanOptions.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/ScanReport.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/ScanReportList.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/ScanRunningList.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/ScanTargetHistory.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/ScheduledScans.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/TicketDelete.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/TicketEdit.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/TicketList.pm');
  module_boilerplate_ok('lib/QualysGuard/Response/TicketListDeleted.pm');
}

