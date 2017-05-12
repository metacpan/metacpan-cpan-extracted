package SIAM::Driver::Simple;

use warnings;
use strict;

use YAML ();
use Log::Handler;
use Digest::MD5 ();
use File::stat;

=head1 NAME


SIAM::Driver::Simple - a reference implementation of SIAM Driver


=cut


=head1 SYNOPSIS

The driver does not connect to any external databases. Instead, it reads
all the SIAM objects from its YAML data file.

The top level element in the data file is expected to be an array of
objects that are contained in the SIAM root. The following object
classes are expected to be contained by the root object:

=over 4

=item * SIAM::Contract

=item * SIAM::AccessScope

=item * SIAM::User

=item * SIAM::Device

=item * SIAM::Attribute

=back

Each object definition may have an entry with the key C<_contains_>
which points to an array of contained objects. For example, an
C<SIAM::Contract> object is expected to contain one or more
C<SIAM::Service> objects.

If a key starts with C<_compute_>, it represents a computable for a
given object.

All other keys in the object entry define the object attributes. The
values are expected to be strings and numbers. The data file should
define all the attributes, including C<siam.object.id> and
C<siam.object.class>.

See the file I<t/driver-simple.data.yaml> in SIAM package distribution
for reference.


=head1 MANDATORY METHODS

The following methods are required by C<SIAM::Documentation::DriverSpec>.


=head2 new

Instantiates a new driver object. The method expects a hashref
containing the attributes, as follows:

=over 4

=item * Logger

The logger object is supplied by SIAM.

=item * Datafile

Full path of the YAML data file which defines all the objects for this driver.

=back

=cut

sub new
{
    my $class = shift;
    my $drvopts = shift;

    my $self = {};
    bless $self, $class;

    $self->{'logger'} = $drvopts->{'Logger'};
    die('Logger is not supplied to the driver')
        unless defined($self->{'logger'});
    
    foreach my $param ('Datafile')
    {
        if( not defined($drvopts->{$param}) )
        {
            $self->error('Missing mandatiry parameter ' . $param .
                         ' in SIAM::Driver::Simple->new()');
            return undef;
        }
    }

    $self->{'datafile'} = $drvopts->{'Datafile'};
    
    if( not -r $self->{'datafile'} )
    {
        $self->error('Data file is not readable: ' . $self->{'datafile'});
        return undef;
    }
    
    return $self;    
}


=head2 connect

Reads the YAML data file

=cut

sub connect
{
    my $self = shift;

    $self->debug('Connecting SIAM::Driver::Simple driver to data file: ' .
                 $self->{'datafile'});

    my $st = stat($self->{'datafile'});
    $self->{'datafile_lastmod'} = $st->mtime();    
    
    my $data = eval { YAML::LoadFile($self->{'datafile'}) };
    if( $@ )
    {
        $self->error('Cannot load YAML data from ' .
                     $self->{'datafile'} . ': ' . $@);
        return undef;
    }
    
    if( ref($data) ne 'ARRAY' )
    {
        $self->error('Top level is not a sequence in ' . $self->{'datafile'});
        return undef;
    }

    $self->{'objects'} = {};
    $self->{'cont_attr_index'} = {};
    $self->{'attr_index'} = {};
    $self->{'contains'} = {};
    $self->{'container'} = {};
    $self->{'data_ready'} = 1;
    $self->{'computable_cache'} = {};
    
    foreach my $obj (@{$data})
    {
        $self->_import_object($obj, 'SIAM.ROOT');
    }
    
    return $self->{'data_ready'};
}

# recursively import the objects

sub _import_object
{
    my $self = shift;
    my $obj = shift;
    my $container_id = shift;

    my $id = $obj->{'siam.object.id'};
    if( not defined($id) )
    {
        $self->error($container_id .
                     ' contains an object without "siam.object.id"' );
        $self->{'data_ready'} = 0;
        return;
    }

    my $class = $obj->{'siam.object.class'};
    if( not defined($class) )
    {
        $self->error('Object ' . $id . ' does not have "siam.object.class"' );
        $self->{'data_ready'} = 0;
        return;
    }
        
    # duplicate all attributes except "_contains_"

    my $dup = {};
    while( my ($key, $val) = each %{$obj} )
    {
        if( $key ne '_contains_' )
        {
            $dup->{$key} = $val;
            $self->{'cont_attr_index'}{$class}{$container_id}{
                $key}{$val}{$id} = 1;
            $self->{'attr_index'}{$class}{$key}{$val}{$id} = 1;
        }
    }
    
    $self->{'objects'}{$id} = $dup;    
    $self->{'contains'}{$container_id}{$class}{$id} = 1;
    $self->{'container'}{$id} = $container_id;
        
    if( defined($obj->{'_contains_'}) )
    {
        foreach my $contained_obj (@{$obj->{'_contains_'}})
        {
            $self->_import_object($contained_obj, $id);
        }
    }
}


