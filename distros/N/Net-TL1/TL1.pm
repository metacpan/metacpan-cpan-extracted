package Net::TL1;

# Copyright (c) 2005, Steven Hessing. All rights reserved. This
# program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use Net::Telnet;

use 5.006;
use strict;
use warnings;

use FileHandle;

our $VERSION = '0.05';

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;

	my $ref = shift;
	$self->{Debug} = defined $$ref{Debug} ? $$ref{Debug} : 0;
	$self->{Port} = defined $$ref{Port} ? $$ref{Port} : 14000;
	$self->{Telnet} = new Net::Telnet (Timeout => 60, Port => $self->{Port},
		Prompt => '/;/', Errmode => 'return');
	if (defined $$ref{Host}) {
		$self->{Host} = $$ref{Host};
		($self->{Telnet})->open($self->{Host});
	}

	#
	# The values below only hold the data of the last executed command
	#
	$self->{Target} = '';
	$self->{Date} = '';
	$self->{Time} = '';
	@{$self->{Result}{Raw}} = ();

	#
	# These variables hold data of all executed commands as long
	# as they had unique ctags
	#
	%{$self->{Commands}} = ();
	@{$self->{ctags}} = ();

	return $self;
}

sub close {
	my $this = shift;

	$this->{Telnet}->close;
	return $this->{Telnet} = undef;
}

sub get_hashref {
	my $this = shift;

	my ($ctag) = @_;
	$ctag = $this->{ctags}[@{$this->{ctags}} - 1]
		if !defined $ctag;

	return $this->{Commands}{$ctag}{Hash};
}

###
### $tl1->Execute ($command [, @lines])
###
### $command: TL1 command to be executed
### @lines: If included, does not perform actual query but takes
### the @lines as simulated output of the command
####
sub Execute {
	my $this = shift;

	my @lines = @_;
	return undef if !defined $this->{Telnet} && ! @lines;

	my $cmd = shift;
	$this->{Debug} > 3 && print STDERR "EXECUTE: $cmd\n";

	if (! @lines) {
		@{$this->{Result}{Raw}} = $this->{Telnet}->cmd ($cmd);
	} else {
		@{$this->{Result}{Raw}} = @lines;
	}
	return $this->ParseRaw;
}

sub ParseSimpleOutputLines {
	my $this = shift;

	my ($ctag) = @_;

	foreach my $line (@{$this->{Commands}{$ctag}{Output}}) {
		if ($line =~ /^\s*"(\w+)-(\d+)-(\d+)-(\d+)-(\d+):(\w+),(.*)"\s*$/) {
			my ($aid, $rack, $shelf, $slot, $port, $param, $value) = 
				($1, $2, $3, $4, $5, $6, $7);
			if ($value =~ /^\s*\\"(.*)\\"\s*$/) {
				$value = $1;
			}
			$this->{Debug} > 6 && print STDERR "DATA: $param -> $value\n";

			$this->{Commands}{$ctag}{Hash}{$aid}{$rack}{$shelf}{$slot}{$port}{$param} = $value;
		} else {
			$this->{Debug} > 4 && print STDERR "Couldn't parse: $line\n";
		}
	}
	return scalar(@{$this->{Commands}{$ctag}{Output}});
}

sub ParseAid {
	my $this = shift;

	my ($ctag, $line) = @_;

	my ($ref, $data, $status);
	my ($aid, $rack, $shelf, $slot, $port);
	if ($line =~ /^^\s*"(\w+)-([-\d]+):+(.*)$/) {
		
		$aid = $1;
		($rack, $shelf, $slot, $port) = split /-/, $2;
		$this->{Debug} > 5 && print STDERR "DATA: $aid-$rack-$shelf-$slot";
	
		if (!defined $port) {
			$ref =
				$this->{Commands}{$ctag}{Hash}{$aid}{$rack}{$shelf}{$slot} =
				{};
		} else {
			$ref =
			   $this->{Commands}{$ctag}{Hash}{$aid}{$rack}{$shelf}{$slot}{$port}
			   = {};
			$this->{Debug} > 5 && print STDERR "-$port";
		}
		$this->{Debug} > 5 && print STDERR "\n";
		$data = $3;
	}
	
	#
	# Remove trailing ," from line, the comma is not always present.
	#
	if ($data =~ /(.*),*"\s*$/) {
		$data = $1;
	}
	
	#
	# Some commands include an IS-NR, OS-NR status at the end, behind a colon
	#
	if ($data =~ /^(.*):(\S+?),*$/) {
		$status = $2;
		$data = $1;
	}
		
	return ($ref, $data, $status);
}

