use v5.10;
use strict;
use warnings;

package MooseX::Role::MongoDB;
# ABSTRACT: Provide MongoDB connections, databases and collections

our $VERSION = '0.010';

use Moose::Role 2;
use MooseX::AttributeShortcuts;

use Carp ();
use MongoDB 1;
use MongoDB::MongoClient 1;
use Socket 1.96 qw/:addrinfo SOCK_RAW/; # IPv6 capable
use String::Flogger qw/flog/;
use Type::Params qw/compile/;
use Types::Standard qw/:types/;
use namespace::autoclean;

#--------------------------------------------------------------------------#
# Dependencies
#--------------------------------------------------------------------------#

#pod =requires _logger
#pod
#pod You must provide a private method that returns a logging object.  It must
#pod implement at least the C<info> and C<debug> methods.  L<MooseX::Role::Logger>
#pod version 0.002 or later is recommended, but other logging roles may be
#pod sufficient.
#pod
#pod =cut

requires '_logger';

#--------------------------------------------------------------------------#
# Configuration attributes
#--------------------------------------------------------------------------#

has _mongo_client_class => (
    is  => 'lazy',
    isa => 'Str',
);

sub _build__mongo_client_class { return 'MongoDB::MongoClient' }

has _mongo_client_options => (
    is  => 'lazy',
    isa => HashRef, # hashlike?
);

sub _build__mongo_client_options { return {} }

has _mongo_default_database => (
    is  => 'lazy',
    isa => Str,
);

sub _build__mongo_default_database { return 'test' }

#--------------------------------------------------------------------------#
# Caching attributes
#--------------------------------------------------------------------------#

has _mongo_pid => (
    is      => 'rwp',     # private setter so we can update on fork
    isa     => 'Num',
    default => sub { $$ },
);

has _mongo_client => (
    is        => 'lazy',
    isa       => InstanceOf ['MongoDB::MongoClient'],
    clearer   => 1,
    predicate => '_has_mongo_client',
);

sub _build__mongo_client {
    my ($self) = @_;
    my $options = { %{ $self->_mongo_client_options } };
    if ( exists $options->{host} ) {
        $options->{host} = $self->_host_names_to_ip( $options->{host} );
    }
    $options->{db_name} //= $self->_mongo_default_database;
    $self->_mongo_log( debug => "connecting to MongoDB with %s", $options );
    return MongoDB::MongoClient->new($options);
}

has _mongo_database_cache => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__mongo_database_cache { return {} }

has _mongo_collection_cache => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__mongo_collection_cache { return {} }

#--------------------------------------------------------------------------#
# Role methods
#--------------------------------------------------------------------------#

#pod =method _mongo_database
#pod
#pod     $obj->_mongo_database( $database_name );
#pod
#pod Returns a L<MongoDB::Database>.  The argument is the database name.
#pod With no argument, the default database name is used.
#pod
#pod =cut

sub _mongo_database {
    state $check = compile( Object, Optional [Str] );
    my ( $self, $database ) = $check->(@_);
    $database //= $self->_mongo_default_database;
    $self->_mongo_check_connection;
    $self->_mongo_log( debug => "retrieving database $database" );
    return $self->_mongo_database_cache->{$database} //=
      $self->_mongo_client->get_database($database);
}

#pod =method _mongo_collection
#pod
#pod     $obj->_mongo_collection( $database_name, $collection_name );
#pod     $obj->_mongo_collection( $collection_name );
#pod
#pod Returns a L<MongoDB::Collection>.  With two arguments, the first argument is
#pod the database name and the second is the collection name.  With a single
#pod argument, the argument is the collection name from the default database name.
#pod
#pod =cut

sub _mongo_collection {
    state $check = compile( Object, Str, Optional [Str] );
    my ( $self, @args ) = $check->(@_);
    my ( $database, $collection ) =
      @args > 1 ? @args : ( $self->_mongo_default_database, $args[0] );
    $self->_mongo_check_connection;
    $self->_mongo_log( debug => "retrieving collection $database.$collection" );
    return $self->_mongo_collection_cache->{$database}{$collection} //=
      $self->_mongo_database($database)->get_collection($collection);
}

