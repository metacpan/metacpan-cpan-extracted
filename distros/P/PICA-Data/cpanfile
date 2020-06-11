requires 'perl', '5.14.1';
requires 'Carp', '0';
requires 'Exporter', '0';
requires 'IO::File', '1.14';
requires 'IO::Handle', '0';
requires 'List::Util', '1.33';
requires 'Scalar::Util', '0';
requires 'XML::LibXML', '1.78';
requires 'XML::LibXML', '2';
requires 'XML::Writer', '0';

# don't included here because Dist::Zilla::App::Command::listdeps would include it
# recommends 'Catmandu::PICA';

on 'develop', sub {
  requires 'Code::TidyAll', 0;
  requires 'Perl::Tidy', 0;
  requires 'Test::Code::TidyAll', '0.20';
  requires 'Text::Diff', 0; # undeclared Test::Code::TidyAll plugin dependency
};

on 'test', sub {
  requires 'File::Temp' , '0.2304';
  requires 'IO::File' , '1.14';
  requires 'Test::Exception', '0.43';
  requires 'Test::More', '1.001003';
  requires 'Test::Deep', '0.119';
  requires 'Test::Warn' , '0';
  requires 'Test::XML' , '0.08';
  requires 'YAML::Tiny', '1.46';
};
