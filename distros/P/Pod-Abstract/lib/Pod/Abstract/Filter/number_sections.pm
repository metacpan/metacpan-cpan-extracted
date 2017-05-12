package Pod::Abstract::Filter::number_sections;
use strict;
use warnings;

use base qw( Pod::Abstract::Filter );
use Pod::Abstract::BuildNode qw(node);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter::number_sections - paf command for basic multipart
section numbering.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;

    my $h1 = 0;
    my @h1 = $pa->select('/head1');
    foreach my $hn1 (@h1) {
        $h1 ++;
        $hn1->param('heading')->unshift(node->text("$h1. "));
        
        my @h2 = $hn1->select('/head2');
        my $h2 = 0;
        foreach my $hn2 (@h2) {
            $h2 ++;
            $hn2->param('heading')->unshift(node->text("$h1.$h2 "));
            
            my @h3 = $hn2->select('/head3');
            my $h3 = 0;
            foreach my $hn3 (@h3) {
                $h3 ++;
                $hn3->param('heading')->unshift(node->text("$h1.$h2.$h3 "));
                
                my @h4 = $hn3->select('/head4');
                my $h4 = 0;
                foreach my $hn4 (@h4) {
                    $h4 ++;
                    $hn4->param('heading')->
                        unshift(node->text("$h1.$h2.$h3.$h4 "));
                }
            }
        }
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
