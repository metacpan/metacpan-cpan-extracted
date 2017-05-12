package Pod::Abstract::Filter::cut;
use strict;
use warnings;

use base qw(Pod::Abstract::Filter);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter::cut - paf command to remove non-processed (cut)
portions of a Pod document.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my @cut = $pa->select("//#cut");
    foreach my $cut (@cut) {
        $cut->detach;
    }
    
    return $pa;
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
