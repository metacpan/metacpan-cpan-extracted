package Rose::DB::Cache;

use strict;

use base 'Rose::Object';

use Scalar::Util qw(refaddr);
use Rose::DB::Cache::Entry;

our $VERSION = '0.755';

our $Debug = 0;

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar =>
  [
    'entry_class',
    '_default_use_cache_during_apache_startup',
  ],
);

__PACKAGE__->entry_class('Rose::DB::Cache::Entry');
__PACKAGE__->default_use_cache_during_apache_startup(0);

our($MP2_Is_Child, $Apache_Has_Started);

sub default_use_cache_during_apache_startup
{
  my($class) = shift;
  return $class->_default_use_cache_during_apache_startup($_[0] ? 1 : 0)  if(@_);
  return  $class->_default_use_cache_during_apache_startup;
}

sub use_cache_during_apache_startup
{
  my($self) = shift;

  return $self->{'use_cache_during_apache_startup'} = $_[0] ? 1 : 0  if(@_);

  if(defined $self->{'use_cache_during_apache_startup'})
  {
    return $self->{'use_cache_during_apache_startup'};
  }
  else
  {
    return $self->{'use_cache_during_apache_startup'} = 
      ref($self)->default_use_cache_during_apache_startup;
  }
}

sub prepare_for_apache_fork
{
  my($self) = shift;

  foreach my $entry ($self->db_cache_entries)
  {
    if($entry->created_during_apache_startup)
    {
      my $db = $entry->db;
      $Debug && warn "$$ Disconnecting and undef-ing ", $db->dbh, " contained in $db";
      $db->dbh->disconnect;
      $db->dbh(undef);
      $db = undef;
      $Debug && warn "$$ Deleting cache entry for $db";
      delete $self->{'cache'}{$entry->key};
    }
  }
}

sub build_cache_key
{
  my($class, %args) = @_;
  return join("\0", $args{'domain'}, $args{'type'});
}

QUIET:
{
  no warnings 'uninitialized';
  use constant MOD_PERL_1     => ($ENV{'MOD_PERL'} && !$ENV{'MOD_PERL_API_VERSION'})     ? 1 : 0;
  use constant MOD_PERL_2     => ($ENV{'MOD_PERL'} && $ENV{'MOD_PERL_API_VERSION'} == 2) ? 1 : 0;
  use constant APACHE_DBI     => ($INC{'Apache/DBI.pm'} || $Apache::DBI::VERSION)        ? 1 : 0;
  use constant APACHE_DBI_MP2 => (APACHE_DBI && MOD_PERL_2) ? 1 : 0;
  use constant APACHE_DBI_MP1 => (APACHE_DBI && MOD_PERL_1) ? 1 : 0;
}

sub db_cache_entries
{
  my($self) = shift;
  return wantarray ? values %{$self->{'cache'} || {}} : 
                     [ values %{$self->{'cache'} || {}} ];
}

sub db_cache_keys
{
  my($self) = shift;
  return wantarray ? keys %{$self->{'cache'} || {}} : 
                     [ keys %{$self->{'cache'} || {}} ];
}

sub get_db
{
  my($self) = shift;

  my $key = $self->build_cache_key(@_);

  if(my $entry = $self->{'cache'}{$key})
  {
    if(my $db = $entry->db)
    {
      $self->prepare_db($db, $entry);
      return $db;
    }
  }

  return undef;
}

sub set_db
{
  my($self, $db) = @_;

  my $key = 
    $self->build_cache_key(domain => $db->domain, 
                           type   => $db->type,
                           db     => $db);

  my $entry = ref($self)->entry_class->new(db => $db, key => $key);

  # Don't cache anything during apache startup if use_cache_during_apache_startup
  # is false.  Weird conditional structure is meant to encourage code elimination
  # thanks to the lone constants in the if/elsif conditions.
  if(MOD_PERL_1)
  {
    if($Apache::Server::Starting)
    {
      if($self->use_cache_during_apache_startup)
      {
        $entry->created_during_apache_startup(1);
        $entry->prepared(0);
      }
      else
      {
        $Debug && warn "Refusing to cache $db during apache server start-up ",
                       "because use_cache_during_apache_startup is false";

        return $db;
      }
    }
  }

  if(MOD_PERL_2)
  {
    if(!$MP2_Is_Child)
    {
      if($self->use_cache_during_apache_startup)
      {
        $entry->created_during_apache_startup(1);
        $entry->prepared(0);
      }
      else
      {
        $Debug && warn "Refusing to cache $db in pre-fork apache process ",
                       "because use_cache_during_apache_startup is false";
        return $db;
      }
    }
  }

  $self->{'cache'}{$key} = $entry;

  return $db;
}

