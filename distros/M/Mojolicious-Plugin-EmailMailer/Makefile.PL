use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::EmailMailer',
  VERSION_FROM => 'lib/Mojolicious/Plugin/EmailMailer.pm',
  ABSTRACT     => 'Mojolicious Plugin to send mail through Email::Mailer.',
  AUTHOR       => 'Luc Didry <ldidry@cpan.org>',
  CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '6.48'
  },
  MIN_PERL_VERSION => 5.020,
  PREREQ_PM    => {
      'Mojolicious'   => '9.34',
      'Email::Mailer' => '1.22',
      'Email::Sender' => '2.601',
      'Try::Tiny'     => '0.31',
      'Hash::Merge'   => '0',
      'MIME::Words'   => '5.515'
  },
  LICENSE      => 'perl_5',
  test         => {TESTS => 't/*.t'},
  META_MERGE   => {
      "meta-spec" => { version => 2 },
      resources   => {
          bugtracker => {
              web  => 'https://framagit.org/luc/mojolicious-plugin-emailmailer/issues'
          },
          repository => {
              type => 'git',
              url  => 'https://framagit.org/luc/mojolicious-plugin-emailmailer.git',
              web  => 'https://framagit.org/luc/mojolicious-plugin-emailmailer'
          }
      }
  }
);
