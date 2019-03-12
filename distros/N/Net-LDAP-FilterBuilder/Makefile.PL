
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Build LDAP filter statements',
  'AUTHOR' => 'Originally written by Ray Miller.',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-LDAP-FilterBuilder',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::LDAP::FilterBuilder',
  'PREREQ_PM' => {
    'overload' => '0'
  },
  'VERSION' => '1.200002',
  'test' => {
    'TESTS' => 't/*.t'
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
     'meta-spec' => { version => 2 },
     resources => {
        repository => {
           type => 'git',
           url  => 'https://github.com/ollyg/Net-LDAP-FilterBuilder.git',
           web  => 'https://github.com/ollyg/Net-LDAP-FilterBuilder',
        },
     }})
     : ()
  ),
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



