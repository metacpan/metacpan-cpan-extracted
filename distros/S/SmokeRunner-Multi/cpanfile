requires "Archive::Tar" => "0";
requires "Class::Accessor::Fast" => "0";
requires "Class::Factory::Util" => "0";
requires "Cwd" => "0";
requires "DBD::SQLite" => "0";
requires "DBI" => "0";
requires "DateTime::Format::Strptime" => "0";
requires "Exporter" => "0";
requires "File::Basename" => "0";
requires "File::Find::Rule" => "0";
requires "File::HomeDir" => "0";
requires "File::Path" => "0";
requires "File::Spec" => "0";
requires "File::Temp" => "0";
requires "File::Which" => "0";
requires "File::chdir" => "0";
requires "IPC::Run3" => "0";
requires "List::Util" => "0";
requires "Moo" => "0";
requires "MooX::Singleton" => "0";
requires "Params::Validate" => "0";
requires "Scalar::Util" => "0";
requires "YAML::Syck" => "0";
requires "base" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Copy" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "lib" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::PAUSE::Permissions" => "0";
  requires "Test::Vars" => "0";
};
