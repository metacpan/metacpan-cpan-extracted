package Oryx::Class;

use Carp qw(carp croak);
use UNIVERSAL qw(isa can);
use Scalar::Util qw(weaken);
use warnings;
use strict;
no strict 'refs';

use base qw(Class::Data::Inheritable Class::Observable);

=head1 NAME

Oryx::Class - abstract base class for Oryx classes

=head1 SYNOPSIS
 
 # define a persistent class
 package CMS::Page;
 use base qw(Oryx::Class);
  
 # ... class meta-data here (see DEFINING CLASS META-DATA below) ...
  
 1;
  
 #===========================================================================
 # use a persistent class
 use CMS::Page;
  
 $page = CMS::Page->create({title => 'Life in the Metaverse'});
 $page = CMS::Page->retrieve($id);
  
 $page->update;
 $page->delete;
  
 @pages = CMS::Page->search({author => 'Richard Hun%'}, \@order, $limit, $offset);
  
 #===========================================================================
 # commit your changes
 $page->dbh->commit; # or simply ...
 $page->commit;
  
 #===========================================================================
 # attribute mutator
 $page->title('The Metamanic Mechanic');
 $tite = $page->title;
  
 #===========================================================================
 # reference association mutator
 $template_obj = $page->template;
 $page->template( $template_obj );
  
 #===========================================================================
 # array association accessor
 $page->paragraphs->[0] = $intro_para;
 $paragraph = $page->paragraphs->[42];
  
 #===========================================================================
 # array association operators
 $concl = pop   @{$page->paragraphs};
 $intro = shift @{$page->paragraphs};
 push    @{$page->paragraphs}, $concl;
 unshift @{$page->paragraphs}, $new_intro;
 splice  @{$page->paragraphs}, 1, 4, ($summary);
  
 #===========================================================================
 # hash association accessor
 $image_obj = $page->images->{logo};
 $page->images->{mug_shot} = $my_ugly_mug;
 @keys   = keys   %{$page->images};
 @values = values %{$page->images};
  
 #===========================================================================
 # support for Class::Observable
 Page->add_observer(sub {
     my ($item, $action) = @_;
     #...
 }); 
 $page->add_observer(...); # instance

=head1 DESCRIPTION

Abstract base class for Oryx persistent classes.

=head1 ABSTRACT METHODS

These methods are overridden by the implementing Class class, i.e.
L<Oryx::DBI::Class> or L<Oryx::DBM::Class>, for example, but the
interfaces stay the same, so they are documented here.

=over

=item B<create( \%proto )>

creates a persistent object using C<\%proto> to set up the initial state.

=item B<retrieve( $oid )>

retrieves an object from storage by its object id

=item B<update>

updates storage to persist and reflect changes in the object

=item B<delete>

deletes the object from storage

=item B<search( \%param, [ \@order, $limit, $offset ] )>

searches for objects with fields matching C<\%param>. SQL style
C<%> wildcards are supported. C<\@order>, C<$limit> and C<$offset> are
optional. C<\@order> is a list of columns which are used to sort the
results, C<$limit> is an integer which is used to limit the number of
results, and C<$offset> is used to exclude the first results up to
that number. These last two arguments are useful for paging through
search results.

=item B<commit>

commits the transaction if your database supports it and AutoCommit
is disabled, then you must do this.

=back

=head2 Observers

Oryx::Class objects now unherit from L<Class::Observable> thereby
implementing a publish/subscribe system similar to triggers.

The signals are named according to the 6 interface methods prefixed with
I<before_*> and I<after_*>, so the following signals are sent:

=over 4

=item before_create

Handler is passed a hashref as argument with fields: C<param>, the search parameters, and C<query>, the L<SQL::Abstract> where clause

=item after_create

Handler is passed a hashref as argument with fields: C<param>, the search parameters, and C<proto>, the hashref which will be blessed into an instance of this class (during 'construct')

=item before_retrieve

Handler is passed a hashref as argument with fields: C<id>, the id of the object to fetch, and C<query>, the L<SQL::Abstract> where clause

=item after_retrieve

Handler is passed a hashref as argument with fields: C<proto>, the hashref which will be blessed into an instance of this class (during 'construct')

=item before_update

Handler is passed a hashref as argument with fields: C<query>, the L<SQL::Abstract> where clause.

=item after_update

Handler takes no arguments.

=item before_delete

Handler is passed a hashref as argument with fields: C<query>, the L<SQL::Abstract> where clause.

