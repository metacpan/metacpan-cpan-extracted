package Rose::DBx::Object::Cached::CHI;

use strict;

use Carp();

use CHI;
use Storable;
use Rose::DB::Object;
use Rose::DB::Object::Helpers ();
use Rose::DB::Object::Cached;

use Data::Dumper;

our @ISA = qw(Rose::DB::Object);

use Rose::DB::Object::Constants qw(STATE_IN_DB MODIFIED_COLUMNS);

our $VERSION = '0.22';
our $SETTINGS = undef;
our $Debug = 0;
our $USE_IN_SYNC = 0;

# Use same expiration units from Rose::DB::Object::Cached;
my %Expiration_Units = %Rose::DB::Object::Cached::Expiration_Units;


# Anything that cannot be in a column name will work for these
# Changed to '&' for compatibility with Memcached
use constant PK_SEP => "&";
use constant UK_SEP => "&";
use constant LEVEL_SEP => "&";

# Try to pick a very unlikely value to stand in for undef in
# the stringified multi-column unique key value
use constant UNDEF  => "\1\2undef\2\1";


sub remember
{
  my($self) = shift;
  my $class = ref $self;
  my $meta = $self->meta;

  local $Storable::Deparse = 1;

  my $cache = $class->__xrdbopriv_get_cache_handle;

  my $pk = join(PK_SEP, grep { defined } map { $self->$_() } $meta->primary_key_column_accessor_names);

  my $safe_obj = $self->__xrdbopriv_clone->__xrdbopriv_strip;  ## Strip has been fixed so that all CODE REFs are gone
                                                               ## but keeping the clone here so we don't mess with the
                                                               ## object the developer is currently working with

  my %orig_modified = $self->{MODIFIED_COLUMNS()} ? %{$self->{MODIFIED_COLUMNS()}} : ();
  $safe_obj->{MODIFIED_COLUMNS()} = \%orig_modified;

  my $expire_in = ($self->meta->cached_objects_expire_in || $class->cached_objects_settings->{expires_in} || 'never');

  my $pk_cache_key = "${class}::Objects_By_Id" . LEVEL_SEP . $pk;
  my $successful_pk_set = $cache->set($pk_cache_key, $safe_obj,$expire_in);
  $cache->remove($pk_cache_key) unless $successful_pk_set;

  my $accessor = $meta->column_accessor_method_names_hash;

  foreach my $cols ($self->meta->unique_keys_column_names)
  {
    my $values_defined = 0;

    my $key_name  = join(UK_SEP, @$cols);
    my $key_value = join(UK_SEP, grep { defined($_) ? $_ : UNDEF }
                         map { my $m = $accessor->{$_}; my $colval = $safe_obj->$m();$values_defined++ if defined($colval);$colval } @$cols);

    next unless ($values_defined == @$cols);

    my $ObKey_cache_key = "${class}::Objects_By_Key" . LEVEL_SEP . $key_name . LEVEL_SEP . $key_value;
    my $ObKeys_cache_key = "${class}::Objects_Keys" . LEVEL_SEP . $pk . LEVEL_SEP . $key_name;

    my $successful_set = $cache->set($ObKey_cache_key, $safe_obj, $expire_in);
    $cache->remove($ObKey_cache_key) unless $successful_set;

    $successful_set = $cache->set("${class}::Objects_Keys" . LEVEL_SEP . $pk . LEVEL_SEP . $key_name, $key_value, $expire_in);
    $cache->remove($ObKeys_cache_key) unless $successful_set;

  }

  if ($Rose::DBx::Object::Cached::CHI::USE_IN_SYNC && $successful_pk_set ) {
    my $chi_cache_object = $self->{__xrdbopriv_chi_created_at} = $cache->get_object("${class}::Objects_By_Id" . LEVEL_SEP . $pk);
    $self->{__xrdbopriv_chi_created_at} = $chi_cache_object->created_at();
  }

};


