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
  requires 'Log::Any'         => '>= 1.711';
  requires 'Moo'              => '>= 2.004000';
  requires 'MooX::TypeTiny'   => '>= 0.002003';
  requires 'Type::Tiny'       => '0';
  requires 'namespace::clean' => '0';
};

on 'test' => sub {
  requires 'Log::Log4perl' => '0';
  requires 'Test::More'    => '0';
  requires 'Test::Output'  => '0';
};

on 'develop' => sub {
  suggests 'App::Software::License' => 0;
  suggests 'App::cpanminus'         => '>= 1.7046';
};
