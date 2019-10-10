package OpenERP::OOM::Class::Base;

use 5.010;
use Carp;
use Moose;
use RPC::XML;
use DateTime;
use DateTime::Format::Strptime;
use MooseX::NotRequired;
use Try::Tiny;
use Try::Tiny::Retry;
use Time::HiRes qw/usleep/;

extends 'Moose::Object';
with 'OpenERP::OOM::DynamicUtils';

=head1 NAME

OpenERP::OOM::Class::Base

=head1 SYNOPSYS

 my $obj = $schema->class('Name')->create(\%args);
 
 foreach my $obj ($schema->class('Name')->search(@query)) {
    ...
 }

=head1 DESCRIPTION

Provides a base set of methods for OpenERP::OOM classes (search, create, etc).

=cut

has 'schema' => (
    is => 'ro',
);

has 'object_class' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_object_class',
);

sub _build_object_class {
    my $self = shift;
    
    # if you get this blow up it probably means the class doesn't compile for some
    # reason.  Run the t/00-load.t tests.  If they pass check you have a use_ok 
    # statement for all your modules.
    die 'Your code doesn\'t compile llamma' if !$self->can('object');
    $self->ensure_class_loaded($self->object);
    
    $self->object->meta->add_method('class' => sub{return $self});
    
    return $self->object->new;
}

#-------------------------------------------------------------------------------

=head2 search

Searches OpenERP and returns a list of objects matching a given query.

    my @list = $schema->class('Name')->search(
        ['name', 'ilike', 'OpusVL'],
        ['active', '=', 1],
    );

The query is formatted as a list of array references, each specifying a
column name, operator, and value. The objects returned will be those where
all of these sub-queries match.

Searches can be performed against OpenERP fields, linked objects (e.g. DBIx::Class
relationships), or a combination of both.

    my @list = $schema->class('Name')->search(
        ['active', '=', 1],
        ['details', {status => 'value'}, {}],
    )

In this example, 'details' is a linked DBIx::Class object with a column called
'status'.

An optional 'search context' can also be provided at the end of the query list, e.g.

    my @list = $schema->class('Location')->search(
        ['usage' => '=' => 'internal'],
        ['active' => '=' => 1],
        {
            active_id => $self->id,
            active_ids => [$self->id],
            active_model => 'product.product',
            full => 1,
            product_id => $self->id,
            search_default_in_location => 1,
            section_id => undef,
            tz => undef,
        }
    );

Supplying a context further restricts the search, for example to narrow down a
'stock by location' query to 'stock of a specific product by location'.

Following the search context, an arrayref of options can be given to return a
paged set of results:

    {
        limit  => 10,    # Return max 10 results
        offset => 20,    # Start at result 20
    }

=head2 raw_search

This is the same as search but it doesn't turn the results into objects.  This 
is useful if your search is likely to have returned fields that aren't part of
the object.  Queries like those used by the Stock By Location report are likely
to return stock levels as well as the location details for example.

=cut

sub raw_search {
    my $self = shift;
    return $self->_raw_search(0, @_);
}

=head2 search_limited_fields

This is an alternative version of search that only fills in the required fields
of the object.

    # avoid pulling the whole attachement down for a search
    my @a = $attachments->search_limited_fields([
        qw/res_model res_name type url create_uid create_date
            datas_fname description name res_id/
    ], [
        res_model => '=' => 'product.template',
        res_id => '=' => 1,
    ]);

This allows you to avoid pulling down problem fields.  The most obvious example
is get a list of attachments for an object, without pulling down all the data
for the attachement.

=cut 

sub search_limited_fields {
    my $self = shift;
    return $self->_search_limited_fields(1, @_);
}

sub _search_limited_fields {
    my $self = shift;
    my $objects = shift;
    my $fields = shift;

    my $ids = $self->_raw_search(1, @_);
	return wantarray ? () : undef unless ( defined $ids && ref $ids eq 'ARRAY' && scalar @$ids >= 1 );
    my ($context) = grep { ref $_ eq 'HASH' } @_;
    return $self->_retrieve_list($objects, $ids, $context, $fields);
}

