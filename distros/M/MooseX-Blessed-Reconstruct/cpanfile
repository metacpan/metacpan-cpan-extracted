requires "Carp" => "0";
requires "Class::Load" => "0";
requires "Class::MOP" => "0.93";
requires "Data::Visitor" => "0.21";
requires "Moose" => "1.05";
requires "Scalar::Util" => "0";
requires "Test::use::ok" => "0";
requires "namespace::clean" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0.88";
  requires "ok" => "0";
  requires "perl" => "5.006";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "version" => "0.9901";
};
