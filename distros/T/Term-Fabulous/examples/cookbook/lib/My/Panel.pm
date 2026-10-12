package My::Panel;

use v5.32;
use warnings;
use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

class My::Panel :isa(Term::Fabulous::Widget::Box) :strict(params) {
	use Clay::XS qw(CLAY_TOP_TO_BOTTOM);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Widget::Text;

	field $title_widget = Term::Fabulous::Widget::Text->new( text => '', text_color => [ 255, 200, 80, 255 ] );

	# Defaults; a layout's properties are applied after construction and
	# override them.
	ADJUST {
		my $layout = $self->layout;
		$self->layout( { %$layout, layout_direction => CLAY_TOP_TO_BOTTOM } ) unless exists $layout->{layout_direction};
		$self->bordered(1) unless $self->has_look_override('bordered');
		foreach my $side (qw(top right bottom left)) {
			my $accessor = "border_style_$side";
			$self->$accessor( Term::Fabulous::Enum::BorderStyle->Round ) unless defined $self->$accessor;
		}
		$self->add_child($title_widget);    # the first child; the layout adds the others after it
	}

	# Title text, a character string.
	method title (@new) {
		$title_widget->text( $new[0] ) if @new;
		return $title_widget->text;
	}

	# A structured property: 'title "Settings" color="#ffcc00"' has an
	# argument and a key=value property, so a handler of its own parses
	# the node.
	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, title => \&_parse_title );
	}

	method _parse_title ($kid) {
		my @args  = $kid->args->@*;
		my %props = map { $_->[0] => $_->[1]->as_perl } $kid->props->@*;
		die "My::Panel: 'title' takes one string and an optional color=..."
			unless @args == 1 && $args[0]->is_string && !grep { $_ ne 'color' } keys %props;

		$self->title( $args[0]->value );
		$title_widget->text_color( $props{color} ) if exists $props{color};
		return;
	}
}

1;
