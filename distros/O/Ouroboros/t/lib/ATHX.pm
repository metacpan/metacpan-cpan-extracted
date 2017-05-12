package ATHX;
use strict;
use warnings;

use Config;
use DynaLoader;
use Exporter "import";

our @EXPORT = qw/athx pthx/;

# Don't do this at home.
sub athx {
    if ($Config{usemultiplicity}) {
        my $size = $Config{ptrsize};
        die "unsupported pointer size" unless $size == 4 || $size == 8;

        my $proc = DynaLoader::dl_load_file("");
        my $self_ptr = DynaLoader::dl_find_symbol($proc, "PL_curinterp");
        my $self = unpack $size == 4 ? "L" : "Q", pack "P$size", $self_ptr;

        return ($self);
    } else {
        return ();
    }
}

1;
