package Oryx;

use Carp qw(carp croak);
use UNIVERSAL qw(isa can);
use Oryx::Class;

our $VERSION = '0.24';
our $DEBUG = 0;

sub new { croak("abstract") }

sub import {
    my $class = shift;
    my %param = @_;
    if (defined $param{auto_deploy}) {
	Oryx::Class->auto_deploy($param{auto_deploy});
    }
    if (defined $param{dont_cache}) {
        Oryx::Class->dont_cache($param{dont_cache});
    }
}

sub init {
    my ($self, $Class, $conn, $schema) = @_;

    $DEBUG && $self->_carp("SCHEMA => $schema, Class => $Class");
    unless (ref($schema) and isa($schema, 'Oryx::Schema')) {
        $schema = 'Oryx::Schema' unless $schema;
	eval "use $schema"; croak($@) if $@;
	$schema = $schema->new;
	$DEBUG && $self->_carp("new schema instance => $schema");
    }

    $self->schema($schema);
    $self->set_util($conn->[0]); # $dsname

    push @Oryx::Class::ISA, $Class;
    $self->Class($Class);
    $self->Class->storage($self);

    if (%Oryx::Class::Orphans) {
	foreach (keys %Oryx::Class::Orphans) {
	    eval { Oryx::Class::import($_) };
	    $DEBUG && $_->_carp($@) if $@;
	    $schema->addClass($_);
	}
	%Oryx::Class::Orphans = ();
    }
}

sub connect {
    my ($class, $conn, $schema) = @_;
    $schema = 'Oryx::Schema' unless $schema;

    # determine the type of storage we're using from the dsn
    my $storage;
    if ($conn->[0] =~ /^dbm:/) {
        eval 'use Oryx::DBM'; $class->_croak($@) if $@;
	$storage = Oryx::DBM->new;
    } else {
        eval 'use Oryx::DBI'; $class->_croak($@) if $@;
	$storage = Oryx::DBI->new;
    }

    $storage->connect($conn, $schema);
    return $storage;
}

sub Class { $_[0]->{Class} = $_[1] if $_[1]; $_[0]->{Class} }

# delegate to the actual implementing storage class
sub deploySchema {
    my ($self, $schema) = @_;
    $self->Class->storage->deploySchema($schema);
}

sub _carp {
    my $class = ref $_[0] || $_[0];
    carp("[".$class."] $_[1]");
}

sub _croak {
    my $class = ref $_[0] || $_[0];
    croak("[".$class."] $_[1]");
}

1;

__END__

=head1 NAME

Oryx - Meta-Model Driven Object Persistance with Multiple Inheritance

=head1 SYNOPSIS
 
 # define a persistent class
 package CMS::Page;
 use base qw(Oryx::Class);
 our $schema = {
    attributes => [{
        name => 'title',
        type => 'String',
    }],
    associations => [{
        role => 'paragraphs',
        type => 'Array',
        class => 'CMS::Paragraph',
    },{
        role => 'author',
        type => 'Reference',
        class => 'CMS::Author',
    }]
 };
  
 1;
 # ... for more details see DEFINING CLASS META-DATA in L<Oryx::Class>) 
  
 #===========================================================================
 # use a persistent class
 use CMS::Page;
  
 $page = CMS::Page->create({title => 'Life in the Metaverse'});
 $page = CMS::Page->retrieve($id);
  
 $page->update;
 $page->delete;
  
 @pages = CMS::Page->search({author => 'Richard Hun%'}, \@order, $limit, $offset);
  
 # search with SQL WHERE clause (which pages contain a particular paragraph):
 @book = CMS::Page->search({
     EXISTS => \q{(
     SELECT id FROM page WHERE
        page.id = author.id AND
        page.title LIKE \'Meta%\'
     )}
 });
  
 #===========================================================================
 # commit your changes
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

 #===========================================================================
 # connect to storage
 $storage = Oryx->connect(['dbi:Pg:dbname=cms', $usname, $passwd]);
 
 # or specify a schema
 $storage = Oryx->connect(
    ["dbi:Pg:dbname=cms", $usname, $passwd], 'CMS::Schema'
 );
 
 # for DBM::Deep back-end
 Oryx->connect(['dbm:Deep:datapath=/path/to/data'], 'CMS::Schema');

 #===========================================================================
 # deploy the schema
 $storage->deploySchema();              # for all known classes (via `use')
 $storage->deploySchema('CMS::Schema');
 $storage->deployClass('CMS::Page');
 
 # automatically deploy as needed
 use Oryx ( auto_deploy => 1 );           # for all classes
 CMS::Page->auto_deploy(1);             # only for this class
 
=head1 DESCRIPTION

Oryx is an object persistence framework which supports both object-relational
mapping as well as DMB style databases and as such is not coupled with any
particular storage back-end. In other words, you should be able to
swap out an RDMBS with a DBM style database (and vice versa) without
changing your persistent classes at all.

