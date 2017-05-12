package QualysGuard::Response::TicketList;

use warnings;
use strict;

use base qw( QualysGuard::Response );

our $VERSION = '0.02';


# =============================================================
# - new
# =============================================================
sub new {
    my ( $class, $xml ) = @_; 

    my $self = __PACKAGE__->SUPER::new( $xml );

    bless $self, $class;

    # -- check for QualysGuard function error

    if ( $self->exists('/REMEDIATION_TICKETS/ERROR') ) { 
        $self->{error_code} = $self->findvalue('/REMEDIATION_TICKETS/ERROR/@number');
        $self->{error_text} = $self->getNodeText('/REMEDIATION_TICKETS/ERROR');
        $self->{error_text} =~ s/^\s+(.*)\s+$/$1/m;
    }   

    return $self;
}


# =============================================================
# - is_truncated
# =============================================================
sub is_truncated {
    my $self = shift;
    return ( $self->exists('/REMEDIATION_TICKETS/TRUNCATION') ) ? 1 : 0;
}



# =============================================================
# - get_last_ticket_number
# =============================================================
sub get_last_ticket_number {
    my $self = shift;
    if ( $self->is_truncated() ) {
        if ( $self->exists('/REMEDIATION_TICKETS/TRUNCATION/@last') ) {
            return $self->findvalue('/REMEDIATION_TICKETS/TRUNCATION/@last');
        }
    }

    return undef;
}



1;

__END__


=head1 NAME

QualysGuard::Response::TicketList

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

see L<QualysGuard::Request> for more information.


=head1 DESCRIPTION

This module is a subclass of QualysGuard::Response and XML::XPath.

see QualysGuard API documentation for more information.

=head1 PUBLIC INTERFACE

=over 4

=item is_tuncated

Returns a I<1> or I<0> based on if the results have been truncated at 1000 tickets.
 
=item get_last_ticket_number
 
Returns the last ticket number included in the ticket list report or undef if report is not truncated.
 
see QualysGuard API documentation for more information.

=back

=head1 AUTHOR

Patrick Devlin, C<< <pdevlin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-qualysguard-response-assetdatareport at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=QualysGuard::Request>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc QualysGuard::Request


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=QualysGuard::Request>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/QualysGuard::Request>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/QualysGuard::Request>

=item * Search CPAN

L<http://search.cpan.org/dist/QualysGuard::Request>

=back

=head1 SEE ALSO
 
L<QualysGuard::Request>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Patrick Devlin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Qualys and the QualysGuard product are registered trademarks of Qualys, Inc.
