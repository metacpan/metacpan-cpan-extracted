requires   "HTTP::Tiny";
requires   "IO::Socket::SSL";
requires   "JSON::MaybeXS";
requires   "Text::Wrap";
requires   "version";

recommends "HTTP::Tiny"               => "0.059";
recommends "IO::Socket::SSL"          => "1.35";

suggests   "HTTP::Tiny"               => "0.088";
suggests   "IO::Socket::SSL"          => "2.083";
suggests   "JSON::MaybeXS"            => "1.004005";
suggests   "Perl::Tidy"               => "20230912";
suggests   "version"                  => "0.9929";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.70";
    };

on "test" => sub {
    requires   "Test::More";

    suggests   "Test::More"               => "1.302195";
    };
