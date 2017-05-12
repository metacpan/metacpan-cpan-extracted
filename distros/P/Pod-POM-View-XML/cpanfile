requires "Encode" => "0";
requires "Escape::Houdini" => "0";
requires "PerlX::Maybe" => "0";
requires "Pod::POM::View" => "0";
requires "XML::Writer" => "0.620";
requires "parent" => "0";
requires "strict" => "0";
requires "vars" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::POM" => "0";
  requires "Test::More" => "0.88";
  requires "perl" => "5.006";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "version" => "0.9901";
};
