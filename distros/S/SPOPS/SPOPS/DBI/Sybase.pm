package SPOPS::DBI::Sybase;

# $Id: Sybase.pm,v 3.6 2004/06/02 00:48:22 lachoy Exp $

use strict;
use SPOPS::Key::DBI::Identity;

$SPOPS::DBI::Sybase::VERSION  = sprintf("%d.%02d", q$Revision: 3.6 $ =~ /(\d+)\.(\d+)/);

sub sql_current_date  { return 'GETDATE()' }

# Backward compatibility and convenience, so you don't have to specify
# another item in the isa -- instead just set 'syb_identity' or
# 'increment_field' to true.

sub post_fetch_id {
    my ( $item, @args ) = @_;
    return undef unless ( $item->CONFIG->{increment_field} or $item->CONFIG->{syb_identity} );
    return SPOPS::Key::DBI::Identity::post_fetch_id( $item, @args );
}


1;

__END__

=head1 NAME

SPOPS::DBI::Sybase -- Sybase-specific routines for the SPOPS::DBI

=head1 SYNOPSIS

 # In your configuration:

 'myspops' => {
     'isa' => [ qw/ SPOPS::DBI::Sybase SPOPS::DBI / ],

     # If you have an IDENTITY field, set increment_field to true...
     'increment_field' => 1,
     # ...and the IDENTITY field in 'no_insert' and 'no_update'
     'no_insert'       => [ 'id' ],
     'no_update'       => [ 'id' ],
     ...
 },

=head1 DESCRIPTION

This just implements some Sybase-specific routines so we
can abstract them out.

One of them optionally returns the IDENTITY value returned by the last
insert. Of course, this only works if you have an IDENTITY field in
your table:

 CREATE TABLE my_table (
   id  numeric( 8, 0 ) IDENTITY not null,
   ...
 )

B<NOTE>: You also need to let this module know if you are using this
IDENTITY option by setting in your class configuration the key
'increment_field' to a true value.

=head1 METHODS

B<sql_quote>

L<DBD::Sybase|DBD::Sybase> depends on the type of a field if you are
quoting values to put into a statement, so we override the default
'sql_quote' from C<SPOPS::SQLInterface> to ensure the type of the
field is used in the DBI-E<gt>quote call.

=head1 BUGS

B<Working with FreeTDS>

SPOPS works with FreeTDS/MS SQL Server (presumably with FreeTDS/Sybase
as well, but it has not been tested). However, there is one hitch: the
combination of L<DBD::Sybase|DBD::Sybase> and FreeTDS does not seem to
work properly with the standard DBI field type discovery. As a result,
you need to specify your datatypes in your SPOPS configuration using
the C<dbi_type_info> key:

 my %config = (
       doodad => {
          class          => 'My::Doodad',
          isa            => [ 'SPOPS::DBI::Sybase', 'SPOPS::DBI' ],
          ...,
          dbi_type_info  => { doodad_id => 'int',
                              name      => 'char',
                              action    => 'char' },
       },
 );

See the discussion of "fake types" in
L<SPOPS::DBI::TypeInfo|SPOPS::DBI::TypeInfo> for more information.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Key::DBI::Identity|SPOPS::Key::DBI::Identity>

L<DBD::Sybase|DBD::Sybase>

L<DBI|DBI>

FreeTDS: http://www.freetds.org/

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>

See the L<SPOPS|SPOPS> module for the full author list.
