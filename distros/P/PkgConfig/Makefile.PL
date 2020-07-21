use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker 6.56;
use Getopt::Long;
use Config;

### Makefile.PL commandline params
# e.g. Makefile.PL --script=ppkg-config --script=pkg-config
Getopt::Long::GetOptions("script=s" => \my @scripts);

if (@scripts == 0 && defined $ENV{PERL_PKG_CONFIG_SCRIPTS})
{
  @scripts = ($ENV{PERL_PKG_CONFIG_SCRIPTS});
}

if (@scripts) {
  @scripts = map { split /,/ } @scripts;
  if (grep /^none$/, @scripts) {
    @scripts = ();
  } else {
    @scripts = map { "script/$_" } @scripts;
    -f $_ or die "non-existing '$_'" for (@scripts);
  }
}
else {
  @scripts = ( 'script/ppkg-config', $^O ne 'MSWin32' ? 'script/pkg-config.pl' : () );
  if($^O eq 'MSWin32' && $Config{myuname} =~ /strawberry-perl/) {
    if(eval q{ require 5.020 }) {
      push @scripts, 'script/pkg-config';

      print "\n\n";
      print "!!! Note that script will be installed as pkg-config  !!!\n";
      print "!!! in addition to ppkg-config since you are using    !!!\n";
      print "!!! Strawberry Perl 5.20 or better.  This is probably !!!\n";
      print "!!! What you want                                     !!!\n";
      print "\n\n";

      if($Config{myuname} =~ /strawberry-perl 5\.20\.0\.1/)
      {
        print "\n\n";
        print "!!! Some of the .pc files that come with your version !!!\n";
        print "!!! of Strawberry Perl may not work correctly with    !!!\n";
        print "!!! this version of PkgConfig.  You should consider   !!!\n";
        print "!!! patching them.  See README.win32 for details.     !!!\n";
        print "\n\n";
      }

    } else {
      print "\n\n";
      print "!!! You may want to consider installing the script as !!!\n";
      print "!!! pkg-config as it can then be used by              !!!\n";
      print "!!! ExtUtils::PkgConfig (This is how it works in      !!!\n";
      print "!!! Strawberry 5.20 and better in fact).  Please see  !!!\n";
      print "!!! details in README.win32 if you are interested.    !!!\n";
      print "\n\n";
    }
  }
}

WriteMakefile(
    NAME                => 'PkgConfig',
    AUTHOR              => q{M. Nunberg <mnunberg@haskalah.org>},
    VERSION_FROM        => 'lib/PkgConfig.pm',
    ABSTRACT_FROM       => 'lib/PkgConfig.pm',
    LICENSE             => 'perl',
    MIN_PERL_VERSION    => '5.006000',
    PL_FILES            => {},
    EXE_FILES           => \@scripts,
    PREREQ_PM => {
        'Test::More' => '0.94',
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.56',
    },
    PM => {
      "lib/PkgConfig.pm" => "\$(INST_LIB)/PkgConfig.pm",
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web  => 'https://github.com/PerlPkgConfig/perl-PkgConfig/issues',
            },
            homepage => 'https://metacpan.org/pod/PkgConfig',
            repository => {
                type => 'git',
                url  => 'https://github.com/PerlPkgConfig/perl-PkgConfig.git',
                web  => 'https://github.com/PerlPkgConfig/perl-PkgConfig',
            },
            x_IRC => "irc://irc.perl.org/#native",
        },
        provides => {
            PkgConfig => {
                file    => "lib/PkgConfig.pm",
                version => do { require "./lib/PkgConfig.pm"; $PkgConfig::VERSION; },
            },
        },
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PkgConfig-*' },
);

sub MY::test_via_harness
{
  my($self, $perl, $tests) = @_;
  "\t$perl run_test.pl"
}

