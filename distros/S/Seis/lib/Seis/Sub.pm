package Seis::Sub;
use strict;
use warnings;
use utf8;
use 5.010_001;

package # Hide from PAUSE
    Sub;

use B;

sub _new {
    my ($class, $code) = @_;
    bless {code => $code}, $class;
}

sub name {
    my $self = shift;
    my $coderef = $self->{code};
    my $b       = B::svref_2object($coderef);
    my $cvflags = $b->CvFLAGS;
    '&'.join('::', $b->GV->STASH->NAME, $b->GV->NAME);
}

sub nextwith {
    my $code = shift;
    goto $code;
}

1;
__END__

=head1 NAME

Sub - The subroutine class
