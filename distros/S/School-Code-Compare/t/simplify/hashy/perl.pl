use strict;
use warnings;
use v5.22;

# This is a bigger script

my @array = qw( 99 hello 1 world ); # we declare an array

foreach my $word ( @array ) {
    if ( $word !~ /\d/ ) {
        print $word;
    }
}

say ''; # to print a newline

my $msg = <<'END';
That's it.
Whe're done!
END

print $msg;

__END__

:-)
