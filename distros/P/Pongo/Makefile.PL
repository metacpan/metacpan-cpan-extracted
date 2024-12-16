use 5.008005;
use strict;
use warnings;
use ExtUtils::MakeMaker 7.12;

my $os = $^O;

my %config = (
  NAME           => 'Pongo',
  VERSION_FROM   => 'lib/Pongo.pm',
  PREREQ_PM      => { 'ExtUtils::MakeMaker' => '7.12' },
  ABSTRACT_FROM  => 'lib/Pongo.pm',
  AUTHOR         => 'Rudraditya Thakur',
  CCFLAGS        => '-Wall -std=c99 -I/usr/local/include/libmongoc-1.0 -I/usr/local/include/libbson-1.0',
  OPTIMIZE       => '-O3',
  LICENSE        => 'GPL-3.0 License',
  XSMULTI        => 1,
);

if ($os eq 'linux') {
    $config{CCFLAGS} = '-Wall -std=c99 -I/usr/include/libmongoc-1.0 -I/usr/include/libbson-1.0';
    $config{LIBS}    = ['-lmongoc-1.0 -lbson-1.0'];
} elsif ($os eq 'darwin') {
    $config{CCFLAGS} = '-Wall -std=c99 -I/usr/local/include/libmongoc-1.0 -I/usr/local/include/libbson-1.0';
    $config{LIBS}    = ['-lmongoc-1.0 -lbson-1.0'];
} else {
    die "Unsupported operating system: $os";
}

WriteMakefile(%config);
