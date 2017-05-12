package SimpleCDB;
#
########################################################################
#
# Perl-only Constant Database
#  (c) Benjamin D. Low <b.d.low@ieee.org>
#
#  See end of file for pod documentation.
#  See HISTORY file for commentary on major developments.
#
########################################################################
#

use strict;

# prefer 5.004, but can do with 5.003
# - all the comments in this file re. 5.003 are with respect to a 
#   Solaris 2.5.1 machine. It may well be the issues are the fault
#   of the o/s, not perl - YMMV.
use 5.003;

use Carp;

use Tie::Hash;

use vars qw/@ISA @EXPORT $VERSION $DEBUG/;

use Exporter ();
@ISA    = qw/Exporter Tie::Hash/;
@EXPORT = @Fcntl::EXPORT;

$VERSION = '1.0';

use vars qw/$NFILES $SEP $METAFILE $LOCKRDTIMEOUT $LOCKWRTIMEOUT $ERROR/;
$NFILES = 16;
$SEP = "\x00";		# default separator
$METAFILE = '_info';	# info about the DB, reqd for reading

$LOCKRDTIMEOUT = 5;		# how long to block for read access
$LOCKWRTIMEOUT = 900;	#           "           write   "

$ERROR = undef;	# error message

BEGIN
{
	my @flock = qw/:DEFAULT/;
	if ($] >= 5.004)	# should have a complete Fcntl
	{
		push @flock, ':flock';
	}
	else				# hope for the best...
	{
		sub LOCK_SH () { 1 };
		sub LOCK_EX () { 2 };
		sub LOCK_NB () { 4 };
		sub LOCK_UN () { 8 };
	}

	use Fcntl @flock;
}

# don't let POSIX's EXPORT list (:flock) clash w/ Fcntl
{ package SimpleDB::POSIX; use POSIX; }

BEGIN
# what to do if EWOULDBLOCK isn't defined...
# - unfortunately different systems have different values for
#   EWOULDBLOCK (11 on Solaris/Linux, 246 on HP/UX). Oh well.
{
	no strict 'subs';

	#print "POSIX::EWOULDBLOCK is " . (eval 'POSIX::EWOULDBLOCK' 
	#	eq 'POSIX::EWOULDBLOCK' ? 'not ' : '') . "defined\n";

	# if EWOULDBLOCK is defined (as a sub, string, or whatever),
	# the test eval will pick it up, otherwise it'll just return 
	# the string
	eval 'package POSIX; sub EWOULDBLOCK() { 11 } ' 
		if (eval 'POSIX::EWOULDBLOCK' eq 'POSIX::EWOULDBLOCK');
}

use FileHandle;	# IO::File wasn't around for < 5.004

sub debug ($@) { $^W=0; if ($DEBUG and $_[0]<=$DEBUG) { shift; warn @_,"\n" } }

