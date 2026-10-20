package Term::Fabulous::Layout;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

class Term::Fabulous::Layout :strict(params) {
	use Feature::Compat::Try;
	use Text::KDL::XS qw(parse_kdl);
	use Term::Fabulous::Check qw(describe);

	my $MODULE_NAME = qr/\A[A-Za-z_]\w*(?:::\w+)*\z/a;
	my $ALIAS       = qr/\A[A-Z]\w*\z/a;
	my $LAYOUT_ROLE = 'Term::Fabulous::Role::CanParseLayout';

	field $raw         :reader;
	field $root_widget :reader;
	field $required_modules :reader = {};
	field $_root_node;

	ADJUST :params ( :$string = undef, :$file = undef, :$allowed_namespaces = undef ) {
		die "Term::Fabulous::Layout: provide either 'string' or 'file'"
			if !defined $string && !defined $file;
		die "Term::Fabulous::Layout: provide 'string' or 'file', not both" if defined $string && defined $file;
		my $allowed = _checked_namespaces($allowed_namespaces);

		my $source = $string // _open_file($file);
		try {
			$raw = parse_kdl($source);
		}
		catch ($error) {
			die "Term::Fabulous::Layout: failed to parse KDL: $error";
		}

		$required_modules = _use_instructions( $raw, $allowed );
		_load_widget_class( $_, $required_modules->{$_} ) foreach sort keys %$required_modules;
		$_root_node = _root_node( $raw, $required_modules );
	}

	# Text::KDL::XS reads a filehandle as UTF-8 bytes, a string as characters
	sub _open_file ($path) {
		open my $handle, '<:raw', $path or die "Term::Fabulous::Layout: cannot open '$path': $!";
		return $handle;
	}

	# The namespaces a layout may load modules from, or undef for any.
	sub _checked_namespaces ($namespaces) {
		return undef unless defined $namespaces;
		die "Term::Fabulous::Layout: allowed_namespaces must be an array reference of package names, got " . describe($namespaces)
			unless ref $namespaces eq 'ARRAY';
		die "Term::Fabulous::Layout: allowed_namespaces needs at least one package name; leave it out to allow any module" unless @$namespaces;
		foreach my $namespace (@$namespaces) {
			die "Term::Fabulous::Layout: allowed_namespaces holds an invalid package name " . describe($namespace)
				unless defined $namespace && !ref $namespace && $namespace =~ $MODULE_NAME;
		}
		return [@$namespaces];
	}

	# Maps every alias declared by a top-level 'use' node to its module.
	# Every module is checked against the allowed namespaces before any is
	# loaded, because loading runs its code.
	sub _use_instructions ( $document, $allowed ) {
		my %module_by_alias;
		foreach my $node ( $document->nodes->@* ) {
			next unless $node->name eq 'use';
			my ( $alias, $module ) = _parse_use($node);
			_check_allowed( $module, $allowed );
			die "Term::Fabulous::Layout: widget alias '$alias' is declared twice" if exists $module_by_alias{$alias};
			$module_by_alias{$alias} = $module;
		}
		return \%module_by_alias;
	}

	sub _parse_use ($node) {
		my @args        = map                                                { $_->is_string ? $_->value : undef } $node->args->@*;
		my $well_formed = !$node->props->@* && !$node->children->@* && !grep { !defined } @args;

		if ( $well_formed && @args == 1 ) {
			my ($module) = @args;
			_check_module_name($module);
			die "Term::Fabulous::Layout: 'use $module' without 'as' needs a module name starting with an uppercase letter, because the name is also the widget node name"
				unless $module =~ /\A[A-Z]/;
			return ( $module, $module );
		}
		if ( $well_formed && @args == 3 && $args[1] eq 'as' ) {
			my ( $module, undef, $alias ) = @args;
			_check_module_name($module);
			die "Term::Fabulous::Layout: invalid widget alias '$alias'; it must start with an uppercase letter and contain only letters, digits and '_'"
				unless $alias =~ $ALIAS;
			return ( $alias, $module );
		}
		die "Term::Fabulous::Layout: invalid 'use' instruction; expected 'use Module::Name' or 'use Module::Name as Alias'";
	}

	sub _check_module_name ($module) {
		die "Term::Fabulous::Layout: invalid module name '$module' in 'use'" unless $module =~ $MODULE_NAME;
		return;
	}

	# A module is in a namespace when it is the namespace or below it.
	sub _check_allowed ( $module, $allowed ) {
		return unless defined $allowed;
		return if grep { $module eq $_ || index( $module, "${_}::" ) == 0 } @$allowed;
		die "Term::Fabulous::Layout: 'use $module' is not allowed; allowed_namespaces permits only modules in " . join( ', ', @$allowed );
	}

