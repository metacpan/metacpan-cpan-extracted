package SimpleDB::Class;
BEGIN {
  $SimpleDB::Class::VERSION = '1.0503';
}

=head1 NAME

SimpleDB::Class - An Object Relational Mapper (ORM) for the Amazon SimpleDB service.

=head1 VERSION

version 1.0503

=head1 SYNOPSIS

 package Library;

 use Moose;
 extends 'SimpleDB::Class';
 
 __PACKAGE__->load_namespaces();

 1;

 package Library::Book;

 use Moose;
 extends 'SimpleDB::Class::Item';

 __PACKAGE__->set_domain_name('book');
 __PACKAGE__->add_attributes(
     title          => { isa => 'Str', default => 'Untitled' },
     publish_date   => { isa => 'Date' },
     edition        => { isa => 'Int', default => 1 },
     isbn           => { isa => 'Str' },
     publisherId    => { isa => 'Str' },
     author         => { isa => 'Str' },
 );
 __PACKAGE__->belongs_to('publisher', 'Library::Publisher', 'publisherId');

 1;

 package Library::Publisher;

 use Moose;
 extends 'SimpleDB::Class::Item';

 __PACKAGE__->set_domain_name('publisher');
 __PACKAGE__->add_attributes(
     name   => { isa => 'Str' },
 );
 __PACKAGE__->has_many('books', 'Library::Book', 'publisherId');

 1;

 use 5.010;
 use Library;
 use DateTime;

 my $library = Library->new(access_key => 'xxx', secret_key => 'yyy', cache_servers=>\@servers );
  
 my $specific_book = $library->domain('book')->find('id goes here');

 my $books = $library->domain('publisher')->find($id)->books;
 my $books = $library->domain('book')->search( where => {publish_date => ['between', DateTime->new(year=>2001), DateTime->new(year=>2003)]} );
 while (my $book = $books->next) {
    say $book->title;
 }

=head1 DESCRIPTION

SimpleDB::Class gives you a way to persist your objects in Amazon's SimpleDB service search them easily. It hides the mess of web services, pseudo SQL, and XML document formats that you'd normally need to deal with to use the service, and gives you a tight clean Perl API to access it.

On top of being a simple to use ORM that functions in a manner similar to L<DBIx::Class>, SimpleDB::Class has some other niceties that make dealing with SimpleDB easier:

=over

=item *

It uses memcached to cache objects locally so that most of the time you don't have to care that SimpleDB is eventually consistent. This also speeds up many requests. See Eventual Consistency below for details.

=item *

It automatically formats dates and integers for sortability in SimpleDB. 

=item *

It automatically casts date fields as L<DateTime> objects. 

=item *

It automatically serializes hashes into JSON so they can be stored in SimpleDB domain attributes, and deserializes on retrieval. 

=item *

It gives you an easy way to handle pagination of data. See L<SimpleDB::Class::ResultSet/"paginate">.

=item *

It uses L<Moose> for everything, which makes it easy to use Moose's introspection features or method insertion features. 

=item *

It automatically generates UUID based ItemNames (unique IDs) if you don't want to supply an ID yourself. 

=item *

It has built in domain prefixing to account for the fact that you can't create multiple SimpleDB instances under the same account.

=item *

It ignores attributes in your items that aren't in your L<SimpleDB::Class::Item> subclasses.

=item *

L<SimpleDB::Class::ResultSet>s automatically fetch additional items from SimpleDB if a next token is provided, so you don't have to care that SimpleDB sends you back data in small packets.

=item * 

It allows for multiple similar object types to be stored in a single domain and then cast into different classes at retrieval time. See L<SimpleDB::Class::Item/"recast_using"> for details.

=item *

It allows for mass updates and deletes on L<SimpleDB::Class::ResultSet>s, which is a nice level of automation to keep your code small.

=back

=head2 Eventual Consistency

