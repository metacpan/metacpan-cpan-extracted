package SPOPS::Iterator;

# $Id: Iterator.pm,v 3.4 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base  qw( Exporter );
use Log::Log4perl qw( get_logger );
use SPOPS;

$SPOPS::Iterator::VERSION   = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);
@SPOPS::Iterator::EXPORT_OK = qw( ITER_IS_DONE ITER_FINISHED );

use constant ITER_POSITION      => '_position';
use constant ITER_NEXT_POSITION => '_count';
use constant ITER_NEXT_VALUE    => '_current';
use constant ITER_IS_DONE       => 'DONE';
use constant ITER_FINISHED      => 'FINISHED';

my $log = get_logger();

sub has_next { return defined $_[0]->{ ITER_NEXT_VALUE() }; }

sub position { return $_[0]->{ ITER_POSITION() }; }

sub is_first { return $_[0]->{ ITER_POSITION() } == 1; }

sub is_last  { return $_[0]->is_done; }

sub is_done  { return ! defined $_[0]->{ ITER_NEXT_VALUE() }; }


sub get_next {
    my ( $self ) = @_;
    $log->is_info &&
        $log->info( "Calling", ref $self, "get_next()" );
    my $obj = $self->{ ITER_NEXT_VALUE() };
    $self->{ ITER_POSITION() } = $self->{ ITER_NEXT_POSITION() };
    if ( defined $obj ) {
        $log->is_info &&
            $log->info( "Object retrieved from holding. Trying to load_next()" );
        $self->load_next;
    }
    return $obj;
}


sub get_all {
    my ( $self ) = @_;
    $log->is_info &&
        $log->info( "Retrieving remainder of objects with get_all()" );
    my @object_list = ();
    while ( my $object = $self->get_next ) {
        push @object_list, $object;
    }
    return \@object_list;
}


sub discard {
    my ( $self ) = @_;
    $log->is_info &&
        $log->info( "Discarding remainder of values at $self->{ ITER_POSITION() }" );
    $self->{ ITER_NEXT_VALUE() }    = undef;
    $self->{ ITER_NEXT_POSITION() } = undef;
    $self->finish;
}


sub new {
    my ( $pkg, $params ) = @_;
    my $class = ref $pkg || $pkg;
    $log->is_info &&
        $log->info( "Trying to create a new iterator of class ($class)" );
    my $self = bless( { ITER_POSITION()       => 0,
                        ITER_NEXT_POSITION()  => 0,
                        ITER_NEXT_VALUE()     => undef }, $class );
    $self->{_CLASS}         = $params->{class};
    $self->{_SKIP_SECURITY} = $params->{skip_security};
    $self->{_FIELDS}        = $params->{fields};

    # Let potential errors bubble up from this method
    $self->initialize( $params );

    $self->load_next;
    return $self;
}


sub initialize   { 
    my ( $self ) = @_;
    $log->is_info &&
        $log->info( "Calling initialize() in parent class, which is likely a bad thing. ",
                      "Implementation (", ref $self, ") should override" );
    return 1;
}


sub fetch_object { 
    my ( $self ) = @_;
    $log->is_info &&
        $log->info( "Calling fetch_object() in parent class, which is a bad thing. ",
                      "Implementation (", ref $self, ") should override" );
    return undef;
}


sub load_next {
    my ( $self ) = @_;
    my @next_info = $self->fetch_object;
    if ( ! defined $next_info[0] || $next_info[0] eq ITER_IS_DONE ) {
        $log->is_info &&
            $log->info( "load_next() got ITER_IS_DONE; cleaning up" );
        $self->finish;
        $self->{ ITER_NEXT_VALUE() }    = undef;
        $self->{ ITER_NEXT_POSITION() } = undef;
    }
    else {
        $log->is_info &&
            $log->info( "load_next() retrieved a new object and put into holding." );
        $self->{ ITER_NEXT_VALUE() }    = $next_info[0];
        $self->{ ITER_NEXT_POSITION() } = $next_info[1];
    }
}


sub finish { 
    my ( $self ) = @_;
    $log->is_info &&
        $log->info( "Calling finish() in parent class. This is ok." );
    return $self->{ ITER_FINISHED() } = 1;
}


sub DESTROY {
    my ( $self ) = @_;
    $self->finish unless ( $self->{ ITER_FINISHED() } );
}


sub from_list {
    my ( $class, $list ) = @_;
    require SPOPS::Iterator::WrapList;
    return SPOPS::Iterator::WrapList->new({ object_list => $list });
}

1;

__END__

=pod

=head1 NAME

SPOPS::Iterator - Class to cycle through results and return SPOPS objects

=head1 SYNOPSIS

 my $iter = $spops_class->fetch_iterator({ where => 'last_name like ?',
                                           value => [ 'smi%' ] });
 while ( $iter->has_next ) {
     my $object = $iter->get_next;
     print "Object ID: ", $object->id, " at position: ",
           $iter->position, "\n";
 }