	sub _load_widget_class ( $alias, $module ) {
		( my $path = "$module.pm" ) =~ s{::}{/}g;
		try {
			require $path;
		}
		catch ($error) {
			die "Term::Fabulous::Layout: cannot load '$module' for widget alias '$alias': $error";
		}
		die "Term::Fabulous::Layout: '$module' (widget alias '$alias') does not compose $LAYOUT_ROLE, so it cannot be built from a layout"
			unless $module->DOES($LAYOUT_ROLE);
		return;
	}

	sub _root_node ( $document, $module_by_alias ) {
		my @widget_nodes;
		foreach my $node ( $document->nodes->@* ) {
			my $name = $node->name;
			next if $name eq 'use';
			die "Term::Fabulous::Layout: unexpected top-level node '$name'; only 'use' instructions and one root widget are allowed"
				unless exists $module_by_alias->{$name};
			push @widget_nodes, $node;
		}
		die "Term::Fabulous::Layout: no root widget found in the layout" unless @widget_nodes;
		die "Term::Fabulous::Layout: multiple root widgets found in the layout (" . join( ', ', map { $_->name } @widget_nodes ) . ")"
			if @widget_nodes > 1;
		return $widget_nodes[0];
	}

	sub _widget_id ($node) {
		my $name = $node->name;
		die "Term::Fabulous::Layout: widget '$name' does not accept key=value properties (got: " . join( ', ', map { $_->[0] } $node->props->@* ) . ")"
			if $node->props->@*;

		my @args = $node->args->@*;
		return undef unless @args;
		die "Term::Fabulous::Layout: widget '$name' takes at most one argument, a string id" unless @args == 1 && $args[0]->is_string;
		return $args[0]->value;
	}

	method _build_widget ($node) {
		my $name  = $node->name;
		my $class = $required_modules->{$name} // die "Term::Fabulous::Layout: unknown widget '$name'; declare it with 'use Module::Name as $name'";
		my $id    = _widget_id($node);

		my $widget;
		try {
			$widget = $class->new( id => $id );
			$widget->apply_layout_node($node);
		}
		catch ($error) {
			die "Term::Fabulous::Layout: cannot build widget '$name'" . ( defined $id ? " \"$id\"" : '' ) . ": $error";
		}

		foreach my $child ( $node->children->@* ) {
			next unless Term::Fabulous::Role::CanParseLayout::is_widget_node_name( $child->name );    # properties are parsed by the widget itself
			die "Term::Fabulous::Layout: widget '$name' cannot contain child widgets (found '" . $child->name . "')"
				unless $widget->can('add_child');
			$widget->add_child( $self->_build_widget($child) );
		}
		return $widget;
	}

	method build () {
		$root_widget //= $self->_build_widget($_root_node);
		return $root_widget;
	}

