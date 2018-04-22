package Report_HTML_DB::Models::Services::PagedResponse;

use Moose;
use MooseX::Storage;
with Storage('format'   =>      'JSON');

=pod

This class will be used to be a model of paged responses returned from services

=cut

has status_code => 	( is => 'ro', isa => 'Str');
has message 	=>	( is => 'ro', isa => 'Str');
has elapsed_ms	=>	( is => 'ro', isa => 'Str');
has response	=>	( is => 'ro');
has total	=>	( is => 'ro', isa => 'Str');
has offset	=>	( is => 'ro', isa => 'Str');
has page_size	=>	( is => 'ro', isa => 'Str');

sub setResponse {
	my ( $self, $response ) = @_;
	$self->{response} = $response;
	return $self->{response};
}

sub getResponse {
	my ($self) = @_;
	return $self->{response};
}

sub setStatusCode {
	my ( $self, $status_code ) = @_;
	$self->{status_code} = $status_code;
	return $self->{status_code};
}

sub getStatusCode {
	my ($self) = @_;
	return $self->{status_code};
}

sub setMessage {
	my ( $self, $message ) = @_;
	$self->{message} = $message;
	return $self->{message};
}

sub getMessage {
	my ($self) = @_;
	return $self->{message};
}

sub setElapsedMs {
	my ( $self, $elapsed_ms ) = @_;
	$self->{elapsed_ms} = $elapsed_ms;
	return $self->{elapsed_ms};
}

sub getElapsedMs {
	my ($self) = @_;
	return $self->{elapsed_ms};
}

sub setTotal {
        my ( $self, $total ) = @_;
        $self->{total} = $total;
        return $self->{total};
}

sub getTotal {
        my ($self) = @_;
        return $self->{total};
}

sub setOffset {
        my ( $self, $offset ) = @_;
        $self->{offset} = $offset;
        return $self->{offset};
}

sub getOffset {
        my ($self) = @_;
        return $self->{offset};
}

sub setPageSize {
        my ( $self, $page_size ) = @_;
        $self->{page_size} = $page_size;
        return $self->{page_size};
}

sub getPageSize {
        my ($self) = @_;
        return $self->{page_size};
}

1;
