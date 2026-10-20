package Term::Fabulous::Widget::TextNode;

use v5.32;
use warnings;

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Role::Interaction::Focusable;

# The Clay::UI roles behind Term::Fabulous::Widget::Text, kept in a
# parent class so that Text can override their methods (an Object::Pad
# class cannot override a method of a role it composes itself).
class Term::Fabulous::Widget::TextNode
	:does(Clay::UI::Text)
	:does(Clay::UI::Role::Interaction::Focusable)
	:abstract
{
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::TextNode - The Clay::UI roles behind
Term::Fabulous::Widget::Text

=head1 DESCRIPTION

An abstract class that composes L<Clay::UI::Text> and
L<Clay::UI::Role::Interaction::Focusable>, and nothing else.
L<Term::Fabulous::Widget::Text> inherits from it instead of composing
the roles directly, because an L<Object::Pad> class cannot override a
method of a role it composes, while a subclass can override an
inherited method. This lets Term::Fabulous::Widget::Text accept every
L<Term::Fabulous::Color> format in C<text_color>, and take the focus
only while it has links.

Do not subclass this class; subclass L<Term::Fabulous::Widget::Text>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Text>, L<Clay::UI::Text>,
L<Clay::UI::Role::Interaction::Focusable>.

=cut
