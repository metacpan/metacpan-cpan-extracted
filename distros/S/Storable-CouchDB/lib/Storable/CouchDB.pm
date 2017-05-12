package Storable::CouchDB;
use strict;
use warnings;
use CouchDB::Client;

our $VERSION='0.04';

=head1 NAME

Storable::CouchDB - Persistences for Perl data structures in Apache CouchDB

=head1 SYNOPSIS

  use Storable::CouchDB;
  my $s = Storable::CouchDB->new;
  my $data = $s->retrieve('doc'); #undef if not exists
  $s->store('doc1' => "data");    #overwrites or creates if not exists
  $s->store('doc2' => {"my" => "data"});
  $s->store('doc3' => ["my", "data"]);
  $s->store('doc4' => undef);
  $s->store('doc5' => $deepDataStructure);
  $s->delete('doc');

=head2 Inheritance

  package My::Storable::CouchDB;
  use base qw{Storable::CouchDB};
  sub db {"what-i-want"};
  sub uri {"http://where.i.want:5984/"};
  1;

=head1 DESCRIPTION

The Storable::CouchDB package brings persistence to your Perl data structures containing SCALAR, ARRAY, HASH or anything that can be serialized into JSON.

The concept for this package is to provide similar capabilities as Storable::store and Storable::retrieve which work seamlessly with CouchDB instead of a file system.

=head2 Storage Details

The data is stored in the CouchDB under a key named "data", in the document named by the "doc" argument, in the database return by the "db" method, on the server returned by the "uri" method.

In pseudo code:

  $uri . $db . $doc -> "data" = $data

Example:

The perl script

  perl -MStorable::CouchDB -e 'Storable::CouchDB->new->store(counter=>{key=>[1,2,3]})' 

Creates or updates this document

  http://127.0.0.1:5984/perl-storable-couchdb/counter

Which returns this JSON structure

  {
    "_id":"counter",
    "_rev":"39-31732f54c3ad4f2b61c217a9a8cf6171",
    "data":{"key":[1,2,3]}
  }

=head1 USAGE

Write a Perl data structure to the database.

  use Storable::CouchDB;
  my $s = Storable::CouchDB->new;
  $s->store('doc' => "Hello World!");

Read a Perl data structure from the database.

  use Storable::CouchDB;
  my $s = Storable::CouchDB->new;
  my $data = $s->retrieve('doc');
  print "$data\n";

prints "Hello World!"

=head1 CONSTRUCTOR

=head2 new

  my $s = Storable::CouchDB->new; #use default server and database

  my $s = Storable::CouchDB->new(
                                 uri => 'http://127.0.0.1:5984/',  #default
                                 db  => 'perl-storable-couchDB',   #default
                                );

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self = shift();
  %$self=@_;
}

=head2 store

  $s->store('doc' => "Value");
  $s->store('doc' => {a => 1});
  $s->store('doc' => [1, 2, 3]);
  my $data=$s->store('doc' => {b => 2}); #returns data that was stored

API Difference: The L<Storable> API uses the 'store data > filename' syntax which I think is counterintuitive for a document key=>value store like Apache CouchDB.

=cut

sub store {
  my $self=shift;
  die("Error: Wrong number of arguments.") unless @_ == 2;
  my $doc=shift;
  die("Error: Document name must be defined.") unless defined $doc;
  my $data=shift;                        #support storing undef!
  my $cdbdoc=$self->_db->newDoc($doc);   #isa CouchDB::Client::Doc
  if ($self->_db->docExists($doc)) {
    $cdbdoc->retrieve;                   #to get revision number for object
    $cdbdoc->data({data=>$data});
    $cdbdoc->update;
  } else {
    $cdbdoc->data({data=>$data});
    $cdbdoc->create;
  }
  return $cdbdoc->data->{"data"};
}

=head2 retrieve

  my $data=$s->retrieve('doc'); #undef if not exists (but you can also store undef)

=cut

sub retrieve {
  my $self=shift;
  die("Error: Wrong number of arguments.") unless @_ == 1;
  my $doc=shift;
  die("Error: Document name must be defined.") unless defined $doc;
  if ($self->_db->docExists($doc)) {
    my $cdbdoc=$self->_db->newDoc($doc); #isa CouchDB::Client::Doc
    $cdbdoc->retrieve;
    return $cdbdoc->data->{"data"};      #This may also be undef
  } else {
    return undef;
  }
}

=head2 delete

  $s->delete('doc');

  my $data=$s->delete('doc'); #returns value from database just before delete

=cut

sub delete {
  my $self=shift;
  die("Error: Wrong number of arguments.") unless @_ == 1;
  my $doc=shift;
  die("Error: Document name must be defined.") unless defined $doc;
  if ($self->_db->docExists($doc)) {
    my $cdbdoc=$self->_db->newDoc($doc); #isa CouchDB::Client::Doc
    $cdbdoc->retrieve;                   #to get revision number for object
    my $data=$cdbdoc->data->{"data"};    #since we already have the data
    $cdbdoc->delete;
    return $data;                        #return what we deleted
  } else {
    return undef;
  }
}

=head1 METHODS (Properties)

=cut

sub _client {                            #isa CouchDB::Client
  my $self=shift;
  unless (defined $self->{"_client"}) {
    $self->{"_client"}=CouchDB::Client->new(uri=>$self->uri);
    $self->{"_client"}->testConnection or die("Error: CouchDB Server Unavailable");
  }
  return $self->{"_client"};
}

sub _db {                                #isa CouchDB::Client::DB
  my $self=shift;
  unless (defined $self->{"_db"}) {
    $self->{"_db"}=$self->_client->newDB($self->db);
    $self->{"_db"}->create unless $self->_client->dbExists($self->db);
  }
  return $self->{"_db"};
}

=head2 db

Sets and retrieves the Apache CouchDB database name.

Default: perl-storable-couchdb

Limitation: Only lowercase characters (a-z), digits (0-9), and any of the characters _, $, (, ), +, -, and / are allowed. Must begin with a letter.

=cut

sub db {
  my $self=shift;
  $self->{"db"}=shift if @_;
  $self->{"db"}='perl-storable-couchdb' unless defined $self->{"db"};
  return $self->{"db"};
}

=head2 uri

URI of the Apache CouchDB server

Default: http://127.0.0.1:5984/

=cut

sub uri {
  my $self=shift;
  $self->{"uri"}=shift if @_;
  $self->{"uri"}='http://127.0.0.1:5984/' unless defined $self->{"uri"};
  return $self->{"uri"};
}

=head1 LIMITATIONS

All I need this package for storing ASCII values so currently this package meets my requirements.  But, I would like to add blessed object support.  I will gladly accept patches!

This package relies heavily on L<CouchDB::Client> to do the right thing.  So far, I have not had any compliants other than a slightly awkard interface.

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  Satellite Tracking of People, LLC
  mrdvt92
  http://www.davisnetworks.com/

=head1 COPYRIGHT

Copyright (c) 2011 Michael R. Davis - MRDVT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Storable>, L<CouchDB::Client>, Apache CouchDB http://couchdb.apache.org/

=cut

1;
