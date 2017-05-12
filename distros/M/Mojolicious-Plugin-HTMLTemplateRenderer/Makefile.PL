use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::HTMLTemplateRenderer',
  VERSION_FROM => 'lib/Mojolicious/Plugin/HTMLTemplateRenderer.pm',
  ABSTRACT     => 'Mojolicious Plugin to render templates with HTML::Template',
  AUTHOR       => 'Bob Faist <bfaist@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '4.0', 'HTML::Template' => '2.0'},
  test         => {TESTS => 't/*.t'}
);
