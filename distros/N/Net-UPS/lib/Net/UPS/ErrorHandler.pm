package Net::UPS::ErrorHandler;
$Net::UPS::ErrorHandler::VERSION = '0.16';
{
  $Net::UPS::ErrorHandler::DIST = 'Net-UPS';
}
use strict;
use warnings;
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
