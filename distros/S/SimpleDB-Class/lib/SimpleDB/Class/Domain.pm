package SimpleDB::Class::Domain;
BEGIN {
  $SimpleDB::Class::Domain::VERSION = '1.0503';
}

=head1 NAME

SimpleDB::Class::Domain - A schematic representation of a SimpleDB domain.

=head1 VERSION

version 1.0503

=head1 DESCRIPTION

A subclass of this class is created for each domain in SimpleDB with it's name, attributes, and relationships.

=head1 METHODS

The following methods are available from this class.

=cut

use Moose;
use SimpleDB::Class::SQL;
use SimpleDB::Class::ResultSet;
use SimpleDB::Class::Exception;


#--------------------------------------------------------

=head2 new ( params ) 

Constructor. Normally you should never call this method yourself, instead use the domain() method in L<SimpleDB::Class>.

=head3 params

A hash containing the parameters needed to construct this object.

=head4 simpledb

Required. A reference to a L<SimpleDB::Class> object.

=head4 name

Required. The SimpleDB domain name associated with this class.

=cut


#--------------------------------------------------------

=head2 item_class ( )

Returns the L<SimpleDB::Class::Item> subclass name passed into the constructor.

=cut

has item_class => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    trigger     => sub {
        my ($self, $item, $old) = @_;
        $self->name($item->domain_name);
    },
);

with 'SimpleDB::Class::Role::Itemized';

#--------------------------------------------------------

=head2 name ( )

Returns the name determined automatically by the item_class passed into the constructor.

=cut

has name => (
    is          => 'rw',
    default     => undef,
);

#--------------------------------------------------------

=head2 simpledb ( )

Returns the L<SimpleDB::Class> object set in the constructor.

=cut

has simpledb => (
    is          => 'ro',
    required    => 1,
);

#--------------------------------------------------------

=head2 create  ( )

Creates this domain in the SimpleDB.

=cut

sub create {
    my ($self) = @_;
    my $db = $self->simpledb;
    $db->http->send_request('CreateDomain', {
        DomainName => $db->add_domain_prefix($self->name),
    });
}

#--------------------------------------------------------

=head2 delete ( )

Deletes this domain from the SimpleDB.

=cut

sub delete {
    my ($self) = @_;
    my $db = $self->simpledb;
    $db->http->send_request('DeleteDomain', {
        DomainName => $db->add_domain_prefix($self->name),
    });
}

#--------------------------------------------------------

=head2 find ( id, [ options ] )

Retrieves an item from the SimpleDB by ID and then returns a L<SimpleDB::Class::Item> object.

=head3 id

The unique identifier (called ItemName in AWS documentation) of the item to retrieve.

=head3 options

A hash which allows options to modify the retrieval. 

=head4 consistent

A boolean that if set true will get around Eventual Consistency, but at a reduced performance. Note that since L<SimpleDB::Class> fetches requests by id (like this one) directly from memcached, this option should never be needed. It is provided only for completeness. 

=head4 set

A hash reference of attribute names paired with values that should be set as soon as the item is instantiated. This is useful for prefilling cache attributes, and is used by the C<belongs_to> method for that purpose. Doing so prevents stale object references.

=cut

sub find {
    my ($self, $id, %options) = @_;
    SimpleDB::Class::Exception::InvalidParam->throw(name=>'id', value=>undef) unless defined $id;
    my $db = $self->simpledb;
    my $cache = $db->cache;
    my $name = $db->add_domain_prefix($self->name);

    # instantiate item
    my $attributes = eval{$cache->get($name, $id)};
    my $e;
    my $item;
    if (SimpleDB::Class::Exception::ObjectNotFound->caught) {
        my %params = ( 
            ItemName    => $id,
            DomainName  => $name,
        );
        if ($options{consistent}) {
            $params{ConsistentRead} = 'true';
        }
        my $result = $db->http->send_request('GetAttributes', \%params);
        $item = $self->parse_item($id, $result->{GetAttributesResult}{Attribute});
        if (defined $item) {
            $cache->set($name, $id, $item->to_hashref);
        }
    }
    elsif (my $e = SimpleDB::Class::Exception->caught) {
        warn $e->error;
        $e->rethrow;
    }
    elsif (defined $attributes) {
        $item = $self->instantiate_item($attributes, $id);
    }
    else {
        SimpleDB::Class::Exception->throw(error=>"An undefined error occured while fetching the item.");
    }

    # process the 'set' option
    return undef unless defined $item;
    foreach my $attribute (keys %{$options{set}}) {
        $item->$attribute( $options{set}{$attribute} );
    }

    return $item;
}

