use strict;
use Carp;

use constant USE_IO_STRING => $] <= 5.008;


sub ro_fh {
    my @handles = ();
    my $i = 1;

    for my $stringref (@_) {
        croak "error: argument $i is not a scalarref"
            unless ref $stringref eq "SCALAR";

        my $fh = undef;

        if (USE_IO_STRING) {
            require IO::String;
            $fh = IO::String->new($stringref);
        }
        else {
            open($fh, "<", $stringref)
                or croak "fatal: Can't read in-memory buffer: $!";
        }

        $i++;
        push @handles, $fh;
    }

    return @handles
}


sub wo_fh {
    my @handles = ();
    my $i = 1;

    for my $stringref (@_) {
        croak "error: argument $i is not a scalarref"
            unless ref $stringref eq "SCALAR";

        my $fh = undef;

        if (USE_IO_STRING) {
            require IO::String;
            $fh = IO::String->new($stringref);
        }
        else {
            open($fh, ">", $stringref)
                or croak "fatal: Can't read in-memory buffer: $!";
        }

        $i++;
        push @handles, $fh;
    }

    return @handles
}


1
