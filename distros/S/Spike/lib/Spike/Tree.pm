package Spike::Tree;

use strict;
use warnings;

use base qw(Spike::Object);

use Scalar::Util qw(weaken);

sub new {
    my ($proto, $name) = @_;
    my $class = ref $proto || $proto;

    return $class->SUPER::new(name => $name);
}

sub childs { @{shift->{childs} ||= []} }

sub add_child {
    my ($self, $child) = @_;

    if ($child->parent) {
        return if !$child->parent->rm_child($child);
    }

    push @{$self->{childs} ||= []}, $child;
    weaken($child->{parent} = $self);

    return $self;
}

sub rm_child {
    my ($self, $child) = @_;

    return if !$child->parent || $child->parent != $self;

    $child->{parent} = undef;
    @{$self->{childs}} = grep { $_ != $child } @{$self->{childs} ||= []};

    return $self;
}

__PACKAGE__->mk_accessors(qw(name));
__PACKAGE__->mk_ro_accessors(qw(parent));

1;
