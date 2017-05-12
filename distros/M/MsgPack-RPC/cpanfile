requires "Beam::Emitter" => "0";
requires "Beam::Event" => "0";
requires "Data::Printer" => "0";
requires "Exporter::Tiny" => "0";
requires "IO::Socket::INET" => "0";
requires "IO::Socket::UNIX" => "0";
requires "List::AllUtils" => "0";
requires "Moose" => "0";
requires "MooseX::NonMoose" => "0";
requires "MooseX::Role::Loggable" => "0";
requires "Promises" => "0";
requires "Type::Tiny" => "0";
requires "Types::Standard" => "0";
requires "experimental" => "0";
requires "overload" => "0";
requires "perl" => "v5.20.0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Approx" => "0";
  requires "Test::Deep" => "0";
  requires "Test::More" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::Vars" => "0";
};
