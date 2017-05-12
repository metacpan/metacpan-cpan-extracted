use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
        "NAME"                  =>      'POE::Component::Client::WebSocket',
        "AUTHOR"                =>      q{Paul G Webster <daemon@cpan.org>},
        "MIN_PERL_VERSION"      =>      "5.006",
        "ABSTRACT"              =>      "A simplistic websocket client for use in POE applications.",
        "CONFIGURE_REQUIRES"    =>      { "ExtUtils::MakeMaker" => 0 },
        "DISTNAME"              =>      "POE-Component-Client-WebSocket",
        "LICENSE"               =>      "artistic_2",
        "PREREQ_PM"             =>      {
                "POE"                           =>      0,
                "POE::Filter::SSL"              =>      0,
                "POE::Filter::HTTP::Parser"     =>      0,
                "POE::Filter::Stackable"        =>      0,
                "URI"                           =>      0,
                "MIME::Base64"                  =>      0,
                "Protocol::WebSocket::Frame"    =>      0,
        },
        TEST_REQUIRES          =>      {
                'Test::More'                    =>      0,
        },
        VERSION_FROM           =>       'lib/POE/Component/Client/WebSocket.pm',
        "test" => {
                "TESTS"        => "t/*.t"
        }
);

my %FallbackPrereqs = (
        "POE"                           =>      0,
        "POE::Filter::SSL"              =>      0,
        "POE::Filter::HTTP::Parser"     =>      0,
        "POE::Filter::Stackable"        =>      0,
        "URI"                           =>      0,
        "MIME::Base64"                  =>      0,
        "Protocol::WebSocket::Frame"    =>      0,
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}
 
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };
 
WriteMakefile(%WriteMakefileArgs);

