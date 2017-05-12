requires "Carp" => "0";
requires "Cwd" => "0";
requires "JSON" => "0";
requires "Moo" => "0";
requires "Selenium::Remote::Driver::Firefox::Profile" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "IO::Socket::INET" => "0";
  requires "Selenium::Remote::Driver" => "0.2102";
  requires "Test::More" => "0";
  requires "Test::ParallelSubtest" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
