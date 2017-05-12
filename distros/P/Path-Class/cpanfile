requires "Carp" => "0";
requires "Cwd" => "0";
requires "Exporter" => "0";
requires "File::Copy" => "0";
requires "File::Path" => "0";
requires "File::Spec" => "3.26";
requires "File::Temp" => "0";
requires "File::stat" => "0";
requires "IO::Dir" => "0";
requires "IO::File" => "0";
requires "Perl::OSType" => "0";
requires "Scalar::Util" => "0";
requires "overload" => "0";
requires "parent" => "0";
requires "strict" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.3601";
};

on 'test' => sub {
  requires "Test" => "0";
  requires "Test::More" => "0";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
  requires "Module::Build" => "0.3601";
};
