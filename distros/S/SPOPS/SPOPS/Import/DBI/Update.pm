package SPOPS::Import::DBI::Update;

# $Id: Update.pm,v 1.1 2004/06/01 14:46:09 lachoy Exp $

use strict;
use base qw( SPOPS::Import::DBI::GenericOperation );
use SPOPS::SQLInterface;

$SPOPS::Import::DBI::Update::VERSION  = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( field field_value );
SPOPS::Import::DBI::Update->mk_accessors( @FIELDS );

sub data { return [] }

sub _run_operation {
    my ( $self, $update_args ) = @_;
    $update_args->{field} = $self->field;
    $update_args->{value} ||= [];
    my $field_values = $self->field_value || [];
    $update_args->{value} = [ @{ $field_values },
                              @{ $update_args->{value} } ];
    my $rv = SPOPS::SQLInterface->db_update( $update_args );
    return ( $rv eq '0E0' ) ? 0 : $rv;
}

sub set_update_data {
    my ( $self, $update_info ) = @_;
    my @fields = ();
    my @values = ();
    while ( my ( $field, $value ) = each %{ $update_info } ) {
        push @fields, $field;
        push @values, $value;
    }
    $self->field( \@fields );
    $self->field_value( \@values );
}

1;

__END__

=head1 NAME

SPOPS::Import::DBI::Update - Update existing data in a DBI table

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use DBI;
 use SPOPS::Import;
 
 {
     my $dbh = DBI->connect( 'DBI:Pg:dbname=test' );
     $dbh->{RaiseError} = 1;

     my $importer = SPOPS::Import->new( 'dbupdate' );
     $importer->db( $dbh );
     $importer->table( 'import' );
 
     # Set the update fields individually...
     $importer->field( [ 'foo', 'bar', 'baz' ] );
     $importer->field_value( [ 'fooval', 'barval', 'bazval' ] );
 
     # ...or all at once
     $importer->set_update_data({
         foo => 'fooval',
         bar => 'barval',
         baz => 'bazval',
     });
 
     $importer->where( 'name like ?' );
     $importer->add_where_params( [ "%foo" ] );
     my $status = $importer->run;
     foreach my $entry ( @{ $status } ) {
         if ( $entry->[0] ) { print "$entry->[1][0]: OK\n" }
         else               { print "$entry->[1][0]: FAIL ($entry->[2])\n" }
     }
     $dbh->disconnect;
}

=head1 DESCRIPTION

This importer updates existing data in a DBI table.

This may seem out of place in the L<SPOPS::Import> hierarchy, but not
if you think of importing in the more abstract manner of manipulating
data in the database rather than getting data out of it...

=head2 Return from run()

The return value from C<run()> will be a single arrayref within the
status arrayref. As with other importers the first value will be true
if the operation succeeded, false if not. The one difference is that
on success the second value will be the number of records updated --
this may be '0' if your WHERE clause did not match anything. (The
third value in the arrayref will be the error message on failure.)

=head1 ADDITIONAL ACTIONS

=head2 Methods

B<set_update_data( \%fields_and_values )>

Instead of setting the fields and values with the properties B<field>
and B<field_value>, respectively, you can set them all at once with a
more natural hash reference.

=head2 Properties

B<field>

Arrayref of fields to update

B<field_value>

Arrayref of values to update in the same order as B<field>.

=head1 SEE ALSO

L<SPOPS::Import::DBI::GenericOperation>

=head1 COPYRIGHT

Copyright (c) 2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
