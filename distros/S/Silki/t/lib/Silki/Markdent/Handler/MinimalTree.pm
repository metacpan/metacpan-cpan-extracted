package Silki::Markdent::Handler::MinimalTree;

use strict;
use warnings;
use namespace::autoclean;

use Markdent::Types qw( Str );
use Tree::Simple;

use Moose;
use MooseX::Params::Validate qw( validated_hash );
use MooseX::SemiAffordanceAccessor;

extends 'Markdent::Handler::MinimalTree';

sub wiki_link {
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        link_text    => { isa => Str },
        display_text => { isa => Str, optional => 1 },
    );

    delete @p{ grep { !defined $p{$_} } keys %p };

    my $link_node = Tree::Simple->new( { type => 'wiki_link', %p } );

    $self->_current_node()->addChild($link_node);
}

sub file_link {
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        link_text    => { isa => Str },
        display_text => { isa => Str, optional => 1 },
    );

    delete @p{ grep { !defined $p{$_} } keys %p };

    my $link_node = Tree::Simple->new( { type => 'file_link', %p } );

    $self->_current_node()->addChild($link_node);
}

sub image_link {
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        link_text => { isa => Str },
    );

    delete @p{ grep { !defined $p{$_} } keys %p };

    my $link_node = Tree::Simple->new( { type => 'image_link', %p } );

    $self->_current_node()->addChild($link_node);
}

__PACKAGE__->meta()->make_immutable();

1;