=head1 DESCRIPTION

One of the problems with current SPOPS implementations is that
retrieving groups of objects is an all-or-nothing affair -- you get a
list with all instantiated objects or you do not retrive them in the
first place. This can be quite memory intensive, particularly when a
user executes a query that can return thousands of objects back at one
time.

This class -- or, more specifically, implementations of the interface
in this class -- aims to change that. Instead of returning a list of
objects from a group retrieval, you get back an C<SPOPS::Iterator>
object. This object has a simple interface to cycle forward through
objects and let you deal with them one at a time.

It does not keep track of these for you -- once you request the SPOPS
object through the C<get_next()> call, the iterator loses track of it. The
iterator does keep track of the current count (on a 1-based scheme)
and whether you are currently 'on' the first or last element.

It is important to state that this works within the realm of other
SPOPS capabilities -- just like the C<fetch_group()> method, all
objects returned will get checked for security, and if a user cannot
see a certain object it does not get returned and the iterator moves
onto the next object.

As a result, users will B<never> create an C<SPOPS::Iterator> object
themselves. Instead, the object is returned from a method in a SPOPS
implementation class, such as C<SPOPS::DBI>.

The initial module documentation is for the interface; there is also a
section of creating a subclass of this module for SPOPS authors.

=head1 PUBLIC METHODS

B<has_next()>

Returns boolean value: true if there are further values to retrieve,
false if not.

Example:

  my $iter = $spops_class->fetch_iterator({ where => "active = 'yes'" });
  while ( $iter->has_next ) {
    ...
  }

Note that calling C<has_next()> on an iterator does not advance it
through the list of SPOPS objects. To advance the iterator you must
call C<get_next()>. A common error might be something like:

 my $iter = $spops_class->fetch_iterator({ where => "active = 'yes'" });
 while ( $iter->has_next ) {
    print "On record number: ", $iter->position, "\n";
 }

Which will simply print:

 On record number: 1
 On record number: 1
 On record number: 1
 On record number: 1
 ...

Since the iterator is never advancing.

B<position()>

Returns the position of the last item fetched.

So if you start up an iterator and execute the following code:

 my $iter = $spops_class->fetch_iterator({ where => "active = 'yes'" });
 my $obj = $iter->get_next;
 print "Position is: ", $iter->position, "\n";
 my $another_obj = $iter->get_next;
 print "Position is: ", $iter->position, "\n";

It would print:

 Position is: 1
 Position is: 2

Note that if you have specified to retrieve only a certain number of
records the position will indicate this:

 my $iter = $spops_class->fetch_iterator({ ..., limit => '10,20' });
 my $obj = $iter->get_next;
 print "Position is: ", $iter->position, "\n";
 my $another_obj = $iter->get_next;
 print "Position is: ", $iter->position, "\n";

Would print:

 Position is: 10
 Position is: 11

Since you requested to fetch the values from 10 to 20.

B<is_first()>

Returns true if the last item fetched is the first one.

B<is_last()>

Returns true is the lsat item fetched is the last one.

B<is_done()>

Alias for B<is_last()>

B<get_next()>

Returns next SPOPS object in the iterator if there is one to return,
or C<undef> otherwise.  Also advances the iterator to the next
element. Should be wrapped in an C<eval> block to trap errors. If an
error is generated you can get the message from C<$@> and also get
additional information by requesting:

  my $error_info = SPOPS::Error->get;

Example:

  my $iter = $spops_class->fetch_iterator({ where => "active = 'yes'" });
  while ( $iter->has_next() ) {
      my $object = $iter->get_next;
      my $related_objects = $object->related;
      ...
  }

You can also do this:

  my $iter = $spops_class->fetch_iterator({ where => "active = 'yes'" });
  while ( my $object = $iter->get_next ) {
     my $related_objects = $object->related;
     ...
  }

This is arguably the more perlish way to do it, and both interfaces
are currently supported.

B<get_all()>

Returns an arrayref of all remaining SPOPS objects in the iterator.

Example:

  my $iter = $spops_class->fetch_iterator({ where => "active = 'yes'" });
  my $object_one = $iter->get_next;
  my $object_two = $iter->get_next;
  my $object_remaining_list = $iter->get_all();

B<discard()>

Tells the iterator that you are done with the results and that it can
perform any cleanup actions. The iterator will still exist after you
call C<discard()>, but you cannot fetch any more records, the
C<is_done()> method will return true and the C<position()> method will
return the position of the last item fetched.

The C<is_last()> method will also return true. This might seem
counterintuitive since you never reached the end of the iterator, but
since you closed the iterator yourself this seems the right thing to
do.

Example:

  my $iter = $spops_class->fetch_iterator({ where => "active = 'yes'" });
  my ( $penguin );
  while ( my $object = $iter->get_next ) {
      if ( $object->{last_name} eq 'Lemieux' ) {
          $penguin = $object;
          $iter->discard;
          last;
      }
      print "Player $object->{first_name} $object->{last_name} is not Mario.\n";
  }

B<from_list( \@objects )>

As a convenience you can create an iterator from an existing list of
objects. The utility of this might not be immediately obvious -- if
you already have a list, what do you need an iterator for? But this
allows you to create one set of code for object lists while allowing
your code to accept both object lists and object iterators. For
instance:

 unless( $params->{iterator} {
     $params->{iterator} = SPOPS::Iterator->from_list( $params->{list} );
 }
 my $template = Template->new;
 $template->process( \*DATA, $params );

 __DATA__

 Object listing:

 [% WHILE ( object = iterator.get_next ) -%]
       Object: [% object.name %] (ID: [% object.id %])
 [% END -%]

=head1 INTERNAL DOCUMENTATION

Methods documented below are not meant to be called by users of an
iterator object. This documentation is meant for SPOPS driver authors
who need to implement their own C<SPOPS::Iterator> subclasses.

=head2 Subclassing SPOPS::Iterator

Creating a subclass of C<SPOPS::Iterator> is quite easy. Subclass
authors only need to override the following methods:

=over 4

=item *

B<initialize()>

=item *

B<fetch_object()>

=item *

B<finish()>

=back

Everything else is done for you.

B<new( \%params )>

The constructor is generally called behind the scenes -- the only
people having to deal with it are SPOPS driver authors.

The constructor takes a single hashref for an argument. The keys and
values of the hashref depend on the driver implementation, but some
consistent ones are:

=over 4

=item *

B<where>: Set conditions for fetching

=item *

B<value>: Set values to be used in the where clause

=item *

B<skip_security>: Set to true if you want to skip security checks.

=item *

B<skip_cache>: Set to true if you want to bypass the cache. (Since the
cache is not yet implemented, this has no effect.)

=item *

B<limit>: Either a max value ('n') or an offset and max ('m,n') which
limits the return results. This way you can run a query to fetch lots
of objects but only have the iterator return objects 30 - 39.

=back

The constructor should do all the work necessary to setup a query,
take the returned setup value and keep it around so it can call on it
repeatedly as requested.

B<initialize( \%params )>

Coders implementing the interface of C<SPOPS::Iterator> should create
a method C<initialize()> which takes the values passed into C<new()>
and gets the iterator ready to rumble. This might be preparing a SQL
statement and executing it, or opening up a file and positioning the
seek at the first record: whatever.

There is no return value from this method. If you encounter an error
you should throw a L<SPOPS::Exception|SPOPS::Exception> object or
appropriate subclass.

B<fetch_object()>

Internal method that must be overridden by a C<SPOPS::Iterator>
implementation. This is what actually does the work for retrieving the
next object.

Return value is a list with two members. The first is the object
returned, the second is the count of the object. This count becomes
the return value for C<position()>.

If the list is exhausted, simply return the constant C<ITER_IS_DONE>,
which is exported from C<SPOPS::Iterator>.

B<load_next()>

Loads the object into the 'next' slot.

B<finish()>

Internal method for cleaning up resources. It is called when the user
calls C<discard()> on an iterator, when the C<fetch_object()> method
returns that it is done and, as a last resort, when the iterator
object is garbage-collected and the C<DESTROY()> method called.

If necessary, C<SPOPS::Iterator> implementors should override this
method to perform whatever cleanup actions are necessary for the
iterator -- closing the database statement handle, closing the file,
etc. If you do not override it we tell the object it is finished and
no cleanup is done beyond what is done normally by Perl when variables
go out of scope.

Note that the overridden method should set:

 $self->{ ITER_FINISHED() }

to a true value to let the iterator know that it has been cleaned
up. This way we will not call C<finish()> a second time when the
object is garbage-collected.

B<DESTROY()>

Ensure that an iterator is properly cleaned up when it goes out of
scope.

=head1 BUGS

None yet!

=head1 TO DO

B<Provide more 'position' management>

Subclasses generally need to maintain the position themselves, which
can be irritating.

B<Relationship calls return iterators>

Relationship calls (for relationships created by
L<SPOPS::ClassFactory|SPOPS::ClassFactory> and/or one of its utilized
behaviors) should be modified to optionally return an
C<SPOPS::Iterator> object. So you could do:

  my $iter = $user->group({ iterator => 1 });
  while ( my $group = $iter->get_next ) {
       print "User is in group: $group->{name}\n";
  }

Other options:

  my $iter = $user->group_iterator();
  my $iter = $user->relation_iterator( 'group' );

=head1 SEE ALSO

L<SPOPS|SPOPS>

L<Template::Iterator|Template::Iterator>

Talks and papers by Mark-Jason Dominus on infinite lists and
iterators. (See: http://www.plover.com/perl/)

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

=cut