#--------------------------------------------------------

=head2 insert ( attributes, [ options ] ) 

Adds a new item to this domain.

=head3 attributes

A hash reference of name value pairs to insert as attributes into this item.

=head3 options

A hash of extra options to modify the put.

=head4 id

Optionally specify a unqiue id for this item.

=head4 set 

A hash reference of attribute names paired with values that should be set as soon as the item is instantiated. This is useful for prefilling cache attributes to prevent stale object references.

=cut

sub insert {
    my ($self, $attributes, %options) = @_;
    my $item = $self->instantiate_item($attributes, $options{id})->put;

    # process 'set' option
    foreach my $attribute (keys %{$options{set}}) {
        $item->$attribute( $options{set}{$attribute} );
    }

    return $item;
}

#--------------------------------------------------------

=head2 count ( [ options ] ) 

Returns an integer indicating how many items are in this domain.

WARNING: With this method you need to be aware that SimpleDB is eventually consistent. See L<SimpleDB::Class/"Eventual Consistency"> for details.

=head3 options

A hash containing options to modify the count.

=head4 where

A where clause as defined in L<SimpleDB::Class::SQL> if you want to count only a certain number of items in the domain.

=head4 consistent

A boolean that if set true will get around Eventual Consistency, but at a reduced performance.

=cut

sub count {
    my ($self, %options) = @_;
    my $select = SimpleDB::Class::SQL->new(
        item_class  => $self->item_class,
        simpledb    => $self->simpledb,
        where       => $options{where},
        output      => 'count(*)',
    );
    my %params = ( SelectExpression    => $select->to_sql );
    if ($options{consistent}) {
        $params{ConsistentRead} = 'true';
    }
    my $result = $self->simpledb->http->send_request('Select', \%params);
    return $result->{SelectResult}{Item}[0]{Attribute}{Value};
}

#--------------------------------------------------------

=head2 fetch_ids ( [ options ] ) 

Returns an array reference of ids (itemName()s) in the domain.

WARNING: With this method you need to be aware that SimpleDB is eventually consistent. See L<SimpleDB::Class/"Eventual Consistency"> for details.

=head3 options

A hash containing options to modify the array reference.

=head4 where

A where clause as defined in L<SimpleDB::Class::SQL> if you want to fetch only a certain number of items in the domain.

=head4 consistent

Defaults to 0. A boolean that if set true will get around Eventual Consistency, but at a reduced performance.

=cut

sub fetch_ids {
    my ($self, %options) = @_;
    my $select = SimpleDB::Class::SQL->new(
        item_class  => $self->item_class,
        simpledb    => $self->simpledb,
        where       => $options{where},
        output      => 'itemName()',
    );
    my %params = ( SelectExpression    => $select->to_sql );
    if ($options{consistent}) {
        $params{ConsistentRead} = 'true';
    }
    my $result = $self->simpledb->http->send_request('Select', \%params);
    my $items = $result->{SelectResult}{Item};
    my @ids;
    foreach my $item (@{$items}) {
        push @ids, $item->{Name};
    }
    return \@ids;
}

#--------------------------------------------------------

=head2 max ( attribute, [ options ] )

Returns the maximum value of an attribute.

