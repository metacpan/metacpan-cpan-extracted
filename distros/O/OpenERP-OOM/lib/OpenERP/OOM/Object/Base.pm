package OpenERP::OOM::Object::Base;

use 5.010;
use Carp;
use Data::Dumper;
use List::MoreUtils qw/uniq/;
use Moose;
use Try::Tiny;
use Try::Tiny::Retry;
use Time::HiRes qw/usleep/;
use Switch::Plain;

extends 'Moose::Object';
with 'OpenERP::OOM::DynamicUtils';


has 'id' => (
    isa => 'Int',
    is  => 'ro',
);

sub BUILD {
    my $self = shift;

    # Add methods to follow links
    my $links = $self->meta->link;
    while (my ($name, $link) = each %$links) {
        sswitch ($link->{type}) {
            case ('single'): {
                $self->meta->add_method(
                    $name,
                    sub {
                        my $obj = shift;
                        $obj->{"_$name"} //= $obj->class->schema->link($link->{class})->retrieve($link->{args}, $obj->{$link->{key}});

                        unless ($obj->{"_$name"}) {
                            # FIXME: If $obj->{"_$name"} is undefined, we have a data integrity problem.
                            # Either the linked data is missing, or the key in the OpenERP object is missing.
                            die "Error linking to OpenERP object " . $obj->id . " of class " . ref($obj);
                        }

                        # NOTE: this only links up the object from the linked object
                        # if it has a _source attribute
                        #
                        # has _source => (is => 'rw');

                        if ($obj->{"_$name"}->can('_source')) {
                            # set the _source attribute to point back
                            # to the linked object.
                            $obj->{"_$name"}->_source($obj);
                        }

                        return $obj->{"_$name"};
                    }
                )
            }
            case ('multiple'): {
                $self->meta->add_method(
                    $name,
                    sub {
                        return $self->class->schema->link($link->{class})->retrieve_list($link->{args}, $self->{$link->{key}});
                    }
                )
            }
        }
    }
}


#-------------------------------------------------------------------------------


sub update {
    my $self = shift;

    if (my $update = shift) {
        while (my ($param, $value) = each %$update) {
            $self->$param($value);
        }
    }
    my $context = $self->class->_get_context(shift);

    my $object;
    foreach my $attribute ($self->dirty_attributes) {
        next if ($attribute eq 'id');
        next if ($attribute =~ '^_');

        $object->{$attribute} = $self->{$attribute};
    }

    my $relationships = $self->meta->relationship;
    while (my ($name, $rel) = each %$relationships) {
        if ($object->{$rel->{key}}) {
            sswitch ($rel->{type}) {
                case ('one2many'): {
                    delete $object->{$rel->{key}};  # Don't update one2many relationships
                }
                case ('many2many'): {
                    $object->{$rel->{key}} = [[6,0,$object->{$rel->{key}}]];
                }
            }
        }
    }

    # Force Str parameters to be object type RPC::XML::string
    foreach my $attribute ($self->meta->get_all_attributes) {
        if (exists $object->{$attribute->name}) {
            $object->{$attribute->name} = $self->prepare_attribute_for_send($attribute->type_constraint, $object->{$attribute->name});
        }
    }

    $self->class->_with_retries(sub {
        $self->class->schema->client->update($self->model, $self->id, $object, $context);
    });
    $self->refresh;

    return $self;
}

#-------------------------------------------------------------------------------


sub update_single {
    my ($self, $property) = @_;
    my $value = $self->{$property};

    # Check to see if the property is the key to a many2many relationship
    my $relationships = $self->meta->relationship;
    my ($key) = grep { $relationships->{$_}->{key} eq $property } keys %$relationships;
    if($key)
    {
        my $rel = $relationships->{$key};
        if ($rel->{type} eq 'many2many') {
            $value = [[6,0,$value]];
        }
    }

    # Force Str parameters to be object type RPC::XML::string
    foreach my $attribute ($self->meta->get_all_attributes) {
        if ($attribute->name eq $property) {
            $value = $self->prepare_attribute_for_send($attribute->type_constraint, $value);
        }
    }

    $self->class->schema->client->update($self->model, $self->id, {$property => $value});
    return $self;
}

#-------------------------------------------------------------------------------


sub refresh {
    my $self = shift;

    my $new = $self->class->retrieve($self->id);

    foreach my $attribute ($self->meta->get_all_attributes) {
        my $name = $attribute->name;
        $self->{$name} = ($new->$name);
    }
    $self->mark_all_clean; # reset the dirty attribute

    return $self;
}


#-------------------------------------------------------------------------------


sub delete {
    my $self = shift;

    $self->class->schema->client->delete($self->model, $self->id);
}

sub _copy
{
    my $self = shift;

    my $id = $self->class->schema->client->copy($self->model, $self->id);
    # now load the new invoice and return it
    return $id;
}