SimpleDB is eventually consistent, which means that if you do a write, and then read directly after the write you may not get what you just wrote. L<SimpleDB::Class> gets around this problem for the post part because it caches all L<SimpleDB::Class::Item>s in memcached. That is to say that if an object can be read from cache, it will be. The one area where this falls short are some methods in L<SimpleDB::Class::Domain> and L<SimpleDB::Class::ResultSet> that perform searches on the database which look up items based upon their attributes rather than based upon id. Even in those cases, once an object is located we try to pull it from cache rather than using the data SimpleDB gave us, simply because the cache may be more current. However, a search result may return too few (inserts pending) or too many (deletes pending) results in L<SimpleDB::Class::ResultSet>, or it may return an object which no longer fits certain criteria that you just searched for (updates pending). As long as you're aware of it, and write your programs accordingly, there shouldn't be a problem.

At the end of February 2010 Amazon added a C<ConsistentRead> option to SimpleDB, which means you don't have to care about eventual consistency if you wish to sacrifice some performance. We have exposed this as an option for you to turn on in the methods like C<search> in L<SimpleDB::Class::Domain> where you have to be concerned about eventual consistency. 

Does all this mean that this module makes SimpleDB as ACID compliant as a traditional RDBMS? No it does not. There are still no locks on domains (think tables), or items (think rows). So you probably shouldn't be storing sensitive financial transactions in this. We just provide an easy to use API that will allow you to more easily and a little more safely take advantage of Amazon's excellent SimpleDB service for things like storing logs, metadata, and game data.

For more information about eventual consistency visit L<http://en.wikipedia.org/wiki/Eventual_consistency> or the eventual consistency section of the Amazon SimpleDB Developer's Guide at L<http://docs.amazonwebservices.com/AmazonSimpleDB/2009-04-15/DeveloperGuide/EventualConsistencySummary.html>.

=head1 METHODS

The following methods are available from this class.

=cut

use Moose;
use MooseX::ClassAttribute;
use SimpleDB::Class::Cache;
use SimpleDB::Client;
use SimpleDB::Class::Domain;
use Module::Find;

#--------------------------------------------------------

=head2 new ( params ) 

=head3 params

A hash containing the parameters to pass in to this method.

=head4 access_key

The access key given to you from Amazon when you sign up for the SimpleDB service at this URL: L<http://aws.amazon.com/simpledb/>

=head4 secret_key

The secret access key given to you from Amazon.

=head4 cache_servers

An array reference of cache servers. See L<SimpleDB::Class::Cache> for details.

=head4 simpledb_uri

An optional L<URI> object to connect to an alternate SimpleDB server. See also L<SimpleDB::Client/"simpledb_uri">.

=head4 domain_prefix

An optional string that is prepended to all domain names wherever they are used in the system.

=cut

#--------------------------------------------------------

=head2 load_namespaces ( [ namespace ] )

Class method. Loads all the modules in the current namespace, so if you subclass SimpleDB::Class with a package called Library (as in the example provided), then everything in the Library namespace would be loaded automatically. Should be called to load all the modules you subclass, so you don't have to manually use each of them.

=head3 namespace

Specify a specific namespace like Library::SimpleDB if you don't want everything in the Library namespace to be loaded.

=cut

sub load_namespaces {
    my ($class, $namespace) = @_;
    $namespace ||= $class; # if no namespace is set
    useall $namespace;
}

#--------------------------------------------------------

=head2 cache_servers ( )

Returns the cache server array reference passed into the constructor.

=cut

has cache_servers => (
    is          => 'ro',
    required    => 1,
);

#--------------------------------------------------------

=head2 cache ( )

Returns a reference to the L<SimpleDB::Class::Cache> instance.

=cut

has cache => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return SimpleDB::Class::Cache->new(servers=>$self->cache_servers);
    },
);

#--------------------------------------------------------

=head2 access_key ( )

Returns the access key passed to the constructor.

=cut

has 'access_key' => (
    is              => 'ro',
    required        => 1,
    documentation   => 'The AWS SimpleDB access key id provided by Amazon.',
);

#--------------------------------------------------------

=head2 secret_key ( )

Returns the secret key passed to the constructor.

=cut

has 'secret_key' => (
    is              => 'ro',
    required        => 1,
    documentation   => 'The AWS SimpleDB secret access key id provided by Amazon.',
);

#--------------------------------------------------------

=head2 simpledb_uri ( )

Returns the L<URI> object passed into the constructor, if any. See also L<SimpleDB::Client/"simpledb_uri">.

=head2 has_simpledb_uri ( )

