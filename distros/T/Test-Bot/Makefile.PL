use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Bot',
    AUTHOR              => q{Mischa Spiegelmock <revmischa@cpan.org>},
    VERSION_FROM        => 'lib/Test/Bot.pm',
    ABSTRACT_FROM       => 'lib/Test/Bot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Any::Moose' => 0,
        'MouseX::NativeTraits::ArrayRef' => 0,
        'TAP::Harness' => 0,
        'AnyEvent::IRC::Client' => 0,
        'Class::MOP' => 0,
        'MouseX::Getopt' => 0,
        'Twiggy::Server' => 0,
        'Plack::Request' => 0,
        'JSON' => 0,
        'DateTime' => 0,
        'DateTime::Format::ISO8601' => 0,
        'Capture::Tiny' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Bot-*' },
);
