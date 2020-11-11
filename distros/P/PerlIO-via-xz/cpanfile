requires   "Carp";
requires   "IO::Compress::Xz"         => "2.096";
requires   "IO::Uncompress::UnXz"     => "2.096";
requires   "PerlIO";

recommends "Encode"                   => "3.07";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";
    };

on "test" => sub {
    requires   "Test::More";

    recommends "Test::More"               => "1.302183";
    };
