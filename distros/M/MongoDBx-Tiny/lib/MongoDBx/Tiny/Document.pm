package MongoDBx::Tiny::Document;

use 5.006;
use strict;
use warnings;

=head1 NAME

MongoDBx::Tiny::Document - document class

=head1 SYNOPSIS

  package My::Data::Foo;
  use strict;
  use MongoDBx::Tiny::Document;

  COLLECTION_NAME 'foo';

  # FIELD NAME, sub{}, sub{}..
  ESSENTIAL q/code/; # like CDBI's Essential.
  FIELD 'code', INT, LENGTH(10), DEFAULT('0'), REQUIRED;
  FIELD 'name', STR, LENGTH(30), DEFAULT('noname');

  # RELATION ACCESSOR, sub{}
  RELATION 'bar', RELATION_DEFAULT('single','foo_id','id');

  INDEX 'code',{ unique => 1 };
  INDEX 'name';
  INDEX [code => 1, name => -1];

  sub process_some {
      my ($class,$tiny,$validator) = @_;
      $tiny->insert($class->collection_name,$validator->document);
  }


  package My::Data::Bar;
  use strict;
  use MongoDBx::Tiny::Document;

  COLLECTION_NAME 'bar';
  ESSENTIAL qw/foo_id code/;
  FIELD 'foo_id', OID, DEFAULT(''), REQUIRED;
  FIELD 'code',   INT(10),     DEFAULT('0'),REQUIRED;
  FIELD 'name',   VARCHAR(30), DEFAULT('noname'),&MY_ATTRIBUTE;

  RELATION 'foo', RELATION_DEFAULT('single','id','foo_id');

  TRIGGER  'before_insert', sub {
      my ($document_class,$tiny,$document,$opt) = @_;
  };

  # before_update,after_update,before_remove,after_remove
  TRIGGER  'after_insert', sub {
      my ($document_class,$object,$opt) = @_;
  };

  QUERY_ATTRIBUTES {
      # no support in update and delete
      single => { del_flag   => "off" },
      search => { del_flag   => "off" }
  };

  sub MY_ATTRIBUTE {
        return {
      	    name     => 'MY_ATTRIBUTE',
	    callback => sub {
                return 1;
	    }
        };
  }

=cut

use Data::Dumper;
use Scalar::Util qw(blessed);
use Class::Trigger;
use Carp qw/carp confess/;
use MongoDBx::Tiny::Util;
use Params::Validate;

use overload
    '""' => \&id,
    'fallback' => 1;

sub import {
    my $class = shift || __PACKAGE__;
    my $caller = (caller(0))[0];
    {
	no strict 'refs';
	push @{"${caller}::ISA"}, $class;
    }
    strict->import;
    warnings->import;
    __PACKAGE__->export_to_level(1, @_);
    if (__PACKAGE__ ne $class) {
	$class->export_to_level(1,@_);
    }
}

=head1 EXPORT

A list of functions that can be exported.

=head2 COLLECTION_NAME

  # define collection name.
  COLLECTION_NAME 'collection_name';

=head2 ESSENTIAL

  # define essential field always fetched.
  ESSENTIAL qw/field1 field2 field3/;

=head2 FIELD

  # define field name and validation.
  FIELD 'field_name', CODE, CODE;

=head2 RELATION

  RELATION 'relation_name', RELATION_NAME;

  sub RELATION_NAME {
      my $self   = shift;
      my $c_name = shift; # relation
      my $tiny = $self->tiny;
      # xxx
  }

=head2 TRIGGER

  [EXPERIMENTAL]

  TRIGGER  'phase', CODE;

=head2 QUERY_ATTRIBUTES
 
  [EXPERIMENTAL]

  QUERY_ATTRIBUTES {
      # no support in update and delete
      single => { del_flag   => "off" },
      search => { del_flag   => "off" }
  };

  TODO: no_query option for condition

=head2 INDEX
 
  [EXPERIMENTAL]

  INDEX 'field_1';
  INDEX 'field_2',{ unique => 1,drop_dups => 1, safe => 1, background => 1, name => 'foo' };
  INDEX [field_2 => 1, field_3 => -1];

  # for manage index
  $tiny->set_indexes('collection_name');

