package Pod::Abstract::Filter::uncut;
use strict;
use warnings;

use base qw(Pod::Abstract::Filter);
use Pod::Abstract::BuildNode qw(node);

our $VERSION = '0.26';

=head1 NAME

Pod::Abstract::Filter::uncut - Turn source code into verbatim nodes.

=head1 DESCRIPTION

Takes all cut blocks from the source document, after the first Pod block
starts, and converts them into inline verbatim Pod blocks. The effect of
this is to allow viewing of source code inline with the formatted Pod
documentation describing it.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my @cuts = $pa->select('//#cut[! << #cut]'); # First cut in each run
    
    foreach my $cut (@cuts) {
        next unless $cut->body =~ m/^=cut/;
        my $n = $cut->next;
        while( $n && $n->type eq '#cut' ) {
            my $body = $n->body;
            $body =~ s/\n\s*$//m;
            $cut->push(node->verbatim($body));
            $n->detach;
            $n = $cut->next;
        }
        $cut->hoist;
        $cut->detach;
    }
    $pa->coalesce_body(":verbatim");
    $pa->coalesce_body(":text");

    # Detach/remove any blank verbatim nodes, so we don't have extra
    # empty verbatim blocks to deal with.

    $_->detach foreach $pa->select('//:verbatim[ . =~ {^[\s]*$}]');
    
    return $pa;
}

=head1 AUTHOR

Ben Lilburne <bnej80@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2025 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