my $digest;		# sub ref to routine to create a hash of a string
my %_digest = 	# randomly sorted mapping of decimal -> hex numbers
qw/
	  0 fc   1 81   2 ab   3 c8   4 82   5 ad   6 f2   7 ff   8 c2   9 bd 
	 10 dd  11 84  12 dc  13 a2  14 db  15 c9  16 a1  17 b5  18 d9  19 b4 
	 20 d7  21 ae  22 ce  23 92  24 cd  25 99  26 87  27 c1  28 a7  29 a5 
	 30 bf  31 8e  32 e6  33 e7  34 ea  35 98  36 f5  37 f9  38 fb  39 df 
	 40 cb  41 d2  42 8f  43 d5  44 b2  45 da  46 b9  47 0d  48 0e  49 11 
	 50 12  51 14  52 17  53 19  54 1a  55 1b  56 1c  57 1e  58 1f  59 20 
	 60 21  61 22  62 23  63 24  64 25  65 26  66 27  67 28  68 2a  69 2b 
	 70 2c  71 2d  72 2f  73 30  74 31  75 32  76 33  77 34  78 35  79 37 
	 80 39  81 3a  82 3b  83 3d  84 3e  85 40  86 41  87 42  88 43  89 45 
	 90 46  91 48  92 4d  93 4f  94 51  95 52  96 55  97 56  98 57  99 58 
	100 59 101 5c 102 5d 103 5f 104 60 105 61 106 62 107 64 108 66 109 67 
	110 68 111 6b 112 6c 113 6d 114 6e 115 6f 116 70 117 71 118 72 119 73 
	120 74 121 76 122 79 123 7b 124 7c 125 7d 126 7e 127 7f 128 80 129 83 
	130 85 131 86 132 88 133 89 134 8a 135 8b 136 8c 137 8d 138 90 139 91 
	140 93 141 94 142 95 143 96 144 97 145 9a 146 9b 147 9c 148 9d 149 9e 
	150 9f 151 a0 152 a3 153 a4 154 a6 155 a8 156 a9 157 aa 158 ac 159 af 
	160 b0 161 b1 162 b3 163 b6 164 b7 165 b8 166 ba 167 bb 168 bc 169 be 
	170 c0 171 c3 172 c4 173 c5 174 c6 175 c7 176 ca 177 cc 178 cf 179 d0 
	180 d1 181 d3 182 d4 183 d6 184 d8 185 de 186 e0 187 e1 188 e2 189 e3 
	190 e4 191 e5 192 00 193 01 194 e8 195 e9 196 02 197 eb 198 ec 199 ed 
	200 ee 201 ef 202 f0 203 f1 204 04 205 f3 206 f4 207 05 208 f6 209 f7 
	210 f8 211 07 212 fa 213 09 214 0a 215 fd 216 fe 217 0c 218 16 219 1d 
	220 5e 221 13 222 2e 223 69 224 15 225 0f 226 10 227 08 228 47 229 03 
	230 75 231 44 232 78 233 38 234 50 235 6a 236 4c 237 36 238 7a 239 29 
	240 5b 241 18 242 4b 243 5a 244 4a 245 49 246 63 247 54 248 0b 249 77 
	250 3f 251 65 252 53 253 06 254 3c 255 4e
/;

BEGIN
{
	if (eval 'use Digest::MD5 (); 1')
	{
		#debug 1, "using Digest::MD5";
		$digest = \&Digest::MD5::md5_hex;
	}
	else

# crypt is waaaayyyyy too slow (which is to be expected I suppose, presumably
# it's purposely designed to be an expensive operation :-)
# 	else
# 	{
# 		# resort to crypt - both much slower and less rigorous than Digest::MD5
# 		# - fudge crypt's output to be a hex string, skipping the salt and
# 		#   omitting the tail fractional-byte
# 		#debug 1, "using crypt";
# 		$digest = sub { unpack('@1H10', pack('H*', crypt ($_[0], 'kylan'))) };
# 	}
	{
		$digest = sub
		{
			# yeah, well, this works but no guarantees
			my $d = $_[0] || 'bcc3b7b7b80';
			my $cs = unpack('%16C*', $d) . length($d);
			join '', map {$_digest{(($_ ^ $cs) + 3) % 256}} unpack('C*', $d);
		};
	}
}

sub digest
# returns a hex-encoded digest of a string, of a given length
{
	local $^W = 0;
	# 5.003 doesn't support the $c->() syntax
	substr (&{$digest}($_[0]), 0, $_[1]) || '0';
}

sub newFileHandle ($;$$)
{
	# 5.003's FileHandle doesn't support 'perm' field
	return ($] >= 5.004) ? new FileHandle (@_) : new FileHandle ($_[0], $_[1]);
}

