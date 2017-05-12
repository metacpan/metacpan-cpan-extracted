use strict;
use warnings;

use IO::All;

# some bits stolen from Ingy! (thanks, Brian :)
use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0)) or die "Couldn't chdir to ".dirname($0);
(my $outfilename = basename($0)) =~ s/\.PL$//;

print "Preparing $outfilename...\n";
io($outfilename)->print( "$Config{startperl}\n", join('',<DATA>) );
chmod 0755, $outfilename;
print "Done!\n";

__DATA__
use strict;
use warnings;

eval 'exec /usr/bin/perl -S $0 ${1+"$@"}'
    if 0; # not running under some shell

# FIXME -- add real $VERSION
our $VERSION = '0.01';

use SoggyOnion;
use YAML qw( LoadFile );

# hello, world!
print "started soggyonion version $VERSION on ",
    scalar localtime(time), "\n";

# process arguments -- currently, just load the configuration,
# but do a pile of error checking.
my $config;
die "usage: $0 /path/to/config.yaml\n"
    unless @ARGV == 1;
die "file $ARGV[0] doesn't exist\n"
    unless -f $ARGV[0];
die "file $ARGV[0] isn't readable\n"
    unless -r $ARGV[0];
eval {
    $config = LoadFile( $ARGV[0] );
};
die "error reading config:\n$@\n"
    if $@;

# do the thing
SoggyOnion->options( $config->{options} );
SoggyOnion->generate( $config->{layout} );
exit 0;

