package Net::FreeDB2::Entry;

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

require 5.005_62;
use strict;
use warnings;
use Error qw (:try);

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FreeDB2::Entry ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our ( $VERSION ) = '$Revision: 0.8.2.3 $ ' =~ /\$Revision:\s+([^\s]+)/;

my $DB_LINE_LEN_DEF = 256;

my $XMCD_RX =	'^\s*#\s*xmcd';
my $XMCD_ERR =	'# xmcd';
my $TFO_RX =	'^\s*#\s*Track\s+frame\s+offsets\s*:\s*$';
my $TFO_ERR =	'# Track frame offsets:';
my $FO_RX =	'^\s*#\s*(\d+)\s*$';
my $FO_ERR =	'# <number>';
my $DL_RX =	'^\s*#\s*Disc\s+length\s*:\s*(\d+)\s+seconds\s*$';
my $DL_ERR =	'# Disc length: <length> seconds';
my $REV_RX =	'^\s*#\s*Revision\s*:\s*(\d+)\s*';
my $REV_ERR =	'# Revision: <revision>';
my $SUB_RX =	'^\s*#\s*Submitted\s+via\s*:\s*(\S+)\s+(\S+)\s*(.*)\s*$';
my $SUB_ERR =	'# Submitted via: <client_name> <client_version> <optional_comments>';
my $DID_RX =	'^\s*DISCID\s*=\s*(\S+)\s*$';
my $DID_ERR =	'DISCID=<disc ID>';
my $DTITLE_RX =	'^\s*DTITLE\s*=(.*)$';
my $DYEAR_RX =	'^\s*DYEAR\s*=(.*)$';
my $DGENRE_RX =	'^\s*DGENRE\s*=(.*)$';
my $TTITLEN_RX =	'^\s*TTITLE(\d+)\s*=(.*)$';
my $EXTD_RX =	'^\s*EXTD\s*=(.*)$';
my $EXTTN_RX =	'^\s*EXTT(\d+)\s*=(.*)$';
my $CDPARA_TRACK_RX =	'^\s*(\d+)\.\s*(\d+)\s*\[\d+[:.]\d+[:.]\d+\]\s*(\d+)\s*\[\d+[:.]\d+[:.]\d+\]';
my $CDPARA_TOTAL_RX = '^\s*TOTAL\s+(\d+)';

sub new {
	my $class = shift;

	my $self = {};
	bless ($self, (ref($class) || $class));
	return ($self->_initialize (@_));
}

sub _initialize {
	my $self = shift;
	my $opt = shift || {};

	(defined ($opt->{fh}) or defined ($opt->{fn}) or defined ($opt->{array_ref})) and $self->read ($opt);
	defined ($opt->{dev}) and $self->readDev ($opt);
	return ($self);
}