sub _lock
{
	my ($s, $op) = @_;
	my $l;
	eval
	{
		local $SIG{ALRM} = sub { $! = POSIX::EWOULDBLOCK; die "$!\n" };
		alarm(($op & LOCK_EX) ? $s->{wrt} : $s->{rdt});
		$l = flock($s->{lockfh}, $op);
		alarm(0);
	};
	if ($@) { chomp $@; } elsif (!$l) { $@ = "$!" }
	return $l;
}

sub TIEHASH
# args compatible w/ DB_File:
# dir - where to put files
# flags - file open (DB) flags
# perms - file creation permissions
# plus:
# nfiles - number of files to use when creating the DB (rounded to power of 16)
# sep - character to use as the internal field separator
#
# - to avoid problems with system file decriptor limits, files are opened 
#   and closed as-needed in the access routines.
{
	$ERROR = undef;

    my ($class, $dir, $flags, $perms, $nfiles, $sep, $rdt, $wrt) = @_;
	$dir    ||= '.';
	$flags  |= O_CREAT if ($flags & O_WRONLY);
	$perms  ||= 0666;	# don't restrict the user's umask
	$nfiles ||= $NFILES;
	$sep    ||= $SEP;

	$rdt    ||= $LOCKRDTIMEOUT;
	$wrt    ||= $LOCKWRTIMEOUT;

	#debug 2, sprintf 'TIEHASH (%s, %s, 0x%x, %s, %d, \x%x)', 
	#	$class, $dir, $flags, $perms, $nfiles, ord($sep);

	$ERROR = 'must specify flags', return undef unless defined $flags;
	$ERROR = 'invalid flag: O_APPEND', return undef if ($flags & O_APPEND);

	# check base directory exists, create if necessary
	unless (-d $dir)
		{ mkdir($dir, $perms|0700) or $ERROR="mkdir failed: $!", return undef; }

	my $s = {};	# object data

	$s->{rdt} = $rdt;
	$s->{wrt} = $wrt;

	# acquire lock (held till object is destroyed)
	if ($flags & (O_WRONLY|O_RDWR))
	{
		$s->{lockfh} = newFileHandle ("$dir/$METAFILE", 
			O_WRONLY|O_TRUNC|O_CREAT, $perms)
			or $ERROR="could not write [$dir/$METAFILE]: $!", return undef;

		# there may be current readers, wait my turn
		_lock($s, LOCK_EX) or $ERROR = "lock_ex failed: $@", return undef;

		#debug 1, 'LOCK_EX';
		# nfiles, sep written to info file at end of this sub
	}
	else
	{
		# well, how about that - yet another broken part of 5.003
		# - flock won't give you a shared lock (gives errno = "Bad file 
		#   number", as if the file mode was wrong (e.g. EX lock on a 
		#   readonly file)). Anyhow, using a O_RDWR file partially works - 
		#   you get an exclusive lock (even for LOCK_SH).
		# - want to avoid a reader waiting for a database update (which can
		#   take quite a while), so don't block (for long)
		my $m = ($] < 5.004) ? O_RDWR : O_RDONLY;
		$s->{lockfh} = newFileHandle ("$dir/$METAFILE", $m, $perms)
			or $ERROR="could not read [$dir/$METAFILE]: $!", return undef;

		_lock($s, LOCK_SH) or $ERROR = "lock_sh failed: $@", return undef;

		#debug 1, 'LOCK_SH';
		$nfiles = $s->{lockfh}->getline();
		$sep = $s->{lockfh}->getline();
		$ERROR = "invalid info file [$dir/$METAFILE]", return undef
			unless (defined $nfiles and defined $sep);
		chomp $nfiles;
		chomp $sep;
	}

	$s->{perms} = $perms;
	$s->{nfiles} = $nfiles;
	$s->{sep} = $sep;
	$s->{sep_ord} = ord($sep);

	$ERROR = "invalid number of files [$nfiles]", return undef 
		unless $nfiles =~ /^[1-9]\d*$/;

	$s->{dir} = $dir;
	# hang on to open flags, for use in _open
	# - exclude TRUNC and friends (files may be opened multiple times)
	$s->{fflags} = $flags & (O_RDONLY | O_WRONLY | O_RDWR | O_CREAT);

	# create the file/s (round nfiles up to a power of 16)
	# - a digest length of 0 is fine (nfiles == 1)
	$s->{dlen} = POSIX::ceil(log($nfiles)/log(16));	# filename/digest len
	$nfiles =  16 ** $s->{dlen};
	#debug 6, "digest length = [$s->{dlen}], nfiles = [$nfiles]";

	$s->{f} = {};		# digest => filename
	$s->{fh} = {};		# digest => filehandle
	$s->{fpos} = {};	# digest => fileposition
	$s->{dlist} = [];	# list of digest values

	my $i;
	for ($i = 0; $i < $nfiles; $i++)
	{
		# 5.003's printf doesn't support '*'
		#my $d = sprintf ('%0*x', $s->{dlen}, $i);
		my $d = substr(('0' x 16) . sprintf ('%x', $i), -($s->{dlen}||1));
		my $f = "$dir/$d";
		#debug 6, "filename [$f]";

		# hang on to the digest values + filenames for _open
		push (@{$s->{dlist}}, $d);
		$s->{f}{$d} = $f;

		truncate($f, 0) if ($flags & O_TRUNC);	# start afresh if required
	}

	if ($flags & (O_WRONLY|O_RDWR))
	{
		$s->{lockfh}->print($nfiles . "\n");
		$s->{lockfh}->print($sep . "\n");
	}

	bless $s, $class;
}

