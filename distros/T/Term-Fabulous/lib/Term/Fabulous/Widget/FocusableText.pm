package Term::Fabulous::Widget::FocusableText;

use v5.32;
use warnings;

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Role::Interaction::Focusable;
use Term::Fabulous::Widget::Text;

# The focus role behind Term::Fabulous::Widget::RichText, kept in a
# parent class so that RichText can override its methods (an Object::Pad
# class cannot override a method of a role it composes itself).
class Term::Fabulous::Widget::FocusableText
	:isa(Term::Fabulous::Widget::Text)
	:does(Clay::UI::Role::Interaction::Focusable)
	:abstract
{
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::FocusableText - The focus role behind
Term::Fabulous::Widget::RichText

=head1 DESCRIPTION

An abstract L<Term::Fabulous::Widget::Text> that composes
L<Clay::UI::Role::Interaction::Focusable> and nothing else.
L<Term::Fabulous::Widget::RichText> inherits from it instead of
composing the role directly, because an L<Object::Pad> class cannot
override a method of a role it composes, while a subclass can override
an inherited method. This lets a RichText take the focus only while it
has links (L<Term::Fabulous::Widget::RichText/accepts_focus>).

Do not subclass this class; subclass L<Term::Fabulous::Widget::RichText>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::RichText>, L<Term::Fabulous::Widget::TextNode>,
L<Clay::UI::Role::Interaction::Focusable>.

=cut