sub read {
	my $self = shift;
	my $opt = shift || {};

	# Make an array reference out of $opt->{fh}, $opt->{fn} or
	# $opt->{array_ref}.
	# From http://www.freedb.org/src/latest/DBFORMAT :
	# The beginning of the first line in a database entry should consist of
	# the string "# xmcd". This string identifies the file as an xmcd format
	# CD database file. More text can appear after the "xmcd", but is
	# unnecessary.
	my $array_ref;
	my $lineNr = 1;;
	if (exists ($opt->{fh})|| exists ($opt->{fn})) {
		my $fh;
		if (exists ($opt->{fh})) {
			$fh = $opt->{fh};
		} elsif (exists ($opt->{fn})) {
			use IO::File;
			$fh = IO::File->new ("< $opt->{fn}");
		}
		defined ($fh) || throw Error::Simple ('ERROR: Net::FreeDB2::Entry::read, Failed to make file handle out of provided options.');
		
		my $line = $fh->getline ();
		chomp ($line);
		$line =~ /$XMCD_RX/ || throw Error::Simple ("ERROR: Net::FreeDB2::Entry::read, Expected '$XMCD_ERR' in line " . $lineNr . ' but encountered: ' . $line);

		my @array = ();
		while ($line = $fh->getline ()) {
			chomp ($line);
			push (@array, $line);
		}
		$array_ref = \@array;
	} elsif (exists ($opt->{array_ref})) {
		$array_ref = $opt->{array_ref};
		my $line = shift (@{$array_ref});
		$line =~ /$XMCD_RX/ || throw Error::Simple ("ERROR: Net::FreeDB2::Entry::read, Expected '$XMCD_ERR' in line " . $lineNr . ' but encountered: ' . $line);
	} else {
		throw Error::Simple ("ERROR: Net::FreeDB2::Entry::read, missing option 'fh', 'fn' or 'array_ref'");
	}


	# Tollerate '#.*' until '# Track frame offsets:'
	my $line;
	while ($line = shift (@{$array_ref})) {
		$lineNr++;
		($line =~ /$TFO_RX/i) && last;
		($line =~ /^\s*#/) && next;
		throw Error::Simple ("ERROR: Net::FreeDB2::Entry::read, Expected '$TFO_ERR' in line " . $lineNr . ' but encountered: ' . $line);
	}

	# Read frame offsets
	my $track = 1;
	while ($line = shift (@{$array_ref})) {
		$lineNr++;
		my ($off) = $line =~ /$FO_RX/;
		defined ($off) || last;
		$self->setFrameOffset ($track++, $off);
	}
	$track > 1 || throw Error::Simple ("ERROR: Net::FreeDB2::Entry::read, Expected '$FO_ERR' in line " . $lineNr . ' but encountered: ' . $line);

	# Read '# Disc length', '"# Revision', "# Submitted via' until 'DID'
	while ($line = shift (@{$array_ref})) {
		$lineNr++;
		my ($len) = $line =~ /$DL_RX/i;
		if (defined ($len)) {
			$self->setDiscLength ($len);
			next;
		}
		my ($rev) = $line =~ /$REV_RX/i;
		if (defined ($rev)) {
			$self->setRevision ($rev);
			next;
		}
		my ($name, $vers, $comm) = $line =~ /$SUB_RX/i;
		if (defined ($name)) {
			$self->setClientName ($name);
			$self->setClientVersion ($vers);
			$self->setClientComment ($comm);
			next;
		}
		my ($discid) = $line =~ /$DID_RX/i;
		if (defined ($discid)) {
			$self->setDiscID ($discid);
			last;
		}
		($line =~ /^\s*#/) && next;
		last;
	}
	$self->getDiscLength () || throw Error::Simple ("ERROR: Net::FreeDB2::Entry::read, Expected '$DL_ERR' in line " . $lineNr . ' but encountered: ' . $line);
	defined ($self->getRevision ()) || throw Error::Simple ("ERROR: Net::FreeDB2::Entry::read, Expected '$REV_ERR' in line " . $lineNr . ' but encountered: ' . $line);
	$self->getClientName () || throw Error::Simple ("ERROR: Net::FreeDB2::Entry::read, Expected '$SUB_ERR' in line " . $lineNr . ' but encountered: ' . $line);
	$self->getDiscID () || throw Error::Simple ("ERROR: Net::FreeDB2::Entry::read, Expected '$DID_ERR' in line " . $lineNr . ' but encountered: ' . $line);

	# Read DTITLE, DYEAR, DGENRE, TTITLEN, EXTD, EXTTN
	# Indeed, this code is a bit forgiving
	my $DTITLE = '';
	my $DYEAR = '';
	my $DGENRE = '';
	my @TTITLEN = '';
	my $EXTD = '';
	my @EXTTN = '';
	while ($line = shift (@{$array_ref})) {
		$lineNr++;
		my $str;
		($str) = $line =~ /$DTITLE_RX/;
		if (defined ($str)) {
			$DTITLE .= $str;
			next;
		}
		($str) = $line =~ /$DYEAR_RX/;
		if (defined ($str)) {
			$DYEAR .= $str;
			next;
		}
		($str) = $line =~ /$DGENRE_RX/;
		if (defined ($str)) {
			$DGENRE .= $str;
			next;
		}
		my $nr;
		($nr, $str) = $line =~ /$TTITLEN_RX/;
		if (defined ($nr)) {
			$TTITLEN[$nr] .= $str;
			next;
		}
		($str) = $line =~ /$EXTD_RX/;
		if (defined ($str)) {
			$EXTD .= $str;
			next;
		}
		($nr, $str) = $line =~ /$EXTTN_RX/;
		if (defined ($nr)) {
			$EXTTN[$nr] .= $str;
			next;
		}
	}
	# Set artist and title
	my ($artist, $title) = split (/\s*\/\s*/, $DTITLE, 2);
	$title = '' if (!$title);
	$artist =~ s/\\n/\n/gm;
	$title =~ s/\\n/\n/gm;
	$self->setArtist ($artist);
	$self->setTitle ($title);

	# DYEAR
	$DYEAR =~ s/\\n/\n/gm;
	$self->setDyear ($DYEAR);

	# DGENRE
	$DGENRE =~ s/\\n/\n/gm;
	$self->setDgenre ($DGENRE);

	# TTITLEN
	for (my $i = 0; $i < scalar (@TTITLEN); $i++) {
		$TTITLEN[$i] =~ s/\\n/\n/gm;
		$self->setTtitlen ($i+1, $TTITLEN[$i]);
	}

	# EXTD
	$EXTD =~ s/\\n/\n/gm;
	$self->setExtd ($EXTD);

	# EXTTN
	for (my $i = 0; $i < scalar (@EXTTN); $i++) {
		$EXTTN[$i] =~ s/\\n/\n/gm;
		$self->setExttn ($i+1, $EXTTN[$i]);
	}
}

sub readDev {
	my $self = shift;
	my $opt = shift || {};

	# Setup the cdparanoia command
	my $cmd = 'cdparanoia -Q';
	$cmd .= " -d '$opt->{dev}'" if (exists $opt->{dev});

	# Run the cdparanoia command
	use IO::File;
	my $fh = IO::File->new ("$cmd 2>&1 |");
	defined ($fh) || throw Error::Simple ("ERROR: Net::FreeDB2::Entry::readDev, Failed to open pipe from command '$cmd'.");

	# Parse cdparanoia's output
	my $frameOffset = 150;
	while (my $line = $fh->getline ()) {
		my ($track, $framelength, $frameBegin) = $line =~ /$CDPARA_TRACK_RX/;
		if (defined ($track)) {
			$self->setFrameOffset ($track, $frameOffset);
			$frameOffset += $framelength;
			next;
		}

		my ($frameTotal) = $line =~ /$CDPARA_TOTAL_RX/;
		if (defined ($frameTotal)) {
			$self->setDiscLength (int ($frameTotal / 75) + 2);
			last;
		}
	}

	# Check if anything is read
	($frameOffset == 150) && throw Error::Simple ("ERROR: Net::FreeDB2::Entry::readDev, Command '$cmd' did not produce any usable output.");

	# Make discid
	$self->mkDiscID ();
}

sub write {
	my $self = shift;
	my $opt = shift || {};

	# Make an empty array
	my @array = ();

	# xmcd
	push (@array, "# xmcd");
	push (@array, "#");

	# Make maximum tracks
	my $max = scalar ($self->getFrameOffset ());

	# Track frame offsets:
	push (@array, "# Track frame offsets:");
	for (my $i = 1; $i <= $max; $i++) {
		push (@array, "#\t" . $self->getFrameOffset ($i));
	}
	push (@array, "#");

	# Disc length: N seconds
	push (@array, "# Disc length: " . $self->getDiscLength () . " seconds");
	push (@array, "#");

	# Revision: N
	push (@array, "# Revision: " . ($self->getRevision () || '0'));
	push (@array, "#");

	# Submitted via: client_name client_version optional_comments
	my $str = ($self->getClientName () || 'none') . ' ';
	$str .= ($self->getClientVersion () || '0');
	$str .= ' ' . $self->getClientComment () if ($self->getClientComment ());
	push (@array, sprintf ("%.79s", "# Submitted via: " . $str));
	push (@array, "#");

	# DISCID
	push (@array, "DISCID=" . ($self->getDiscID () || ''));

	# DTITLE (Artist / Title)
	$self->print_db_length (\@array, 'DTITLE=',
		($self->getArtist () || '') . ' / ' . ($self->getTitle () || ''));

	# DYEAR
	$self->print_db_length (\@array, 'DYEAR=', $self->getDyear ());

	# DGENRE
	$self->print_db_length (\@array, 'DGENRE=', $self->getDgenre ());

	# TTITLEN
	for (my $i = 1; $i <= $max; $i++) {
		my $str;
		try {
			$str = $self->getTtitlen ($i);
		} catch Error::Simple with {
		};
		$self->print_db_length (\@array, "TTITLE" . int ($i-1) . "=", $str);
	}

	# EXTD
	$self->print_db_length (\@array, 'EXTD=', $self->getExtd ());

	# EXTTN
	for (my $i = 1; $i <= $max; $i++) {
		my $str;
		try {
			$str = $self->getExttn ($i);
		} catch Error::Simple with {
		};
		$self->print_db_length (\@array, "EXTT" . int ($i-1) . "=", $str);
	}

	# PLAYORDER
	push (@array, "PLAYORDER=");

	if (exists ($opt->{fh})|| exists ($opt->{fn})) {
		# Make a file handle out of $opt->{fh} or $opt->{fn}
		my $fh;
		if (exists ($opt->{fh})) {
			$fh = $opt->{fh};
		} elsif (exists ($opt->{fn})) {
			use IO::File;
			$fh = IO::File->new ("> $opt->{fn}");
		}
		defined ($fh) || throw Error::Simple ('ERROR: Net::FreeDB2::Entry::write, Failed to make file handle out of provided options.');
		foreach my $line (@array) {
			$fh->print ($line, "\n");
		}
	} elsif (exists ($opt->{array_ref})) {
		@{$opt->{array_ref}} = @array;
	} else {
		throw Error::Simple ("ERROR: Net::FreeDB2::Entry::write, missing option 'fh', 'fn' or 'array_ref'");
	}
}

sub setFrameOffset {
	my $self = shift;
	my $track = int (shift);
	my $off = int (shift);

	# Check for a positive track number
	$track > 0 || throw Error::Simple ("ERROR: setFrameOffset, track must be a positive integer.");

	# Check for a positive offset
	$off > 0 || throw Error::Simple ("ERROR: setFrameOffset, offset must be a positive integer.");

	# Set the offset
	$self->{Net_FreeDB2_Entry}{track}{$track}{off} = $off;
}

sub getFrameOffset {
	my $self = shift;
	my $track = int (shift || 0);

	# Check for a positive or 0 track number
	$track > -1 || throw Error::Simple ("ERROR: getFrameOffset, track must be a positive or 0 integer.");

	# Handle a specified track number
	if ($track) {
		# Check for an existing track number
		(exists ($self->{Net_FreeDB2_Entry}{track}{$track}) && exists ($self->{Net_FreeDB2_Entry}{track}{$track}{off})) || throw Error::Simple ("ERROR: getFrameOffset, no track with number '$track'.");

		# Return the offset
		return ($self->{Net_FreeDB2_Entry}{track}{$track}{off});
	}

	# Return all offsets if track == 0;
	my @ret = ();
	foreach my $track (sort {$a <=> $b} (keys (%{$self->{Net_FreeDB2_Entry}{track}}))) {
		exists ($self->{Net_FreeDB2_Entry}{track}{$track}{off}) || next;
		push (@ret, $self->{Net_FreeDB2_Entry}{track}{$track}{off});
	}
	return (@ret);
}

sub setDiscLength {
	my $self = shift;
	my $length = int (shift);

	$length || throw Error::Simple ("ERROR: setDiscLength, length must be a positive integer.");
	$self->{Net_FreeDB2_Entry}{length} = $length;
}

sub getDiscLength {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{length});
}

sub setRevision {
	my $self = shift;
	my $revision = shift;

	$self->{Net_FreeDB2_Entry}{revision} = $revision;
}

sub getRevision {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{revision});
}

