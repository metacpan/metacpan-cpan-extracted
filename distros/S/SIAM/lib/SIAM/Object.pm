package SIAM::Object;

use warnings;
use strict;

use Log::Handler;
use SIAM::Report;

# default log manager
our $logmgr = Log::Handler->new(
                                'screen' =>
                                {'log_to' => 'STDERR',
                                 'maxlevel' => 'warning',
                                 'minlevel' => 'emergency'});


=head1 NAME


SIAM::Object - the base class for all SIAM object (including the root).


=cut


=head1 SYNOPSIS



=head1 INSTANCE METHODS

=head2 new

  $new_object = new SIAM::Object($driver, $id)

Instantiates a new object. The method expects a driver object and an Object ID.

=cut

sub new
{
    my $class = shift;
    my $driver = shift;
    my $id = shift;

    my $self = {};
    bless $self, $class;

    $self->{'_attr'} = {'siam.object.id'    => $id,
                        'siam.object.class' => $class};    
    $self->{'_driver'} = $driver;

    # retrieve attributes from the driver unless I am root
    if( not $self->is_root )
    {
        if( not $driver->fetch_attributes($self->{'_attr'}) )
        {
            SIAM::Object->error('Failed fetching attributes for ' . $id);
            return undef;
        }

        # set siam.object.complete to true if undefined
        if( not defined($self->{'_attr'}{'siam.object.complete'}) )
        {
            $self->{'_attr'}{'siam.object.complete'} = 1;
        }

        # set siam.object.has_reports to false if undefined
        if( not defined($self->{'_attr'}{'siam.object.has_reports'}) )
        {
            $self->{'_attr'}{'siam.object.has_reports'} = 0;
        }
        
        # check if mandatory attributes are defined by the driver
        if( $self->can('_mandatory_attributes') )
        {
            foreach my $attr (@{ $self->_mandatory_attributes() })
            {
                if( not defined($self->{'_attr'}{$attr}) )
                {
                    SIAM::Object->error
                          ('Driver did not fetch a mandatory attribute "' .
                           $attr . '" for object ID "' . $id . '"');
                    return undef;
                }
            }
        }
    }

    return $self;    
}


=head2 instantiate_object

Expects the object class and ID. Returns an object retrieved from the driver.

=cut

sub instantiate_object
{
    my $self = shift;
    my $obj_class = shift;
    my $obj_id = shift;

    my $obj = eval 'new ' . $obj_class . '($self->_driver, $obj_id)';
    if( $@ )
    {
        $self->error('Cannot instantiate object of class "' . $obj_class .
                     '" and ID "' . $obj_id . '": ' . $@);
        return undef;
    }
    
    return $obj;
}


=head2 get_contained_objects

 my $list = $object->get_contained_objects($classname, $options);

Fetches the list of contained objects of a given class. Returns arrayref of
C<SIAM::Object> instances. This is the preferred method of instantiating new
objects instead of manually calling the C<new> method.

It is assumed that the class name is already known to Perl, and the
corresponding module was loaded with C<use> or C<require>.

Without the options, the method retrieves all available objects. Options may
define a filter criteria as follows:

 my $list =
   $siam->get_contained_objects('SIAM::Contract', {
       'match_attribute' => [ 'siam.object.access_scope_id',
                                 ['SCOPEID01', 'SCOPEID02'] ]
     });

Currently only one filter condition is supported. 

=cut

sub get_contained_objects
{
    my $self = shift;
    my $classname = shift;
    my $options = shift;

    my $driver = $self->_driver;
    my $ids =
        $driver->fetch_contained_object_ids($self->id, $classname, $options);
    
    my $ret = [];
    foreach my $id (@{$ids})
    {
        my $obj = eval($classname . '->new($driver, $id)');

        if( $@ )
        {
            SIAM::Object->error($@);
        }
        elsif( defined($obj) )
        {
            push(@{$ret}, $obj);
        }
    }

    return $ret;
}


=head2 get_objects_by_attribute

  my $list = $siam->get_objects_by_attribute(
       'SIAM::Device', 'siam.device.inventory_id', $id);

The method takes 3 arguments: class name, attribute name, and attribute
value. It returns an arrayref of objects matching the attribute. Empty
arrayref is returned if no objects match the criteria.

=cut

sub get_objects_by_attribute
{
    my $self = shift;
    my $classname = shift;
    my $attr = shift;
    my $value = shift;

    my $driver = $self->_driver;
    my $ids =
        $driver->fetch_object_ids_by_attribute($classname, $attr, $value);
    
    my $ret = [];
    foreach my $id (@{$ids})
    {
        my $obj = eval($classname . '->new($driver, $id)');
        
        if( $@ )
        {
            SIAM::Object->error($@);
        }
        elsif( defined($obj) )
        {
            push(@{$ret}, $obj);
        }
    }

    return $ret;
}
    


=head2 deep_walk_contained_objects

 my $list = $object->deep_walk_contained_objects($classname);

The method walks down the tree of contained objects and retrieves a list
of all found objects. It returns an array reference with all found objects;

=cut


sub deep_walk_contained_objects
{
    my $self = shift;
    my $classname = shift;

    # id => objref
    # the hash is needed to avoid object duplications
    my $results = {};
    $self->_walk_recursive($classname, $results);

    return [values %{$results}];
}


