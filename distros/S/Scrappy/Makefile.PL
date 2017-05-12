
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'The All Powerful Web Spidering, Scraping, Creeping Crawling Framework',
  'AUTHOR' => 'Al Newkirk <awncorp@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'Scrappy',
  'EXE_FILES' => [
    'bin/scrappy'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Scrappy',
  'PREREQ_PM' => {
    'Array::Unique' => '0',
    'Cwd' => '0',
    'Data::Dumper' => '0',
    'DateTime' => '0',
    'DateTime::Format::SQLite' => '0',
    'File::Find::Rule' => '0',
    'File::ShareDir' => '0',
    'File::Slurp' => '0',
    'File::Util' => '0',
    'HTML::TreeBuilder' => '0',
    'Moose' => '0',
    'Parallel::ForkManager' => '0',
    'String::TT' => '0',
    'Template' => '0',
    'Test::More' => '0',
    'Try::Tiny' => '0',
    'URI' => '0',
    'WWW::Mechanize' => '0',
    'Web::Scraper' => '0',
    'YAML::Syck' => '0'
  },
  'VERSION' => '0.94112090',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

package
MY;
use File::ShareDir::Install qw(postamble);