This is achieved with the use a meta model which fits in as closely
with Perl's own as possible - and due to Perl's excellent
introspection capabilities and enormous flexibility - this is very
close indeed. For this reason Hash, Array and Reference association
types are implemented with liberal use of `tie'. The use of a meta
model, albeit a very transparent one, conceptually supports the
de-coupling of storage back-end from persistent classes, and, for the
most part, beside a really small amout of meta-data, you would use
persistent classes in a way that is virtually indistinguishable from
ordinary perl classes.

Oryx follows the DRY principle - Don't Repeat Yourself - inspired by
the fantastic Ruby on Rails framework, so what you do say, you say it
only once when defining your C<$schema> for your class. After that,
everything is taken care of for you, including automatic table creation
(if you're using an RDBMS storage). Oryx attempts to name tables
and link tables created in this way sensibly, so that if you need to
you should be able to find your way around in the schema with ease.

Because Oryx implements relationships as ordinary Perl Array and Hash
references, you can create any structures or object relationships
that you could create in native Perl and have these persist in a database.
This gives you the flexibility to create trees, cyclic structures, linked
lists, mixed lists (lists with instances of different classes), etc.

Oryx also supports multiple inheritance by Perl's native C<use base>
mechanism. Abstract classes, which are simply classes with no attributes,
are meaningful too, see L<Oryx::Class> for details.

L<Oryx::Class> also now inherits from L<Class::Observable>, see relevant docs.

=head1 INTRODUCTION

This documentation applies to classes persisted in L<DBM::Deep> style
storage as well except insofar as the implementation details are
concerned where tables and columns are mentioned - separate files are
used for L<DBM::Deep> based storage instead of tables (see
L<Oryx::DBM> for details).

This is still an early release and supports L<DBM::Deep>, MySQL,
SQLite and Postgres back-ends at the moment. Having said this, Oryx is
already quite usable. It needs to be thrashed a lot more and support
for the rest of the popular RDBMS needs to be added. Things will
change (for the better, one hopes); if you're interested in helping to
precipitate that change... let me know, you'd be most welcome.

=head1 OVERVIEW

The documentation has been divided up between the different components:

=over

=item L<Oryx::Class>

Contains the details for defining persistent classes and how to use them.
Read this first.

=item L<Oryx::Association>

Describes Associations meta-types in more detail.

=item L<Oryx::Attribute>

Explains Attribute meta-types.

=item L<Oryx::Parent>

All about Inheritance in Oryx.

=item L<Oryx::Value>

A description of our DB friendly primitive types.

=item L<Oryx::Manual::Guts>

Oryx meta-model and internals for developers.

=back

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


=head1 CONNECTING TO STORAGE

The call to Oryx->connect(...) specifies the dsn and connection
credentials to use when connecting where applicable. For DBM::Deep
style storage, the connection arguments look like this:

 Oryx->connect(['dbm:Deep:datapath=/path/to/data'], 'CMS::Schema');

For RDBMS (Postgres in this case) it may look like this:

 Oryx->connect(["dbi:Pg:dbname=cms", $usname, $passwd], 'CMS::Schema');

The Schema defaults to 'Oryx::Schema' and is therefore optional, so we
could say Oryx->connect([ ... dsn ... ]), and forget about passing in
a Schema.

One advantage to using separate Schema classes is that this gives you
namespace separation where you need to connect several sets of classes
to different storage back ends (especially where these are mixed in
such a way where the same classes exist in different stores). Another
advantage is that the Schema class may define a B<prefix> method which
simply returns a string to prefix table names with, for those of us
who only get a single database with our hosting package and need to
have some namespace separation.

Here's an example of a Schema class :

 package CMS::Schema;
 use base qw(Oryx::Schema);
  
 # optionaly include your classes
 use CMS::Page;
 use CMS::Paragraph;
 use CMS::Image;
  
 sub prefix { 'cms' }
 
 1;

=head1 DEPLOYING YOUR SCHEMA

If you've built a large schema and would like to deploy it in
one shot, or have written an install script, then you can C<use> all the
classes near the top of your script somewhere, or in your schema class,
and call C<deploySchema()>. Note, however, that this will only have to be
done once as you will generally get errors if you try to create a table
more than once in your RDBMS.

Ordinarily, though you would turn on C<auto_deploy> for your classes, either
by saying:

 use Oryx(auto_deploy => 1);

or if you prefer, then you can set it on a per class basis:

 use CMS::Page(auto_deploy => 1);

This will avoid the performance hit of checking for the existence of
a class' table.

=head1 TODO

=over

=item B<Add support for bidrectional associations>

At the moment all associations are implemented as unidirectional

=item B<Add Oryx::Association::Set>

Set associations using L<Set::Object>

=item B<test test test>

Tests are a bit sparse at the moment.

=item B<Support for Oracle, etc.>

Only MySQL, PostgreSQL SQLite and DBM::Deep are supported currently.
It should be fairly trivial to add support for the other RDBMS'

=item B<More documentation>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to:

=over 4

=item I<Sam Vilain>

For educating me about meta-models and feedback.

=item I<Andrew Sterling Hanenkamp>

For bug reports and patches, and his ongoing help with documentation,
tests and good suggestions.

=over

=head1 SEE ALSO

L<Class::DBI>, L<Tangram>, L<Class::Tangram>, L<SQL::Abstract>,
L<Class::Data::Inheritable>, L<Data::Types>, L<DBM::Deep>, L<DBI>,
L<ImA::DBI>

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENSE

Oryx is free software and may be used under the same terms as Perl itself.

=cut
