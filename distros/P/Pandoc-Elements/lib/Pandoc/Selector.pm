package Pandoc::Selector;
use strict;
use warnings;
use 5.010001;

use Pandoc::Elements;

my $IDENTIFIER = qr{[\p{L}\p{N}_-]+};
my $NAME       = qr{[A-Za-z]+};

sub new {
    my ($class, $selector) = @_;
    # TODO: compile selector
    bless { selector => $selector }, $class;
}

sub match {
    my ($self, $element) = @_;

    foreach my $selector ( split /\|/, $self->{selector} ) {
        return 1 if _match_expression($selector, $element);
    }

    return 0;
}

sub _match_expression {
    my ( $selector, $elem ) = @_;
    $selector =~ s/^\s+|\s+$//g;

    # name
    return 0
      if $selector =~ s/^($NAME)\s*//i and lc($1) ne lc( $elem->name );
    return 1 if $selector eq '';

    # type
    if ( $selector =~ s/^:(document|block|inline|meta)\s*// ) {
        my $method = "is_$1";
        return 0 unless $elem->$method;
        return 1 if $selector eq '';
    }

    # TODO: :method (e.g. :url)

    # TODO: [:level=1]

    # TODO [<number>]

    # TODO [@<attr>]

    # id and/or classes
    return 0 unless $elem->isa('Pandoc::Document::AttributesRole');
    return _match_attributes($selector, $elem);
}

# check #id and .class
sub _match_attributes {
    my ( $selector, $elem ) = @_;

    $selector =~ s/^\s+|\s+$//g; # trim

    while ( $selector ne '' ) {
        if ( $selector =~ s/^#($IDENTIFIER)\s*// ) {
            return 0 unless $elem->id eq $1;
        }
        elsif ( $selector =~ s/^\.($IDENTIFIER)\s*// ) {
            return 0 unless grep { $1 eq $_ } @{ $elem->attr->[1] };
        }
        else {
            return 0;
        }
    }

    return 1;
}

1;
__END__

=head1 NAME

Pandoc::Selector - Pandoc document selector language

=head1 SYNOPSIS

  my $selector = Pandoc::Selector->new('Code.perl|CodeBlock.perl');

  # check whether an element matches
  $selector->match($element);

  # use as element method
  $element->match('Code.perl|CodeBlock.perl')

=head1 DESCRIPTION

Pandoc::Selector provides a language to select elements of a Pandoc document.
It borrows ideas from L<CSS Selectors|https://www.w3.org/TR/selectors-3/>,
L<XPath|https://www.w3.org/TR/xpath/> and similar languages.

The language is being developed together with this implementation.

=head1 EXAMPLES

  Header#main
  Code.perl
  Code.perl.raw
  :inline

=head1 SELECTOR GRAMMAR

Whitespace between parts of the syntax is optional and not included in the
following grammar. A B<Selector> is a list of one or more B<expression lists>
separated by pipes (C<|>). For instance the selector C<Subscript|Superscript>
selects both Subscript elements and Superscript elements.

  Selector        ::= ExpressionList ( '|' ExpressionList )*

An B<expression list> is a list of one or more B<expressions>:

  ExpressionList  ::= Expression ( Expression )*

An B<expression> is any of B<name expression>, B<id expression>, B<class
expression>, and B<type expression>.

  Expression      ::= NameExpression
                      | IdExpression
                      | ClassExpression
                      | TypeExpression

  NameExpression  ::= Name

  Name            ::= [A-Za-z]+

  IdExpression    ::= '#' [\p{L}\p{N}_-]+

  ClassExpression ::= '.' [\p{L}\p{N}_-]+

  TypeExpression  ::= ':' Name

=head1 SEE ALSO

See example filter C<select> to select parts of a document.

=cut
