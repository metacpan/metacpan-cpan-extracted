requires "Bio::Chado::Schema" => "0.20000";
requires "DBD::SQLite" => "1.37";
requires "DBIx::Class::Fixtures" => "1.001018";
requires "Data::Random" => "0.08";
requires "File::Path" => "2.08";
requires "File::ShareDir" => "1.02";
requires "Graph" => "0.94";
requires "HTTP::Tiny" => "0.029";
requires "IPC::Cmd" => "0.58";
requires "Module::Path" => "0.09";
requires "Module::Runtime" => "0.013";
requires "Moo" => "1.001";
requires "MooX::ClassAttribute" => "0.006";
requires "MooX::HandlesVia" => "0.001000";
requires "MooX::InsideOut" => "0.001002";
requires "MooX::late" => "0.009";
requires "Path::Class" => "0.18";
requires "Test::DatabaseRow" => "2.03";
requires "Try::Tiny" => "0.03";
requires "XML::Twig" => "3.35";
requires "XML::XPath" => "1.13";
requires "YAML" => "0.70";
requires "namespace::autoclean" => "0.11";
requires "perl" => "5.010";
suggests "DBD::Pg" => "v2.19.3";
suggests "File::Find::Rule" => "0.33";
suggests "Getopt::Long::Descriptive" => "0.093";

on 'build' => sub {
  requires "Module::Build" => "0.3601";
};

on 'test' => sub {
  requires "Class::Unload" => "0.07";
  requires "Test::Exception" => "0.31";
  requires "Test::More" => "0.94";
  requires "Test::Tester" => "0.108";
};

on 'configure' => sub {
  requires "Module::Build" => "0.3601";
};

on 'develop' => sub {
  requires "Test::CPAN::Meta" => "0";
};