	method walk_nodes ($code) {
		my @nodes = ( $raw->nodes->@* );
		while (@nodes) {
			my $node = shift @nodes;
			$code->($node);
			push @nodes, $node->children->@* if $node->children;
		}
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Layout - Build a widget tree from a KDL layout description

=head1 SYNOPSIS

	use Term::Fabulous;
	use Term::Fabulous::Layout;

	my $layout = Term::Fabulous::Layout->new( string => <<'KDL' );
	use Term::Fabulous::Widget::Box as Box
	use Term::Fabulous::Widget::Text as Text

	Box "root" {
		layout direction=down gap=1
		sizing width=grow height=grow
		padding left=1 right=1
		border style=Round color="rgb(20, 140, 56)"
		bordered #true
		background_color "#141937"

		Text "greeting" {
			text "Hello!"
			text_color "rgba(220, 34, 220, 1.0)"
		}
	}
	KDL

	my $root = $layout->build;
	$root->find_by_id('greeting')->text('Hello, KDL!');
	Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;

	# Or read the layout from a file:
	my $from_file = Term::Fabulous::Layout->new( file => 'screens/main.kdl' );

=head1 DESCRIPTION

Instead of building a widget tree in Perl, you can describe it in a
layout file written in KDL, a small document language of nested nodes
(see L<https://kdl.dev>). Term::Fabulous::Layout parses such a
description with L<Text::KDL::XS>, loads the widget classes it names and
builds the widget tree. You then hand the root widget to
L<Term::Fabulous> or L<Term::Fabulous::Static> as usual, and attach
event listeners in Perl.

A layout file describes the static part of a user interface: which
widgets there are, how they are nested, sized, colored and bordered,
and the initial values of input widgets. Behavior (listeners, timers)
stays in Perl. Everything a layout can do, Perl can do as well; a few
options are available only in Perl (see L</LIMITATIONS>).

This page is the reference. The guide is
L<the KDL chapter of the manual|Term::Fabulous::Manual::KDL/KDL LAYOUT FILES>,
with complete programs and their screenshots. This is
F<examples/kdl-layout.pl>, which builds its screen from the layout file
F<examples/kdl-layout.kdl>:

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/example-kdl-layout.svg" alt="A title bar, a sidebar with the buttons web, db and mail with db focused, and a main panel showing the details of the db server"></p>

=end html

=head1 CONSTRUCTOR

=head2 new

	my $layout = Term::Fabulous::Layout->new( string => $kdl_text );
	my $layout = Term::Fabulous::Layout->new( file   => $path );
	my $layout = Term::Fabulous::Layout->new( file   => $path, allowed_namespaces => ['Term::Fabulous::Widget'] );

Parses the document, checks its C<use> instructions, loads the widget
classes and finds the root widget node. The widgets themselves are
built later, by L</build>. Every problem dies with a message that starts
with C<Term::Fabulous::Layout:> (see L</ERRORS>). Unknown parameters
die.

Give exactly one of C<string> and C<file>; giving none or both dies.

=over

=item C<string>

The layout as a Perl character string (decoded text). A here-document
in a source file with C<use utf8> is such a string.

=item C<file>

The path of a layout file. The file is read as UTF-8 encoded bytes.
Dies if it cannot be opened.

=item C<allowed_namespaces>

Optional. An array reference of package names, such as
C<< [ 'Term::Fabulous::Widget', 'My::App::Widget' ] >>: the layout may
C<use> only these packages and the modules below them
(C<Term::Fabulous::Widget::Box> is below C<Term::Fabulous::Widget>,
C<Term::Fabulous::WidgetKit> is not). Every C<use> is checked before
any module is loaded, so a refused one runs no code; it dies with
C<'use MODULE' is not allowed; allowed_namespaces permits only modules
in ...>. Default: C<undef>, any module. Anything but a non-empty array
reference of valid package names dies. See L</SECURITY>.

=back

=head1 METHODS

=head2 build

	my $root = $layout->build;

Builds the widget tree and returns its root widget. The tree is built
only once: later calls return the same root widget. Since a widget can
be part of only one tree, build a new Term::Fabulous::Layout object if
you need a second copy of the same widgets.

Each widget is built with C<< $class->new( id => $id ) >>, then its
property nodes are applied to the finished widget with
C<< $widget->apply_layout_node($node) >> (see
L<Term::Fabulous::Role::CanParseLayout>), and then its child widgets
are built and added. So a layout sets properties like a program calling
the accessors after C<new>, and the order of the properties of related
values does not matter (a Slider's C<min> and C<max>, a Dropdown's
C<options> and C<value>). Invalid properties die here, not in L</new>.

To get at the other widgets of the tree, call
L<Term::Fabulous::Widget/find_by_id> on the root (see L</EXAMPLES>).

=head2 root_widget

	my $root = $layout->root_widget;

The root widget built by L</build>, or C<undef> before the first call
of L</build>.

=head2 required_modules

	my %module_by_alias = %{ $layout->required_modules };    # ( Box => 'Term::Fabulous::Widget::Box', ... )

A hash reference that maps every widget name declared with C<use> to
its Perl module.

=head2 raw

	my $document = $layout->raw;

The parsed L<Text::KDL::XS::Document>, for programs that want to
inspect the layout's nodes themselves, for example a tool that lists the
ids of a layout file.

=head2 walk_nodes

	$layout->walk_nodes( sub ($node) {
		say $node->name;
	} );

Calls the code reference once for every node of the document
(L<Text::KDL::XS::Node> objects), including C<use> instructions and
property nodes, breadth first: all top-level nodes, then their
children, and so on. Nodes commented out with C</-> are not part of the
document. Returns nothing.

=head1 THE KDL FORMAT

=head2 A short introduction to KDL

A KDL document is a list of nodes. A node has a name, followed by
optional arguments, optional C<key=value> properties and an optional
block of child nodes in braces:

=for highlighter language=kdl

	name argument1 argument2 key=value other="value" {
		child-node
		another-child 42
	}

Nodes end at a line break or a semicolon, so short nodes can share a
line: C<RadioButton { label "Small"; value "s"; }>.

Values are written like this:

=for highlighter language=text

	Value                          Example                Perl value
	-----------------------------  ---------------------  -----------------
	string in double quotes        "Hello, world"         'Hello, world'
	bare word                      grow, Round, down      'grow', ...
	integer or decimal number      40, 2.5, 0x1f          40, 2.5, 31
	boolean                        #true, #false          1, 0
	no value                       #null                  undef

Strings that contain spaces, parentheses, C<#>, C<=> or other special
characters must be quoted: C<"#141937">, C<"fixed(10)">,
C<"rgb(1, 2, 3)">. Inside quotes, C<\n> is a line break, C<\"> a quote
and C<\\> a backslash; a raw string, C<#"C:\path"#>, takes backslashes
as they are. Boolean properties must be written C<#true> and C<#false>
(C<1> and C<0> are accepted too); any other value, such as C<"no"> or
C<"false"> in quotes, dies, and a bare C<true> is a syntax error.

Comments are C<// to the end of the line>, C</* blocks */>, and C</->
in front of a node, which comments out the whole node with its
children:

=for highlighter language=kdl

	/- Text { text "not shown"; }

=head2 Top level: use instructions and one root widget

The top level of a layout contains C<use> instructions, which declare
the widget classes, and exactly one widget node, the root widget.
Nothing else is allowed at the top level.

	use Term::Fabulous::Widget::Box as Box
	use Term::Fabulous::Widget::TextField as TextField
	use My::App::Widget::Clock as Clock

	Box "root" { ... }

C<use Module::Name as Alias> declares that nodes named C<Alias> build
C<Module::Name> widgets. C<Module::Name> must be a plain Perl package
name (letters, digits, C<_> and C<::>). C<Alias> must start with an
uppercase letter and contain only letters, digits and C<_>. Each alias
can be declared only once. The module is loaded with C<require> and
must compose L<Term::Fabulous::Role::CanParseLayout>, which all
Term::Fabulous widgets do (see L</NODE TYPES>); your own widgets can
too (see L<using your widget in KDL|Term::Fabulous::Manual::CustomWidgets/Using your widget in KDL>).

The short form C<use Module::Name> uses the full module name as the
widget node name, so the module name must start with an uppercase
letter:

	use Term::Fabulous::Widget::Box

	Term::Fabulous::Widget::Box "root" { ... }

C<use> takes no C<key=value> properties and no children.

=head2 Widget nodes

	Alias "id" {
		property-node ...
		ChildAlias "child-id" { ... }
	}

A node whose name is a declared alias builds one widget. It takes at
most one argument, a string, which becomes the widget's C<id>, and no
C<key=value> properties. Inside its braces:

=over

=item *

Nodes whose names start with an B<uppercase> letter are child widgets.
Their names must be declared aliases. Every widget except
L<Term::Fabulous::Widget::Text> and L<Term::Fabulous::Widget::Table>
accepts children.

=item *

Every other node is a property of the widget, such as C<sizing> or
C<text>. Each widget class documents its properties in the KDL
PROPERTIES section of its page (see L</NODE TYPES>); an unknown one
dies with the list of the known names.

=back

Properties are applied after the widget was constructed, with the same
checks as the Perl method of the same name, in the order they appear;
values that depend on each other are applied together, wherever they
stand: a dropdown's options before its C<value>, a slider's C<min>,
C<max> and C<step> as one range before its C<value>, a text field's
C<max_length> before its C<value>.

Ids are optional. They are used by Clay to keep track of widgets between
frames, they are required for a ScrollBox, and they are how you find
widgets after L</build> (see L</EXAMPLES>). Ids must be unique within
the tree. L</build> does not check this; the first frame drawn with
duplicate ids dies with
C<Clay error: An element with this ID was already previously declared during this layout.>

=head2 Kinds of property nodes

A property node has one of two shapes:

=over

=item *

One argument: C<text "Hello">, C<width_group 1>, C<checked #true>.

=item *

Only key=value pairs: C<padding left=1 right=1>,
C<bordered left=#true right=#true>.

=back

A property node never has children; the only exceptions are the
structured properties of a few widgets that say so, such as a table's
C<column> with its C<style> nodes. A property whose name ends in
C<_color> takes any color string L<Term::Fabulous::Color> understands
(C<"#61afef">, C<"#61afef80">, C<"rgb(97, 175, 239)">,
C<"rgba(97, 175, 239, 0.5)">, C<"hsl(207, 82%, 66%)">, ...; see
L<Term::Fabulous::Manual::Looks/Color formats>). Color names such as
C<"red"> are not color strings.

=head1 NODE TYPES

Every widget class of Term::Fabulous can be declared in a layout,
except L<Term::Fabulous::Widget::Prompt>,
L<Term::Fabulous::Widget::FileDialog>,
L<Term::Fabulous::Widget::KeyReference>,
L<Term::Fabulous::Widget::DocumentTabs>,
L<Term::Fabulous::Widget::Menu> and L<Term::Fabulous::Widget::MenuBar>:
their fields, items, rows and tabs come from code, and they answer
through events, which a layout file cannot hold. The
table lists the others with the alias the examples use; each link leads to the
list of properties the class accepts. All of them except Text accept
the L</Box properties>.

=for highlighter language=text

	Alias             Class                                     Properties
	----------------  ----------------------------------------  --------------------------------
	Box               Term::Fabulous::Widget::Box               Box properties
	Text              Term::Fabulous::Widget::Text              text, text_color, wrap_mode, ...
	Button            Term::Fabulous::Widget::Button            Box + focus and press looks
	Dialog            Term::Fabulous::Widget::Dialog            Box + backdrop, z_index
	ScrollBox         Term::Fabulous::Widget::ScrollBox         Box + horizontal, vertical
	Canvas            Term::Fabulous::Widget::Canvas            Box
	PixelCanvas       Term::Fabulous::Widget::PixelCanvas       Box
	Image             Term::Fabulous::Widget::Image             Box + file, base64, fit, ...
	Sixel             Term::Fabulous::Widget::Sixel             Box + file, base64, fit, ...
	TextField         Term::Fabulous::Widget::TextField         input widget + text options
	TextArea          Term::Fabulous::Widget::TextArea          input widget + text options
	Checkbox          Term::Fabulous::Widget::Checkbox          input widget + label, checked
	RadioGroup        Term::Fabulous::Widget::RadioGroup        Box + value, disabled
	RadioButton       Term::Fabulous::Widget::RadioButton       input widget + label, value
	Dropdown          Term::Fabulous::Widget::Dropdown          input widget + options, value
	Slider            Term::Fabulous::Widget::Slider            input widget + range, value
	StarRating        Term::Fabulous::Widget::StarRating        input widget + max, value, half
	SegmentedControl  Term::Fabulous::Widget::SegmentedControl  input widget + options, value
	ColorPicker       Term::Fabulous::Widget::ColorPicker       Box + value, alpha, sliders, ...
	Divider           Term::Fabulous::Widget::Divider           Box + text, line_style, ...
	Accordion         Term::Fabulous::Widget::Accordion         Box + multiple, bordered, ...
	Item              Term::Fabulous::Widget::Accordion::Item   Box + title, open, disabled
	Tabs              Term::Fabulous::Widget::Tabs              Box + side, orientation, ...
	Page              Term::Fabulous::Widget::Tabs::Page        Box + title, active, disabled
	TabBar            Term::Fabulous::Widget::Tabs::Bar         Box + side, orientation, ...
	Tab               Term::Fabulous::Widget::Tabs::Button      Button + title, icon
	ProgressBar       Term::Fabulous::Widget::ProgressBar       Box + range, value, style, ...
	Spinner           Term::Fabulous::Widget::Spinner           Box + style, frames, label
	Toast             Term::Fabulous::Widget::Toast             Box + kind, title, message, ...
	StatusBar         Term::Fabulous::Widget::StatusBar         Box + message, kind, timeout
	Table             Term::Fabulous::Widget::Table             Box + columns, lines, sort, ...
	LineChart         Term::Fabulous::Widget::LineChart         chart + series, axes, ...
	AreaChart         Term::Fabulous::Widget::AreaChart         chart + series, axes, ...
	BarChart          Term::Fabulous::Widget::BarChart          chart + series, axes, ...
	ScatterPlot       Term::Fabulous::Widget::ScatterPlot       chart + series, axes, ...
	Histogram         Term::Fabulous::Widget::Histogram         chart + series, bins, ...
	Sparkline         Term::Fabulous::Widget::Sparkline         chart + values, type, ...
	PieChart          Term::Fabulous::Widget::PieChart          chart + slice, sort, ...
	DonutChart        Term::Fabulous::Widget::DonutChart        pie chart properties
	PolarAreaChart    Term::Fabulous::Widget::PolarAreaChart    pie chart + max, ticks
	RadarChart        Term::Fabulous::Widget::RadarChart        chart + series, labels, ticks

The properties of each class:

=over

=item * L<Box|Term::Fabulous::Widget::Box/KDL PROPERTIES> (summarized in L</Box properties>)

=item * L<Text|Term::Fabulous::Widget::Text/KDL PROPERTIES>

=item * L<Button|Term::Fabulous::Widget::Button/KDL PROPERTIES>

=item * L<Dialog|Term::Fabulous::Widget::Dialog/KDL PROPERTIES>

=item * L<ScrollBox|Term::Fabulous::Widget::ScrollBox/KDL PROPERTIES>

=item * L<Canvas|Term::Fabulous::Widget::Canvas/KDL PROPERTIES>

=item * L<PixelCanvas|Term::Fabulous::Widget::PixelCanvas/KDL PROPERTIES>

=item * L<Image|Term::Fabulous::Widget::Image/KDL PROPERTIES>

=item * L<Sixel|Term::Fabulous::Widget::Sixel/KDL PROPERTIES>

=item * L<TextField|Term::Fabulous::Widget::TextField/KDL PROPERTIES>

=item * L<TextArea|Term::Fabulous::Widget::TextArea/KDL PROPERTIES>

=item * L<Checkbox|Term::Fabulous::Widget::Checkbox/KDL PROPERTIES>

=item * L<RadioGroup|Term::Fabulous::Widget::RadioGroup/KDL PROPERTIES>

=item * L<RadioButton|Term::Fabulous::Widget::RadioButton/KDL PROPERTIES>

=item * L<Dropdown|Term::Fabulous::Widget::Dropdown/KDL PROPERTIES>

=item * L<Slider|Term::Fabulous::Widget::Slider/KDL PROPERTIES>

=item * L<StarRating|Term::Fabulous::Widget::StarRating/KDL PROPERTIES>

=item * L<SegmentedControl|Term::Fabulous::Widget::SegmentedControl/KDL PROPERTIES>

=item * L<ColorPicker|Term::Fabulous::Widget::ColorPicker/KDL PROPERTIES>

=item * L<Divider|Term::Fabulous::Widget::Divider/KDL PROPERTIES>

=item * L<Accordion|Term::Fabulous::Widget::Accordion/KDL PROPERTIES> and L<Item|Term::Fabulous::Widget::Accordion::Item/KDL PROPERTIES>

=item * L<Tabs|Term::Fabulous::Widget::Tabs/KDL PROPERTIES> and L<Page|Term::Fabulous::Widget::Tabs::Page/KDL PROPERTIES>, L<TabBar|Term::Fabulous::Widget::Tabs::Bar/KDL PROPERTIES> and L<Tab|Term::Fabulous::Widget::Tabs::Button/KDL PROPERTIES>

=item * L<ProgressBar|Term::Fabulous::Widget::ProgressBar/KDL PROPERTIES>

=item * L<Spinner|Term::Fabulous::Widget::Spinner/KDL PROPERTIES>

=item * L<Toast|Term::Fabulous::Widget::Toast/KDL PROPERTIES>

=item * L<StatusBar|Term::Fabulous::Widget::StatusBar/KDL PROPERTIES>

=item * L<Table|Term::Fabulous::Widget::Table/KDL PROPERTIES>

=item * L<LineChart|Term::Fabulous::Widget::LineChart/KDL PROPERTIES>

=item * L<AreaChart|Term::Fabulous::Widget::AreaChart/KDL PROPERTIES>

=item * L<BarChart|Term::Fabulous::Widget::BarChart/KDL PROPERTIES>

=item * L<ScatterPlot|Term::Fabulous::Widget::ScatterPlot/KDL PROPERTIES>

=item * L<Histogram|Term::Fabulous::Widget::Histogram/KDL PROPERTIES>

=item * L<Sparkline|Term::Fabulous::Widget::Sparkline/KDL PROPERTIES>

=item * L<PieChart|Term::Fabulous::Widget::PieChart/KDL PROPERTIES>

=item * L<DonutChart|Term::Fabulous::Widget::DonutChart/KDL PROPERTIES>

=item * L<PolarAreaChart|Term::Fabulous::Widget::PolarAreaChart/KDL PROPERTIES>

=item * L<RadarChart|Term::Fabulous::Widget::RadarChart/KDL PROPERTIES>

=back

The properties shared by several classes are described once, on the
page of their base class: those of all input widgets in
L<Term::Fabulous::Widget::Input/KDL PROPERTIES>, those of TextField and
TextArea in L<Term::Fabulous::Widget::TextInput/KDL PROPERTIES>, those
of all charts in L<Term::Fabulous::Widget::Chart/KDL PROPERTIES> and
those of the charts with axes in
L<Term::Fabulous::Widget::XYChart/KDL PROPERTIES>. These four base
classes are abstract and cannot be used as nodes themselves. The parts
other widgets build for themselves (such as
C<Term::Fabulous::Widget::Dialog::Backdrop>, C<Term::Fabulous::Widget::Dropdown::List>
and the C<Term::Fabulous::Widget::Table::*> parts) cannot be built from
a layout either.

A Dialog is not drawn until it is opened from Perl, and it is opened
on its own, not as a child of another widget: describe it as the root of
a layout of its own, build it, and call C<< $dialog->open($ui) >> (see
L<Term::Fabulous::Widget::Dialog>).

=head1 PROPERTIES

=head2 Box properties

L<Term::Fabulous::Widget::Box> and every widget built on it (all widgets
except Text) accept these property nodes. The
L<KDL PROPERTIES section of the Box page|Term::Fabulous::Widget::Box/KDL PROPERTIES>
describes each one with an example, and
L<the layout chapter of the manual|Term::Fabulous::Manual::Layout/LAYOUT>
shows what they do, with pictures.

	Property node                               Value
	------------------------------------------  -------------------------------------------
	layout direction=... gap=N                  direction: down, ttb, top_to_bottom
	       line_gap=N line_sizing=...           (children top to bottom), right, ltr,
	                                            left_to_right (left to right), wrap,
	                                            ltr_wrap, left_to_right_wrap (left to
	                                            right, wrapping onto new lines) or
	                                            stack, back_to_front, btf (on top of
	                                            each other);
	                                            gap (alias child_gap): cells between
	                                            children, an integer >= 0;
	                                            line_gap: rows between wrapped lines,
	                                            an integer >= 0; line_sizing: grow
	                                            (the default) or fit
	sizing width=... height=...                 each: grow, fit, "grow(MIN)",
	                                            "grow(MIN, MAX)", "fit(MIN)",
	                                            "fit(MIN, MAX)" with MIN and MAX integers
	                                            >= 0 and MIN <= MAX (no MAX: no maximum),
	                                            "percent(N)" with N in 0..100 (decimals
	                                            allowed), or "fixed(N)" with N an
	                                            integer >= 0
	padding left=N right=N top=N bottom=N       any subset; integers >= 0
	child_alignment x=... y=...                 x: left (the default), center or right;
	                                            y: top (the default), center or bottom
	floating attach_to=... parent_id="..."      takes the box out of the layout and
	         element=... parent=...             draws it on top (see below)
	         offset_x=N offset_y=N z_index=N
	         pointer_capture=... clip_to=...
	border style=... style-top=...              style: a border style name (Round, Solid,
	       style-right=... style-bottom=...     Heavy, ...) for all four sides; the
	       style-left=... color=...             style-SIDE keys override it for one side;
	                                            color: a color string
	bordered #true                              a border on all four sides (#false: none)
	bordered top=#true left=#true ...           per side (top, right, bottom, left);
	                                            missing sides have none
	background_color "..."                      a color string
	glyphs_show_through #true                   #true or #false (the default): whether text
	                                            and borders below a translucent background
	                                            stay visible (see Term::Fabulous::Widget)
	border_color "..."                          a color string (same as border color=)
	width_group N                               an integer 0..1048575; 0 means no group
	height_group N                              an integer 0..1048575; 0 means no group

C<layout>, C<sizing>, C<padding>, C<border>, C<child_alignment> and
C<floating> take only the keys shown, and at least one of them. The
border style names are those of
L<Term::Fabulous::Enum::BorderStyle> and are case sensitive. A border
is only drawn on the sides C<bordered> names; without C<bordered>, the
theme decides for the widget's family (no border for a Box, see
L<Term::Fabulous::Manual::Looks/Borders from the theme>).

C<width_group> and C<height_group> give widgets in different parts of
the tree the same width or height; see
L<Term::Fabulous::Manual::Layout/Equal sizes across the tree>.

C<floating> sets the widget's C<floating> hash (see
L<Term::Fabulous::Widget/floating> and
L<Term::Fabulous::Manual::Layout/Floating widgets>); its keys are:

