package SPOPS::Exception::DBI;

# $Id: DBI.pm,v 3.3 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base qw( SPOPS::Exception );

$SPOPS::Exception::DBI::VERSION   = sprintf("%d.%02d", q$Revision: 3.3 $ =~ /(\d+)\.(\d+)/);
@SPOPS::Exception::DBI::EXPORT_OK = qw( spops_dbi_error );

my @FIELDS = qw( sql bound_value action );
SPOPS::Exception::DBI->mk_accessors( @FIELDS );

sub get_fields {
    return ( $_[0]->SUPER::get_fields, @FIELDS );
}

sub spops_dbi_error {
    goto &SPOPS::Exception::throw( 'SPOPS::Exception::DBI', @_ );
}

sub to_string   {
    my ( $self ) = @_;
    my $class = ref $self;
    return "Invalid -- not called from object."  unless ( $class );

    no strict 'refs';
    if ( $self->sql ) {
        return ( ${ $class . '::ShowTrace' } )
                 ? join( "\n", $self->message, $self->sql, $self->trace->as_string )
                 : join( "\n", $self->message(), $self->sql );
    }
    else {
        return ( ${ $class . '::ShowTrace' } )
                 ? join( "\n", $self->message, $self->trace->as_string )
                 : $self->message();
    }
}

1;

__END__

=pod

=head1 NAME

SPOPS::Exception::DBI - SPOPS exception with extra DBI parameters

=head1 SYNOPSIS

 my $rows = eval { SPOPS::SQLInterface->db_select( \%params ) };
 if ( $@ and $@->isa( 'SPOPS::Exception::DBI' ) ) {
     print "Tried to excecute SQL: ", $@->sql, "\n",
           "with values: ", ( ref $@->bound_value )
                              ? join( " :: ", @{ $@->bound_value } ) : 'n/a',
           "but died with the message: ", $@->message, "\n";
 }

=head1 DESCRIPTION

Same as L<SPOPS::Exception|SPOPS::Exception> but we add three new
properties:

B<sql> ($)

The SQL statement SPOPS tried to run. Note that this may be empty if
the exception was thrown before the statement could be prepared. (For
instance, if SPOPS cannot find a datasource.)

B<bound_value> (\@)

The value(s) that would have been bound to the various
placeholders. This may return undef if SPOPS did not reach the stage
where it collected the bound values or if there were none. So you will
want to test and ensure the return value is an arrayref before using
it as such, otherwise you will get the dreaded error: "Can't use an
undefined value as an ARRAY reference".

B<action> ($)

Indicates the DBI action (generally 'do', 'prepare' or 'execute') that
was being run when SPOPS encountered the error. This may be empty if
we did not even reach the DBI stage yet.

=head1 METHODS

No extra methods, but we override 'to_string' so any SQL executed will
be part of the error.

Additionally, you can use a shortcut if you are throwing
errors:

 use SPOPS::Exception::DBI qw( spops_dbi_error );

 ...
 spops_dbi_error "I found a DBI error: $@ ",
                 { sql => $sql, action => 'prepare' };

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Exception|SPOPS::Exception>

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

=cut
