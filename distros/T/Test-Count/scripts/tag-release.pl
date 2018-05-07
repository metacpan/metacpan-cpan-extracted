#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    ( map { m{\Aversion *= *(\S+)\n?\z} ? ($1) : () }
        io->file("./dist.ini")->getlines() );

if ( !defined($version) )
{
    die "Version is undefined!";
}

my $mini_repos_base =
    'https://svn.berlios.de/svnroot/repos/web-cpan/Test-Count';

my @cmd = (
    "hg", "tag", "-m", "Tagging the Test-Count release as $version",
    "releases/$version",
);

print join( " ", map { /\s/ ? qq{"$_"} : $_ } @cmd ), "\n";
exec(@cmd);

