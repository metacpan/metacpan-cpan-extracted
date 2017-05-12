package Net::UPS::ErrorHandler;

# $Id: ErrorHandler.pm,v 1.2 2005/09/06 05:44:43 sherzodr Exp $

use strict;
use Carp ( 'croak' );


sub set_error {
    my $class = shift;
    $class = ref($class) || $class;
    unless ( @_ ) {
        croak "set_error(): usage error";
    }
    no strict 'refs';
    ${$class . '::error'} = $_[0];
    return undef;
}

sub errstr {
    my $class = shift;
    $class = ref($class) || $class;
    no strict 'refs';
    return ${$class . '::error'};
}

1;

__END__;

=pod

=head1 NAME

Net::UPS::ErrorHandler - Simple error handler class for Net::UPS

=head1 AUTHOR AND LICENSING

For support and licensing information refer to L<Net::UPS|Net::UPS/"AUTHOR">


=cut
