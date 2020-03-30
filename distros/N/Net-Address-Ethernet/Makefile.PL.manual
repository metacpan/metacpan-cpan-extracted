
use lib '.';

use inc::Module::Install;

all_from('lib/Net/Address/Ethernet.pm');

requires( perl => 5.004 );
recommends('Data::Dumper');
requires('Net::Domain');
requires('Net::Ifconfig::Wrapper');
requires('Regexp::Common');
requires('Sys::Hostname');
test_requires('Test::More');
recommends('Test::Pod');
recommends('Test::Pod::Coverage');

use Env;
if ($ENV{MTHURN_PERL_DEV})
  {
  warn "DDD This is author's development environment\n";
  use_ptar();
  } # if

WriteAll;

if ($ENV{MTHURN_PERL_DEV})
  {
  my $sFnameMakefile = q{Makefile};
  eval "use File::Slurp";
  my $s = read_file($sFnameMakefile);
  if ($s !~ s/(DIRFILESEP\s*=\s*).+$/$1\//m)
    {
    warn " EEE did not find DIRFILESEP in Makefile\n";
    } # if
  if ($s !~ s/(pm_to_blib\()\{\{\@ARGV\}\}/$1 . '{@ARGV}'/e)
    {
    warn " EEE did not find pm_to_blib@ARGV in Makefile\n";
    } # if
  if ($s !~ s/(from_to\s+=>\s+)\{\{\@ARGV\}\}/$1 . '{@ARGV}'/e)
    {
    warn " EEE did not find from_to@ARGV in Makefile\n";
    } # if
  write_file($sFnameMakefile, $s);
  } # if

__END__

