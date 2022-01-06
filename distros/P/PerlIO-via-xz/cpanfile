requires   "Carp";
requires   "IO::Compress::Xz"         => "2.100";
requires   "IO::Uncompress::UnXz"     => "2.100";
requires   "PerlIO";

recommends "IO::Compress::Xz"         => "2.101";
recommends "IO::Uncompress::UnXz"     => "2.101";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";
    };

on "test" => sub {
    requires   "Test::More";

    recommends "Test::More"               => "1.302188";
    };
