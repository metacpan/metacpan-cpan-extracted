requires "Data::Dumper::Concise" => "0";
requires "Function::Parameters" => "0";
requires "Module::Runtime" => "0";
requires "Mojo::JSON" => "0";
requires "Mojo::Parameters" => "0";
requires "Mojo::URL" => "0";
requires "Mojo::UserAgent" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "Moose::Util" => "0";
requires "namespace::autoclean" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "FindBin" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Mojolicious" => "0";
  requires "Test::Compile" => "0";
  requires "Test::Exception" => "0";
  requires "Test::Kwalitee" => "0";
  requires "Test::Mojo" => "0";
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
  requires "lib" => "0";
  requires "perl" => "5.006";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::Kwalitee" => "1.21";
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
};