#pod =method _mongo_clear_caches
#pod
#pod     $obj->_mongo_clear_caches;
#pod
#pod Clears the MongoDB client, database and collection caches.  The next
#pod request for a database or collection will reconnect to the MongoDB.
#pod
#pod =cut

sub _mongo_clear_caches {
    my ($self) = @_;
    $self->_clear_mongo_collection_cache;
    $self->_clear_mongo_database_cache;
    $self->_clear_mongo_client;
    return 1;
}

#--------------------------------------------------------------------------#
# Private methods
#--------------------------------------------------------------------------#

# check if we've forked and need to reconnect
sub _mongo_check_connection {
    my ($self) = @_;

    my $mc = $self->_has_mongo_client ? $self->_mongo_client : undef;

    # v1.0.0 alpha and later reconnects after disconnects
    my $is_alpha = $mc && eval { $mc->VERSION(v0.998.0) };

    my $reset_reason;
    if ( $$ != $self->_mongo_pid ) {
        $reset_reason = "PID change";
        $self->_set__mongo_pid($$);
    }
    elsif ( !$is_alpha && $mc && !$mc->connected ) {
        $reset_reason = "Not connected";
    }

    if ($reset_reason) {
        $self->_mongo_log( debug => "clearing MongoDB caches: $reset_reason" );
        $self->_mongo_clear_caches;
    }

    return;
}

sub _mongo_log {
    my ( $self, $level, @msg ) = @_;
    $msg[0] = "$self ($$) $msg[0]";
    $self->_logger->$level( flog( [@msg] ) );
}

sub _parse_connection_uri {
    my ( $self, $uri ) = @_;
    my %parse;
    if (
        $uri =~ m{ ^
            mongodb://
            (?: ([^:]*) : ([^@]*) @ )? # [username:password@]
            ([^/]*) # host1[:port1][,host2[:port2],...[,hostN[:portN]]]
            (?:
               / ([^?]*) # /[database]
                (?: [?] (.*) )? # [?options]
            )?
            $ }x
      )
    {
        return {
            username  => $1 // '',
            password  => $2 // '',
            hostpairs => $3 // '',
            db_name   => $4 // '',
            options   => $5 // '',
        };
    }
    return;
}

