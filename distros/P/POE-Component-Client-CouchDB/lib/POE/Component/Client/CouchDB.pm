package POE::Component::Client::CouchDB;
use POE qw(Component::Client::REST::JSON);
use Moose;

our $VERSION = '0.05';

has rest => (
  is      => 'ro',
  isa     => 'POE::Component::Client::REST::JSON',
  handles => [qw(shutdown)],
  default => sub { 
    POE::Component::Client::REST::JSON->new(Alias => "$_[0]-REST") 
  },
);

has host => (
  is       => 'ro',
  isa      => 'Str',
  default  => 'localhost'
);

has port => (
  is       => 'ro',
  isa      => 'Int',
  default  => 5984,
);

sub call {
  my ($self, $method, $path, @rest) = @_;
  my ($host, $port) = ($self->host, $self->port);
  $self->rest->call($method, "http://$host:$port/$path", @rest);
}

sub all_dbs {
  my ($self, @opt) = @_;
  $self->call(GET => _all_dbs => @opt);
}

sub create_db {
  my ($self, $name, @opt) = @_;
  $self->call(PUT => $name, @opt);
}

sub delete_db {
  my ($self, $name, @opt) = @_;
  $self->call(DELETE => $name, @opt);
}

sub db_info {
  my ($self, $name, @opt) = @_;
  $self->call(GET => $name, @opt);
}

sub database {
  my ($self, $name) = @_;
  require POE::Component::Client::CouchDB::Database;
  return POE::Component::Client::CouchDB::Database->new(
    couch => $self,
    name => $name,
  );
}

__PACKAGE__->meta->add_method(db => \&database);

1;

__END__

=head1 NAME

POE::Component::Client::CouchDB - Asynchronous CouchDB server interaction

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

This class makes use of L<POE::Component::Client::REST::JSON> to provide an
asynchronous interface to the CouchDB REST API.  All methods use
L<call|/METHODS> to make the request, and follow its calling convention.

    use POE qw(Component::Client::CouchDB);

    my $alias = 'Huzzah!';
    POE::Session->create(inline_states => {
      _start => sub {
        $poe_kernel->alias_set($alias);
        my $couch = POE::Component::Client::CouchDB->new;
        $couch->create_db('foobar', callback => [$alias, 'db_created']);
      },
      db_created => sub {
        my ($data, $response) = @_[ARG0..ARG1];
        use YAML;
        print Dump($data);
        $poe_kernel->alias_remove($alias);
      },
    });

    $poe_kernel->run();

=head1 ATTRIBUTES

=over 4

=item rest

You can optionally supply a configured L<POE::Component::Client::REST::JSON>
object to be used, but by default one will be created (you can also get this one to pass to another DB object...  C<-&gt;new(rest =&gt; $old-&gt;rest)>)

=item host

The hostname of the CouchDB server.  Defaults to localhost.

=item port

The port of the CouchDB server.  Defaults to 5984.

=back

=head1 METHODS

Note that all of these methods take a callback keyword argument (CODE or 
[session, state]) as their last argument except where otherwise noted.

=over 4

=item call I<method, path, ...>

This is L<POE::Component::Client::REST::JSON>'s call with the url part 
partially filled in - use a path instead (such as "_all_dbs").  You shouldn't 
need to use this directly, so don't.

=item all_dbs

=item create_db I<name>

=item delete_db I<name>

=item db_info I<name>

These all do what you would expect according to the CouchDB documentation.
See L<http://wiki.apache.org/couchdb/HttpDatabaseApi>.

=item database I<name>

=item db I<name>

Returns a new L<POE::Component::Client::CouchDB::Database> representing the
database with the specified name.  This method does not follow the REST
calling conventions, cause it's not a REST call!

=item shutdown

Equivalent to $obj->rest->shutdown();

=back

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 BUGS

Probably.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul Driver

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
