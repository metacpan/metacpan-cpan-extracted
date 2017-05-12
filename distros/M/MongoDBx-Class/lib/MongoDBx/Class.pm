package MongoDBx::Class;

# ABSTRACT: Flexible ORM for MongoDB databases

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use MongoDB 0.40;
use MongoDBx::Class::Connection;
use MongoDBx::Class::ConnectionPool::Backup;
use MongoDBx::Class::ConnectionPool::Rotated;
use MongoDBx::Class::Database;
use MongoDBx::Class::Collection;
use MongoDBx::Class::Cursor;
use MongoDBx::Class::Reference;
use MongoDBx::Class::Meta::AttributeTraits;
use Carp;

# let's set some internal subtypes we can use to automatically coerce
# objects when expanding documents.
subtype 'MongoDBx::Class::CoercedReference'
	=> as 'MongoDBx::Class::Reference';

subtype 'ArrayOfMongoDBx::Class::CoercedReference'
	=> as 'ArrayRef[MongoDBx::Class::Reference]';

coerce 'MongoDBx::Class::CoercedReference'
	=> from 'Object'
	=> via { $_->isa('MongoDBx::Class::Reference') ? $_ : MongoDBx::Class::Reference->new(ref_coll => $_->_collection->name, ref_id => $_->_id, _collection => $_->_collection, _class => 'MongoDBx::Class::Reference') };

coerce 'ArrayOfMongoDBx::Class::CoercedReference'
	=> from 'ArrayRef[Object]'
	=> via {
		my @arr;
		foreach my $i (@$_) {
			push(@arr, $i->isa('MongoDBx::Class::Reference') ? $i : MongoDBx::Class::Reference->new(ref_coll => $i->_collection->name, ref_id => $i->_id, _collection => $i->_collection, _class => 'MongoDBx::Class::Reference'));
		}
		return \@arr;
	};

=encoding utf8

=head1 NAME

MongoDBx::Class - Flexible ORM for MongoDB databases

=head1 VERSION

version 1.030002

=head1 SYNOPSIS

Normal usage:

	use MongoDBx::Class;

	# create a new instance of the module and load a model schema
	my $dbx = MongoDBx::Class->new(namespace => 'MyApp::Model::DB');

	# if MongoDBx::Class can't find your model schema (possibly because
	# it exists in some different location), you can do this:
	my $dbx = MongoDBx::Class->new(namespace => 'MyApp::Model::DB', search_dirs => ['/path/to/model/dir']);

	# connect to a MongoDB server
	my $conn = $dbx->connect(host => 'localhost', port => 27017);

	# be safe by default
	$conn->safe(1); # we could've also just passed "safe => 1" to $dbx->connect() above

	# get a MongoDB database
	my $db = $conn->get_database('myapp');

	# insert a person
	my $person = $db->get_collection('people')->insert({ name => 'Some Guy', birth_date => '1984-06-12', _class => 'Person' });

	print "Created person ".$person->name." (".$person->id.")\n";

	$person->update({ name => 'Some Smart Guy' });

	$person->delete;

See L<MongoDBx::Class::ConnectionPool> for simple connection pool usage.

=head1 DESCRIPTION

L<MongoDBx::Class> is a flexible object relational mapper (ORM) for
L<MongoDB> databases. Given a schema-like collection of document classes,
MongoDBx::Class expands MongoDB objects (hash-refs in Perl) from the
database into objects of those document classes, and collapses such objects
back to the database.