sub _raw_search {
    my ($self, $ids_only, @args) = @_;
    ### Initial search args: @args
    
    my @search;
    while (@args && ref $args[0] ne 'HASH') {push @search, shift @args}
    
    # Loop through each search criteria, and if it is a linked object 
    # search, replace it with a translated OpenERP search parameter.
    foreach my $criteria (@search) {
        if(ref $criteria eq 'ARRAY') {
            my $search_field = $criteria->[0];

            if (my $link = $self->object_class->meta->link->{$search_field}) {
                if ($self->schema->link($link->{class})->can('search')) {
                    my @results = $self->schema->link($link->{class})->search($link->{args}, @$criteria[1 .. @$criteria-1]);

                    if (@results) {
                        ### Adding to OpenERP search: 
                        ### $link->{key} 
                        ### IN 
                        ### join(', ', @results)
                        $criteria = [$link->{key}, 'in', \@results];
                    } else {
                        return;  # No results found, so no point searching in OpenERP
                    }
                } else {
                    carp "Cannot search for link type " . $link->{class};
                }
            }
        }
    }
    
    my $context = $self->_get_context(shift @args);
    my $options = shift @args;
    $options = {} unless $options;
    ### Search: @search
    ### Search context: $context
    ### Search options: $options
    if($ids_only)
    {
        return $self->schema->client->search($self->object_class->model,[@search], $context, $options->{offset}, $options->{limit}, $options->{order});
    }

    my $objects = $self->schema->client->search_detail($self->object_class->model,[@search], $context, $options->{offset}, $options->{limit}, $options->{order});

    if ($objects) {    
        foreach my $attribute ($self->object_class->meta->get_all_attributes) {
            if($attribute->type_constraint && $attribute->type_constraint =~ /DateTime/)
            {
                map { $_->{$attribute->name} = $self->_parse_datetime($_->{$attribute->name}) } @$objects;
            }
        }
        return $objects;
    } else {
        return undef;
    }
}

sub search
{
    my $self = shift;
    my $objects = $self->raw_search(@_);
    if($objects) {
        return map {$self->object_class->new($_)} @$objects;
    } else {
        return wantarray ? () : undef;
    }
}

=head2 is_not_null

Returns search criteria for a not null search.  i.e. equivalend to $field is not null in SQL.

    $self->search($self->is_not_null('x_department'), [ 'other_field', '=', 3 ]);

=cut

sub is_not_null
{
    my $self = shift;
    my $field = shift;
    return [ $field, '!=', RPC::XML::boolean->new(0) ];
}

=head2 null

Returns a 'null' for use in OpenERP calls and objects.  (Actually this is a False value).

=cut

sub null { RPC::XML::boolean->new(0) }

=head2 is_null

Returns search criteria for an is null search.  i.e. equivalend to $field is null in SQL.

    $self->search($self->is_null('x_department'), [ 'other_field', '=', 3 ]);

=cut

sub is_null
{
    my $self = shift;
    my $field = shift;
    return [ $field, '=', RPC::XML::boolean->new(0) ];
}

#-------------------------------------------------------------------------------

=head2 find

Returns the first object matching a given query.

 my $obj = $schema->class('Name')->find(['id', '=', 32]);

Will return C<undef> if no objects matching the query are found.

=cut

sub find {
    my $self = shift;
    
    #my $ids = $self->schema->client->search($self->object_class->model,[@_]);
    my $ids = $self->raw_search(@_);
    
    if ($ids->[0]) {
        #return $self->retrieve($ids->[0]);
        return $self->object_class->new($ids->[0]);
    }
}


=head2 get_options

This returns the options for available for a selection field.  It will croak if you
try to give it a field that isn't an option.

=cut

sub get_options 
{
    my $self = shift;
    my $field = shift;

    my $model_info = $self->schema->client->model_fields($self->object_class->model);
    my $field_info = $model_info->{$field};
    croak 'Can only get options for selection objects' unless $field_info->{type} eq 'selection';
    my $options = $field_info->{selection};
    return $options;
}

#-------------------------------------------------------------------------------

=head2 retrieve

Returns an object by ID.

 my $obj = $schema->class('Name')->retrieve(32);

=cut

sub retrieve {
    my ($self, $id, @args) = @_;
    
    # FIXME - This should probably be in a try/catch block
    my $context = $self->_get_context(shift @args);
    $self->_ensure_object_fields(\@args);
    if (my $object = $self->schema->client->read_single($self->object_class->model, $id, $context, @args)) 
    {
        return $self->_inflate_object($self->object, $object);
    }
}

