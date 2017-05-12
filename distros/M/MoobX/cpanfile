requires "Attribute::Handlers" => "0";
requires "Carp" => "0";
requires "Exporter::Tiny" => "0";
requires "Graph::Directed" => "0";
requires "Module::Runtime" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "Moose::Util" => "0";
requires "MooseX::MungeHas" => "0";
requires "Scalar::Util" => "0";
requires "experimental" => "0";
requires "overload" => "0";
requires "parent" => "0";
requires "perl" => "v5.20.0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "List::AllUtils" => "0";
  requires "Test::More" => "0";
  requires "Test::Warn" => "0";
  requires "strict" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0";
  requires "Test::PAUSE::Permissions" => "0";
  requires "strict" => "0";
};
