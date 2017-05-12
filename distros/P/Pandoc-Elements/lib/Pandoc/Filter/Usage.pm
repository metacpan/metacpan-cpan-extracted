package Pandoc::Filter::Usage;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.26';

sub pod2usage {
    my %opt = ref $_[0] ? %{$_[0]} : @_;
    
    $opt{exitval} //= 0;

    ## no critic
    my $module = -t STDOUT ? 'Pod::Text::Termcap' : 'Pod::Text';
    eval "require $module" or die "Can't locate $module in \@INC\n";
    $module->new( indent => 2, nourls => 1 )->parse_file($0);

    exit $opt{exitval} if $opt{exitval} ne 'NOEXIT';
}

1;

=head1 NAME

Pandoc::Filter::Usage - print filter documentation from embedded Pod

=head1 DESCRIPTION

This module is deprecated. Please remove references to it from your scripts and
use L<Pod::Usage> instead.

=cut
