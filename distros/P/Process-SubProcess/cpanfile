requires 'ExtUtils::MakeMaker';
requires 'Getopt::Long::Descriptive';
requires 'Path::Tiny';
requires 'JSON';
requires 'YAML';
requires 'Data::Dump';

on 'test' => sub {
  requires 'Test::More';
  requires 'Capture::Tiny';
};

feature 'test_perl-5.10', 'testing in perl 5.10' => sub {
  requires 'local::lib';
  requires 'Perl::Build';
};
