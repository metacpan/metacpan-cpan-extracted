package SPOPS::DBI::SQLite;

# $Id: SQLite.pm,v 3.5 2004/06/02 00:48:22 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );

use DBI qw( SQL_VARCHAR );
use SPOPS;
use SPOPS::DBI::TypeInfo;
use SPOPS::Utility;

my $log = get_logger();

$SPOPS::DBI::SQLite::VERSION = sprintf("%d.%02d", q$Revision: 3.5 $ =~ /(\d+)\.(\d+)/);

sub sql_current_date  { return SPOPS::Utility->now }


########################################
# KEY GENERATION

sub pre_fetch_id  { return undef }

sub post_fetch_id {
    my ( $class, $p ) = @_;
    return undef unless ( $class->CONFIG->{increment_field} );
    return $p->{db}->func( 'last_insert_rowid' );
}


########################################
# TYPE MAPPING

# Since SQLite is typeless, just assume everything is a text field

my %TYPE_INFO = ();

sub db_discover_types {
    my ( $class, $table, $p ) = @_;
    my $db       = $p->{db} || $class->global_datasource_handle;
    my $type_idx = join( '-', lc $db->{Name}, lc $table );
    unless ( $TYPE_INFO{ $type_idx } ) {
        my $fields = $class->field_list;
        my $type_info = SPOPS::DBI::TypeInfo->new({ database => $db->{Name},
                                                    table    => $table });
        foreach my $field ( @{ $fields } ) {
            $type_info->add_type( $field, SQL_VARCHAR );
        }
        $TYPE_INFO{ $type_idx } = $type_info;
    }
    return $TYPE_INFO{ $type_idx }
}

1;

__END__

=head1 NAME

SPOPS::DBI::SQLite -- SQLite-specific code for DBI collections

=head1 SYNOPSIS

 myobject => {
   isa             => [ qw( SPOPS::DBI::SQLite SPOPS::DBI ) ],
   increment_field => 1,
   id_field        => 'id',
   no_insert       => [ 'id' ],
 };

=head1 DESCRIPTION

This just implements some SQLite-specific routines so we can abstract
them out.

One of these items is to auto-generate keys. SQLite supports
auto-generated keys in one instance only -- when you specify the first
column as an C<integer> field (not C<int>, for some reason SQLite is
sensitive to this) and as the primary key. For the value to be
generated, you should not insert a value for it.

So to use auto-generated keys, just define your table:


 CREATE TABLE my_table (
   id integer not null primary key,
   ...
 )

or

 CREATE TABLE my_table (
   id integer not null,
   ...
   primary key ( id )
 )

And tell SPOPS you are using an auto-increment field:

 myobject => {
   isa             => [ qw( SPOPS::DBI::SQLite SPOPS::DBI ) ],
   increment_field => 1,
   id_field        => 'id',
   no_insert       => [ 'id' ],
 };

B<NOTE>: Since SQLite is typeless, we assume for quoting purposes that
everything is a C<SQL_VARCHAR> type of field, overriding
C<db_discover_types> from L<SPOPS::SQLInterface|SPOPS::SQLInterface>
with our own version.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<DBD::SQLite|DBD::SQLite>

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2002-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
