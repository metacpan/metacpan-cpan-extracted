package MyApp::Controller::Item;
use strict;
use warnings;
use parent 'Pickles::Controller';
use Data::Dumper;sub p {warn Dumper \@_;my @c = caller;print STDERR "  at $c[1]:$c[2]\n\n"}

sub view {}

1;

__END__