sub setClientName {
	my $self = shift;
	my $client_name = shift;

	$self->{Net_FreeDB2_Entry}{client_name} = $client_name;
}

sub getClientName {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{client_name});
}

sub setClientVersion {
	my $self = shift;
	my $client_version = shift;

	$self->{Net_FreeDB2_Entry}{client_version} = $client_version;
}

sub getClientVersion {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{client_version});
}

sub setClientComment {
	my $self = shift;
	my $client_comment = shift;

	$self->{Net_FreeDB2_Entry}{client_comment} = $client_comment;
}

sub getClientComment {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{client_comment});
}

sub setDiscID {
	my $self = shift;
	my $disc_id = shift;

	$self->{Net_FreeDB2_Entry}{disc_id} = $disc_id;
}

sub getDiscID {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{disc_id});
}

sub mkDiscID {
	my $self = shift;

	# Make sum
	my $sum = 0;
	for (my $i = 1; $i <= scalar ($self->getFrameOffset ()); $i++) {
		$sum += &digitSum ($self->getFrameOffset ($i)/75);
	}

	# Make ID out of sum, getDiscLength () -2 and the number of tracks.
	# And call setDiscID.
	$self->setDiscID (sprintf ("%8x", ($sum % 0xff) << 24 |
		int( $self->getDiscLength () - 2) << 8 |
		scalar ($self->getFrameOffset ())));
}

