package SVG::VCD::Taxon;

use strict;
use warnings;


sub new {
    my $class = shift();
    my(%fields) = @_;

    return bless {
	%fields
    }, $class;
}


sub field {
    my $this = shift();
    my($key) = @_;

    return $this->{$key};
}


1;
