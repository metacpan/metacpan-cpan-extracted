package Net::TL1::Alcatel;
@ISA = qw(Net::TL1);

use Net::TL1;

use strict;
use warnings;

our $VERSION = '0.03';

sub rtrvservprov {
	my $this = shift;

	my ($ref) = @_;
	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	my $string = $this->get_linecommand
		('RTRV-SERVPROV', 'SERV', $$ref{ctag}, $ref);

	return undef if !defined $string;

	my $result = $this->Execute ($string);

	return undef if $this->is_error($$ref{ctag});

	$this->ParseCompoundOutputLines ($$ref{ctag});
	return $$ref{ctag};
}

sub rtrvservcurr {
	my $this = shift;

	my ($ref) = @_;
	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	my $string = $this->get_linecommand
		('RTRV-SERVCURR', 'SERV', $$ref{ctag}, $ref);

	return undef if !defined $string;

	my $result = $this->Execute ($string);

	return undef if $this->is_error($$ref{ctag});

	$this->ParseCompoundOutputLines ($$ref{ctag});
	return $$ref{ctag};
}


sub rtrvinvxdslcpe {
	my $this = shift;

	my ($ref) = @_;
	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	my $string = $this->get_linecommand
		('RTRV-INV-XDSLCPE', 'XDSL', $$ref{ctag}, $ref);

	return undef if !defined $string;

	my $result = $this->Execute ($string);

	return undef if $this->is_error($$ref{ctag});

	$this->ParseCompoundOutputLines ($$ref{ctag});
	return $$ref{ctag};
}

sub reptopstatatmport {
	my $this = shift;

	my ($ref) = @_;
	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	my $string = $this->get_linecommand
		('REPT-OPSTAT-ATMPORT', 'LTATM', $$ref{ctag}, $ref);

	return undef if !defined $string;

	my $result = $this->Execute ($string);

	return undef if $this->is_error($$ref{ctag});

	$this->ParseSimpleOutputLines ($$ref{ctag});
	return $$ref{ctag};
}


sub rtrvxdsl {
	my $this = shift;

	my ($ref) = @_;
	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	my $string = $this->get_linecommand
		('RTRV-XDSL', 'XDSL', $$ref{ctag}, $ref);

	return undef if !defined $string;

	my $result = $this->Execute ($string);

	return undef if $this->is_error($$ref{ctag});

	$this->ParseCompoundOutputLines ($$ref{ctag});
	return $$ref{ctag};
}

sub reptopstatxlnecom {
	my $this = shift;

	my ($ref) = @_;

	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	my $string = $this->get_linecommand
		('REPT-OPSTAT-XLNECOM', 'XDSL', $$ref{ctag}, $ref);

	return undef if !defined $string;

	my $result = $this->Execute ($string);
	return undef if  $this->is_error($$ref{ctag});

	$this->ParseSimpleOutputLines ($$ref{ctag});
	return $$ref{ctag};
}

sub reptopstatxbearer {
	my $this = shift;

	my ($ref) = @_;

	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	my $string = $this->get_linecommand
		('REPT-OPSTAT-XBEARER', 'XDSL', $$ref{ctag}, $ref);

	return undef if !defined $string;

	my $result = $this->Execute ($string);
	return undef if  $this->is_error($$ref{ctag});

	$this->ParseSimpleOutputLines ($$ref{ctag});

	return $$ref{ctag};
}

sub reptopstatxline {
	my $this = shift;

	my ($ref) = @_;

	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	my $string = $this->get_linecommand
		('REPT-OPSTAT-XLNE', 'XDSL', $$ref{ctag}, $ref);

	return undef if !defined $string;

	my $result = $this->Execute ($string);
	return undef if  $this->is_error($$ref{ctag});

	$this->ParseSimpleOutputLines ($$ref{ctag});

	return $$ref{ctag};
}

