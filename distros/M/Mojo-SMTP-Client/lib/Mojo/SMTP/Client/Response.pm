package Mojo::SMTP::Client::Response;

use Mojo::Base -base;
use overload '""' => \&to_string, fallback => 1;

use constant CRLF => "\x0d\x0a";

has 'error';

sub new {
	my $class = shift;
	my $resp  = shift;
	
	my $self = $class->SUPER::new(@_);
	$self->{resp} = $resp;
	$self;
}

sub code {
	my $self = shift;
	unless ($self->{code}) {
		$self->_parse_response();
	}
	
	$self->{code};
}

sub message {
	my $self = shift;
	unless ($self->{message}) {
		$self->_parse_response();
	}
}

sub to_string {
	$_[0]->{resp};
}

sub _parse_response {
	my $self = shift;
	
	my @lines = split CRLF, $self->{resp} or return;
	($self->{code}) = $lines[0] =~ /^(\d+)/;
	
	my @msg;
	
	for (@lines) {
		if (/^\d+[-\s](.+)/) {
			push @msg, $1;
		}
	}
	
	$self->{message} = join CRLF, @msg;
}

1;

__END__

=pod

=head1 NAME

Mojo::SMTP::Client::Response - Response class for Mojo::SMTP::Client

=head1 SYNOPSIS

	use Mojo::SMTP::Client;
	
	my $smtp = Mojo::SMTP::Client->new;
	my $resp = $smtp->send(from => $from, to => $to, data => $msg);
	if ($resp->error) {
		die $resp->error;
	}
	
	say "Sent successfully with last response = ", $resp;

=head1 DESCRIPTION

C<Mojo::SMTP::Client::Response> represents response from SMTP server and
may be used to get code, message or raw response.

=head1 ATTRIBUTES

C<Mojo::SMTP::Client::Response> implements the following attributes

=head2 error

Error for this response. Should be one of C<Mojo::SMTP::Client::Exception::*>
defined in L<Mojo::SMTP::Client::Exception>. Default is C<undef>.

=head1 METHODS

C<Mojo::SMTP::Client::Response> implements the following methods

=head2 new($raw_resp, ...)

Contructs new C<Mojo::SMTP::Client::Response> object. One required parameter
is raw response from SMTP server as a string.

=head2 code

Get three-digit code for this response. May be undefined if response was not received
because of error in the stream (timeout or other).

=head2 message

Get message for this response. Will contain several lines for multiline responses.
May be undefined if response was not received because of error in the stream (timeout or other).

=head2 to_string

Get raw response as a string. Response will be also auto stringified in string context.

=head1 SEE ALSO

L<Mojo::SMTP::Client>, L<Mojo::SMTP::Client::Response>, L<Mojo::SMTP::Client::Exception>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
