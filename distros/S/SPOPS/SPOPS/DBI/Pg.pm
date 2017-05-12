package SPOPS::DBI::Pg;

# $Id: Pg.pm,v 3.6 2004/06/02 00:48:22 lachoy Exp $

use strict;
use Log::Log4perl    qw( get_logger );
use SPOPS;
use SPOPS::Exception qw( spops_error );

$SPOPS::DBI::Pg::VERSION  = sprintf("%d.%02d", q$Revision: 3.6 $ =~ /(\d+)\.(\d+)/);

use constant PG_SEQUENCE_NEXT    => q{SELECT NEXTVAL( '%s' )};
use constant PG_SEQUENCE_CURRENT => q{SELECT CURRVAL( '%s' )};

my $log = get_logger();

sub sql_current_date     { return 'CURRENT_TIMESTAMP()' }
sub sql_case_insensitive { return '~*' }

sub pre_fetch_id {
    my ( $item, $p ) = @_;
    my ( $seq_name );
    return undef unless ( $item->CONFIG->{increment_field} );
    return undef unless ( $seq_name = $item->CONFIG->{sequence_name} );
    my ( $sth );
    eval {
        $sth = $p->{db}->prepare( sprintf( PG_SEQUENCE_NEXT, $seq_name ) );
        $sth->execute;
    };
    if ( $@ ) {
        spops_error "Failed to retrieve ID from sequence '$seq_name': $@";
    }
    return ( $sth->fetchrow_arrayref->[0], undef );
}


sub post_fetch_id {
    my ( $item, $p ) = @_;
    return undef unless ( $item->CONFIG->{increment_field} );
    return undef if ( $item->CONFIG->{sequence_name} );

    # If it's a SERIAL datatype try to fetch the value just inserted

    my $seq_name = $item->CONFIG->{sequence_name}
                   || join( '_', $item->CONFIG->{base_table},
                                 $item->CONFIG->{id_field},
                                 'seq' );
    return undef unless ( $seq_name );
    my $sth = $p->{db}->prepare( sprintf( PG_SEQUENCE_CURRENT, $seq_name ) );
    $sth->execute;
    return ($sth->fetchrow_array)[0];
}

1;

__END__

=head1 NAME

SPOPS::DBI::Pg -- PostgreSQL-specific routines for the SPOPS::DBI

=head1 SYNOPSIS

 # In your configuration:

 'myspops' => {
     'isa' => [ qw/ SPOPS::DBI::Pg SPOPS::DBI / ],

     # If you have a SERIAL field, just set increment_field to a true
     # value

     'increment_field' => 1,

     # If you want to specify the name of your sequence (whether using
     # a SERIAL field or not):

     'sequence_name'   => 'myseq',
     ...
 },

=head1 DESCRIPTION

This just implements some Postgres-specific routines so we can
abstract them out.

One of them optionally returns the sequence value of the just-inserted
id field. Of course, this only works if you have a the field marked as
'SERIAL' or using a sequence value in your table:

 CREATE TABLE my_table (
   id  SERIAL,
   ...
 )

or

 CREATE TABLE my_table (
   id int not null primary key,
   ...
 );
 
 CREATE SEQUENCE myobject_sequence;

You must to let this module know if you are using this option by
setting in your class configuration the key 'increment_field' to a
true value:

 $spops = {
    myobj => {
       class => 'My::Object',
       isa   => [ qw/ SPOPS::DBI::Pg  SPOPS::DBI / ],
       increment_field => 1,
       ...
    },
 };

If you use the 'SERIAL' datatype then you do not have to specify a
sequence name. Otherwise you need to tell SPOPS what sequence to use
in the class configuration:

 $spops = {
    myobj => {
       class           => 'My::Object',
       isa             => [ qw/ SPOPS::DBI::Pg  SPOPS::DBI / ],
       increment_field => 1,
       sequence_name   => 'myobject_sequence',
    },
 };

B<NOTE>: The name automatically created by PostgreSQL when you use the
'SERIAL' datatype follows a certain convention
($table-$idfield-seq). But if the table or ID field are too long,
PostgreSQL will truncate the name so it will fit in the 32-character
limit for symbols. In this case you will either need to recompile
PostgreSQL (yuck) or list the sequence name in the class
configuration. See a message from the openinteract-help mailing list
at:

  http://www.geocrawler.com/archives/3/8429/2002/1/0/7551783/

for more information on recompiling if you are so inclined.

=head1 METHODS

B<sql_current_date()>

Returns 'CURRENT_TIMESTAMP()', used in PostgreSQL to return the value
for right now.

B<sql_quote( $value, $data_type, [ $db_handle ] )>

L<DBD::Pg|DBD::Pg> depends on the type of a field if you are quoting
values to put into a statement, so we override the default 'sql_quote'
from L<SPOPS::SQLInterface|SPOPS::SQLInterface> to ensure the type of
the field is used in the DBI-E<gt>quote call.

The C<$data_type> should correspond to one of the DBI datatypes (see
the file 'dbi_sql.h' in your Perl library tree for more info). If the
DBI database handle C<$db_handle> is not passed in, we try to find it
with the class method C<global_datasource_handle()>.

B<pre_fetch_id( \%params )>

If 'increment_field' is not set we do not fetch an ID. If
'sequence_name' is not also set we do not fetch an ID, assuming that
you have defined the ID field using the 'SERIAL' datatype.

Otherwise we go ahead and fetch an ID from the specified sequence.

B<post_fetch_id( \%params )>

If you are using a SERIAL column (indicated by no 'sequence_name') we
fetch the value used by the database for this sequence.

=head1 SEE ALSO

L<DBD::Pg|DBD::Pg>

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>
