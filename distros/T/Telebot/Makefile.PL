use 5.016;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Telebot',
  VERSION_FROM => 'lib/Telebot.pm',
  ABSTRACT     => 'Telegram bot backend',
  AUTHOR       => 'Igor Lobanov <liol@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version   => 2},
    no_index       => {directory => ['t']},
    prereqs        => {runtime   => {requires => {perl => '5.016'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/igorlobanov/telebot/issues'},
      homepage   => 'https://github.com/igorlobanov',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/igorlobanov/telebot.git',
        web  => 'https://github.com/igorlobanov/telebot',
      },
    },
  },
  PREREQ_PM => {Mojolicious => '9.0', 'YAML::XS' => '0.67', Minion => '10.15', 'Mojo::Pg' => '4.23'},
  EXE_FILES => ['script/telebot'],
  test      => {TESTS       => 't/*.t'}
);
