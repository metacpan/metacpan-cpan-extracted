use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
require ExtUtils::Depends;
require File::Spec::Functions;

my $package_name = 'PDL::IO::HDF';
(my $repo = $package_name) =~ s#::#-#g;
$repo = "PDLPorters/$repo";
WriteMakefile(
  NAME => $package_name,
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  LICENSE=> "perl",
  VERSION_FROM => 'HDF.pm',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'PDL' => '2.094',
    'ExtUtils::Depends' => '0.402',
    'Alien::HDF4' => 0,
  },
  PREREQ_PM => {
    'PDL' => '2.094',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
  PM => { 'HDF.pm' => '$(INST_LIBDIR)/HDF.pm' },
  dist => { COMPRESS => 'gzip', SUFFIX => 'gz' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>"https://github.com/$repo/issues"},
      repository  => {
        url => "git://github.com/$repo.git",
        type => 'git',
        web => "https://github.com/$repo",
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
);

sub MY::postamble {
  my $oneliner = PDL::Core::Dev::_oneliner(qq{exit if \$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(shift); }});
  qq|\ninstall :: pure_install\n\t$oneliner \$(NAME)\n|;
}