=item after_delete

Handler takes no arguments.

=item before_search

Handler is passed a hashref as argument with fields: C<query>, the L<SQL::Abstract> where clause, C<param>, the search parameters, the C<order> and C<limit> parameters.

=item after_search

Handler is passed a hashref as argument with fields: C<query>, the L<SQL::Abstract> where clause, C<param>, the search parameters, the C<order> and C<limit> parameters, and C<objects>, an arrayref of objects returned by the search.

=item before_construct

Handler is passed a hashref as argument with fields: C<proto>, the hashref which will be blessed into an instance of this class.

=item after_construct

Handler is passed a hashref as argument with fields: C<object>, the persistent object.

=back


=cut

use vars qw($XML_DOM_Lite_Is_Available);

BEGIN {
    __PACKAGE__->mk_classdata("auto_deploy");
    __PACKAGE__->mk_classdata("dont_cache");

    $XML_DOM_Lite_Is_Available = 1;
    eval "use XML::DOM::Lite qw(Parser Node :constants);";
    $XML_DOM_Lite_Is_Available = 0 if $@;
}

our $DEBUG = 0;
our $PARSER;

sub parser {
    $PARSER = Parser->new( whitespace => 'strip' ) unless defined $PARSER;
    $PARSER;
}

our %Orphans;

# Object Cache
our %Live_Objects;

=head1 METHODS

These methods are concrete.

=over

=item init

Initialises the class data (see L<Class::Data::Inheritable>)

=cut

sub init {
    my $class = shift;
    $DEBUG && $class->_carp('initializing class data');

    # set up class data accessors :
    $class->mk_classdata("_meta");
    $class->mk_classdata("attributes");
    $class->mk_classdata("associations");
    $class->mk_classdata("methods");
    $class->mk_classdata("parents");

    # DATA section cache
    $class->mk_classdata('dataNode');

    $class->meta({});
    $class->attributes({});
    $class->associations({});
    $class->methods({});
    $class->parents([]);

    ${ $class.'::__initialized' } = 1;
}

=item import

Does the work of constructing the class' meta-instances
(L<Oryx::Attribute>, L<Oryx::Association> and L<Oryx::Parent>
instances) from the C<$shema> class variable or defined
in the DATA section of the module if you have L<XML::DOM::Lite>
installed.

=cut

sub import {
    my $class = shift;
    my %param = @_;

    $DEBUG>1 && $class->_carp("importing...");

    if ($class eq __PACKAGE__ and defined $param{auto_deploy}) {
        $class->auto_deploy($param{auto_deploy});
        return; # not interested in doing anything further
    }
    return if $class eq __PACKAGE__
        or $class eq 'Oryx::MetaClass'
        or $class =~ /Oryx::[^:]+::Class/;

    if (${ $class.'::__initialized' }) {
        $DEBUG>1 && $class->_carp('already initialized, returning');
        return;
    }

    if (can($class, 'storage') and $class->storage) {
	if (%Orphans) {
            foreach (keys %Orphans) {
                $DEBUG>1 && $_->_carp('YAY! I am no longer an Orphan');
	        $class->storage->schema->addClass($_)
            }
	    %Orphans = ();
	}
	$class->storage->schema->addClass($class);
    } else {
        $DEBUG && $class->_carp("no storage available Orphaning");
	$Orphans{$class}++;
        $class->auto_deploy($param{auto_deploy})
            if defined $param{auto_deploy};
        return;
    }

    # initialise class data
    $class->init;
    $DEBUG && $class->_carp("setting up...");

    # first set up parent relationships (this doesn't *have* to be
    # done first, but I believe that the chicken came before the
    # egg... the are, as always, good semantic and performance reasons
    # behind this belief... if not behind this particular fragment of
    # code being here instead of at the bottom of this function).
    foreach (@{$class.'::ISA'}) {
	# only if the superclass is a subclass of Oryx::DBx::Class
	if (isa($_, __PACKAGE__)
        and $_ ne __PACKAGE__
        and $_ !~ /Oryx::[^:]+::Class/) {
	    $class->addParent($_);
	}
    }

    my $schema;
    unless ($schema = ${$class.'::schema'})  {
        my $xmldata = $class->parseDataIO;
        eval(q{use Oryx::Schema::Generator});
        die $@ if $@;
        $schema = Oryx::Schema::Generator->generate($class, $xmldata);
    }
    if ($schema) {
        $class->name($schema->{name}) if defined $schema->{name};
	foreach (@{$schema->{attributes}}) {
	    $class->addAttribute($_);
	}
	foreach (@{$schema->{associations}}) {
	    $class->addAssociation($_);
	}
	foreach (@{$schema->{methods}}) {
	    $class->addMethod($_);
	}
    }
    if ($class->auto_deploy or $param{auto_deploy}) {
	unless ($class->storage->util->table_exists(
        $class->dbh, $class->table)) {
	    $class->storage->deploy_class($class);
	}
    }
    if ($param{dont_cache}) { $class->dont_cache(1) }
}