sub _ensure_object_fields
{
    my $self = shift;
    my $args = shift;

    unless(@$args)
    {
        my @fields;
        foreach my $attribute ($self->object_class->meta->get_all_attributes) 
        {
            my $name = $attribute->name;
            push @fields, $name unless $name =~ /^_/;
        }
        push @$args, \@fields;
    }
}

sub _get_context
{
    my $self = shift;
    my $context = shift;

    my %translation = ( lang => $self->schema->lang );
    if($context)
    {
        # merge the context with our language for translation.
        @translation{keys %$context} = values %$context;
    }
    $context = \%translation;
    return $context;
}

sub _inflate_object
{
    my $self = shift;
    my $object_class = shift;
    my $object = shift;

    foreach my $attribute ($self->object_class->meta->get_all_attributes) {
        if($attribute->type_constraint && $attribute->type_constraint =~ /DateTime/)
        {
            $object->{$attribute->name} = $self->_parse_datetime($object->{$attribute->name});
        }
    }
    return $object_class->new($object);
}

sub _do_strptime {
    my ($self, $string, $format) = @_;
    return unless $string;
    my $parser = DateTime::Format::Strptime->new(pattern => $format, time_zone => 'UTC');
    return $parser->parse_datetime($string);
}

sub _parse_datetime {
    my ($self, $string) = @_;
    return $self->_do_strptime($string, '%Y-%m-%d %H:%M:%S') // $self->_do_strptime($string, '%Y-%m-%d');
}

=head2 default_values

Returns an instance of the object filled in with the default values suggested by OpenERP.

=cut
sub default_values
{
    my $self = shift;
    my $context = shift;
    # do a default_get

    my @fields = map { $_->name } $self->object_class->meta->get_all_attributes;
    my $object = $self->schema->client->get_defaults($self->object_class->model, \@fields, $context);
    my $class = MooseX::NotRequired::make_optional_subclass($self->object);
    return $self->_inflate_object($class, $object);
}

=head2 create_related_object_for_DBIC

Creates a related DBIC object for an object of this class (before the object
is created).

It returns a transaction guard alongside the id so that if the corresponding
object fails to create it can be aborted.  

This can make the link up smoother as you know the id of the object to refer
to in OpenERP before creating the OpenERP object.  It also allows for failures
to be dealt with more reliably.

     my ($id, $guard) = $self->create_related_object_for_DBIC('details', $details);
     # Create the object
     $object->{x_dbic_link_id} = $id;
     $object->{default_code} = sprintf("OBJ%06d", $id);

     my $prod = $self->$orig($object);
     $guard->commit;

=cut

sub create_related_object_for_DBIC
{
    my ($self, $relation_name, $data) = @_;
    my $object = $self->object_class;
    my $relation = $object->meta->link->{$relation_name};
    if($relation)
    {
        die 'Wrong type of relation' unless $relation->{class} eq 'DBIC';
        my $link = $self->schema->link($relation->{class});
        my $guard = $link->dbic_schema->storage->txn_scope_guard;
        my $id = $link->create($relation->{args}, $data);
        return ($id, $guard);
    }
    else
    {
        die 'Unable to find relation';
    }
}
#-------------------------------------------------------------------------------

=head2 retrieve_list

Takes a reference to a list of object IDs and returns a list of objects.

 my @list = $schema->class('Name')->retrieve_list([32, 15, 60]);

=cut

sub retrieve_list {
    my $self = shift;
    return $self->_retrieve_list(1, @_);
}

sub _retrieve_list {
    my ($self, $inflate_objects, $ids, @args) = @_;
    
    my $context = $self->_get_context(shift @args);
    $self->_ensure_object_fields(\@args);
    if (my $objects = $self->schema->client->read($self->object_class->model, $ids, $context, @args)) {
        foreach my $attribute ($self->object_class->meta->get_all_attributes) {
            if($attribute->type_constraint && $attribute->type_constraint =~ /DateTime/)
            {
                map { $_->{$attribute->name} = $self->_parse_datetime($_->{$attribute->name}) } @$objects;
            }
        }
        my %id_map = map { $_->{id} => $_ } @$objects;
        my @sorted = map { $id_map{$_} } @$ids;
        return map {$self->object_class->new($_)} @sorted if $inflate_objects;
        return @sorted;
    }
}