	Key              Value
	---------------  ----------------------------------------------------------
	attach_to        parent (the default), root or element; element
	                 requires parent_id
	parent_id        the id of the widget to attach to (with attach_to=element)
	element          the point of this box placed on the point "parent" of
	parent           the widget it is attached to: left_top (the default),
	                 left_center, left_bottom, center_top, center_center,
	                 center_bottom, right_top, right_center, right_bottom
	offset_x         an integer added to the position, in cells
	offset_y         an integer added to the position, in cells
	z_index          an integer -32768..32767; higher is drawn on top
	pointer_capture  capture (the default) or passthrough
	clip_to          none (the default) or attached_parent

	Box "root" {
		Button "menu-button" { Text { text "Menu"; } }
		Box "menu" {
			floating attach_to=element parent_id="menu-button" parent=left_bottom
			floating z_index=10
		}
	}

An unknown name in C<child_alignment> or C<floating> dies with the
known names.

A property node may appear more than once. A second C<padding>,
C<sizing>, C<layout>, C<child_alignment> or C<floating> node changes
only the keys it names and keeps the others.

=for highlighter language=kdl

	Box "panel" {
		layout direction=down gap=1
		sizing width="percent(50)" height=fit
		padding left=1 right=1
		border style=Round style-top=Heavy color="#61afef"
		bordered #true
		background_color "rgb(28, 33, 45)"
	}

=head1 EXAMPLES

=head2 A form, built from a layout

=for highlighter language=perl