sub ParseCompoundOutputLines {
	my $this = shift;

	my ($ctag) = @_;

	foreach my $line (@{$this->{Commands}{$ctag}{Output}}) {
		my ($ref, $data, $status) = $this->ParseAid ($ctag, $line);
		if (defined $ref) {
			if (defined $status ) {
				$$ref{Status} = $status;
			}
			my $count = 0;
			$data .= ",";
			while (length $data && $count++ < 100) {
				$this->{Debug} > 6 && print STDERR "DATA: $data\n";
				if ($data=~ /^(\w+)=([^,]*?),(.*)$/) {
					#
					# We already have a generic match, let's see
					# if we can do a more specific match, in these
					# case a value that is surrounded by \" ... \"
					# $1, $2 etc will be set by the last succesfull match
					#
					$data =~ /^(\w+)=\\"(.*?)\\",(.*)$/;
					my ($param, $value) = ($1, $2);
					$this->{Debug} > 5 &&
						print STDERR "PARAM: $param -> $value\n";
					$data = $3;
					$$ref{$param} = $value;
				}
			}
			die "No match\n" if ($count > 90);
		} else {
			$this->{Debug} > 4 && print STDERR "Couldn't parse: $line\n";
		}
	}
	return scalar(@{$this->{Commands}{$ctag}{Output}});
}

sub ParseRaw {
	my $this = shift;

	my $lines = @{$this->{Result}{Raw}};
	if ($this->{Debug} > 4) {
		foreach my $line (@{$this->{Result}{Raw}}) {
			print STDERR "RAW: $line";
		}
	}
	my $index = 0;
	my ($skip, $ctag);
	my $ctag_added = 0;
	do {
		($skip, $ctag) = $this->ParseHeader($index);
		if (! $ctag_added) {
			push @{$this->{ctags}}, $ctag;
			$ctag_added = 1;
		}

		$this->{Debug} > 2 && print STDERR "Skip $skip lines for header\n";
		# If no header present then skip will be 0
		if ($skip) {
			$index += $skip;
			$skip = $this->ParseBody($index, $ctag);
			$this->{Debug} > 2 &&  print STDERR "Skip $skip lines for body\n";
			$index += $skip;
		}
	} until ($index >= ($lines - 1) || $skip == 0);
	return defined $ctag ?  $this->{Commands}{$ctag}{Result} : undef;
}

sub ParseHeader {
	my $this = shift;

	my ($start) = @_;

	my $lines = @{$this->{Result}{Raw}} - 1;
	my $read;
	foreach my $index ($start .. $lines) {
		$this->{Debug} > 3 &&
			print STDERR "READ($index): $this->{Result}{Raw}[$index]";
		if ($this->{Result}{Raw}[$index] =~
				/^\s*(\S+)\s+(\d{2}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})/) {
			$this->{Target} = $1;
			$this->{Date} = $2;
			$this->{Time} = $3;
			$read = $index;
			$this->{Debug} > 3 && print STDERR "SET ($index) Target to $1\n";
			last;
		}
	}

	my $line = $this->{Result}{Raw}[++$read];
	$this->{Debug} > 3 && print STDERR "READ ($read): $line";
	my $ctag;
	my $rc;
	if ($line =~ /^\s*M\s+(\d+)\s+(\S+)\s*$/) {
		$ctag = $1;
		$this->{Debug} > 3 && print STDERR "SET ($read) CTAG to $1\n";
		$this->{Debug} > 3 && print STDERR "SET ($read) Result to $2\n";
		$rc = $this->{Commands}{$ctag}{Result} = $2;
	}
	$line = $this->{Result}{Raw}[++$read];
	if (defined $line) {
		$this->{Debug} > 3 && print STDERR "READ ($read): $line";
		if ($line =~ /^\s*\/\*\s*(\S+)\s*\*\/\s*$/) {
			$this->{Debug} > 3 && print STDERR "SET ($read) Command to $1\n";
			$this->{Commands}{$ctag}{Command} = $1;
		}
	} else {
		$read--;
	}
	if (defined $rc && $rc eq 'DENY') {
		$line = $this->{Result}{Raw}[++$read];
		if (defined $line) {
			$this->{Debug} > 3 && print STDERR "READ: $line\n";
			$this->{Debug} > 3 && print STDERR "SET ($read): Error to $line\n";
			$this->{Commands}{$ctag}{Error} = $line;
		}
		return 0;
	}
	return ($read + 1 - $start, $ctag);
}

