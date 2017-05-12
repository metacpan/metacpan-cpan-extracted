package t::Context;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = 1;

die "t::Context sees array context at file scope" if wantarray;
die "t::Context sees void context at file scope" unless defined wantarray;

"t::Context return";