#my $_opens = 0;

sub _open
# open a DB file, transparently staying within the system file descriptor
# limits
{
	my ($self, $d) = @_;
	my $fh;

	my $n = int rand @{$self->{dlist}};
	my $i = 0;
	while ($i < @{$self->{dlist}})
	{
		$fh = $self->{fh}{$d} = 
			newFileHandle ($self->{f}{$d}, $self->{fflags}, $self->{perms});
		last if defined ($fh);	# good, opened the file

		last unless $! == POSIX::EMFILE;	# abort on any other condition

		# if we're out of descriptors, close a random file to free one up
		# - would like to just grab the next one off the fh hash, but can't 
		#   efficiently use 'each' over the filehandles hash as there's 
		#   no simple way to reset the iterator
		#   - use a separate array containing digest values
		# - remember the file position of closed files, to restore later
		my $t = $self->{dlist}[($n + $i) % @{$self->{dlist}}];	# target
		if (defined $self->{fh}{$t})
		{
			#debug 5, "\$! = EMFILE -> closing [$t] (" . 
			#	fileno($self->{fh}{$t}) . ")";
			$self->{fpos}{$t} = $self->{fh}{$t}->tell();
			close($self->{fh}{$t});
			$self->{fh}{$t} = undef;
		}
		$i++;
	}

	$ERROR = "could not open [$self->{f}{$d}]: $!", return undef 
		unless defined $fh;

	# reposition the file pointer
	$fh->seek(0, ${$self->{fpos}}{$d}) if defined ${$self->{fpos}}{$d};

	#$_opens++;

	#debug 4, "opened [$d] (" . fileno($fh) . ")";

	return $fh;
}

sub _escape ($;$$)
# 'special' characters (newlines and the field separator) need to be escaped 
# when they appear within a hash key or value
# - these special values are replaced with their 'base64' encoding
# - further, special note must be made for undef and empty strings, I use the
#   _ and - characters to do this, and escape them if present in the 'user'
#   string
{
	if    (not defined $_[0]) { $_[0] = '-'   }	# undef
	elsif ($_[0] eq '' ) { $_[0] = '_'   }	# empty string
	elsif ($_[0] eq '_') { $_[0] = '%5F' }
	elsif ($_[0] eq '-') { $_[0] = '%2D' }
	else	# non-empty, incl "false" (e.g. '0')
	{
		$_[0] =~ s/%/%25/sg;				# percents
		$_[0] =~ s/\n/%0a/sg;				# newlines
		$_[0] =~ s/\Q$_[1]\E/\%{$_[2]}/sge if $_[1];	# separator
	}
}