sub mkQuery {
	my $self = shift;

	# Make a 'fresh' disc ID
	$self->mkDiscID ();

	# Return query: disc ID, number of tracks, frame offsets and disc lenght
	return (sprintf ("%s %d %s %d",
		$self->getDiscID (), 
		scalar ($self->getFrameOffset ()),
		join (' ', $self->getFrameOffset ()),
		$self->getDiscLength ()
	));
}

sub setArtist {
	my $self = shift;
	my $artist = shift;

	$self->{Net_FreeDB2_Entry}{artist} = $artist;
}

sub getArtist {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{artist});
}

sub setTitle {
	my $self = shift;
	my $title = shift;

	$self->{Net_FreeDB2_Entry}{title} = $title;
}

sub getTitle {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{title});
}

sub setDyear {
	my $self = shift;
	my $year = shift;

	$self->{Net_FreeDB2_Entry}{year} = $year;
}

sub getDyear {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{year});
}

sub setDgenre {
	my $self = shift;
	my $genre = shift;

	$self->{Net_FreeDB2_Entry}{genre} = $genre;
}

sub getDgenre {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{genre});
}

sub setTtitlen {
	my $self = shift;
	my $track = int (shift);
	my $title = shift;

	# Check for a positive track number
	$track > 0 || throw Error::Simple ("ERROR: setTtitlen, track must be a positive integer.");

	# Set the title
	$self->{Net_FreeDB2_Entry}{track}{$track}{title} = $title;
}

