use strict;

package Salvation::MacroProcessor;

our $VERSION = 0.93;

use Moose;
use Moose::Exporter ();
use Moose::Util::MetaRole ();

use Salvation::MacroProcessor::Connector ();
use Salvation::MacroProcessor::MethodDescription ();


Moose::Exporter -> setup_import_methods( with_meta => [ 'smp_add_description', 'smp_add_share', 'smp_add_alias', 'smp_add_connector', 'smp_import_descriptions', 'smp_import_shares' ] );


sub init_meta
{
	my ( undef, %args ) = @_;

	Moose -> init_meta( %args );

	return &Moose::Util::MetaRole::apply_metaroles(
		for             => $args{ 'for_class' },
		class_metaroles => {
			class => [ 'Salvation::MacroProcessor::Meta::Role' ]
		}
	);
}

sub smp_add_description
{
	my ( $meta, $name, %args ) = @_;

	$args{ 'method' }          = $name;
	$args{ 'associated_meta' } = $meta;

	$meta -> smp_add_description( Salvation::MacroProcessor::MethodDescription -> new( %args ) );

	return 1;
}

sub smp_add_share
{
	my ( $meta, $name, $code ) = @_;

	$meta -> smp_add_share( $name => $code );

	return 1;
}

sub smp_add_alias
{
	my ( $meta, $alias, $name ) = @_;

	$meta -> smp_add_alias( $alias => $name );

	return 1;
}

sub smp_add_connector
{
	my ( $meta, $name, %args ) = @_;

	$args{ 'name' }            = $name;
	$args{ 'associated_meta' } = $meta;

	$meta -> smp_add_connector( Salvation::MacroProcessor::Connector -> new( %args ) );

	return 1;
}

sub smp_import_descriptions
{
	my ( $meta, %args ) = @_;

	$meta -> smp_import_descriptions( { %args } ); # yes, this is copying

	return 1;
}

sub smp_import_shares
{
	my ( $meta, %args ) = @_;

	$meta -> smp_import_shares( { %args } ); # yes, this is also copying

	return 1;
}


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

__END__

# ABSTRACT: Macros definition and processing engine

=pod

=head1 NAME

Salvation::MacroProcessor - Macros definition and processing engine

=head1 DESCRIPTION

=head2 What is it?

B<Salvation::MacroProcessor> is another architectural solution.

It is aimed to help to avoid code doubling and increase re-usability of code snippets by providing some kind of macros definition and processing engine.

It provides an architecture and a core functions, but leaves creation of the code that will actually do something up to you.

=head2 What should I do to use it?

First of all, you should use L<Moose>.

Next, you should define a L<Salvation::MacroProcessor::Hook>-derived class with specific name and methods.

Next, you should define method descriptions. Consider using functions from B<Salvation::MacroProcessor> or L<Salvation::MacroProcessor::ForRoles> modules for this.

Then you'll be able to use your descriptions via L<Salvation::MacroProcessor::Spec> module.

=head2 Can I look at some example besides tests?

Oh, yes, you can.

Say we have a class C<Class1>:

 package Class1;

 use Moose;

 no Moose;

This is a base class for, say, our little ORM. It has method named C<get_many> which selects any arbitrary amount of rows from database and returns each row as a C<Class1> class instance.

 sub get_many
 {
 	my ( $self, @query ) = @_;

	my @rows = &do_real_db_select_and_make_objects( $self, \@query ); # content of this function does not mean anything for us

	return &create_iterator( \@rows ); # this somehow creates an iterator object which does L<Salvation::MacroProcessor::Iterator::Compliance> role
 }

C<Class1> also has some methods matching column names:

 sub id; # is primary key
 sub column1;
 sub column2;
 sub column3;

. And sometimes you need to query database with following conditions:

 where ( ( column1 = 'some value' and column2 is null and column3 is not null ) or ( column1 is null and column2 = 'some other value' ) )

. You're doing it using your ORM, which results in, say, following call:

 my $it = Class1 -> get_many(
 	_clause => [
		cond => [
			_clause => [
				cond => [
					column1 => 'some value',
					column2 => { is => undef },
					column3 => { 'is not' => undef }
				]
			],
			_clause => [
				cond => [
					column1 => { is => undef },
					column2 => 'some other value'
				]
			]
		],
		logic => 'or'
	]
 )

. And every time you need to make this query - you need to take this call with you. Of course you can put in inside some function, then call that function to retrieve your conditions and be happy. Then you will encounter the need to mix this query with some other parts, or change it slightly, and your function you used to retrieve your conditions could grow if it has been written without future in mind. Alright, let's imagine you are the best and you've done everything right here. Doesn't matter. Moving forward.

You already have a method inside C<Class1>, which will check if current instance matches criteria above, or not:

 sub check_if_this_is_the_object;

This method does return C<true> or C<false>, checking your object. So, when you need to select objects, you use your C<get_many> call with arguments, and when you need to check one object - you call C<check_if_this_is_the_object>. Kinda not unified.

Well then, let's see what you can do.