sub clear { shift->{'cache'} = {} }

if(MOD_PERL_2)
{
  require Apache2::ServerUtil;
  require Apache2::RequestUtil;
  require Apache2::Const;
  Apache2::Const->import(-compile => qw(OK));

  $MP2_Is_Child = 0;

  if(__PACKAGE__->apache_has_started)
  {
    $Debug && warn "$$ is already MP2 child (not registering child init handler)\n";
    $MP2_Is_Child = 1;
  }
  elsif(!$ENV{'ROSE_DB_NO_CHILD_INIT_HANDLER'})
  {
    Apache2::ServerUtil->server->push_handlers(
      PerlChildInitHandler => \&__mod_perl_2_rose_db_child_init_handler);
  }
}

# http://mail-archives.apache.org/mod_mbox/perl-dev/200504.mbox/%3C4256B5FF.5060401@stason.org%3E
# To work around this issue, we'll use a named subroutine.
sub __mod_perl_2_rose_db_child_init_handler
{
  $Debug && warn "$$ is MP2 child\n";
  $MP2_Is_Child = 1;
  return Apache2::Const::OK();
}

sub apache_has_started
{
  my($class) = shift;

  if(@_)
  {
    return $Apache_Has_Started = $_[0] ? 1 : 0;
  }

  return $Apache_Has_Started  if(defined $Apache_Has_Started);

  if(MOD_PERL_2)
  {
    return $Apache_Has_Started = $MP2_Is_Child;
  }

  if(MOD_PERL_1)
  {
    return $Apache_Has_Started = $Apache::Server::Starting;
  }

  return undef;
}

sub prepare_db
{
  my($self, $db, $entry) = @_;

  if(MOD_PERL_1)
  {
    if($Apache::Server::Starting)
    {
      $entry->created_during_apache_startup(1);
      $entry->prepared(0);
    }
    elsif(!$entry->is_prepared)
    {
      if($entry->created_during_apache_startup)
      {  
        if($db->has_dbh)
        {
          $Debug && warn "$$ Disconnecting and undef-ing dbh ", $db->dbh, 
                         " created during apache startup from $db\n";

          my $error;

          TRY:
          {
            local $@;
            eval { $db->dbh->disconnect }; # will probably fail!
            $error = $@;
          }

          warn "$$ Could not disconnect dbh created during apache startup: ", 
               $db->dbh, " - $error"  if($error);

          $db->dbh(undef);
        }

        $entry->created_during_apache_startup(0);
      }

      Apache->push_handlers(PerlCleanupHandler => sub
      {
        $Debug && warn "$$ Clear dbh and prepared flag for $db, $entry\n";
        $db->dbh(undef)      if($db);
        $entry->prepared(0)  if($entry);
      });

      $entry->prepared(1);
    }
  }

  # Not a chained elsif to help Perl eliminate the unused code (maybe unnecessary?)
  if(MOD_PERL_2)
  {
    if(!$MP2_Is_Child)
    {
      $entry->created_during_apache_startup(1);
      $entry->prepared(0);
    }
    elsif(!$entry->is_prepared)
    {
      if($entry->created_during_apache_startup)
      {
        if($db->has_dbh)
        {
          $Debug && warn "$$ Disconnecting and undef-ing dbh ", $db->dbh, 
                         " created during apache startup from $db\n";

          my $error;

          TRY:
          {
            local $@;
            eval { $db->dbh->disconnect }; # will probably fail!
            $error = $@;
          }

          warn "$$ Could not disconnect dbh created during apache startup: ", 
               $db->dbh, " - $error"  if($error);

          $db->dbh(undef);
        }

        $entry->created_during_apache_startup(0);
      }

      my($r, $error);

      TRY:
      {
        local $@;
        eval { $r = Apache2::RequestUtil->request };
        $error = $@;
      }

      if($error)
      {
        $Debug && warn "Couldn't get apache request (restart count is ", 
                       Apache2::ServerUtil::restart_count(), ") - $error\n";
        $entry->created_during_apache_startup(1); # tag for cleanup
        $entry->prepared(0);

        return;
      }
      else
      {
        $r->push_handlers(PerlCleanupHandler => sub
        {
          $Debug && warn "$$ Clear dbh and prepared flag for $db, $entry\n";
          $db->dbh(undef)      if($db);
          $entry->prepared(0)  if($entry);
          return Apache2::Const::OK();
        });
      }

      $entry->prepared(1);
    }
  }
}

