package SPOPS::Import::DBI::TableTransform::Oracle;

# $Id: Oracle.pm,v 3.4 2004/06/02 00:48:23 lachoy Exp $

use strict;
use base qw( SPOPS::Import::DBI::TableTransform );

$SPOPS::Import::DBI::TableTransform::Oracle::VERSION  = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

sub increment {
    my ( $self, $sql ) = @_;
    $$sql =~ s/%%INCREMENT%%/INT NOT NULL/g;

# TODO: Think about doing something here like:
    #my ( $table_name ) = $$sql =~ /create\s+table\s+(\w+)\s*/;
    #$self->add_extra_statement( "CREATE SEQUENCE ${table_name}_id_seq" );
}

sub increment_type {
    my ( $self, $sql ) = @_;
    $$sql =~ s/%%INCREMENT_TYPE%%/INT/g;
}

sub datetime {
    my ( $self, $sql ) = @_;
    $$sql =~ s/%%DATETIME%%/DATE/g;
}

1;

__END__

=head1 NAME

SPOPS::Import::DBI::TableTransform::Oracle - Table transformations for Oracle

=head1 SYNOPSIS

 my $table = qq/
   CREATE TABLE blah ( id %%INCREMENT%% primary key,
                       name varchar(50) )
 /;
 my $transformer = SPOPS::Import::DBI::TableTransform->new( 'oracle' );
 $transformer->increment( \$table );
 print $table;
 
 # Output:
 # CREATE TABLE blah ( id INT NOT NULL primary key,
 #                     name varchar(50) )

=head1 DESCRIPTION

Oracle-specific type conversions for the auto-increment and other
field types.

=head1 METHODS

B<increment>

Returns 'INT NOT NULL'

B<increment_type>

Returns 'INT'

B<datetime>

Returns 'DATE'

=head1 BUGS

None known.

=head1 TO DO

B<Add hook for extra statement>

Since Oracle supports a sequence-based increment type, think about
adding a hook for an extra statement to be registered.

=head1 SEE ALSO

L<SPOPS::Import::DBI::TableTransform|SPOPS::Import::DBI::TableTransform>

=head1 COPYRIGHT

Copyright (c) 2002-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

