
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Web Document System",
  "AUTHOR" => "Mateu X. Hunter",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Mojito",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Mojito",
  "PREREQ_PM" => {
    "CHI" => 0,
    "DBM::Deep" => 0,
    "Data::Dumper::Concise" => 0,
    "DateTime" => 0,
    "DateTime::TimeZone" => 0,
    "Digest::MD5" => 0,
    "Dir::Self" => 0,
    "Elasticsearch" => 0,
    "Elasticsearch::Scroll" => 0,
    "Encode" => 0,
    "File::Spec" => 0,
    "Git::Wrapper" => 0,
    "HTML::Entities" => 0,
    "HTML::Strip" => 0,
    "HTML::Toc" => 0,
    "HTML::TocInsertor" => 0,
    "HTML::Zoom" => 0,
    "HTTP::Tiny" => 0,
    "IO::File" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "MetaCPAN::API" => 0,
    "MongoDB" => 0,
    "MongoDB::OID" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "Path::Class" => 0,
    "Plack::Middleware" => 0,
    "Plack::Util::Accessor" => 0,
    "Pod::Simple::XHTML" => 0,
    "Sub::Quote" => 0,
    "Syntax::Keyword::Junction" => 0,
    "Text::MultiMarkdown" => 0,
    "Text::Textile" => 0,
    "Text::WikiCreole" => 0,
    "Try::Tiny" => 0,
    "WWW::Mechanize" => 0,
    "XML::Atom::SimpleFeed" => 0,
    "if" => 0,
    "parent" => 0,
    "strictures" => 1,
    "utf8" => 0
  },
  "TEST_REQUIRES" => {
    "FindBin" => 0,
    "HTTP::Request" => 0,
    "HTTP::Request::Common" => 0,
    "JSON" => 0,
    "Plack::Middleware::Auth::Digest" => 0,
    "Plack::Test" => 0,
    "Plack::Util" => 0,
    "Test::Deep" => 0,
    "Test::Differences" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.24",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



