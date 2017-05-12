package MongoDB::Simple;

use strict;
use warnings;
our $VERSION = '0.005';

use Exporter;
our @EXPORT = qw/ collection string date array object parent dbref boolean oid database locator matches /;

use MongoDB;
use MongoDB::Simple::ArrayType;
use MongoDB::Simple::HashType;

use Switch;
use DateTime;
use DateTime::Format::W3CDTF;
use Data::Dumper;

our %metadata = (); # internal metadata cache used for all packages

{
    # Setup some MongoDB magic
    #
    # Lets us cast MongoDB results into classes
    #     my $obj = db->coll->find_one({criteria})->as('ClassName');
    #     my $obj = $cursor->next->as('ClassName');

    no strict 'refs';
    no warnings 'redefine';

    my $mongodb_find_one = \&{'MongoDB::Collection::find_one'};
    *{'MongoDB::Simple::Collection::find_one::Result::as'} = sub {
        my ($self, $as) = @_;
        return $as->new(doc => $self);
    };

    *{'MongoDB::Collection::find_one'} = sub {
        return mongodb_blessed_result(&$mongodb_find_one(@_));
    };
    my $mongodb_cursor_next = \&{'MongoDB::Cursor::next'};
    *{'MongoDB::Cursor::next'} = sub {
        return mongodb_blessed_result(&$mongodb_cursor_next);
    };

    sub mongodb_blessed_result {
        my ($result) = @_;
        if($result) {
            return bless $result, 'MongoDB::Simple::Collection::find_one::Result';
        }
        return $result;
    }
}

################################################################################
# Object methods                                                               #
################################################################################

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        'client'        => undef, # stores the client (or can be passed in)
        'db'            => undef, # stores the database (or can be passed in)
        'col'           => undef, # stores the collection (or can be passed in)
        'meta'          => undef, # stores the keyword metadata
        'doc'           => {}, # stores the document
        'changes'       => [], # stores changes made since load/save
        'parent'        => undef, # stores the parent object
        'field'         => undef, # stores the field name from the parent object
        'index'         => undef, # stores the index (if the item is in an array)
        'objcache'      => {}, # stores created objects
        'arraycache'    => {}, # stores array objects
        'existsInDb'    => 0,
        'debugMode'     => $ENV{'MONGODB_SIMPLE_DEBUG'} // 0,
        'forceUnshiftOperator' => 0, # forces implementation of unshift to work as expected
        'warnOnUnshiftOperator' => 1, # enables a warning when unshift is used against an array without forceUnshiftOperator
        %args
    }, $class;

    # Get metadata for this class
    $self->{meta} = $self->getmeta;

    # Setup db/collection
    if(!$self->{col}) {
        if(!$self->{db}) {
            if($self->{client} && $self->{meta}->{database}) {
                $self->{db} = $self->{client}->get_database($self->{meta}->{database});
            }
        }
        if($self->{client} && $self->{db} && !$self->{col} && $self->{meta}->{collection}) {
            $self->{col} = $self->{db}->get_collection($self->{meta}->{collection});
        }
    }

    # Inject field methods, done first time object of this type is constructed instead of 
    # build time so we can use field names which clash with helper keywords
    {
        no strict 'refs';
        if(!$self->{meta}->{compiled}) {
            for my $field (keys %{$self->{meta}->{fields}}) {
                my $type = $self->{meta}->{fields}->{$field}->{type};
                $self->log("   -- injecting method for field '$field' as type '$type'");
                switch ($type) {
                    case "string" { *{$class.'::'.$field} = sub { return stringAccessor(shift, $field, @_); } }
                    case "date" { *{$class.'::'.$field} = sub { return dateAccessor(shift, $field, @_); } }
                    case "boolean" { *{$class.'::'.$field} = sub { return booleanAccessor(shift, $field, @_); } }
                    case "array" { *{$class.'::'.$field} = sub { return arrayAccessor(shift, $field, @_); } }
                    case "object" { *{$class.'::'.$field} = sub { return objectAccessor(shift, $field, @_); } }
                    case "dbref" { *{$class.'::'.$field} = sub { return dbrefAccessor(shift, $field, @_); } }
                }
                $self->log("-- creating field $field");
            }
            #addmeta('compiled', 1);
            my $pkg = ref $self;
            $metadata{$pkg}{compiled} = 1;
        }
    }

    return $self;
}

sub log {
    my $self = shift;
    print STDERR (@_, "\n") if $self->{debugMode};
}

