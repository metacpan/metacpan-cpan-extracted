requires   "HTTP::Tiny";
requires   "IO::Socket::SSL";
requires   "JSON::MaybeXS";
requires   "Module::CoreList";
requires   "Text::Wrap";
requires   "YAML::PP";
requires   "version";

recommends "HTTP::Tiny"               => "0.083";
recommends "IO::Socket::SSL"          => "1.36";

suggests   "HTTP::Tiny"               => "0.088";
suggests   "IO::Socket::SSL"          => "2.089";
suggests   "JSON::MaybeXS"            => "1.004005";
suggests   "Module::CoreList"         => "5.20240320";
suggests   "Perl::Tidy"               => "20230912";
suggests   "YAML::PP"                 => "0.38.0";
suggests   "version"                  => "0.9929";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.70";
    };

on "test" => sub {
    requires   "Test::More";

    suggests   "Test::More"               => "1.302207";
    };
