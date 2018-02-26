#!/usr/bin/perl

use Modern::Perl;
use FindBin;
use lib ("$FindBin::Bin/../lib");

use Term::CLI;

$SIG{INT} = 'IGNORE';

my $term = Term::CLI->new(
    name => 'bssh',             # A basically simple shell.
);

say "\n[Welcome to BSSH]";
while ( defined(my $line = $term->readline) ) {
    $term->execute($line);
}
say "\n-- exit";
exit 0;
