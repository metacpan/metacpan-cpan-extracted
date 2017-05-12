package QualysGuard::Response::GenericReturn;

use warnings;
use strict;

use base qw( QualysGuard::Response );

our $VERSION = '0.01';


# =============================================================
# - new
# =============================================================
sub new {
    my ( $class, $xml ) = @_; 

    my $self = __PACKAGE__->SUPER::new( $xml );

    bless $self, $class;

    # -- extract the response status

    $self->{status}         = $self->findvalue('/GENERIC_RETURN/RETURN/@status')->value();
    $self->{status_text}    = $self->getNodeText('/GENERIC_RETURN/RETURN')->value();
    $self->{status_text}    =~ s/^\s+(.*)\s+$/$1/m;

    if ( $self->exists('/GENERIC_RETURN/RETURN/@number') ) { 
        $self->{status_code} = $self->findvalue('/GENERIC_RETURN/RETURN/@number')->value();
    }   

    if ( $self->{status} eq "FAILED" ) { 
        $self->{error_text} = $self->{status_text};
        $self->{error_code} = $self->{status_code};
    }   

    return $self;
}



# =============================================================
# - is_success
# =============================================================
sub is_success {
    my $self = shift;
    return ( $self->{status} eq "SUCCESS" ) ? 1 : 0;
}



# =============================================================
# - is_warning
# =============================================================
sub is_warning {
    my $self = shift;
    return ( $self->{status} eq "WARNING" ) ? 1 : 0;
}



# =============================================================
# - status_line
# =============================================================
sub status_line {
    my $self = shift;
    return $self->{status_text};
}



1;

__END__

=head1 NAME

QualysGuard::Response::GenericReturn 

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

see L<QualysGuard::Request> for more information.


=head1 DESCRIPTION

This module is a subclass of QualysGuard::Response and XML::XPath.

see QualysGuard API documentation for more information.


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