=item meta

Simple accessor to the class meta data.

=cut

sub meta {
    my $class = shift;
    $class->_meta(shift) if @_;
    $class->_meta;
}

=item construct( $class, $proto )

This is typically called from within the C<create> and C<retrieve>
methods of the implementation class (L<Oryx::DBI::Class> or 
<Oryx::DBM::Class, for example) which then blesses C<$proto>
into C<$class> and then allows each class meta-instance to frobnicate
it in turn if they have any need to, before handing the instance to
you.

=cut

sub construct {
    my ($class, $proto) = @_;

    my $object;
    my $key = $class->_mk_cache_key($proto->{id});
    return $object if ($object = $Live_Objects{$key});

    $class->notify_observers('before_construct', { proto => $proto });
    $object = bless $proto, $class;

    $_->construct($object) foreach $class->members;
    $_->construct($object) foreach @{$class->parents};

    $class->notify_observers('after_construct', { object => $object });
    $DEBUG && $class->_carp("constructing $object id => ".$object->id);

    weaken($Live_Objects{$key} = $object) unless $object->dont_cache;
    return $object;
}

=item addAttribute( $meta )

Creates an Attribute meta-instance and associates it with the class.

=cut

sub addAttribute {
    my ($class, $meta) = @_;
    my $attrib =
        (ref($class->storage).'::Attribute')->new($meta, $class);
    $class->attributes->{$attrib->name} = $attrib;
}

=item addAssociation( $meta )

Creates an Association meta-instance and associates it with the class.

=cut

sub addAssociation {
    my ($class, $meta) = @_;
    my $assoc =
        (ref($class->storage).'::Association')->new($meta, $class);
    $class->associations->{$assoc->role} = $assoc;
}

=item addMethod( $meta )

Does nothing at the moment as I cannot decide what such a method
would be used for exactly.

=cut

sub addMethod {
    my ($class, $meta) = @_;
    my $methd =
        (ref($class->storage).'::Method')->new($meta, $class);
    $class->methods->{$methd->name} = $methd;
}

=item addParent( $super )

Creates a Parent meta-instance and associates it with the class.

=cut

sub addParent {
    my ($class, $super) = @_;
    push @{$class->parents},
        (ref($class->storage).'::Parent')->new($super, $class);
}

=item id

Returns the object id.

=cut

sub id { $_[0]->{id} }

=item is_abstract

True if the class does not define any attributes. This is used
for creating a special table for sharing sequences accross subclasses
and for instantiating the correct subclass instance if C<retrieve()>
is called on an abstract class.

=cut

sub is_abstract {
    my $class = shift;
    return not %{$class->attributes};
}

=item table

Returns the table name for this class.

=cut

sub table {
    my $class = shift;
    unless (defined $class->meta->{table}) {
	$class->meta->{table} = $class->schema->prefix.$class->name;
    }
    $class->meta->{table};
}

=item name([ $name ])

Get or set the C<name> meta-attribute for the class.

=cut

sub name {
    my $class = shift;
    my $name  = shift;
    $class->setMetaAttribute("name", $name) if $name;
    unless (defined $class->getMetaAttribute("name")) {
	$class =~ /([^:]+)$/;
	$class->setMetaAttribute("name", lc("$1"));
    }
    $class->getMetaAttribute("name");
}

=item members

Return a list of all meta-instances (Attribute, Association, Method
and Parent instances).

=cut

sub members {
    my $class = shift;
    return (
        values %{$class->attributes},
	values %{$class->associations},
	values %{$class->methods},
        # not really members, but we'll treat the same
	#@{$class->parents},
    );
}

=item commit

calls $self->dbh->commit to commit the trasaction

=cut

sub commit { $_[0]->dbh->commit }

=item schema

shortcut for $self->storage->schema. Read only.

=cut

sub schema { $_[0]->storage->schema }

