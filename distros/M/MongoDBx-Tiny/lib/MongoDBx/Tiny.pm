package MongoDBx::Tiny;

use 5.006;
use strict;
use warnings;

=head1 NAME

MongoDBx::Tiny - Simple Mongo ORM for Perl

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  # --------------------
  package My::Data;

  use MongoDBx::Tiny;

  CONNECT_INFO  host => 'localhost', port => 27017;
  DATABASE_NAME 'my_data';

  # --------------------
  package My::Data::Foo;

  use MongoDBx::Tiny::Document;

  COLLECTION_NAME 'foo';

  ESSENTIAL qw/code/;
  FIELD 'code', INT, LENGTH(10), DEFAULT('0'), REQUIRED;
  FIELD 'name', STR, LENGTH(30), DEFAULT('noname');

  # --------------------
  package main;

  my $tiny = My::Data->new;
  $tiny->insert(foo => { code => 123, name => "foo_123"}) or die $!;
  my $foo = $tiny->single(foo => { code => 123});
  $foo->name('foo_321');
  $foo->update;
  $foo->remove;

=cut

use MongoDB;
use Carp qw/carp confess/;
use Data::Dumper;
use MongoDBx::Tiny::Util;
use Params::Validate ();
use Scalar::Util qw(blessed);


sub import {
    my $caller = (caller(0))[0];
    {
	no strict 'refs';
	push @{"${caller}::ISA"}, __PACKAGE__;
    }
    strict->import;
    warnings->import;
    __PACKAGE__->export_to_level(1, @_);
}

require Exporter;
use base qw/Exporter/;
our @EXPORT = qw/CONNECT_INFO DATABASE_NAME LOAD_PLUGIN/;
our $_CONNECT_INFO;
our $_DATABASE_NAME;

=head1 EXPORT

A list of functions that can be exported.

=head2 CONNECT_INFO

      CONNECT_INFO  host => 'localhost', port => 27017;

=head2 DATABASE_NAME

      DATABASE_NAME 'my_data';

=head2 LOAD_PLUGIN

      LOAD_PLUGIN 'One'; # MongoDBx::Tiny::Plugin::One
      LOAD_PLUGIN 'Two';
      LOAD_PLUGIN '+Class::Name';

=cut

{
    no warnings qw(once);
    *CONNECT_INFO  = \&install_connect_info;
    *DATABASE_NAME = \&install_database_name;
    *LOAD_PLUGIN   = \&install_plugin;
}

sub install_connect_info  { util_class_attr('CONNECT_INFO', @_)  }

sub install_database_name { util_class_attr('DATABASE_NAME',@_)  }

sub install_plugin        {
    my $class = (caller(0))[0];
    $class->load_plugin(shift)
}


=head1 SUBROUTINES/METHODS

=head2 new

    my $tiny = My::Data->new();

    # or you can specify connect_info, database_name.
    my $tiny = My::Data->new({
        connect_info  => [ host => 'localhost', port => 27017 ],
        database_name => 'my_data',
    });

=cut

sub new {
    my $class = shift;
    my $opt   = shift;
    if (ref $opt->{connect_info} eq 'ARRAY') {
	$class->install_connect_info($opt->{connect_info});
    }
    if ($opt->{database_name} ) {
	$class->install_database_name($opt->{database_name});
    }
    my $self = bless{},$class;
    eval { $self->connect; };

    if ($@) {
	Carp::carp $@;
	return;
    }

    return $self;
}

=head2 get_connection

  returns MongoDB::Connection. you can override how to get connection object.

    sub get_connection {
        my $class = shift;

        return MongoDB::Connection->new(@{$class->CONNECT_INFO}) if !$ENV{PLACK_ENV};

        my $key   = 'some_key';
        if (in_scope_container() and my $con = scope_container($key)) {
            return $con;
        } else {
    	    my $con = MongoDB::Connection->new(@{$class->CONNECT_INFO});
    	    scope_container($key, $con) if in_scope_container();
    	    return $con;
        }
    }


=cut

sub get_connection {
    my $class = shift;
    return MongoDB::Connection->new(@{$class->connect_info});
}

=head2 connect_info, database_name

  alias to installed value

    my $connect_info  = $tiny->connect_info;

    my $database_name = $tiny->database_name;

=cut

sub connect_info {
    my $class = shift; # or self
    util_class_attr('CONNECT_INFO',$class);
}

sub database_name {
    my $class = shift; # or self
    util_class_attr('DATABASE_NAME',$class);
}

=head2 connection, database

  alias to connection and database object.

    my $connection = $tiny->connection; # MongoDB::Connection object

    my $database   = $tiny->database;   # MongoDB::Database object

=cut


sub connection { shift->{connection} }

sub database   { shift->{database}   }

