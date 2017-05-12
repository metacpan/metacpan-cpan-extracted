requires "perl" => "5.006";
requires "Exporter";
on configure => sub {
    requires "ExtUtils::MakeMaker";
};

on build => sub {
    requires "ExtUtils::MakeMaker" => "6.59";
    requires "Test::More";
    requires "Test::Pod";
    requires "Test::Pod::Coverage";
    requires "Pod::Coverage::TrustPod";
};