=head2 MongoDBx::Tiny::Attributes::EXPORT

  perldoc MongoDBx::Tiny::Attributes

=head2 MongoDBx::Tiny::Relation::EXPORT

  perldoc MongoDBx::Tiny::Relation

=cut


require Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw/COLLECTION_NAME ESSENTIAL FIELD RELATION TRIGGER QUERY_ATTRIBUTES INDEX/;
use MongoDBx::Tiny::Attributes;
use MongoDBx::Tiny::Relation;
push @EXPORT,@{MongoDBx::Tiny::Attributes::EXPORT};
push @EXPORT,@{MongoDBx::Tiny::Relation::EXPORT};

our $_COLLECTION_NAME;
our $_ESSENTIAL;
our $_FIELD;
our $_RELATION;

{
    no warnings qw(once);
    *COLLECTION_NAME  = \&install_collection_name;
    *ESSENTIAL        = \&install_essential;
    *FIELD            = \&install_field;
    *RELATION         = \&install_relation;
    *TRIGGER          = \&install_trigger;
    *QUERY_ATTRIBUTES = \&install_query_attributes;
    *INDEX            = \&install_index;
}

sub install_collection_name  { util_class_attr('COLLECTION_NAME',@_) }

sub install_essential{ util_class_attr('ESSENTIAL',@_)         }

sub install_field {
    my ($proto) = shift;
    my ($class,$stat) = util_guess_class($proto);
    my $name;
    if ($stat->{caller}) {
	$name = $proto;
    }


    my $attr = 'FIELD';

    my $field_obj  = util_class_attr($attr,$class) ||
	MongoDBx::Tiny::Document::Field->new;

    Carp::croak q/FIELD needs attributes/ unless @_;

    if (@_) {
	my (@type) = @_;
	$field_obj->add($name,\@type);
	util_class_attr($attr,$class,$field_obj);

	unless ($class->can($name)) {
	    my $accessor = sub {
		my $self = shift;
		unless ($self->_completed){
		    my $essential = $self->essential;
		    if (!$essential->{$name}) {
			my @not_complete = grep { !$essential->{$_}} $self->field->list;
			my $doc = $self->collection->find_one(
			    {_id => $self->id},{ map { $_ => 1 } @not_complete }
			);
			for (@not_complete) {
			    $self->{$_} = $doc->{$_};
			}
			$self->_completed(1);
		    }
		}

		if(@_ >= 1) {
		    $self->_changed($name);
		}
		if(@_ == 1) {
		    return $self->{$name} = $_[0];
		} elsif(@_ > 1) {
		    return $self->{$name} = [@_];
		} else {
		    return $self->{$name};
		}
	    };
	    {
		no strict 'refs';
		*{"${class}::${name}"} = $accessor;
	    }
	}
    }
    return $field_obj;
}

sub install_relation {
    my $proto = shift;

    my ($class,$stat) = util_guess_class($proto);

    my $c_name;
    if ($stat->{caller}) {
	$c_name = $proto;
    } else {
	$c_name = shift;
    }

    my $attr = 'RELATION';

    my $relation  = util_class_attr($attr,$class) ||
	MongoDBx::Tiny::Document::Relation->new;
    if (@_) {
	my ($clause) = @_;
	$relation->add($c_name => [$clause]);
	util_class_attr($attr,$class,$relation);

	unless ($class->can($c_name)) {
	    {
		no strict 'refs';
		*{$class . "::" . $c_name} = sub {
		    my $self = shift;
		    $clause->($self,$c_name);
		}
	    }
	}
    }
    return $relation;
}

sub install_trigger {
    my ($proto) = shift;
    my ($class,$stat) = util_guess_class($proto);
    my $name;
    if ($stat->{caller}) {
	$name = $proto;
    }
    if(@_) {
	my $trigger  = util_class_attr('TRIGGER',$class);
	$trigger->{$name} ++;
	util_class_attr('TRIGGER',$class,$trigger);
    }
    return $class->add_trigger($name,@_);
}

sub install_query_attributes{ util_class_attr('QUERY_ATTRIBUTES',@_)         }