=head2 disconnect

Disconnects the driver from its underlying databases.

=cut

sub disconnect
{
    my $self = shift;
    
    delete $self->{'objects'};
    delete $self->{'attr_index'};
    delete $self->{'cont_attr_index'};
    delete $self->{'contains'};
    delete $self->{'container'};
    delete $self->{'computable_cache'};
    $self->{'data_ready'} = 0;
}


=head2 fetch_attributes

 $status = $driver->fetch_attributes($attrs);

Retrieve the object by ID and populate the hash with object attributes.

=cut

sub fetch_attributes
{
    my $self = shift;
    my $obj = shift;

    my $id = $obj->{'siam.object.id'};
    if( not defined($id) )
    {
        $self->error('siam.object.id is not specified in fetch_attributes' );
        return undef;
    }
    
    if( not defined($self->{'objects'}{$id}) )
    {
        $self->error('Object not found: ' . $id );      
        return undef;
    }

    while( my($key, $val) = each %{$self->{'objects'}{$id}} )
    {
        if( $key !~ /^_compute_/o )
        {
            $obj->{$key} = $val;
        }
    }
    
    return 1;
}
    

=head2 fetch_computable

  $value = $driver->fetch_computable($id, $key);

Retrieve a computable. Return empty string if unsupported.

=cut

sub fetch_computable
{
    my $self = shift;
    my $id = shift;
    my $key = shift;

    my $obj = $self->{'objects'}{$id};
    if( not defined($obj) )
    {
        $self->error('Object not found: ' . $id );
        return undef;
    }

    if( $key eq 'siam.contract.content_md5hash' )
    {
        if( $obj->{'siam.object.class'} eq 'SIAM::Contract' )
        {
            my $st = stat($self->{'datafile'});
            if( $st->mtime() != $self->{'datafile_lastmod'} )
            {
                $self->disconnect();
                $self->connect();
            }
            elsif( defined($self->{'computable_cache'}{$key}) )
            {
                return $self->{'computable_cache'}{$key};
            }
                
            my $md5 = new Digest::MD5;
            $self->_object_content_md5($id, $md5);
            my $ret = $md5->hexdigest();
            $self->{'computable_cache'}{$key} = $ret;
            return $ret;
        }
    }
    else
    {
        my $val = $self->{'objects'}{$id}{'_compute_' . $key};
        if( defined($val) )
        {
            return $val;
        }
    }
    
    return '';
}
            

# recursively add all contained objects for MD5 calculation
sub _object_content_md5
{
    my $self = shift;
    my $id = shift;
    my $md5 = shift;

    my $obj = $self->{'objects'}{$id};
    
    foreach my $attr (sort keys %{$obj})
    {
        $md5->add('#' . $attr . '//' . $obj->{$attr} . '#');
    }

    if( defined($self->{'contains'}{$id}) )
    {
        foreach my $class (sort keys %{$self->{'contains'}{$id}})
        {
            foreach my $contained_id (sort
                                      keys %{$self->{'contains'}{$id}{$class}})
            {
                $self->_object_content_md5($contained_id, $md5);
            }
        }        
    }
}
    


=head2 fetch_contained_object_ids

   $ids = $driver->fetch_contained_object_ids($id, 'SIAM::Contract', {
       'match_attribute' => [ 'siam.object.access_scope_id',
                              ['SCOPEID01', 'SCOPEID02'] ]
      }
     );

Retrieve the contained object IDs.

=cut

sub fetch_contained_object_ids
{
    my $self = shift;
    my $container_id = shift;
    my $class = shift;
    my $options = shift;

    my $ret = [];

    if( defined($options) )
    {
        if( defined($options->{'match_attribute'}) )
        {
            my ($filter_attr, $filter_val) = @{$options->{'match_attribute'}};
            
            foreach my $val (@{$filter_val})                
            {
                push(@{$ret}, 
                     keys %{$self->{'cont_attr_index'}{$class}{$container_id}{
                         $filter_attr}{$val}});
            }

            return $ret;
        }
    }
    
    if( defined($self->{'contains'}{$container_id}{$class}) )
    {
        push(@{$ret}, keys %{$self->{'contains'}{$container_id}{$class}});
    }

    return $ret;
}



=head2 fetch_contained_classes

  $classes = $driver->fetch_contained_classes($id);

