package OpenTracing::Tag;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use parent qw(OpenTracing::Common);

sub key { shift->{key} }
sub value { shift->{value} }

1;
