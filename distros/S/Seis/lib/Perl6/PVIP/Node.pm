package Perl6::PVIP::Node;
use strict;
use warnings;

# most of methods are written in xs.

sub perl {
    my $self = shift;
    +{
        type        => $self->type,
        line_number => $self->line_number,
        value       => do {
            if ($self->category == Perl6::PVIP::PVIP_CATEGORY_CHILDREN()) {
                [map { $_->perl } @{$self->value}];
            } else {
                $self->value;
            }
        }
    };
}

1;

__END__

=head1 NAME

Perl6::PVIP::Node - Node object

=head1 DESCRIPTION

This is a node representation in Perl6::PVIP.

=head1 METHODS

=over 4

=item $node->type()

This method returns the method type in C<PVIP_NODE_*> constants.

=item $node->name()

String representation of the type from the node.

=item $node->value() : Str|Int|Number|ArrayRef[Perl6::PVIP::Node]

This method returns the value, the node has.


=item $node->as_sexp(): Str

This method converts the node as S-Expression.

=item $node->category() : Int

This method returns the category of the node.
It's one of the following

=over 4

=item PVIP_CATEGORY_INT

=item PVIP_CATEGORY_NUMBER

=item PVIP_CATEGORY_STRING

=item PVIP_CATEGORY_CHILDREN

=item PVIP_CATEGORY_UNKNOWN

=back

=back
