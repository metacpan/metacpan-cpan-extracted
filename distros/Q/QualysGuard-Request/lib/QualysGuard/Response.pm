package QualysGuard::Response;

use warnings;
use strict;

use base qw( XML::XPath );
use IO::File;
use Carp;

our $VERSION = '0.02';



# -------------------------------------------------------------------
#   new - constructor
# -------------------------------------------------------------------
sub new {
    my ( $class, $xml ) = @_;

    if ( ! defined $xml ) {
        croak "Missing or undefined XML response";
    }

    my $self = __PACKAGE__->SUPER::new( $xml );

    # -- extract the DOCTYPE
    my $doctype = (split("\n", $xml))[1];

    if ( $doctype !~ m/^<!DOCTYPE\ (.*)\ SYSTEM "(.[^"]*)">/ ) {
        croak "Missing on unknown DOCTYPE";
    }

    $self->{doctype}    = $1;
    $self->{dtd}        = $2;
    $self->{data}       = undef;
    $self->{xsl_output} = undef;
    $self->{error_code} = undef;
    $self->{error_text} = undef;

    return $self;
}


# -------------------------------------------------------------------
#   is_error
# -------------------------------------------------------------------
sub is_error {
    my $self = shift;
    return ( defined $self->{error_code} ) ? 1 : 0;
}



# -------------------------------------------------------------------
#   error_code
# -------------------------------------------------------------------
sub error_code {
    my $self = shift;
    if ( $self->is_error() ) {
        return $self->{error_code};
    }
}



# -------------------------------------------------------------------
#   get_error
# -------------------------------------------------------------------
sub get_error {
    my $self = shift;
    if ( $self->is_error() ) {
        return sprintf("Qualys Error [%s] : %s", $self->{error_code}, $self->{error_text} );
    }
}



# -------------------------------------------------------------------
#   save_to
# -------------------------------------------------------------------
sub save_to {
    my $self = shift;
    my $filename = shift;
    my $FH = IO::File->new();

    if ( $FH->open("> $filename") ) {
        print $FH $self->get_xml();
        $FH->close();
    }

    else {
        carp "Error : $!";
    }
}



1;

__END__

=head1 NAME

QualysGuard::Response - subclass of XML::XPath used to handle QualysGuard API XML responses

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use QualysGuard::Request;

    $QualysGuard::Request::Username = "username";
    $QualysGuard::Request::Password = "password";

    my $qualys_request = QualysGuard::Request->new( 'map_report_list' );

    # - provide map_report_list function arguments

    $qualys_request->attributes({
        'last'    => 'yes',
        'domain'  => 'example.com', 
    });

    my $qualys_response = $qualys_request->submit();

    if ( $qualys_response->is_error() ) {
        die $qualys_response->get_error(); 
    }

    $qualys_response->save_to( 'map_report_list.xml' );

    ...

=head1 DESCRIPTION

A subclass of B<XML::XPath>.

This is a base abstract class that is used to define core methods and attributes
shared across all QualysGuard::Response subclasses. I<Don't use this class directly>.


=head1 PUBLIC INTERFACE

=over 4

=item is_error

Returns a I<1> or I<0> based on the results of the requested QualysGuard function.

=item error_code

Returns the I<native> QualysGuard API error code.

=item get_error

Returns the QualysGuard API error code and error message returned by the QualysGuard function.


=item save_to( FILENAME )

Saves out the XML response returned from the QualysGuard function.

=back


=head1 AUTHOR

Patrick Devlin, C<< <pdevlin at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-qualysguard-request at rt.cpan.org>, or through
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

