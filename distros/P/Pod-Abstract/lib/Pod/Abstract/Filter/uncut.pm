package Pod::Abstract::Filter::uncut;
use strict;
use warnings;

use base qw(Pod::Abstract::Filter);
use Pod::Abstract::BuildNode qw(node);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter::uncut - paf command to turn source code into
verbatim nodes.

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
            $cut->push(node->verbatim($n->body));
            $n->detach;
            $n = $cut->next;
        }
        $cut->coalesce_body(':verbatim');
        $cut->hoist;
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