sub _walk_recursive
{
    my $self = shift;
    my $classname = shift;
    my $results = shift;

    my $driver = $self->_driver;
    my $contained_classes = $driver->fetch_contained_classes($self->id());

    foreach my $obect_class (@{$contained_classes})
    {
        my $list = $self->get_contained_objects($obect_class);

        if( $obect_class eq $classname )
        {
            foreach my $item (@{$list})
            {
                $results->{$item->id()} = $item;
            }
        }
            
        foreach my $item (@{$list})
        {
            $item->_walk_recursive($classname, $results);
        }
    }
    return;
}



=head2 id

Returns a value of C<siam.object.id> attribute

=cut

sub id { shift->attr('siam.object.id') }


=head2 objclass

Returns the value of C<siam.object.class> attribute.

=cut
    
sub objclass { shift->attr('siam.object.class') }


=head2 attr

 $val = $contract->attr('siam.contract.inventory_id');

Returns a value of an attribute.

=cut

sub attr
{
    my $self = shift;
    my $key = shift;
    return $self->{'_attr'}{$key};
}


=head2 attributes

Returns a hashref with copies of all object attributes.

=cut

sub attributes
{
    my $self = shift;

    my $ret = {};
    while( my($key, $val) = each %{$self->{'_attr'}} )
    {
        $ret->{$key} = $val;
    }
    return $ret;
}


=head2 is_complete

Returns the value of C<siam.object.complete>.

=cut

sub is_complete
{
    my $self = shift;
    my $key = shift;
    return $self->{'_attr'}{'siam.object.complete'};
}

    

=head2 computable

 $val = $contract->computable('siam.contract.content_md5hash');

Returns a value of a computable.

=cut

sub computable
{
    my $self = shift;
    my $key = shift;
    return $self->_driver->fetch_computable($self->id, $key);
}


=head2 set_condition

 $dataelement->set_condition('torrus.import_successful', 1);

The SIAM client application may use this method to send a (key, value)
pair to the driver and tell it about some state update. The condition
names and accepted values are defined by the driver and are
driver-specific. This is a one-way communication, and there is no way to
read the condition value.

=cut

sub set_condition
{
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->_driver->set_condition($self->id, $key, $value);
}

=head2 is_root

Returns true if the object is a root.

=cut

sub is_root { (shift->id) eq 'SIAM.ROOT' }


=head2 is_predefined

Returns true if the object is a predefined object (the one with the ID
starting with I<SIAM.>)

=cut

sub is_predefined { substr(shift->id, 0, 5) eq 'SIAM.' }


=head2 contained_in

Returns the object that contains this object. Returns undef if container
is the root object.

=cut

sub contained_in
{
    my $self = shift;

    my $attr = $self->_driver->fetch_container($self->id);
    if( $attr->{'siam.object.id'} eq 'SIAM.ROOT' )
    {
        return undef;
    }
    
    return $self->instantiate_object($attr->{'siam.object.class'},
                                     $attr->{'siam.object.id'});
}
    


=head2 get_reports

Returns arrayref with contained SIAM::Report objects

=cut

sub get_reports
{
    my $self = shift;

    if( $self->attr('siam.object.has_reports') )
    {
        return $self->get_contained_objects('SIAM::Report');
    }
    else
    {
        return [];
    }
}



=head1 CLASS METHODS

=head2 validate_driver

Takes a driver object as an argument and verifies if it implements all
required methods. returns true if all required methods are present. It
issues error messages in case of missing methods.

=cut

sub validate_driver
{
    my $class = shift;
    my $driver = shift;

    my $ok = 1;
    foreach my $m ('fetch_attributes', 'fetch_contained_object_ids',
                   'fetch_contained_classes', 'fetch_container',
                   'fetch_object_ids_by_attribute', 'set_condition',
                   'manifest_attributes', 'connect', 'disconnect')
    {
        if( not $driver->can($m) )
        {
            SIAM::Object->error
                  ('The driver of class ' . ref($driver) . ' does not ' .
                   'implement a required method: ' . $m);
            $ok = 0;
        }
    }

    return $ok;
}





=head2 set_log_manager

Sets a log manager for SIAM objects. Note that it does not set the log
manager for the driver.  The default log manager is a C<Log::Handler>
object with STDERR output of warnings and errors. The method expects one
argument, an object which implements the following methods:

=over 4

=item * debug

=item * info

=item * warn

=item * error

=back

Classes that suit as log managers: C<Log::Handler>, C<Log::Log4perl>, ...

=cut

sub set_log_manager
{
    my $class = shift;
    $logmgr = shift;
}


=head2 get_log_manager

Returns the current logger object.

=cut

sub get_log_manager
{
    return $logmgr;
}


=head2 debug, info, warn, error

These methods dispatch a message to the log manager. If the log manager
is undefined, all except C<debug()> print the message to STDERR with a
preceeding timestamp.

=cut

sub debug
{
    my $class = shift;
    my $msg = shift;
    $logmgr->debug($msg);
}

sub info
{
    my $class = shift;
    my $msg = shift;
    $logmgr->info($msg);
}

sub warn
{
    my $class = shift;
    my $msg = shift;
    $logmgr->warn($msg);
}

sub error
{
    my $class = shift;
    my $msg = shift;
    $logmgr->error($msg);
}



=head1 PRIVATE METHODS

=head2 _driver

Returns the driver object

=cut

sub _driver { shift->{'_driver'} }


=head2 _print_stderr

Prints a message to STDERR with a preceeding timestamp

=cut

sub _print_stderr
{
    my $class = shift;
    my $msg = shift;

    print STDERR '[' . scalar(localtime(time())) . '] ' . $msg . "\n";
}



1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
