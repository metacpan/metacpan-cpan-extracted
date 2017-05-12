
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Subroutine calls over the network using common serialization",
  "AUTHOR" => "Oliver Gorwits <oliver\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "IO::Pipe" => 0,
    "IO::String" => 0,
    "Test::More" => 0,
    "URI::file" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "RPC-Serialized",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "RPC::Serialized",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Accessor::Fast::Contained" => 0,
    "Data::Serializer" => 0,
    "Exception::Class" => 0,
    "IO::File" => 0,
    "IO::Handle" => 0,
    "IO::Socket::INET" => 0,
    "IO::Socket::SSL" => 0,
    "IO::Socket::UNIX" => 0,
    "Log::Dispatch::Syslog" => 0,
    "Module::MultiConf" => 0,
    "Net::Server::PreFork" => 0,
    "Net::Server::Single" => 0,
    "Readonly" => 0,
    "Symbol" => 0,
    "UNIVERSAL" => 0,
    "URI" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.123630",
  "test" => {
    "TESTS" => "t/*.t"
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