Returns arrayref with class names.

=cut

sub fetch_contained_classes
{
    my $self = shift;
    my $id = shift;

    my $ret = [];
    if( defined($self->{'contains'}{$id}) )
    {
        foreach my $class (sort keys %{$self->{'contains'}{$id}})
        {
            push(@{$ret}, $class);
        }
    }
    return $ret;
}


=head2 fetch_container

  $attr = $driver->fetch_container($id);

Retrieve the container ID and class.

=cut

sub fetch_container
{
    my $self = shift;
    my $id = shift;

    my $container_id = $self->{'container'}{$id};
    if( not defined($container_id) )
    {
        return undef;
    }

    my $ret = {'siam.object.id' => $container_id};
    if( $container_id ne 'SIAM.ROOT' )
    {
        $ret->{'siam.object.class'} =
            $self->{'objects'}{$container_id}{'siam.object.class'};
    }
    
    return $ret;
}


=head2 fetch_object_ids_by_attribute

  $list = $driver->fetch_object_ids_by_attribute($classname, $attr, $value);

Returns a list of object IDs which match the attribute value.

=cut

sub fetch_object_ids_by_attribute
{
    my $self = shift;
    my $class = shift;
    my $attr = shift;
    my $value = shift;

    return [keys %{$self->{'attr_index'}{$class}{$attr}{$value}}];
}
        


=head2 set_condition

The method does nothing in this driver, but only issues a debug message.

=cut

sub set_condition
{
    my $self = shift;
    my $id = shift;    
    my $key = shift;
    my $value = shift;

    $self->debug('set_condition is called for ' . $id . ': (' .
                 $key . ', ' . $value . ')');
}


=head2 manifest_attributes

The method returns an arrayref with all known attribute names.

=cut

sub manifest_attributes
{
    my $self = shift;

    # avoid duplicates and skip siam.* attributes
    my %manifest;
    while(my ($class, $r1) = each %{$self->{'attr_index'}})
    {
        while(my ($attr, $r2) = each %{$r1})
        {
            if( $attr !~ /^siam\./o )
            {
                $manifest{$attr} = 1;
            }
        }
    }

    return [keys %manifest];
}




=head1 ADDITIONAL METHODS

The following methods are not in the Specification.


=head2 debug

Prints a debug message to the logger.

=cut

sub debug
{
    my $self = shift;
    my $msg = shift;    
    $self->{'logger'}->debug($msg);
}


=head2 error

Prints an error message to the logger.

=cut

sub error
{
    my $self = shift;
    my $msg = shift;    
    $self->{'logger'}->error($msg);
}


=head2 object_exists

Takes an object ID and returns true if such object is present in the database.

=cut

sub object_exists
{
    my $self = shift;
    my $id = shift;
    return defined($self->{'objects'}{$id});
}


=head2 clone_data

  $data = SIAM::Driver::Simple->clone_data($siam, $callback);

The method takes a SIAM object and a callback reference.  It walks
through the SIAM data and produces a clone suitable for
storing into a YAML file and re-using with C<SIAM::Driver::Simple>.

The callback is a sub reference which is supplied with the object ID as
an argument. Only the objects which result in true value are being
cloned.

The method is usable for producing a test data out of productive system.

=cut

sub clone_data
{
    my $class = shift;
    my $siam = shift;
    my $filter_callback = shift;

    return $class->_retrieve_object_data($siam, $filter_callback);
}

# recursively walk the objects
    
sub _retrieve_object_data
{
    my $class = shift;
    my $obj = shift;
    my $filter_callback = shift;

    my $ret = {};

    if( not $obj->is_root() )
    {
        my $attrs = $obj->attributes();
        while(my($key, $val) = each %{$attrs})
        {
            $ret->{$key} = $val;
        }
    }

    my $contained_data = [];
    my $classes = $obj->_driver->fetch_contained_classes($obj->id);
    foreach my $objclass ( @{$classes} )
    {
        my $objects = $obj->get_contained_objects($objclass);
        foreach my $contained_obj (@{$objects})
        {
            if( &{$filter_callback}($contained_obj) )
            {
                push(@{$contained_data}, 
                     $class->_retrieve_object_data($contained_obj,
                                                   $filter_callback));
            }
        }
    }

    if( $obj->is_root() )
    {
        return $contained_data;
    }
    
    if( scalar(@{$contained_data}) > 0 )
    {
        $ret->{'_contains_'} = $contained_data;
    }

    return $ret;
}
                     



=head1 SEE ALSO

L<SIAM::Documentation::DriverSpec>, L<YAML>, L<Log::Handler>

=cut

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
