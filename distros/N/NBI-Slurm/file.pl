use strict;
use warnings;

sub days_since_update {
    my $file_path = shift;

    # Check if the required modules can be loaded
    eval {
        require File::Spec;
        require Time::Piece;
        require Time::Seconds;
    };
    if ($@) {
        return -1;  # Failed to load required module(s)
    }

    # Check if the file exists
    unless (-e $file_path) {
        return -1;  # File not found
    }

    # Get the file's last modification time
    my $last_modified = (stat($file_path))[9];

    # Calculate the number of days since the last modification
    my $current_time = time();
    my $days_since_update = int(($current_time - $last_modified) / (24 * 60 * 60));

    return $days_since_update;
}

my $days = days_since_update($ARGV[0]);
-e $ARGV[0] or die "File not found.\n";
if ($days == -1) {
    print "File not found or failed to load required module(s).\n";
} else {
    print "Days since last update: $days\n";
}

