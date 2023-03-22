#<<<
use strict; use warnings;
#>>>

on 'configure' => sub {
  requires 'Config'                        => '0';
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';
  requires 'File::Spec'                    => '0';
  requires 'lib'                           => '0';
  requires 'subs'                          => '0';
};

on 'runtime' => sub {
  requires 'Getopt::Long' => '>= 2.24';
  requires 'Test::More'   => '>= 0.99';
  requires 'parent'       => '0';
};

on 'test' => sub {
  requires 'Test::Builder::Tester' => '0';
};

on 'develop' => sub {
  suggests 'App::Software::License' => '0';
  suggests 'App::cpanminus'         => '>= 1.7046';
};
