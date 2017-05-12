package Object::Recorder;

use warnings;
use strict;

use Memoize;
use Object::Recorder::Storage;

=head1 NAME

Object::Recorder - Records method calls into a serializable data structure

=cut

our $VERSION = '0.01';

# this is a debug switch
# if true will call the underlying objects directly instead of recording
our $BYPASS_STORAGE = 0;

=head1 SYNOPSIS

This module makes it possible to record method calls issued to a set of objects
inti a serializable container which can later be replayed, perfoming the actual
method calls.

    use Object::Recorder;
    
    # start recording method calls to an instance of My::Object
    # will build the object by calling My::Object->new( @params )
    my @params = ('constructor', 'args');
    my $obj = Object::Recorder->record(
        'My::Object', 
        new => @params
    );

    my @args = (1, 2, 'whatever');
    $obj->some_method_call(@args);

    # this object will be blessed directly without calling any constructors
    my $another_obj = Object::Recorder->record('Another::Object');

    # $another_object will only be created when $obj is replayed
    $obj->another_method_call($another_object);

    # it's ok to have return values (currently, only 1 is supported)
    my $return = $another_object->return_something();
    
    # this will DWIM
    $return->call_method_on_returned_value();

And then, somewhere else:

    $obj->replay();

In this case, replaying will perform these steps:

    my $obj1 = My::Object->new('constructor', 'args');
    $obj1->some_method_call(1, 2, 'whatever');

    my $obj2 = bless {}, 'Another::Object';
    $obj1->another_method_call($obj2);

    my $ret = $obj2->return_something();
    $ret->call_method_on_returned_value();

This can be useful for several reasons. For instance, it could be used in the
creation of task objects which would then be processed by a cluster of worker
servers, without the need to update the worker code for each new type of task.

It seems that this feature could also be useful in some sort of caching scheme 
besides being useful in distributed systems in general.

=head1 CLASS METHODS

=head2 record( $class_name, [ $constructor, @args ]

This method starts the recording process and returns an object which can be 
used as if it were an instance of C<$class_name>. If C<$constructor> is not
given, the object will be build by directly C<bless>ing it into the given
C<$class_name>. If C<$constructor> is given, this method will be used as the
constructor method name, which will be called with the given C<@args> (if any).

As a debug helper, if C<$Object::Recorder::BYPASS_STORAGE> is set, this method
will skip the recording process and call the constructor directly. This can be
helpful is something's going wrong.

=cut

sub record         { 
    my $class = shift;
    return $class->create_storage( @_ )
        unless $BYPASS_STORAGE;

    # debug mode: don't record, execute directly
    my ($rec_class, $constructor, @args) = @_;
    return 
        $constructor ? 
            $rec_class->$constructor(@args) : bless {}, $rec_class;
}

=head2 replay

Replays the storage object, performing the stored method calls.

=cut

sub replay {
    my $class = shift;
    my ($store, $obj) = @_;

    my $retval = $class->_replay($store, $obj);

    # cleanup the internal cache after replay calls
    Memoize::flush_cache('_evaluate_arg');
    Memoize::flush_cache('_get_obj');

    return $retval;
}

=head2 storage_class

Should return the storage object's class name (used by C<create_storage>).

=cut

sub storage_class  { 'Object::Recorder::Storage' }

=head2 create_storage

Should return a suitable storage object.

=cut

sub create_storage { shift->storage_class->new(@_) }

# private methods
sub _evaluate_arg {
    my $class = shift;
    my ($obj) = @_;

    return $obj
        unless ref $obj eq $class->storage_class;
    
    return $class->_replay($obj);
}

# memoizes the appropriate methods
memoize('_evaluate_arg');
memoize('_get_obj');

sub _get_obj {
    my $class = shift;
    my ($store, $obj) = @_;

    unless (defined $obj) {
        my $object_class = $store->{object_class};
        
        # make sure the module is loaded
        eval "require $object_class;";

        if (my $constructor = $store->{constructor}) {
            
            my @args = map { $class->_evaluate_arg($_) } @{$store->{args}};

            # we should call a constructor method
            $obj = $object_class->$constructor( @args );
        }
        else {
            # otherwise, create a standard object
            $obj = bless {}, $object_class;
        }
    }

    $store->{expansion_pending} = 1;

    return $obj;
}

sub _replay {
    my $class = shift;
    my ($store, $obj) = @_;

    # return if we're not calling an specific constructor and also don't have
    # any recorded calls
    return if @{$store->{calls}} == 0 and not $store->{constructor};

    die "no object nor object class" 
        if not defined $obj and not $store->{object_class};

    # only create the object if we don't have one yet
    $obj = $class->_get_obj($store, $obj);

    # only expand the object if it's not already being expanded
    if ($store->{expansion_pending}) {
        
        $store->{expansion_pending} = 0;

        for my $call (@{$store->{calls}}) {
            
            my $method = $call->{method};
            
            # expand stored args
            my @args = map { $class->_evaluate_arg($_) } @{$call->{args}};
            
            # recursively replay objects
            $class->_replay($call->{retval}, $obj->$method(@args));
        }
    }

    return $obj;
}

=head1 LIMITATIONS

Currently, this module currently only supports methods calls which have up to a 
single return value and it also doesn't play well with context-sensitive return 
values. This limitation could be worked around but would involve some trickery. 
I'll probably try implementing it if someone asks me to, but it works good 
enough for my own needs.

It won't record direct accesses to the object, only method calls. So if you 
need to fiddle with the object's internal attributes, this module won't work 
for you. Implementing this would require C<tie()>ing the storage object and
recording that, too.

In other words:

    $obj->{some_field} = 'some_value';

won't be recorded.

Patches are welcome.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-object-recorder at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Recorder>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2007 Nilson Santos Figueiredo Junior.
Copyright (C) 2007 Picturetrail, Inc.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
