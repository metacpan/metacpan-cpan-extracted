package SPOPS::Key::DBI::Sequence;

# $Id: Sequence.pm,v 3.4 2004/06/02 00:48:23 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;

$SPOPS::Key::DBI::Sequence::VERSION  = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

# Default SELECT statement to use to retrieve the sequence -- you can
# override this in your config or in the parameters passed to
# 'retrieve_sequence()'

use constant DEFAULT_SEQUENCE_CALL => q/SELECT NEXTVAL( '%s' )/;

my $log = get_logger();

# Retrieve the sequence value

sub pre_fetch_id { return retrieve_sequence( @_ ) }


# Perform the actual work -- this is in a separate method so that
# other classes can use this one without having to put it in an 'isa'

sub retrieve_sequence {
    my ( $item, $p ) = @_;
    $p ||= {};

    my $sequence_name = $p->{sequence_name} || $item->CONFIG->{sequence_name};
    unless ( $sequence_name ) {
        my $class_name = ( ref $item ) ? ref $item : $item;
        $log->warn( "Cannot retrieve sequence without a sequence name!",
               "No sequence name found in parameter or in object",
               "configuration. (Object: $class_name)" );
        return undef;
    }

    $p->{db} ||= $item->global_datasource_handle();
    return undef unless ( ref $p->{db} );

    $log->is_debug &&
        $log->debug( "Trying to get value from sequence ($sequence_name)" );
    my $sequence_call  = $p->{sequence_call} ||
                         $item->CONFIG->{sequence_call} ||
                         DEFAULT_SEQUENCE_CALL;
    my $sql = sprintf( $sequence_call, $sequence_name );
    $log->is_debug &&
        $log->debug( "SQL used to retrieve sequence:\n$sql" );
    my ( $sth );
    eval {
        $sth = $p->{db}->prepare( $sql );
        $sth->execute;
    };
    if ( $@ ) {
        SPOPS::Exception::DBI->throw( "Cannot kick sequence [$sequence_name]: $@",
                                      { sql => $sql, action => 'retrieve_sequence' } );
    }
    my ( $id ) = $sth->fetchrow_array;
    return $id;
}

# Ensure only pre_fetch_id is called

sub post_fetch_id { return undef }

1;

__END__

=head1 NAME

SPOPS::Key::DBI::Sequence -- Retrieve sequence values from a supported DBI database 

=head1 SYNOPSIS

 # In the SPOPS configuration (note that 'sequence_call' is optional
 # and if not given the default will be used)

 $spops = {
   'myspops' => {
       'isa' => [ qw/ SPOPS::Key::DBI::Sequence  SPOPS::DBI / ],
       'sequence_name' => 'mysequence',
       'sequence_call' => 'SELECT %s.nextval',
       ...
   },
 };

 # Note: Other classes (such as 'SPOPS::DBI::Pg') use this class
 # without requiring you to specify it or any of the configuration
 # information.

=head1 DESCRIPTION

This class makes a call to a 'sequence' to retrieve a value for use as
a unique ID. Sequence implementations vary among databases, but
generally they ensure that the sequence always generates a unique
number no matter how many times it is accesed and by how many
different connections.

To configure your SPOPS object to get its ID values from a sequence
you can set the following configuration information either in your
object or in the parameters passed to C<retrieve_sequence()>:

B<sequence_name> ($) (required)

This holds the name of the sequence. Databases can typically have
many sequences but only one per table. 

B<sequence_call> ($) (optional)

This class comes with the default sequence call of:

 SELECT NEXTVAL( '$sequence_name' )

If you need to change this for your database, it should be in a form
accessible by C<sprintf> so we can plugin the sequence name. For
instance:

 sequence_name => 'myseq',
 sequence_call => ' SELECT %s.nextval',

Will get expanded to:

 SELECT myseq.nextval

when the call is made to retrieve a sequence.

=head1 METHODS

B<pre_fetch_id()>

Calls C<retrieve_sequence()> to get the sequence value and returns it.

B<retrieve_sequence( )>

Performs the action to retrieve the sequence. Uses the sequence call
and sequence name to make a SQL call to retrieve the next value from a
sequence. This should be database-independent, and the parts that are
not independent (such as the format of the sequence call) are
configurable in either the object configuration or in the call to this
method. (Method parameters take precedence.)

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<DBI|DBI>, PostgreSQL and Oracle databases, both of which have sequences.

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>