sub parseDataIO {
    my ($class) = @_;
    unless ($XML_DOM_Lite_Is_Available) {
	$class->_carp('XML DATA schemas are not supported unless'
		      .' you have XML::DOM::Lite installed');
	return undef;
    }
    my $stream = $class->loadDataIO;
    if ($stream) {
        return $class->parser->parse($stream)->documentElement;
    } else {
	return undef;
    }
}

sub loadDataIO {
    my $class = shift;
    my $fh = *{"$class\::DATA"}{IO};
    return undef unless $fh;
    local $/ = undef;
    my $stream = <$fh>;
    return $stream;
}

=item remove_from_cache

Object method to remove it from the memory cache.

=cut

sub remove_from_cache {
    my $self = shift;
    my $key = $self->_mk_cache_key($self->id);
    CORE::delete( $Live_Objects{$key} );
}

sub _mk_cache_key {
    my $class = ref($_[0]) || $_[0];
    my $id = $_[1];
    return join('|', ( $class, $id ));
}

sub _carp {
    my $thing = ref($_[0]) ? ref($_[0]) : $_[0];
    carp("[$thing] $_[1]");
}

sub _croak {
    my $thing = ref($_[0]) ? ref($_[0]) : $_[0];
    croak("[$thing] $_[1]");
}

sub DESTROY { $_[0]->remove_from_cache }

1;
__END__

=head1 CREATING PERSISTENT CLASSES

Creating persistent classes is simple, there is no need to create any
database tables by hand as the DB schema is deployed automatically as
needed (see L</"AUTOMATIC TABLE CREATION"> below).

The following three steps illustrate how this is done:

=over

=item B<< Inherit from Oryx::Class or subclass thereof (see L</INHERITANCE> below) >>:

 package CMS::Page;
 use base qw(Oryx::Class);

=item B<< Define meta-data (see L</"DEFINING CLASS META-DATA"> below) >>:

 our $schema = {
     attributes => [{
         name  => 'title',
         type  => 'String',
     },{
         name  => 'author',
         type  => 'String',
     },{
         name  => 'number',
         type  => 'Integer',
     }],
     associations => [{
         role  => 'paragraphs',
         class => 'CMS::Paragraph',
         type  => 'Array',
     },{
         role  => 'template',
         class => 'CMS::Template',
         type  => 'Reference',
     }],
 };
 
 1;

=item B<< Connect to storage (see L</"CONNECTING TO STORAGE"> below) >>:

...far away in another piece of code...

 use CMS::Page;
 
 use Oryx;
 Oryx->connect(["dbi:Pg:dbname=cms", $usname, $passwd]);
 
 ...

=back

Now we're ready to start using persistent CMS::Page objects (and friends).

=head1 CREATING AND USING OBJECTS

Oryx::Class defines a I<create> method (see L<Oryx::Class> for more)
which takes a hash reference as a constructor for setting up the
object's initial state:

     use CMS::Page;
     my $page = CMS::Schema::Page->create({
         title  => 'Meta Model Mania',
         author => 'Sam Vilain',
     });

Once an object has been instatiated, attribute mutators can be used to
get and set attributes on the object (see L</ATTRIBUTES> below):

     $page->number(42);

Associations are similar except that we associate one object with
another (see L</ASSOCIATIONS> below), so we create an instance of the
target class:

     my $paragraph1 = CMS::Paragraph->create({
         content => $some_block_of_text,
     });

And then, because the association mutator returns a reference to a
tied object (an ARRAY in this case), we can:

     $page->paragraphs->[0] = $paragraph1;

Then update your object when done:

     $page->update;

Or if you no longer need it:

     $page->delete;

Finally, commit your changes:

     $page->commit;

=head1 DEFINING CLASS META-DATA

Three ways of defining meta data for your persistent classes are
supported as follows:

=over

=item B<Tangram style using a $schema class variable>:

 package CMS::Page;
 use base qw(Oryx::Class);
 
 our $schema = {
     attributes => [{
         name  => 'title',
         type  => 'String',
     },{
         name  => 'author',
         type  => 'String',
     }],
     associations => [{
         role  => 'paragraphs',
         class => 'CMS::Paragraph',
         type  => 'Array',
     },{
         role  => 'template',
         class => 'CMS::Template',
         type  => 'Reference',
     }],
 };
 
 1;

