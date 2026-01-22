
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Extensible Perl internet server",
  "AUTHOR" => "Paul Seamons <paul\@seamons.com> and Rob Brown <bbb\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Server",
  "EXE_FILES" => [
    "bin/net-server"
  ],
  "LICENSE" => "perl",
  "NAME" => "Net::Server",
  "PREREQ_PM" => {
    "File::Temp" => 0,
    "IO::Socket" => 0,
    "POSIX" => 0,
    "Socket" => 0,
    "Time::HiRes" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION_FROM" => "lib/Net/Server.pm",
  "test" => {
    "TESTS" => "t/*.t"
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
     resources => {
         homepage => "https://github.com/rhandom/perl-net-server",
         repository => {
             type => 'git',
             url  => 'https://github.com/rhandom/perl-net-server',
             web  => 'https://github.com/rhandom/perl-net-server',
         },
         bugtracker => {
             #web => 'https://rt.cpan.org/Dist/Display.html?Name=Net-Server'
             web => 'https://github.com/rhandom/perl-net-server/issues'
         },
     },
  },
);


my %FallbackPrereqs = (
  "IO::Socket" => 0,
  "POSIX" => 0,
  "Socket" => 0,
  "Time::HiRes" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



