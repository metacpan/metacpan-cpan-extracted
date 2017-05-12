# -*- cperl -*-

package Parse::YALALR::Kernel;
use Parse::YALALR::Parser;

use fields (id =>              #
	    items =>           #
	    shifts =>          #
	    reduces =>         #
	    actions =>         #
	    REDUCE_WHY =>      #
	    SHIFT_WHY =>       #
);

use strict;

sub new {
    my $class = shift;
    my Parse::YALALR::Parser $parser = shift;
    my ($items) = @_;

    no strict 'refs';
    my Parse::YALALR::Kernel $self = bless [ \%{"${class}::FIELDS"} ], $class;
    $self->{id} = $parser->{nstates}++;
    $self->{items} = $items;
    return $self;
}

1;
