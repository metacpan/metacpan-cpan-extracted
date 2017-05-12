
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "These modules are used for internal cPanel development.",
  "AUTHOR" => "cPanel <cpanel\@cpan.org>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-Cpanel-Internal",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::Cpanel::Internal",
  "PREREQ_PM" => {
    "Acme::Bleach" => 0,
    "App::Ack" => 0,
    "Archive::Any" => 0,
    "Archive::Tar" => 0,
    "Archive::Tar::Builder" => 0,
    "Authen::Libwrap" => 0,
    "B::C" => 0,
    "B::Flags" => 0,
    "BSD::Resource" => 0,
    "Business::ISBN" => 0,
    "Capture::Tiny" => 0,
    "Class::C3" => 0,
    "Class::Inspector" => 0,
    "Compress::Zlib" => 0,
    "Crypt::DES_EDE3" => 0,
    "Crypt::OpenPGP" => 0,
    "Crypt::Random" => 0,
    "Cwd" => 0,
    "DBD::Mock" => 0,
    "DBD::Pg" => 0,
    "DBI" => 0,
    "Date::Parse" => 0,
    "DateTime" => 0,
    "Devel::Cover" => 0,
    "Devel::NYTProf" => 0,
    "Devel::REPL" => 0,
    "Devel::Size" => 0,
    "Diff::LibXDiff" => 0,
    "Digest::MD5" => 0,
    "Dist::Zilla::Plugin::GitHub::Meta" => 0,
    "Dist::Zilla::Plugin::Repository" => 0,
    "Dist::Zilla::PluginBundle::Git" => 0,
    "Email::Address" => 0,
    "Encode::Detect" => 0,
    "Error" => 0,
    "Expect" => 0,
    "ExtUtils::CBuilder" => 0,
    "ExtUtils::Constant" => 0,
    "File::Comments" => 0,
    "File::Comments::Plugin::C" => 0,
    "File::Copy::Recursive" => 0,
    "File::Glob" => 0,
    "File::Path::Tiny" => 0,
    "File::Which" => 0,
    "Filesys::Df" => 0,
    "Filesys::POSIX" => 0,
    "Filter::Util::Call" => 0,
    "GSSAPI" => 0,
    "Getopt::Euclid" => 0,
    "Getopt::Param" => 0,
    "Git::Repository" => 0,
    "Git::Wrapper" => 0,
    "Graph::Easy::As_svg" => 0,
    "Graph::Easy::Manual" => 0,
    "IO::AIO" => 0,
    "IO::Interface" => 0,
    "IO::Prompt" => 0,
    "IO::Tty" => 0,
    "Image::Xbm" => 0,
    "Image::Xpm" => 0,
    "JSON::XS" => 0,
    "Log::Log4perl" => 0,
    "Mail::SendEasy" => 0,
    "Mail::Sender::Easy" => 0,
    "Math::BigInt::GMP" => 0,
    "Math::BigInt::Pari" => 0,
    "Math::Pari" => 0,
    "Math::Round" => 0,
    "Module::Extract::VERSION" => 0,
    "Module::Install" => 0,
    "Module::Metadata" => 0,
    "Module::Signature" => 0,
    "Module::Want" => 0,
    "Moo" => 0,
    "Moose" => 0,
    "Net::Ident" => 0,
    "Net::Jabber::Bot" => 0,
    "Net::OpenSSH" => 0,
    "Net::SSLeay" => 0,
    "Net::TCPwrappers" => 0,
    "Opcodes" => 0,
    "Path::Iter" => 0,
    "Perl::Tidy" => 0,
    "Perlbal" => 0,
    "Pod::Markdown" => 0,
    "REST::Google::Translate" => 0,
    "REST::Google::Translate2" => 0,
    "Readonly::XS" => 0,
    "Regexp::Parser" => 0,
    "SOAP::Lite" => 0,
    "Storable" => 0,
    "String::BOM" => 0,
    "String::CRC32" => 0,
    "Sub::Install" => 0,
    "Test::CPAN::Meta" => 0,
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::File::Contents" => 0,
    "Test::Manifest" => 0,
    "Test::MinimumVersion" => 0,
    "Test::Mock::Cmd" => 0,
    "Test::MockModule" => 0,
    "Test::MockObject" => 0,
    "Test::NoWarnings" => 0,
    "Test::Object" => 0,
    "Test::Output" => 0,
    "Test::Parallel" => 0,
    "Test::Pod" => 0,
    "Test::Pod::Coverage" => 0,
    "Test::Script" => 0,
    "Test::SubCalls" => 0,
    "Test::Tester" => 0,
    "Test::Unit" => 0,
    "Test::Warn" => 0,
    "Test::YAML::Meta" => 0,
    "Test::YAML::Valid" => 0,
    "Text::Extract::MaketextCallPhrases" => 0,
    "Text::Fold" => 0,
    "Text::Iconv" => 0,
    "Text::Trim" => 0,
    "Time::HiRes" => 0,
    "Variable::Magic" => 0,
    "WWW::Mechanize" => 0,
    "XML::DOM" => 0,
    "XML::SAX" => 0,
    "YAML" => 0,
    "cPanel::SyncUtil" => 0,
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



