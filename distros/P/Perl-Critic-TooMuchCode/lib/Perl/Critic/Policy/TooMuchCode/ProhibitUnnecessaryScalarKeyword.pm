package Perl::Critic::Policy::TooMuchCode::ProhibitUnnecessaryScalarKeyword;
use strict;
use warnings;

use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw(maintenance)    }
sub applies_to           { return 'PPI::Token::Word' }

sub violates {
    my ( $self, $elem, undef ) = @_;
    return unless $elem->content eq 'scalar';
    my $e = $elem->snext_sibling;
    return unless $e && $e->isa('PPI::Token::Symbol') && $e->raw_type eq '@';
    $e = $elem->sprevious_sibling;
    return unless $e && $e->isa('PPI::Token::Operator') && $e->content eq '=';
    $e = $e->sprevious_sibling;
    return unless $e && $e->isa('PPI::Token::Symbol') && $e->raw_type eq '$';

    return $self->violation('Unnecessary scalar keyword', "Assigning an array to a scalar implies scalar context.", $elem);
}

1;

__END__

=head1 NAME

TooMuchCode::ProhibitUnnecessaryScalarKeyword - Finds `scalar` in scalar context.

=head1 DESCRIPTION

This policy dictates that the use of `scalar` for in statement like this needs to be removed:

    my $n = scalar @items;

If the left-hand side of assigiment is a single scalar variable, then the assignment is in scalar
contetx. There is no need to add C<scalar> keyword.

1;