sub copy
{
    my ($self, @args) = @_;
    my $args = shift;
    my $id = $self->_copy;
    # passing args through allows for field refinement.
    my $clone = $self->class->retrieve($id, @args);
    return $clone;
}

#-------------------------------------------------------------------------------


sub print {
    my $self = shift;

    say "Print called";
}


#-------------------------------------------------------------------------------


sub real_create_related
{
    my $self = shift;
    my $relation_name = shift;
    my $object = shift;
    my $context = $self->class->_get_context(shift);

    # find relationship class
    my $class = $self->relationship_class($relation_name);
    my $data = $class->_collapse_data_to_ids($object);

    $self->class->schema->client->update($self->model, $self->id, {$relation_name => [[ 0, 0, $data ]]}, $context);

    # FIXME: need to check what happens to existing data
    # how do you add multiple objects ?
    return;
}


sub create_related {
    my ($self, $relation_name, $object) = @_;

    ### Creating related object 
    ### $relation_name
    ### with initial data:
    ### $object
    my $created_obj;

    if (my $relation = $self->meta->relationship->{$relation_name}) {
        sswitch ($relation->{type}) {
            case ('one2many'): {
                my $class = $self->meta->name;
                if ($class =~ m/(.*?)::(\w+)$/) {
                    my ($base, $name) = ($1, $2);
                    my $related_class = $base . "::" . $relation->{class};

                    $self->ensure_class_loaded($related_class);
                    my $related_meta = $related_class->meta->relationship;

                    my $far_end_relation;
                    REL: for my $key (keys %$related_meta) {
                        my $value = $related_meta->{$key};
                        if ($value->{class} eq $name) {
                            $far_end_relation = $key;
                            last REL;
                        }
                    }

                    if ($far_end_relation) {
                        my $foreign_key = $related_meta->{$far_end_relation}->{key};

                        ### Far end relation exists
                        $created_obj = $self->class->schema->class($relation->{class})->create({
                            %$object,
                            $foreign_key => $self->id,
                        });

                        $self->refresh;
                    } else {
                        my $new_object = $self->class->schema->class($relation->{class})->create($object);

                        $created_obj = $new_object;
                        $self->refresh;

                        unless (grep {$new_object->id} @{$self->{$relation->{key}}}) {
                            push @{$self->{$relation->{key}}}, $new_object->id;
                            $self->update;
                        }
                    }
                }
            }
            case ('many2many'): {
                say "create_related many2many";
            }
            case ('many2one'): {
                say "create_related many2one";
            }
        }
    } elsif ($relation = $self->meta->link->{$relation_name}) {
        sswitch ($relation->{type}) {
            case ('single'): {
                ### Creating linked object
                try {
                    my $id = $self->class->schema->link($relation->{class})->create($relation->{args}, $object);
                    $created_obj = $id;
                    ### Linked object created with key $id
                    $self->{$relation->{key}} = $id;
                    $self->update_single($relation->{key});
                    undef $self->{"_$relation_name"};
                } catch {
                    die "Error creating linked object: $_[0]";
                };
            }
            case ('multiple'): {
                say "create_linked multiple";
            }
        }
    }
    else {
        croak "Can not find relation $relation_name";
    }
    return $created_obj if $created_obj;
}

sub _id
{
    my $val = shift;
    return ref $val ? $val->id : $val;
}


sub find_related {
    my ($self) = shift;
    my @results = $self->search_related(@_);
    if(scalar @results > 1)
    {
        # should this just croak?
        carp 'find_related returned more than 1 result';
    }
    if(@results)
    {
        return $results[0];
    }
}


sub relationship_class
{
    my ($self, $relationship) = @_;
    if (my $relation = $self->meta->relationship->{$relationship}) {
        my $type = $relation->{type};
        croak 'Cannot get a class for a DBIC relationship' if $type eq 'single' 
                                                            || $type eq 'multiple';
        my $class = $relation->{class};
        return $self->class->schema->class($class);
    }
    croak "Unable to find relation $relationship";
}


