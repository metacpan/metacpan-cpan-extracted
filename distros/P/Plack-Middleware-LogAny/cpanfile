#<<<
use strict; use warnings;
#>>>

on 'configure' => sub {
  requires 'Config'                        => '0';
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';
};

on 'runtime' => sub {
  requires 'Log::Any'              => '>= 1.711';
  requires 'Plack::Middleware'     => '0';
  requires 'Plack::Util::Accessor' => '0';
};

on 'test' => sub {
  requires 'Test::More'                  => '0';
  requires 'Log::Any::Adapter::Log4perl' => '>= 0.09';
};

on 'develop' => sub {
  suggests 'App::Software::License' => 0;
  suggests 'Pod::Markdown::Github'  => 0;
};
