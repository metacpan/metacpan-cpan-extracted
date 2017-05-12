package POE::Filter::FastCGI;
BEGIN {
  $POE::Filter::FastCGI::VERSION = '0.19';
}

use strict;
use bytes;

our(@ROLE, @TYPE);

BEGIN {
	# Some normal constants
	use constant FCGI_VERSION_1   => 1;
	use constant HEADER_LENGTH    => 8;
   use constant STATE_WAIT       => 1;
   use constant STATE_DATA       => 2;

   use constant REQUEST_COMPLETE => 0;
   use constant CANT_MPX_CONN    => 1;
   use constant OVERLOADED       => 2;
   use constant UNKNOWN_ROLE     => 3;

    # Request flag constants
    use constant FCGI_KEEP_CONN   => 1;

	# Constant maps
	@TYPE = qw(
		NULL
		BEGIN_REQUEST
		ABORT_REQUEST
		END_REQUEST
		PARAMS
		FCGI_STDIN
		FCGI_STDOUT
		FCGI_STDERR
	);
	my $c = 1;
	constant->import($_ => $c++) for @TYPE[1 .. $#TYPE];

	@ROLE = qw(
		NULL
		RESPONDER
		AUTHORIZER
		FILTER
	);
	$c = 1;
	constant->import($_ => $c++) for @ROLE[1 .. $#ROLE];
}

sub new {
	my($class) = @_;
	my $self = bless {
		buffer => "",
		conn => [ ],
		state  => STATE_WAIT,
	}, $class;
	return $self;
}

sub get {
	my($self, $stream) = @_;
	$self->get_one_start($stream);
	my(@out, $conn);
	do {
		$conn = $self->get_one;
		push @out => @$conn if @$conn;
	}while(@$conn);
	return \@out;
}

sub get_pending {
	my($self) = @_;
	return $self->{buffer} ? $self->{buffer} : undef;
}

sub get_one {
	my($self) = @_;

	while($self->{buffer}) {
		if($self->{state} == STATE_WAIT) {
			return [ ] unless length $self->{buffer} >= HEADER_LENGTH;

			# Remove FastCGI header from buffer
			my $header = substr $self->{buffer}, 0, HEADER_LENGTH, "";

			@$self{qw/version type requestid contentlen padlen/} =
				unpack "CCnnC", $header;

			warn "Wrong version, or direct request from a browser"
				if $self->{version} != FCGI_VERSION_1;

			if($self->{contentlen}) {
				$self->{state} = STATE_DATA;
			}else{
				my $conn = $self->_do_record;
				return [$conn] if defined $conn;
				next;
			}
		}

		if(length $self->{buffer} >= ($self->{contentlen} + $self->{padlen})) {
			# Remove content from buffer
			my $content = substr $self->{buffer}, 0, $self->{contentlen}, "";
			# Remove padding
			substr $self->{buffer}, 0, $self->{padlen}, "";

			my $conn = $self->_do_record($content);
			return [$conn] if defined $conn;
      } else {
         return [ ];
      }
	}
	return [ ];
}

sub get_one_start {
	my($self, $stream) = @_;
	$self->{buffer} .= join '', @$stream;
}

# Process FastCGI record
sub _do_record {
	my($self, $content) = @_;

	if($self->{type} == BEGIN_REQUEST) {
		my($role, $flags) = unpack "nC", $content;
		$self->{conn}->[$self->{requestid}] = {
			state => BEGIN_REQUEST,
			flags => $flags,
			role => $ROLE[$role],
			cgi => { },
		};

		$self->{conn}->[$self->{requestid}]{keepconn} = $flags & FCGI_KEEP_CONN ? 1 : 0;
		return $self->_cleanup;
	}

	return $self->_cleanup if not defined $self->{conn}->[$self->{requestid}];

	my $conn = $self->{conn}->[$self->{requestid}];
	$conn->{state} = $self->{type};

	if($self->{type} == PARAMS) {
	   if(defined $content) {
			my $offset = 0;
			my($nlen, $vlen);
			while(defined($nlen = _read_nv_len(\$content, \$offset)) &&
					defined($vlen = _read_nv_len(\$content, \$offset))) {
				my($name, $value) = (substr($content, $offset, $nlen),
						substr($content, $offset + $nlen, $vlen));
				$conn->{cgi}->{$name} = $value;
				$offset += $nlen + $vlen;
			}
		}
	}elsif($self->{type} == FCGI_STDIN) {
		if(defined $content) {
			$conn->{postdata} .= $content;
		}else{
			my $cgi = delete $conn->{cgi};
			return [$self->{requestid}, $conn, $cgi];
		}
	}

	return $self->_cleanup;
}

sub _cleanup {
	my($self, $request) = @_;
	delete @$self{qw/version type requestid contentlen padlen/};
	$self->{state} = STATE_WAIT;
	return $request;
}

sub _read_nv_len {
   my($dataref, $offsetref) = @_;
   my $buf = substr($$dataref, $$offsetref++, 1);
   return undef unless length $buf;
   my $len = unpack("C", $buf);

   if($len & 0x80) { # High order bit set
      $buf = substr($$dataref, $$offsetref, 3);
      return undef unless $buf;
      $$offsetref += 3;
      $len = unpack("N", (pack("C", $len & 0x7f) . $buf));
   }

   return $len;
}

sub put {
	my($self, $input) = @_;
	my @output;

	for my $response(@$input) {
		if(UNIVERSAL::isa($response, "POE::Component::FastCGI::Response")) {
			$self->_write(\@output, $response->{requestid},
				FCGI_STDOUT, $response->as_string);
			$self->_close(\@output, $response->{requestid});
		}elsif(ref $response eq "HASH") {
			if(length $response->{content}) {
				$self->_write(\@output, $response->{requestid},
					FCGI_STDOUT, $response->{content});
			}
			if(exists $response->{close} and $response->{close}) {
				$self->_close(\@output, $response->{requestid});
			}
		}else{
			warn "Unhandled put";
		}
	}

	return [ join '', @output ];
}

# Close a connection
sub _close {
	my($self, $output, $id, $status, $appstatus) = @_;
	$status = REQUEST_COMPLETE unless defined $status;
	$self->_write($output, $id, FCGI_STDOUT, "") if $status == REQUEST_COMPLETE;
	$self->_write($output, $id, END_REQUEST,
		pack("NCx3", (defined $appstatus ? $appstatus : 0), $status, 0));
	delete $self->{conn}->[$id];
}

# Append FastCGI packets to @$output.
sub _write {
   my ($self, $output, $id, $type, $content) = @_;
   my $length = length $content;
   my $offset = 0;

	if($length == 0) {
		# Null packet
		push @$output, pack("CCnnCx", FCGI_VERSION_1, $type, $id, 0, 0);
		return;
	}

	# Create as many 32KiB packets as needed
   while ($length > 0) {
      my $len = $length > 32*1024 ? 32*1024 : $length;
      my $padlen = (8 - ($len % 8)) % 8;
      push @$output, pack("CCnnCxa${len}x$padlen",
         FCGI_VERSION_1, $type, $id, $len, $padlen,
         substr($content, $offset, $len));

      $length -= $len;
      $offset += $len;
   }
}

1;

=head1 NAME

POE::Filter::FastCGI - Parse and create FastCGI requests

=head1 SYNOPSIS

   $fastcgi = POE::Filter::FastCGI->new;
   $arrayref_with_binary_fastcgi_response = $fastcgi->put($put);
   $arrayref_with_fastcgi_request_array = $fastcgi->get($chunks);

=head1 DESCRIPTION

Parses the FastCGI binary protocol into a perl array with the CGI
environment and any POST or other data that is sent.

Accepts either L<POE::Component::FastCGI::Response> objects or a
simple hash reference via C<put> and converts into the FastCGI
binary protocol. The hash reference should have keys of requestid
and content and an optional key of close to end the FastCGI
request.

=head1 AUTHOR

Copyright 2005, David Leadbeater L<http://dgl.cx/contact>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Some parts taken from FCGI's Pure Perl implementation.

=head1 BUGS

This is rather tightly coupled with L<POE::Component::FastCGI>, ideally
there would be some form of intermediate perl object to use for FastCGI
like L<POE::Filter::HTTPD> can make use of L<HTTP::Request>.

This code is pure perl, it's probably slow compared to L<FCGI> (which is
mostly C) and it doesn't handle as many record types as L<FCGI>. However
L<FCGI> doesn't allow more than one concurrent request.

=head1 SEE ALSO

L<POE::Component::FastCGI>, L<POE::Filter::HTTPD>, L<POE::Filter>.

=cut
