
package PRANG::Graph::Meta::Element;
$PRANG::Graph::Meta::Element::VERSION = '0.18';
use Moose::Role;
use PRANG::Util qw(types_of);
use MooseX::Params::Validate;

has 'xmlns' =>
	is => "rw",
	isa => "Str",
	predicate => "has_xmlns",
	;

has 'xmlns_attr' =>
	is => "rw",
	isa => "Str",
	predicate => "has_xmlns_attr",
	;

has 'xml_nodeName' =>
	is => "rw",
	isa => "Str|HashRef",
	predicate => "has_xml_nodeName",
	;

has 'xml_nodeName_prefix' =>
	is => "rw",
	isa => "HashRef[Str]",
	predicate => "has_xml_nodeName_prefix",
	;

has 'xml_nodeName_attr' =>
	is => "rw",
	isa => "Str",
	predicate => "has_xml_nodeName_attr",
	;

has 'xml_required' =>
	is => "rw",
	isa => "Bool",
	predicate => "has_xml_required",
	;

has 'xml_min' =>
	is => "rw",
	isa => "Int",
	predicate => "has_xml_min",
	;

has 'xml_max' =>
	is => "rw",
	isa => "Int",
	predicate => "has_xml_max",
	;

# FIXME: see commitlog, core Moose should get support for this again
#        (perhaps)
#has '+isa' =>
#	required => 1,
#	;

has 'graph_node' =>
	is => "rw",
	isa => "PRANG::Graph::Node",
	lazy => 1,
	required => 1,
	default => sub {
	my $self = shift;
	$self->build_graph_node;
	},
	;

has "_item_tc" =>
	is => "rw",
	isa => "Moose::Meta::TypeConstraint",
	;

use constant HIGHER_ORDER_TYPE =>
	"Moose::Meta::TypeConstraint::Parameterized";

sub _error {
    my $self = shift;
    my ( $message ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );    
    
	my $class = $self->associated_class;
	my $context = " (Element: ";
	if ($class) {
		$context .= $class->name;
	}
	else {
		$context .= "(unassociated)";
	}
	$context .= "/".$self->name.") ";
	$message.$context;
}

sub error {
    my $self = shift;
    my ( $message ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );      
    
	confess $self->_error($message);
}

sub warn_of {
    my $self = shift;
    my ( $message ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );    
    
	warn $self->_error($message)."\n";
}