sub _unescape ($)
{
	if    ($_[0] eq '_') { $_[0] = ''    }
	elsif ($_[0] eq '-') { $_[0] = undef }
	else  {$_[0] =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg }
}

sub FETCH 
{
	$ERROR = undef;

    my ($self, $key) = @_;

	# is this a call via NEXTKEY?
	if (exists $self->{nextval})
	{
		#debug 6, " record cached via NEXTKEY";
		my $v = $self->{nextval};
		delete $self->{nextval};	# make sure stale results don't arise
		return $v;
	}

	croak("FETCH: DB is WRONLY") if ($self->{fflags} & O_WRONLY);

	my $d = digest($key, $self->{dlen});

	# escape newlines and separators
	# - as per STORE - compare apples with apples
	_escape($key, $self->{sep}, $self->{sep_ord});

	#debug 2, "FETCH ($self, $key [$d])";

	my $fh = defined $self->{fh}{$d} ? $self->{fh}{$d} : _open($self, $d);
	return undef unless defined $fh;
	#debug 4, " fileno: " . fileno($fh);

	$fh->seek(0, 0);	# rewind
	my $l = $self->{cache};	# last line read is cached, presuming multiple reads
	#debug 6, " line cached" if defined $l;
	$l = $fh->getline() unless defined $l;
	while (defined $l)
	{
		#debug 9, " at " . $fh->tell();
		last if $l =~ /^\Q$key$self->{sep}\E/;
		$l = $fh->getline();
	}

	if ($l)
	{
		$self->{cache} = $l;

		#debug 3, " found at " . $fh->tell();
		chomp $l;
		my ($k, $v) = split($self->{sep}, $l, 2);
		_unescape($v);
		return $v;
	}
	else
	{
		#debug 3, "\tkey not found";
		return undef;
	}
}

sub EXISTS
{
	$ERROR = undef;

    my ($self, $key) = @_;

	croak("EXISTS: DB is WRONLY") if ($self->{fflags} & O_WRONLY);

	my $d = digest($key, $self->{dlen});

	# escape newlines and separators
	# - as per STORE - compare apples with apples
	_escape($key, $self->{sep}, $self->{sep_ord});

	#debug 2, "EXISTS ($self, $key [$d])";

	my $fh = defined $self->{fh}{$d} ? $self->{fh}{$d} : _open($self, $d);
	return undef unless defined $fh;
	#debug 4, " fileno: " . fileno($fh);

	$fh->seek(0, 0);	# rewind
	my $l;
	while (defined ($l = $fh->getline()))
	{
		last if $l =~ /^\Q$key$self->{sep}\E/;
	}
	$self->{cache} = $l if defined $l;	# cache for FETCH, if found

	#debug 3, $_ ? " found at " . $fh->tell() : " not found";

	# returning undef seems to cause perl to try to FETCH the key
	# - presumably this is some kind of fall-back if the exists operator
	#  "fails"
	return $l ? 1 : 0;
}

sub _nextfile
# find and open the next non-null file
# - i.e. skip files which don't exist (recall that files are opened (created)
#   on-demand)
# - note that a file may be used (contain data), but not open
{
	my ($self) = @_;
	my $fh;

	$self->{'next'} = 0 unless defined $self->{'next'};

	while (not defined $fh and $self->{'next'} < @{$self->{dlist}})
	{
		# lookup next fh hash key
		my $d = $self->{dlist}->[$self->{'next'}];

		# if fh=defined, file is already open (which also implies it exists :-)
		# - otherwise, open the filename, if it exists
		unless (defined ($fh = $self->{fh}{$d}))
		{
			$fh = _open($self, $d) if -e $self->{f}{$d};
		}
		$self->{'next'}++;	# get ready for next time round
	}
	#warn "_next = " . ($self->{'next'} - 1) . "\n" if $fh;
	return $fh;
}

