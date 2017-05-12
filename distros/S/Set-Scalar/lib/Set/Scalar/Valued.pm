package Set::Scalar::Valued;

use strict;
local $^W = 1;

use vars qw($VERSION @ISA);

$VERSION = '1.29';
@ISA = qw(Set::Scalar::Base Set::Scalar::Real);

use Set::Scalar::Base qw(_make_elements as_string _strval);
use Set::Scalar::Real;
use Set::Scalar::ValuedUniverse;

use overload
    '""'	=> \&as_string,
    'cmp'	=> \&cmp;

sub ELEMENT_SEPARATOR { ", "   }
sub VALUE_SEPARATOR   { " => " }
sub SET_FORMAT        { "{%s}" }

sub _make_valued_elements {
    my $elements = shift;
    my %elements;

    while (my ($key, $value) = splice @$elements, 0, 2) {
	$elements{ _strval($key) } = [ $key, $value ];
    }

    return %elements;
}

sub _insert_hook {
    my $self     = shift;

    if (@_) {
        my $elements = shift;

        $self->universe->_extend( { _make_elements( map { $_->[0] }
						    values %$elements ) } );
	$self->_insert_elements( $elements );
    }
}

sub _new_hook {
    my $self     = shift;
    my $elements = shift;

    $self->{'universe'} = Set::Scalar::ValuedUniverse->universe;

    $self->_insert( { _make_valued_elements( $elements ) } );
}

sub insert {
    my $self     = shift;

    $self->_insert( { _make_valued_elements \@_ } );
}

sub _valued_elements {
    my $self = shift;

    return @_ ?
	@{ $self->{'elements'} }{ map { _strval($_) } @_ } :
	values %{ $self->{'elements'} };  
}

sub valued_elements {
    my $self = shift;

    return map { @$_ } $self->_valued_elements(@_);
}

*valued_members = \&valued_elements;

sub value {
    my $self   = shift;
    my $member = shift;

    return $self->{'elements'}->{ $member };
}

sub elements {
    my $self = shift;

    return map { $_->[0] } $self->_valued_elements(@_);
}

sub values {
    my $self = shift;

    return map { $_->[1] } $self->_valued_elements(@_);
}

sub _elements_as_string {
    my $self = shift;

    my %valued_elements = $self->valued_elements;
    my $value_separator = $self->_value_separator;

    my @elements = map { $_ .
                         $value_separator . 
                         $valued_elements{$_}
                       } keys %valued_elements;

    return (join($self->_element_separator, sort @elements),
	    $self->_elements_have_reference([%valued_elements]));
}

sub _value_separator {
    my $self = shift;

    return $self->{'display'}->{'value_separator'}
        if exists $self->{'display'}->{'value_separator'};

    my $universe = $self->universe;

    return $universe->{'display'}->{'value_separator'}
        if exists $universe->{'display'}->{'value_separator'};

    return (ref $self)->VALUE_SEPARATOR;
}

sub invert {
    my $self = shift;

    $self->_invert( { _make_valued_elements \@_ } );
}

sub fill {
    die "$0: ", __PACKAGE__, "::fill() inappropriate.\n";
}

=pod

=head1 NAME

Set::Scalar::Valued - valued sets

=head1 SYNOPSIS

    use Set::Scalar::Valued;
    $s = Set::Scalar::Valued->new;
    $s->insert(a => 12, 'b c' => $d);
    $s->delete('b c' => $d);
    $t = Set::Scalar->new(x => $y, y => $z);

=head1 DESCRIPTION

Valued sets are an extension of the traditional set concept.  In
addition to a member just existing in the set, the member also has a
distinct value.  You can think of this a combination of a traditional
set and a Perl hash.

The used methods are as for the traditional of Set::Scalar, with
the difference that when creating (new()) or modifying (insert(),
delete(), invert()), you must supply twice the number of arguments:
the member-value pairs, instead of just the members.  Note, though,
that in the current implementation of delete() the value half is
unused, the deletion is by the member.  In future implementation
this behavior may change so that also the value matters.

There are a couple of additional methods:

    %ve = $s->valued_members;

which returns the member-value pairs, and

    @v  = $s->values;

which returns just the values (in the same order as the members()
method would return the members), and

    $v  = $s->value($member);

which returns the value of the member.

The display format of a valued set is the member-value pairs separated
by " => ", the pairs separated by ", " and enclosed in curly brackets {}.

=head1 AUTHOR

Jarkko Hietaniemi <jhi@iki.fi>

=cut

1;
