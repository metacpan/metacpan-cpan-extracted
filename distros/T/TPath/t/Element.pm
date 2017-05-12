# our basic tree element for use in testing

package Element;

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Moose;

use overload '""' => sub { $_[0]->to_string }, fallback => 1;

has tag => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has children => (
    is         => 'ro',
    isa        => 'ArrayRef[Element]',
    default    => sub { [] },
    auto_deref => 1,
);

has attributes => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    default => sub { {} },
);

has parent => (
    is       => 'ro',
    isa      => 'Maybe[Element]',
    weak_ref => 1,
    required => 1,
);

has id => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { refaddr $_[0] },
);

sub to_string {
    my $self = shift;
    my $s    = '<' . $self->tag;
    while ( my ( $k, $v ) = each %{ $self->attributes } ) {
        $s .= " $k=\"$v\"";
    }
    my @children = @{ $self->children };
    if (@children) {
        $s .= '>';
        $s .= $_ for @children;
        $s .= '</' . $self->tag . '>';
    }
    else {
        $s .= '/>';
    }
    return $s;
}

sub child {
    my ( $self, $i, $child ) = @_;
    $self->children->[$i] = $child if defined $child;
    return $self->children->[$i];
}

sub attribute {
    my ( $self, $key, $value ) = @_;
    $self->attributes->{$key} = $value if defined $value;
    return $self->attributes->{$key};
}

sub has_attribute {
    my ( $self, $key ) = @_;
    return exists $self->attributes->{$key};
}

# complete sub-tree identity
sub equals {
    my ( $self, $other ) = @_;
    return unless blessed $other;
    return unless $other->isa('Element');
    return unless $self->tag eq $other->tag;
    my %own_attributes   = %{ $self->attributes };
    my %other_attributes = %{ $other->attributes };
    return unless scalar keys %other_attributes == scalar keys %own_attributes;
    for my $k ( keys %own_attributes ) {
        return unless exists $other_attributes{$k};
        my $o1 = $own_attributes{$k};
        my $o2 = $other_attributes{$k};
        return if ( ( defined $o1 ) ^ ( defined $o2 ) );
        if ( defined $o1 ) {
            return unless $o1 eq $o2;
        }
    }
    my @own_children   = $self->children;
    my @other_children = $other->children;
    return unless @own_children == @other_children;
    for my $i ( 0 .. $#own_children ) {
        my $o1 = $own_children[$i];
        my $o2 = $other_children[$i];
        return unless $o1->equals($o2);
    }
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
