requires   "Carp";
requires   "IO::Compress::Xz"         => "2.100";
requires   "IO::Uncompress::UnXz"     => "2.100";
requires   "PerlIO";

recommends "IO::Compress::Xz"         => "2.204";
recommends "IO::Uncompress::UnXz"     => "2.204";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.70";
    };

on "test" => sub {
    requires   "Test::More";

    recommends "Test::More"               => "1.302195";
    };