	use v5.32;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Term::Fabulous;
	use Term::Fabulous::Layout;

	my $layout = Term::Fabulous::Layout->new( string => <<'KDL' );
	use Term::Fabulous::Widget::Box as Box
	use Term::Fabulous::Widget::Text as Text
	use Term::Fabulous::Widget::TextField as TextField
	use Term::Fabulous::Widget::Checkbox as Checkbox
	use Term::Fabulous::Widget::RadioGroup as RadioGroup
	use Term::Fabulous::Widget::RadioButton as RadioButton
	use Term::Fabulous::Widget::Dropdown as Dropdown
	use Term::Fabulous::Widget::Slider as Slider

	Box "form" {
		layout direction=down gap=1
		sizing width=grow height=grow
		padding left=1 right=1
		border style=Round color="#61afef"
		bordered #true

		Text "title" {
			text "Sign up"
			text_color "rgb(255, 200, 80)"
		}
		TextField "name" {
			placeholder "Your name"
			max_length 40
		}
		TextField "password" {
			mask "*"
		}
		RadioGroup "plan" {
			layout direction=right gap=2
			value "pro"
			RadioButton { label "Free"; value "free"; }
			RadioButton { label "Pro"; value "pro"; }
		}
		Dropdown "country" {
			placeholder "Country"
			options "Austria" "Germany"
			option "Switzerland" value="CH"
			value "CH"
		}
		Slider "age" {
			min 18
			max 99
			value 30
			value_format "%d years"
		}
		Checkbox "news" {
			label "Send me news"
			checked #true
		}
	}
	KDL

