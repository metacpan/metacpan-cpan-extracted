use strict;
use warnings;

use File::Spec;

use Number::Phone::FR ':full';

do File::Spec->catfile(qw[t 10-one.t]);
die $@ if $@;