=head2 cursor_class, validator_class, gridfs_class

  override if you want.

    MongoDBx::Tiny::Cursor
  
    MongoDBx::Tiny::Validator
  
    MongoDBx::Tiny::GridFS

=cut

sub cursor_class    { 'MongoDBx::Tiny::Cursor' }

sub validator_class { 'MongoDBx::Tiny::Validator' }

sub gridfs_class    { 'MongoDBx::Tiny::GridFS' }

=head2 collection

  returns MongoDB::Collection

    $collection = $tiny->collection('collection_name')

=cut

sub collection {
    my $self = shift;
    my $name = shift or confess q|no collection name|;
    my $opt  = shift || {no_cache => 0};
    if ($opt->{no_cache}) {
	if ($self->database->can('get_collection')) {
	    return $self->database->get_collection($name);
	} else {
	    return $self->database->$name();
	}
    } else {
	my $cache = $self->{collection};
	return $cache->{$name} if $cache->{$name};
	return ($self->{collection}->{$name} = $self->database->can('get_collection') ? 
		    $self->database->get_collection($name) : 
		    $self->database->$name());
    }
}

=head2 connect / disconnect

  just (re)connect & disconnect

=cut

sub connect  {
    my $self = shift;
    $self->disconnect;

    my $connection = $self->get_connection;
    my $db_name    = $self->database_name;
    my $database   = $connection->can('get_database') ? 
	$connection->get_database($db_name) :
	$connection->$db_name();
    $self->{connection} = $connection;
    $self->{database}   = $database;
    $self->{gridfs}     = undef;

    return $self->{connection};
}

sub disconnect  {
    my $self = shift;
    for (qw(connection database gridfs collection)) {
	delete $self->{$_};
    }
    return 1;
}


=head2 insert,create

    $document_object = $tiny->insert('collection_name' => $document);

=cut

{
    no warnings qw(once);
    *create = \&insert;
}

sub insert {
    my $self       = shift;
    my $c_name     = shift or confess q/no collection name/;
    my $document   = shift or confess q/no document/;

    my $opt        = shift;
    $opt->{state}  = 'insert';

    my $validator = $self->validate($c_name,$document,$opt);

    if ($validator->has_error) {
	confess "invalid document: \n" . (Dumper $validator->errors);
    }

    my $d_class   = $self->document_class($c_name);
    unless ($opt->{no_trigger}) {
	$d_class->call_trigger('before_insert',$self,$document,$opt) ;
    }

    my $collection = $self->collection($c_name);
    my $id         = $collection->insert($document);
    my $object = $self->single($c_name,$id);
    unless ($opt->{no_trigger}) {
	$d_class->call_trigger('after_insert',$object,$opt);
    }
    return $object;
}

=head2 single

  returns MongoDBx::Tiny::Document object.

    $document_object = $tiny->single('collection_name' => $MongoDB_oid_object);
    
    $tiny->single('collection_name' => $oid_text);
    
    $query = { field => $val };
    $tiny->single('collection_name' => $query);

=cut

sub single {
    #xxx
    # 4ff19d717bcc56834b000000
    # tiny->single("sfa"); # return first value
    my $self   = shift;
    my $c_name = shift;

    my $collection = $self->collection($c_name);
    my $document;
    my $d_class   = $self->document_class($c_name);

    my $essential = $d_class->essential; #

    my ($proto) = shift;
    unless (ref $proto eq 'HASH') {
	$proto = { _id => "$proto" };
    }
    $proto = util_to_oid($proto,'_id',$d_class->field->list('OID'));

    my $reserved= $d_class->query_attributes('single');
    if ($reserved && ( my @attr = keys %$reserved)) {
	$proto->{$_} ||= $reserved->{$_} for @attr;
    }
    $document = $collection->find_one($proto,$essential);

    # # needed?
    # elsif (scalar @_ >= 2) {
    # 	my %query = @_;
    # 	$document = $collection->find_one(\%query,$essential);
    # }
    return unless $document;
    $self->document_to_object($c_name,$document);
}

=head2 search

  returns MongoDBx::Tiny::Cursor object.

    $query = { field => $val };
    $cursor = $tiny->search('collection_name' => $query);
    while (my $object = $cursor->next) {
        # warn $object->id;
    }
    
    # list context
    @object = $tiny->search('collection_name' => $query);

=cut

sub search {
    my $self = shift;
    # xxx
    my $c_name = shift;
    my $collection = $self->collection($c_name);
    my $d_class   = $self->document_class($c_name);
    my $essential = $d_class->essential; # 
    my $query = shift;
    my @operation = @_;

    $query = util_to_oid($query,'_id',$d_class->field->list('OID'));
    my $reserved= $d_class->query_attributes('search');
    if ($reserved && ( my @attr = keys %$reserved)) {
	$query->{$_} ||= $reserved->{$_} for @attr;
    }

    my $cursor = $collection->find($query)->fields($essential);
    if (wantarray) {
	return map { $self->document_to_object($c_name,$_) } $cursor->all;
    } else {
	eval "require " . $self->cursor_class;
	return $self->cursor_class->new(
	    tiny => $self, c_name => $c_name,cursor => $cursor
	);
    }
}

