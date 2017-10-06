use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME      => 'Splunk::HEC',
  VERSION_FROM => 'lib/Splunk/HEC.pm',
  ABSTRACT     => 'Splunk HTTP Event Collector (HEC) Client',
  AUTHOR       => 'Ezra Forbus <eforbus@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime => {requires => {perl => '5.010001'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/eforbus/perl-splunk-hec/issues'},
      homepage   => 'https://github.com/eforbus/perl-splunk-hec',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/eforbus/perl-splunk-hec.git',
        web  => 'https://github.com/eforbus/perl-splunk-hec.git'
      }
    },
  },
  PREREQ_PM => {
    'HTTP::Tiny'   => '0.070',
    'JSON::XS'     => '2.27103',
    'Pod::Simple'   => '3.09',
    'Time::Local'   => '1.2'
  },
  test => {TESTS => 't/*.t t/*/*.t'}
);
