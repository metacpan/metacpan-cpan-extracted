#!/usr/bin/env perl

use 5.014;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../lib");

use Term::CLI;

$SIG{INT} = 'IGNORE';

my $term = Term::CLI->new(
    name   => 'bssh',               # A basically simple shell.
    skip   => qr/^\s*(?:#.*)?$/,    # Skip comments and empty lines.
    prompt => 'bssh> ',             # A more descriptive prompt.
);

say "\n[Welcome to BSSH]";
while ( defined( my $line = $term->readline ) ) {
    $term->execute_line($line);
}
say "\n-- exit";
exit 0;