sub _host_names_to_ip {
    my ( $self, $uri ) = @_;
    my $parsed = $self->_parse_connection_uri($uri)
      or Carp::confess("Could not parse connection string '$uri'\n");

    # convert hostnames to IP addresses to work around
    # some MongoDB bugs/inefficiencies
    my @pairs;
    for my $p ( split /,/, $parsed->{hostpairs} ) {
        my ( $host, $port ) = split /:/, $p;
        my $ipaddr;
        for my $family ( Socket::AF_INET(), Socket::AF_INET6() ) {
            my ( $err, $res ) =
              getaddrinfo( $host, "", { family => $family, socktype => SOCK_RAW } );
            next if $err;
            ( $err, $ipaddr ) = getnameinfo( $res->{addr}, NI_NUMERICHOST, NIx_NOSERV );
            last if defined $ipaddr;
        }
        Carp::croak "Cannot resolve address for '$host'" unless defined $ipaddr;
        $ipaddr .= ":$port" if defined $port && length $port;
        push @pairs, $ipaddr;
    }

    # reassemble new host URI
    my $new_host = "mongodb://";
    $new_host .= "$parsed->{username}:$parsed->{password}\@"
      if length $parsed->{username};
    $new_host .= join( ",", @pairs );
    $new_host .= "/" if length $parsed->{db_name} || length $parsed->{options};
    $new_host .= $parsed->{db_name} if length $parsed->{db_name};
    $new_host .= "?$parsed->{options}" if length $parsed->{options};

    return $new_host;
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Role::MongoDB - Provide MongoDB connections, databases and collections

=head1 VERSION

version 0.010

=head1 SYNOPSIS

In your module:

    package MyData;
    use Moose;
    with 'MooseX::Role::MongoDB';

    has database => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has client_options => (
        is       => 'ro',
        isa      => 'HashRef',
        default  => sub { {} },
    );

    sub _build__mongo_default_database { return $_[0]->database }
    sub _build__mongo_client_options   { return $_[0]->client_options }

    sub do_stuff {
        my ($self) = @_;

        # get "test" database
        my $db = $self->_mongo_database("test");

        # get "books" collection from default database
        my $books = $self->_mongo_collection("books");

        # get "books" collection from another database
        my $other = $self->_mongo_collection("otherdb" => "books");

        # ... do stuff with them
    }

In your code:

    my $obj = MyData->new(
        database => 'MyDB',
        client_options  => {
            host => "mongodb://example.net:27017",
            username => "willywonka",
            password => "ilovechocolate",
        },
    );

    $obj->do_stuff;

=head1 DESCRIPTION

This role helps create and manage L<MongoDB> objects.  All MongoDB objects will
be generated lazily on demand and cached.  The role manages a single
L<MongoDB::MongoClient> connection, but many L<MongoDB::Database> and
L<MongoDB::Collection> objects.

The role also compensates for dropped connections and forks.  If these are
detected, the object caches are cleared and new connections and objects will be
generated in the new process.

Note that a lost connection will not be detectable until I<after> an exception
is thrown due to a failed operation.

When using this role, you should not hold onto MongoDB objects for long if
there is a chance of your code forking.  Instead, request them again
each time you need them.

=head1 REQUIREMENTS

=head2 _logger

You must provide a private method that returns a logging object.  It must
implement at least the C<info> and C<debug> methods.  L<MooseX::Role::Logger>
version 0.002 or later is recommended, but other logging roles may be
sufficient.

=head1 METHODS

=head2 _mongo_database

    $obj->_mongo_database( $database_name );

Returns a L<MongoDB::Database>.  The argument is the database name.
With no argument, the default database name is used.

=head2 _mongo_collection

    $obj->_mongo_collection( $database_name, $collection_name );
    $obj->_mongo_collection( $collection_name );

Returns a L<MongoDB::Collection>.  With two arguments, the first argument is
the database name and the second is the collection name.  With a single
argument, the argument is the collection name from the default database name.

=head2 _mongo_clear_caches

    $obj->_mongo_clear_caches;

Clears the MongoDB client, database and collection caches.  The next
request for a database or collection will reconnect to the MongoDB.

=for Pod::Coverage BUILD

=head1 CONFIGURING

The role uses several private attributes to configure itself:

=over 4

=item *

C<_mongo_client_class> — name of the client class

=item *

C<_mongo_client_options> — passed to client constructor

=item *

C<_mongo_default_database> — default name used if not specified

=back

Each of these have lazy builders that you can override in your class to
customize behavior of the role.

The builders are:

=over 4

=item *

C<_build__mongo_client_class> — default is C<MongoDB::MongoClient>

=item *

C<_build__mongo_client_options> — default is an empty hash reference

=item *

C<_build__mongo_default_database> — default is the string 'test'

=back

You will generally want to at least override C<_build__mongo_client_options> to
allow connecting to different hosts.  You may want to set it explicitly or you
may want to have your own public attribute for users to set (as shown in the
L</SYNOPSIS>).  The choice is up to you.

If a MongoDB C<host> string is provided in the client options hash, any host
names will be converted to IP addresses to avoid known bugs using
authentication over SSL.

Note that the C<_mongo_default_database> is also used as the default database for
authentication, unless a C<db_name> is provided to C<_mongo_client_options>.

=head1 LOGGING

Currently, only 'debug' level logs messages are generated for tracing MongoDB
interaction activity across forks.  See the tests for an example of how to
enable it.

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=item *

L<MongoDB>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/MooseX-Role-MongoDB/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/MooseX-Role-MongoDB>

  git clone https://github.com/dagolden/MooseX-Role-MongoDB.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alexandr Ciornii David Golden Todd Bruner

=over 4

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

David Golden <xdg@xdg.me>

=item *

Todd Bruner <tbruner@sandia.gov>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