1;

__END__

=head1 NAME

Rose::DB::Cache - A mod_perl-aware cache for Rose::DB objects.

=head1 SYNOPSIS

  # Usage
  package My::DB;

  use base 'Rose::DB';
  ...

  $cache = My::DB->db_cache;

  $db = $cache->get_db(...);

  $cache->set_db($db);

  $cache->clear;


  # Subclassing
  package My::DB::Cache;

  use Rose::DB::Cache;
  our @ISA = qw(Rose::DB::Cache);

  # Override methods as desired
  sub get_db          { ... }
  sub set_db          { ... }
  sub prepare_db      { ... }
  sub build_cache_key { ... }
  sub clear           { ... }
  ...

=head1 DESCRIPTION

L<Rose::DB::Cache> provides both an API and a default implementation of a caching system for L<Rose::DB> objects.  Each L<Rose::DB>-derived class L<references|Rose::DB/db_cache> a L<Rose::DB::Cache>-derived object to which it delegates cache-related activities.  See the L<new_or_cached|Rose::DB/new_or_cached> method for an example.

The default implementation caches and returns L<Rose::DB> objects using the combination of their L<type|Rose::DB/type> and L<domain|Rose::DB/domain> as the cache key.  There is no cache expiration or other cache cleaning.

The only sophistication in the default implementation is that it is L<mod_perl>- and L<Apache::DBI>-aware.  When running under mod_perl, with or without L<Apache::DBI>, the L<dbh|Rose::DB/dbh> attribute of each cached L<Rose::DB> object is set to C<undef> at the end of each request.  Additionally, any db connections made in a pre-fork parent apache process are not cached.

When running under L<Apache::DBI>, the behavior described above will ensure that L<Apache::DBI>'s "ping" and rollback features work as expected, keeping the L<DBI> database handles L<contained|Rose::DB/dbh> within each L<Rose::DB> object connected and alive.

When running under mod_perl I<without> L<Apache::DBI>, the behavior described above will use a single L<DBI> database connection per cached L<Rose::DB> object per request, but will discard these connections at the end of each request.

Both mod_perl 1.x and 2.x are supported.  Under mod_perl 2.x, you should load L<Rose::DB> on server startup (e.g., in your C<startup.pl> file).  If this is not possible, then you must explicitly tell L<Rose::DB::Cache> that apache has started up already by setting L<apache_has_started|/apache_has_started> to a true value.

Subclasses can override any and all methods described below in order to implement their own caching strategy.

=head1 CLASS METHODS

=over 4

=item B<apache_has_started [BOOL]>

Get or set a boolean value indicating whether or not apache has completed its startup process.  If this value is not set explicitly, a best guess as to the answer will be returned.

=item B<build_cache_key PARAMS>

Given the name/value pairs PARAMS, return a string representing the corresponding cache key.  Calls to this method from within L<Rose::DB::Cache> will include at least C<type> and C<domain> parameters, but you may pass any parameters if you override all methods that call this method in your subclass.

=item B<default_use_cache_during_apache_startup [BOOL]>

Get or set a boolean value that determines the default value of the L<use_cache_during_apache_startup|/use_cache_during_apache_startup> object attribute.  The default value is false.  See the L<use_cache_during_apache_startup|/use_cache_during_apache_startup> documentation for more information.

=item B<entry_class [CLASS]>

Get or set the name of the L<Rose::DB::Cache::Entry>-derived class used to store cached L<Rose::DB> objects on behalf of this class.  The default value is L<Rose::DB::Cache::Entry>.

=back

=head1 CONSTRUCTORS

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::DB::Cache> object based on PARAMS, where PARAMS are
name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<clear>

Clear the cache entirely.

=item B<db_cache_entries>

Returns a list (in list context) or reference to an array (in scalar context) of L<cache entries|Rose::DB::Cache::Entry> for each cached db object.

=item B<db_cache_keys>

Returns a list (in list context) or reference to an array (in scalar context) of L<keys|Rose::DB::Cache::Entry/key> for each L <cache entries|Rose::DB::Cache::Entry>.

=item B<get_db [PARAMS]>

Return the cached L<Rose::DB>-derived object corresponding to the name/value pairs passed in PARAMS.  PARAMS are passed to the L<build_cache_key|/build_cache_key> method, and the key returned is used to look up the cached object.

If a cached object is found, the L<prepare_db|/prepare_db> method is called, passing the cached db object and its corresponding L<Rose::DB::Cache::Entry> object as arguments.  The cached db object is then returned.

