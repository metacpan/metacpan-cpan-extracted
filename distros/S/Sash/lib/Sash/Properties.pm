package Sash::Properties;
use strict;
use warnings;

use Carp;

# Default the output type.
my $_output = 'tabular';

# Allow the user to define the output type.
sub output {
    my $class = shift;
    my $output = shift;
    
    my $allowed_output_formats = 'perlval|tabular|vertical';

    if ( defined $output ) {
        croak "Invalid output <$output> format. Allowed output formats are $allowed_output_formats"
            unless $output =~ /$allowed_output_formats/i; 
    
        $_output = lc( $output );
    }
    
    return $_output;
}

# The following emulate constants so we can control the internal structure of
# the comparisons.

sub vertical {
    return 'vertical';
}

sub tabular {
    return 'tabular';
}

sub perlval {
    return 'perlval';
}

1;
