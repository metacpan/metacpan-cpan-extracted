# makes sure stringification of an expression is semantically identical to the original

use v5.10;
use strict;
use warnings;
no if $] >= 5.018, warnings => "experimental";

use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;
use Test::Exception;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;

my ( $path, $p, @elements );

$p        = parse(q{<a><b><aa/></b><b><bb/></b></a>});
$path     = q{//b[~..~ = ~a~]};
@elements = $f->path($path)->select($p);
is @elements, 1, "found expected number of elements with $path on $p";
is $elements[0], '<b><aa/></b>', 'found correct element';

{
    package Node;

    sub new {
        my $class = shift;
        bless { @_, children => [] }, $class;
    }

    sub tag      { $_[0]->{tag} }
    sub children { $_[0]->{children} }
    sub payload  { $_[0]->{payload} }
    sub add      { my $self = shift; push @{ $self->children }, @_; $self }

    sub eql {
        my ( $self, $left, $right ) = @_;
        return if defined $left ^ defined $right;
        return 1 unless defined $left;
        my ( $lt, $rt ) = map { ref $_ } $left, $right;
        if ( $lt eq $rt ) {
            for ( $lt ) {
                when ('HASH') {
                    my @k1 = keys %$left;
                    return unless @k1 == keys %$right;
                    for my $k (@k1) {
                        return unless exists $right->{$k};
                        return unless $self->eql( $left->{$k}, $right->{$k} );
                    }
                    return 1;
                }
                when ('ARRAY') {
                    my @a1 = @$left;
                    my @a2 = @$right;
                    return unless @a1 == @a2;
                    for my $i ( 0 .. $#a1 ) {
                        return unless $self->eql( $a1[$i], $a2[$i] );
                    }
                    return 1;
                }
                default { return $left eq $right }
            }
        }
        return;
    }
}

{
    package Node1;
    use base 'Node';

    sub equals {
        my ( $self, $other ) = @_;
        return $self->tag eq $other->tag
          && $self->eql( $self->payload, $other->payload );
    }
}
{
    package Node2;
    use base 'Node';
    
    use overload '==' => sub {
        my ( $self, $other ) = @_;
        return $self->tag eq $other->tag
          && $self->eql( $self->payload, $other->payload );
    };
}

{

    package Forester;
    use Moose;
    use MooseX::MethodAttributes;
    with 'TPath::Forester';

    sub children {
        my ( $self, $n ) = @_;
        @{ $n->{children} };
    }

    sub tag {
        my ( $self, $n ) = @_;
        $n->{tag};
    }

    sub p : Attr {
        my ( undef, $ctx ) = @_;
        $ctx->n->payload;
    }

}

$f = Forester->new;

# with no definition of semantic equality
my $tree = Node->new( tag => 'b', payload => [1] )->add(
    Node->new( tag => 'b', payload => [2] )->add(
        Node->new( tag => 'a', payload => { c => 1 } )
          ->add( Node->new( tag => 'a', payload => { c => 1 } ) )
    )
);
$path     = q{//*[. = *]};
@elements = $f->path($path)->select($tree);
is @elements, 0, "received expected number of elements with $path";
$path     = q{//*[. == *]};
@elements = $f->path($path)->select($tree);
is @elements, 0, "received expected number of elements with $path";

my $payload = {foo=>'bar'};
$tree = Node->new( tag => 'b', payload => $payload )->add(
    Node->new( tag => 'b', payload => $payload )->add(
        Node->new( tag => 'a', payload => { c => 1 } )
          ->add( Node->new( tag => 'a', payload => { c => 1 } ) )
    )
);
$path     = q{//*[@at(., 'p') = @at(*, 'p')]};
@elements = $f->path($path)->select($tree);
is @elements, 2, "received expected number of elements with $path";
is $elements[0]->tag, 'b', 'expected tag for first element received';
is $elements[1]->tag, 'a', 'expected tag for first element received';
$path     = q{//*[@at(., 'p') == @at(*, 'p')]};
@elements = $f->path($path)->select($tree);
is @elements, 1, "received expected number of elements with $path";
is $elements[0]->tag, 'b', 'expected tag for element received';

# with 'equals' semantic equal
$tree = Node1->new( tag => 'b', payload => [1] )->add(
    Node1->new( tag => 'b', payload => [2] )->add(
        Node1->new( tag => 'a', payload => { c => 1 } )
          ->add( Node1->new( tag => 'a', payload => { c => 1 } ) )
    )
);
$path     = q{//*[. = *]};
@elements = $f->path($path)->select($tree);
is @elements, 1, "received expected number of elements with $path";
is $elements[0]->tag, 'a', 'expected tag for element received';
$path     = q{//*[. == *]};
@elements = $f->path($path)->select($tree);
is @elements, 0, "received expected number of elements with $path";

$tree = Node1->new( tag => 'b', payload => $payload )->add(
    Node1->new( tag => 'b', payload => $payload )->add(
        Node1->new( tag => 'a', payload => { c => 1 } )
          ->add( Node1->new( tag => 'a', payload => { c => 1 } ) )
    )
);
$path     = q{//*[@at(., 'p') = @at(*, 'p')]};
@elements = $f->path($path)->select($tree);
is @elements, 2, "received expected number of elements with $path";
is $elements[0]->tag, 'b', 'expected tag for first element received';
is $elements[1]->tag, 'a', 'expected tag for first element received';
$path     = q{//*[@at(., 'p') == @at(*, 'p')]};
@elements = $f->path($path)->select($tree);
is @elements, 1, "received expected number of elements with $path";
is $elements[0]->tag, 'b', 'expected tag for element received';

# with overloaded == semantic equality
$tree = Node2->new( tag => 'b', payload => [1] )->add(
    Node2->new( tag => 'b', payload => [2] )->add(
        Node2->new( tag => 'a', payload => { c => 1 } )
          ->add( Node2->new( tag => 'a', payload => { c => 1 } ) )
    )
);
$path     = q{//*[. = *]};
@elements = $f->path($path)->select($tree);
is @elements, 1, "received expected number of elements with $path";
is $elements[0]->tag, 'a', 'expected tag for element received';
$path     = q{//*[. == *]};
@elements = $f->path($path)->select($tree);
is @elements, 0, "received expected number of elements with $path";

$tree = Node2->new( tag => 'b', payload => $payload )->add(
    Node2->new( tag => 'b', payload => $payload )->add(
        Node2->new( tag => 'a', payload => { c => 1 } )
          ->add( Node2->new( tag => 'a', payload => { c => 1 } ) )
    )
);
$path     = q{//*[@at(., 'p') = @at(*, 'p')]};
@elements = $f->path($path)->select($tree);
is @elements, 2, "received expected number of elements with $path";
is $elements[0]->tag, 'b', 'expected tag for first element received';
is $elements[1]->tag, 'a', 'expected tag for first element received';
$path     = q{//*[@at(., 'p') == @at(*, 'p')]};
@elements = $f->path($path)->select($tree);
is @elements, 1, "received expected number of elements with $path";
is $elements[0]->tag, 'b', 'expected tag for element received';

done_testing();
