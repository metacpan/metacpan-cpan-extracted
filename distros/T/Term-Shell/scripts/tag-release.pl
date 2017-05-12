#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
    io->file("./lib/Term/Shell.pm")->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my @cmd = (
    "git", "tag", "-m",
    "Tagging Term-Shell as $version",
    $version,
);

print join(" ", map { /\s/ ? qq{"$_"} : $_ } @cmd), "\n";
exec(@cmd);