sub load {
    my $self = shift;

    my $locator = $self->getLocator(@_);
    my $doc = $self->{col}->find_one($locator);

    if(!$doc) {
        die("Failed to load document with locator: " . (Dumper $locator));
    }

    $self->{existsInDb} = 1;
    $self->{doc} = $doc;
    $self->{changes} = [];
    $self->{callbacks} = [];
    $self->{objcache} = {};
    $self->{arraycache} = {};
}

sub getLocator {
    my ($self, $id) = @_;

    # Use a locator{} block if its defined
    if($self->{meta}->{locator}) {
        my $loc = $self->{meta}->{locator};
        return &$loc($self, $id);
    }

    # If id provided isn't a hash, return a mongodb _id matching hash
    if(ref($id) !~ /HASH/) {
        return {
            "_id" => $id // $self->{doc}->{_id}
        };
    };

    # Otherwise return whatever was passed in
    return $id;
}

sub registerChange {
    my ($self, $field, $change, $value, $callbacks) = @_;

    # called by accessors and child objects/arrays

    # e.g. 
    #   registerChange($self, 'name', '$set', 'Test');
    #   registerChange($self, 'tags', '$push', 'Tag');

    # if no parent, store in {changes}
    # if parent -> parent->registerChange
    #   registerChange($self, $self->{field} . '.' . $field, $change, $value);
    
    $self->log("registerChange: field[$field], change[$change], value[" . ($value ? $value : '<undef>') . "]");

    if($self->{parent}) {
        $self->log("  -- passing to parent (index: " . (defined $self->{index} ? $self->{index} : 'none') . ")");
        $self->{parent}->registerChange($self->{field} . ( defined $self->{index} ? '.' . $self->{index} : '' ) . '.' . $field, $change, $value, $callbacks);
        return;
    }

    push @{$self->{changes}}, {
        field => $field,
        change => $change,
        value => $value,
        callbacks => $callbacks
    };

    # change saving to just run all updates in order
    # if we do all $set's like we do now, we can't do this and expect it to work:
    #    $obj->arraytype(['a','b','c']);
    #    pop $obj->arraytype;
    #    $obj->arraytype(['a','b','c']);
    #    $obj->save; # arraytype now contains ['a','b'] since pop happened after both sets
}

sub save {
    my ($self) = @_;

    if($self->{existsInDb}) {
        $self->log("Save::");
        $self->log("Exists in db, locator: " . $self->getLocator);

        # We'll update in a particular order
        $self->log("Changes::");
        $self->log(Dumper $self->{changes});

        # TODO can optimise changes, e.g. collapsing array operations

        for my $change (@{$self->{changes}}) {
            if($change->{change} eq '$unshift') {
                # rewrite array - $unshift needs to set the field as array and value as array, not as array item
                $self->{col}->update($self->getLocator, {
                    '$set' => {
                        $change->{field} => $change->{value}
                    }
                });
            } else {
                if($change->{change} eq '$shift') {
                    $change->{change} = '$pop';
                    $change->{value} = -1;
                } 
                $self->{col}->update($self->getLocator, {
                    $change->{change} => {
                        $change->{field} => $change->{value}
                    }
                });
            }
            if($change->{callbacks}) {
                $self->log("Running callbacks for field " . $change->{field});
                for my $cb (@{$change->{callbacks}}) {
                    &$cb;
                }
            }
        }
        
        # Changes here are saved too, also empty array
        $self->{changes} = [];
    } else {
        my $obj = {};
        $self->log("Save:: insert");
        for my $field (keys %{$self->{meta}->{fields}}) {
            $self->log("checking field $field");
            # TODO perhaps should be a difference between unset and undefined?
            if($self->$field) {
                $self->log("field $field has a value: " . $self->$field);
                if($self->{meta}->{fields}->{$field}->{type} =~ /array/i) {
                    $self->log("field $field is an array");
                    $obj->{$field} = $self->{arraycache}->{$field}->{objref}->{doc};
                } elsif ($self->{meta}->{fields}->{$field}->{type} =~ /object/i) {
                    $self->log("field $field is an object");
                    my $o = $self->$field;
                    $self->log(Dumper $o);
                    $self->log(ref $o);
                    $obj->{$field} = ref $o eq 'HASH' ? $o : $o->{doc};
                } else {
                    $self->log("field $field is a scalar:");
                    $self->log(Dumper $self->$field);
                    $obj->{$field} = $self->$field;
                }
            }
        }

        $self->log(Dumper $obj);
        my $id = $self->{col}->insert($obj);
        $self->{existsInDb} = 1;
        # TODO what about inner object changes
        $self->{changes} = [];
        $self->log(Dumper $id);
        return $id;
    }
}

