package SPOPS::Key::DBI::Identity;

# $Id: Identity.pm,v 3.4 2004/06/02 00:48:23 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;

my $log = get_logger();

$SPOPS::Key::DBI::Identity::VERSION  = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

# Ensure only POST_fetch_id used

sub pre_fetch_id  { return undef }


# Retrieve the IDENTITY value

sub post_fetch_id {
    my ( $self, $p ) = @_;
    eval { $p->{statement}->finish };
    my $sql = 'SELECT @@IDENTITY';
    my ( $sth );
    eval {
        $sth = $p->{db}->prepare( $sql );
        $sth->execute;
    };
    if ( $@ ) {
        SPOPS::Exception::DBI->throw( "Cannot retrieve \@\@IDENTITY value: $@",
                                      { sql => $sql, action => 'post_fetch_id' } );
    }
    my $row = $sth->fetchrow_arrayref;
    $log->is_info &&
        $log->info( "Found inserted ID ($row->[0])" );
    return $row->[0];
}

1;

__END__

=head1 NAME

SPOPS::Key::DBI::Identity -- Retrieve IDENTITY values from a supported DBI database 

=head1 SYNOPSIS

 # In your SPOPS configuration
 $spops  = {
   'myspops' => {
       'isa' => [ qw/ SPOPS::Key::DBI::Identity  SPOPS::DBI / ],
       ...
   },
 };

=head1 DESCRIPTION

This class enables a just-created object to the IDENTITY value
returned by its last insert. Of course, this only works if you have an
IDENTITY field in your table, such as:

 CREATE TABLE my_table (
   id    NUMERIC( 8, 0 ) IDENTITY NOT NULL,
   ...
 )

This method is typically used in Sybase and Microsoft SQL Server
databases. The client library (Open Client, FreeTDS, ODBC) should not
make a difference to this module since we perform a SELECT statement
to retrieve the value rather than relying on a property of the
database/statement handle.

=head1 METHODS

B<post_fetch_id()>

Retrieve the IDENTITY value after inserting a row.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<DBD::Sybase|DBD::Sybase>

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>

See the L<SPOPS|SPOPS> module for the full author list.
