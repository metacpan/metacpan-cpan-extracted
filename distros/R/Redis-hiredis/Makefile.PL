require 5.004 ;
use ExtUtils::MakeMaker 5.16 ;
use Config ;

my @parts = qw/dict hiredis net sds/;
my $cfiles = [ map { "$_.c" } @parts ];
my $ofiles = join ' ', map { "$_.o" } @parts;

WriteMakefile(
  NAME            => 'Redis::hiredis',
  AUTHOR          => 'Brian Clapper <bclapper@omniti.com>',
  ABSTRACT        => 'interact with Redis using the hiredis client',
  VERSION_FROM    => 'lib/Redis/hiredis.pm',
  OBJECT          => "Redis-hiredis.o $ofiles",
  C               => $cfiles,
  OPTIMIZE        => $ENV{'OPTIMIZE'}
);
