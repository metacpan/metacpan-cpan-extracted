package Rose::DB::Object::Cached;

use strict;

use Carp();

use Rose::DB::Object;
our @ISA = qw(Rose::DB::Object);

use Rose::DB::Object::Constants qw(STATE_IN_DB);

our $VERSION = '0.785';

our $Debug = 0;

# Anything that cannot be in a column name will work for these
use constant PK_SEP => "\0\0";
use constant UK_SEP => "\0\0";

# Try to pick a very unlikely value to stand in for undef in 
# the stringified multi-column unique key value
use constant UNDEF  => "\1\2undef\2\1";

sub remember
{
  my($self) = shift;

  my $class = ref $self;
  my $meta  = $self->meta;
  my $pk = join(PK_SEP, grep { defined } map { $self->$_() } $meta->primary_key_column_accessor_names);

  no strict 'refs';

  my $ttl_secs = $class->meta->cached_objects_expire_in || 0;
  my $loaded = $ttl_secs ? time : 0;

  ${"${class}::Objects_By_Id"}{$pk} = $self;

  if($ttl_secs)
  {
    ${"${class}::Objects_By_Id_Loaded"}{$pk} = $loaded;
  }

  my $accessor = $meta->column_accessor_method_names_hash;

  foreach my $cols ($self->meta->unique_keys_column_names)
  {
    no warnings;
    my $key_name  = join(UK_SEP, @$cols);
    my $key_value = join(UK_SEP, grep { defined($_) ? $_ : UNDEF } 
                         map { my $m = $accessor->{$_}; $self->$m() } @$cols);

    ${"${class}::Objects_By_Key"}{$key_name}{$key_value} = $self;
    ${"${class}::Objects_Keys"}{$pk}{$key_name} = $key_value;

    if($ttl_secs)
    {
      ${"${class}::Objects_By_Key_Loaded"}{$key_name}{$key_value} = $loaded;
    }
  }
};

# This constant is not arbitrary.  It must be defined and false.
# I'm playing games with return values, but this is all internal
# anyway and can change at any time.
use constant CACHE_EXPIRED => 0;

sub __xrdbopriv_get_object
{
  my($class) = ref $_[0] || $_[0];

  my $ttl_secs = $class->meta->cached_objects_expire_in;

  if(@_ == 2)
  {
    my($pk) = $_[1];

    no strict 'refs';
    no warnings;

    if(${"${class}::Objects_By_Id"}{$pk})
    {
      if($ttl_secs && (time - ${"${class}::Objects_By_Id_Loaded"}{$pk}) >= $ttl_secs)
      {
        delete ${"${class}::Objects_By_Id"}{$pk};
        return CACHE_EXPIRED;
      }

      return ${"${class}::Objects_By_Id"}{$pk};
    }

    return undef;
  }
  else
  {
    my($key_name, $key_value) = ($_[1], $_[2]);

    no strict 'refs';
    no warnings;

    if(${"${class}::Objects_By_Key"}{$key_name}{$key_value})
    {
      if($ttl_secs && (time - ${"${class}::Objects_By_Key_Loaded"}{$key_name}{$key_value}) >= $ttl_secs)
      {
        delete ${"${class}::Objects_By_Key_Loaded"}{$key_name}{$key_value};
        return undef; # cache expired
      }

      ${"${class}::Objects_By_Key"}{$key_name}{$key_value}->remember();
      return ${"${class}::Objects_By_Key"}{$key_name}{$key_value};
    }

    return undef;
  }
};

sub load
{
  # XXX: Must maintain alias to actual "self" object arg

  my %args = (self => @_); # faster than @_[1 .. $#_];

  unless(delete $args{'refresh'})
  {
    my $pk = join(PK_SEP, grep { defined } map { $_[0]->$_() } $_[0]->meta->primary_key_column_accessor_names);

    my $object = __xrdbopriv_get_object($_[0], $pk);

    if($object)
    {
      $_[0] = $object;
      $_[0]->{STATE_IN_DB()} = 1;
      return $_[0] || 1;
    }
    elsif(!(defined $object && $object == CACHE_EXPIRED))
    {
      my $meta = $_[0]->meta;
      my $accessor = $meta->column_accessor_method_names_hash;

      foreach my $cols ($meta->unique_keys_column_names)
      {
        no warnings;
        my $key_name  = join(UK_SEP, @$cols);
        my $key_value = join(UK_SEP, grep { defined($_) ? $_ : UNDEF } 
                             map { my $m = $accessor->{$_}; $_[0]->$m() } @$cols);

        if(my $object = __xrdbopriv_get_object($_[0], $key_name, $key_value))
        {
          $_[0] = $object;
          $_[0]->{STATE_IN_DB()} = 1;
          return $_[0] || 1;
        }
      }
    }
  }

  my $ret = $_[0]->SUPER::load(%args);
  $_[0]->remember  if($ret);

  return $ret;
}

sub insert
{
  my($self) = shift;

  my $ret = $self->SUPER::insert(@_);
  return $ret  unless($ret);

  $self->remember;

  return $ret;
}

