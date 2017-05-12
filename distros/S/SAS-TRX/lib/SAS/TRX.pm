package SAS::TRX;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.07';

use IO::File;

#
#	Constructor
#
sub new
{
	my $class	= shift;
	my $self	= {
		FH => undef,
		TRX => {},
	};
	
	bless ($self,$class);
        return $self;
}

#
#	Given a file named
#
sub load
{
	my $self	= shift;
	my $src		= shift;

	$self->{FH} = new IO::File $src;

	$self->read_trx();
}

my $LIBRARY_HEADER = 'HEADER RECORD*******LIBRARY HEADER RECORD!!!!!!!000000000000000000000000000000  ';
my $NAMESTR_HEADER = 'HEADER RECORD\*\*\*\*\*\*\*NAMESTR HEADER RECORD!!!!!!!000000(\d{4})00000000000000000000';
my $MEMBER_HEADER  = 'HEADER RECORD\*\*\*\*\*\*\*MEMBER  HEADER RECORD!!!!!!!000000000000000001600000000(\d{3})';
my $DSCRPTR_HEADER = 'HEADER RECORD*******DSCRPTR HEADER RECORD!!!!!!!000000000000000000000000000000  ';
my $OBS_HEADER	   = 'HEADER RECORD*******OBS     HEADER RECORD!!!!!!!000000000000000000000000000000  ';

#
#	Get LIBRARY header. Abort if not found
#
sub library_hdr
{
	my $self	= shift;

	my ($tmp, %lhdata);

	read $self->{FH}, $tmp, 80;
	die "LIBRARY header not found:$tmp:" unless $tmp eq $LIBRARY_HEADER;

	read $self->{FH}, $tmp, 80;
	@lhdata{qw(SYMBOL1 SYMBOL2 LIB VER OS CREATE)} = unpack '(A8)4 A32 A16', $tmp;

	read $self->{FH}, $tmp, 80;
	@lhdata{qw(DATETIME16)} = unpack 'A16', $tmp;

	@{$self}{qw(LIB VER)} = @lhdata{qw(LIB VER)};
}

#
#	Get member descriptor data
#
sub descriptor_hdr
{
	my $self	= shift;

	my ($tmp, %mhdata);

	read $self->{FH}, $tmp, 80;
	die "DSCRPTR header not found" unless ($tmp eq $DSCRPTR_HEADER);

	read $self->{FH}, $tmp, 80;
	@mhdata{qw(SYMBOL DSNAME SASDATA OS BLANKS CREATE)} = unpack '(A8)5 A24 A16', $tmp;

	read $self->{FH}, $tmp, 80;
	@mhdata{qw(DATETIME16 BLANKS DSLABEL DSTYPE)} = unpack 'A16 A16 A40 A8', $tmp;

	return @mhdata{qw{DSNAME DSLABEL DSTYPE}};
}

#
#	Get NAMESTR header. Return number of NAMESTR records
#
sub namestr_hdr
{
	my $self = shift;

	my ($tmp, $nnames);
	read $self->{FH}, $tmp, 80;

	die 'NAMESTR header not found' unless ($tmp =~ m/$NAMESTR_HEADER/o);
	return $1;
}

#
#	Get NAMESTR record
#
sub namestr_rec
{
	my $self	= shift;
	my $reclen	= shift;

	my ($tmp, %nsdata);

	read $self->{FH}, $tmp, $reclen;
	@nsdata{qw(NTYPE NHFUN NLNG NVAR0 NNAME NLABEL NFORM NFL NFD NFJ NFILL NIFORM NIFL NIFD NPOS REST)} = unpack 'n4 A8 A40 A8 n3 A2 A8 n2 N A52', $tmp;
	return \%nsdata;
}

#
#	Get OBS header
#
sub obs_hdr
{
	my $self	= shift;

	my $tmp;
	read $self->{FH}, $tmp, 80;

	die "OBS header not found:$tmp:" unless ($tmp eq $OBS_HEADER);
}