sub ParseBody {
	my $this = shift;

	my ($start, $ctag) = @_;

	my $lines = @{$this->{Result}{Raw}};
	my $read = $lines - $start;
	$this->{Debug} > 0 && print STDERR "BODY contains $read lines\n";
	return 0 if ($read <= 0);
	my $line = "";
	foreach my $index ($start .. $lines - 1) {
		$this->{Debug} > 1 &&
			print STDERR "BODY ($index): $this->{Result}{Raw}[$index]";
		$read = $index;
		if ($this->{Result}{Raw}[$index] !~ /^\s*$/) {
			last if $this->{Result}{Raw}[$index] =~
				/\/\* More Output Follows \*\//;
			if ($this->{Result}{Raw}[$index] !~ /^\s*\/\*.*\*\/\s*$/) {
				if ($this->{Result}{Raw}[$index] =~ /^\s*(\S+.*\S+)\s*$/) {
					$this->{Result}{Raw}[$index] = $1;
				}
				$line .= $this->{Result}{Raw}[$index];
				if ($this->{Result}{Raw}[$index] =~ /"\s*$/) {
					push @{$this->{Commands}{$ctag}{Output}}, $line;
					$line = "";
				}
			}
		}
	}
	return $read + 1 - $start;
}

sub Login {
	my $this = shift;

	my ($ref) = @_;
	return if !defined $$ref{Target};

	return if !defined $$ref{User} || !defined $$ref{Password};
	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	return $this->Execute
		("ACT-USER:$$ref{Target}:$$ref{User}:$$ref{ctag}::$$ref{Password};");
}

sub Logout {
	my $this = shift;

	my ($ref) = @_;
	return if !defined $$ref{Target};

	my $cmd = "CANC-USER:$$ref{Target}:";

	$cmd .= $$ref{User} if (defined $$ref{User});

	$$ref{ctag} = defined $$ref{ctag} ? $$ref{ctag} : $this->get_newctag();

	$cmd .= ":$$ref{ctag}:;";

	return $this->Execute ($cmd);
}

sub dumpraw {
	my $this = shift;

	print STDERR "$this->{Target} - $this->{Time} - $this->{Date}\n";
	foreach my $ctag (@{$this->{ctags}}) {
		print STDERR "CTAG: $ctag -> $this->{Commands}{$ctag}{Command} -> $this->{Commands}{$ctag}{Result}\n";
		if ($this->is_error($ctag)) {
			print STDERR "Error: $this->{Commands}{$ctag}{Error}\n";
		} else {
			foreach my $line (@{$this->{Commands}{$ctag}{Output}}) {
				print STDERR "-> $line\n";
			}
		}
	}
}

sub read_testfile {
	my $this = shift;

	my ($file) = @_;

	my $fh = new FileHandle;
	$fh->open ($file) || return undef;
	my @lines = <$fh>;
	$fh->close;

	my %result;
	while (@lines) {
		my $line;
		while ($line = shift @lines) {
			last if $line =~ /^\s*;/;
		}
		if (defined $line && $line =~ /^\s*;(.*?;)\s*$/) {
			my $command = $1;
			$this->{Debug} > 3 && print STDERR "TESTCOMMAND: $command\n";
			while(my $output = shift @lines) {
				if ($output =~ /^\s*;/) {
					unshift @lines, $output;
					last;
				}
				if ($output =~ /^\s*FreezeThaw\s*(.*)$/) {
					$this->{Debug} > 3 && print STDERR "TESTFT: $1\n";
					$result{$command}{FreezeThaw} = $1;
				} else {
					$this->{Debug} > 3 && print STDERR "TESTOUTPUT: $output\n";
					push @{$result{$command}{output}}, $output;
				}
			}
		}
	}
	return \%result;
}

sub get_ctag {
	my $this = shift;

	if (@{$this->{ctags}}) {
		return $this->{ctags}[@{$this->{ctags}} - 1];
	} else {
		return undef;
	}
}

sub get_newctag {
	my $this = shift;

	return int(rand(1000000));
}

sub is_error {
	my $this = shift;

	my ($ctag) = @_;

	return 1 if ($this->{Commands}{$ctag}{Result} ne 'COMPLD');
	return 0;
}

