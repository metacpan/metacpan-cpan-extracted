package Pod::Abstract::Filter::summary;
use strict;

use base qw(Pod::Abstract::Filter);
use Pod::Abstract::BuildNode qw(node);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter::summary - paf command to show document outline,
with short examples.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my $summary = node->root;
    my $summ_block = node->head1('Summary');
    $summary->nest($summ_block);
    
    $self->summarise_headings($pa,$summ_block);
    $summ_block->nest(node->text("\n"));
    $summ_block->coalesce_body(':text');
    
    return $summary;
}

sub summarise_headings {
    my $self = shift;
    my $pa = shift;
    my $summ_block = shift;
    my $depth = shift;
    $depth = 1 unless defined $depth;
    
    my @headings = $pa->select('/[@heading]');
    my @items = $pa->select('/over/item[@label =~ {[a-zA-Z]+}]'); # Labels that have strings
    
    unshift @headings, @items;
    
    foreach my $head (@headings) {
        my ($hdg) = $head->select('@heading');
        if($head->type eq 'item') {
            ($hdg) = $head->select('@label');
        }
        my $hdg_text = $hdg->text;
        $summ_block->push(
            node->text(("  " x $depth) . $hdg_text . "\n")
            );
        if($hdg_text =~ m/^[0-9a-zA-Z_ ]+$/) {
            my ($synopsis) = $head->select("//:verbatim[. =~ {$hdg_text}](0)");
            if($synopsis) {
                my $synop_body = $synopsis->body;
                $synop_body =~ s/[\r\n]//sg;
                $synop_body =~ s/[\t ]+/ /g;
                $synop_body =~ s/^ //g;
                
                $summ_block->push(
                    node->text(
                        ("  " x $depth) . " \\ " . $synop_body . "\n"
                    )
                );
            }
        }
            
        $self->summarise_headings($head, $summ_block, $depth + 1);
    }
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
