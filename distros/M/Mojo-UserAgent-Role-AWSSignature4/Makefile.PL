use 5.020;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'Mojo::UserAgent::Role::AWSSignature4',
  VERSION_FROM   => 'lib/Mojo/UserAgent/Role/AWSSignature4.pm',
  ABSTRACT       => 'Add AWS Signature Version 4 to Mojo::UserAgent requests',
  AUTHOR         => 'Stefan Adams <sadams@cpan.org>',
  LICENSE        => 'artistic_2',
  META_MERGE => {
    dynamic_config => 0,
    'meta-spec' => { version => 2 },
    no_index       =>
      {directory => [qw(examples t)],},
    prereqs   => {runtime => {requires => {perl => '5.020'}}},
    resources  => {
      bugtracker => {
        web => 'https://github.com/stefanadams/Mojo-UserAgent-Role-AWSSignature4/issues',
      },
      license    => ['https://opensource.org/license/artistic-2-0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/stefanadams/Mojo-UserAgent-Role-AWSSignature4.git',
        web  => 'https://github.com/stefanadams/Mojo-UserAgent-Role-AWSSignature4',
      },
    },
    provides => {
      'Mojo::UserAgent::Role::AWSSignature4' => {
        file    => 'lib/Mojo/UserAgent/Role/AWSSignature4.pm',
        version => '0.01',
      },
    },
  },
  PREREQ_PM      => {
    'Class::Method::Modifiers' => '2.12',
    'Digest::SHA' => '0',
    'Mojolicious' => '9.00',
    'Role::Tiny'  => '2.00',
    'Time::Piece' => '0',
  },
  BUILD_REQUIRES => {
    'Test::More' => '0',
    'Time::Piece' => '0',
  },
  test => {TESTS => 't/*.t t/*/*.t'},
);