WARNING: With this method you need to be aware that SimpleDB is eventually consistent. See L<SimpleDB::Class/"Eventual Consistency"> for details.

=head3 attribute

The name of the attribute to find the maximum value of.

=head3 options

A hash of options to modify the search.

=head4 where

A where clause as defined by L<SimpleDB::Class::SQL>. An optional clause to limit the range of the maximum value.

=head4 consistent

A boolean that if set true will get around Eventual Consistency, but at a reduced performance.

=cut

sub max {
    my ($self, $attribute, %options) = @_;
    my $where = {
        $attribute => ['!=','-1000001'],
    };
    if (ref $options{where} eq 'HASH') {
        $where->{'-and'} = $options{where};
    }
    my $select = SimpleDB::Class::SQL->new(
        simpledb    => $self->simpledb,
        item_class  => $self->item_class,
        where       => $where,
        limit       => 1,
        order_by    => [$attribute],
        output      => $attribute,
    );
    my %params = ( SelectExpression    => $select->to_sql );
    if ($options{consistent}) {
        $params{ConsistentRead} = 'true';
    }
    my $result = $self->simpledb->http->send_request('Select', \%params);
    my $value = $result->{SelectResult}{Item}[0]{Attribute}{Value};
    return $self->item_class->parse_value($attribute, $value);
}

#--------------------------------------------------------

=head2 min ( attribute, [ options ] )

Returns the minimum value of an attribute.

WARNING: With this method you need to be aware that SimpleDB is eventually consistent. See L<SimpleDB::Class/"Eventual Consistency"> for details.

=head3 attribute

The name of the attribute to find the minimum value of.

=head3 options

A hash of extra options to modify the search.

=head4 where

A where clause as defined by L<SimpleDB::Class::SQL>. An optional clause to limit the range of the minimum value.

=head4 consistent

A boolean that if set true will get around Eventual Consistency, but at a reduced performance.

=cut

sub min {
    my ($self, $attribute, %options) = @_;
    my $where = {
        $attribute => ['!=','-1000001'],
    };
    if (ref $options{where} eq 'HASH') {
        $where->{'-and'} = $options{where};
    }
    my $select = SimpleDB::Class::SQL->new(
        simpledb    => $self->simpledb,
        item_class  => $self->item_class,
        where       => $where,
        limit       => 1,
        order_by    => $attribute,
        output      => $attribute,
    );
    my %params = ( SelectExpression    => $select->to_sql );
    if ($options{consistent}) {
        $params{ConsistentRead} = 'true';
    }
    my $result = $self->simpledb->http->send_request('Select', \%params);
    my $value = $result->{SelectResult}{Item}[0]{Attribute}{Value};
    return $self->item_class->parse_value($attribute, $value);
}

#--------------------------------------------------------

=head2 search ( options )

Returns a L<SimpleDB::Class::ResultSet> object. 

WARNING: With this method you need to be aware that SimpleDB is eventually consistent. See L<SimpleDB::Class/"Eventual Consistency"> for details.

=head3 options

A hash of options to set up the search.

=head4 where

A where clause as defined by L<SimpleDB::Class::SQL>.

=head4 order_by

An order by clause as defined by L<SimpleDB::Class::SQL>.

=head4 limit

A limit clause as defined by L<SimpleDB::Class::SQL>.

=head4 consistent

A boolean that if set true will get around Eventual Consistency, but at a reduced performance.

=head4 set 

A hash reference of attribute names paired with values that should be set as soon as the item is instantiated. This is useful for prefilling cache attributes as items come off the result set, and is used by the C<has_many> method for that purpose. Doing so prevents stale object references.

=cut

sub search {
    my ($self, %options) = @_;
    $options{simpledb} = $self->simpledb;
    $options{item_class} = $self->item_class;
    return SimpleDB::Class::ResultSet->new(%options);
}

=head1 LEGAL

SimpleDB::Class is Copyright 2009-2010 Plain Black Corporation (L<http://www.plainblack.com/>) and is licensed under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;