sub FIRSTKEY
{
	my $self = shift;

	croak("FIRSTKEY: DB is WRONLY") if ($self->{fflags} & O_WRONLY);

	#debug 2, "FIRSTKEY ($self)";

	# find the first file
	$self->{'next'} = undef;	# index into $self->{dlist}
	$self->{NEXTKEYfh} = _nextfile($self);

	NEXTKEY($self);
}

sub NEXTKEY
# return the 'next' key in an iteration sequence started via FIRSTKEY
# - perl will call FETCH on this key to extract the value
#   - kind of wasteful, would end up doing multiple reads for the same 
#     piece of data, so cache the result (carefully - the value may well 
#     be undef)
{
	$ERROR = undef;

	my $self = shift;	# 'lastkey' is unused

	#debug 2, "NEXTKEY ($self) [$self->{'next'}]";

	# read next record, over all files
	my $l;
	my $fh = $self->{NEXTKEYfh};	# initialised by FIRSTKEY

	while (defined $fh and not defined ($l = $fh->getline()))
	{
		$fh = $self->{NEXTKEYfh} = _nextfile($self);
	}
	return undef unless defined $l;

	chomp $l;
	my ($k, $v) = split($self->{sep}, $l, 2);

	# unescape key and value
	# - value is 'cached' to be returned by the next FETCH
	_unescape($k);
	_unescape($v);

	$self->{nextval} = $v;
	# undef keys will cause perl to stop iterating, thinking NEXTKEY 
	# has finished... (need an "undef but true" value :-)
	# - this creates a small discrepancy in that you can directly STORE
	#   and FETCH undef and empty keys, but both return empty strings
	return defined $k ? $k : '';
}

sub STORE 
{
	$ERROR = undef;

    my ($self, $key, $value) = @_;

	croak("STORE: DB is RDONLY") unless ($self->{fflags} & (O_WRONLY|O_RDWR));

	my $d = digest($key, $self->{dlen});

	# escape newlines and separators
	_escape($key, $self->{sep}, $self->{sep_ord});

	#debug 2, "STORE ($self, $key [$d])";

	my $fh = defined $self->{fh}{$d} ? $self->{fh}{$d} : _open($self, $d);
	return undef unless defined $fh;
	#debug 4, " fileno: " . fileno($fh);

	# only do newlines for value
	_escape($value);

	my $s = join($self->{sep}, $key, $value);

	$fh->seek(0,2);
	$fh->print($s . "\n");
}


sub DESTROY
{
	$ERROR = undef;

	my ($self) = @_;
	#debug 2, join(', ', 'DESTROY', @_);
	#debug 3, "$_opens opens";
	#debug 4, "currently opened files = " . 
	#	scalar map {defined $self->{fh}{$_}} keys %{$self->{fh}};

	map {close $self->{fh}{$_} if defined $self->{fh}{$_}} keys %{$self->{fh}};

	#debug 1, 'LOCK_UN';

	flock($self->{lockfh}, LOCK_UN);
	close($self->{lockfh});
}

sub nop
{
	$ERROR = undef;

    my ($self, $method) = @_;

    croak ref($self) . " does not define the method ${method}";
}

sub CLEAR    { my $self = shift; $self->nop("CLEAR") }
sub DELETE   { my $self = shift; $self->nop("DELETE") }

1;	# return true, as require requires

__END__

#
######################################################################
#

=head1 NAME

SimpleCDB - Perl-only Constant Database

