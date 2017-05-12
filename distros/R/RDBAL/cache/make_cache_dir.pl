use RDBAL::Config;

if (!-e "$RDBAL::Config::cache_directory") {
    print "Making schema cache directory: $RDBAL::Config::cache_directory\n";
    print STDERR `mkdir $RDBAL::Config::cache_directory`;
    print STDERR `chmod ug+rw $RDBAL::Config::cache_directory`;
} else {
    print "Schema cache directory: $RDBAL::Config::cache_directory already present--skipping\n";
}
