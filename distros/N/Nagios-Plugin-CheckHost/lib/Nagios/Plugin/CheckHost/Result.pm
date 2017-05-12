package Nagios::Plugin::CheckHost::Result;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    
    my $nodes = delete $args{nodes} or die "Missed nodes information";
    my %nodes = map {$_->identifier => $_} @$nodes;
    bless {%args, nodes => \%nodes, results => {}}, $class;
}

sub store_result {
    my ($self, $results) = @_;
    foreach my $node (keys %$results) {
        my $node_c = $self->{nodes}{$node} or next;

        my $r = $results->{$node};

        next unless defined $r;
        if (defined $r->[0]) {
            $self->{results}{$node_c} = $r;
        } else {
            delete $self->{nodes}{$node};
        }
    }
}

sub unfinished_nodes {
    my $self = shift;
    my @nodes;

    foreach my $node (values %{$self->{nodes}}) {
        push @nodes, $node unless exists $self->{results}{$node};
    }

    @nodes;
}

sub remove_unfinished_nodes {
    my $self = shift;

    foreach my $node ($self->unfinished_nodes) {
        delete $self->{nodes}{$node->identifier};
    }
}


sub nodes {
    values %{$_[0]->{nodes}};
}

1;
