requires "List::Util" => "1.33";
requires "Moo" => "0";
requires "MooX::JSON_LD" => "v0.0.13";
requires "Ref::Util" => "0";
requires "Types::Standard" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "v5.10.1";
requires "utf8" => "0";
recommends "Ref::Util::XS" => "0";
recommends "Type::Tiny::XS" => "0";
recommends "aliased" => "0";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "Module::Metadata" => "0";
  requires "Test::JSON::More" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "aliased" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::CleanNamespaces" => "0.15";
  requires "Test::EOF" => "0";
  requires "Test::MinimumVersion" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Portability::Files" => "0";
};
