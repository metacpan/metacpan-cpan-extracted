
=head1 NAME

XBase::Memo - Generic support for various memo formats

=cut

package XBase::Memo;

use strict;
use XBase::Base;

use vars qw( $VERSION @ISA );
@ISA = qw( XBase::Base );
$VERSION = '0.129';

# Read header is called from open to fill the object structures
sub read_header
	{
	my $self = shift;
	my %options = @_;

	my $header;
	$self->read($header, 512) == 512 or do
		{ $self->Error("Error reading header of $self->{'filename'}: $!\n"); return; };

	my ($next_for_append, $block_size, $version);
	my $filename = $self->{'filename'};
	if ($filename =~ /\.fpt$/i)
		{
		($next_for_append, $block_size) = unpack 'N@6n', $header;
		$version = 5;
		bless $self, 'XBase::Memo::Fox';
		}
	elsif ($filename =~ /\.smt$/i) {
		($next_for_append, $block_size) = unpack 'VV', $header;
		bless $self, 'XBase::Memo::Apollo';
		}
	else
		{
		($next_for_append, $version, $block_size)
					= unpack 'V @16C @20v', $header;
		my $dbf_version = $options{'dbf_version'};
		$dbf_version = 15 unless defined $dbf_version;
		if ((($dbf_version & 15) == 3) or $version == 3)
			{
			$block_size = 512;
			$version = 3;
			bless $self, 'XBase::Memo::dBaseIII';
			}
		else
			{
			$version = 4;
			bless $self, 'XBase::Memo::dBaseIV';
			}
		}

	$block_size = 512 if int($block_size) == 0;

	$next_for_append = int ((((-s $self->{'filename'}) - 1) / $block_size) + 1);

	@{$self}{ qw( next_for_append header_len record_len version ) }
		= ( $next_for_append, $block_size, $block_size, $version );

	$self->{'memosep'} = $options{'memosep'};

	1;
	}

sub write_record
	{
	my ($self, $num) = (shift, shift);
	my $length = length(join '', @_);
	my $record_len = $self->{'record_len'};
	my $num_of_blocks = int (($length + $record_len - 1) / $record_len);
	$self->SUPER::write_record($num, @_);
	if ($num < 0 or $num > $self->last_record())
		{
		my $packed = pack "V", $num + $num_of_blocks + 1;
		if (ref $self eq 'XBase::Memo::Fox')
			{ $packed = pack "N", $num + $num_of_blocks + 1; }
		$self->SUPER::write_to(0, $packed);
		$self->{'next_for_append'} = $num + $num_of_blocks + 1;
		}
	$num;
	}

sub last_record	{ shift->{'next_for_append'} - 2; }

sub create
	{
	my $self = shift;
	my %options = @_;
	$self->create_file($options{'name'}) or return;
	my $version = $options{'version'};
	$version = 3 unless defined $version;
	$version = 0 if $version == 4;
	my $header = $self->write_to(0, pack 'VVa8Ca3va490', 1, 0,
			$options{'dbf_filename'}, $version, '', 512, '')
						or return;
	$self->close();
	return $self;
	}


# ################################
# dBase III+ specific memo methods

package XBase::Memo::dBaseIII;

use XBase::Base;
use vars qw( @ISA );
@ISA = qw( XBase::Memo );

sub read_record
	{
	my ($self, $num) = @_;
	my $result = '';
	my $last = $self->last_record();
	if (not defined $self->{'memosep'}) {
		$self->{'memosep'} = "\x1a\x1a";
		if (not defined $self->read_record($last)) {
			$self->{'memosep'} = "\x1a";
			if (not defined $self->read_record($last)) {
				$self->{'memosep'} = "\x1a\x1a";
				}
			}
		}

	while ($num <= $last)
		{
		my $buffer = $self->SUPER::read_record($num, -1) or return;
		my $index = index($buffer, $self->{'memosep'});
		if ($index >= 0)
			{ return $result . substr($buffer, 0, $index); }
		$result .= $buffer;
		$num++;
		}
	return;
	}

sub write_record
	{
	my ($self, $num) = (shift, shift);
	my $type = shift;
	my $data = join "", @_, "\x1a\x1a";
	if ($num >= 0 and $num <= $self->last_record())
		{
		my $buffer = $self->read_record($num);
		if (defined $buffer)
			{
			my $length = length $buffer;
			my $record_len = $self->{'record_len'};
			my $space_in_blocks =
				int (($length + $record_len - 3) / $record_len);
			my $len_in_blocks =
				int ((length($data) + $record_len - 1) / $record_len);
			if ($len_in_blocks > $space_in_blocks)
				{ $num = $self->last_record() + 1; }
			}
		}
	else
		{ $num = $self->last_record() + 1; }
	$self->SUPER::write_record($num, $data);
	$num;
	}

