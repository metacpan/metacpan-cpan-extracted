package MooseX::Storage::IO::CHI;

use strict;
use 5.008_005;
our $VERSION = '0.05';

use CHI;
use MooseX::Role::Parameterized;
use namespace::autoclean;

parameter key_attr => (
    isa      => 'Str',
    required => 1,
);

parameter key_prefix => (
    isa      => 'Str',
    default  => '',
);

parameter expires_in => (
    isa     => 'Maybe[Str]',
    default => undef,
);

parameter cache_attr => (
    isa     => 'Str',
    default => 'cache',
);

parameter cache_args => (
    isa     => 'HashRef',
    default => sub{{}},
);

parameter cache_args_method => (
    isa     => 'Str',
    default => 'cache_args',
);

parameter cache_builder_method => (
    isa     => 'Str',
    default => 'build_cache',
);

role {
    my $p = shift;

    requires 'pack';
    requires 'unpack';

    my $cache_attr           = $p->cache_attr;
    my $cache_builder_method = $p->cache_builder_method;
    my $cache_args_method    = $p->cache_args_method;

    method $cache_builder_method => sub {
        my $class = ref $_[0] || $_[0];
        my $cache_args  = $class->$cache_args_method();
        return CHI->new(%$cache_args);
    };

    method $cache_args_method => sub {
        return $p->cache_args
    };

    has $cache_attr => (
        is      => 'ro',
        isa     => 'CHI::Driver',
        lazy    => 1,
        traits  => [ 'DoNotSerialize' ],
        default => sub { shift->$cache_builder_method },
    );

    method store => sub {
        my ( $self, %args ) = @_;
        my $cache = delete $args{cache} || $self->$cache_attr;
        my $key_attr  = $p->key_attr;
        my $key_value = $self->$key_attr;
        die "Cannot have null value for key_attr $key_attr"
            unless defined $key_value;
        my $cachekey = $p->key_prefix . $key_value;
        my $data;
        if ($self->can('freeze')) {
            $data = $self->freeze;
        } else {
            $data = $self->pack;
        }

        my $set_args;
        if (defined $p->expires_in) {
            $set_args->{expires_in} = $p->expires_in;
        }
        $cache->set($cachekey, $data, $set_args);
    };

    method load => sub {
        my ( $class, $key_value, %args ) = @_;
        my $cache  = delete $args{cache}  || $class->$cache_builder_method;
        my $inject = delete $args{inject} || {};

        my $key_attr = $p->key_attr;
        $key_value // die "undefined value for key attr $key_attr";

        my $cachekey = $p->key_prefix . $key_value;

        my $data = $cache->get($cachekey);
        return undef unless $data;

        $inject->{$cache_attr} = $cache;

        my $obj;
        if ($class->can('thaw')) {
            $obj = $class->thaw($data, inject => $inject, %args);
        } else {
            $obj = $class->unpack($data, inject => $inject, %args);
        }

        return $obj;
    };
};

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::Storage::IO::CHI - Store and retrieve Moose objects to a cache, via L<CHI>.

=head1 SYNOPSIS

First, configure your Moose class via a call to Storage:

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(io => [ 'CHI' => {
      key_attr   => 'doc_id',
      key_prefix => 'mydoc-',
      cache_args => {
          driver  => 'Memcached::libmemcached',
          servers => [ "10.0.0.15:11211", "10.0.0.15:11212" ],
      },
  }]);

  has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
  has 'title'   => (is => 'rw', isa => 'Str');
  has 'body'    => (is => 'rw', isa => 'Str');
  has 'tags'    => (is => 'rw', isa => 'ArrayRef');
  has 'authors' => (is => 'rw', isa => 'HashRef');

  1;

Now you can store/load your class to the cache you defined in cache_args:

  use MyDoc;

  # Create a new instance of MyDoc
  my $doc = MyDoc->new(
      doc_id   => 'foo12',
      title    => 'Foo',
      body     => 'blah blah',
      tags     => [qw(horse yellow angry)],
      authors  => {
          jdoe => {
              name  => 'John Doe',
              email => 'jdoe@gmail.com',
              roles => [qw(author reader)],
          },
          bsmith => {
              name  => 'Bob Smith',
              email => 'bsmith@yahoo.com',
              roles => [qw(editor reader)],
          },
      },
  );

  # Save it to cache (will be stored using key "mydoc-foo12")
  $doc->store();

  # Load the saved data into a new instance
  my $doc2 = MyDoc->load('foo12');

  # This should say 'Bob Smith'
  print $doc2->authors->{bsmith}{name};

