#line 1
package Test::Builder::TodoDiag;
use strict;
use warnings;

our $VERSION = '1.302175';

BEGIN { require Test2::Event::Diag; our @ISA = qw(Test2::Event::Diag) }

sub diagnostics { 0 }

sub facet_data {
    my $self = shift;
    my $out = $self->SUPER::facet_data();
    $out->{info}->[0]->{debug} = 0;
    return $out;
}

1;

__END__

#line 68
