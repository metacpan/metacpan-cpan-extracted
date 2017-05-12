package TPath::Selector::Predicated;
$TPath::Selector::Predicated::VERSION = '1.007';
# ABSTRACT: role of selectors that have predicates


use v5.10;

use Moose::Role;
use TPath::TypeConstraints;
use TPath::Test::Node::Complement;


with 'TPath::Selector';


has predicates => (
    is         => 'ro',
    isa        => 'ArrayRef[TPath::Predicate]',
    default    => sub { [] },
    auto_deref => 1
);


sub apply_predicates {
    my ( $self, @candidates ) = @_;
    for my $p ( $self->predicates ) {
        last unless @candidates;
        @candidates = $p->filter( \@candidates );
    }
    return @candidates;
}

around 'to_string' => sub {
    my ( $orig, $self, @args ) = @_;
    my $s = $self->$orig(@args);
    for my $p ( $self->predicates ) {
        $p = $p->to_string;
        $s .= $p =~ /[\s()]/ ? "[ $p ]" : "[$p]";
    }
    return $s;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Predicated - role of selectors that have predicates

=head1 VERSION

version 1.007

=head1 DESCRIPTION

A L<TPath::Selector> that holds a list of L<TPath::Predicate>s.

=head1 ATTRIBUTES

=head2 predicates

Auto-deref'ed list of L<TPath::Predicate> objects that filter anything selected
by this selector.

=head1 METHODS

=head2 apply_predicates

Expects a list of L<TPath::Context> objects. Applies each predicate to this in turn
and returns the filtered list.

=head1 ROLES

L<TPath::Selector>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
