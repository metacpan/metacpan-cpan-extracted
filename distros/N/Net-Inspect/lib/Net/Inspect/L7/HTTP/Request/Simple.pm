############################################################################
# simple HTTP Request class - everything gets per default put into sub in
# which then can be redefined by subclass
############################################################################
use strict;
use warnings;
package Net::Inspect::L7::HTTP::Request::Simple;
use base 'Net::Inspect::Flow';
use fields qw(conn meta chunked);
use Net::Inspect::Debug qw($DEBUG debug trace);
use Scalar::Util 'weaken';
use Carp 'croak';

sub new_request {
    my ($self,$meta,$conn) = @_;
    my $obj = $self->new;
    $obj->{meta} = $meta;
    weaken($obj->{conn} = $conn);
    return $obj;
}


sub in_request_header {
    my ($self,$hdr,$time) = @_;
    return $self->in(0,$hdr,0,$time);
}

sub in_request_body {
    my ($self,$data,$eof,$time) = @_;
    croak "gaps not supported in_request_body" if ref($data);
    return $self->in(0,$data,$eof&&1,$time);
}

sub in_response_header {
    my ($self,$hdr,$time) = @_;
    return $self->in(1,$hdr,0,$time);
}

sub in_response_body {
    my ($self,$data,$eof,$time) = @_;
    croak "gaps not supported in_response_body" if ref($data);
    return $self->in(1,$data,$eof&&2,$time);
}

sub in_chunk_header {
    my ($self,$dir,$hdr,$time) = @_;
    if ( $self->{chunked}[$dir]++ ) {
	# not first chunk, add chunk end from last one
	$hdr = "\r\n$hdr";
    }
    return $self->in($dir,$hdr,$time);
}
sub in_chunk_trailer {
    my ($self,$dir,$trailer,$time) = @_;
    return $self->in($dir,$trailer,$time);
}

sub in_data {
    my ($self,$dir,$data,$eof,$time) = @_;
    # will ignore all SSL, Websockets... stuff for now
    return length($data);
}

sub fatal {
    my ($self,$reason,$dir,$time) = @_;
    warn "FATAL: $reason\n";
}

sub in {
    my ($self,$dir,$data,$eof,$time) = @_;
    return
}

sub xdebug {
    $DEBUG or return;
    my $self = shift;
    my $msg = shift;
    $msg = "$$.$self->{conn}{connid}.$self->{meta}{reqid} $msg";
    unshift @_,$msg;
    goto &debug;
}

sub xtrace {
    my $self = shift;
    my $msg = shift;
    $msg = "$$.$self->{conn}{connid}.$self->{meta}{reqid} $msg";
    unshift @_,$msg;
    goto &trace;
}


1;
__END__

=head1 NAME

Net::Inspect::L7::HTTP::Request::Simple - simple HTTP request handling

=head1 SYNOPSIS

    ...
    my $rq = myHTTPRequest->new(...);
    my $http = Net::Inspect::L7::HTTP->new($rq);
    my $tcp = Net::Inspect::L4::TCP->new($http);

    package myHTTPRequest;
    use base 'Net::Inspect::L7::HTTP::Request::Simple';
    sub in {
	my ($self,$dir,$data,$eof,$time) = @_;
	# save data into file
	...
    }

=head1 DESCRIPTION

This class implements simple HTTP Request handling.
All hooks required in C<Net::Inspect::L7::HTTP> are implemented.
The hooks for chunked header and trailer just ignore the data, while all the
other hooks call C<in> with the content, which then should be redefined in
subclass:

=over 4

=item in($dir,$data,$eof,$time)

=back

Typical use is for just saving request and response.