# ################################
# dBase IV specific memo methods

package XBase::Memo::dBaseIV;

use XBase::Base;
use vars qw( @ISA );
@ISA = qw( XBase::Memo );

sub read_record
	{
	my ($self, $num) = @_;
	my $result = '';
	my $last = $self->last_record;

	my $buffer = $self->SUPER::read_record($num, -1);
	if (not defined $buffer) { return; }
	my $unpackstr;
	if (ref $self eq 'XBase::Memo::Fox')
		{ $unpackstr = 'NN'; }
	else
		{
		$unpackstr = 'VV';
		return unless substr($buffer, 0, 4) eq "\xff\xff\x08\x00";
		}
	my ($unused_id, $length) = unpack $unpackstr, $buffer;
	$length += 8 if ref $self eq 'XBase::Memo::Fox';

	my $block_size = $self->{'record_len'};
	if ($length < $block_size)
		{ return substr $buffer, 8, $length - 8; }
	my $rest_length = $length - $block_size;
	my $rest_data = $self->SUPER::read_record($num + 1, $rest_length);
	if (not defined $rest_data) { return; }
	return substr($buffer, 8) . $rest_data;
	}

sub write_record
	{
	my ($self, $num) = (shift, shift);
	my $type = shift;
	my $data = join "", @_;
	my $length = (length $data) + 8;

	my $startfield = "\xff\xff\x08\x00" . pack('V', $length);
	if (ref $self eq 'XBase::Memo::Fox')
		{
		if ($type eq 'P')	{ $startfield = pack 'N', 0; }
		elsif ($type eq 'M')	{ $startfield = pack 'N', 1; }
		else			{ $startfield = pack 'N', 2; }
		$startfield .= pack 'N', ($length - 8);
		}
	### $data = $startfield . $data . "\x1a\x1a";
	$data = $startfield . $data;

	if ($num >= 0 and $num <= $self->last_record())
		{
		my $buffer = $self->read_record($num);
		if (defined $buffer)
			{
			my $length = (length $buffer) - 8;
			my $record_len = $self->{'record_len'};
			my $space_in_blocks =
				int (($length + $record_len - 11) / $record_len);
			my $len_in_blocks =
				int ((length($data) + $record_len - 1) / $record_len);
			if ($len_in_blocks > $space_in_blocks)
				{ $num = $self->last_record() + 1; }
			}
		else
			{ $num = $self->last_record() + 1; }
		}
	else
		{ $num = $self->last_record() + 1; }
	my $fill = $self->{'record_len'} - (( length $data ) % $self->{'record_len'});
	$data .= "\000" x $fill;
	$self->SUPER::write_record($num, $data);
	$num;
	}


# #######################################
# FoxPro specific memo methods (fpt file)

package XBase::Memo::Fox;

use XBase::Base;
use vars qw( @ISA );
@ISA = qw( XBase::Memo::dBaseIV );

# #######################################
# Apollo specific memo methods (smt file)
#
# This is a real hack! No documentation used but it works for all files
# i have tested with. 
#					Dirk Tostmann (tostmann@tiss.com)

package XBase::Memo::Apollo;

use XBase::Base;
use vars qw( @ISA );
@ISA = qw( XBase::Memo::dBaseIV );

sub read_record
	{
	my ($self, $num) = @_;
	my $result = '';

	return if $num =~ /^\s+$/;

	my ($block, $len, $offset) = unpack('vVV', $num);
	$block *= 8;

	$result = $self->read_from($offset * $block, $len);

	$result;
	}

sub write_record
	{
	my ($self, $num, $type) = (shift, shift, shift);
	my $data = join "", @_;
	my $length = length $data;
	$num = $self->SUPER::write_record($self->{'next_for_append'}, $data);
	if (defined $num and $num) {
		pack 'vVV', $self->{'block_length'} / 8 , $length, $num;
		}
	else { ' ' x 10; }
	}
1;

__END__

=head1 SYNOPSIS

Used indirectly, via XBase. Users should check its man page.

=head1 DESCRIPTION

Objects of this class are created to deal with memo files, currently
.dbt, .fpt and .smt (code for this provided by Dirk Tostmann).
Package XBase::Memo defines methods B<read_header> to parse that header
of the file and set object's structures, B<write_record> and
B<last_record> to write the records properly formated and find the end
of file.

There are four separate subpackages in XBase::Memo, dBaseIII, dBaseIV,
Fox and Apollo. Memo objects are effectively of one of these types and
they override their specific record handling routines where
appropriate.

=head1 VERSION

0.129

=head1 AUTHOR

(c) 1997--1999 Jan Pazdziora, adelton@fi.muni.cz

=head1 SEE ALSO

perl(1), XBase(3)

=cut

