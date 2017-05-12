
# $Id: Makefile.PL,v 1.27 2009-07-04 14:54:22 Martin Exp $

use inc::Module::Install;

all_from('lib/RDF/Simple.pm');
author('Martin Thurn mthurn@cpan.org');
version(0.415);
perl_version(5.005);

requires('Class::MakeMethods');
requires('File::Slurp');
test_requires('IO::CaptureOutput');
requires('LWP::UserAgent');
requires('Regexp::Common');
test_requires('Test::File');
test_requires('Test::Simple');
requires('URI::Escape');
requires('XML::SAX');
recommends('XML::SAX::Expat');  # Need this for Solaris and Linux?

WriteAll;

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

__END__
