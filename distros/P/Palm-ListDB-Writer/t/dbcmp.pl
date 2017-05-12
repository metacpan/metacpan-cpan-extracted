use strict;
use warnings;

# Compare two List Databases, ignoring timestamps.
# Runs 3 tests.

sub dbcmp {
    my ($db1, $db2, $size) = @_;
    my $fh;

    # Slurp resultant database.
    open($fh, $db1);
    binmode($fh);
    sysread($fh, my $pdb, -s $db1);
    close($fh);
    is(length($pdb), $size, "db length") if defined $size;

    # Slurp reference database.
    open($fh, $db2);
    binmode($fh);
    sysread($fh, my $ref, -s $db2);
    is(length($ref), $size, "ref length") if defined $size;
    close($fh);

    # Wipe out time stamps.
    substr($pdb,36,12) = "";
    substr($ref,36,12) = "";

    # Compare.
    ok($pdb eq $ref, "db <-> ref");

    $pdb eq $ref;
}

1;
