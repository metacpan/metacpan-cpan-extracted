package Net::IMAP::Server::Command::Lsub;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command::List/;

sub traverse {
    my $self  = shift;
    my $node  = shift;
    my $regex = shift;

    $self->list_out($node) if $node->parent and $node->full_path =~ $regex and $node->subscribed;
    my @kids = grep {$_} map {$self->traverse( $_, $regex )} @{ $node->children };
    if (@kids and $node->parent and not $node->subscribed) {
        if ($node->full_path =~ $regex) {
            $self->list_out($node, '\NoSelect');
            return 0;
        } else {
            return 1;
        }
    }
    return 1 if $node->parent and not $node->full_path =~ $regex and $node->subscribed;
    return 0;
}

1;
