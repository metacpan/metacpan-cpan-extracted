requires "Config::JFDI" => "0";
requires "DBIx::Class" => "0";
requires "DBIx::Class::ResultSet" => "0";
requires "DBIx::Class::Schema" => "0";
requires "Data::Munge" => "0";
requires "JSON" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "MooseX::NonMoose" => "0.26";
requires "namespace::autoclean" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "FindBin" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::DBIx::Class" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Most" => "0";
  requires "blib" => "1.01";
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
  requires "Test::Pod" => "1.41";
};