sub __xrdbopriv_get_object
{
  my($class) = ref $_[0] || $_[0];

  local $Storable::Eval = 1;

  my $cache = $class->__xrdbopriv_get_cache_handle;

  if(@_ == 2)
  {
    my($pk) = $_[1];

    my $cache_object = $cache->get_object("${class}::Objects_By_Id" . LEVEL_SEP . $pk);


    if($cache_object && !$cache_object->is_expired)
    {
      my $rose_object = $cache_object->value;
      $rose_object->{__xrdbopriv_chi_created_at} = $cache_object->created_at;
      return $rose_object;
    }

    return undef;
  }
  else
  {
    my($key_name, $key_value) = ($_[1], $_[2]);

    my $cache_object = $cache->get_object("${class}::Objects_By_Key" . LEVEL_SEP . $key_name . LEVEL_SEP . $key_value);
    if($cache_object && !$cache_object->is_expired)
    {
      my $rose_object = $cache_object->value;
      $rose_object->{__xrdbopriv_chi_created_at} = $cache_object->created_at;
      return $rose_object;
    }

    return undef;
  }
};


sub load
{
  # XXX: Must maintain alias to actual "self" object arg

  my %args = (self => @_); # faster than @_[1 .. $#_];

  my $class = ref $_[0];

  unless(delete $args{'refresh'})
  {
    my $pk = join(PK_SEP, grep { defined } map { $_[0]->$_() } $_[0]->meta->primary_key_column_accessor_names);

    my $object = $pk ? __xrdbopriv_get_object($class, $pk) : undef;

    if($object)
    {
      $_[0] = $object;
      $_[0]->{STATE_IN_DB()} = 1;
      return $_[0] || 1;
    }
    elsif(!(defined $object))
    {
      my $meta = $_[0]->meta;
      my $accessor = $meta->column_accessor_method_names_hash;

      foreach my $cols ($_[0]->meta->unique_keys_column_names)
      {
        my $values_defined = 0;

        no warnings;
        my $key_name  = join(UK_SEP, @$cols);
        my $key_value = join(UK_SEP, grep { defined($_) ? $_ : UNDEF }
                             map { my $m = $accessor->{$_}; my $colval = $_[0]->$m();$values_defined++ if defined($colval);$colval } @$cols);


        next unless $values_defined;

        if(my $object = __xrdbopriv_get_object($class, $key_name, $key_value))
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


sub update {
    my($self) = shift;

    my $ret = $self->SUPER::update(@_);
    return $ret  unless($ret);

    $self->remember;

    return $ret;
}

sub insert {
    my($self) = shift;

    my $ret = $self->SUPER::insert(@_);
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

  my $cache = $class->__xrdbopriv_get_cache_handle;

  my $pk = join(PK_SEP, grep { defined } map { $self->$_() } $self->meta->primary_key_column_accessor_names);

  $cache->expire("${class}::Objects_By_Id" . LEVEL_SEP . $pk);

  foreach my $cols ($self->meta->unique_keys_column_names)
  {
    my $key_name  = join(UK_SEP, @$cols);
    my $key_value = $cache->get("${class}::Objects_Keys" . LEVEL_SEP . $pk . LEVEL_SEP . $key_name) || '';
    $cache->expire("${class}::Objects_By_Key" . LEVEL_SEP . $key_name . LEVEL_SEP . $key_value);
  }

  $cache->expire("${class}::Objects_Keys" . LEVEL_SEP . $pk);

  return 1;
}


sub remember_by_primary_key
{
  my($self) = shift;
  my $class = ref $self;

  my $cache = $class->__xrdbopriv_get_cache_handle;

  my $pk = join(PK_SEP, grep { defined } map { $self->$_() } $self->meta->primary_key_column_accessor_names);

  $cache->set("${class}::Objects_By_Id" . LEVEL_SEP . $pk, $self->__xrdbopriv_clone->__xrdbopriv_strip);
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


sub clear_object_cache
{
  my($class) = shift;

  my $cache = $class->__xrdbopriv_get_cache_handle;

  $cache->clear;
}


sub cached_objects_expire_in {
    my $class = shift;
    Rose::DB::Object::Cached::cached_objects_expire_in($class,@_);
}


sub cached_objects_settings {
    my ($class, %params) = @_;;

    no strict 'refs';

    if (keys %params) {

        ${"${class}::CHI_SETTINGS"} = \%params;

    } else {
        if (! defined ${"${class}::CHI_SETTINGS"}) {
            if (defined $SETTINGS) {
                ${"${class}::CHI_SETTINGS"} = $SETTINGS;
            } else {
                ${"${class}::CHI_SETTINGS"} = $class->default_cached_objects_settings;
            }
        }
        return ${"${class}::CHI_SETTINGS"};
    }

}


sub is_cache_in_sync {
    my $self = shift;

    if ($Rose::DBx::Object::Cached::CHI::USE_IN_SYNC) {
        return unless $self->{__xrdbopriv_chi_created_at};
        my $class = ref $self;
        my $cache = $class->__xrdbopriv_get_cache_handle;
        my $pk = join(PK_SEP, grep { defined } map { $self->$_() } $self->meta->primary_key_column_names);
        my $created_at = $cache->get_object("${class}::Objects_By_Id" . LEVEL_SEP . $pk)->created_at;

        if ($created_at) {
            return ($self->{__xrdbopriv_chi_created_at} == $created_at);
        } else {
            if ($_[0]->{STATE_IN_DB()}) {
              # Has been loaded
            } else {
              Carp::cluck "Object never loaded";
            }
            return 0;
        }
    } else {
        warn 'is_cache_in_sync not activated.  Set $Rose::DBx::Object::Cached::CHI::USE_IN_SYNC to a true value';
        return undef;
    }

}


sub default_cached_objects_settings {
    my $class = shift;

    return {
        driver => 'Memory',
        namespace => $class,
        global => 1
    };
}


sub __xrdbopriv_get_cache_handle {
    my $class = shift;

    no strict 'refs';

    if (defined ${"${class}::CHI_CACHE_HANDLE"}) {
        return ${"${class}::CHI_CACHE_HANDLE"};
    } else {
        my $defaults = $class->default_cached_objects_settings();

        my $current_settings = $class->cached_objects_settings;

        my %chi_settings = (
            %$defaults,
            (%$SETTINGS || ()),
            %$current_settings
       );

        my $cache = new CHI(%chi_settings);

        ${"${class}::CHI_CACHE_HANDLE"} = $cache;
        return $cache;
    }
}


sub __xrdbopriv_strip {
    my $self = shift;

    Rose::DB::Object::Helpers::strip($self,@_);

    delete $self->{__xrdbopriv_chi_created_at};

    return $self;
}

sub __xrdbopriv_clone {
    my $self = shift;

    Rose::DB::Object::Helpers::clone($self,@_);
}

1;

__END__


=head1 NAME

Rose::DBx::Object::Cached::CHI - Rose::DB::Object Cache using the CHI interface

=head1 SYNOPSIS

  package Category;

  use Rose::DBx::Object::Cached::CHI;
  our @ISA = qw(Rose::DBx::Object::Cached::CHI);

  __PACKAGE__->meta->table('categories');

  __PACKAGE__->meta->columns
  (
    id          => { type => 'int', primary_key => 1 },
    name        => { type => 'varchar', length => 255 },
    description => { type => 'text' },
  );

  __PACKAGE__->meta->add_unique_key('name');

  __PACKAGE__->meta->initialize;

  ...

  ## Defaults to an in memory cache that does not expire.

  $cat1 = Category->new(id   => 123,
                        name => 'Art');

  $cat1->save or die $category->error;


  $cat2 = Category->new(id => 123);

  # This will load from the memory cache, not the database
  $cat2->load or die $cat2->error;

  ...

  ## Set the cache driver for all Rose::DB::Object derived objects
  $Rose::DBx::Object::Cached::CHI::SETTINGS = {
    driver     => 'FastMmap',
    root_dir   => '/tmp/global_fastmmap',
  };

  $cat1 = Category->new(id   => 123,
                        name => 'Art')->save;

  ## In another script

  $Rose::DBx::Object::Cached::CHI::SETTINGS = {
    driver     => 'FastMmap',
    root_dir   => '/tmp/global_fastmmap',
  };

  # This will load from the FastMmap cache, not the database
  $cat2 = Category->new(id   => 123,
                        name => 'Art')->load;

  ...

  ## Set the cache driver for all Category derived objects
  Category->cached_objects_settings(
    driver     => 'FastMmap',
    root_dir   => '/tmp/global_fastmmap',
  );

  ...


  ## Set cache expire time for all Category objects
  Category->cached_objects_expire_in('5 seconds');

  ## Set cache expire time for all Rose::DB::Object derived objects
  $Rose::DBx::Object::Cached::CHI::SETTINGS = {
    driver     => 'Memory',
    expires_in    => '15 minutes',
  };

  <OR>

  $Rose::DBx::Object::Cached::CHI::SETTINGS = {
    driver     => 'FastMmap',
    root_dir   => '/tmp/global_fastmmap',
    expires_in    => '15 minutes',
  };

  ## Any driver for CHI will work.



=head1 DESCRIPTION

This module intends to extend the caching ability in Rose::DB::Object
allowing objects to be cached by any driver that can be used with
the CHI interface. This opens the possibility to cache objects across
scripts or even servers by opening up methods of caching such as
FastMmap and memcached.

Most of the code is taken straight from L<Rose::DB::Object::Cached>.
This does not extend Rose::DB::Object::Cached because function calls and
how the cache is accessed needed to be changed thoughout the code.

=head1 MAJOR DIFFERENCE from L<Rose::DB::Object::Cached>

All objects derived from a L<Rose::DBx::Object::Cached> class are
set and retrieved from CHI, therefore 2 objects that are
loaded with the same parameters are not the same code reference.

=over 4

=item B<In L<Rose::DB::Object::Cached>>

=over 4

  $cat1 = Category->new(id   => 123,
                          name => 'Art');

  $cat1->save;

  $cat2-> Category->new(id   => 123,
                          name => 'Art');

  $cat2->load;

  print $cat1->name; # prints "Art"

  print $cat2->name; # prints "Art"

  $cat1->name('Blah');

  print $cat2->name; # prints "Blah"

=back

=item  B<In L<Rose::DBx::Object::Cached>>

=over 4

  $cat1 = Category->new(id   => 123,
                          name => 'Art');

  $cat1->save;

  $cat2-> Category->new(id   => 123,
                          name => 'Art');

  $cat2->load;

  print $cat1->name; # prints "Art"
  print $cat2->name; # prints "Art"

  $cat1->name('Blah');
  print $cat2->name; # prints "Art"

=back


=back

=head1 GLOBALS

=over 4

=item B<$SETTINGS>

This global is used to set CHI settings for all objects derived from L<Rose::DBx::Object::Cached::CHI>.  Any settings here will override any default settings, but will conceded to settings configured by the class method L<cached_objects_settings|/cached_objects_settings>

=over 4

Example:

$Rose::DBx::Object::Cached::CHI::SETTINGS = {
    driver     => 'FastMmap',
    root_dir   => '/tmp/global_fastmmap',
};


=back


=back



=head1 CLASS METHODS

Only class methods that do not exist in L<Rose::DB::Object::Cached> are listed here.

=over 4

=item B<cached_objects_settings [PARAMS]>

If called with no arguments this will return the current cache settings.  PARAMS are any valid options for the L<CHI> constructor.

    Example:

    Category->cached_objects_settings (
        driver     => 'FastMmap',
        root_dir   => '/tmp/global_fastmmap',
        expires_in    => '15 minutes',
    )


=back

=item B<default_cached_objects_settings [PARAMS]>

Returns the default CHI settings for the class.  This method should be implemented by a sub class if custom settings are required.

=over 4

    package Category;
    use base Rose::DBx::Object::Cached::CHI;

    ...

    sub default_cached_objects_settings (
        return {
            driver     => 'FastMmap',
            root_dir   => '/tmp/global_fastmmap',
            expires_in    => '15 minutes',
        };
    )

=back

If this method is not implemented in a sub class it will return the following:

=over 4

    { driver => 'Memory', global => 1 }

=back



=back



=head1 OBJECT METHODS

Only object methods that do not exist in L<Rose::DB::Object::Cached> are listed here.

=over 4

=item B<is_cache_in_sync>

Because the cache is only updated when loading and saving this method will return weather the cache has been updated since the object was last loaded.

Returns true if the object is in sync with what exists in the cache.  Returns false if the cache has been updated since the object was loaded.

IMPORTANT: Starting in version 0.16 this is now an optional function that must be turned on by setting $Rose::DBx::Object::Cached::CHI::USE_IN_SYNC to a true value.
The cost of making a call to get the CHI object hurt the overall speed of the module.

=back

=head1 PRIVATE METHODS

=over 4

=item B<__xrdbopriv_clone>

Calls the L<clone|Rose::DB::Object::Helpers/clone> method in L<Rose::DB::Object::Helpers>

=item B<__xrdbopriv_strip>

Calls the L<strip|Rose::DB::Object::Helpers/strip> method in L<Rose::DB::Object::Helpers>


=back


=head1 TODO

=over 4

=item B<Tests>

Currently tests only exist for MySQL.  Almost all of these have been copied directly from the tests that exist for L<Rose::DB::Object>.

=back



=head1 AUTHOR

    Kevin C. McGrath
    CPAN ID: KMCGRATH

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################