sub build_graph_node {
    my $self = shift;
    
	my ($expect_one, $expect_many);

	if ( $self->has_xml_required ) {
		$expect_one = $self->xml_required;
	}
	elsif (
		$self->has_predicate
		or
		$self->has_xml_min and !$self->xml_min
		)
	{   $expect_one = 0;
	}
	else {
		$expect_one = 1;
	}

	my $t_c = $self->type_constraint
		or $self->error(
		"No type constraint on attribute; did you specify 'isa'?",
		);

	# check to see whether ArrayRef was specified
	if ( $t_c->is_a_type_of("ArrayRef") ) {
		my $is_paramd;
		until ( $t_c->equals("ArrayRef") ) {
			if ( $t_c->isa(HIGHER_ORDER_TYPE) ) {
				$is_paramd = 1;
				last;
			}
			else {
				$t_c = $t_c->parent;
			}
		}
		if (not $is_paramd) {
			$self->error("ArrayRef, but not Parameterized");
		}
		$expect_many = 1;

		$t_c = $t_c->type_parameter;
	}
	elsif (
		$self->has_xml_max and $self->xml_max > 1
		or
		$self->has_xml_min and $self->xml_min > 1
		)
	{
		$self->error(
"min/max specified as >1, but type constraint is not an ArrayRef",
		);
	}

	$self->_item_tc($t_c);

	# ok.  now let's walk the type constraint tree, and look for
	# types
	my ($expect_bool, $expect_simple, @expect_type, @expect_role);

	my @st = $t_c;
	my %t_c;
	while ( my $x = shift @st ) {
		$t_c{$x} = $x;
		if ( $x->isa("Moose::Meta::TypeConstraint::Class") ) {
			push @expect_type, $x->class;
		}
		elsif ( $x->isa("Moose::Meta::TypeConstraint::Union") ) {
			push @st, @{ $x->type_constraints };
		}
		elsif ( $x->isa("Moose::Meta::TypeConstraint::Enum") ) {
			push @st, $x->parent;
		}
		elsif ( $x->isa("Moose::Meta::TypeConstraint::Role") ) {

			# likely to be a wildcard.
			push @expect_role, $x->role;
		}
		elsif ( ref $x eq "Moose::Meta::TypeConstraint" ) {
			if ( $x->equals("Bool") ) {
				$expect_bool = 1;
			}
			elsif ( $x->equals("Value") ) {
				$expect_simple = 1;
			}
			else {
				push @st, $x->parent;
			}
		}
		else {
			$self->error(
				"Sorry, I don't know how to map a "
					.ref($x)
			);
		}
	}

	my $node;
	my $nodeName = $self->has_xml_nodeName
		?
		$self->xml_nodeName
		: $self->name;
	my $nodeName_prefix = $self->has_xml_nodeName_prefix
		?
		$self->xml_nodeName_prefix
		: {};
	my $nodeName_r_prefix = { reverse %$nodeName_prefix };

	my $expect_concrete = ($expect_bool||0) +
		($expect_simple||0) + @expect_type;

	if ( $expect_concrete > 1 ) {

		# multiple or ambiguous types are specified; we *need*
		# to know
		if ( !ref $nodeName ) {
			$self->error(
				"type union specified, but no nodename map given"
			);
		}
		while ( my ($nodeName, $type) = each %$nodeName ) {
			if ( not exists $t_c{$type} ) {
				$self->error(
"nodeName to type map specifies $nodeName => '$type', but $type is not"
						." an acceptable type",
				);
			}
		}
	}

	my $prefix_xx;

	# plug-in type classes.
	if (@expect_role) {
		my @users = map { $_->name } types_of(@expect_role);
		if ( $self->has_xml_nodeName and !ref $self->xml_nodeName ) {
			$self->error(
"Str value for xml_nodeName incompatible with specifying a role type "
					."constraint"
			);
		}
		$nodeName = {} if !ref $nodeName;
		for my $user (@users) {
			if ( $user->does("PRANG::Graph") ) {
				my $plugin_nodeName = $user->root_element;
				my $xmlns;
				if ( $xmlns = eval { $user->xmlns }//"" ) {
					if ( not exists $nodeName_r_prefix->{$xmlns} ) {
						$prefix_xx ||= "a";
						$prefix_xx++
							while exists $nodeName_prefix->{$prefix_xx};
						$nodeName_prefix->{$prefix_xx} = $xmlns;
						$nodeName_r_prefix->{$xmlns} = $prefix_xx;
					}
					$plugin_nodeName =
						"$nodeName_r_prefix->{$xmlns}:$plugin_nodeName";
				}
				if ( exists $nodeName->{$plugin_nodeName} ) {
					$self->error(
"Both '$user' and '$nodeName->{$plugin_nodeName}' plug-in type specify nodename $plugin_nodeName"
							.(
							$xmlns ? " (xmlns $xmlns)" : ""
							)
							.", conflict",
					);
				}
				$nodeName->{$plugin_nodeName} = $user;
			}
			else {
				$self->error(
					"Can't use one or more of role(s) @expect_role; "
						.$user->name
						." needs to consume role PRANG::Graph (hint: did you forget to \"with 'PRANG::Graph';\"?)",
				);
			}
			push @expect_type, $user;
			$expect_concrete++;
		}
		$self->xml_nodeName({%$nodeName});
		if ( !$self->has_xml_nodeName_prefix
			and keys %$nodeName_prefix )
		{   $self->xml_nodeName_prefix($nodeName_prefix);
		}
	}
	if (!$expect_concrete) {
		$self->error(
			"no type(s) specified (or, role evaluated to nothing)",
			)
	}

	if ( !ref $nodeName ) {
		my $expected = $expect_bool ? "Bool" :
			$expect_simple ? "Str" : $expect_type[0];
		$nodeName = { $nodeName => $expected };
		$self->xml_nodeName($nodeName);
	}

	# we will be using 'delete' with nodeName, so copy it
	$nodeName = {%$nodeName};

	# figure out the XML namespace of this node and set it on the
	# attribute
	my %xmlns_opts;
	if ( $self->has_xmlns ) {
		$xmlns_opts{xmlns} = $self->xmlns;
	}
	else {
		my $xmlns = eval { $self->associated_class->name->xmlns } // "";
		$xmlns_opts{xmlns} = $xmlns
			if $xmlns;  # FIXME - should *always* set it!
	}
	if ( $self->has_xmlns_attr ) {
		$xmlns_opts{xmlns_attr} = $self->xmlns_attr;
	}
	my $prefix_xmlns = sub {
		my $name = shift;
		if ( $nodeName_prefix and $name =~ /^(\w+):(\w+)/ ) {
			my %this_xmlns_opts = %xmlns_opts;
			my $xmlns = $nodeName_prefix->{$1}
				or die "unknown prefix '$1' used on attribute "
				.$self->name." of "
				.eval{$self->associated_class->name};
			$this_xmlns_opts{xmlns} = $xmlns;
			($2, \%this_xmlns_opts);
		}
		else {
			($name, \%xmlns_opts);
		}
	};

	my @expect;
	for my $class (@expect_type) {
		my (@names) = grep { $nodeName->{$_} eq $class }
			keys %$nodeName;

		# auto-load the classes now... save problems later
		if ( !eval{ $class->meta->can("marshall_in_element") } ) {
			my $ok = eval "use $class; 1";
			if ( !$ok ) {
				die
"problem auto-including class '$class'; (hint: did you expect '$class' to be a subtype, but forget to define it before it was used or not use BEGIN { } appropriately?); exception is: $@";
			}
		}
		if ( !eval{ $class->meta->can("marshall_in_element") } ) {
			die
"'$class' can't marshall in; did you 'use PRANG::Graph'?";
		}

		if ( !@names ) {
			die "type '$class' specified as allowed on '"
				.$self->name
				."' element of "
				.$self->associated_class->name
				.", but which node names indicate that type?  You've defined: "
				.(
				$self->has_xml_nodeName
				? ( ref $self->xml_nodeName
					? join(
						"; ",
						map { "$_ => ".$self->xml_nodeName->{$_} }
							sort keys %{$self->xml_nodeName}
						)
					: ("(all '".$self->xml_nodeName."')")
					)
				: "(nothing)"
				);
		}

		for my $name (@names) {
			my ($nn, $xmlns_args) =
				$prefix_xmlns->($name);
			push @expect, PRANG::Graph::Element->new(
				%$xmlns_args,
				attrName => $self->name,
				nodeClass => $class,
				nodeName => $nn,
			);
			delete $nodeName->{$name};
		}
	}

	if ($expect_bool) {
		my (@names) = grep {
			!$t_c{$nodeName->{$_}}->is_a_type_of("Object")
		} keys %$nodeName;

		# 'Bool' elements are a shorthand for the element
		# 'maybe' being there.
		for my $name (@names) {
			my ($nn, $xmlns_args) = $prefix_xmlns->($name);
			push @expect, PRANG::Graph::Element->new(
				%$xmlns_args,
				attrName => $self->name,
				attIsArray => $expect_many,
				nodeName => $nn,
			);
			delete $nodeName->{$name};
		}
	}
	if ($expect_simple) {
		my (@names) = grep {
			my $t_c = $t_c{$nodeName->{$_}};
			die "dang, "
				.$self->name." of "
				.$self->associated_class->name
				.", no type constraint called $nodeName->{$_} (element $_)"
				if !$t_c;
			!$t_c->is_a_type_of("Object")
		} keys %$nodeName;
		for my $name (@names) {

			# 'Str', 'Int', etc element attributes: this
			# means an XML data type: <attr>value</attr>
			if ( !length($name) ) {

				# this is for 'mixed' data
				push @expect, PRANG::Graph::Text->new(
					attrName => $self->name,
				);
			}
			else {

				# regular XML data style
				my ($nn, $xmlns_args) =
					$prefix_xmlns->($name);
				push @expect, PRANG::Graph::Element->new(
					%$xmlns_args,
					attrName => $self->name,
					nodeName => $nn,
					contents => PRANG::Graph::Text->new,
				);
			}
			delete $nodeName->{$name};
		}
	}

	# determine if we need explicit attributes to record the
	# nodename and/or XML namespace.

	# first rule.  If multiple prefix:nodeName entries map to the
	# same type, then we would have an ambiguous type map, and
	# therefore need at least one of name_attr and xmlns_attr
	my $have_ambiguous;
	my (%seen_types, %seen_xmlns, %seen_localname);
	my $fixed_xmlns = $self->xmlns;
	my $use_prefixes = $self->has_xml_nodeName_prefix;
	if ( $fixed_xmlns and $use_prefixes ) {
		$self->error(
"specify only one of 'xmlns' / 'xml_nodeName_prefix' (note: latter may be implied by use of roles)"
		);
	}
	while ( my ($element_fullname, $class) =
		each %{$self->xml_nodeName})
	{   my ($xmlns, $localname);
		if ($use_prefixes) {
			(my $prefix, $localname) =
				($element_fullname =~ /^(?:(\w+):)?(\w+|\*)/);
			$prefix //= "";
			$xmlns = $nodeName_prefix->{$prefix}//"";
		}
		else {
			$localname = $element_fullname;
			$xmlns = $fixed_xmlns//"";
		}

		$localname //= "";
		$seen_localname{$localname}++;
		$seen_xmlns{$xmlns}++;

		$have_ambiguous++ if $localname eq "*";
		$have_ambiguous++ if $xmlns eq "*";

		my $ent = [ $xmlns, $localname ];
		if ( my $aref = $seen_types{$class} ) {
			$have_ambiguous++;
			push @$aref, $ent;
		}
		else {
			$seen_types{$class} = [$ent];
		}
	}

	# if all nodes have the same localname, we can use just
	# xmlns_attr.  if all nodes have the same xmlns, we can use
	# just name_attr
	my @name_attr;
	if ($have_ambiguous) {
		if ( keys %seen_localname > 1 or $seen_localname{"*"} ) {
			if ( !$self->has_xml_nodeName_attr ) {
				$self->error(
"xml_nodeName map ambiguities or wildcarding imply need for "
						."xml_nodeName_attr, but none given",
				);
			}
			else {
				my $attr = $self->xml_nodeName_attr;
				push @name_attr, name_attr => $attr;
				for my $x (@expect) {
					$x->nodeName_attr($attr);
				}
			}
		}
		else {
			push @name_attr,
				xml_nodeName => (keys %seen_localname)[0]//"";
		}

		if ( keys %seen_xmlns > 1 or $seen_xmlns{"*"} ) {
			if ( !$self->has_xmlns_attr ) {
				$self->error(
"xml_nodeName map ambiguities or wildcarding imply need for "
						."xmlns_attr, but none given",
				);
			}
			else {
				my $attr = $self->xmlns_attr;
				push @name_attr, xmlns_attr => $attr;
				for my $x (@expect) {
					$x->xmlns_attr($attr);
				}
			}
		}
		else {
			push @name_attr, xmlns => (keys %seen_xmlns)[0]//"";
		}
	}
	elsif ( $self->has_xmlns_attr or $self->has_xml_nodeName_attr ) {
		$self->error(
			"unnecessary use of xmlns_attr / xml_nodeName_attr");
	}
	elsif ( $self->has_xml_nodeName ) {
		push @name_attr, type_map => {%{$self->xml_nodeName}};
		if ( $self->has_xml_nodeName_prefix ) {
			push @name_attr, type_map_prefix =>
				{%{$self->xml_nodeName_prefix}};
		}
	}

	if ( @expect > 1 ) {
		$node = PRANG::Graph::Choice->new(
			choices => \@expect,
			attrName => $self->name,
			@name_attr,
		);
	}
	else {
		$node = $expect[0];
		if ( $self->has_xml_nodeName_attr ) {
			$node->nodeName_attr($self->xml_nodeName_attr);
		}
	}

	if ($expect_bool) {
		$expect_one = 0;
	}
	if (    $expect_one
		and !$expect_simple
		and
		!$self->is_required and !$self->has_default
		)
	{
		$self->warn_of(
"expected element is not required, this can cause errors on marshall out"
		);

		# this is probably a bit harsh.
		#$self->meta->find_attribute_by_name("required")->set_value(
		#	$self, 1,
		#	);
	}

	# deal with limits
	if ( !$expect_one or $expect_many) {
		my @min_max;
		if ( $expect_one and !$self->has_xml_min ) {
			$self->xml_min(1);
		}
		if ( $self->has_xml_min ) {
			push @min_max, min => $self->xml_min;
		}
		if ( !$expect_many and !$self->has_xml_max ) {
			$self->xml_max(1);
		}
		if ( $self->has_xml_max ) {
			push @min_max, max => $self->xml_max;
		}
		die "no node!  fail!  processing "
			.$self->associated_class->name
			.", element "
			.$self->name
			unless $node;
		$node = PRANG::Graph::Quantity->new(
			@min_max,
			attrName => $self->name,
			child => $node,
		);
	}
	else {
		$self->xml_min(1);
		$self->xml_max(1);
	}

	return $node;
}