=head2 update

    $tiny->update('collection_name',$query,$document);

=cut

sub update {
    my $self   = shift;
    # xxx
    my $c_name = shift || confess q/no collection name/;;
    my $query  = shift || confess q/no query/;
    my $document = shift;
    my $opt      = shift;
    return unless $document;
    $opt->{state} = 'update';

    my $validator = $self->validate(
	$c_name,$document,$opt
    );
    
    if ($validator->has_error) {
	confess "invalid document: \n" . (Dumper $validator->errors);
    }
    my $d_class   = $self->document_class($c_name);

    my @object; # xxx
    if (!$opt->{no_trigger} and $d_class->trigger('before_update')) {
	my $cursor = $self->search($c_name,$query);
	while (my $object = $cursor->next) {
	    push @object,$object;
	    $object->call_trigger('before_update',$self,$opt);
	}
    }

    my $collection = $self->collection($c_name);
    $collection->update($query,{ '$set' => $document },{ multiple => 1 });

    if (!$opt->{no_trigger} and $d_class->trigger('after_update')) {
	for my $object (@object) {
	    $object->call_trigger('after_update',$self,$opt);
	}
    }
    
    # tiny->remove('foo',{ code => 111 });
}

=head2 remove


    $tiny->remove('collection_name',$query);

=cut

sub remove {
    my $self   = shift;
    # xxx
    my $c_name = shift || confess q/no collection name/;;
    my $query  = shift || confess q/no query/;
    my $opt    = shift || {};

    my $d_class   = $self->document_class($c_name);
    
    my @object; # xxx
    if (!$opt->{no_trigger} and $d_class->trigger('before_remove')) {
	my $cursor = $self->search($c_name,$query);
	while (my $object = $cursor->next) {
	    push @object,$object;
	    $object->call_trigger('before_remove',$object,$opt);
	}
    }

    my $collection = $self->collection($c_name);
    $collection->remove($query);

    if (!$opt->{no_trigger} and $d_class->trigger('after_remove')) {
	for my $object (@object) {
	    $object->call_trigger('after_remove',$object,$opt);
	}
    }
}

=head2 count

    $count_num = $tiny->count('collection_name',$query);

=cut

sub count {
    my $self = shift;
    my $c_name = shift;
    my $collection = $self->collection($c_name);
    my $d_class   = $self->document_class($c_name);
    return $collection->count(shift);
}

=head2 document_to_object

    $document_object = $tiny->document_to_object('collection_name',$document);

=cut

sub document_to_object {
    my $self     = shift;
    my $c_name   = shift or confess q/no collecion name/;
    my $document = shift or confess q/no document/;
    confess q/no id/ unless $document->{_id};

    my $d_class  = $self->document_class($c_name);

    return $d_class->new($document,$self);
}

=head2 validate

    $validator = $tiny->validate('collecion_name',$document,$opt);

      my $validator = $tiny->validate(
          'foo',
          { code => 123, name => "foo_123"},
          { state => 'insert' }
      );
      my $foo1      = $tiny->insert(
          'foo',
          $validator->document,
          { state => 'insert', no_validate => 1 }
      );
      # erros: [{ field => 'field1', code => 'errorcode', message => 'message1' },,,]
      my @erros         = $validator->erros; 
      
      my @fields        = $validator->errors('field');
      my @error_code    = $validator->errors('code');
      my @error_message = $validator->errors('message');

=cut

sub validate {
    my $self = shift;
    my $c_name   = shift or confess q/no collecion_name/;
    my $document = shift or confess q/no document/;
    my $opt      = shift;

    Params::Validate::validate_with(
	params => $opt,
	spec  => {
	    state       => 1,# insert,update
	    no_trigger  => 0,
	    no_validate => 0,
	},
        allow_extra => 1,
    );
    
    $opt->{tiny} = $self;
    eval "require " . $self->validator_class;
    my $validator   = $self->validator_class->new(
	$c_name,
	$document,
	$self,
    );
 
    return $validator->check($opt);
}

=head2 gridfs

  returns MongoDBx::Tiny::GridFS

    $gridfs = $tiny->gridfs();
    
    $gridfs = $tiny->gridfs({database => $mongo_databse_object });
    
    $gridfs = $tiny->gridfs({fields => 'other_filename' });

      my $gridfs = $tiny->gridfs;
      $gridfs->put('/tmp/foo.txt', {"filename" => 'foo.txt' });
      my $foo_txt = $gridfs->get({ filename => 'foo.txt' })->slurp;
      
      $gridfs->put('/tmp/bar.txt','bar.txt');
      my $bar_txt = $gridfs->get('bar.txt')->slurp;

