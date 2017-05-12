use PDLA::Doc;
use File::Copy qw(copy);


# Find the pdl documentation
my ($dir,$file,$pdldoc);

DIRECTORY:
for (@INC) {
    $dir = $_;
    $file = $dir."/PDLA/pdldoc.db";
    if (-f $file) {
        if (! -w "$dir/PDLA") {
            print "No write permission at $dir/PDLA! Not updating docs database.\n";
            exit;
        }
        print "Found docs database $file\n";
        $pdldoc = new PDLA::Doc ($file);
        last DIRECTORY;
    }
}

die ("Unable to find docs database! Not updating docs database.\n") unless $pdldoc;

for (@INC) {
    $dir = "$_/PDLA/Stats";
    if (-d $dir) {
        $pdldoc->ensuredb();
        $pdldoc->scantree($dir);
        eval { $pdldoc->savedb(); };
        warn $@ if $@;

        print "PDLA docs database updated.\n";
        last;
    }
}