sub getTtitlen {
	my $self = shift;
	my $track = int (shift);

	# Check for a positive or 0 track number
	$track > -1 || throw Error::Simple ("ERROR: getTtitlen, track must be a positive or 0 integer.");

	# Handle a specified track number
	if ($track) {
		# Check for an existing track number
		(exists ($self->{Net_FreeDB2_Entry}{track}{$track}) && exists ($self->{Net_FreeDB2_Entry}{track}{$track}{title})) || throw Error::Simple ("ERROR: getFrameOffset, no track with number '$track'.");

		# Return the title
		return ($self->{Net_FreeDB2_Entry}{track}{$track}{title});
	}

	# Return all title if track == 0;
	my @ret = ();
	foreach my $track (sort {$a <=> $b} (keys (%{$self->{Net_FreeDB2_Entry}{track}}))) {
		exists ($self->{Net_FreeDB2_Entry}{track}{$track}{title}) || next;
		push (@ret, $self->{Net_FreeDB2_Entry}{track}{$track}{title});
	}
	return (@ret);
}

sub setExtd {
	my $self = shift;
	my $ext = shift;

	$self->{Net_FreeDB2_Entry}{ext} = $ext;
}

sub getExtd {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{ext});
}

sub setExttn {
	my $self = shift;
	my $track = int (shift);
	my $ext = shift;

	# Check for a positive track number
	$track > 0 || throw Error::Simple ("ERROR: setExttn, track must be a positive integer.");

	# Set the ext
	$self->{Net_FreeDB2_Entry}{track}{$track}{ext} = $ext;
}

