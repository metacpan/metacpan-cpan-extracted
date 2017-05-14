package Myco;

###############################################################################
# $Id: Myco.pm,v 1.8 2006/03/31 19:20:16 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco - The myco object framework

=head1 VERSION

=over 4

=item Release

1.21

=cut

our $VERSION = 1.22;

=head1 SYNOPSIS

 use Myco;

 ### DB connection
 Myco->db_connect(@dbconn);
 Myco->db_disconnect(@dbconn);

 $storage = Myco->storage;      # Tangram connection object

 ### Object retrieval
 $obj = Myco->load($id);        # retrieval by Tangram object id

 # Retrieve all of given class
 @objects = Myco->select('Myco::Foo');

 # Retrieve all of given class, using 'remote' object and filtering
 $remote = Myco->remote('Myco::Foo');
 @objects = Myco->select($remote, $filter);

 # Retrieve all of given class, by cursor
 $cursor = Myco->select('Myco::Foo');
 while (my $obj = $cursor->current()) {
     # process $obj
     $cursor->next();
 }

 ### Object insertion and update
                                # Myco::Entity alternative
 Myco->insert($obj);               # $obj->save;
 Myco->update($obj);               # $obj->save;
 Myco->update(@objects);

 ### Object removal - from db and memory
 Myco->destroy($obj);              # $obj->destroy;
 Myco->destroy(@objects);

 ### Object removal - from just db
 Myco->erase(@objects);

See L<Tangram::Storage|Tangram::Storage> for other miscellany.

=head1 DESCRIPTION

Encapsulates functionality of Tangram::Storage but treats the storage
connection object as class data, allowing access to object
persistence functionality via class method calls.

Intended for use with so-called myco "entity" objects, that is those
belonging to classes that inherit from Myco::Entity.  Use of
inherited instance methods for managing object persistence state where
possible is preferred.  (ie. use C<$obj-E<gt>save> instead of both
C<Myco-E<gt>insert($obj)> and C<Myco-E<gt>update($obj)>.)

Pulls in all other required classes of entire Myco class system.

=cut

### Module Dependencies and Compiler Pragma
require 5.006;

use strict;
use warnings;
use Myco::Exceptions;

use Tangram;
use Myco::Schema;
use WeakRef;
use Myco::Entity::Event;

### Class data
my $_Tstorage;
my $_event_cache;

### Methods
sub storage {
    my ($class, $newval) = @_;
    $_Tstorage = $newval if defined $newval;
    $_event_cache = Myco::Entity::Event->get_event_cache;
    return $_Tstorage;
}

sub is_transient {
    my ($class, $arg) = @_;
    my $id = ref $arg ? $_Tstorage->id($arg) : $arg;
    return 0 unless $id;
    return exists $_Tstorage->{objects}{$id};
}

# We'll have DBI use this coderef to throw exceptions.
my $dbi_err_handler = sub { Myco::Exception::DB->throw(error => shift) };

sub db_connect {
    unless (Myco::Schema->schema) {
	# Hack to allow debugging of what would otherwise be compile-time
	# behavior
	Myco::Schema::mkschema();
    }
    my ($self, $dsn, $user, $pw) = @_;
    return $self->storage(Tangram::Storage->connect(Myco::Schema->schema,
                                                    $dsn, $user, $pw,
                                                    {HandleError =>
                                                     $dbi_err_handler}) )
      unless $self->storage;
}

sub db_disconnect {
    my $self = shift;
    $self->storage->disconnect;
    $self->storage('');
}


##### Localized Tangram::Storage methods

sub load {
    my $obj;
    eval {
	$obj = $_Tstorage->load($_[1]);
    };
    $@ ? undef : $obj;
}

sub destroy {
    my $class = shift;
    my $dbh = $_Tstorage;
    for (@_) {
	my $id = $dbh->id($_);
	Myco->erase($_) if $id;
	$_->clear_refs;
	undef $_;
	$dbh->unload($id) if $id;
    }
    1;
}

sub unload { shift; $_Tstorage->unload(@_) }
sub select { shift; $_Tstorage->select(@_) }
sub remote { shift; $_Tstorage->remote(@_) }
sub id { shift; $_Tstorage->id(@_) }

sub insert {
    my $self = shift;
    my @ids = $_Tstorage->insert(@_);
    for my $entity (@_) {
        Myco::Entity::Event->flush_event($entity)
            if exists $_event_cache->{"$entity"};
    }
    return wantarray ? @ids : shift @ids;
}

sub update {
    my $self = shift;
    for my $entity (@_) {
        Myco::Entity::Event->flush_event($entity)
            if exists $_event_cache->{"$entity"};
    }
    $_Tstorage->update(@_);
}

sub erase {
    my $self = shift;
    for my $entity (@_) {
        my $event = 
          Myco::Entity::Event->new( entity => $entity, kind => 2,
                                          entity_id => $_Tstorage->id($entity)
                                        );
        Myco->insert($event) if $event;
    }
    $_Tstorage->erase(@_);
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    return if $AUTOLOAD =~ /DESTROY$/;
    $AUTOLOAD =~ /.*::(\w+)/;
    $_Tstorage->$1(@_);
}


package main;

use strict;
use warnings;

1;
__END__

=head1 BUGS

Use of AUTOLOAD for Tangram::Storage encapsulation should be retired
for performance reasons.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

all L<Tangram|Tangram> -related perldoc,
L<Myco::Entity|Myco::Entity>,

=cut
