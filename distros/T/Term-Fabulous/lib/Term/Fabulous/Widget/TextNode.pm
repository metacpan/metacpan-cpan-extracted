package Term::Fabulous::Widget::TextNode;

use v5.32;
use warnings;

our $VERSION = '0.03';

use Object::Pad 0.825;

# The Clay::UI text role behind Term::Fabulous::Widget::Text, kept in a
# parent class so that Text can override its methods (an Object::Pad class
# cannot override a method of a role it composes itself).
class Term::Fabulous::Widget::TextNode :does(Clay::UI::Text) :abstract {
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::TextNode - The Clay::UI text role behind
Term::Fabulous::Widget::Text

=head1 DESCRIPTION

An abstract class that composes L<Clay::UI::Text> and nothing else.
L<Term::Fabulous::Widget::Text> inherits from it instead of composing
the role directly, because an L<Object::Pad> class cannot override a
method of a role it composes, while a subclass can override an
inherited method. This lets Term::Fabulous::Widget::Text accept every
L<Term::Fabulous::Color> format in C<text_color>.

Do not subclass this class; subclass L<Term::Fabulous::Widget::Text>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Text>, L<Clay::UI::Text>.

=cut
