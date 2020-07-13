use 5.016;
 
use strict;
use warnings;
 
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'OOP::Private',
  VERSION_FROM => 'lib/OOP/Private.pm',
  ABSTRACT     => 'Private and protected methods',
  AUTHOR       => 'John Smith <retardedshitposter@tfwno.gf>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => [qw(examples t)], package => [],},
    prereqs        => {runtime => {requires => {perl => '5.026'}}},
    resources      => {
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => { type => 'git', url  => 'https://git.nixnet.xyz/john-smith/perl-oop-private.git' },
    },
  },
  PREREQ_PM => {"Attribute::Handlers" => 0},
  test      => {TESTS => 't/*.t t/*/*.t'}
);