package Moose::Meta::Attribute::Custom::Trait::PRANG::Element;
$Moose::Meta::Attribute::Custom::Trait::PRANG::Element::VERSION = '0.18';
sub register_implementation {
	"PRANG::Graph::Meta::Element";
}

1;

=head1 NAME

PRANG::Graph::Meta::Element - metaclass metarole for XML elements

=head1 SYNOPSIS

 use PRANG::Graph;

 has_element 'somechild' =>
    is => "rw",
    isa => "Some::Type",
    xml_required => 0,
    ;

 # equivalent alternative - plays well with others!
 has 'somechild' =>
    is => "rw",
    traits => [qw/PRANG::Element/],
    isa => "Some::Type",
    xml_required => 0,
    ;

=head1 DESCRIPTION

The PRANG concept is that attributes in your classes are marked to
correspond with attributes and elements in your XML.  This class is
for marking your class' attributes as XML I<elements>.  For marking
them as XML I<attributes>, see L<PRANG::Graph::Meta::Attr>.

Non-trivial elements - and this means elements which contain more than
a single TextNode element within - are mapped to Moose classes.  The
child elements that are allowed within that class correspond to the
attributes marked with the C<PRANG::Element> trait, either via
C<has_element> or the Moose C<traits> keyword.

Where it makes sense, as much as possible is set up from the regular
Moose definition of the attribute.  This includes the XML node name,
the type constraint, and also the predicate.

