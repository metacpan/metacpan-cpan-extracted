use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

# create GENERATED subdir with *.pm files during 'make dist' (to make metacpan.org happy)
my $preop = '$(PERLRUNINST) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)';

my $package_name = 'PDL::Fit';
(my $repo = $package_name) =~ s#::#-#g;
$repo = "PDLPorters/$repo";
WriteMakefile(
  NAME => $package_name,
  VERSION_FROM => 'Fit.pm',
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  LICENSE=> "perl",
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'PDL' => '2.094',
  },
  PREREQ_PM => {
    'PDL' => '2.094',
  },
  PM => { map {($_ => '$(INST_LIBDIR)/Fit/'.$_)} <[LP]*.pm> },
  dist => { COMPRESS => 'gzip', SUFFIX => 'gz', PREOP => $preop },
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
