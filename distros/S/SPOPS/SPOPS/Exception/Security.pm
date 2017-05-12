package SPOPS::Exception::Security;

# $Id: Security.pm,v 3.2 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base qw( SPOPS::Exception );
use SPOPS::Secure qw( :verbose :level );

$SPOPS::Exception::Security::VERSION   = sprintf("%d.%02d", q$Revision: 3.2 $ =~ /(\d+)\.(\d+)/);
@SPOPS::Exception::Security::EXPORT_OK = qw( spops_security_error );

my @FIELDS = qw( security_required security_found );
SPOPS::Exception::Security->mk_accessors( @FIELDS );

my %LEVELS = (
   SEC_LEVEL_NONE()    => SEC_LEVEL_NONE_VERBOSE,
   SEC_LEVEL_SUMMARY() => SEC_LEVEL_SUMMARY_VERBOSE,
   SEC_LEVEL_READ()    => SEC_LEVEL_READ_VERBOSE,
   SEC_LEVEL_WRITE()   => SEC_LEVEL_WRITE_VERBOSE,
);

sub get_fields {
    return ( $_[0]->SUPER::get_fields, @FIELDS );
}

sub spops_security_error {
    goto &SPOPS::Exception( 'SPOPS::Exception::Security', @_ );
}

sub to_string {
    my ( $self ) = @_;
    my $req = ( $self->security_required )
                ? $LEVELS{ $self->security_required }
                : 'none specified';
    my $fnd = ( $self->security_found )
                ? $LEVELS{ $self->security_found }
                : 'none specified';
    return "Security violation. Object requested [$req] and got [$fnd]";
}

1;

__END__

=pod

=head1 NAME

SPOPS::Exception::Security - SPOPS exception with extra security parameters

=head1 SYNOPSIS

 my $object = eval { My::Class->fetch( $id ) };
 if ( $@ ) {
     if ( $@->isa( 'SPOPS::Exception::Security' ) ) {
         print "Required security: ", $@->security_required, "\n",
               "Found security: ", $@->security_found, "\n";
     }
 }

=head1 DESCRIPTION

Same as L<SPOPS::Exception|SPOPS::Exception> but we add two new
properties:

B<security_required> ($)

Security level that we were trying to meet.

B<security_found> ($)

Security level found.

=head1 METHODS

B<to_string()>

We override the exception stringification to include the requested and
found security levels (in human-readable format).

You can also use a shortcut if you are throwing errors:

 use SPOPS::Exception::Security qw( spops_security_error );

 ...
 spops_security_error "Security error trying to fetch foo ",
                      { security_required => SEC_LEVEL_WRITE,
                        security_found    => SEC_LEVEL_READ };

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Exception|SPOPS::Exception>

L<SPOPS::Secure|SPOPS::Secure>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

=cut