sub install_index {
    my ($proto)       = shift;
    my ($class,$stat) = util_guess_class($proto);
    my $name;
    if ($stat->{caller}) {
	$name = $proto;
    }

    my $tmp;
    if ($name) {
	my ($index_opt,$opt) = @_;
	$tmp = util_class_attr('INDEXES') || [];
	push @$tmp,[ $name,$index_opt,$opt];
    }

    util_class_attr('INDEXES',$tmp);

}

=head1 SUBROUTINES/METHODS

=head2 new

  $document_object = $document_class->new($document,$tiny);

=cut

sub new {
    my $class    = shift;
    my $document = shift or confess q/no document/;
    my $tiny     = shift or confess q/no tiny/;
    my $self = bless $document , $class;
    $self->{_tiny}     = $tiny;
    $self->{_changed}    = {}; # field is changed or not
    $self->{_completed}  = 0;  # all fields are fetched or not.
    return $self;
}

sub _changed {
    my $self = shift;
    my $field  = shift;
    $self->{_changed}->{$field} = 1 if $field;
    return $self->{_changed};
}

sub _completed {
    my $self = shift;
    my $field  = shift;
    $self->{_completed} = 1 if $field;
    return $self->{_completed};
}

=head2 collection_name, essential, field, relation, trigger, query_attributes, indexes

  alias to installed value

    $collection_name = $document_object->collection_name;
    $essential       = $document_object->essential;# {_id => 1, field1 => 1, field2 => 1}

    # MongoDBx::Tiny::Document::Field
    $field      = $document_object->field;

    # MongoDBx::Tiny::Document::Relation
    $relation = $document_object->relation;

    $qa = $document_object->query_attributes;
    $attr = $qa->{$condition}; # condition: single,search

    $indexes = $document_object->indexes; # arrayref

=cut

sub collection_name  {
    my $class = shift; # or self
    util_class_attr('COLLECTION_NAME',$class);
}

sub essential {
    my $self = shift;
    my @essential = util_class_attr('ESSENTIAL',$self) || '_id';

    if (ref $essential[0] eq 'ARRAY') {
	@essential = @{$essential[0]};
    }
    my $ret = @essential ? { map { $_ => 1 } @essential } : {};
    $ret->{_id} = 1 unless $ret->{_id};
    return $ret;
}

sub field {
    my $class    = shift; # or self
    return util_class_attr('FIELD',$class);
}

sub relation {
    my $class = shift; # or self
    return util_class_attr('RELATION',$class);
}

sub trigger {
    my $class = shift; # or self
    my $name  = shift;
    my $stat  = util_class_attr('TRIGGER',$class);
    return $stat->{$name} if $name;
    return util_class_attr('TRIGGER',$class);
}

sub query_attributes  {
    my $class     = shift; # or self
    my $condition = shift;
    my $reserved = util_class_attr('QUERY_ATTRIBUTES',$class);

    return unless $reserved;
    return $reserved->{$condition} if $condition;
    return $reserved;
}

sub indexes {
    my $class = shift;
    util_class_attr('INDEXES',$class)
}

=head2 id

  returns document value "_id"

=cut

{
    no warnings qw(once);
    *id = \&_id;
}

sub _id   { shift->{_id} }

=head2 tiny

  returns MongoDBx::Tiny object

=cut

sub tiny {
    my $self = shift;
    my $tiny = $self->{_tiny};
    unless ($tiny->connection) {
	$tiny->connect;
    }
    return $tiny;
}

=head2 attributes_hashref

  alias to object_to_document

=cut

sub attributes_hashref { shift->object_to_document(@_) }

=head2 object_to_document

  $document = $document_object->object_to_document;

=cut

sub object_to_document {
    # xxx
    my $self = shift;
    my $opt  = shift;
    my $ret  = {};

    for my $field ("_id",$self->field->list) {
	$ret->{$field} = $self->$field();
    }
    return $ret;
}

=head2 collection

  returns MongoDB::Collection

    $collection = $document_object->collection('collection_name');

=cut

sub collection {
    my $self = shift;
    return $self->tiny->collection($self->collection_name);
}

