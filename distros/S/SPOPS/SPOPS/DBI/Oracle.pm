package SPOPS::DBI::Oracle;

# $Id: Oracle.pm,v 3.6 2004/06/02 00:48:22 lachoy Exp $

use strict;
use SPOPS::Exception qw( spops_error );
use SPOPS::Utility;

$SPOPS::DBI::Oracle::VERSION  = sprintf("%d.%02d", q$Revision: 3.6 $ =~ /(\d+)\.(\d+)/);

sub sql_current_date  { return SPOPS::Utility->now() }

use constant ORA_SEQUENCE_NEXT    => 'SELECT %s.NextVal FROM dual';
use constant ORA_SEQUENCE_CURRENT => 'SELECT %s.CurrVal FROM dual';

sub pre_fetch_id {
    my ( $item, $p ) = @_;
    my ( $seq_name );
    return undef unless ( $item->CONFIG->{increment_field} );
    return undef unless ( $seq_name = $item->CONFIG->{sequence_name} );
    my ( $sth );
    eval {
        $sth = $p->{db}->prepare( sprintf( ORA_SEQUENCE_NEXT, $seq_name ) );
        $sth->execute;
    };
    if ( $@ ) {
        spops_error "Failed to retrieve ID from sequence '$seq_name': $@";
    }
    return ( $sth->fetchrow_arrayref->[0], undef );
}


sub post_fetch_id {
    return undef;
}

1;

__END__

=head1 NAME

SPOPS::DBI::Oracle -- Oracle-specific routines for the SPOPS::DBI

=head1 SYNOPSIS

 # Define your table and sequence

 CREATE TABLE mytable (
   id int not null primary key,
   ...
 );

 CREATE SEQUENCE MySeq;

 # In your configuration:

 'myspops' => {
     'isa'             => [ qw/ SPOPS::DBI::Oracle SPOPS::DBI / ],
     'id'              => 'id',
     'no_insert'       => [ 'id' ],
     'increment_field' => 1,
     'sequence_name'   => 'MySeq';
     ...
 },

=head1 DESCRIPTION

This subclass allows you to specify a sequence name from which you can
retrieve the next ID value.

=head1 METHODS

B<pre_fetch_id>

Fetch the data from the specified sequence and return it.

B<sql_quote>

L<DBD::Oracle|DBD::Oracle> uses the type of a field to implement the
DBI C<quote()> call, so we override the default 'sql_quote' from
L<SPOPS::SQLInterface|SPOPS::SQLInterface>.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<DBD::Oracle|DBD::Oracle>

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2002-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>
