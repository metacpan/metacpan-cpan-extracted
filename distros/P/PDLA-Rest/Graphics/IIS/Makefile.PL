use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

if ($^O =~ /win32/i) {
  write_dummy_make(unsupported('PDLA::Graphics::IIS','win32'));
  return;
}

my @pack = (["iis.pd", qw(IIS PDLA::Graphics::IIS)]);
my %hash = pdlpp_stdargs(@pack);
$hash{LIBS} = ['-lm'];

undef &MY::postamble; # suppress warning
*MY::postamble = sub {
	pdlpp_postamble(@pack);
};

WriteMakefile(%hash);