=head2 update


  $document_object->field_name('val');
  $document_object->update;

  #
  $document_object->update($document);

  # only field_name will be changed
  $document_object->update({ field_name => 'val'});

=cut

sub update {
    my $self     = shift;
    my $document = shift;
    my $opt      = shift;
    $opt->{state} = 'update';
    if ($document && ! ref $document eq 'HASH') {
	confess 'invalid document';
    }

    for (keys %{$self->_changed}) {
	$document->{$_} = $self->$_();
    }

    if (!$document) {
	return;
    } else {
	return  unless (keys %$document);
    }

    my $validator = $self->tiny->validate(
	$self->collection_name,$document,$opt
    );

    if ($validator->has_error) {
	confess "invalid document: \n" . (Dumper $validator->errors);
    }
    unless ($opt->{no_trigger}) {
	$self->call_trigger('before_update',$opt);
    }

    $self->collection->update(
	{'_id' => $self->id},{ '$set' => $document }
    );
    $self->$_($document->{$_}) for keys %$document;
    $self->{_changed} = {};

    unless ($opt->{no_trigger}) {
	$self->call_trigger('after_update',$opt);
    }

    return $self;
}

=head2 remove

  $document_object->remove;

=cut

sub remove {
    my $self = shift;
    my $opt  = shift || {};

    unless ($opt->{no_trigger}) {
	$self->call_trigger('before_remove', $opt);
    }

    my $collection = $self->collection;
    $collection->remove({'_id' => $self->id});

    unless ($opt->{no_trigger}) {
	$self->call_trigger('after_remove', $opt);
    }

    bless $self, __PACKAGE__ . '::REMOVED';

    return 1;
}

sub DESTROY {
    # xxx
}

package MongoDBx::Tiny::Document::Accessor;
use strict;
use overload
    '""' => \&data,
    'fallback' => 1;

sub new {
    my $class = shift;
    my $field_info = shift || {}; # { field1 => [sub,sub], field2 => [sub,sub] }
    bless { _data => $field_info }, $class;
}

sub add {
    my $self = shift;
    my ($name,$val) = @_;
    $self->{_data}->{$name} = $val;
}

sub data {
    my $self = shift;
    return $self->{_data};
}

sub list {
    my $self = shift;
    keys %{$self->{_data}};
}

sub get {
    my $self = shift;
    my $name = shift;
    $self->{_data}->{$name};
}

=head2 MongoDBx::Tiny::Document::Field

    my $field = $document_object->field;
  
    my $attr  = $document_object->get('field_name');
    $attr->{name};
    $attr->{callback};
  
    my @field_names     = $field->list;
  
    my @default_fields  = $field->list('DEFAULT');
    my @required_fields = $field->list('REQUIRED')
    my @oid_fields      = $field->list('OID');

=cut

package MongoDBx::Tiny::Document::Field;
use base qw(MongoDBx::Tiny::Document::Accessor);

sub add {
    my $self = shift;
    my ($name,$val) = @_;
    for (@{$val}) {
	# { name => 'name', callback => sub{} }
	unless (defined $_->{name} ) {
	    die q/invalid field attribute: no name/;
	}
	unless (ref $_->{callback} eq 'CODE') {
	    die q/invalid field attribute: invalid callback: / . $_->{name};
	}

	my $req = $self->{_GROUP}->{$_->{name}} || [];
	push @$req, $name;
	$self->{_GROUP}->{$_->{name}} = $req;
    }
    $self->SUPER::add($name,$val);
}

sub list {
    my $self = shift;
    my $name = shift;
    if ($name) {
	my $req = $self->{_GROUP}->{$name} || [];
	return @$req;
    }
    $self->SUPER::list;
}

=head2 MongoDBx::Tiny::Document::Relation;

    my $relation  = $document_object->relation;
    my @relations = $relation->list;

=cut

package MongoDBx::Tiny::Document::Relation;
use base qw(MongoDBx::Tiny::Document::Accessor);

1;
__END__

=head1 AUTHOR

Naoto ISHIKAWA, C<< <toona at seesaa.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Naoto ISHIKAWA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
