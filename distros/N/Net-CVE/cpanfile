requires   "Carp";
requires   "Data::Dumper";
requires   "HTTP::Tiny"               => "0.009";
requires   "IO::Socket::SSL"          => "1.42";
requires   "JSON::MaybeXS"            => "1.004005";
requires   "List::Util";

recommends "Data::Dumper"             => "2.188";
recommends "Data::Peek"               => "0.52";
recommends "HTTP::Tiny"               => "0.088";
recommends "IO::Socket::SSL"          => "2.085";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.70";
    };

on "test" => sub {
    requires   "Test::More"               => "0.90";
    requires   "Test::Warnings";

    recommends "Test::More"               => "1.302198";
    };
