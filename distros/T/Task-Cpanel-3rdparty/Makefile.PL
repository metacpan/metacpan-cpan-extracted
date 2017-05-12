
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "These modules are used for 3rdparty application development with B<cPanel & WHM>.",
  "AUTHOR" => "cPanel <cpanel\@cpan.org>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-Cpanel-3rdparty",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::Cpanel::3rdparty",
  "PREREQ_PM" => {
    "CGI::Session" => 0,
    "Class::Std::Utils" => 0,
    "Config::Crontab" => 0,
    "Config::General" => 0,
    "Convert::BinHex" => 0,
    "Convert::TNEF" => 0,
    "DBD::SQLite" => 0,
    "Date::Format" => 0,
    "Date::Simple" => 0,
    "File::MimeInfo" => 0,
    "Gearman::Client" => 0,
    "HTML::StripTags" => 0,
    "IO::Interactive" => 0,
    "IO::Socket::SSL" => 0,
    "IO::Stringy" => 0,
    "JSON" => 0,
    "JSON::XS" => 0,
    "LWP::UserAgent" => 0,
    "MIME::Tools" => 0,
    "Mail::Header" => 0,
    "Mozilla::CA" => 0,
    "Net::CIDR" => 0,
    "Net::DNS::SEC" => 0,
    "Net::IP" => 0,
    "Net::Ident" => 0,
    "NetAddr::IP" => 0,
    "Pod::Escapes" => 0,
    "Proc::ProcessTable" => 0,
    "SOAP::Lite" => 0,
    "Smart::Comments" => 0,
    "Sys::SigAction" => 0,
    "Test::Pod" => 0,
    "Unix::Syslog" => 0,
    "WWW::FieldValidator" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "11.36.001",
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