sub hasChanges {
    my ($self) = @_;

    return scalar @{$self->{changes}} > 0 ? 1 : 0;
}

sub dump {
    my ($self) = @_;

    $self->log("Dumping " . (ref $self));
    for my $field ( keys %{$self->{meta}->{fields}} ) {
        $self->log("    $field => " . $self->$field);
    }
}

################################################################################
# Accessor methods                                                             #
################################################################################

sub lookForCallbacks {
    my ($self, $field, $value, $type) = @_;

    my @callbacks = ();
    $self->log("lookForCallbacks: field[$field], value[" . ($value ? $value : '<undef>') . "]");
    if(!$type || $type eq '$set') {
        if($self->{meta}->{fields}->{$field}->{args}->{changed}) {
            $self->log("lookForCallbacks: adding 'changed' callback for field '$field'");
            push @callbacks, sub {
                my $cb = $self->{meta}->{fields}->{$field}->{args}->{changed};
                $self->log("callback capture: field[$field], value[" . ($value ? $value : '<undef>') . "]");
                &$cb($self, $value);
            };
        }
    }
    if($self->{meta}->{fields}->{$field}->{type} && $self->{meta}->{fields}->{$field}->{type} eq 'array') {
        for my $callback ("push", "pop", "shift", "unshift") {
            next if $type && $type ne "\$$callback";

            if($self->{meta}->{fields}->{$field}->{args}->{$callback}) {
                $self->log("lookForCallbacks: adding '$callback' callback for field '$field'");
                push @callbacks, sub {
                    my $cb = $self->{meta}->{fields}->{$field}->{args}->{$callback};
                    $self->log("callback capture: field[$field], value[" . ($value ? $value : '<undef>') . "]");
                    &$cb($self, $value);
                };
            }
        }
    }
    return \@callbacks;
}
sub defaultAccessor {
    my ($self, $field, $value) = @_;

    $self->log("defaultAccessor: field[$field], value[" . ($value ? $value : '<undef>') . "]");

    if(scalar @_ <= 2) {
        return $self->{doc}->{$field};
    }

    return if $self->{doc} && $value && $self->{doc}->{$field} && $value eq $self->{doc}->{$field};

    my $callbacks = $self->lookForCallbacks($field, $value);
    $self->registerChange($field, '$set', $value, $callbacks);
    # XXX unsure if we want to set doc or not.... if we do, it makes insert/upsert easier
    $self->{doc}->{$field} = $value;
}

