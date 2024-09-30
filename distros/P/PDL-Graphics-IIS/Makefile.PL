use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use Config;

os_unsupported if $^O eq 'MSWin32';

my @pack = (["iis.pd", qw(IIS PDL::Graphics::IIS)]);
my %hash = pdlpp_stdargs(@pack);
$hash{LIBS} = ['-lm'];
$hash{OBJECT} .= ' pdliisdisp$(OBJ_EXT)';
$hash{INC} .= qq{ -DO_NONBLOCK="$Config{o_nonblock}"}
  if ($Config{o_nonblock}//'O_NONBLOCK') ne 'O_NONBLOCK';

undef &MY::postamble; # suppress warning
*MY::postamble = sub {
  pdlpp_postamble(@pack);
};

WriteMakefile(
  %hash,
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.010',
  CONFIGURE_REQUIRES => {
    'PDL' => '2.093',
    'ExtUtils::MakeMaker' => '7.26', # os_unsupported
  },
  BUILD_REQUIRES => {
    'PDL' => '2.093',
  },
  PREREQ_PM => {
    'PDL' => '2.093',
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>'https://github.com/PDLPorters/PDL-Graphics-IIS/issues'},
      repository  => {
        url => 'git://github.com/PDLPorters/PDL-Graphics-IIS.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/PDL-Graphics-IIS',
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
    no_index => { file => ['Doc/scantree.pl'] },
  },
);
