package SPOPS::Import::DBI::Delete;

# $Id: Delete.pm,v 1.1 2004/06/01 14:46:09 lachoy Exp $

use strict;
use base qw( SPOPS::Import::DBI::GenericOperation );
use SPOPS::SQLInterface;

$SPOPS::Import::DBI::Delete::VERSION  = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

sub data { return [] }

sub _run_operation {
    my ( $self, $delete_args ) = @_;
    my $rv = SPOPS::SQLInterface->db_delete( $delete_args );
    return ( $rv eq '0E0' ) ? 0 : $rv;
}

1;

__END__

=head1 NAME

SPOPS::Import::DBI::Delete - Delete existing data from a DBI table

=head1 SYNOPSIS

 #!/usr/bin/perl

 use strict;
 use DBI;
 use SPOPS::Import;

 {
     my $dbh = DBI->connect( 'DBI:Pg:dbname=test' );
     $dbh->{RaiseError} = 1;

     my $importer = SPOPS::Import->new( 'dbdelete' );
     $importer->db( $dbh );
     $importer->table( 'import' );
     $importer->where( 'name like ?' );
     $importer->add_where_params( "%foo" );
     my $status = $importer->run;
     foreach my $entry ( @{ $status } ) {
         if ( $entry->[0] ) { print "$entry->[1][0]: OK\n" }
         else               { print "$entry->[1][0]: FAIL ($entry->[2])\n" }
     }
     $dbh->disconnect;
}

=head1 DESCRIPTION

This importer deletes existing data from a DBI table.

This may seem out of place in the L<SPOPS::Import> hierarchy, but not
if you think of importing in the more abstract manner of manipulating
data in the database rather than getting data out of it...

=head2 Return from run()

The return value from C<run()> will be a single arrayref within the
status arrayref. As with other importers the first value will be true
if the operation succeeded, false if not. The one difference is that
on success the second value will be the number of records removed --
this may be '0' if your WHERE clause did not match anything. (The
third value in the arrayref will be the error message on failure.)

=head1 COPYRIGHT

Copyright (c) 2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
