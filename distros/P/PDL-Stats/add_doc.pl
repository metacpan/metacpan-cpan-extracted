use PDL::Doc;
use File::Copy qw(copy);


# Find the pdl documentation
my ($dir,$file,$pdldoc);

DIRECTORY:
for (@INC) {
    $dir = $_;
    $file = $dir."/PDL/pdldoc.db";
    if (-f $file) {
        if (! -w "$dir/PDL") {
            print "No write permission at $dir/PDL! Not updating docs database.\n";
            exit;
        }
        print "Found docs database $file\n";
        $pdldoc = new PDL::Doc ($file);
        last DIRECTORY;
    }
}

die ("Unable to find docs database! Not updating docs database.\n") unless $pdldoc;

for (@INC) {
    $dir = "$_/PDL/Stats";
    if (-d $dir) {
        $pdldoc->ensuredb();
        $pdldoc->scantree($dir);
        eval { $pdldoc->savedb(); };
        warn $@ if $@;

        print "PDL docs database updated.\n";
        last;
    }
}