=item B<Class::DBI style adding members dynamically>:

 package CMS::Paragraph;
 use base qw(Oryx::Class);
 
 __PACKAGE__->addAttribute({
     name  => 'content',
     type  => 'Text',
 });
 
 __PACKAGE__->addAttribute({
     name  => 'formatted',
     type  => 'Boolean',
 });
 
 __PACKAGE__->addAssociation({
     role  => 'images',
     class => 'CMS::Image',
     type  => 'Hash',
 });
 
 1;

=item B<If you have XML::DOM::Lite, put it in the DATA section>:

 package CMS::Image;
 use base qw(Oryx::Class);
 
 1;
 __DATA__
 <Class>
   <Attribute name="alt_text" type="String" />
   <Attribute name="path_to_file" type="String" />
 </Class>

=back

=head1 AUTOMATIC TABLE CREATION

With Oryx, you never need to write a single line of SQL although you
can if you want to in exactly the same way as you would when using
L<Class::DBI> (actually it's a L<ImA::DBI> feature). Tables are named
sensibly as pluralised versions of the class name with link table
names equally intuitive.

=head2 Enabling auto_deploy for all classes

To enable automatic table creation, you need to do the following near
the top of your application before you I<use> any of your classes:

 use Oryx ( auto_deploy => 1 );

Because the check to see if a table exists is made once when the class
is first I<use>'ed, the performance penalty for this is minimal in
long running process environments such as mod perl. Otherwise when
running in an environment where your code is recompiled each time the
program is run, or you would like more control, you can leave
I<auto_deploy> turned off at the top level (which it is by default)
and simply turn it on for each new class that you're adding to the
schema as this method is inherited.

=head1 ATTRIBUTES

Attributes are declared as having a I<name> and a I<type> and as such
are simply tied Oryx::Value derivatives (see L<Oryx::Value> for details)
which are generally associated with a field (or column) in the
underlying database, and which have mutators which are automatically
created in the class for getting and setting these values.

Certain attributes may also be declared with additional properties as
relevant, for instance, attributes declared as type => "Float" support
a I<precision> property which describes the valid number of decimal
places.

=head2 Attribute Value Input Checking

Input is checked when assigning values to attributes and return values
are cast to the correct type using a combination of regular
expressions, the L<Data::Types> module, L<YAML> or L<Class::Date>
where relevant. Where additional properties are set such as I<size> or
I<precision>, these are checked also and your program will croak if
types mismatch or overflow.

=head2 Supported Attribute Value Types

Several basic value data types are supported:

=over

=item I<String>

Varying character type (VARCHAR for most RDBMS). Input is checked
using Data::Types::is_string and if the attribute is declared with
a I<size> property, the length is also checked.

=item I<Text>

Corresponds to a SQL TEXT type; type checking is done using
Data::Types::is_string, but no length checking is performed.

=item I<Boolean>

Corresponds to a a SQL TINYINT or INT type and is checked for the
values 0 or 1.

=item I<Binary>

No checking is done here, but a BLOB or BYTEA or equivalent column
type is created when the class is deployed.

=item I<Complex>

This can be anything that can be (de)serialized using YAML and is
stored internally in the DB in a column with a TEXT type.

=item I<DateTime>

Uses Class::Date objects. You can pass either a Class::Date instance
to the mutator as follows:

 use Class::Date qw(date);
 $page->date_created( date(localtime) );

or any value which is valid input to the Class::Date::new constructor
this includes ARRAY refs etc. (see L<Class::Date> for details).

Attributes declared as DateTime types additionaly support a I<format>
property which is used to set Class::Date::DATE_FORMAT for date
formatting.

=item I<Float>

Floating point number checked using Data::Types::is_float. Return
value is done with Data::Types::to_float and precision checks are made
if the attribute is declared with such.

=item I<Integer>

Corresponds to INT or INTEGER SQL type. Input checks are performed using
Data::Types::is_int.

=item I<Oid>

This is also an integer type, but with the distinction that when a
class is deployed to an RDBMS the column is constrained as a PRIMARY
KEY.

=back

=head1 ASSOCIATIONS

Oryx implements the three most common ways in which associations
between classes can be achieved natively with Perl. An object can be
associated with another by simple reference, or we can use either
ordered (ARRAY), or keyed (HASH) associations - so a field in one
object (usually a blessed HASH reference) can be an ARRAY reference,
for example, which could be filled with references to other objects
(which themselves are persistent).

In RDBMS terms, this sort of to-many ordered relationship requires a
link table with a column holding ordering information, which is
exactly what happens under the hood, but Oryx makes it transparent for
you using Perl's I<tie> mechanism while managing the link table
automagically.

Furthermore one can also have to-many ordered (Array) or to-many
keyed (Hash) associations which are mixed - in other words one class
can have an ARRAY (or HASH) reference which can contain instances of
different classes (see L</"ABSTRACT CLASSES"> below).

=head2 Reference

getting :

 my $a_template = $page->template;

setting :

 $page->template($another_template);

=head2 Array

getting :

 my $para42 = $page->paragraphs->[42];

setting :

 $page->paragraph->[0] = $intro_para;

as well as all the usual I<push>, I<pop>, I<shift>, I<unshift> and I<splice>.

=head2 Hash

getting :

 my $image_obj = $page->images->{logo};

setting :

 $page->images->{mug_shot} = $my_ugly_mug;

=head1 RETRIEVING AND SEARCHING FOR OBJECTS

Retrieval is simple, just pass in the id (primary key) :

 my $page = CMS::Page->retrieve($page_id);

Searching uses 'LIKE' (assuming an RDBMS storage) :
 
 my @pages = CMS::Page->search({ author => '%Hundt%'});

B<NOTE> : Searches don't search through superclass fields yet...

=head1 INHERITANCE

Inheritance works as you would expect.

So if we have the following :

 package CMS::Section;
 use base qw(Oryx::Class);
 
 # ... schema definition here ...
 
 1;
 
 package CMS::Paragraph;
 use base qw(CMS::Section);
 
 # ... schema definition here ...
 
 1;

You get exactly what you would normally get in Perl, that is :

 UNIVERSAL::isa('CMS::Paragraph', 'Oryx::Class')

holds true and attributes and associations defined in CMS::Section are
available to CMS::Paragraph instances. So any class which has
persistant class as an ancestor, can be treated and persisted in the
same way as the ancestor. However, it is important to note that it
gets its own table in the database.

For multiple persistent base classes :

 package Orange;
 use base qw(Food Fruit);

As long as Food and Fruit are Oryx::Class derivatives,
the Force That Into the Database Drives the Object will make sure the
proverbial Right Thing is Done.

Oryx uses a multiple table inheritance model (as opposed to putting
all the instances for classes in an inheritance chain into the same
table), each subclass instance has a corresponding superclass instance
for each superclass (assuming said superclass is a derivative of
Oryx::Class), so that attributes which exists in the superclass are
stored (as a row) in the superclass' table, and are therefore fully
fledged instances of the superclass.

You can access these superclass instances with the I<PARENT> method as
follows:

 my $parent_section_instance = $paragraph->PARENT('CMS::Section');

and then use this instance normally.

Updates and deletes cascade up the inheritance chain, as you'd expect.

=head1 ABSTRACT CLASSES

Abstract classes to Oryx are simply classes which do not define any
attributes, but may have associations. The effect is automatic.

Abstract classes behave slightly differently to concrete classes
(which define attributes) in that if you I<retrieve> an instance of an
abstract class (by id or by accessing a member of an association), you
get an instance of the sub class (the one which created the row in the
abstract class's table).

This is particularly useful where you have an Array or Hash
association between two classes and need to mix instances of different
types in that association. As long as all the members of the array (or
hash) inherit from the same abstract class, accessing them produces
the expected result.

Consider the following case :

                    <ABSTRACT>
 +------+  <Array> +----------+
 | Page |----------| Fragment |
 +------+  frags   +----------+
 |______|          |__________|
                        /_\
                         |
               +---------+------+
               |                |
         +-----------+      +-------+
         | Paragraph |      | Image |
         +-----------+      +-------+
         |___________|      |_______|

Here the I<Paragraph> and I<Image> both inherit from the abstract
I<Fragment> class. When the I<frags> Array association is accessed
it may contain a mixture of both I<Paragraph> and I<Image> instances.

Thus you can say:

 $my_para = Paragraph->create({ ... });
 $my_page->frags->[42] = $my_para;
 
 $my_img = Image->create({ ... });
 $my_page->frags->[69] = $my_img;

pretty neat huh?

=head1 OBJECT CACHING

In the interest of consistency, objects are cached and
are unique in memory. Therefore, if you retrieve an object
more than once, each subsequent retrieve until the reference
count on it has dropped to zero and has been eaten by the garbage
collector, will return a reference to the same object.

This has a performance gain in certain situations too.

 
=head1 AUTHOR

Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENCE

This library is free software and may be used under the same terms as Perl itself.

=cut
