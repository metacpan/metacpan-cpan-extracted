use strict;
use warnings;
use Path::Class;

# create constants list from libdrizzle/constants.h

my $path = shift or die;
my $contents = file($path)->slurp;
while ($contents =~ s/(DRIZZLE_[A-Z0-9_]+)//) {
    my $name = $1;
    next if $name eq 'DRIZZLE_CONSTANTS_H';
    if ($ENV{RAW}) {
        print "$name\n";
    } else {
        # "DRIZZLE_DEFAULT_USER"
        # "DRIZZLE_DEFAULT_UDS"
        # "DRIZZLE_DEFAULT_TCP_HOST"
        print qq{newCONSTSUB(stash, "$name", newSViv($name));\n};
    }
}

