requires 'Archive::Zip';
requires 'Const::Fast';
requires 'Data::Printer';
requires 'DBI';
requires 'File::Slurper';
requires 'HTTP::Response';
requires 'HTTP::Tiny';
requires 'Hash::MultiValue';
requires 'IO::Capture';
requires 'IO::String';
requires 'IPC::Run3';
requires 'JSON::Path';
requires 'JSON::XS';
requires 'Moose';
requires 'MooseX::Types';
requires 'MooseX::Types::Common';
requires 'namespace::autoclean';
requires 'Params::ValidationCompiler', '0.22';
requires 'Test::BDD::Cucumber';
requires 'Try::Tiny';

on build => sub {
    requires 'Test::More';
};

on 'test' => sub {
  requires 'Test::Compile';
};