If no such object exists in the cache, undef is returned.

=item B<prepare_for_apache_fork>

Prepares the cache for the initial fork of the apache parent process by L<disconnect()ing|DBI/disconnect> all database handles and deleting all cache entries that were L<created during apache startup|Rose::DB::Cache::Entry/created_during_apache_startup>.  This call is only necessary if running under L<mod_perl> I<and> L<use_cache_during_apache_startup|/use_cache_during_apache_startup> set set to true.  See the L<use_cache_during_apache_startup|/use_cache_during_apache_startup> documentation for more information.

=item B<prepare_db [DB, ENTRY]>

Prepare the cached L<Rose::DB>-derived object DB for usage.  The cached's db object's L<Rose::DB::Cache::Entry> object, ENTRY, is also passed.

When I<NOT> running under L<mod_perl>, this method does nothing.

When running under L<mod_perl> (version 1.x or 2.x), this method will do the following:

=over 4

=item * Any L<DBI> database handle created inside a L<Rose::DB> object during apache server startup will be L<marked|Rose::DB::Cache::Entry/created_during_apache_startup> as such.  Any attempt to use such an object after the apache startup process has completed (i.e., in a child apache process) will cause it to be discarded and replaced.  Note that you usually don't want it to come to this.  It's better to cleanly disconnect all such database handles before the first apache child forks off.  See the documentation for the L<use_cache_during_apache_startup|/use_cache_during_apache_startup> and L<prepare_for_apache_fork|/prepare_for_apache_fork> methods for more information.

=item * All L<DBI> database handles contained in cached L<Rose::DB> objects will be cleared at the end of each request using a C<PerlCleanupHandler>.  This will cause L<DBI-E<gt>connect|DBI/connect> to be called the next time a L<dbh|Rose::DB/dbh> is requested from a cached L<Rose::DB> object, which in turn will trigger L<Apache::DBI>'s ping mechanism to ensure that the database handle is fresh.

=back

Putting all the pieces together, the following implementation of the L<init_db|Rose::DB::Object/init_db> method in your L<Rose::DB::Object>-derived common base class will ensure that database connections are shared and fresh under L<mod_perl> and (optionally) L<Apache::DBI>, but I<unshared> elsewhere:

  package My::DB::Object;

  use base 'Rose::DB::Object';

  use My::DB; # isa Rose::DB
  ...

  BEGIN:
  {
    if($ENV{'MOD_PERL'})
    {
      *init_db = sub { My::DB->new_or_cached };
    }
    else # act "normally" when not under mod_perl
    {
      *init_db = sub { My::DB->new };
    }
  }

=item B<set_db DB>

Add the L<Rose::DB>-derived object DB to the cache.  The DB's L<domain|Rose::DB/domain>, L<type|Rose::DB/type>, and the db object itself (under the parameter name C<db>) are all are passed to the L<build_cache_key|/build_cache_key> method and the DB object is stored under the key returned.

If running under L<mod_perl> I<and> the apache server is starting up I<and> L<use_cache_during_apache_startup|/use_cache_during_apache_startup> is set to true, then the DB object is I<not> added to the cache, but merely returned.

=item B<use_cache_during_apache_startup [BOOL]>

Get or set a boolean value that determines whether or not to cache database objects during the apache server startup process.  The default value is determined by the L<default_use_cache_during_apache_startup|/default_use_cache_during_apache_startup> class method.

L<DBI> database handles created in the parent apache process cannot be used in child apache processes.  Furthermore, in the case of at least L<one|DBD::Informix> one L<DBI driver class|DBI::DBD>, you must I<also> ensure that any database handles created in the apache parent process during server startup are properly L<disconnect()ed|DBI/disconnect> I<before> you fork off the first apache child.  Failure to do so may cause segmentation faults(!) in child apache processes.

The upshot is that if L<use_cache_during_apache_startup|/use_cache_during_apache_startup> is set to true, you should call L<prepare_for_apache_fork|/prepare_for_apache_fork> at the very end of the apache startup process (i.e., once all other Perl modules have been loaded and all other Perl code has run).  This is usually done by placing a call at the bottom of the traditional C<startup.pl> file.  Assuming C<My::DB> is your L<Rose::DB|Rose::DB>-derived class:

    My::DB->db_cache->prepare_for_apache_fork();

A L<convenience method|Rose::DB/prepare_cache_for_apache_fork> exists in L<Rose::DB> as well, which simply translates into call shown above:

    My::DB->prepare_cache_for_apache_fork();

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
