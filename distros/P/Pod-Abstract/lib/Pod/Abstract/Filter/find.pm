package Pod::Abstract::Filter::find;
use strict;
use warnings;

use base qw(Pod::Abstract::Filter);
use Pod::Abstract::BuildNode qw(node);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter::find - paf command to find specific nodes that
contain a string.

=head1 DESCRIPTION

The intention of this filter is to allow a reduction of large Pod
documents to find a specific function or method. You call C<paf find
-f=function YourModule>, and you get a small subset of nodes matching
"function".

For this to work, there has to be some assumptions about Pod structure. I
am presuming that find is not useful if it returns anything higher than a
head2, so as long as your module wraps function doco in a head2, head3,
head4 or list item, we're fine. If you use head1 then it won't be useful.

In order to be useful as an end user tool, head1 nodes (...) are added
between the found nodes. This stops perldoc from dying with no
documentation. These can be easily stripped using:
C<< $pa->select('/head1') >>, then hoist and detach, or reparent to other
Node types.

A good example of this working as intended is:

 paf find select Pod::Abstract::Node

=cut

sub require_params {
    return ( 'f' );
}

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my $find_string = $self->param('f');
    unless($find_string && $find_string =~ m/^[a-zA-Z0-9_]+$/) {
        die "find: string must be specified with -f=str.\nMust be a simple string.\n";
    }
    
    my $out_doc = node->root;
    $out_doc->nest(node->pod);
    
    # Don't select parent nodes, leaf nodes only
    my @targets = $pa->select("//[. =~ {$find_string}][!/]");
    
    # Don't accept anything less specific than a head2
    my @dest_ok = qw(head2 head3 head4 item);
    
    my %finals = ( );
    
    foreach my $t (@targets) {
        while($t->parent && !( grep { $t->type eq $_ } @dest_ok )) {
            $t = $t->parent;
        }
        if(grep { $t->type eq $_ } @dest_ok) {
            unless($finals{$t->serial}) {
                my $head = node->head1('...');
                if($t->type eq 'item') {
                    my $over = node->over;
                    $over->nest($t->duplicate);
                    $head->nest($over);
                } else {
                    $head->nest($t->duplicate);
                }
                $out_doc->push($head);
                $finals{$t->serial} = 1;
            }
        }
    }
    
    return $out_doc;
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
