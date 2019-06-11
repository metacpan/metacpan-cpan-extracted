package OpenTracing::Log;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use parent qw(OpenTracing::Common);

sub timestamp { shift->{timestamp} }
sub tags { shift->{tags} }
sub tag_list { (shift->{tags} //= [])->@* }

1;