Let's define a class named C<Salvation::MacroProcessor::Hooks::Class1> and define two methods: one to select objects and one to check existing objects.

 package Salvation::MacroProcessor::Hooks::Class1;

 use Moose;

 extends 'Salvation::MacroProcessor::Hooks';

 sub select
 {
 	my ( $self, $spec, $additional_query ) = @_;

 	my $it = $spec -> class() -> get_many( @{ $spec -> query() }, @$additional_query ); # select many objects

	return Salvation::MacroProcessor::Iterator -> new(
		postfilter => sub{ $spec -> __postfilter_each( shift ) }, # kind of common statement
		iterator => $it
	);
 }

 sub check
 {
 	my ( $self, $spec, $object ) = @_;

	my $it = $self -> select( $spec, [ _id => $object -> id() ] );

	my $cnt = 0;
	my $db_object = undef;

	while( defined( my $row = $it -> next() ) )
	{
		die if $cnt ++;

		$db_object = $row;
	}

	return ( defined( $db_object ) and ( $object -> id() == $db_object -> id() ) ); # check if got the same object
 }

 no Moose;

Then let's add description for method of C<Class1> and apply a role aimed to simplify our life:

 use Salvation::MacroProcessor;

 with 'Salvation::MacroProcessor::Role';

 smp_add_description check_if_this_is_the_object => (
 	query => sub
	{
		my $value = shift;

		return ( $value ? \@criteria_from_the_example_above : \@inverted_version_of_the_criteria_above );
	}
 );

. So now we have hook - implementation of our specific logic of querying database, and also we have one description for a method. So we can do this:

 my $it = Class1 -> smp_select(
 	[ check_if_this_is_the_object => true ] # to select some objects matching criteria
 );

 my $it = Class1 -> smp_select(
 	[ check_if_this_is_the_object => false ]
 );

 my $bool = $Class1_instance -> smp_check(
 	[ check_if_this_is_the_object => true ] # to check one object to match criteria
 );

 my $bool = $Class1_instance -> smp_check(
 	[ check_if_this_is_the_object => false ]
 );

. And also we could easily mix this criteria with other ones which will be needed in the future. Needless to say we have an implementation of C<check_if_this_is_the_object> criteria not only in one separate place, but in the nearest place to the class: inside this class.

Later, if we want to create class C<Class2> which will be a C<Class1>-derived class,

 package Class2;

 use Moose;

 extends 'Class1';

 no Moose;

, we don't need to do anything else to use B<Salvation::MacroProcessor> then what we have already done. That is, you need to do nothing: don't need to create the same description as for parent class, don't need to create another hook, nothing! You're provided with full B<Salvation::MacroProcessor> functionality inherited from parent class right out-of-the-box.

This is key concept of B<Salvation::MacroProcessor> and its method descriptions which could be defined once and reused endless amount of times, easily mixed with other descriptions, imported from other classes via connectors, and so on.

You can continue reading the docs for appropriate base classes and other modules, read the tests, or just experiment by yourself to learn more about B<Salvation::MacroProcessor>.

=head1 REQUIRES

L<Moose> 

=head1 FUNCTIONS

=head2 smp_add_description

 smp_add_description some_method_name => (
 	query => $query,
	postfilter => $postfilter,
	required_shares => $required_shares,
	required_filters => $required_filters,
	excludes_filters => $excludes_filters
 );

Create description for method.

Method descriptions are the thing we are here for.

Each argument besides C<some_method_name> is optional, though it should have at least C<query> specified for description to make any sense.

=over

=item some_method_name

String, is a name of a method that is already present in your class.

As L<Salvation::MacroProcessor> is for describing methods which are already present, for the sake of semantics you should always already have a method being described, though its implementation is not strict to not relay on such method's description.

Is also a name of description.

=item query

ArrayRef or CodeRef, represents query part which needs to be applied to the query to get an object which satisfies specified criteria.

When ArrayRef, it won't be modified anyhow, but will be applied to the query as-is.

When CodeRef, it should return an ArrayRef which will be then applied to the query. Supplied function should match one of the following signatures:

=over

=item ( Any $value )

Where C<$value> is, well, a value supplied by you, or any other developer, as a condition for the filter.

Function should match this signature when B<no> C<required_shares> is specified.

=item ( HashRef[ArrayRef[Any]] $shares, Any $value )

Where C<$shares> contains data returned by your shares' code. I.e., if you have defined a share like this:

 smp_add_share my_share => sub
 {
 	return MyShareObject -> new();
 };

, and C<$required_shares> is following ArrayRef:

 [ 'my_share' ]

, then C<$shares> will be somewhat like that:

 { my_share => [ $MyShareObject_instance ] }

. You can safely access C<$MyShareObject_instance> from your C<$query> and make any manipulations you want.

Meaning of C<$value> is unchanged from what have been said previously.

Function should match this signature when C<required_shares> B<is> specified.

=back

=item postfilter

A CodeRef matching following signature:

 ( Any $object, Any $value )

, where C<$value> is a value supplied by you, or any other developer, as a condition for the filter, and C<$object> is an object representing a single row of data returned by the query.

This code is executed for each C<$object> returned by the query in order to filter object list before returning it to a caller.

