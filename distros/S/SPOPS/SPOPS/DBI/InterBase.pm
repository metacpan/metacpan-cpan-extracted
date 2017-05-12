package SPOPS::DBI::InterBase;

# $Id: InterBase.pm,v 3.5 2004/06/02 00:48:22 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;

$SPOPS::DBI::InterBase::VERSION  = sprintf("%d.%02d", q$Revision: 3.5 $ =~ /(\d+)\.(\d+)/);

# Values are:
#   %s - Generator name (config item 'sequence_name'
#   %d - Increment value ('sequence_increment', or 1)
use constant IB_GENERATOR_NEXT    => 'SELECT GEN_ID( %s, %d ) FROM RDB$DATABASE';

my $log = get_logger();

# NOT SURE ABOUT THESE

sub sql_current_date     { return 'CURRENT_TIMESTAMP' }
sub sql_case_insensitive { return 'LIKE' }

sub pre_fetch_id {
    my ( $item, $p ) = @_;
    my ( $gen_name );
    return undef unless ( $item->CONFIG->{increment_field} );
    return undef unless ( $gen_name = $item->CONFIG->{sequence_name} );
    my $gen_increment = $item->CONFIG->{sequence_increment} || 1;
    my $db = $p->{db} || $item->global_datasource_handle;
    my $sql = sprintf( IB_GENERATOR_NEXT, $gen_name,
                                          $gen_increment );
    my ( $sth );
    warn "Trying to prepare [$sql]\n";
    eval {
        $sth = $db->prepare( $sql );
        $sth->execute;
    };
    return ($sth->fetchrow_arrayref)->[0];
}


sub post_fetch_id { return undef }

1;

__END__

=head1 NAME

SPOPS::DBI::InterBase -- InterBase-specific routines for the SPOPS::DBI

=head1 SYNOPSIS

 # In your configuration:

 'myspops' => {
     'isa' => [ qw/ SPOPS::DBI::InterBase SPOPS::DBI / ],

     # If you use a generator to create unique keys, set
     # increment_field to a true value...

     'increment_field' => 1,

     # and set 'sequence_name' to the name of the generator

     'sequence_name'   => 'mygen',

     # ...optionally, you can also specify the increment for the
     # generated values (defaults to 1 if not specified)

     'sequence_increment' => 4,
     ...
 },

=head1 DESCRIPTION

This just implements some InterBase-specific routines so we can
abstract them out.

The main one is to be able to utilize an existing C<generator> object
for creating unique key values. We cannot use the same pattern as with
Oracle/PostgreSQL sequences because there does not seem to be a way to
retrieve the B<current> (rather than next) value from a C<generator>
object.

Therefore, we need to retrieve the next value from the database and
use that in the INSERT. (This happens in the background, no worry to
you.)

How to implement this:

 CREATE TABLE my_table (
   id int not null primary key,
   ...
 );

 CREATE GENERATOR my_generator;

You must to let this module know if you are using this option by
setting in your class configuration the key 'increment_field' to a
true value and also setting key 'sequence_name' to the name of your
generator.

 $spops = {
    myobj => {
       class => 'My::Object',
       isa   => [ qw/ SPOPS::DBI::InterBase  SPOPS::DBI / ],
       increment_field => 1,
       sequence_name => 'my_generator',
       ...
    },
 };

The key 'sequence_name' rather than 'generator_name' is used to be
compatible with other databases.

=head1 METHODS

B<sql_current_date()>

Returns 'CURRENT_TIMESTAMP', used in InterBase to return the value for
right now.

TODO: See how this is used and whether we need to add another methods
for executing this as a standalone statement ('SELECT
CURRENT_TIMESTAMP' on its own does not work.)

B<sql_case_insensitive()>

Returns 'LIKE' right now, even though this does not seem to be correct.

TODO: See if there is a separate operator for case-insensitive
matching.

B<sql_quote( $value, $data_type, [ $db_handle ] )>

L<DBD::InterBase|DBD::InterBase> uses the type of a field if you are
quoting values to put into a statement, so we override the default
'sql_quote' from L<SPOPS::SQLInterface|SPOPS::SQLInterface> to ensure
the type of the field is used in the DBI-E<gt>quote call.

The C<$data_type> should correspond to one of the DBI datatypes (see
the file 'dbi_sql.h' in your Perl library tree for more info). If the
DBI database handle C<$db_handle> is not passed in, we try to find it
with the class method C<global_datasource_handle()>.

B<pre_fetch_id( \%params )>

If 'increment_field' is not set we do not fetch an ID. If
'sequence_name' is not also set we do not fetch an ID. Otherwise we
execute a statement like:

 SELECT GEN_ID( $name, $increment ) FROM RDB$DATABASE

Where:

  $name      - Value of 'sequence_name'
  $increment - Either 'sequence_increment' or 1

B<post_fetch_id( \%params )>

Not used.

=head1 BUGS

Minimally tested, potentially with buggy InterBase knowledge.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<DBD::InterBase|DBD::InterBase>

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2002-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>
