package Podcast::LoggerInterface;
use Carp;

$VERSION="0.51";

sub set_logger { 
    my $self = shift;
    $self->{ 'logger' } = shift;
}

sub set_error_logger { 
    my $self = shift;
    $self->{ 'error_logger' } = shift;
}

sub log_error {
    my $self = shift;
    my $msg = shift;
    if( $self->{ 'error_logger' } ) {
	$self->{ 'error_logger' }->( $msg );
    }
    else {
	croak $msg;
    }
}

sub log_message {
    my $self = shift;
    my $msg = shift;
    if( $self->{ 'logger' } ) {
	$self->{ 'logger' }->( $msg );
    }
}

1;