1;
__END__

=head1 NAME

Net::TL1 - Perl extension for managing network devices using TL1

=head1 SYNOPSIS

  use Net::TL1;

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
devices used in public networks. With its very structured but
human-readable interface it is very suitable to provide the glue for
netwerk device <-> OSS integration.

TL1 can be used as a Command-Line-Interface (CLI) as found on many
switches and routers. However, interaction with TL1-capable network
devices can also be easily automated because input and output in TL1
are so tightly defined. As such TL1 is somewhere in between a CLI and
SNMP. It is usable for humans but interaction can also be easily
automated.

To use TL1 you will need network devices that support TL1 or a gateway
application that translates between TL1 and the command interface as
supported by the device. Such a gateway would typically be provided by
the vendor of the network equipment. Net::TL1 can then be used to
connect to the TL1 device or gateway and issue commands and parse
the resulting output. This output is then stored in easily accessable
data structures.

At this time the support in Net::TL1 for the different TL1
implementations and its commands and features is quite limited. It is
only known to work with Alcatel 7301 ASAM DSLAMs and then only a subset
of its TL1 commands are supported. But Net::TL1 does provide at this
stage a framework to base further development on and is actually used
to automatically provision a DSL network.

=head2 REQUIRES

  Net::Telnet

=head2 EXPORT

  (none)

=head2 INSTALL

The basic:
  tar zxvf Net-TL1-x.xx.tar.gz
  cd Net-TL1-x.xx.tar.gz
  perl Makefile.PL
  make
  make test
  make install

=head2 Getting started

Getting started with Net::TL1 requires that you already have a TL1-
capable device or gateway that Net::TL1 can speak to. From now on I'll
refer to this device or gateway as the TL1 gateway. Furthermore, you'll
ofcourse need to have a copy of perl, Net::Telnet and Net::TL1
installed.

To use the functionality provided by Net::TL1 your script should
include the following lines:

  use Net::TL1;
  $obj = new Net::TL1 ({Host => $host, Port => $port});

with $host being the IP address of the TL1 gateway and Port being the 
tcp port on which the TL1 gateway is listening for incoming sessions.
You can then use the 'Login' method to establish a session with the 
network device:

  $obj->Login ({Target => $target, User => $username,
                Password => $password [, ctag => $ctag}] );

The ctag is a numeric message identifier used in the TL1 specification.
It is used to correlate commands and their output. If you omit it then
Net::TL1 will generate a random ctag and assign it to a command.

You can then issue TL1 commands using the `Execute' method, e.g.:

  $rv = $obj->Execute ('REPT-OPSTAT-XBEARER:PR-DSLAM1:XDSL-1-1-2-1:111:;');

The $rv will hold the TL1 result code of the command. The exact syntax of
the command is defined by the vendor of the network device. In this case,
the command requests certain configuration parameters of an ADSL2+ line
on an Alcatel ASAM7301 DSLAM. The resulting TL1 output is then stored in
the object for later parsing.

In the example above we used a ctag of 111. If we wouldn't have 
specified the ctag then Net::TL1 would have automatically assigned a
ctag. This tag is required for later processing of the output. If you
didn't specify a ctag then you can find out what ctag was generated
using:

  $ctag = $obj->get_ctag;

When parsing the output of TL1 commands I've found two different formats.
For each of the formats you need a different parser. You will need to
experiment which parser is right for which command. The parser is then
called as:

  $lines = $obj->ParseSimpleOutputLines($ctag);

or

  $lines = $obj->ParseCompoundOutputLines($ctag);

These parsers store the results of the TL1 command in hashes of hashes
datastructures. $lines is the number of lines parsed in the output.
With the `get_hashref' method you can get access to these datastructures:

  $ref = $obj->get_hashref([$ctag]);

You can then use something like the Dumper function in the Data::Dumper
module to view your data:

  use Data::Dumper;
  print Dumper($ref);

With the Logout method you can end your session with the network device
and with the close method you can disconnect from the TL1 gateway.

  $obj->Logout ({Target => $target});
  $obj->close;