=head1 SYNOPSIS

 use SimpleCDB;

 # writer
 # - tie blocks until DB is available (exclusive), or timeout
 tie %h, 'SimpleCDB', 'db', O_WRONLY 
	 or die "tie failed: $SimpleCDB::ERROR\n";
 $h{$k} = $v;
 die "store: $SimpleCDB::ERROR" if $SimpleCDB::ERROR;
 untie %h;	# release DB (exclusive) lock

 # reader
 # - tie blocks until DB is available (shared), or timeout
 tie %h, 'SimpleCDB', 'db', O_RDONLY
	 or die "tie failed: $SimpleCDB::ERROR\n";
 $v = $h{$i};
 die "fetch: $SimpleCDB::ERROR" if $SimpleCDB::ERROR;
 untie %h;	# release DB (shared) lock


=head1 DESCRIPTION

This is a simple perl-only DB intended for constant DB applications. A
constant DB is one which, once created, is only ever read from (though
this implementation allows appending of new data). That is, this is an
"append-only DB" - records may only be added and/or extracted.

Course-grained locking provided to allow multiple users, as per flock
semantics (i.e. write access requires an exclusive lock, read access needs
a shared lock (see notes below re. perl < 5.004)). As (exclusive) updates
may be take some time to complete, shared lock attempts will timeout after
a defined waiting period (returning $! == EWOULDBLOCK).  Concurrent update
attempts will behave similarly, but with a longer timeout.

The DB files are simple flat files, with one record per line. Records
(both keys and values) may be arbitrary (binary) data. Records are
extracted from these files via a plain linear search. Unsurprisingly,
this search is a relatively inefficient operation. To improve extraction
speed, records are randomly distributed across N files, with the average
search space is reduced by 1/N compared to a single file. (See below for
some example performance times.) One advantage of this flat file based
solution is that the DB is human readable (assuming the data is), and
with some care can be edited with a plain ol' text editor.

Finally, note that this DB does not support duplicate entries. In practice,
the first record found matching a given key is returned, any duplicates
will be ignored.

=head2 PURPOSE

I needed to extract single records from a 20k-40k record data set, within
at most 5 seconds on an old Sun 4/40, to feed to an interactive voice 
response system. Fine, I thought, an easy job for any old DBM.

Unfortunately, all of the standard "system" DBMs (NBDM, SDBM, ODBM) are
broken when it comes to "large" data sets (though I don't generally call
20,000 records "large") - at least on Solaris 2.5.1 and Solaris
2.6 machines. I found after inserting some 15k records: NDBM dies; SDBM
and ODBM silently "lose" data (you can't extract records which you know
you inserted). On an HPUX machine, it took nearer to 100,000 records to 
break [NSO]DBM. All worked flawlessly on a Linux 2.2.16 machine. The 
program examples/testdbm.pl can be used to exercise the various DBMs.

BerkeleyDB (DB_File) and GDBM work well, but they don't come standard with 
many boxes. Further, this package was originally written for an old Solaris
2.5 box which lacked development tools (and the space and management will
to install such tools) to build a "real" DB.

And besides, I hadn't played with perl's tie mechanism before...

=head1 EXPORTS / CONSTRUCTOR

This modules uses the tie interface, as for DB_File.

The default Fcntl exports are re-exported by default, primarily for the 
LOCK_ constants.

=head1 CLASS METHODS / CLASS VARIABLES

There are two public class variables:

 $SimpleCDB::DEBUG  turn on some debugging messages
 $SimpleCDB::ERROR  error message for last operation, empty if no error 
                    has ocurred

=head1 METHODS

n/a

=head1 NOTES

It seems not all environments have POSIX::EWOULDBLOCK defined, in which
case this module defines it as a subroutine constant.

This DB may use a significant number of file descriptors, you may want
to increase the user/system resource limits for better performance
(e.g. C<ulimit -S -n 300> on a Solaris box). My test programs on Solaris don't
seem to want to open more than 256 files at a time, that is even with the
ulimit set to 300, I got EMFILE results as soon as I reached 256 open
file descriptors.  This means there is still some file closing/opening
going on... Interestingly, on the non-exhaustive, not-terribly-thorough
testing I did, I noticed that using a smaller number of files gave slightly
better performance wrt. creating the DB. e.g.  with ulimit set as above,
over two runs of each on an old Sparc:
      nfiles = 256 : real,user,sys time = 3:20, 2:43, 0:01
      nfiles =  16 : real,user,sys time = 3:00, 2:40, 0:00
