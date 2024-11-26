use strict;
use warnings;
use ExtUtils::MakeMaker;

# Extra build target to build the doc database
sub MY::postamble {
   <<"EOPS";

pdl2.pod : pdl2
\t\$(PERLRUN) -MPod::Select -e "podselect('pdl2');" > pdl2.pod

EOPS
}

my @podpms = map { $_.".pod", '$(INST_LIBDIR)/' . $_ .".pod"} qw/pdl2/;
WriteMakefile(
  NAME => 'PDL::Perldl2',
  VERSION_FROM => 'Script.pm',
  AUTHOR => "Chris Marshall <chm at cpan dot org>",
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.016',
  EXE_FILES => [ 'pdl2' ],
  PM => { 'Script.pm' => '$(INST_LIBDIR)/Perldl2/Script.pm', @podpms },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.14',
  },
  PREREQ_PM => {
    'PDL' => '2.095',
    'Moose' => 0,
    'namespace::clean' => 0,
    'Devel::REPL' => 0,
    'Devel::REPL::Plugin' => 0,
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>'https://github.com/PDLPorters/PDL-Perldl2/issues'},
      repository  => {
        url => 'git://github.com/PDLPorters/PDL-Perldl2.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/PDL-Perldl2',
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
);