sub getExttn {
	my $self = shift;
	my $track = int (shift);

	# Check for a positive or 0 track number
	$track > -1 || throw Error::Simple ("ERROR: setExttn, track must be a positive or 0 integer.");

	# Handle a specified track number
	if ($track) {
		# Check for an existing track number
		(exists ($self->{Net_FreeDB2_Entry}{track}{$track}) && exists ($self->{Net_FreeDB2_Entry}{track}{$track}{ext})) || throw Error::Simple ("ERROR: getFrameOffset, no track with number '$track'.");

		# Return the ext
		return ($self->{Net_FreeDB2_Entry}{track}{$track}{ext});
	}

	# Return all ext if track == 0;
	my @ret = ();
	foreach my $track (sort {$a <=> $b} (keys (%{$self->{Net_FreeDB2_Entry}{track}}))) {
		exists ($self->{Net_FreeDB2_Entry}{track}{$track}{ext}) || next;
		push (@ret, $self->{Net_FreeDB2_Entry}{track}{$track}{ext});
	}
	return (@ret);
}

sub setDbLineLen {
	my $self = shift;
	my $length = int (shift);

	$length > 10 || throw Error::Simple ('ERROR: Net::FreeDB2::Entry::setDbLineLen, length must be greater than 10.');
	$self->{Net_FreeDB2_Entry}{db_line_len} = $length;
}

sub getDbLineLen {
	my $self = shift;

	return ($self->{Net_FreeDB2_Entry}{db_line_len} || $DB_LINE_LEN_DEF);
}

sub print_db_length {
	my $self = shift;
	my $array_ref = shift;
	my $pre = shift;
	my $str = shift || '';

	$str =~ s/\n/\\n/gm;

	my $first = 1;
	while ($first || $str) {
		push (@{$array_ref}, $pre . substr ($str, 0, $self->getDbLineLen () - 1 - length ($pre), ''));
		$first = 0;
	}
}

