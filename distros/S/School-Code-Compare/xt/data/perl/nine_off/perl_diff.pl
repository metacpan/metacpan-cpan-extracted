use strict;
use warnings;

my @array = qw( 99 hello 1 world );

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
