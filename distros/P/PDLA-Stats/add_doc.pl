use PDLA::Doc;
use File::Copy qw(copy);


# Find the pdl documentation
my ($dir,$file,$pdladoc);

DIRECTORY:
for (@INC) {
    $dir = $_;
    $file = $dir."/PDLA/pdladoc.db";
    if (-f $file) {
        if (! -w "$dir/PDLA") {
            print "No write permission at $dir/PDLA! Not updating docs database.\n";
            exit;
        }
        print "Found docs database $file\n";
        $pdladoc = new PDLA::Doc ($file);
        last DIRECTORY;
    }
}

die ("Unable to find docs database! Not updating docs database.\n") unless $pdladoc;

for (@INC) {
    $dir = "$_/PDLA/Stats";
    if (-d $dir) {
        $pdladoc->ensuredb();
        $pdladoc->scantree($dir);
        eval { $pdladoc->savedb(); };
        warn $@ if $@;

        print "PDLA docs database updated.\n";
        last;
    }
}