=cut

sub gridfs     {
    my $self     = shift;
    my $opt      = shift || {};
    my %opt      = Params::Validate::validate_with(
	params => $opt,
	spec   => {
	    database => {optional => 1},
	    fields   => {optional => 1, default => 'filename'},
	}
    );

    my $database = $opt{database} || $self->database;

    eval "require " . $self->gridfs_class;
    return $self->{gridfs} if $self->{gridfs};
    $self->{gridfs} = $self->gridfs_class->new(
	$database->get_gridfs,$opt{fields}
    );
}


=head2 document_class

    $document_class_name = $tiny->document_class('collecion_name');

=cut

sub document_class {
    my $self = shift;
    my $c_name = shift or confess q/no collection name/;
    return util_document_class($c_name,ref $self);
}

=head2 load_plugin

    # --------------------
    
    package MyDB;
    use MongoDBx::Tiny;
  
    LOAD_PLUGIN('PluginName');
    LOAD_PLUGIN('+Class::Name');
    
    # --------------------
    package MongoDBx::Tiny::Plugin::PluginName;
    use strict;
    use warnings;
    use utf8;
    
    our @EXPORT = qw/function_for_plugin/;
    
    sub function_for_plugin {}
    
    # --------------------
    
    $tiny->function_for_plugin;

=cut

sub load_plugin {
    my ($proto, $pkg) = @_;
    
    my $class = ref $proto ? ref $proto : $proto;
    $pkg = $pkg =~ s/^\+// ? $pkg : "MongoDBx::Tiny::Plugin::$pkg";
    eval "require $pkg ";

    no strict 'refs';
    for my $method ( @{"${pkg}::EXPORT"} ) {
	next if $class->can($method);
        *{$class . '::' . $method} = $pkg->can($method);
    }
}

=head2 process

  [EXPERIMENTAL]

    $tiny->process('collecion_name','some',@args);

      $tiny->process('foo','some',$validator,$arg); # just call Data::Foo::process_some
      
      #
      sub process_foo {
          my ($class,$tiny,$validator,$arg) = @_;
      }

=cut

sub process {
    # xxx
    my $self = shift;
    my $c_name = shift or confess q/no collecion name/;
    my $method = shift or confess q/no process method name/;
    my $d_class = $self->document_class($c_name);
    my $process_method = sprintf "process_%s", $method;
    $d_class->$process_method($self,@_);
}

=head2 set_indexes

  [EXPERIMENTAL]

    $tiny->set_indexes('collection_name');

=cut

sub set_indexes {
    my $self   = shift;
    my $c_name = shift;
    my $collection = $self->collection($c_name);
    my $d_class    = $self->document_class($c_name);
    my $indexes = $d_class->indexes || [];


    my $ns = sprintf "%s.%s", $self->database_name,$c_name;

    for my $index (@$indexes) {

	my ($field,$index_opt,$opt) = @$index;
	require Tie::IxHash;
	if (ref $field eq 'ARRAY') {
	    $field = Tie::IxHash->new(@$field);
	}
	my $index_target = ref $field ? $field : { $field => 1 };
	my ($index_exists)  = $self->collection('system.indexes')->find({ns => $ns,key => $index_target})->all;	
	
	if (!$index_exists) {
	    $collection->ensure_index($index_target,$index_opt);
	}
    }
}

=head2 unset_indexes

  [EXPERIMENTAL]

    # drop indexes without "_id";
    $tiny->unset_indexes('collection_name');

=cut

sub unset_indexes {
    my $self   = shift;
    my $c_name = shift;
    my $collection = $self->collection($c_name);

    #> db.system.indexes.find({ns:"my_data.foo",key:{$ne : {"_id":1}}});
    my $ns = sprintf "%s.%s", $self->database_name,$c_name;
    my @index = $self->collection('system.indexes')->find({ns => $ns,key => { '$ne' => {"_id" => 1}}})->all;	
    for (@index) {
	$collection->drop_index($_->{key});
    }
}

sub DESTROY {
    # xxx
}


1;

__END__

=head1 SEE ALSO

=over

=item MongoDBx::Tiny::Document

=item MongoDBx::Tiny::Attributes

=item MongoDBx::Tiny::Relation

=item MongoDBx::Tiny::Util

=item MongoDBx::Tiny::Cursor

=item MongoDBx::Tiny::Validator

=item MongoDBx::Tiny::GridFS

=item MongoDBx::Tiny::GridFS::File

=item MongoDBx::Tiny::Plugin::SingleByCache

=back

=head1 SUPPORT

L<https://github.com/naoto43/mongodbx-tiny/>

=head1 AUTHOR

Naoto ISHIKAWA, C<< <toona at seesaa.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Naoto ISHIKAWA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