sub digitSum {
	my $int = int (shift);


	my $sum = 0;
	while ($int) {
		$sum += $int % 10;
		$int = int ($int / 10);
	}
	return ($sum);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::FreeDB2::Entry - FreeDB/CDDB entry class

=head1 SYNOPSIS

See L<Net::FreeDB2>.

=head1 DESCRIPTION

The C<Net::FreeDB2::Entry> class contains information on FreeDB/CDDB entries (CDs).

=head1 CONSTRUCTOR

=over

=item new ([OPT_HASH_REF])

Creates a new C<Net::FreeDB2::Entry> object. Calls C<read ()> if option C<fh>, C<fn> or C<array_ref> is passed through C<OPT_HASH_REF>. Calls C<readDev ()> if option C<dev> is passed.

Options for C<OPT_HASH_REF> may include:

=over

=item fh

C<IO::Handle> to read from.

=item fn

File name to read from.

=item array_ref

C<ARRAY> reference to read from.

=item dev

Device to C<readDev ()> from.

=back

=back

=head1 METHODS

=over 

=item read (OPT_HASH_REF)

Reads a FreeDB/CDDB database entry according to the option passed through C<HASH> reference C<OPT_HASH_REF>.

Throws an C<Error::Simple> exception if the named file connot be opened, on syntax errors or if no read option are specified.

Options for C<OPT_HASH_REF> may include:

=over

=item fh

C<IO::Handle> to read from.

=item fn

File name to read from.

=item array_ref

C<ARRAY> reference to read from.

=back

=item readDev (OPT_HASH_REF)

Reads frame offsets and the disc length using C<cdparanoia>. Throws an C<Error::Simple> exception if the C<cdparanoia> command fails or did not produce any usable output.

Options for C<OPT_HASH_REF> may include:

=over

=item dev

Device for C<cdparanoia>. If not specified, the C<cdparanoia> default device is tried.

=back


=item write (OPT_HASH_REF)

Writes a FreeDB/CDDB database entry according to the option passed. Throws an C<Error::Simple> exception if the named file connot be opened or if no write option are specified.

Options for C<OPT_HASH_REF> may include:

=over

=item fh

C<IO::Handle> to write to.

=item fn

File name to write to.

=item array_ref

C<ARRAY> reference to write to.

=back

=item setFrameOffset (TRACK, VALUE)

Set the frame offset track attribute. C<TRACK> is the track number and C<VALUE> is the value. Both C<TRACK> and C<VALUE> must be B<positive> integers.

=item getFrameOffset ([TRACK])

Returns the frame offset track attribute(s). C<TRACK> is the track number. If not specified, a list of all frame offsets is returned.

=item setDiscLength (VALUE)

Set the disc length attribute. C<VALUE> is the value. Must be a C<positive> integer.

=item getDiscLength ()

Returns the disc length attribute.

=item setRevision (VALUE)

Set the revision attribute. C<VALUE> is the value.

=item getRevision ()

Returns the revision attribute.

=item setClientName (VALUE)

Set the client name. C<VALUE> is the value.

=item getClientName ()

Returns the client name attribute.

=item setClientVersion (VALUE)

Set the client version. C<VALUE> is the value.

=item getClientVersion ()

Returns the client version attribute.

=item setClientComment (VALUE)

Set the client comment. C<VALUE> is the value.

=item getClientComment ()

Returns the client comment attribute.

=item setDiscID (VALUE)

Set the DISCID attribute. C<VALUE> is the value.

=item getDiscID ()

Returns the DISCID attribute.

=item mkDiscID ()

Makes the DISCID out of the disc's frame offsets and disc length. Stores it through the C<setDiscID ()> method.

=item mkQuery ()

Makes the FreeDB/CDDB qurey for this disc and returns it. Calls C<mkDiscID ()> in the process.

=item setArtist (VALUE)

Set the artist attribute. C<VALUE> is the value.

=item getDiscID ()

Returns the artist attribute.

=item setTitle (VALUE)

Set the title attribute. C<VALUE> is the value.

=item getTitle ()

Returns the title attribute.

=item setDyear (VALUE)

Set the DYEAR attribute. C<VALUE> is the value.

=item getDyear ()

Returns the DYEAR attribute.

=item setDgenre (VALUE)

Set the DGENRE attribute. C<VALUE> is the value.

=item getDgenre ()

Returns the DGENRE attribute.

=item setTtitlen (TRACK, VALUE)

Set the TTITLEN track attribute. C<TRACK> is the track number and C<VALUE> is the value. C<TRACK> must be a B<positive> integer.

=item getTtitlen ([TRACK])

Returns the TTITLEN track attribute(s). C<TRACK> is the track number. If not specified, a list of all TTITLEN is returned.

=item setExtd (VALUE)

Set the EXTD attribute. C<VALUE> is the value.

=item setExtd ()

Returns the EXTD attribute.

=item setExttn (TRACK, VALUE)

Set the EXTTN track attribute. C<TRACK> is the track number and C<VALUE> is the value. C<TRACK> must be a B<positive> integer.

=item getExttn ([TRACK])

Returns the EXTTN track attribute(s). C<TRACK> is the track number. If not specified, a list of all EXTTN is returned.

=item setDbLineLen (VALUE)

Set the database line length attribute. C<VALUE> is the value. Throws an C<Error::Simple> exception if C<VALUE> isn't larger than 10.

=item getDbLineLen ()

Returns the database line length attribute. If empty, returns I<my> variable C<$DB_LINE_LEN_DEF>.

=item print_db_length (ARRAY_REF, PRE, STRING)

B<PRIVATE METHOD>. Helper method for C<write ()>. Push the specified C<STRING> string, precurred by the C<PRE> string on the C<ARRAY> referenced by C<ARRAY_REF>. A too long a string (longer than C<getDbLineLen ()> characters) is chopped up like FreeDB/CDDB requires.

=item digitSum (NUMBER)

Helper method for C<mkDiscID ()>. Calculate the digit sum.

=back

=head1 SEE ALSO

L<Net::FreeDB2::Connection::HTTP>, L<Net::FreeDB2::Match> and L<Net::FreeDB2::Response::Read>

=head1 BUGS

None known.

=head1 HISTORY

First development: September 2002

=head1 AUTHOR

Vincenzo Zocca E<lt>Vincenzo@Zocca.comE<gt>

=head1 COPYRIGHT

Copyright 2002, Vincenzo Zocca.

=head1 LICENSE

This file is part of the C<Net::FreeDB2> module hierarchy for Perl by
Vincenzo Zocca.

The Net::FreeDB2 module hierarchy is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

The Net::FreeDB2 module hierarchy is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Net::FreeDB2 module hierarchy; if not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut

