package SPOPS::Exception;

# $Id: Exception.pm,v 3.5 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base qw( Class::Accessor Exporter );
use overload '""' => \&stringify;
use Devel::StackTrace;
use SPOPS::Error;

$SPOPS::Exception::VERSION   = sprintf("%d.%02d", q$Revision: 3.5 $ =~ /(\d+)\.(\d+)/);
@SPOPS::Exception::EXPORT_OK = qw( spops_error );

use constant DEBUG => 0;

my @STACK  = ();
my @FIELDS = qw( message package filename line method trace );
SPOPS::Exception->mk_accessors( @FIELDS );

########################################
# SHORTCUT

sub spops_error { goto &throw( 'SPOPS::Exception', @_ ) }


########################################
# CLASS METHODS

sub throw {
    my ( $class, @message ) = @_;

    if ( ref $message[0] ) {
        my $rethrown = $message[0];
        if ( UNIVERSAL::isa( $rethrown, __PACKAGE__ ) ) {
            die $rethrown;
        }
    }

    my $params = ( ref $message[-1] eq 'HASH' )
                   ? pop( @message ) : {};
    my $msg    = join( '', @message );

    my $self = bless( {}, $class );

    # Do all the fields

    foreach my $field ( $self->get_fields ) {
        $self->$field( $params->{ $field } ) if ( $params->{ $field } );
    }

    # Now do the message and the initial trace stuff

    $self->message( $msg );

    my @initial_call = caller;
    $self->package( $initial_call[0] );
    $self->filename( $initial_call[1] );
    $self->line( $initial_call[2] );

    # Grab the method name separately, since the subroutine call
    # doesn't seem to be matched up properly with the other caller()
    # stuff when we do caller(0). Weird.

    my @added_call = caller(1);
    $added_call[3] =~ s/^.*:://;
    $self->method( $added_call[3] );

    $self->trace( Devel::StackTrace->new );

    DEBUG && warn "[$class] thrown: ", $self->message, "\n";

    $self->initialize( $params );

    push @STACK, $self;

    # BACKWARDS COMPATIBILITY (will remove before 1.0)

    $self->fill_error_variables;

    die $self;
}

sub initialize {}

sub get_fields { return @FIELDS }

sub get_stack   { return @STACK }
sub clear_stack { @STACK = ()   }


########################################
# OBJECT METHODS

sub creation_location {
    my ( $self ) = @_;
    return 'Created in package [' . $self->package . '] ' .
           'in method [' . $self->method . ']; ' .
           'at file [' . $self->filename . '] ' .
           'at line [' . $self->line . ']';
}

sub stringify   { return $_[0]->to_string() }

sub to_string   {
    my ( $self ) = @_;
    my $class = ref $self;
    return "Invalid -- not called from object."  unless ( $class );

    no strict 'refs';
    return $self->message()                      unless ( ${ $class . '::ShowTrace' } );
    return join( "\n", $self->message, $self->trace->as_string );
}

# BACKWARDS COMPATIBILITY (will remove before 1.0)

sub fill_error_variables {
    my ( $self ) = @_;
    SPOPS::Error->set({ user_msg => $self->message,  system_msg => $self->message,
                        package  => $self->package,  method     => $self->method,
                        filename => $self->filename, line       => $self->line });
}

1;

__END__

=head1 NAME

SPOPS::Exception - Base class for exceptions in SPOPS

=head1 SYNOPSIS

 # As a user

 use SPOPS::Exception;

 eval { $user->save };
 if ( $@ ) {
    print "Error: $@",
          "Stack trace: ", $@->trace->as_string, "\n";
 }

 # Get all exceptions (including from subclasses that don't override
 # throw()) since the stack was last cleared

 my @errors = SPOPS::Exception->get_stack;
 print "Errors found:\n";
 foreach my $e ( @errors ) {
    print "ERROR: ", $e->message, "\n";
 }

 # As a developer

 use SPOPS::Exception;

 my $rv = eval { $dbh->do( $sql ) };
 if ( $@ ) {
     SPOPS::Exception->throw( $@ );
 }

 # Use the shortcut

 use SPOPS::Exception qw( spops_error );
 my $rv = eval { $dbh->do( $sql ) };
 spops_error( $@ ) if ( $@ );

 # Throw an exception that subclasses SPOPS::Exception with extra
 # fields

 my $rv = eval { $dbh->do( $sql ) };
 if ( $@ ) {
     SPOPS::Exception::DBI->throw( $@, { sql    => $sql,
                                         action => 'do' } );
 }

 # Throw an exception with a longer message and parameters

 SPOPS::Exception->throw( "This is a very very very very ",
                          "very long message, even though it ",
                          "doesn't say too much.",
                          { action => 'blah' } );

 # Catch an exception, do some cleanup then rethrow it

 my $rv = eval { $object->important_spops_operation };
 if ( $@ ) {
     my $exception = $@;
     close_this_resource();
     close_that_resource();
     SPOPS::Exception->throw( $exception );
 }

=head1 DESCRIPTION