	my $root  = $layout->build;
	my $title = $root->find_by_id('title');

	# Every Change event bubbles up to the form box.
	$root->on( Change => sub ($event) {
		$title->text( 'Changed: ' . $event->target->id );
		return;
	} );

	Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;

F<examples/kdl-form.pl> is a longer form of the same kind, and
F<examples/kdl-layout.pl> loads its layout from a file; both are shown
with screenshots in L<Term::Fabulous::Manual::KDL/KDL LAYOUT FILES>.

=head2 Finding widgets by id

L</build> returns only the root widget. To get at the other widgets,
call L<Term::Fabulous::Widget/find_by_id> on the root: it returns the
first widget (in depth-first order) whose id is the argument, Text
widgets included, or C<undef> when there is none. See also
L<Term::Fabulous::Cookbook::Forms/Find widgets by id>.

	my $country = $root->find_by_id('country');
	say $country->value;    # CH

=head2 Adding what a layout cannot express

Build first, then set the remaining options in Perl:

	my $age = $root->find_by_id('age');
	$age->value_format( sub ($value) { $value < 21 ? "$value (young)" : "$value years" } );
	$age->on( Change => sub ($event) { ...; return } );

=head1 LIMITATIONS

These options exist in Perl but cannot be written in a layout:

=over

=item *

event listeners, and the C<classes> of a widget;

=item *

C<border_corners> and C<outer_border_sides> (see
L<Term::Fabulous::Role::HasBorderStyle>);

=item *

the C<expand> key of a widget's C<floating> hash;

=item *

the C<child_offset> of a ScrollBox;

=item *

code references, such as a Slider's C<value_format> as code, and the
other widget-specific options their KDL PROPERTIES sections name as
Perl-only (for example a table's rows and a chart's data callbacks).

=back

Set them in Perl after L</build>, as shown in
L</Adding what a layout cannot express>.

=head1 ERRORS

Everything that is wrong with a layout dies, either in L</new> or in
L</build>. Messages start with C<Term::Fabulous::Layout:>; errors in a
widget's properties also name the widget and its id, followed by the
widget class's own message:

=for highlighter language=text

