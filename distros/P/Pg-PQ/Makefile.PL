
use ExtUtils::MakeMaker;

use strict;
use warnings;

use 5.010;

my ($version, $major) = `pg_config --version 2>&1` =~ /PostgreSQL\s+((\d+)\.\d+(?:\.\d+|\w+))\b/i;
unless (defined $major and $major >= 8) {
    die "libpq 8.x.x or later required (" . ($version // 'none') . " found)\n";
}

print STDERR "PostgreSQL $version found\n";

my $incdir = `pg_config --includedir`;
my $libdir = `pg_config --libdir`;
chomp($incdir, $libdir);

my %prereq_pm;
$prereq_pm{'Test::PostgreSQL'} = '1.05' if $ENV{AUTOMATED_TESTING};

WriteMakefile( NAME          => 'Pg::PQ',
               VERSION_FROM  => 'lib/Pg/PQ.pm',
               PREREQ_PM     => \%prereq_pm,
               ABSTRACT_FROM => 'lib/Pg/PQ.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS          => ["-L$libdir -lpq"],
               DEFINE        => qq(-DPQMAJOR=$major -DPQVERSION='"$version"'), # e.g., '-DHAVE_SOMETHING'
               INC           => "-I. -I$incdir",
               # OBJECT        => '$(O_FILES)', # link all the C files too
             );