sub search_related {
    my ($self, $relation_name, @search) = @_;

    # find the relation details and add it to the search criteria.
    if (my $relation = $self->meta->relationship->{$relation_name}) {
        sswitch ($relation->{type}) {
            case ('one2many'): {
                my $class = $self->meta->name;
                if ($class =~ m/(.*?)::(\w+)$/) {
                    my ($base, $name) = ($1, $2);
                    my $related_class = $self->class->schema->class($relation->{class});
                    my $related_meta = $related_class->object->meta->relationship;

                    my $far_end_relation;
                    REL: for my $key (keys %$related_meta) {
                        my $value = $related_meta->{$key};
                        if ($value->{class} eq $name) {
                            $far_end_relation = $key;
                            last REL;
                        }
                    }

                    if ($far_end_relation) {

                        my $foreign_key = $related_meta->{$far_end_relation}->{key};

                        push @search, [ $foreign_key, '=', $self->id ];
                        return $related_class->search(@search);

                    } else {
                        # well, perhaps we could fix this, but I can't be bothered at the moment.
                        croak 'Unable to search_related without relationship back';
                    }
                }
            }
            case ('many2many'): {
                croak 'Unable to search_related many2many relationships';
            }
            case ('many2one'): {
                croak 'Unable to search_related many2one relationships';
            }
        }
    } elsif ($relation = $self->meta->link->{$relation_name}) {
        croak 'Unable to search_related outside NonOpenERP';
    }

    croak 'Unable to search_related'; # beat up the lame programmer who did this.
}


#-------------------------------------------------------------------------------


sub add_related {
    my ($self, $relation_name, $object) = @_;

    if (my $relation = $self->meta->relationship->{$relation_name}) {
        sswitch ($relation->{type}) {
            case ('one2many'): {
                # FIXME - is this the same process as adding a many2many relationship?
            }
            case ('many2many'): {
                push @{$self->{$relation->{key}}}, _id($object);
                $self->{$relation->{key}} = [uniq @{$self->{$relation->{key}}}];
                $self->update_single($relation->{key});
            }
        }
    } elsif ($relation = $self->meta->link->{$relation_name}) {
        sswitch ($relation->{type}) {
            case ('multiple'): {
                # FIXME - handle linked as well as related objects
            }
        }
    }
}


#-------------------------------------------------------------------------------


sub set_related {
    my ($self, $relation_name, $object) = @_;

    if (my $relation = $self->meta->relationship->{$relation_name}) {
        sswitch ($relation->{type}) {
            case ('many2one'): {
                $self->{$relation->{key}} = $object ? _id($object) : undef;
                $self->update_single($relation->{key});
            }
            case ('many2many'): {
                my @array;
                if($object)
                {
                    if(ref $object eq 'ARRAY')
                    {
                        @array = map { _id($_) } @$object;
                    }
                    else 
                    {
                        push @array, _id($object);
                    }
                }
                $self->{$relation->{key}} = \@array;
                $self->update_single($relation->{key});
            }
            default: {
                carp "Cannot use set_related() on a $_ relationship";
            }
        }
    } else {
        carp "Relation '$relation_name' does not exist!";
    }
}


sub execute_workflow
{
    my ($self, $workflow) = @_;

    retry
    {
        $self->class->schema->client->object_exec_workflow($workflow, $self->model, $self->id);
    }
    retry_if {/current transaction is aborted, commands ignored until end of transaction block/}
    catch
    {
        die $_; # rethrow the unhandled exception
    };
}


sub execute
{
    my $self   = shift;
    my $action = shift;
    my @params = @_;

    my @args = ($action, $self->model, [$self->id], @params);
    my $retval;
    $self->class->_with_retries(sub {
        $retval = $self->class->schema->client->object_execute(@args);
    });
    return $retval;
}


sub executex
{
    my ($self, $action, @rest) = @_;

    my @args = ($action, $self->model, [$self->id]);
    push @args, @rest if @rest;
    my $retval;
    $self->class->_with_retries(sub {
        $retval = $self->class->schema->client->object_execute(@args);
    });
    return $retval;
}


