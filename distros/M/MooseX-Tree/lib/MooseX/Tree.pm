package MooseX::Tree;

# ABSTRACT: Moose Role to provide simple hierarchical tree functionality to objects

our $VERSION = '0.001'; # VERSION

use MooseX::Role::Parameterized;

our $DESCEND_ORDER = 'pre';    # default

parameter parent_link =>       #
    ( is => 'ro', isa => 'Str', default => 'parent' );
parameter parent_type =>       #
    ( is => 'ro', isa => 'Str', default => 'Object' );

parameter children_link =>
    ( is => 'ro', isa => 'Str', default => 'children' );
parameter children_type =>     #
    ( is => 'ro', isa => 'Str', default => 'Object' );

parameter ancestors_method =>
    ( is => 'ro', isa => 'Str', default => 'ancestors' );
parameter descendants_method =>
    ( is => 'ro', isa => 'Str', default => 'descendants' );

role {
    my $parent        = $_[0]->parent_link;
    my $parent_type   = $_[0]->parent_type;
    my $children      = $_[0]->children_link;
    my $children_type = $_[0]->children_type;
    my $ancestors     = $_[0]->ancestors_method;
    my $descendants   = $_[0]->descendants_method;

    my $pre_method   = "${descendants}_pre_order";
    my $post_method  = "${descendants}_post_order";
    my $level_method = "${descendants}_level_order";
    my $group_method = "${descendants}_group_order";

    has $parent => (    #
        is  => 'rw',
        isa => "Maybe[$parent_type]",
    );
    has $children => (
        is      => 'rw',
        isa     => "ArrayRef[$children_type]",
        default => sub { [] },
    );

    method "add_$children" => sub {
        my ( $self, @add ) = @_;

        push @{ $self->$children }, @add;

        return $self;
    };

    method $ancestors => sub {
        my ($self) = @_;

        my @ancestors
            = $self->parent
            ? ( $self->parent, $self->parent->ancestors )
            : ();

        return @ancestors;
    };

    method $descendants => sub {
        my ( $self, %args ) = @_;

        my $order = $args{order} || $DESCEND_ORDER;

        return
              $order eq 'pre'   ? $self->$pre_method
            : $order eq 'post'  ? $self->$post_method
            : $order eq 'level' ? $self->$level_method
            : $order eq 'group' ? $self->$group_method
            :                     die "Unknown descend order: $order";
    };

    method $pre_method => sub {
        return map { $_, $_->$pre_method() } @{ shift->$children };
    };

    method $post_method => sub {
        return map { $_->$post_method(), $_ } @{ shift->$children };
    };

    method $level_method => sub {
        my $self = shift;

        my @list;
        my @queue = @{ $self->$children };

        while ( my $node = shift @queue ) {
            push @list,  $node;
            push @queue, @{ $node->$children };
        }
        return @list;
    };

    method $group_method => sub {
        my $self = shift;

        my @list;
        my @queue = map { [ 0, $_ ] } @{ $self->$children };

        while ( my ( $level, $node ) = @{ shift(@queue) || [] } ) {
            push @{ $list[$level] }, $node;
            push @queue, map { [ $level + 1, $_ ] } @{ $node->$children };
        }
        return @list;
    };
};


1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Tree - Moose Role to provide simple hierarchical tree functionality to objects

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package My::Node;
    
    use Moose;
    with 'MooseX::Tree';
    
    ... then: ...
    
    my $node = My::Node->new();
    
    my $parent      = $node->parent;
    my @children    = $node->children;
    my @ancestors   = $node->ancestors;
    my @descendants = $node->descendants;

=head1 DESCRIPTION

Under development.

Moose Role to provide simple tree functionality.

=head1 METHODS

Note: method names can be overridden by providing parameters when consuming
this role.

=head2 parent

=head2 children

=head2 ancestors

=head2 descendants

=head1 TODO

=over

=item *

Document and test role parameters (to set attribute/method names)

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/moosex-tree/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/moosex-tree>

  git clone git://github.com/mjemmeson/moosex-tree.git

=head1 AUTHOR

Michael Jemmeson <mjemmeson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Jemmeson <mjemmeson@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