Perhaps this is due to file caching?

Speaking of performance, I used Devel::DProf to find that using crypt to
generate the digest is a real bottleneck (75% CPU time was in generating
the digest :-) Using MD5 reduces this to around 6% (only half of which
is in MD5)! My homebrew digest is not nearly as good as MD5 (both in CPU
and quality), but it more or less does the job when MD5 isn't available.

Here's how it runs:
 Records are between 0 and 100 bytes each. Times are user/sys/real, as
either minutes:seconds or just seconds. wr = create the db with the 
stated number of records. rd = read one record (next to last inserted, i.e.
should be about the worst case).

  Sun 4/40 (sun4c), Solaris 2.5
   40,000 records, nfiles =   1: wr =14:48/29/14:03  rd = 26/2.2/28
   40,000 records, nfiles =  16: wr =14:04/30/15:15  rd =  4/1.0/ 6
   40,000 records, nfiles = 256: wr =14:33/34/15:32  rd =  3/0.8/ 4
    i.e. sloooowwwww to build, good enough on extraction.

  Sun Ultra/1 (sun4u), Solaris 2.6 (SCSI disks)
   40,000 records, nfiles =   1: wr = 53/2.8/57  rd = 3.0/0.1/3.4
   40,000 records, nfiles =  16: wr = 53/2.4/57  rd = 0.5/0.0/0.6
   40,000 records, nfiles = 256: wr =196/19/240  rd = 0.3/0.0/0.4

  x86 C433/64MB, IDE ATA/66 disk, Linux 2.2.16
   40,000 records, nfiles =   1: wr = 18/0.7/19  rd = 1.3/0.0/1.4
   40,000 records, nfiles =  16: wr = 18/0.8/19  rd = 0.3/0.0/0.3
   40,000 records, nfiles = 256: wr = 18/0.8/20  rd = 0.2/0.0/0.2
  100,000 records, nfiles =   1: wr = 47/2.0/49  rd = 3.1/0.1/3.2
  100,000 records, nfiles =  16: wr = 47/2.0/49  rd = 0.4/0.0/0.4
  100,000 records, nfiles = 256: wr = 47/2.2/49  rd = 0.2/0.0/0.2
    i.e. I think the o/s is caching the whole bloody lot :-)

Clearly, other overheads limit the benefit of the distributed file hashing,
however the result is useful for my purposes... 

The important thing is, it works (as opposed to NDBM and friends).
while (each %h) always shows as much data as you put in :-)


=head1 "BUGS"

Possibly, though it works for me :-)

I've noted that on a HP-UX B.10.20 box that ALRMs don't seem to trigger
when I expect they should. For example, in _lock, I set alarm for say
5s and then call flock, which I expect to block until either the lock is
granted *or* the alarm goes off (as happens for Solaris and Linux). However,
it is as if the HP-UX box's ALRM signal is delayed until the flock
returns. HP-UX doesn't have a flock call, but does support lockf (which 
can lock regions of a file), so perhaps this behaviour is an artefact
of perl's flock emulation...

=head1 COPYRIGHT

Copyright (c) 2000 Benjamin Low <b.d.low@ieee.org>.
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Artistic License for more details.

=head1 AUTHORS

Written as a last resort, and as an excuse to write my first tied module, 
by Benjamin Low <b.d.low@ieee.org>, July 2000.

=head1 SEE ALSO

Dan Berstein has a nice constant DB implementation, written in C, at

http://cr.yp.to/cdb.html

If you've a C compiler handy I recommend this library over SimpleCDB.

If you want a read+write DB, go for GDBM - it doesn't support fine-grained 
locking but does actually work.

=cut