Returns a boolean indicating whether the user has overridden the URI.

=cut

has simpledb_uri => (
    is          => 'ro',
    predicate   => 'has_simpledb_uri',
);


#--------------------------------------------------------

=head2 domain_prefix ( )

Returns the value passed into the constructor.

=head2 has_domain_prefix ( )

Returns a boolean indicating whether the user has specified a domain_prefix.

=cut

has domain_prefix => (
    is          => 'ro',
    predicate   => 'has_domain_prefix',
    default     => undef,
);

#--------------------------------------------------------

=head2 add_domain_prefix ( domain ) 

If the domain_prefix is set, this method will apply it do a passed in domain name. If it's not, it will simply return the domain anme as is.

B<NOTE:> This is used mostly internally to SimpleDB::Class, so unless you're extending SimpleDB::Class itself, rather than just using it, you don't have to use this method.

=head3 domain

The domain to apply the prefix to.

=cut

sub add_domain_prefix {
    my ($self, $domain) = @_;
    if ($self->has_domain_prefix) {
        return $self->domain_prefix . $domain;
    }
    return $domain;
}


#--------------------------------------------------------

=head2 http ( )

Returns the L<SimpleDB::Client> instance used to connect to the SimpleDB service.

=cut

has http => (
    is              => 'ro',
    lazy            => 1,
    default         => sub { 
                        my $self = shift; 
                        my %params = (access_key=>$self->access_key, secret_key=>$self->secret_key);
                        if ($self->has_simpledb_uri) {
                            $params{simpledb_uri} = $self->simpledb_uri;
                        }
                        return SimpleDB::Client->new(%params);
                        },
);

#--------------------------------------------------------

=head2 domain_names ( )

Class method. Returns a hashref of the domain names and class names registered from subclassing L<SimpleDB::Class::Domain> and calling set_name. 

=cut

class_has 'domain_names' => (
    is      => 'rw',
    default => sub{{}},
);

#--------------------------------------------------------

=head2 domain ( moniker )

Returns an instanciated L<SimpleDB::Class::Domain> based upon its L<SimpleDB::Class::Item> classname or its domain name.

=head3 moniker

Can either be the L<SimpleDB::Class::Item> subclass name, or the domain name.

=cut

sub domain {
    my ($self, $moniker) = @_;
    my $class = $self->domain_names->{$moniker};
    $class ||= $moniker;
    my $d = SimpleDB::Class::Domain->new(simpledb=>$self, item_class=>$class);
    return $d;
}

#--------------------------------------------------------

=head2 list_domains ( )

Retrieves the list of domain names from your SimpleDB account and returns them as an array reference.

=cut

sub list_domains {
    my ($self) = @_;
    my $result = $self->http->send_request('ListDomains');
    my $domains = $result->{ListDomainsResult}{DomainName};
    unless (ref $domains eq 'ARRAY') {
        $domains = [$domains];
    }
    return $domains;
}

=head1 PREREQS

This package requires the following modules:

L<JSON>
L<Sub::Name>
L<DateTime>
L<DateTime::Format::Strptime>
L<Moose>
L<MooseX::Types>
L<MooseX::ClassAttribute>
L<Module::Find>
L<UUID::Tiny>
L<Exception::Class>
L<Memcached::libmemcached>
L<Clone>
L<SimpleDB::Client>

=head1 TODO

Still left to figure out:

=over

=item *

Creating multi-domain objects ( so you can put each country's data into it's own domain, but still search all country-oriented data at once).

=item *

More exception handling.

=item *

More tests.

=item *

All the other stuff I forgot about or didn't know when I designed this thing.

=back

=head1 SUPPORT

=over

=item Repository

L<http://github.com/plainblack/SimpleDB-Class>

=item Bug Reports

L<http://rt.cpan.org/Public/Dist/Display.html?Name=SimpleDB-Class>

=back

=head1 AUTHOR

JT Smith <jt_at_plainblack_com>

I have to give credit where credit is due: SimpleDB::Class is heavily inspired by L<DBIx::Class> by Matt Trout (and others).

=head1 LEGAL

SimpleDB::Class is Copyright 2009-2010 Plain Black Corporation (L<http://www.plainblack.com/>) and is licensed under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;