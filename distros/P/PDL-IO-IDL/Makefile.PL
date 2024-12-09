use ExtUtils::MakeMaker;
use strict;
use warnings;
use PDL::Core::Dev;

my $package_name = "PDL::IO::IDL";
(my $repo = $package_name) =~ s#::#-#g;
$repo = "PDLPorters/$repo";
WriteMakefile(
  NAME => $package_name,
  VERSION_FROM => 'IDL.pm',
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'PDL' => '2.094',
  },
  PREREQ_PM => {
    'PDL' => '2.094',
  },
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
