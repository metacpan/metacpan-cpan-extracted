
use warnings;
use strict;

my $VERSION = 1.29;

use inc::Module::Install;

version(0.419);
all_from('lib/RDF/Simple.pm');
author('Martin Thurn mthurn@cpan.org');
perl_version(5.005);

requires('Class::MethodMaker');
requires('File::Slurp');
test_requires('IO::CaptureOutput');
requires('LWP::UserAgent');
requires('Regexp::Common');
test_requires('Test::File');
test_requires('Test::Simple');
requires('URI::Escape');
requires('XML::SAX');
recommends('XML::SAX::Expat');  # Need this for Solaris and Linux?

sub MY::postamble
  {
  my $ret = '';
  $ret .= <<'PART0';
coverage :
	- mkdir cover_db
	- cover -delete
	- $(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover
	firefox cover_db/coverage.html
PART0
  return $ret;
  } # MY::postamble

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
  if ($s !~ s/(pm_to_blib\()\{\{\@ARGV}}/$1 . '{@ARGV}'/e)
    {
    warn " EEE did not find pm_to_blib@ARGV in Makefile\n";
    } # if
  if ($s !~ s/(from_to\s+=>\s+)\{\{\@ARGV}}/$1 . '{@ARGV}'/e)
    {
    warn " EEE did not find from_to@ARGV in Makefile\n";
    } # if
  write_file($sFnameMakefile, $s);
  } # if

__END__