sub get_linecommand {
	my $this = shift;

	my ($cmd, $aid, $ctag, $ref) = @_;

	return undef if !defined $$ref{Target};
	return undef if !defined $$ref{Rack} || !defined $$ref{Shelf}
		|| !defined $$ref{Slot};
	#return undef if !defined $$ref{Circuit} &&
	#	(!defined $$ref{FirstCircuit} || !defined $$ref{LastCircuit});

	my $string = "$cmd:$$ref{Target}:$aid-$$ref{Rack}-$$ref{Shelf}";
	if (defined $$ref{Slot}) {
		$string .= "-$$ref{Slot}";
	}
	if (defined $$ref{Circuit}) {
		$string .= "-$$ref{Circuit}";
	} 
	if (defined $$ref{FirstCircuit} && defined $$ref{LastCircuit}) {
		$string .= "-$$ref{FirstCircuit}&&-$$ref{LastCircuit}";
	}
	$string .= ":$$ref{ctag}:;";
	$this->{Debug} && print STDERR "$string\n";
	return $string;
}

1;
__END__

=head1 NAME

  Net::TL1::Alcatel - Perl extension for managing Alcatel network
  devices using TL1

=head1 SYNOPSIS 

  use Net::TL1::Alcatel;

  $ctag = $obj->rtrvxdsl([{ctag => $ctag}]);
  $ctag = $obj->reptopstatxlnecom([{ctag => $ctag}]);
  $ctag = $obj->reptopstatxbearer([{ctag => $ctag}]);
  $ctag = $obj->reptopstatxline([{ctag => $ctag}]);
  $ctag = $obj->rtrvservprov([{ctag => $ctag}]):
  $ctag = $obj->rtrvservcurr ([{ctag => $ctag}]):
  $ctag = $obj->rtrvinvxdslcpe([{ctag => $ctag}]):
  $ctag = $obj->reptopstatatmport([{ctag => $ctag}]):

  Methods inherited from Net::TL1 :

  $obj = new Net::TL1 ({
    Host => $host,
    [Port => $port],
    [Debug => $val]
  });

  $obj->Login ({
    Target => $target,
    User => $username,
    Password => $password,
    [ctag => $ctag]
  });

  $obj->Logout ({Target => $target});

  $lines = $obj->Execute($cmd, [@output]);

  $bool = $obj->is_error($ctag);
  $ctag = $obj->get_ctag;
  $lines = $obj->ParseRaw;
  ($lines, $ctag) = $obj->ParseHeader;
  ($ref, $data, $status) = $obj->ParseAid($ctag, $line);
  $lines = $obj->ParseBody;
  $lines = $obj->ParseSimpleOutputLines($ctag);
  $lines = $obj->ParseCompoundOutputLines($ctag);

  $ctag = $obj->get_newctag;
  $ref = $obj->get_hashref([$ctag]);

  $obj->read_testfile($filename);
  $obj->dumpraw;

  $obj->close;

=head1 DESCRIPTION

  Transaction Language 1 is a configuration interface to network
  devices used in public networks. Through its very structured but
  human-readable interface it is very suitable to provide the glue for
  netwerk device <-> OSS integration.

  The Net::TL1::Alcatel module provides an interface to the AWS TL1
  gatway product of Alcatel. Several of the TL1 commands are directly
  supported using methods available in the class.

  Each of the methods require a reference to hash be passed with the 
  following keys:
  
    'Target': Name of the network device
    'Rack', 'Shelf', 'Slot'
    Either 'Circuit' or 'FirstCircuit' and 'LastCircuit' to support 
    ranges of ports.
    'ctag': The ctag key is optional. If none is provided then a ctag
    will be randomly assigned.
	
  Please see the Net::TL1 POD documentation for detailed documentation
  of the module.

=head2 REQUIRES

  Net::TL1

=head2 EXPORT

  (none)

=head1 AUTHOR

  Steven Hessing, E<lt>stevenh@xsmail.comE<gt>

=head1 SEE ALSO

=item L<http://www.tl1.com/>

=item Net::TL1

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2005, Steven Hessing. All rights reserved. This
  program is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.

=cut

