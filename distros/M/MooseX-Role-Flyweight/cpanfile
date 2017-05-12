requires "JSON" => "2.00";
requires "Moose::Role" => "0";
requires "Scalar::Util" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.006";
recommends "JSON::XS" => "0";

on 'test' => sub {
  requires "Moose" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "lib" => "0";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