This class is the base for all exceptions in SPOPS. An exception is
generally used to indicate some sort of error condition rather than a
situation that might normally be encountered. For instance, you would
not throw an exception if you tried to C<fetch()> a record not in a
datastore. But you would throw an exception if the query failed
because the database schema was changed and the SQL statement referred
to removed fields.

This module replaces C<SPOPS::Error> and the error handling it
used. There is a backwards compatible function in place so that the
variables get set in C<SPOPS::Error>, but this is not permanent. If
you use these you should modify your code ASAP.

You can easily create new classes of exceptions if you like, see
L<SUBCLASSING> below.

=head1 METHODS

=head2 Class Methods

B<throw( $message, [ $message...], [ \%params ] )>

B<throw( $exception )>

This is the main action method and normally the only one you will ever
use. The most common use is to create a new exception object with the
message consisting of all the parameters concatenated
together.

More rarely, you can pass another exception object as the first
argument. If you do we just rethrow it -- the original stack trace and
all information should be maintained.

Additionally with the common use: if the last argument is a hashref we
add the additional information from it to the exception, as
supported. (For instance, you can write a custom exception to accept a
'module' parameter which declares which of the plugins to your
accounting system generated the error.)

Once we create the exception we then call C<die> with the
object. Before calling C<die> we first do the following:

=over 4

=item 1.

Check C<\%params> for any parameters matching fieldnames returned by
C<get_fields()>, and if found set the field in the object to the
parameter.

=item 2.

Fill the object with the relevant calling information: C<package>,
C<filename>, C<line>, C<method>.

=item 3.

Set the C<trace> property of the object to a
L<Devel::StackTrace|Devel::StackTrace> object.

=item 4.

Call C<initialize()> so that subclasses can do any object
initialization/tracking they need to do. (See L<SUBCLASSING> below.)

=item 5.

Track the object in our internal stack.

=back

B<get_fields()>

Returns a list of property names used for this class. If a subclass
wants to add properties to the base exception object, the common idiom
is:

 my @FIELDS = qw( this that );
 My::Custom::Exception->mk_accessors( @FIELDS );
 sub get_fields { return ( $_[0]->SUPER::get_fields(), @FIELDS ) }

So that all fields are represented. (The C<mk_accessors()> method is
inherited from this class, since it inherits from
L<Class::Accessor|Class::Accessor>.

=head2 Object Methods

B<creation_location>

Returns a string with information about where the exception was
thrown. It looks like (all on one line):

 Created in [%package%] in method [%method%];
 at file [%filename%] at line [%line%]

B<to_string>

Return a stringified version of the exception object. The default is
probably good enough for most exception objects -- it just returns the
message the exception was created with.

However, if the class variable C<ShowTrace> is set to a true value in
the exception class, then we also include the output of the
C<as_string()> method on a L<Devel::StackTrace|Devel::StackTrace>
object.

B<fill_error_variables>

You normally do not need to call this since it is done from
C<throw()>. This exists only for backward compatibility with
C<SPOPS::Error>. The exception fills up the relevant C<SPOPS::Error>
package variables with its information.

=head1 PROPERTIES

B<message>

This is the message the exception is created with -- there should be
one with every exception. (It is bad form to throw an exception with
no message.)

B<package>

The package the exception was thrown from.

B<filename>

The file the exception was thrown from.

B<line>

The line number in C<filename> the exception was thrown from.

B<method>

The subroutine the exception was thrown from.

B<trace>

Returns a L<Devel::StackTrace|Devel::StackTrace> object. If you set a
package variable 'ShowTrace' in your exception then the output of
C<to_string()> (along with the stringification output) will include
the stack trace output as well as the message.

This output may produce redundant messages in the default
C<to_string()> method -- just override the method in your exception
class if you want to create your own output.

=head1 SUBCLASSING

It is very easy to create your own SPOPS or application errors:

 package My::Custom::Exception;

 use strict;
 use base qw( SPOPS::Exception );

Easy! If you want to include different information that can be passed
via C<new()>:

 package My::Custom::Exception;

 use strict;
 use base qw( SPOPS::Exception );
 my @FIELDS = qw( this that );
 My::Custom::Exception->mk_accessors( @FIELDS );

 sub get_fields { return ( $_[0]->SUPER::get_fields(), @FIELDS ) }

And now your custom exception can take extra parameters:

 My::Custom::Exception->throw( $@, { this => 'bermuda shorts',
                                     that => 'teva sandals' });

If you want to do extra initialization, data checking or whatnot, just
create a method C<initialize()>. It gets called just before the C<die>
is called in C<throw()>. Example:

 package My::Custom::Exception;

 # ... as above

 my $COUNT = 0;
 sub initialize {
     my ( $self, $params ) = @_;
     $COUNT++;
     if ( $COUNT > 5 ) {
         $self->message(
               $self->message . "-- More than five errors?! ($COUNT) Whattsamatta?" );
     }
 }

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<Devel::StackTrace|Devel::StackTrace>

L<Class::Accessor|Class::Accessor>

L<Exception::Class|Exception::Class> for lots of good ideas -- once we
get rid of backwards compatibility we will probably switch to using
this as a base class.

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