	Term::Fabulous::Layout: cannot build widget 'Box' "panel": Term::Fabulous::Widget::Box: unknown layout property 'colour' (known: background_color, border, border_color, bordered, child_alignment, classes, floating, glyphs_show_through, height_group, layout, padding, sizing, width_group)

L</new> dies for:

=over

=item * neither or both of C<string> and C<file>, or a file that cannot be opened;

=item * KDL syntax errors (C<failed to parse KDL: KDL parse error>; the parser does not report a line number);

=item * a malformed C<use>, an invalid module name or alias, or an alias declared twice;

=item * a module outside the C<allowed_namespaces>, or an invalid C<allowed_namespaces>;

=item * a module that cannot be loaded, or that does not compose L<Term::Fabulous::Role::CanParseLayout>;

=item * a top-level node that is neither C<use> nor a declared widget, no root widget, or more than one.

=back

L</build> dies for:

=over

=item * an undeclared widget name (C<unknown widget 'Foo'; declare it with 'use Module::Name as Foo'>);

=item * a widget node with C<key=value> properties, more than one argument, or a non-string id;

=item * child widgets inside a widget that cannot hold children;

=item * a widget the class cannot construct with only an id: an abstract base class, or a ScrollBox without an id;

=item * unknown property names, property nodes of the wrong shape, unknown keys, and invalid values.

=back

=head1 SECURITY

A layout names the Perl modules it loads, and loading a module runs its
code. Only syntactically valid package names are accepted (no paths),
and a module that does not compose L<Term::Fabulous::Role::CanParseLayout>
is rejected, but only after it has been loaded, so its top-level code
has already run. A layout can therefore load and run any module
installed on the system. Treat layout files like program code: do not
load layouts from untrusted sources.

A program that loads layouts its users write can restrict them with
L</new>'s C<allowed_namespaces>: a C<use> of any module outside these
namespaces dies before any module of the layout is loaded. Choose
namespaces that hold only widget classes; every module in them can
still be loaded and run.

Properties can only call the accessors a widget class declares in its
C<layout_properties> (see L<Term::Fabulous::Role::CanParseLayout>), so a
layout cannot call arbitrary methods.

=head1 SEE ALSO

L<Term::Fabulous::Manual::KDL/KDL LAYOUT FILES> (the guide),
L<Term::Fabulous::Role::CanParseLayout> (widget classes in layouts),
L<Term::Fabulous::Widget::Box/KDL PROPERTIES>,
L<Term::Fabulous::Manual::Layout/LAYOUT>,
L<Term::Fabulous::Cookbook::Forms/Build a form from a KDL file (text fields, radio buttons, dropdown, slider, checkbox)>,
L<Term::Fabulous::Cookbook::Tables/Describe a table in a KDL layout (columns, lines, sort, groups)>,
L<Term::Fabulous::Cookbook::ChartTechniques/Describe charts in a KDL layout (series, slices, transforms)>,
L<Term::Fabulous::Cookbook::Extending/Make a widget usable from KDL>,
L<Text::KDL::XS>, L<https://kdl.dev>.

=cut