sub update
{
  my($self) = shift;

  my $ret = $self->SUPER::update(@_);
  return $ret  unless($ret);

  $self->remember;

  return $ret;
}

sub delete
{
  my($self) = shift;
  my $ret = $self->SUPER::delete(@_);
  $self->forget  if($ret);
  return $ret;
}

sub forget
{
  my($self) = shift;

  my $class = ref $self;
  my $pk = join(PK_SEP, grep { defined } map { $self->$_() } $self->meta->primary_key_column_accessor_names);

  no strict 'refs';
  delete ${"${class}::Objects_By_Id"}{$pk};

  foreach my $cols ($self->meta->unique_keys_column_names)
  {
    no warnings;
    my $key_name  = join(UK_SEP, @$cols);
    my $key_value = ${"${class}::Objects_Keys"}{$pk}{$key_name};
    delete ${"${class}::Objects_By_Key"}{$key_name}{$key_value};
  }

  delete ${"${class}::Objects_Keys"}{$pk};

  return 1;
}

sub remember_by_primary_key
{
  my($self) = shift;

  my $class = ref $self;
  my $pk = join(PK_SEP, grep { defined } map { $self->$_() } $self->meta->primary_key_column_accessor_names);

  no strict 'refs';
  ${"${class}::Objects_By_Id"}{$pk} = $self;
}

sub remember_all
{
  my($class) = shift;

  require Rose::DB::Object::Manager;

  my(undef, %args) = Rose::DB::Object::Manager->normalize_get_objects_args(@_);

  my $objects = 
    Rose::DB::Object::Manager->get_objects(
      object_class => $class,
      share_db     => 0,
      %args);

  foreach my $object (@$objects)
  {
    $object->remember;
  }

  return @$objects  if(defined wantarray);
}

# Code borrowed from Cache::Cache
my %Expiration_Units =
(
  map(($_,            1), qw(s sec secs second seconds)),
  map(($_,           60), qw(m min mins minute minutes)),
  map(($_,        60*60), qw(h hr hrs hour hours)),
  map(($_,     60*60*24), qw(d day days)),
  map(($_,   60*60*24*7), qw(w wk wks week weeks)),
  map(($_, 60*60*24*365), qw(y yr yrs year years))
);

sub clear_object_cache
{
  my($class) = ref($_[0]) || $_[0];

  no strict 'refs';
  %{"${class}::Objects_By_Id"}  = ();
  %{"${class}::Objects_By_Key"} = ();
  %{"${class}::Objects_Keys"}   = ();

  if($class->cached_objects_expire_in)
  {
    %{"${class}::Objects_By_Key_Loaded"} = ();
    %{"${class}::Objects_By_Id_Loaded"}  = ();
  }

  return 1;
}

