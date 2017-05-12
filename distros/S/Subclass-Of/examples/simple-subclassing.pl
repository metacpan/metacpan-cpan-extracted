use 5.010;
use strict;
use warnings;

# A subclass of IO::File that returns File::stat objects
# (but only in scalar context).
#
use File::stat ();
use Subclass::Of "IO::File", -methods => [
	stat => sub { wantarray ? ::SUPER() : bless [::SUPER()], "File::stat" },
];

use Data::Dumper;
my $file = File->new(__FILE__, "r");

say $file->stat->size; # says 359