=head2 Methods

  $obj = new Net::TL1 ({
    Host => $host,
    [Port => $port],             
    [Debug => $debug]               
  });

    Establishes the TCP connection to the TL1 gateway. $host is the IP
    address in string format of the TL1 gateway, which could be the same
    as the network device. $port is the TCP port on which the TL1 gateway
    is listening for incoming connections. It has a default value of
    14000. $debug has a default value of 0, the higher the value, the
    more debug output is provided.

  $lines = $obj->Login ({
    Target => $target,
    User => $username,
    Password => $password,
    [ctag => $ctag]                
  });

    The Login option sets up the TL1 session with a network device. The
    $target is the name of the network device, $username and $password
    provide the username and password. Optionally a $ctag value can be
    provided, if none is provided then a randon ctag will be provided.
    The return value is the number of output lines of the login command
    or `undef' if there was an error.

  $obj->Logout ({Target => $target});
    Closes the TL1 session with the network device. Returns the number
    of output lines generated by the TL1 gateway or `undef' if there
    was an error.

  $lines = $obj->Execute($cmd, [@output]);
    Executes $cmd on the TL1 gateway. Stores the output in $obj. 
    If @output is provided then the command is not actually send to
    the TL1 gateway and @output is used as simulated TL1 output. 
    This is useful for testing purposes.
    $lines containts the number of lines returned by the TL1 gateway
    or `undef' if there was an error.

  $ctag = $obj->get_ctag;
    Returns the ctag value of the last TL1 command executed. This
    method must be used if no ctag was specified in the last TL1
    command to further process the output of the TL1 command.

  $bool = $obj->is_error($ctag);
    Returns '1' if the last TL1 command was succesfully executed by
    the TL1 gateway or otherwise '0'.

  $lines = $obj->ParseRaw;
    Parses the raw output of the TL1 gateway to separate the output
    of different TL1 messages and to split these messages into
    headers and bodies. Used internally by the `Execute' method.
    Returns the number of lines parsed or `undef' if there was an
    error.

  ($lines, $ctag) = $obj->ParseHeader;
    Parses the TL1 output header of a command. Used internally.
    Returns the number of lines parsed and the ctag of the command
    of which the header output was parsed.

  ($ref, $data, $status) = $obj->ParseAid($ctag, $line);
    Parses a TL1 line in the body containing an AID, result
    parameters and possibly a status field. Used internally.
    Returns a reference to the hashes of hashes data-structure
    to store the parameters, the result parameters to be parsed,
    and if applicable, the TL1 status code (e.g. 'IS-NR').

  $lines = $obj->ParseBody;
    Parses the TL1 output body of a command. Used internally.
    Returns the number of lines parsed.

  $lines = $obj->ParseSimpleOutputLines($ctag);
    One of two available parsing functions to store the output of
    a TL1 command in a data structure. Returns the number of lines
    parsed or `undef' on error.

  $lines = $obj->ParseCompoundOutputLines($ctag);
    One of two available parsing functions to store the output of
    a TL1 command in a data structure. Returns the number of lines
    parsed or `undef' on error.

  $ctag = $obj->get_newctag;
    Returns a (pseudo-) randomly generated ctag.

  $ref = $obj->get_hashref([$ctag]);
    Returns a reference to a hash of hashes used to stored the
    parsed output of a TL1 command.

  $obj->read_testfile($filename);
    Reads a text file containing test data for validation of the
    methods. See the `TESTING' section.
         
  $obj->dumpraw;
     Prints out the raw output from the TL1 gateway.

  $obj->close;
     Closes the TCP connection with the TL1 gateway, returns `undef'.

=head2 DEVELOPMENT and TESTING

  With the release of 0.05, Net::TL1 has some test capabilities. The
  'read_testfile' method provides a means to read a test file. This
  test file contains a set of commands, each with the TL1 output
  of the command and a serialized representation of the data structure
  as created by the parsing functions.
  By providing the `Execute' method with the TL1 output from the test
  file, the output of an actual TL1 gateway can be simulated.
  The FreezeThaw module is used to serialize the data structures. The
  FreezeThaw output must be included on a separate line in the test
  file, prepended with the string `FreezeThaw ' for the 'read_testfile'
  to recognize the serialized data.

=head2 TODO

  - Net::TL1 should perform proper handling of blocks out outputed text
    conforming to the TL1 spec. A small problem is that the spec is not
    readily available but must be purchased from Telcordia.

=head1 AUTHOR

Steven Hessing, E<lt>stevenh@xsmail.comE<gt>

=head1 SEE ALSO

=item L<http://www.tl1.com/>

=item Net::TL1::Alcatel

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005, Steven Hessing. All rights reserved. This
program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