If you like, you can also set the C<xmlns> and C<xml_nodeName>
attribute property, to override the default behaviour, which is to
assume that the XML element name matches the Moose attribute name, and
that the XML namespace of the element is that of the enclosing class
(ie, C<$class-E<gt>xmlns>), if defined.

The B<order> of declaring element attributes is important.  They
implicitly define a "sequence".  To specify a "choice", you must use a
union sub-type - see below.  Care must be taken with bundling element
attributes into roles as ordering when composing is not defined.

The B<predicate> property of the attribute is also important.  If you
do not define C<predicate>, then the attribute is considered
I<required>.  This can be overridden by specifying C<xml_required> (it
must be defined to be effective).

The B<isa> property (B<type constraint>) you set via 'isa' is
I<required>.  The behaviour for major types is described below.  The
module knows about sub-typing, and so if you specify a sub-type of one
of these types, then the behaviour will be as for the type on this
list.  Only a limited subset of higher-order/parametric/structured
types are permitted as described.

=over 4

=item B<Bool  sub-type>

If the attribute is a Bool sub-type (er, or just "Bool", then the
element will marshall to the empty element if true, or no element if
false.  The requirement that C<predicate> be defined is relaxed for
C<Bool> sub-types.

ie, C<Bool> will serialise to:

   <object>
     <somechild />
   </object>

For true and

   <object>
   </object>

For false.

=item B<Scalar sub-type>

If it is a Scalar subtype (eg, an enum, a Str or an Int), then the
value of the Moose attribute is marshalled to the value of the element
as a TextNode; eg

  <somechild>somevalue</somechild>

=item B<Object sub-type>

If the attribute is an Object subtype (ie, a Class), then the element
is serialised according to the definition of the Class defined.

eg, with;

   {
       package CD;
       use Moose; use PRANG::Graph;
       has_element 'author' => qw( is rw isa Person );
       has_attr 'name' => qw( is rw isa Str );
   }
   {
       package Person;
       use Moose; use PRANG::Graph;
       has_attr 'group' => qw( is rw isa Bool );
       has_attr 'name' => qw( is rw isa Str );
       has_element 'deceased' => qw( is rw isa Bool );
   }

Then the object;

  CD->new(
    name => "2Pacalypse Now",
    author => Person->new(
       group => 0,
       name => "Tupac Shakur",
       deceased => 1,
       )
  );

Would serialise to (assuming that there is a L<PRANG::Graph> document
type with C<cd> as a root element):

  <cd name="2Pacalypse Now">
    <author group="0" name="Tupac Shakur>
      <deceased />
    </author>
  </cd>

=item B<ArrayRef sub-type>

An C<ArrayRef> sub-type indicates that the element may occur multiple
times at this point.  Bounds may be specified directly - the
C<xml_min> and C<xml_max> attribute properties.

Higher-order types are supported; in fact, to not specify the type of
the elements of the array is a big no-no.

If C<xml_nodeName> is specified, it refers to the items; no array
container node is expected.

For example;

  has_attr 'name' =>
     is => "rw",
     isa => "Str",
     ;
  has_attr 'releases' =>
     is => "rw",
     isa => "ArrayRef[CD]",
     xml_min => 0,
     xml_nodeName => "cd",
     ;

Assuming that this property appeared in the definition for 'artist',
and that CD C<has_attr 'title'...>, it would let you parse:

  <artist>
    <name>The Headless Chickens</name>
    <cd title="Stunt Clown">...<cd>
    <cd title="Body Blow">...<cd>
    <cd title="Greedy">...<cd>
  </artist>

You cannot (currently) Union an ArrayRef type with other simple types.

=item B<Union types>

Union types are special; they indicate that any one of the types
indicated may be expected next.  By default, the name of the element
is still the name of the Moose attribute, and if the case is that a
particular element may just be repeated any number of times, this is
fine.

However, this can be inconvenient in the typical case where the
alternation is between a set of elements which are allowed in the
particular context, each corresponding to a particular Moose type.
Another one is the case of mixed XML, where there may be text, then
XML fragments, more text, more XML, etc.

There are two relevant questions to answer.  When marshalling OUT, we
want to know what element name to use for the attribute in the slot.
When marshalling IN, we need to know what element names are allowable,
and potentially which sub-type to expect for a particular element
name.

After applying much DWIMery, the following scenarios arise;

=over

=item B<1:1 mapping from Type to Element name>

This is often the case for message containers that allow any number of
a collection of classes inside.  For this case, a map must be provided
to the C<xml_nodeName> function, which allows marshalling in and out
to proceed.

  has_element 'message' =>
      is => "rw",
      isa => "my::unionType",
      xml_nodeName => {
          "nodename" => "TypeA",
          "somenode" => "TypeB",
      };

It is an error if types are repeated in the map.  The empty string can
be used as a node name for text nodes, otherwise they are not allowed.

This case is made of win because no extra attributes are required to
help the marshaller; the type of the data is enough.

An example of this in practice;

  subtype "My::XML::Language::choice0"
     => as join("|", map { "My::XML::Language::$_" }
                  qw( CD Store Person ) );

  has_element 'things' =>
     is => "rw",
     isa => "ArrayRef[My::XML::Language::choice0]",
     xml_nodeName => +{ map {( lc($_) => $_ )} qw(CD Store Person) },
     ;

This would allow the enclosing class to have a 'things' property,
which contains all of the elements at that point, which can be C<cd>,
C<store> or C<person> elements.

In this case, it may be preferrable to pass a role name as the element
type, and let this module evaluate construct the C<xml_nodeName> map
itself.

=item B<more types than element names>

This happens when some of the types have different XML namespaces; the
type of the node is indicated by the namespace prefix.

In this case, you must supply a namespace map, too.

  has_element 'message' =>
      is => "rw",
      isa => "my::unionType",
      xml_nodeName => {
          "trumpery:nodename" => "TypeA",
          "rubble:nodename" => "TypeB",
          "claptrap:nodename" => "TypeC",
      },
      xml_nodeName_prefix => {
          "trumpery" => "uri:type:A",
          "rubble" => "uri:type:B",
          "claptrap" => "uri:type:C",
      },
      ;

B<FIXME:> this is currently unimplemented.

=item B<more element names than types>

This can happen for two reasons: one is that the schema that this
element definition comes from is re-using types.  Another is that you
are just accepting XML without validation (eg, XMLSchema's
C<processContents="skip"> property).  In this case, there needs to be
another attribute which records the names of the node.

  has_element 'message' =>
      is => "rw",
      isa => "my::unionType",
      xml_nodeName => {
          "nodename" => "TypeA",
          "somenode" => "TypeB",
          "someother" => "TypeB",
      },
      xml_nodeName_attr => "message_name",
      ;

If any node name is allowed, then you can simply pass in C<*> as an
C<xml_nodeName> value.

=item B<more namespaces than types>

The principle use of this is L<PRANG::XMLSchema::Whatever>, which
converts arbitrarily namespaced XML into objects.  In this case,
another attribute is needed, to record the XML namespaces of the
elements.

  has 'nodenames' =>
	is => "rw",
	isa => "ArrayRef[Maybe[Str]]",
        ;

  has 'nodenames_xmlns' =>
	is => "rw",
	isa => "ArrayRef[Maybe[Str]]",
	;

  has_element 'contents' =>
      is => "rw",
      isa => "ArrayRef[PRANG::XMLSchema::Whatever|Str]",
      xml_nodeName => { "" => "Str", "*" => "PRANG::XMLSchema::Whatever" },
      xml_nodeName_attr => "nodenames",
      xmlns => "*",
      xmlns_attr => "nodenames_xmlns",
      ;

B<FIXME:> this is currently unimplemented.

=item B<unknown/extensible element names and types>

These are indicated by specifying a role.  At the time that the
L<PRANG::Graph::Node> is built for the attribute, the currently
available implementors of these roles are checked, which must all
implement L<PRANG::Graph>.

They Treated as if there is an C<xml_nodeName> entry for the class,
from the C<root_element> value for the class to the type.  This allows
writing extensible schemas.

=back

=back

=head1 SEE ALSO

L<PRANG::Graph::Meta::Attr>, L<PRANG::Graph::Meta::Element>,
L<PRANG::Graph::Node>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut
