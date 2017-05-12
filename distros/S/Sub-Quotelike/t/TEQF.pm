package TEQF; # Test Exporting Quotelike Functions

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(rot13);

use Sub::Quotelike;

sub rot13 (") {
    my $str = shift;
    $str =~ tr/a-zA-Z/n-za-mN-ZA-M/;
    return $str;
}

sub import {
    TEQF->export_to_level(1,@_);
    goto &Sub::Quotelike::import; # Thanks to Benjamin Goldberg for this trick
}

*unimport = \&Sub::Quotelike::unimport;

1;