#
#	Read library member
#
sub get_member
{
	my $self	= shift;

	my ($vars, $i, $tmp);

	my $nstr_len	= $self->{NSTR_LEN};

	my ($dsname, $dslabel, $dstype) = $self->descriptor_hdr();
	$self->{TRX}{$dsname}{DSLABEL} = $dstype;
	$self->{TRX}{$dsname}{DSTYPE}  = $dstype;

	# Dataset structure description
	$vars = $self->namestr_hdr();
	for ($i=0; $i < $vars; $i++) {
		push @{ $self->{TRX}{$dsname}{VAR} }, $self->namestr_rec($nstr_len);
	}
	# Align to the next punch card
	if ($vars * $nstr_len % 80) {
		seek($self->{FH}, 80 - $vars * $nstr_len % 80, 1);
	}



	my ($databuf, $rowlen, $var, $format, @types);
	# Compute row length	
	$tmp = $#{$self->{TRX}{$dsname}{VAR}};
	$rowlen = $self->{TRX}{$dsname}{VAR}[$tmp]{NPOS}+
		$self->{TRX}{$dsname}{VAR}[$tmp]{NLNG};

	$self->{TRX}{$dsname}{CNAMES} = [];
	$self->{TRX}{$dsname}{CTYPES} = [];
	# Compute conversion formats.
	foreach $var (@{ $self->{TRX}{$dsname}{VAR} }) {
		$format .= 'a' . $var->{NLNG};

		# Remember just a list of variable names
		push @{$self->{TRX}{$dsname}{CNAMES}}, $var->{NNAME};
		# And types
		push @{$self->{TRX}{$dsname}{CTYPES}}, $var->{NTYPE};
	}

	# Upload to destination. May create header for compressed INSERT
	$self->data_header($dsname) if ($self->can('data_header'));

	# Observation data
	$self->obs_hdr();
	$databuf='';
	while (read( $self->{FH}, $tmp, 80 )) {
		$databuf .= $tmp;
		last if $databuf =~ m/$MEMBER_HEADER/o;

		while (length($databuf) >= $rowlen) {
			$self->row2array($dsname, $databuf, $format);
			$databuf = substr($databuf, $rowlen);
			last unless $databuf =~ /[^ ]/go;
		}
		last if eof $self->{FH};	# read after eof may be wrong
	}
	$self->{NSTR_LEN} = $1;	# In case the library is joined from various platforms data

	# Upload to destination. May create header for compressed INSERT
	$self->data_footer($dsname) if $self->can('data_footer');
}

#
#	Convert TRX observation (data row)
#	into array of values
#
sub row2array
{
	my ($self, $dsname, $row, $format) = @_;


	my @data = unpack($format, $row);
	
	for (my $i=0; $i<= $#data; $i++) {
		if ($self->{TRX}{$dsname}{CTYPES}[$i] == 1) {
			$data[$i] = ibm_float($data[$i]);
		} else {
			# Trim whitespaces
			$data[$i] =~ s/\s+$//;
			$data[$i] =~ s/^\s+//;
		}
	}

	# Unload to target
	$self->data_row($dsname, \@data) if $self->can('data_row');
}

#
#	Decrypt TRX numeric representation
#
#	I agree that "significand" is "that which is to be signified".
#	Let the meaningful part be "mantissa". As it was before.
#	
sub ibm_float
{
	my $value = shift;

	my ($firstbyte,$bin) = unpack "CB*", $value;

	if ($bin == 0) {
		return	undef	if ($firstbyte);	# Undefined values
		return	0;
	}

	my $exp=($firstbyte & 0x7F) - 0x40;
	my $mantissa = 0;

	while (length($bin)) {
		$mantissa += 1 if (chop $bin);
		$mantissa /= 2;
	}

	$mantissa = -$mantissa	if ($firstbyte & 0x80);
	return	$mantissa*(16**$exp);
}

#
#	Read library
#
sub read_trx
{
	my $self	= shift;

	my ($tmp, $nstr_len);

	$self->library_hdr();

	# Skip possible junk until member header
	do {
		read $self->{FH}, $tmp, 80;
	} until (eof($self->{FH}) || $tmp =~ m/$MEMBER_HEADER/o);
	$self->{NSTR_LEN} = $1;

	# Get library members
	until (eof($self->{FH})) {
		$self->get_member();
	}
	# We have got it all. Dump the results, if anybody cares
	$self->data_description() if $self->can('data_description');
}


1;

__END__

=head1 NAME

SAS::TRX - [Abstract] class, provides SAS transport (XPORT) format decoding.
Calls [overloaded] methods for subsequent output formatting.

=head1 SYNOPSIS

  use base SAS::TRX;

  Provides SAS TRX-related functionality for a child.

=item B<load>

  my $trx = new SAS::TRX;
  $trx->load('filename'); # load and parse 'filename'.

  During the parse will call the following [child] methods, if available:

    data_header		- after all NAMESTR blocks for a TRX library member
			  have been parsed, a list of columns is available
    data_row		- for each observation
    data_footer		- after OBS block has been parsed
    data_description	- at the end of TRX parsing

  

=head1 DESCRIPTION

SAS transport format (XPORT) access

The following deviations from standard are allowed:
	1. Numbers can be any length >1 bytes, exponent is always 7 bit
	2. "Missing values" may have any non-zero exponent

Removes leading and trailing whitespaces while character values transformation.

=head2 EXPORT

Nothing is exported.


=head1 SEE ALSO

SAS::TRX::MySQL for example of usage

TS-140 (http://support.sas.com/techsup/technote/ts140.html)
for format description


=head1 AUTHOR

Alexander Kuznetsov, <acca (at) cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Alexander Kuznetsov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
