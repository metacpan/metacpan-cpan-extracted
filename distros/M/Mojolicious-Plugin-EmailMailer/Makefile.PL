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
      'Mojolicious'   => '8.36',
      'Email::Mailer' => '1.15',
      'Email::Sender' => '1.300034',
      'Try::Tiny'     => '0.30',
      'Hash::Merge'   => '0',
      'MIME::Words'   => '0'
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
