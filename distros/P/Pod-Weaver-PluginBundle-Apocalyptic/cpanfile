requires "Pod::Elemental::Transformer::List" => "0.101620";
requires "Pod::Weaver::Config::Assembler" => "4.001";
requires "Pod::Weaver::Plugin::EnsureUniqueSections" => "0.103531";
requires "Pod::Weaver::Plugin::StopWords" => "1.001005";
requires "Pod::Weaver::Section::Contributors" => "0.008";
requires "Pod::Weaver::Section::SeeAlso" => "1.002";
requires "Pod::Weaver::Section::Support" => "1.003";
requires "Pod::Weaver::Section::WarrantyDisclaimer" => "0.111290";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0.88";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "version" => "0.9901";
};