Boolean value should be returned, C<false> means "skip this object" and C<true> means "yes, this object is what we want".

=item required_shares

An ArrayRef of shares' names which are required by this filter and which will be passed to C<query>' CodeRef.

=item required_filters

An ArrayRef of other descriptions' names which you are required to use in order to use this one. If at least one is missing from your query - an error will be thrown.

=item excludes_filters

An ArrayRef of other descriptions' names which should B<not> be used together with this one. If at least one is included in your query - an error will be thrown.

=back

=head2 smp_add_alias

 smp_add_alias 'synonym' => 'original name';

Create an alias for description.

=head2 smp_add_connector

 smp_add_connector 'custom connector name' => (
 	required_shares => $required_shares,
	code => $code
 );

Create a connector. Connectors are used to import descriptions from other classes.

C<required_shares> has the same requirements and meaning as an argument of the same name of B<smp_add_description> function.

C<code> is a CodeRef and has the same requirements as the C<query> argument of B<smp_add_description> function, though its meaning is different.

C<$code> is called when we need to include filters from different class in a query. It is used to wrap query parts of such foreing descriptions and then apply them to current query. C<$value> passed to the C<$code> call is always of type C<ArrayRef[Any]>, instead of plain C<Any> as in B<smp_add_description>' C<$query>, and this array could contain anything that is specified by you as query parts in descriptions, in almost any combinations.

Let's check out the example. Imagine that you have class C<Class1> which has something like that:

 smp_add_description some_method => (
 	query => [
		column => 'value'
	]
 );

. Also you have class C<Class2> which in its case has something like that:

 smp_add_description some_other_method => (
 	query => [
		other_column => 'other value'
	]
 );

 smp_add_connector 'Class1 connector' => (
 	code => sub
	{
		my $value = shift;

		# $value here is always an ArrayRef

		return [ class1_descriptions => $value ];
	}
 );

 smp_import_descriptions
 	class => 'Class1',
	prefix => 'c1_',
	connector => 'Class1 connector'
 ;

. Then, you are trying to execute following query using C<Class2> as base object:

 [
 	[ c1_some_method => 'dummy' ],
	[ some_other_method => 'dummy' ]
 ]

. Such query will be expanded into following object using specified connector:

 [
 	other_column => 'other value',
	class1_descriptions => [
		column => 'value'
	]
 ]

.

C<required_shares> is an optional argument, C<code> is a required one.

=head2 smp_add_share

 smp_add_share 'some name' => $code;

Create a share.

Shares are implementation of user-defined instance-wide static variables for query object, kind of like L<Moose>' attributes (see L<Moose::Menual::Attributes>), but much lighter. In fact, shares are most like "builder" definitions.

Each share has only two properties: name (C<'some name'> in the example above) and factory code (C<$code> in the example above).

C<$code> is a CodeRef.

C<$code> is executed no more than one time for one query. C<$code> function is called when a description requiring this share is encountered during query composition and a value for this share has not been initialized for current query object yet.

C<$code> is always executed in a list context.

C<$code> could C<return> any amount of objects of any type, including an amount equal to zero. These results will be provided to you as-is.

=head2 smp_import_descriptions

 smp_import_descriptions
 	class => $class,
	prefix => $prefix,
	list => $list,
	connector => $connector
 ;

Import descriptions from another class.

Arguments:

=over

=item class

String, a name of a class from which descriptions will be imported.

This class should be loaded manually in order to import descriptions.

Note that actual import is lazy: each description will be imported at the time it first being required by the query, though it may be necessary to load C<$class> class before B<smp_import_descriptions> statement in order to get the list of C<$class>' methods. See C<list> argument documentation for more details.

=item prefix

String, custom prefix which will be applied to each and every description name.

Optional argument.

Imagine that you have class C<Class1> which in its case has description for method C<method>. You also have class C<Class2> which has this:

 smp_import_descriptions
 	class => 'Class1',
	prefix => 'some_prefix_',
	connector => $connector
 ;

. It means that description for method C<method> of class C<Class1> will be exposed to class C<Class2> as description with the name C<some_prefix_method>.

It also is used to prefix each element of C<required_shares>, C<required_filters> and C<excludes_filters> lists of each imported descriptions, though prefixed shares' and filters' names will be used for internal checks only.

=item list

ArrayRef, a list of descriptions' names to be imported.

Optional argument.

If specified, this list will be trusted and no additional checks for existense of such methods in the C<$class> class will be executed. So the class C<$class> could be loaded anytime later, before actual usage of imported descriptions.

If omitted, the system will try to build the list itself, accessing C<$class> immediately at B<smp_import_descriptions> call, requiring C<$class> class to be loaded.

=item connector

String, name of connector which will be used to import descriptions.

=back

=head2 smp_import_shares

 smp_import_shares
 	class => $class,
	prefix => $prefix,
	list => $list
 ;

Import shares from another class.

Mostly the same as B<smp_import_descriptions>, but works with shares instead of descriptions and has no C<connector> argument as it is not necessary here.

If you're importing descriptions which require some shares - you should either define such shares in your target class, or import such descriptions from source class.

=cut