=head1 DESCRIPTION

MooseX::Storage::IO::CHI is a Moose role that provides an io layer for L<MooseX::Storage> to store/load your Moose objects to a cache, using L<CHI>.

You should understand the basics of L<Moose>, L<MooseX::Storage>, and L<CHI> before using this module.

At a bare minimum the consuming class needs to give this role a L<CHI> configuration, and a field to use as a cachekey - see L<cache_args|"cache_args"> and L<key_attr|"key_attr">.

=head1 PARAMETERS

Following are the parameters you can set when consuming this role that configure it in different ways.

=head2 key_attr

"key_attr" is a required parameter when consuming this role.  It specifies an attribute in your class that will provide the value to use as a cachekey when storing your object via L<CHI>'s set method.

=head2 key_prefix

A string that will be used to prefix the key_attr value when building the cachekey.

=head2 expires_in

Expiration duration to use when saving items to cache.

=head2 cache_args

A hashref of args that will be passed to L<CHI>'s constructor when building cache objects.

=head2 cache_attr

=head2 cache_args_method

=head2 cache_builder_method

Parameters you can use if you want to rename the various attributes and methods that are added to your class by this role.

=head1 ATTRIBUTES

Following are attributes that will be added to your consuming class.

=head2 cache

A L<CHI> object that will be used to communicate to your cache.  See L<CACHE CONFIGURATION|"CACHE CONFIGURATION"> for how to configure.

You can change this attribute's name via the cache_attr parameter.

=head1 METHODS

Following are methods that will be added to your consuming class.

=head2 $obj->store([ cache => $cache ])

Object method.  Stores the packed Moose object to your cache, via L<CHI>'s set method.  You can optionally pass in a cache object directly instead of using the object's cache attribute.

We will look at the <"expires_in"|expires_in> parameter when calling set().

=head2 $obj = $class->load($key_value, [, cache => $cache, inject => { key => val, ... } ])

Class method.  Queries your cache using L<CHI>'s get method, and returns a new Moose object built from the resulting data.  Returns undefined if there was a cache miss.

The first argument is the key value (the value for key_attr) to use, and is required.  It will be prefixed with key_prefix when querying the cache.

You can optionally pass in a cache object directly instead of having the class build one for you.

You can also pass in an inject hashref to supply additional arguments to the class' new function, or override ones from the cached data.

=head2 $cache = $class->build_cache()

See L<CACHE CONFIGURATION|"CACHE CONFIGURATION">.

You can change this method's name via the cache_builder_method parameter.

=head2 $args = $class->cache_args()

See L<CACHE CONFIGURATION|"CACHE CONFIGURATION">

You can change this method's name via the cache_args_method parameter.

=head1 CACHE CONFIGURATION

There are a handful ways to configure how this module sets up a L<CHI> object to talk to your cache:

A) Setup contructor args via the cache_args parameter.  See the L<SYNOPSIS|"SYNOPSIS"> for an example of how to do this.

B) Pass your own cache object at every call, e.g.

  my $cache = CHI->new(...);
  my $obj   = MyDoc->new(...);
  $obj->store(cache => $cache);
  my $obj2 = MyDoc->load(cache => $cache);

C) Override the cache_args method in your class to provide constructor args for CHI, e.g.

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(io => [ 'CHI' => {
      key_attr => 'doc_id',
  }]);

  sub cache_args {
      my $class = shift;
      my $servers = My::Config->memcached_servers;
      return {
          driver  => 'Memcached::libmemcached',
          servers => $servers,
      };
  }

D) Override the build_cache method in your class to directly build a CHI object, e.g.

  package MyDoc;
  ...
  sub build_cache {
      my $class = shift;
      my $cache = My::Config->get_cache_obj;
      return $cache;
  }

=head1 NOTES

=head2 Serialization

If your class provides a format serialization level - i.e. freeze and thaw methods - it will be called around calling CHI's get/set methods.  Otherwise, we will rely on CHI's serialization.

=head1 SEE ALSO

=over 4

=item L<Moose>

=item L<MooseX::Storage>

=item L<CHI>

=back

=head1 AUTHOR

Steve Caldwell E<lt>scaldwell@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Steve Caldwell E<lt>scaldwell@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to L<Campus Explorer|http://www.campusexplorer.com>, who allowed me to release this code as open source.

=cut
