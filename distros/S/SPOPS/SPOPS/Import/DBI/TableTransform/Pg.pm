package SPOPS::Import::DBI::TableTransform::Pg;

# $Id: Pg.pm,v 3.4 2004/06/02 00:48:23 lachoy Exp $

use strict;
use base qw( SPOPS::Import::DBI::TableTransform );

$SPOPS::Import::DBI::TableTransform::Pg::VERSION  = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

sub increment {
    my ( $self, $sql ) = @_;
    $$sql =~ s/%%INCREMENT%%/INT/g;
}

sub increment_type {
    my ( $self, $sql ) = @_;
    $$sql =~ s/%%INCREMENT_TYPE%%/INT/g;
}

sub datetime {
    my ( $self, $sql ) = @_;
    $$sql =~ s/%%DATETIME%%/TIMESTAMP/g;
}

1;


__END__

=head1 NAME

SPOPS::Import::DBI::TableTransform::Pg - Table transformations for PostgreSQL

=head1 SYNOPSIS

 my $table = qq/
   CREATE TABLE blah ( id %%INCREMENT%% primary key,
                       name varchar(50) )
 /;
 my $transformer = SPOPS::Import::DBI::TableTransform->new( 'pg' );
 $transformer->increment( \$table );
 print $table;
 
 # Output:
 # CREATE TABLE blah ( id INT primary key,
 #                     name varchar(50) )

=head1 DESCRIPTION

PostgreSQL-specific type conversions for the auto-increment and other
field types.

=head1 METHODS

B<increment>

Returns 'INT NOT NULL' -- relying on the sequence autocreated by
'SERIAL' can get you into trouble since long table names get
truncated. Just create your own sequence and specify it in the
'sequence_name' key of your object config (see
L<SPOPS::DBI::Pg|SPOPS::DBI::Pg>).

B<increment_type>

Returns 'INT'

B<datetime>

Returns 'TIMESTAMP'

=head1 BUGS

None known.

=head1 TO DO

B<Add hook for extra statement>

Since PostgreSQL supports a sequence-based increment type, think about
adding a hook for an extra statement to be registered and modifying
'%%INCREMENT%%' to be 'INT NOT NULL' and the extra statement to create
a sequence of a given name.

=head1 SEE ALSO

L<SPOPS::Import::DBI::TableTransform|SPOPS::Import::DBI::TableTransform>

=head1 COPYRIGHT

Copyright (c) 2002-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