MongoDBx::Class takes advantage of the fact that Perl's L<MongoDB> driver
is L<Moose>-based to extend and tweak the driver's behavior, instead of
wrapping it. This means MongoDBx::Class does not define its own syntax,
so you simply use it exactly as you would the L<MongoDB> driver directly.
That said, MongoDBx::Class adds some sugar that enhances and simplifies
the syntax unobtrusively (either use it or don't). Thus, it is relatively
easy to convert your current L<MongoDB> applications to MongoDBx::Class.
A collection in MongoDBx::Class C<isa('MongoDB::Collection')>, a database
in MongoDBx::Class C<isa('MongoDB::Database')>, etc.

As opposed to other ORMs (even non-MongoDB ones), MongoDBx::Class attempts
to stay as close as possible to MongoDB's non-schematic nature. While most
ORMs enforce using a single collection (or table in the SQL world) for
every object class, MongoDBx::Class allows you to store documents of
different classes in different collections (and even databases). A collection
can hold documents of many different classes. Not only that, as MongoDBx::Class
is Moose based, you can easily create very flexible schemas by using
concepts such as inheritance and L<roles|Moose::Manual::Roles>. For example, say
you have a collection called 'people' with documents representing, well,
people, but these people can either be teachers or students. Also, students
may assume the role "hall monitor". With MongoDBx::Class, you can create
a common base class, say "People", and two more classes that extend it - 
"Teacher" and "Student" with attributes that are only relevant to each one.
You also create a role called "HallMonitor", possibly with some methods
of its own. You can save all these "people documents" into a single
MongoDB collection, and when fetching documents from that collection,
they will be properly expanded to their correct classes (though you will
have to apply roles yourself - at least for now).

=head2 COMPARISON WITH OTHER MongoDB ORMs

As MongoDB is rather young, there aren't many options out there, though
CPAN has some pretty good ones, and will probably have more as MongoDB
popularity rises.

The first MongoDB ORM in CPAN was L<Mongoose>, and while it's a very good
ORM, MongoDBx::Class was mainly written to overcome some limitations of
Mongoose. The biggest of these limitations is that in order to provide a
more comfortable syntax than MongoDB's native syntax, Mongoose makes the
unfortunate decision of being implemented as a L<singleton|MooseX::Singleton>,
meaning only one instance of a Mongoose-based schema can be used in an
application. That essentially kills multithreaded applications. Say you
have a L<Plack>-based (doesn't have to be Plack-based though) web application
deployed via L<Starman> (or any other web server for that matter), which
is a pre-forking web server - you're pretty much doomed. As
L<MongoDB's driver|MongoDB::Connection/"Multithreading"> states, it doesn't
support connection pooling, so every fork has to have its own connection
to the MongoDB server. Mongoose being a singleton means your threads will
not have a connection to the server, and you're screwed. MongoDBx::Class
does not suffer this limitation. You can start as many connections as you
like. If you're running in a pre-forking environment, you don't have to
worry about it at all.

Other differences from Mongoose include:

=over

=item * Mongoose creates its own syntax, MongoDBx::Class doesn't, you
use L<MongoDB>'s syntax directly.

=item * A document class in Mongoose is connected to a single collection
only, and a collection can only have documents of that class. MongoDBx::Class
doesn't have that limitation. Do what you like.

=item * Mongoose has limited support for multiple database usage.
With MongoDBx::Class, you can use as many databases as you want.

=item * MongoDBx::Class is way faster. While I haven't performed any real
benchmarks, an application converted from Mongoose to MongoDBx::Class
showed an increase of speed in orders of magnitude.

=item * In Mongoose, your document class attributes are expected to be
read-write (i.e. C<< is => 'rw' >> in Moose), otherwise expansion will fail.
This is not the case with MongoDBx::Class, your attributes can safely be
read-only.

=back

Another ORM for MongoDB is L<Mongrel>, which doesn't use Moose and is thus
lighter (though as L<MongoDB> is already Moose-based, I see no benefit here).
It uses L<Oogly> for data validation (while Moose has its own type validation),
and seems to define its own syntax as well. Unfortunately, documentation
is currently lacking, and I haven't given it a try, so I can't draw
specific comparisons here.

Even before Mongoose was born, you could use MongoDB as a backend for
L<KiokuDB>, by using L<KiokuDB::Backend::MongoDB>. However, KiokuDB is
considered a database of its own and uses some conventions which doesn't
fit well with MongoDB. L<Mongoose::Intro|Mongoose::Intro/"Why not use KiokuDB?">
already gives a pretty convincing case when and why you should or shouldn't
want to use KiokuDB.

=head2 CONNECTION POOLING

Since version 0.9, C<MongoDBx::Class> provides experimental, simple connection pooling for
applications. Take a look at L<MongoDBx::Class::ConnectionPool> for more
information.

=head2 CAVEATS AND THINGS TO CONSIDER

There are a few caveats and important facts to take note of when using
MongoDBx::Class as of today:

=over

=item * MongoDBx::Class's flexibility is dependant on its ability to recognize
which class a document in a MongoDB collection expands to. Currently,
MongoDBx::Class requires every document to have an attribute called "_class"
that contains the name of the document class to use. This isn't very
comfortable, but works. I'm still thinking of ways to expand documents
without this. This pretty much means that you will have to perform
some preparations to use existing MongoDB database with MongoDBx::Class - 
you will have to update every document in the database with the "_class"
attribute.

=item * References (representing joins) are expected to be in the DBRef
format, as defined in L<http://www.mongodb.org/display/DOCS/Database+References>.
If your database references aren't in this format, you'll have to convert
them first.

=item * The '_id' attribute of all your documents has to be an internally
generated L<MongoDB::OID>. This limitation may or may not be lifted in
the future.

=back

=head2 TUTORIAL

To start using MongoDBx::Class, please read L<MongoDBx::Class::Tutorial>.
It also contains a list of frequently asked questions.

=head1 ATTRIBUTES

=cut

has 'namespace' => (is => 'ro', isa => 'Str', required => 1);

has 'search_dirs' => (is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] });