sub stringAccessor {
    return defaultAccessor(@_);
}
sub booleanAccessor {
    return defaultAccessor(@_);
}
sub dateAccessor {
    my ($self, $field, $value) = @_;

    if(scalar @_ <= 2) {
        $value = $self->{doc}->{$field};
        $value = DateTime::Format::W3CDTF->new->parse_datetime($value) if $value;
        return $value;
    }

    if(ref($value) =~ /DateTime/) {
        $value = DateTime::Format::W3CDTF->new->format_datetime($value);
    }

    return if $self->{doc} && $value && $self->{doc}->{$field} && $value eq $self->{doc}->{$field};

    my $callbacks = $self->lookForCallbacks($field, $value);
    $self->registerChange($field, '$set', $value, $callbacks);
    # XXX unsure if we want to set doc or not.... if we do, it makes insert/upsert easier
    $self->{doc}->{$field} = $value;
}
sub arrayAccessor {
    my ($self, $field, $value) = @_;

    if(scalar @_ <= 2) {
        if($self->{arraycache}->{$field}) {
            return $self->{arraycache}->{$field}->{arrayref};
        }

        my @arr;
        my $docval = $self->{doc}->{$field};
        if($docval) {
            for my $item (@$docval) {
                my $type = $self->{meta}->{fields}->{$field}->{args}->{type};
                my $types = $self->{meta}->{fields}->{$field}->{args}->{types};
                if($type) {
                    push @arr, $type->new(parent => $self, doc => $item, field => $field, index => scalar @arr);
                } elsif ($types) {
                    my $matched = 0;
                    for my $type (@$types) {
                        if($metadata{$type}->{matches}) {
                            my $matcher = $metadata{$type}->{matches};
                            my $matches = &$matcher($item);
                            if($matches) {
                                push @arr, $type->new(parent => $self, doc => $item, field => $field, index => scalar @arr);
                                $matched = 1;
                                last;
                            }
                        }
                    }
                    if(!$matched) {
                        die('No type matched current document: ' . Dumper $item);
                    }
                } else {
                    push @arr, $item;
                }
            }

            my $a = tie my @array, 'MongoDB::Simple::ArrayType', parent => $self, field => $field, array => \@arr;
            $self->{arraycache}->{$field} = {
                arrayref => \@array,
                objref => $a
            };
            return \@array;
        }

        return undef;
    }

    return if $self->{doc} && $value && $self->{doc}->{$field} && $value eq $self->{doc}->{$field};

    if(!tied($value)) {
        my @array;
        my $a = tie @array, 'MongoDB::Simple::ArrayType', parent => $self, field => $field;
        $self->{arraycache}->{$field} = {
            arrayref => \@array,
            objref => $a
        };
        push @array, @$value;
        $value = $a->{array};
        #$value = \@array;
    }

    # Don't think we want to do this... it causes an array to be seen as a change, but its handled separately
    # $self->{changes}->{$field} = $value;
    #$self->registerChange($field, '$set', $value, $callbacks);

    # XXX unsure if we want to set doc or not.... if we do, it makes insert/upsert easier
    $self->{doc}->{$field} = $value;

    #$self->lookForCallbacks($field, $value);
}
sub objectAccessor {
    my ($self, $field, $value) = @_;

    my $type = $self->{meta}->{fields}->{$field}->{args}->{type};
    my $obj;

    if(scalar @_ <= 2) {
        if(defined $self->{doc}->{$field}) {
            if($type) {
                if($self->{objcache}->{$field}) {
                    return $self->{objcache}->{$field};
                }
                $obj = $type->new(parent => $self, doc => $self->{doc}->{$field}, field => $field);
                $self->{objcache}->{$field} = $obj;
                return $obj;
            } else {
                if($self->{objcache}->{$field}) {
                    $self->log("Returning already tied hash for field [$field] on getter");
                    #return $self->{objcache}->{$field}->{hash};
                    return $self->{objcache}->{$field}->{hashref};
                }
                my %hashx = (%{$self->{doc}->{$field}});
                $self->log("Tying hash for field [$field] on getter");
                $obj = tie %hashx, 'MongoDB::Simple::HashType', hash => $self->{doc}->{$field}, parent => $self, field => $field;
                $self->{objcache}->{$field} = {
                    objref => $obj,
                    hashref => \%hashx
                };
                #$self->{doc}->{$field} = \%hashx;
                return $self->{doc}->{$field};
            }
        } else {
            return undef;
        }
    }

    if(ref($value) !~ /^HASH$/) {
        $self->{objcache}->{$field} = $value;
        $value->{parent} = $self;
        $value->{field} = $field;
        $value = $value->{doc};
    } else {
        if(!tied($value)) {
            my %hashx;
            $self->log("Tying hash for field [$field] on setter");
            my $obj = tie %hashx, 'MongoDB::Simple::HashType', hash => $value, parent => $self, field => $field;
            $self->{objcache}->{$field} = {
                objref => $obj,
                hashref => \%hashx
            };
        }
    }
    return if $self->{doc} && $value && $self->{doc}->{$field} && $value eq $self->{doc}->{$field};

    my $callbacks = $self->lookForCallbacks($field, $value);
    $self->registerChange($field, '$set', $value, $callbacks);
    # XXX unsure if we want to set doc or not.... if we do, it makes insert/upsert easier
    $self->{doc}->{$field} = $value;
} 
sub dbrefAccessor {
    return defaultAccessor(@_);
}

################################################################################
# Static methods                                                               #
################################################################################

sub import {
    my $class = caller;
#    push @{"$class::ISA"}, $_[0];
    $Exporter::ExportLevel = 1;
    Exporter::import(@_);
}

sub addmeta {
    my ($key, $meta) = @_;
    my $pack = caller 1;
    $metadata{$pack}{$key} = $meta;
    #print "addmeta: adding '$key' to $pack\n";
}
sub addfieldmeta {
    my ($field, $meta) = @_;
    my $pack = caller 1;
    $metadata{$pack}{'fields'}{$field} = $meta;
    #print "addfield: adding '$field' to $pack fields\n";
}

sub getmeta {
    my ($self) = @_;
    my $pack = ref $self;
    #print "getmeta: $pack\n";
    return \%{$metadata{$pack}};
}

sub package_start {
    my $class = caller 1;
    #print "-" x 80;
    #print "\n";
    #print "MongoDB:: Package '$class'\n";
}

sub oid {
    my ($id) = @_;
    return new MongoDB::OID(value => $id);
}

################################################################################
# Keywords                                                                     #
################################################################################

sub locator {
    my ($locator) = @_;
    addmeta("locator", $locator);
}

