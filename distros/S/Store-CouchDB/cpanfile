requires "Any::Moose" => "0";
requires "Carp" => "0";
requires "Data::Dump" => "0";
requires "Data::Printer" => "0";
requires "JSON" => "0";
requires "LWP::UserAgent" => "0";
requires "Types::Serialiser" => "0";
requires "URI::Escape" => "0";

on 'test' => sub {
  requires "Scalar::Util" => "0";
  requires "Test::More" => "0";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