has 'doc_classes' => (is => 'ro', isa => 'HashRef', default => sub { {} });

=head2 namespace

A string representing the namespace of the MongoDB schema used (e.g.
C<MyApp::Schema>). Your document classes, structurally speaking, should be
descendants of this namespace (e.g. C<MyApp::Schema::Article>,
C<MyApp::Schema::Post>).

=head2 search_dirs

An array-ref of directories in which to search for the document classes.
Not required, useful if for some reason MongoDBx::Class can't find
your document classes.

=head2 doc_classes

A hash-ref of document classes found when loading the schema.

=head1 CLASS METHODS

=head2 new( namespace => $namespace )

Creates a new instance of this module. Requires the namespace of the
database schema to use. The schema will be immediately loaded, but no
connection to a MongoDB server is made yet.

=head1 OBJECT METHODS

=head2 connect( %options )

Initiates a new connection to a MongoDB server running on a certain host
and listening to a certain port. C<%options> is the hash of attributes
that can be passed to C<new()> in L<MongoDB::Connection>, plus the 'safe'
attribute from L<MongoDBx::Class::Connection>. You're mostly expected to
provide the 'host' and 'port' options. If a host is not provided, 'localhost'
is used. If a port is not provided, 27017 (MongoDB's default port) is
used. Returns a L<MongoDBx::Class::Connection> object.

NOTE: Since version 0.7, the created connection object isn't saved in the
top MongoDBx::Class object, but only returned, in order to be more like how
connection is made in L<MongoDB> (and to allow multiple connections). This
change breaks backwords compatibility.

=cut

sub connect {
	my ($self, %opts) = @_;

	$opts{namespace} = $self->namespace;
	$opts{doc_classes} = $self->doc_classes;

	return MongoDBx::Class::Connection->new(%opts);
}

=head2 pool( [ type => $type, max_conns => $max_conns, params => \%params, ... ] )

Creates a new connection pool (see L<MongoDBx::Class::ConnectionPool> for
more info) and returns it. C<type> is either 'rotated' or 'backup' (the
default). C<params> is a hash-ref of parameters that can be passed to
C<< MongoDB::Connection->new() >> when creating connections in the pool.
See L<MongoDBx::Class::ConnectionPool/"ATTRIBUTES"> for a complete list
of attributes that can be passed.

=cut

sub pool {
	my ($self, %opts) = @_;

	$opts{params} ||= {};
	$opts{params}->{namespace} = $self->namespace;
	$opts{params}->{doc_classes} = $self->doc_classes;

	if ($opts{type} && $opts{type} eq 'rotated') {
		return MongoDBx::Class::ConnectionPool::Rotated->new(%opts);
	} else {
		return MongoDBx::Class::ConnectionPool::Backup->new(%opts);
	}
}

=head1 INTERNAL METHODS

The following methods are only to be used internally.

=head2 BUILD()

Automatically called when creating a new instance of this module. This
loads the schema and saves a hash-ref of document classes found in the object.
Automatic loading courtesy of L<Module::Pluggable>.

=cut

sub BUILD {
	my $self = shift;

	# load the classes
	require Module::Pluggable;
	Module::Pluggable->import(search_path => [$self->namespace], search_dirs => $self->search_dirs, require => 1, sub_name => '_doc_classes');
	foreach ($self->_doc_classes) {
		my $name = $_;
		$name =~ s/$self->{namespace}:://;
		$self->doc_classes->{$name} = $_;
	}
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBx::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBx::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBx::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBx::Class/>

=back

=head1 SEE ALSO

L<MongoDB>, L<Mongoose>, L<Mongrel>, L<KiokuDB::Backend::MongoDB>.

=head1 ACKNOWLEDGEMENTS

=over

=item * Rodrigo de Oliveira, author of L<Mongoose>, whose code greatly assisted
me in writing MongoDBx::Class.

=item * Thomas Müller, for adding support for the Transient trait.

=item * Dan Dascalescu, for fixing typos and other problems in the documentation.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