sub matches {
    my ($matches) = @_;
    addmeta("matches", $matches);
}

sub database {
    my ($database) = @_;
    addmeta("database", $database);
    #print STDERR "MongoDB:: database '$database'\n";
}

sub collection {
    my ($collection) = @_;
    package_start;
    addmeta("collection", $collection);
    #print STDERR "MongoDB:: collection '$collection'\n";
}

sub parent {
    my (%hash) = @_;
    package_start;
    addmeta("parent", \%hash);
    #print STDERR "MongoDB:: parent { type => '$hash{type}', key => '$hash{key}' }\n";
}

sub string {
    my ($key, $args) = @_;
    addfieldmeta($key, { type => 'string', args => $args });
    #print STDERR "MongoDB:: string '$key' => $value\n";
}

sub date {
    my ($key, $args) = @_;
    addfieldmeta($key, { type => 'date', args => $args });
    #print STDERR "MongoDB:: date '$key' => $value\n";
}

sub dbref {
    my ($key, $args) = @_;
    #print STDERR "MongoDB:: dbref '$key' =>\n";
    addfieldmeta($key, { type => 'dbref', args => $args });
    for my $ref ( keys %$args ) {
        #print STDERR "    - '$ref' => $args->{$ref}\n";
    }
}

sub boolean {
    my ($key, $args) = @_;
    addfieldmeta($key, { type => 'boolean', args => $args });
    #print STDERR "MongoDB:: boolean '$key' => $value\n";
}

sub array {
    my ($key, $args) = @_;
    addfieldmeta($key, { type => 'array', args => $args });
    #print STDERR "MongoDB:: array '$key' => { type => '$args->{type}' }\n";
}

sub object {
    my ($key, $args) = @_;
    addfieldmeta($key, { type => 'object', args => $args });
    #print STDERR "MongoDB:: object '$key' => { type => '$args->{type}' }\n";
}

    my ($self, @args) = @_;

=head1 NAME

MongoDB::Simple

=head1 SYNOPSIS

    package My::Data::Class;
    use base 'MongoDB::Simple';
    use MongoDB::Simple;

    database 'dbname';
    collection 'collname';

    string 'stringfield' => {
        "changed" => sub {
            my ($self, $value) = @_;
            # ... called when changes to 'stringfield' are saved in database
        }
    };
    date 'datefield';
    boolean 'booleanfield';
    object 'objectfield';
    array 'arrayfield';
    object 'typedobject' => { type => 'My::Data::Class::Foo' };
    array 'typedarray' => { type => 'My::Data::Class::Bar' };
    array 'multiarray' => { types => ['My::Data::Class::Foo', 'My::Data::Class::Bar'] };

    package My::Data::Class::Foo;

    parent type => 'My::Data::Class', key => 'typedobject';

    matches sub {
        my ($doc) = @_;
        my %keys = map { $_ => 1 } keys %$doc;
        return 1 if (scalar keys %keys == 1) && $keys{fooname};
        return 0;
    }

    string 'fooname';

    package My::Data::Class::Bar;

    parent type => 'My::Data::Class', key => 'typedarray';

    matches sub {
        my ($doc) = @_;
        my %keys = map { $_ => 1 } keys %$doc;
        return 1 if (scalar keys %keys == 1) && $keys{barname};
        return 0;
    }

    string 'barname';

    package main;

    use MongoDB;
    use DateTime;

    my $mongo = new MongoClient;
    my $cls = new My::Data::Class(client => $mongo);

    $cls->stringfield("Example string");
    $cls->datefield(DateTime->now);
    $cls->booleanfield(true);
    $cls->objectfield({ foo => "bar" });
    push $cls->arrayfield, 'baz';

    $cls->typedobject(new My::Data::Class::Foo);
    $cls->typedobject->fooname('Foo');

    my $bar = new My::Data::Class::Bar;
    $bar->barname('Bar');
    push $cls->typedarray, $bar;

    my $id = $cls->save;

    my $cls2 = new My::Data::Class(client => $mongo);
    $cls2->load($id);

=head1 DESCRIPTION

L<MongoDB::Simple> simplifies mapping of MongoDB documents to Perl objects.

=head1 SEE ALSO

Documentation needs more work - refer to the examples in the t/test.t file.

=head1 AUTHORS

Ian Kent - <iankent@cpan.org> - original author

=head1 COPYRIGHT AND LICENSE

This library is free software under the same terms as perl itself

Copyright (c) 2013 Ian Kent

MongoDB::Simple is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the license for more details.

=cut

1;
