package Net::DNS::ZoneParse::Parser::Native::DNSext;

# This package contains code only needed to extent Net::DNS::RR.
# according patches had been sent, but until they are merged,
# requiring this file provides a suitable workaround.

package Net::DNS::RR;

=head3 $fqdn = $self->dns_fqdn($domain, $origin)

If $domain isn't fully qualified and thus not ending with a dot, the origin
will be appended. In both cases the finalizing dot will be cut off afterwards.

This functions is inteded to be used by the extension of Net::DNS::RR::xx
parsing functionality.

=cut

sub dns_fqdn {
	my ($self, $name, $origin) = @_;
	$name = $self->_dns_expand_chars($name, $origin);
	$name = $origin unless $name;
	$name .= ".".$origin unless(substr($name, -1) eq ".");
	return substr($name, 0, -1); # last char must be a dot now
}

# expand any special character within one item
# called as
# $self->_dns_expand_chars($string, $origin)
sub _dns_expand_chars {
	local($_);
	$_ = $_[1];
	my $origin = $_[2] || "";
	s/(?<![\w\\])@/$origin/;
	s/\\(\d+)/pack("C",$1)/e;
	s/\\//;
	$_[1] = $_;
	return $_;
}

# extend Net::DNS::RR to make it possible to parse the string differently
# from files and from packets
#
# the default is to reuse the new_from_string
#
sub new_from_filestring {
	my ($self, $ele, $data, $param) = @_;
	return $self->new_from_string($ele, $self->_dns_expand_chars(
			$data, $param->{origin}));
}

package Net::DNS::RR::CNAME;

sub new_from_filestring {
	my ($self, $ele, $data, $param) = @_;
	return $self->new_from_string($ele,
		$self->dns_fqdn($data, $param->{origin}));
}

package Net::DNS::RR::MX;

sub new_from_filestring {
	my ($self, $ele, $data, $param) = @_;
	# as the exchange is the only host and always the last item,
	# it is possible to simply use dns_fqdn here, too
	return $self->new_from_string($ele,
		$self->dns_fqdn($data, $param->{origin}));
}

package Net::DNS::RR::NS;

sub new_from_filestring {
	my ($self, $ele, $data, $param) = @_;
	return $self->new_from_string($ele,
		$self->dns_fqdn($data, $param->{origin}));
}


package Net::DNS::RR::SOA;

sub new_serial {
	my ($self, $inc) = @_;

	if($inc) {
		$self->serial += $inc;
	} else {
		my $newserial = strftime("%Y%m%d%H", localtime(time));
	        $self->serial = ($newserial > $self->serial)
			? $newserial
			: $self->serial + 1;
	}
	return $self->serial;
}


1;

