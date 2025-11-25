#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon # Test2::V0 etc.
  qw/$silent $verbose $debug run_perlscript/;

use Spreadsheet::Edit;

use Spreadsheet::Edit::IO qw/let2cx cx2let convert_spreadsheet
                             filepath_from_spec sheetname_from_spec/;

# November 2025: The code to find libreoffice has been rewritten and no
# longer uses File::Find (which has internal problems on some platforms).
#
# Enable debug tracing but only show it if there is a problem
my $path;
{ my @warnings;
  eval{
    local $SIG{__WARN__} = $debug ? 'DEFAULT' : sub { push @warnings, @_; };
    local $ENV{SPREADSHEET_EDIT_FINDDEBUG} = 1;
    $path = Spreadsheet::Edit::IO::openlibreoffice_path();
  };
  my $caught = $@;
  if ($caught || any { /se of uninitialized/} @warnings) {
    diag @warnings;
    diag "EXCEPTION: $caught" if $caught;
    fail("File::Find trouble") unless $debug && !$caught;
  }
}
is(!!Spreadsheet::Edit::IO::can_cvt_spreadsheets(), !!$path);
if (!$path) {
  diag "LibreOffice not found\n";
} else {
  diag "openlibreoffice_path=$path",
       " version=",u(Spreadsheet::Edit::IO::_openlibre_features->{raw_version});
}

ok(1, "Basic loading & import; find LibreOffice");

done_testing;

