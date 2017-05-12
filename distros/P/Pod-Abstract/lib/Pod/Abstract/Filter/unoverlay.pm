package Pod::Abstract::Filter::unoverlay;
use strict;
use warnings;

use base qw(Pod::Abstract::Filter);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter::unoverlay - paf command to remove "overlay" blocks
from a Pod document, as created by the paf overlay command.

=begin :overlay

=overlay METHODS Pod::Abstract::Filter

=end :overlay

=head1 METHODS

=head2 new

=for overlay from Pod::Abstract::Filter

=head2 filter

Strips any sections marked C<=for overlay> from the listed overlay
specification from the target document. This will expunge everything
that has been previously overlaid or marked for overlay from the
specified documents.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my ($overlay_list) = $pa->select("//begin[. =~ {^:overlay}](0)");
    unless($overlay_list) {
        die "No overlay defined in document\n";
    }
    my @overlays = $overlay_list->select("/overlay");
    foreach my $overlay (@overlays) {
        my $o_def = $overlay->body;
        my ($section, $module) = split " ", $o_def;
        
        my ($t) = $pa->select("//[\@heading =~ {$section}](0)");
        my @t_headings = $t->select("/[\@heading]");
        foreach my $hdg (@t_headings) {
            my @overlay_from = 
                $hdg->select(
                    "/for[. =~ {^overlay from }]");
            my @from_current = grep {
                substr($_->body, -(length $module)) eq $module
            } @overlay_from;
            if(@from_current) {
                $hdg->detach;
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