sub get_report
{
    my $self = shift;
    my $report_id = shift;

    my $id = $self->class->schema->client->report_report($report_id, $self->id,
            { 
                model       => $self->model, 
                id          => $self->id,
                report_type => 'pdf',
            }, @_);

    # the report_report function returns only a report id, which is all we need to pass to the next function call
    # but report_report_get don't work first time (?!) so we need to call it recursively until with get an answer
    my $data;
    while(!$data)
    {
        $data = $self->class->schema->client->report_report_get($id);
        sleep 1;
    }
    return $data;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM::Object::Base

=head1 VERSION

version 0.46

=head1 DESCRIPTION

Provides a base set of properties and methods for OpenERP::OOM objects (update, delete, etc).

=head1 NAME

OpenERP::OOM::Class::Base

=head1 SYNOPSYS

 my $obj = $schema->class('Name')->create(\%args);

 :say $obj->id;

 $obj->name('New name');
 $obj->update;

 $obj->delete;

=head1 PROPERTIES

=head2 id

Returns the OpenERP ID of an object.

 say $obj->id;

=head2 BUILD

The BUILD method sets up the methods for the links to the attached objects.

=head1 METHODS

=head2 update

Updates an object in OpenERP after its properties have been changed.

 $obj->name('New name');
 $obj->update;

Also allows a hashref to be passed to update multiple properties:

 $obj->update({
    name  => 'new name',
    ref   => 'new reference',
    price => 'new price',
 });

=head2 update_single

Updates OpenERP with a single property of an object.

 $obj->name('New name');
 $obj->status('Active');

 $obj->update_single('name');  # Only the 'name' property is updated

=head2 refresh

Reloads an object's properties from OpenERP.

 $obj->refresh;

=head2 delete

Deletes an object from OpenERP.

 my $obj = $schema->class('Partner')->retrieve(60);
 $obj->delete;

=head2 copy

Clone the current object, returning the new object.

This is equivalent to pressing duplicate in the OpenERP user interface.

=head2 print

This is a debug method.

=head2 real_create_related

This actually does the create related via OpenERP.

I'm not sure in what scenarios you should use it versus the scenario's you 
shouldn't.  Suck it and see.

It will create calls like this,

# DEBUG_RPC:rpc.request:('execute', 'db', 1, '*', ('stock.partial.picking', 'write', [1], {'product_moves_out': [(0, 0, {'prodlot_id': False, 'product_id': 16, 'product_uom': 1, 'quantity': 10.0})]}, {'lang': 'en_GB', 'search_default_available': 1, 'project_id': False, 'tz': False, '__last_update': {'stock.partial.picking,1': False}, 'active_model': 'ir.ui.menu', 'section_id': False, 'contact_display': 'partner_address', 'active_ids': [3], 'active_id': 316}))

Note that it will not return the object created.

=head2 create_related

Creates a related or linked object.

 $obj->create_related('address',{
     street   => 'Drury Lane',
     postcode => 'CV21 3DE',
 });

=head2 find_related

Finds a property related to the current object.

    my $line = $po->find_related('order_lines', [ 'id', '=', 1 ]);

This only works with relationships to OpenERP objects (i.e. not DBIC) and 
to one2many relationships where the other side of the relationship has a field
pointing back to the object you are searching from.

In any other case the method will croak.

If the search criteria return more than one result it will whine.

=head2 relationship_class

Returns the OpenERP::OOM::Class object for the relationship passed in.

Obviously this only works for the OpenERP relationships.  It will croak
if you ask for a relationship to a DBIC object.

=head2 search_related

Searches for objects of a relation associated with this object.

    my @lines = $po->search_related('order_lines', [ 'state', '=', 'draft' ]);

This only works with relationships to OpenERP objects (i.e. not DBIC) and 
to one2many relationships where the other side of the relationship has a field
pointing back to the object you are searching from.

In any other case the method will croak.

=head2 add_related

Adds a related or linked object to a one2many, many2many, or multiple relationship.

 my $partner  = $schema->class('Partner')->find(...);
 my $category = $schema->class('PartnerCategory')->find(...);

 $partner->add_related('category', $category);

=head2 set_related

Like the DBIx::Class set_related.  Sets up a link to a related object.

=head2 execute_workflow

Performs an exec_workflow in OpenERP.  

    $self->execute_workflow('purchase_confirm');

Is likely to translate to something like this,

    # DEBUG_RPC:rpc.request:('exec_workflow', 'db', 1, '*', ('purchase.order', 'purchase_confirm', 24))

The 24 is the id of the object.

=head2 execute

Performs an execute in OpenERP.  

    $self->execute('action_process');

Is likely to translate to something like this,

    # DEBUG_RPC:rpc.request:('execute', 'gooner', 1, '*', ('stock.picking', 'action_process', [26], {'lang': 'en_GB', 'search_default_available': 1, 'active_ids': [316], 'tz': False, 'active_model': 'ir.ui.menu', 'section_id': False, 'contact_display': 'partner_address', 'project_id': False, 'active_id': 316}))

The 26 is the id of the object.

=head2 executex

Similar to execute but it allows you to specify any number of parameters.

Primarily created to prevent any compatibility problems with other callers.
Although I'm not entirely sure if there are any.

    $self->executex('add_invoices_to_payment', [1,2], [3,4]);

Translates roughly to 

    execute_kw(..., 'payment.order', 'add_invoices_to_payment', [5], [1, 2], [3, 4])

Stick a hash on the end of the list of params to pass a context object.

=head2 get_report

To print a purchase order we need to send a report, then get it, then display it, then print it (and you don't want to know about all the traffic behind the scenes...)

The first step looks like this:

    # DEBUG_RPC:rpc.request:('report', 'aquarius_openerp_jj_staging', 1, '*', (u'purchase.quotation', [1], {'model': u'purchase.order', 'id': 1, 'report_type': u'pdf'}, {'lang': u'en_GB', 'active_ids': [1], 'tz': False, 'active_model': u'purchase.order', 'section_id': False, 'search_default_draft': 1, 'project_id': False, 'active_id': 1}))

=head1 AUTHOR

Jon Allen (JJ), <jj@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