sub cached_objects_expire_in
{
  my($class) = shift;

  $class = ref($class)  if(ref($class));

  no strict 'refs';
  return ${"${class}::Cache_Expires"} ||= 0  unless(@_);

  my $arg = shift;

  my $secs;

  if($arg =~ /^now$/i)
  {
    $class->forget_all;
    $secs = 0;
  }
  elsif($arg =~ /^never$/)
  {
    $secs = 0;
  }
  elsif($arg =~ /^\s*([+-]?(?:\d+|\d*\.\d*))\s*$/)
  {
    $secs = $arg;
  }
  elsif($arg =~ /^\s*([+-]?(?:\d+(?:\.\d*)?|\d*\.\d+))\s*(\w*)\s*$/ && exists $Expiration_Units{$2})
  {
    $secs = $Expiration_Units{$2} * $1;
  }
  else
  {
    Carp::croak("Invalid cache expiration time: '$arg'");
  }

  return ${"${class}::Cache_Expires"} = $secs;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Cached - Memory cached object representation of a single row in a database table.

=head1 SYNOPSIS

  package Category;

  use base 'Rose::DB::Object::Cached';

  __PACKAGE__->meta->setup
  (
    table => 'categories',

    columns =>
    [
      id          => { type => 'int', primary_key => 1 },
      name        => { type => 'varchar', length => 255 },
      description => { type => 'text' },
    ],

    unique_key => 'name',
  );

  ...

  $cat1 = Category->new(id   => 123,
                        name => 'Art');

  $cat1->save or die $category->error;


  $cat2 = Category->new(id => 123);

  # This will load from the memory cache, not the database
  $cat2->load or die $cat2->error; 

  # $cat2 is the same object as $cat1
  print "Yep, cached"  if($cat1 eq $cat2);

  # No, really, it's the same object
  $cat1->name('Blah');
  print $cat2->name; # prints "Blah"

  # The object cache supports time-based expiration
  Category->cached_objects_expire_in('15 minutes');

  $cat1 = Category->new(id => 123);
  $cat1->save or $cat1->die;

  $cat1->load; # loaded from cache

  $cat2 = Category->new(id => 123);
  $cat2->load; # loaded from cache

  <15 minutes pass>

  $cat3 = Category->new(id => 123);
  $cat3->load; # NOT loaded from cache

  ...

=head1 DESCRIPTION

C<Rose::DB::Object::Cached> is a subclass of L<Rose::DB::Object> that is backed by a write-through memory cache.  Whenever an object is loaded from or saved to the database, it is cached in memory.  Any subsequent attempt to load an object of the same class with the same primary key or unique key value(s) will give you the cached object instead of loading from the database.

This means that I<modifications to an object will also modify all other objects in memory that have the same primary key.>  The L<synopsis|/SYNOPSIS> above highlights this fact.

This class is most useful for encapsulating "read-only" rows, or other data that is updated very infrequently.  In the C<Category> example above, it would be inefficient to repeatedly load category information in a long-running process (such as a mod_perl Apache web server) if that information changes infrequently.

The memory cache can be cleared for an individual object or all objects of the same class.  There is also support for simple time-based cache expiration.  See the L<clear_object_cache|/clear_object_cache> and L<cached_objects_expire_in|/cached_objects_expire_in> methods for more information.

Only the methods that are overridden or otherwise behaviorally modified are documented here.  See the L<Rose::DB::Object> documentation for the rest.

=head1 CLASS METHODS

=over 4

=item B<cached_objects_expire_in [DURATION]>

This method controls the expiration of cached objects.

If called with no arguments, the cache expiration limit in seconds is returned.  If passed a DURATION, the cache expiration is set.  Valid formats for DURATION are in the form "NUMBER UNIT" where NUMBER is a positive number and UNIT is one of the following:

    s sec secs second seconds
    m min mins minute minutes
    h hr hrs hour hours
    d day days
    w wk wks week weeks
    y yr yrs year years

All formats of the DURATION argument are converted to seconds.  Days are exactly 24 hours, weeks are 7 days, and years are 365 days.

If an object was read from the database the specified number of seconds ago or earlier, it is purged from the cache and reloaded from the database the next time it is loaded.

A L<cached_objects_expire_in|/cached_objects_expire_in> value of undef or zero means that nothing will ever expire from the object cache.  This is the default.

=item B<clear_object_cache>

Clear the memory cache for all objects of this class.

=back

=head1 OBJECT METHODS

=over 4

=item B<delete [PARAMS]>

This method works like the L<delete|Rose::DB::Object/delete> method from L<Rose::DB::Object> except that it also calls the L<forget|/forget> method if the object was deleted successfully or did not exist in the first place.

=item B<forget>

Delete the current object from the memory cache.

=item B<load [PARAMS]>

Load an object based on either a primary key or a unique key.

If the object exists in the memory cache, the current object "becomes" the cached object.  See the L<synopsis|/SYNOPSIS> or L<description|/DESCRIPTION> above for more information.

If the object is not in the memory cache, it is loaded from the database.  If the load succeeds, it is also written to the memory cache.

PARAMS are name/value pairs, and are optional.  Valid parameters are:

=over 4

=item B<refresh>

If set to a true value, then the data is always loaded from the database rather than from the memory cache.  If the load succeeds, the object replaces whatever was in the cache.  If it fails, the cache is not modified.

=back

Returns true if the object was loaded successfully, false if the row could not be loaded or did not exist in the database.  The true value returned on success will be the object itself.  If the object L<overload>s its boolean value such that it is not true, then a true value will be returned instead of the object itself.

=item B<insert [PARAMS]>

This method does the same thing as the L<Rose::DB::Object> L<method of the same name|Rose::DB::Object/insert>, except that it also saves the object to the memory cache if the insert succeeds.  If it fails, the memory cache is not modified.

=item B<remember>

Save the current object to the memory cache I<without> saving it to the database as well.  Objects are cached based on their primary key values and all their unique key values.

=item B<remember_all [PARAMS]>

Load and L<remember|/remember> all objects from this table, optionally filtered by PARAMS which can be any valid L<Rose::DB::Object::Manager-E<gt>get_objects()|Rose::DB::Object::Manager/get_objects> parameters.  Remembered objects will replace any previously cached objects with the same keys.

=item B<remember_by_primary_key [PARAMS]>

Save the current object to the memory cache I<without> saving it to the database as well.  The object will be cached based on its primary key value I<only>.  This is unlike the L<remeber|/remember> method which caches objects based on their primary key values and all their unique key values.

=item B<save [PARAMS]>

This method does the same thing as the L<Rose::DB::Object> L<method of the same name|Rose::DB::Object/save>, except that it also saves the object to the memory cache if the save succeeds.  If it fails, the memory cache is not modified.

=item B<update [PARAMS]>

This method does the same thing as the L<Rose::DB::Object> L<method of the same name|Rose::DB::Object/update>, except that it also saves the object to the memory cache if the update succeeds.  If it fails, the memory cache is not modified.

=back

=head1 RESERVED METHODS

In addition to the reserved methods listed in the L<Rose::DB::Object> documentation, the following method names are also reserved for objects that inherit from this class:

    cached_objects_expire_in
    clear_object_cache
    forget
    remember
    remember_all
    remember_by_primary_key

If you have a column with one of these names, you must alias it.  See the L<Rose::DB::Object> documentation for more information on column aliasing and reserved methods.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