#-------------------------------------------------------------------------------

sub _collapse_data_to_ids
{
    my ($self, $object_data) = @_;

    my $relationships = $self->object_class->meta->relationship;
    while (my ($name, $rel) = each %$relationships) {
        if ($rel->{type} eq 'one2many') {
            if ($object_data->{$name}) {
                $object_data->{$rel->{key}} = $self->_id($rel, $object_data->{$name});
                delete $object_data->{$name} if $name ne $rel->{key};
            }
        }
        
        if ($rel->{type} eq 'many2one') {
            if ($object_data->{$name}) {
                $object_data->{$rel->{key}} = $self->_id($rel, $object_data->{$name});
                delete $object_data->{$name} if $name ne $rel->{key};
            }            
        }
        if ($rel->{type} eq 'many2many') {
            if ($object_data->{$name}) {
                my $val = $object_data->{$name};
                my @ids;
                if(ref $val eq 'ARRAY')
                {
                    # they passed in an arrayref.
                    my $objects = $val;
                    @ids = map { $self->_id($rel, $_) } @$objects;
                }
                else
                {
                    # assume it's a single object.
                    push @ids, $self->_id($rel, $val);
                }
                $object_data->{$rel->{key}} = [[ 6, 0, \@ids ]];
                delete $object_data->{$name} if $name ne $rel->{key};
            }            
        }
    }
    # Force Str parameters to be object type RPC::XML::string
    foreach my $attribute ($self->object_class->meta->get_all_attributes) {
        if (exists $object_data->{$attribute->name}) {
            $object_data->{$attribute->name} = $self->prepare_attribute_for_send($attribute->type_constraint, $object_data->{$attribute->name});
        }
    }
    return $object_data;
}

sub _id
{
    my $self = shift;
    my $rel = shift;
    my $val = shift;
    my $ref = ref $val;
    if($ref)
    {
        # FIXME: this is close to what I want but I need to be doing it with the class
        # that corresponds to the relation we're delving into.
        if($ref eq 'HASH')
        {
            my $class = $self->schema->class($rel->{class});
            return [[ 0, 0, $class->_collapse_data_to_ids($val) ]];
        } 
        elsif($ref eq 'ARRAY') 
        {
            # this should allow us to do child objects too.
            my $class = $self->schema->class($rel->{class});
            my @expanded = map { [ 0, 0, $class->_collapse_data_to_ids($_) ] } @$val;
            return \@expanded;
        }
        else
        {
            return $val->id;
        }
    }
    return $val;
}

=head2 create

Creates a new instance of an object in OpenERP.

 my $obj = $schema->class('Name')->create({
     name   => 'OpusVL',
     active => 1,
 });

Takes a hashref of object parameters.

Returns the new object or C<undef> if it could not be created.

=cut

sub create {
    my ($self, $object_data, @args) = @_;

    ### Create called with initial object data: 
    ### $object_data;
    
    $object_data = $self->_collapse_data_to_ids($object_data);

    ### To
    ### $object_data;
    my $id; 
    $self->_with_retries(sub {
        $id = $self->schema->client->create($self->object_class->model, $object_data, @args);
    });
    if ($id) 
    {
        return $self->retrieve($id);
    }
}

sub _with_retries
{
    my $self = shift;
    my $call = shift;
    retry
    {
        $call->();
    } 
    retry_if {/current transaction is aborted, commands ignored until end of transaction block/}
    catch
    {
        die $_; # rethrow the unhandled exception
    };
}


#-------------------------------------------------------------------------------

=head2 execute

Performs an execute in OpenERP on the class level.  

    $c->model('OpenERP')->class('Invoice')->execute('build_invoice', $args);

Please look at L<OpenERP::OOM::Object::Base> for more information on C<execute>

=cut

sub execute {
    my $self   = shift;
    my $action = shift;
    my @params = @_;
    my @args = ($action, $self->object_class->model, @params);
    my $retval;
    $self->_with_retries(sub {
        $retval = $self->schema->client->object_execute(@args);
    });
    return $retval;
}

#-------------------------------------------------------------------------------


1;
