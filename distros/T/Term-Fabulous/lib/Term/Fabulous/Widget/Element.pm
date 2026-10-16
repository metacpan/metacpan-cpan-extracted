package Term::Fabulous::Widget::Element;

use v5.32;
use warnings;

our $VERSION = '0.03';

use Object::Pad 0.825;

# The Clay::UI roles a container widget is made of. Term::Fabulous::Widget
# inherits them from here so that it can override the role methods (an
# Object::Pad class cannot override a method of a role it composes itself).
class Term::Fabulous::Widget::Element
	:does(Clay::UI::Role::Core::Container)

	:does(Clay::UI::Role::Events::Listener)
	:does(Clay::UI::Role::Events::Emitter)

	:does(Clay::UI::Role::Layout::HasFloating)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Layout::HasParent)
	:does(Clay::UI::Role::Layout::HasSizingGroup)

	:does(Clay::UI::Role::Style::HasBackground)
	:does(Clay::UI::Role::Style::HasStates)

	:does(Clay::UI::Role::Style::HasBorder)
	:abstract {
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Element - The Clay::UI roles behind
Term::Fabulous::Widget

=head1 DESCRIPTION

An abstract class that composes the L<Clay::UI> roles every container
widget needs: C<Clay::UI::Role::Core::Container>, the event roles, the
layout roles and the background and border styles. It has no methods of
its own.

L<Term::Fabulous::Widget> inherits from it instead of composing the
roles directly, because an L<Object::Pad> class cannot override a
method of a role it composes, while a subclass can override an
inherited method. This lets Term::Fabulous::Widget accept every
L<Term::Fabulous::Color> format in C<background_color> and
C<border_color>.

Do not subclass this class; subclass L<Term::Fabulous::Widget> or one
of its subclasses.

=head1 SEE ALSO

L<Term::Fabulous::Widget>, L<Clay::UI>.

=cut
