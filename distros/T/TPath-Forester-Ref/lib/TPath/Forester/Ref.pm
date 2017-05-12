package TPath::Forester::Ref;
{
  $TPath::Forester::Ref::VERSION = '0.004';
}

# ABSTRACT: L<TPath::Forester> that understands Perl structs


use v5.10;
use Moose;
use Moose::Util qw(apply_all_roles);
use Moose::Exporter;
use MooseX::MethodAttributes;
use namespace::autoclean;
use TPath::Forester::Ref::Node;
use TPath::Forester::Ref::Expression;

Moose::Exporter->setup_import_methods( as_is => [ tfr => \&tfr ], );


with 'TPath::Forester' => { -excludes => 'wrap' };

sub children { @{ $_[1]->children } }

sub tag { $_[1]->tag }


sub array : Attr { $_[1]->n->type eq 'array' ? 1 : undef; }


sub obj_can : Attr(can) {
    my ( undef, $ctx, $method ) = @_;
    $ctx->n->type eq 'object' && $ctx->n->value->can($method) ? 1 : undef;
}


sub code : Attr { $_[1]->n->type eq 'code' ? 1 : undef }


sub obj_defined : Attr(defined) { defined $_[1]->n->value ? 1 : undef }


sub obj_does : Attr(does) {
    my ( undef, $ctx, $role ) = @_;
    $ctx->n->type eq 'object' && $ctx->n->value->does($role) ? 1 : undef;
}


sub glob : Attr { $_[1]->n->type eq 'glob' ? 1 : undef }


sub hash : Attr { $_[1]->n->type eq 'hash' ? 1 : undef }


sub obj_isa : Attr(isa) {
    my ( undef, $ctx, @classes ) = @_;
    return undef unless $ctx->n->type eq 'object';
    for my $class (@classes) {
        return 1 if $ctx->n->value->isa($class);
    }
    undef;
}


sub key : Attr { $_[1]->n->tag }


sub num : Attr { $_[1]->n->type eq 'num' ? 1 : undef }


sub obj : Attr { $_[1]->n->type eq 'object' ? 1 : undef }


sub is_ref : Attr(ref) { $_[1]->n->is_ref ? 1 : undef }


sub is_non_ref : Attr(non-ref) { $_[1]->n->is_ref ? undef : 1 }


sub repeat : Attr {
    my ( undef, $ctx, $index ) = @_;
    my $reps = $ctx->n->is_repeated;
    return undef unless defined $reps;
    return $reps ? 1 : undef unless defined $index;
    $ctx->n->is_repeated == $index ? 1 : undef;
}


sub repeated : Attr { defined $_[1]->n->is_repeated ? 1 : undef }


sub is_scalar : Attr(scalar) { $_[1]->n->type eq 'scalar' ? 1 : undef }


sub str : Attr { $_[1]->n->type eq 'string' ? 1 : undef }


sub is_undef : Attr(undef) { $_[1]->n->type eq 'undef' ? 1 : undef }


{
    no warnings 'redefine';

    sub wrap {
        my ( $self, $n ) = @_;
        return $n if blessed($n) && $n->isa('TPath::Forester::Ref::Node');
        coerce($n);
    }
}

around path => sub {
    my ( $orig, $self, $expr ) = @_;
    my $path = $self->$orig($expr);
    bless $path, 'TPath::Forester::Ref::Expression';
};

# acquaints all the nodes in a tree with their root
sub coerce {
    my ( $ref, $root, $tag ) = @_;
    my $node;
    if ($root) {
        $node = TPath::Forester::Ref::Node->new(
            value => $ref,
            _root => $root,
            tag   => $tag,
        );
    }
    else {
        $root = TPath::Forester::Ref::Node->new( value => $ref, tag => undef );
        apply_all_roles( $root, 'TPath::Forester::Ref::Root' );
        $root->_add_root($root);
        $node = $root;
    }
    $root->_cycle_check($node);
    return $node if $node->is_repeated;
    for ( $node->type ) {
        when ('hash') {
            for my $key ( sort keys %$ref ) {
                push @{ $node->children }, coerce( $ref->{$key}, $root, $key );
            }
        }
        when ('array') {
            push @{ $node->children }, coerce( $_, $root ) for @$ref;
        }
    }
    return $node;
}


sub tfr() { state $singleton = TPath::Forester::Ref->new }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

TPath::Forester::Ref - L<TPath::Forester> that understands Perl structs

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use TPath::Forester::Ref;
  use Data::Dumper;
  
  my $ref = {
      a => [],
      b => {
          g => undef,
          h => { i => [ { l => 3, 4 => 5 }, 2 ], k => 1 },
          c => [qw(d e f)]
      }
  };
  
  my @hashes = tfr->path(q{//@hash})->dsel($ref);
  print scalar @hashes, "\n"; # 3
  my @arrays = tfr->path(q{//@array})->dsel($ref);
  print scalar @arrays, "\n"; # 3
  print Dumper $arrays[2];    # hash keys are sorted alphabetically
  # $VAR1 = [
  #           {
  #             'l' => 3,
  #             '4' => 5
  #           },
  #           2
  #         ];

=head1 DESCRIPTION

C<TPath::Forester::Ref> adapts L<TPath::Forester> to run-of-the-mill Perl
data structures.

=head1 METHODS

=head2 C<@array>

Whether the node is an array ref.

=head2 C<@can('method')>

Attribute that is defined if the node in question has the specified method.

=head2 C<@code>

Attribute that is defined if the node is a code reference.

=head2 C<@defined>

Attribute that is defined if the node is a defined value.

=head2 C<@does('role')>

Attribute that is defined if the node does the specified role.

=head2 C<@glob>

Attribute that is defined if the node is a glob reference.

=head2 C<@hash>

Attribute that is defined if the node is a hash reference.

=head2 C<@isa('Foo','Bar')>

Attribute that is defined if the node instantiates any of the specified classes.

=head2 C<@key>

Attribute that returns the hash key, if any, associated with the node value.

=head2 C<@num>

Attribute defined for nodes whose value looks like a number according to L<Scalar::Util>.

=head2 C<@obj>

Attribute that is defined for nodes holding objects.

=head2 C<@ref>

Attribute defined for nodes holding references such as C<{}> or C<[]>.

=head2 C<@non-ref>

Attribute that is defined for nodes holding non-references -- C<undef>, strings,
or numbers.

=head2 C<@repeat> or C<@repeat(1)>

Attribute that is defined if the node holds a reference that has occurs earlier
in the tree. If a parameter is supplied, it is defined if the node in question
is the specified repetition of the reference, where the first instance is repetition
0.

=head2 C<@repeated>

Attribute that is defined for any node holding a reference that occurs more than once
in the tree.

=head2 C<@scalar>

Attribute that is defined for any node holding a scalar reference.

=head2 C<@str>

Attribute that is defined for any node holding a string.

=head2 C<@undef>

Attribute that is defined for any node holding the C<undef> value.

=head2 wrap

Takes a reference and converts it into a tree, overriding L<TPath::Forester>'s no-op C<wrap>
method.

  my $tree = tfr->wrap(
      { foo => bar, baz => [qw(1 2 3 4)], qux => { quux => { corge => undef } } }
  );

This is useful if you are going to be doing multiple selections from a single
struct and want to use a common index. If you B<don't> use C<wrap> to work off
a common object your index will give strange results as it won't be able to
find the parents of your nodes.

=head1 FUNCTIONS

=head2 tfr

Returns singleton C<TPath::Forester::Ref>.

=head1 ROLES

L<TPath::Forester>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
