package Noid;

use 5.000000;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION;
$VERSION = sprintf "%d.%02d", q$Name: Release-0-424 $ =~ /Release-(\d+)-(\d+)/;
our @EXPORT_OK = qw(
	addmsg bind checkchar dbopen dbclose dbcreate dbinfo
	errmsg fetch getnoid hold hold_release hold_set
	locktest logmsg mint n2xdig note parse_template queue
	sample scope validate VERSION xdig 
);

# Noid - Nice opaque identifiers (Perl module)
# 
# Author:  John A. Kunze, jak@ucop.edu, California Digital Library
#		Originally created, UCSF/CKM, November 2002
# 
# ---------
# Copyright (c) 2002-2006 UC Regents
# 
# Permission to use, copy, modify, distribute, and sell this software and
# its documentation for any purpose is hereby granted without fee, provided
# that (i) the above copyright notices and this permission notice appear in
# all copies of the software and related documentation, and (ii) the names
# of the UC Regents and the University of California are not used in any
# advertising or publicity relating to the software without the specific,
# prior written permission of the University of California.
# 
# THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY 
# WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE FOR ANY
# SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
# OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY
# THEORY OF LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE
# OR PERFORMANCE OF THIS SOFTWARE.
# ---------

# Perl style note -- this code makes frequent use of a fast, big boolean
# version of an if-elsif-else idiom that Perl encourages because entering
# a { block } is relatively expensive, but it looks strange if you're not
# used to it.  Instead of
#
#	if ( e1 && e2 && e3 ) {
#		s1;
#		s2;
#		...;
#	}
#	elsif ( e4 || e5 && e6 ) {
#		s3;
#	}
#	else {
#		s4;
#		s5;
#	}
#
# we can write this series of test expressions and statements as
#
#	e1 && e2 && e3 and
#		s1,
#		s2,
#	1 or
#	e4 || e5 && e6 and
#		s3,
#	1 or
#		s4,
#		s5,
#	1;
#
# If we KNOW (not safest) that s2 and s3 are "true", we shorten it to
#
#	e1 && e2 && e3 and
#		s1,
#		s2
#	or
#	e4 || e5 && e6 and
#		s3
#	or
#		s4,
#		s5
#	;
#
# For the big boolean form to work, you'll be well-advised to call make
# your Perl calls with the parenthesized syntax, so that the commas
# terminating the boolean statements don't get swallowed up by the Perl
# functions and built-ins that you're using (eg, can get into trouble
# unless you parenthesize your "print" statements).

# yyy many comment blocks are very out of date -- need thorough review
# yyy make it so that http://uclibs.org/PID/foo maps to 
#     ark.cdlib.org/ark:/13030/xzfoo  [ requirement from SCP meeting May 2004]
# yyy use "wantarray" function to return either number or message
#     when bailing out.
# yyy add cdlpid doc to pod ?
# yyy write about comparison with PURLs
# yyy check chars, authentication, ordinal stored in metadata
# yyy implement mod 4/8/16 distribution within large counter regions?
# yyy implement count-down counters as well as count-up?
# yyy make a shadow DB

# yyy upgrade ark-service and ERC.pm (which still use PDB.pm)

# yyy bindallow(), binddeny() ????

use constant NOLIMIT		=> -1;
use constant SEQNUM_MIN		=>  1;
use constant SEQNUM_MAX		=>  1000000;

# The database must hold nearly arbitrary user-level identifiers
# alongside various admin variables.  In order not to conflict, we
# require all admin variables to start with ":/", eg, ":/oacounter".
# We use "$R/" frequently as our "reserved root" prefix.
#
my $R = ":";		# prefix for global top level of admin db variables

use Fcntl qw(:DEFAULT :flock);
use BerkeleyDB;

# Global %opendbtab is a hash that maps a hashref (as key) to a database
# reference.  At a minimum, we need opendbtab so that we avoid passing a
# db reference to dbclose, which cannot do the final "untie" (see
# "untie gotcha" documentation) while the caller's db reference is
# still defined.
#
my %opendbtab;

# To iterate over all Noids in the database, use
#
# each %hash
# return $db or null
# $flags one of O_RDONLY, O_RDWR, O_CREAT

our ($legalstring, $alphacount, $digitcount);
our $locktest = 0;

# Adds an error message for a database pointer/object.  If the message
# pertains to a failed open, the pointer is null, in which case the
# message gets saved to what essentially acts like a global (possible
# threading conflict).
#
sub addmsg{ my( $noid, $message )=@_;

	$noid ||= "";		# act like a global in case $noid undefined
	$opendbtab{"msg/$noid"} .= $message . "\n";
	return 1;
}

# Returns accumulated messages for a database pointer/object.  If the
# second argument is non-zero, also reset the message to the empty string.
#
sub errmsg{ my( $noid, $reset )=@_;

	$noid ||= "";		# act like a global in case $noid undefined
	my $s = $opendbtab{"msg/$noid"};
	$reset and
		$opendbtab{"msg/$noid"} = "";
	return $s;
}

sub logmsg{ my( $noid, $message )=@_;

	$noid ||= "";		# act like a global in case $noid undefined
	my $logfhandle = $opendbtab{"log/$noid"};
	defined($logfhandle) and
		print($logfhandle $message, "\n");
	# yyy file was opened for append -- hopefully that means always
	#     append even if others have appended to it since our last append;
	#     possible sync problems...
	return 1;
}

sub storefile { my( $fname, $contents )=@_;
	! open(OUT, ">$fname") and
		return 0;
	print OUT $contents;
	close(OUT);
	return 1;
}

# Legal values of $how for the bind function.
#
my @valid_hows = qw(
	new replace set
	append prepend add insert
	delete purge mint peppermint
);

#
# --- begin alphabetic listing (with a few exceptions) of functions ---
#

# Returns ANVL message on success, undef on error.
#
sub bind { my( $noid, $contact, $validate, $how, $id, $elem, $value )=@_;
# yyy to add: incr, decr for $how;  possibly other ops (* + - / **)

	# Validate identifier and element if necessary.
	#
	# yyy to do: check $elem against controlled vocab
	#     (for errors more than for security)
	# yyy should this genonly setting be so capable of contradicting
	#     the $validate arg?
	$$noid{"$R/genonly"} && $validate
		&& ! validate($noid, "-", $id) and
			return(undef)
	or
	! defined($id) || $id eq "" and
		addmsg($noid, "error: bind needs an identifier specified."),
		return(undef)
	;
	! defined($elem) || $elem eq "" and
		addmsg($noid, qq@error: "bind $how" requires an element name.@),
		return(undef);

	# Transform and place a "hold" (if "long" term and we're not deleting)
	# on a special identifier.  Right now that means a user-entrered Id
	# of the form :idmap/Idpattern.  In this case, change it to a database
	# Id of the form "$R/idmap/$elem", and change $elem to hold Idpattern;
	# this makes lookup faster and easier.
	#
	# First save original id and element names in $oid and $oelem to
	# use for all user messages; we use whatever is in $id and $elem
	# for actual database operations.
	#
	my ($oid, $oelem, $hold) = ($id, $elem, 0);
	if ($id =~ /^:/) {
		$id !~ m|^:idmap/(.+)| and
			addmsg($noid, qq@error: $oid: id cannot begin with ":"@
				. qq@ unless of the form ":idmap/Idpattern".@),
			return(undef);
		($id, $elem) = ("$R/idmap/$oelem", $1);
		$$noid{"$R/longterm"} and
			$hold = 1;
	}
	# yyy transform other ids beginning with ":"?

	# Check circulation status.  Error if term is "long" and the id
	# hasn't been issued unless a hold was placed on it.
	#
	# If no circ record and no hold...
	if (! defined($$noid{"$id\t$R/c"}) && ! exists($$noid{"$id\t$R/h"})) {
		$$noid{"$R/longterm"} and
			addmsg($noid, "error: "
				. qq@$oid: "long" term disallows binding @
				. "an unissued identifier unless a hold is "
				. "first placed on it."),
			return(undef)
		or
			logmsg($noid, "warning:"
				. " $oid: binding an unissued identifier"
				. " that has no hold placed on it.")
		;
	}
	if (grep(/^$how$/, @valid_hows) != 1) {
		addmsg($noid, "error: bind how?  What does $how mean?");
		return(undef);
	}
	my $peppermint = ($how eq "peppermint");
	$peppermint and
		# yyy to do
		addmsg($noid, qq@error: bind "peppermint" not implemented.@),
		return(undef);
	# YYY bind mint file Elem Value		-- put into FILE by itself
	# YYY bind mint stuff_into_big_file Elem Value -- cat into file
	if ($how eq "mint" || $how eq "peppermint") {
		$id ne "new" and
			addmsg(qq@error: bind "mint" requires id to be @
				. qq@given as "new".@),
			return(undef);
		! ($id = $oid = mint($noid, $contact, $peppermint)) and
			return(undef);
	}
	$how eq "delete" || $how eq "purge" and
		(defined($value) && $value eq "" and
			addmsg($noid, qq@error: why does "bind $how" @
				. "have a supplied value ($value)?"),
			return(undef)),
		$value = "",
		1
	or
	! defined($value) and
		addmsg($noid,
			qq@error: "bind $how $elem" requires a value to bind.@),
		return(undef)
	;
	# If we get here, $value is defined and we can use with impunity.

	dblock();
	if (! defined($$noid{"$id\t$elem"})) {		# currently unbound
		grep(/^$how$/, qw( replace append prepend delete )) == 1 and
			addmsg($noid, qq@error: for "bind $how", "$oid $oelem" @
				. "must already be bound."),
			dbunlock(),
			return(undef);
		$$noid{"$id\t$elem"} = "";	# can concatenate with impunity
	}
	else {						# currently bound
		grep(/^$how$/, qw( new mint peppermint )) == 1 and
			addmsg($noid, qq@error: for "bind $how", "$oid $oelem" @
				. " cannot already be bound."),
			dbunlock(),
			return(undef);
	}
	# We don't care about bound/unbound for:  set, add, insert, purge

	my $oldlen = length($$noid{"$id\t$elem"});
	my $newlen = length($value);
	my $statmsg = "$newlen bytes written";

	$how eq "delete" || $how eq "purge" and
		delete($$noid{"$id\t$elem"}),
		$statmsg = "$oldlen bytes removed"
	or
	$how eq "add" || $how eq "append" and
		$$noid{"$id\t$elem"} .= $value,
		$statmsg .= " to the end of $oldlen bytes",
	or
	$how eq "insert" || $how eq "prepend" and
		$$noid{"$id\t$elem"} = $value . $$noid{"$id\t$elem"},
		$statmsg .= " to the beginning of $oldlen bytes",
	or
		$$noid{"$id\t$elem"} = $value,
		$statmsg .= ", replacing $oldlen bytes",
	;
	$hold and exists($$noid{"$id\t$elem"}) and ! hold_set($noid, $id) and
		$hold = -1;	# don't just bail out -- we need to unlock

	# yyy $contact info ?  mainly for "long" term identifiers?
	dbunlock();

	return(
# yyy should this $id be or not be $oid???
# yyy should labels for Id and Element be lowercased???
"Id:      $id
Element: $elem
Bind:    $how
Status:  " . ($hold == -1 ? errmsg($noid) : "ok, $statmsg") . "\n");
}

# Primes:
#   2        3        5        7      
#  11       13       17       19      
#  23       29       31       37      
#  41       43       47       53      
#  59       61       67       71      
#  73       79       83       89      
#  97      101      103      107      
# 109      113      127      131      
# 137      139      149      151      
# 157      163      167      173      
# 179      181      191      193      
# 197      199      211      223      
# 227      229      233      239      
# 241      251      257      263      
# 269      271      277      281      
# 283      293      307      311      
# 313      317      331      337      
# 347      349      353      359      
# 367      373      379      383      
# 389      397      401      409      
# 419      421      431      433      
# 439      443      449      457      
# 461      463      467      479      
# 487      491      499      503  ...

# yyy other character subsets? eg, 0-9, a-z, and _  (37 chars, with 37 prime)
#      this could be mask character 'w' ?
# yyy there are 94 printable ASCII characters, with nearest lower prime = 89
#      a radix of 89 would result in a huge, compact space with check chars
#      mask character 'c' ?

# Extended digits array.  Maps ordinal value to ASCII character.
my @xdig = (
	'0', '1', '2', '3', '4',   '5', '6', '7', '8', '9',
	'b', 'c', 'd', 'f', 'g',   'h', 'j', 'k', 'm', 'n',
	'p', 'q', 'r', 's', 't',   'v', 'w', 'x', 'z'
);
# $legalstring should be 0123456789bcdfghjkmnpqrstvwxz
$legalstring = join('', @xdig);
$alphacount = scalar(@xdig);		# extended digits count
$digitcount = 10;			# pure digit count

# Ordinal value hash for extended digits.  Maps ASCII characters to ordinals.
my %ordxdig = (
	'0' =>  0,  '1' =>  1,  '2' =>  2,  '3' =>  3,  '4' =>  4,
	'5' =>  5,  '6' =>  6,  '7' =>  7,  '8' =>  8,  '9' =>  9,

	'b' => 10,  'c' => 11,  'd' => 12,  'f' => 13,  'g' => 14,
	'h' => 15,  'j' => 16,  'k' => 17,  'm' => 18,  'n' => 19,

	'p' => 20,  'q' => 21,  'r' => 22,  's' => 23,  't' => 24,
	'v' => 25,  'w' => 26,  'x' => 27,  'z' => 28
);

# Compute check character for given identifier.  If identifier ends in '+'
# (plus), replace it with a check character computed from the preceding chars,
# and return the modified identifier.  If not, isolate the last char and
# compute a check character using the preceding chars; return the original
# identifier if the computed char matches the isolated char, or undef if not.

# User explanation:  check digits help systems to catch transcription
# errors that users might not be aware of upon retrieval; while users
# often have other knowledge with which to determine that the wrong
# retrieval occurred, this error is sometimes not readily apparent.
# Check digits reduce the chances of this kind of error.
# yyy ask Steve Silberstein (of III) about check digits?

sub checkchar{ my( $id )=@_;
	return undef
		if (! $id );
	my $lastchar = chop($id);
	my $pos = 1;
	my $sum = 0;
	my $c;
	for $c (split(//, $id)) {
		# if character undefined, it's ordinal value is zero
		$sum += $pos * (defined($ordxdig{"$c"}) ? $ordxdig{"$c"} : 0);
		$pos++;
	}
	my $checkchar = $xdig[$sum % $alphacount];
	#print "RADIX=$alphacount, mod=", $sum % $alphacount, "\n";
	return $id . $checkchar
		if ($lastchar eq "+" || $lastchar eq $checkchar);
	return undef;		# must be request to check, but failed match
	# xxx test if check char changes on permutations
	# XXX include test of length to make sure < than 29 (R) chars long
	# yyy will this work for doi/handles?
}

# Returns an array of cleared ids and byte counts if $verbose is set,
# otherwise returns an empty array.  Set $verbose when we want to report what
# was cleared.  Admin bindings aren't touched; they must be cleared manually.
#
# We always check for bindings before issuing, because even a previously
# unissued id may have been bound (unusual for many minter situations).
#
# Use dblock() before and dbunlock() after calling this routine.
#
sub clear_bindings { my( $noid, $id, $verbose )=@_;

	my @retvals;
	my $db = $opendbtab{"bdb/$noid"};
	my $cursor = $db->db_cursor();

	# yyy right now "$id\t" defines how we bind stuff to an id, but in the
	#     future that could change.  in particular we don't bind (now)
	#     anything to just "$id" (without a tab after it)
	my ($first, $skip, $done) = ("$id\t", 0, 0);
	my ($key, $value) = ($first, 0);
	my $status = $cursor->c_get($key, $value, DB_SET_RANGE);
	$status == 0 and
		$skip = ($key =~ m|^$first$R/|),
		$done = ($key !~ m|^$first|),
	1 or
		$done = 1
	;
	while (! $done) {
		! $skip and $verbose and
			# if $verbose (ie, fetch), include label and
			# remember to strip "Id\t" from front of $key
			push(@retvals, ($key =~ /^[^\t]*\t(.*)/ ? $1 : $key)
				. ": clearing " . length($value) . " bytes"),
			delete($$noid{$key});
		$status = $cursor->c_get($key, $value, DB_NEXT);
		$status != 0 || $key !~ /^$first/ and
			$done = 1	# no more elements under id
		or
			$skip = ($key =~ m|^$first$R/|)
		;
	}
	undef($cursor);
	return($verbose ? @retvals : ());
}

# Returns a short printable message on success, undef on error.
#
sub dbcreate { my( $dbdir, $contact, $template, $term,
		$naan, $naa, $subnaa )=@_;

	my ($total, $noid);
	my $dir = "$dbdir/NOID";
	my $dbname = "$dir/noid.bdb";
	# yyy try to use "die" to communicate to caller (graceful?)
	# yyy how come tie doesn't complain if it exists already?

	-e $dbname and
		addmsg(undef, "error: a NOID database already exists in "
			. ($dbdir ne "." ? "\"$dbdir\"."
				: "the current directory.") . "\n"
			. "\tTo permit creation of a new minter, rename\n"
			. "\tor remove the entire NOID subdirectory."),
		return(undef);
	! -d $dir && ! mkdir($dir) and
		addmsg(undef, "error: couldn't create database directory\n"
			. "$dir: $!\n"),
		return(undef);

	my ($prefix, $mask, $gen_type, $msg, $genonly);
	! defined($template) and
		$genonly = 0,
		$template = ".zd"
	or
		$genonly = 1,			# not generated ids only
	;
	$total = parse_template($template, $prefix, $mask, $gen_type, $msg);
	! $total and
		addmsg($noid, $msg),
		return(undef);
	my $synonym = "noid" . ($genonly ? "_$msg" : "any");

	# Type check various parameters.
	#
	! defined($contact) || $contact !~ /\S/ and
		addmsg($noid, "error: contact ($contact) must be non-empty."),
		return(undef);

	$term ||= "-";
	$term ne "long" && $term ne "medium"
			&& $term ne "-" && $term ne "short" and
		addmsg($noid, "error: term ($term) must be either "
			. qq@"long", "medium", "-", or "short".@),
		return(undef);

	! defined($naa) and $naa = "";
	! defined($naan) and $naan = "";
	! defined($subnaa) and $subnaa = "";

	$term eq "long" &&
		($naan !~ /\S/ || $naa !~ /\S/ || $subnaa !~ /\S/) and
			addmsg($noid, qq@error: longterm identifiers require @
				. "an NAA Number, NAA, and SubNAA."),
			return(undef);
	# xxx should be able to check naa and naan live against registry
	# yyy code should invite to apply for NAAN by email to ark@cdlib.org
	# yyy ARK only? why not DOI/handle?
	$term eq "long" && ($naan !~ /\d\d\d\d\d/) and
		addmsg($noid, qq@error: term of "long" requires a @
			. "5-digit NAAN (00000 if none), and non-empty "
			. "string values for NAA and SubNAA."),
		return(undef);

	# Create log and logbdb files from scratch and make them writable
	# before calling dbopen().
	#
	! storefile("$dir/log", "") || ! chmod(0666, "$dir/log") and
		addmsg(undef, "Couldn't chmod log file: $!"),
		return(undef);
	! storefile("$dir/logbdb", "") || ! chmod(0666, "$dir/logbdb") and
		addmsg(undef, "Couldn't chmod logbdb file: $!"),
		return(undef);
	! ($noid = dbopen($dbname, DB_CREATE)) and
		addmsg(undef, "can't create database file: $!"),
		return(undef);
	logmsg($noid, ($template ?
		qq@Creating database for template "$template".@
		: "Creating database for bind-only minter."));

	# Database info
	# yyy should be using db-> ops directly (for efficiency and?)
	#     so we can use DB_DUP flag
	$$noid{"$R/naa"} = $naa;
	$$noid{"$R/naan"} = $naan;
	$$noid{"$R/subnaa"} = $subnaa || "";

	$$noid{"$R/longterm"} = ($term eq "long");
	$$noid{"$R/wrap"} = ($term eq "short");		# yyy follow through

	$$noid{"$R/template"} = $template;
	$$noid{"$R/prefix"} = $prefix;
	$$noid{"$R/mask"} = $mask;
	$$noid{"$R/firstpart"} = ($naan ? $naan . "/" : "") . $prefix;
	$$noid{"$R/addcheckchar"} = ($mask =~ /k$/);	# boolean answer

	$$noid{"$R/generator_type"} = $gen_type;
	$$noid{"$R/genonly"} = $genonly;

	$$noid{"$R/total"} = $total;
	$$noid{"$R/padwidth"} = ($total == NOLIMIT ? 16 : 2) + length($mask);
		# yyy kludge -- padwidth of 16 enough for most lvf sorting

	# Some variables:
	#   oacounter	overall counter's current value (last value minted)
	#   oatop	overall counter's greatest possible value of counter
	#   held	total with "hold" placed
	#   queued	total currently in the queue
	$$noid{"$R/oacounter"} = 0;
	$$noid{"$R/oatop"} = $total;
	$$noid{"$R/held"} = 0;
	$$noid{"$R/queued"} = 0;

	$$noid{"$R/fseqnum"} = SEQNUM_MIN;	# see queue() and mint()
	$$noid{"$R/gseqnum"} = SEQNUM_MIN;	# see queue()
	$$noid{"$R/gseqnum_date"} = 0;		# see queue()

	$$noid{"$R/version"} = $VERSION;

	# yyy should verify that a given NAAN and NAA are registered,
	#     and should offer to register them if not.... ?

	# Capture the properties of this minter.
	#
	# There are seven properties, represented by a string of seven
	# capital letters or a hyphen if the property does not apply.
	# The maximal string is GRANITE (we first had GRANT, then GARNET).
	# We don't allow 'l' as an extended digit (good for minimizing
	# visual transcriptions errors), but we don't get a chance to brag
	# about that here.
	#
	# Note that on the Mohs mineral hardness scale from 1 - 10,
	# the hardest is diamonds (which are forever), but granites
	# (combinations of feldspar and quartz) are 5.5 to 7 in hardness.
	# From http://geology.about.com/library/bl/blmohsscale.htm ; see also
	# http://www.mineraltown.com/infocoleccionar/mohs_scale_of_hardness.htm
	#
	# These are far from perfect measures of identifier durability,
	# and of course they are only from the assigner's point of view.
	# For example, an alphabetical restriction doesn't guarantee
	# opaqueness, but it indicates that semantics will be limited.
	#
	# yyy document that (I)mpressionable has to do with printing, does
	#     not apply to general URLs, but does apply to phone numbers and
	#     ISBNs and ISSNs
	# yyy document that the opaqueness test is English-centric -- these
	#     measures work to some extent in English, but not in Welsh(?)
	#     or "l33t"
	# yyy document that the properties are numerous enough to look for
	#     a compact acronym, that the choice of acronym is sort of
	#     arbitrary, so (GRANITE) was chosen since it's easy to remember
	#
	# $pre and $msk are in service of the letter "A" below.
	(my $pre = $prefix) =~ s/[a-z]/e/ig;
	(my $msk = $mask) =~ s/k/e/g;
	$msk =~ s/^ze/zeeee/;		# initial 'e' can become many later on

	my $properties = 
		($naan ne "" && $naan ne "00000" ? "G" : "-")
		. ($gen_type eq "random" ? "R" : "-")
		# yyy substr is supposed to cut off first char
		. ($genonly && ($pre . substr($msk, 1)) !~ /eee/ ? "A" : "-")
		. ($term eq "long" ? "N" : "-")
		. ($genonly && $prefix !~ /-/ ? "I" : "-")
		. ($$noid{"$R/addcheckchar"} ? "T" : "-")
		# yyy "E" mask test anticipates future extensions to alphabets
		. ($genonly && ($prefix =~ /[aeiouy]/i || $mask =~ /[^rszdek]/)
			? "-" : "E")		# Elided vowels or not
	;
	$$noid{"$R/properties"} = $properties;

	# Now figure out "where" element.
	#
	use Sys::Hostname;
	my $host = hostname();

#	my $child_process_id;
#	unless (defined($child_process_id = open(CHILD, "-|"))) {
#		die "unable to start child process, $!, stopped";
#		}
#	if ($child_process_id == 0) {
#		# We are in the child.  Set the PATH environment variable.
#		$ENV{"PATH"} = "/bin:/usr/bin";
#		# Run the command we want, with its STDOUT redirected
#		# to the pipe that goes back to the parent.
#		exec "/bin/hostname";
#		die "unable to execute \"/bin/hostname\", $!, stopped";
#	}
#	else {
#		# We are in the parent, and the CHILD file handle is
#		# the read end of the pipe that has its write end as
#		# STDOUT of the child.
#		$host = <CHILD>;
#		close(CHILD);
#		chomp $host;
#	}

	my $cwd = $dbdir;	# by default, assuming $dbdir is absolute path 
	if ($dbdir !~ m|^/|) {
		$cwd = $ENV{"PWD"} . "/$dbdir";
		}

	# Adjust some empty values for short-term display purposes.
	#
	$naa ||= "no Name Assigning Authority";
	$subnaa ||= "no sub authority";
	$naan ||= "no NAA Number";

	# Create a human- and machine-readable report.
	#
	my @p = split(//, $properties);			# split into letters
	s/-/_ not/ || s/./_____/
		for (@p);
	my $random_sample;			# undefined on purpose
	$total == NOLIMIT and
		$random_sample = int(rand(10));	# first sample less than 10
	my $sample1 = sample($noid, $random_sample);
	$total == NOLIMIT and
		$random_sample = int(rand(100000));	# second sample bigger
	my $sample2 = sample($noid, $random_sample);

	my $htotal = ($total == NOLIMIT ? "unlimited" : human_num($total));
	my $what = ($total == NOLIMIT ? "unlimited" : $total)
		. qq@ $gen_type identifiers of form $template
       A Noid minting and binding database has been created that will bind
       @
		. ($genonly ? "" : "any identifier ") . "and mint "
		. ($total == NOLIMIT ? qq@an unbounded number of identifiers
       with the template "$template".@
		: $htotal . qq@ identifiers with the template "$template".@)
		. qq@
       Sample identifiers would be "$sample1" and "$sample2".
       Minting order is $gen_type.@;

	$$noid{"$R/erc"} = 
qq@# Creation record for the identifier generator in NOID/noid.bdb.
# 
erc:
who:       $contact
what:      $what
when:      @ . temper() . qq@
where:     $host:$cwd
Version:   Noid $VERSION
Size:      @ . ($total == NOLIMIT ? "unlimited" : $total) . qq@
Template:  @ . (! $template ? "(:none)" : $template . qq@
       A suggested parent directory for this template is "$synonym".  Note:
       separate minters need separate directories, and templates can suggest
       short names; e.g., the template "xz.redek" suggests the parent directory
       "noid_xz4" since identifiers are "xz" followed by 4 characters.@) . qq@
Policy:    (:$properties)
       This minter's durability summary is (maximum possible being "GRANITE")
         "$properties", which breaks down, property by property, as follows.
          ^^^^^^^
          |||||||_$p[6] (E)lided of vowels to avoid creating words by accident
          ||||||_$p[5] (T)ranscription safe due to a generated check character
          |||||_$p[4] (I)mpression safe from ignorable typesetter-added hyphens
          ||||_$p[3] (N)on-reassignable in life of Name Assigning Authority
          |||_$p[2] (A)lphabetic-run-limited to pairs to avoid acronyms
          ||_$p[1] (R)andomly sequenced to avoid series semantics
          |_$p[0] (G)lobally unique within a registered namespace (currently
                     tests only ARK namespaces; apply for one at ark@
	     . '@' . qq@cdlib.org)
Authority: $naa | $subnaa
NAAN:      $naan
@;
	! storefile("$dir/README", $$noid{"$R/erc"})
		and return(undef);
	# yyy useful for quick info on a minter from just doing 'ls NOID'??
	#          storefile("$dir/T=$prefix.$mask", "foo\n");

	my $report = qq@Created:   minter for $what  @
		. qq@See $dir/README for details.\n@;

	! $template and
		dbclose($noid),
		return($report);

	init_counters($noid);
	dbclose($noid);
	return($report);
}

# Report values according to $level.  Values of $level:
# "brief" (default)	user vals and interesting admin vals
# "full"		user vals and all admin vals
# "dump"		all vals, including all identifier bindings
#
sub dbinfo { my( $noid, $level )=@_;
	my $db = $opendbtab{"bdb/$noid"};
	my $cursor = $db->db_cursor();
	my ($key, $value) = ("$R/", 0);
	if ($level eq "dump") {
		print "$key: $value\n"
			while ($cursor->c_get($key, $value, DB_NEXT) == 0);
		return 1;
	}
	my $status = $cursor->c_get($key, $value, DB_SET_RANGE);
	if ($status) {
		addmsg($noid, "c_get status/errno ($status/$!)");
		return 0;
	}
	if ($key =~ m|^$R/$R/|) {
		print "User Assigned Values\n";
		print "  $key: $value\n";
		while ($cursor->c_get($key, $value, DB_NEXT) == 0) {
			last
				if ($key !~ m|^$R/$R/|);
			print "  $key: $value\n";
		}
		print "\n";
	}
	print "Admin Values\n";
	print "  $key: $value\n";
	while ($cursor->c_get($key, $value, DB_NEXT) == 0) {
		last
			if ($key !~ m|^$R/|);
		print "  $key: $value\n"
			if ($level eq "full" or
				$key !~ m|^$R/c\d| &&
				$key !~ m|^$R/saclist| &&
				$key !~ m|^$R/recycle/|);
	}
	print "\n";
	undef $cursor;
	return 1;
}

# yyy eventually we would like to do fancy fine-grained locking with
#     BerkeleyDB features.  For now, lock before tie(), unlock after untie().
sub dblock{ return 1;	# placeholder
}
sub dbunlock{ return 1;	# placeholder
}

# returns noid: a listref
# $flags can be DB_RDONLY, DB_CREATE, or 0 (for read/write, the default)
#
sub dbopen { my( $dbname, $flags )=@_;

	# yyy to test: can we now open more than one noid at once?

	my ($env, $envhome);
	($envhome = $dbname) =~ s|[^/]+$||;	# path ending in "NOID/"
	! -d $envhome and
		addmsg(undef, "$envhome not a directory"),
		return undef;
	# yyy probably these envflags are overkill right now
	my $envflags = DB_INIT_LOCK | DB_INIT_TXN | DB_INIT_MPOOL;
	#my $envflags = DB_INIT_CDB | DB_INIT_MPOOL;
	($flags & DB_CREATE) and
		$envflags |= DB_CREATE;
	my @envargs = (
		-Home => $envhome,
		-Flags => $envflags,
		-Verbose => 1
	);

	# If it exists and is writable, use log file to inscribe BDB errors.
	#
	my ($logfile, $logfhandle, $log_opened, $logbdb);

	$logfile = $envhome . "log";
	$log_opened = open($logfhandle, ">>$logfile");
	$logbdb = $envhome . "logbdb";
	-w $logbdb and
		push(@envargs, ( -ErrFile => $logbdb ));
	# yyy should we complain if can't open log file?

	$env = new BerkeleyDB::Env @envargs;
	! defined($env) and
		addmsg(undef, "no \"Env\" object ($BerkeleyDB::Error)"),
		return undef;

#=for deleting
#
#	print "OK so far\n"; exit(0);
#	if ($flags && DB_CREATE) {
#		# initialize environment files
#		print "envhome=$envhome\n";
#		$env = new BerkeleyDB::Env @envargs;
#		! defined($env) and
#			addmsg(undef,
#				"no \"Env\" object ($BerkeleyDB::Error)"),
#			return undef;
#	}
#	else {
#		print "flags=$flags\n";
#	}
#	print "OK so far\n"; exit(0);
#	$env = new BerkeleyDB::Env @envargs;
#	unless (defined($env)) {
#		die "unable to get a \"BerkeleyDB::Env\" object ($BerkeleyDB::Error), stopped";
#		}
#
#=cut

	my $noid = {};		# eventual minter database handle

	# For now we use simple database-level file locking with a timeout.
	# Unlocking is implicit when the NOIDLOCK file handle is closed
	# either explicitly or upon process termination.
	#
	my $lockfile = $envhome . "lock";
	my $timeout = 5;	# max number of seconds to wait for lock
	my $locktype = (($flags & DB_RDONLY) ? LOCK_SH : LOCK_EX);

	! sysopen(NOIDLOCK, $lockfile, O_RDWR | O_CREAT) and
		addmsg(undef, "cannot open \"$lockfile\": $!"),
		return undef;
	eval {
		
		local $SIG{ALRM} = sub { die("lock timeout after $timeout "
			. "seconds; consider removing \"$lockfile\"\n")
		};
		alarm $timeout;		# alarm goes off in $timeout seconds
		eval {	# yyy if system has no flock, say in dbcreate profile?
			flock(NOIDLOCK, $locktype)	# blocking lock
				or die("cannot flock: $!");
		};
		alarm 0;		# cancel the alarm
		die $@ if $@;		# re-raise the exception
	};
	alarm 0;			# race condition protection
	if ($@) {			# re-raise the exception
		addmsg(undef, "error: $@");
		return undef;
	}

	my $db = tie(%$noid, "BerkeleyDB::Btree",
			-Filename => "noid.bdb",	# env has path to it
			-Flags => $flags,
## yyy			-Property => DB_DUP,
			-Env => $env)
		or addmsg(undef, "tie failed on $dbname: $BerkeleyDB::Error")
			and return undef;
	# yyy how to set error code or return string?
	#	or die("Can't open database file: $!\n");
	#print "dbopen: returning hashref=$noid, db=$db\n";
	$opendbtab{"bdb/$noid"} = $db;
	$opendbtab{"msg/$noid"} = "";
	$opendbtab{"log/$noid"} = ($log_opened ? $logfhandle : undef);

	$locktest and
		print("locktest: holding lock for $locktest seconds...\n"),
		sleep($locktest);

	return $noid;
}

# Call with number of seconds to sleep at end of each open.
# This exists only for the purpose of testing the locking mechanism.
#
sub locktest { my( $sleepvalue )=@_;
	$locktest = $sleepvalue;	# set global variable for locktest
	return 1;
}

sub dbclose { my( $noid )=@_;
	undef $opendbtab{"msg/$noid"};
	defined($opendbtab{"log/$noid"}) and
		close($opendbtab{"log/$noid"});
	undef $opendbtab{"bdb/$noid"};
	untie %$noid;
	close NOIDLOCK;		# let go of lock
}

# yyy is this needed? in present form?
#
# get next value and, if no error, change the 2nd and 3rd parameters and
# return 1, else return 0.  To start at the beginning, the 2nd parameter,
# key (key), should be set to zero by caller, who might do this:
# $key = 0; while (each($noid, $key, $value)) { ... }
# The 3rd parameter will contain the corresponding value.

sub eachnoid { my( $noid, $key, $value )=@_;
	# yyy check that $db is tied?  this is assumed for now
	# yyy need to get next non-admin key/value pair
	my $db = $opendbtab{"bdb/$noid"};
	#was: my $flag = ($key ? R_NEXT : R_FIRST);
	# fix from Jim Fullton:
	my $flag = ($key ? DB_NEXT : DB_FIRST);
	my $cursor = $db->db_cursor();
	if ($cursor->c_get($key, $value, $flag)) {
		return 0;
	}
	$_[1] = $key;
	$_[2] = $value;
	return 1;
}

# A no-op function to call instead of checkchar().
#
sub echo {
	return $_[0];
}

# $verbose is 1 if we want labels, 0 if we don't
# yyy do we need to be able to "get/fetch" with a discriminant,
#     eg, for smart multiple resolution??
sub fetch { my( $noid, $verbose, $id, @elems )=@_;

	! defined($id) and
		addmsg($noid, "error: " . ($verbose ? "fetch" : "get")
			. " requires that an identifier be specified."),
		return(undef);

	my ($hdr, $retval) = ("", "");
	$verbose and $hdr = "id:    $id"
		. (exists($$noid{"$id\t$R/h"}) ? " hold" : "") . "\n"
		. (validate($noid, "-", $id) ? "" : errmsg($noid) . "\n")
		. "Circ:  " . ($$noid{"$id\t$R/c"}
			? $$noid{"$id\t$R/c"} : "uncirculated") . "\n";

	my $db = $opendbtab{"bdb/$noid"};
	my $cursor = $db->db_cursor();

	if ($#elems < 0) {	# No elements were specified, so find them.
		my ($first, $skip, $done) = ("$id\t", 0, 0);
		my ($key, $value) = ($first, 0);
		my $status = $cursor->c_get($key, $value, DB_SET_RANGE);
		$status == 0 and
			$skip = ($key =~ m|^$first$R/|),
			$done = ($key !~ m|^$first|),
		1 or
			$done = 1
		;
		while (! $done) {
			! $skip and
				# if $verbose (ie, fetch), include label and
				# remember to strip "Id\t" from front of $key
				$retval .= ($verbose ?
					($key =~ /^[^\t]*\t(.*)/ ? $1 : $key)
						. ": " : "") . "$value\n";
			$status = $cursor->c_get($key, $value, DB_NEXT);
			$status != 0 || $key !~ /^$first/ and
				$done = 1	# no more elements under id
			or
				$skip = ($key =~ m|^$first$R/|)
			;
		}
		undef($cursor);
		! $retval and
			addmsg($noid, $hdr
				. "note: no elements bound under $id."),
			return(undef);
		return($hdr . $retval);
	}
	# yyy should this work for elem names with regexprs in them?
	# XXX idmap won't bind with longterm ???
	my $idmapped;
	for my $elem (@elems) {
		$$noid{"$id\t$elem"} and
			($verbose and
				$retval .= "$elem: "),
			$retval .= $$noid{"$id\t$elem"} . "\n"
		or
			$idmapped = id2elemval($cursor, $verbose, $id, $elem),
			($verbose and
				$retval .= ($idmapped ? "$idmapped\nnote: "
					. "previous result produced by :idmap\n"
				    : qq@error: "$id $elem" is not bound.\n@)
			or
				$retval .= "$idmapped\n"
			)
		;
	}
	undef($cursor);
	return($hdr . $retval);
}

# Generate the actual next id to give out.  May be randomly or sequentially
# selected.  This routine should not be called if there are ripe recyclable
# identifiers to use.
#
# This routine and n2xdig comprise the real heart of the minter software.
#
sub genid { my( $noid )=@_;
	dblock();

	# Variables:
	#   oacounter	overall counter's current value (last value minted)
	#   oatop	overall counter's greatest possible value of counter
	#   saclist	(sub) active counters list
	#   siclist	(sub) inactive counters list
	#   c$n/value	subcounter name's ($scn) value

	my $oacounter = $$noid{"$R/oacounter"};

	# yyy what are we going to do with counters for held? queued?

	if ($$noid{"$R/oatop"} != NOLIMIT && $oacounter >= $$noid{"$R/oatop"}) {

		# Critical test of whether we're willing to re-use identifiers
		# by re-setting (wrapping) the counter to zero.  To be extra
		# careful we check both the longterm and wrap settings, even
		# though, in theory, wrap won't be set if longterm is set.
		#
		if ($$noid{"$R/longterm"} || ! $$noid{"$R/wrap"}) {
			dbunlock();
			my $m = "error: identifiers exhausted (stopped at "
				. $$noid{"$R/oatop"} . ").";
			addmsg($noid, $m);
			logmsg($noid, $m);
			return undef;
		}
		# If we get here, term is not "long".
		logmsg($noid, temper() . ": Resetting counter to zero; "
			. "previously issued identifiers will be re-issued");
		if ($$noid{"$R/generator_type"} eq "sequential") {
			$$noid{"$R/oacounter"} = 0;
		}
		else {
			init_counters($noid);	# yyy calls dblock -- problem?
		}
		$oacounter = 0;
	}
	# If we get here, the counter may actually have just been reset.

	# Deal with the easy sequential generator case and exit early.
	#
	if ($$noid{"$R/generator_type"} eq "sequential") {
		my $id = &n2xdig($$noid{"$R/oacounter"}, $$noid{"$R/mask"});
		$$noid{"$R/oacounter"}++;	# incr to reflect new total
		dbunlock();
		return $id;
	}

	# If we get here, the generator must be of type "random".
	#
	my $len = (my @saclist = split(/ /, $$noid{"$R/saclist"}));
	if ($len < 1) {
		dbunlock();
		addmsg($noid, "error: no active counters panic, "
			. "but $oacounter identifiers left?");
		return undef;
	}
	my $randn = int(rand($len));	# pick a specific counter name
	my $sctrn = $saclist[$randn];	# at random; then pull its $n
	my $n = substr($sctrn, 1);	# numeric equivalent from the name
	#print "randn=$randn, sctrn=$sctrn, counter n=$n\t";
	my $sctr = $$noid{"$R/${sctrn}/value"};	# and get its value
	$sctr++;				# increment and
	$$noid{"$R/${sctrn}/value"} = $sctr;	# store new current value
	$$noid{"$R/oacounter"}++;		# incr overall counter - some
						# redundancy for sanity's sake

	# deal with an exhausted subcounter
	if ($sctr >= $$noid{"$R/${sctrn}/top"}) {
		my ($c, $modsaclist) = ("", "");
		# remove from active counters list
		foreach $c (@saclist) {		# drop $sctrn, but add it to
			next if ($c eq $sctrn);		# inactive subcounters
			$modsaclist .= "$c ";
		}
		$$noid{"$R/saclist"} = $modsaclist;		# update saclist
		$$noid{"$R/siclist"} .= " $sctrn";		# and siclist
		#print "===> Exhausted counter $sctrn\n";
	}

	# $sctr holds counter value, $n holds ordinal of the counter itself
	my $id = &n2xdig(
			$sctr + ($n * $$noid{"$R/percounter"}),
			$$noid{"$R/mask"});
	dbunlock();
	return $id;
}

# Identifier admin info is stored in three places:
#
#    id\t:/h	hold status: if exists = hold, else no hold
#    id\t:/c	circulation record, if it exists, is
#		    circ_status_history_vector|when|contact(who)|oacounter
#			where circ_status_history_vector is a string of [iqu]
#			and oacounter is current overall counter value, FWIW;
#			circ status goes first to make record easy to update
#    id\t:/p	pepper
#
# Returns a single letter circulation status, which must be one
# of 'i', 'q', or 'u'.  Returns the empty string on error.
#
sub get_circ_svec { my( $noid, $id )=@_;

	my $circ_rec = $$noid{"$id\t$R/c"};
	! defined($circ_rec) and
		return '';

	# Circulation status vector (string of letter codes) is the 1st
	# element, elements being separated by '|'.  We don't care about
	# the other elements for now because we can find everything we
	# need at the beginning of the string (without splitting it).
	# Let errors hit the log file rather than bothering the caller.
	#
	my $circ_svec = (split(/\|/, $circ_rec))[0];

	! defined($circ_svec) || $circ_svec eq "" and
		logmsg($noid, "error: id $id has no circ status vector -- "
			. "circ record is $circ_rec"),
		return '';
	$circ_svec !~ /^([iqu])[iqu]*$/ and
		logmsg($noid, "error: id $id has a circ status vector "
			. "containing letters other than 'i', "
			. "'q', or 'u' -- circ record is $circ_rec"),
		return '';
	return $1;
}

# As a last step of issuing or queuing an identifier, adjust the circulation
# status record.  We place a "hold" if we're both issuing an identifier and
# the minter is for "long" term ids.  If we're issuing, we also purge any
# element bindings that exist; this means that a queued identifier's bindings
# will by default last until it is re-minted.
#
# The caller must know what they're doing because we don't check parameters
# for errors; this routine is not externally visible anyway.  Returns the
# input identifier on success, or undef on error.
#
sub set_circ_rec { my( $noid, $id, $circ_svec, $date, $contact )=@_;

	my $status = 1;
	my $circ_rec = "$circ_svec|$date|$contact|" . $$noid{"$R/oacounter"};

	# yyy do we care what the previous circ record was?  since right now
	#     we just clobber without looking at it

	dblock();

	# Check for and clear any bindings if we're issuing an identifier.
	# We ignore the return value from clear_bindings().
	# Replace or clear admin bindings by hand, including pepper if any.
	# 		yyy pepper not implemented yet
	# If issuing a longterm id, we automatically place a hold on it.
	#
	$circ_svec =~ /^i/ and
		clear_bindings($noid, $id, 0),
		delete($$noid{"$id\t$R/p"}),
		($$noid{"$R/longterm"} and
			$status = hold_set($noid, $id)),
	;
	$$noid{"$id\t$R/c"} = $circ_rec;

	dbunlock();

	# This next logmsg should account for the bulk of the log when
	# longterm identifiers are in effect.
	#
	$$noid{"$R/longterm"} and
		logmsg($noid, "m: $circ_rec"
			. ($status ? "" : " -- hold failed"));

	! $status and			# must be an error in hold_set()
		return(undef);
	return $id;
}

# Get the value of any named internal variable (prefaced by $R)
# given an open database reference.
#
sub getnoid { my( $noid, $varname )=@_;
	return $$noid{"$R/$varname"};
}

#=for deleting
## Simple ancillary counter that we currently use to pair a sequence number
## with each minted identifier.  However, these are independent actions.
## The direction parameter is negative, zero, or positive to count down,
## reset, or count up upon call.  Returns the current counter value.
##
## (yyy should we make it do zero-padding on the left to a fixed width
##      determined by number of digits in the total?)
##
#sub count { my( $noid, $direction )=@_;
#
#	$direction > 0
#		and return ++$$noid{"$R/seqnum"};
#	$direction < 0
#		and return --$$noid{"$R/seqnum"};
#	# $direction must == 0
#	return $$noid{"$R/seqnum"} = 0;
#}
#=cut

# A hold may be placed on an identifier to keep it from being minted/issued.
# Returns 1 on success, 0 on error.  Sets errmsg() in either case.
# 
sub hold { my( $noid, $contact, $on_off, @ids )=@_;

	# yyy what makes sense in this case?
	#! $$noid{"$R/template"} and
	#	addmsg($noid,
	#		"error: holding makes no sense in a bind-only minter."),
	#	return(0);
	! defined($contact) and
		addmsg($noid, "error: contact undefined"),
		return(0);
	! defined($on_off) and
		addmsg($noid, qq@error: hold "set" or "release"?@),
		return(0);
	! @ids and
		addmsg($noid, qq@error: no Id(s) specified@),
		return(0);
	$on_off ne "set" && $on_off ne "release" and
		addmsg($noid, "error: unrecognized hold directive ($on_off)"),
		return(0);

	my $release = $on_off eq "release";
	# yyy what is sensible thing to do if no ids are present?
	my $iderror = "";
	$$noid{"$R/genonly"} and
		($iderror = validate($noid, "-", @ids)) !~ /error:/ and
			$iderror = "";
	$iderror and
		addmsg($noid, "error: hold operation not started -- one or "
			. "more ids did not validate:\n$iderror"),
		return(0);
	my $status;
	my $n = 0;
	for my $id (@ids) {
		if ($release) {		# no hold means key doesn't exist
			logmsg($noid, temper() . " $id: releasing hold")
				if ($$noid{"$R/longterm"});
			dblock();
			$status = hold_release($noid, $id);
		}
		else {			# "hold" means key exists
			logmsg($noid, temper() . " $id: placing hold")
				if ($$noid{"$R/longterm"});
			dblock();
			$status = hold_set($noid, $id);
		}
		dbunlock();
		! $status and
			return(0);
		$n++;			# xxx should report number

		# Incr/Decrement for each id rather than by scalar(@ids);
		# if something goes wrong in the loop, we won't be way off.

		# XXX should we refuse to hold if "long" and issued?
		#     else we cannot use "hold" in the sense of either
		#     "reserved for future use" or "reserved, never issued"
		#
	}
	addmsg($noid, "ok: $n hold" . ($n == 1 ? "" : "s") . " placed");
	return(1);
}

# Returns 1 on success, 0 on error.  Use dblock() before and dbunlock()
# after calling this routine.
# yyy don't care if hold was in effect or not
#
sub hold_set { my( $noid, $id )=@_;

	$$noid{"$id\t$R/h"} = 1;		# value doesn't matter
	$$noid{"$R/held"}++;
	if ($$noid{"$R/total"} != NOLIMIT	# ie, if total is non-zero
			&& $$noid{"$R/held"} > $$noid{"$R/oatop"}) {
		my $m = "error: hold count (" . $$noid{"$R/held"}
			. ") exceeding total possible on id $id";
		addmsg($noid, $m);
		logmsg($noid, $m);
		return(0);
	}
	return(1);
}

# Returns 1 on success, 0 on error.  Use dblock() before and dbunlock()
# after calling this routine.
# yyy don't care if hold was in effect or not
#
sub hold_release { my( $noid, $id )=@_;

	delete($$noid{"$id\t$R/h"});
	$$noid{"$R/held"}--;
	if ($$noid{"$R/held"} < 0) {
		my $m = "error: hold count (" . $$noid{"$R/held"}
			. ") going negative on id $id";
		addmsg($noid, $m);
		logmsg($noid, $m);
		return(0);
	}
	return(1);
}

# Return printable form of an integer after adding commas to separate
# groups of 3 digits.
#
sub human_num { my( $num )=@_;

	$num ||= 0;
	my $numstr = sprintf("%u", $num);
	if ($numstr =~ /^\d\d\d\d+$/) {		# if num is 4 or more digits
		$numstr .= ",";			# prepare to add commas
		while ($numstr =~ s/(\d)(\d\d\d,)/$1,$2/) {};
		chop($numstr);
	}
	return $numstr;
}

# Return $elem: $val or error string.
#
sub id2elemval { my( $cursor, $verbose, $id, $elem )=@_;

	my $first = "$R/idmap/$elem\t";
	my ($key, $value) = ($first, 0);
	my $status = $cursor->c_get($key, $value, DB_SET_RANGE);
	$status and
		return "error: id2elemval: c_get status/errno ($status/$!)";
	$key !~ /^$first/ and
		return "";
	my ($pattern, $newval);
	while (1) {	# exhaustively visit all patterns for this element
		($pattern) = ($key =~ m|$first(.+)|);
		$newval = $id;
		defined($pattern) and
			# yyy kludgy use of unlikely delimiters
			(eval '$newval =~ ' . qq@s$pattern$value@ and
				# replaced, so return
				return ($verbose ? "$elem: " : "") . $newval),
			($@ and
				return "error: id2elemval eval: $@")
			;
		$cursor->c_get($key, $value, DB_NEXT) != 0 and
			return "";
		$key !~ /^$first/ and		# no match and ran out of rules
			return "";
	}
}

# Initialize counters.
#
sub init_counters { my( $noid )=@_;

	# Variables:
	#   oacounter	overall counter's current value (last value minted)
	#   saclist	(sub) active counters list
	#   siclist	(sub) inactive counters list
	#   c$n/value	subcounter name's ($n) value
	#   c$n/top	subcounter name's greatest possible value

	dblock();

	$$noid{"$R/oacounter"} = 0;
	my $total = $$noid{"$R/total"};

	my $maxcounters = 293;		# prime, a little more than 29*10
	#
	# Using a prime under the theory (unverified) that it may help even
	# out distribution across the more significant digits of generated
	# identifiers.  In this way, for example, a method for mapping an
	# identifier to a pathname (eg, fk9tmb35x -> fk/9t/mb/35/x/, which
	# could be a directory holding all files related to the named
	# object), would result in a reasonably balanced filesystem tree
	# -- no subdirectories too unevenly loaded.  That's the hope anyway.

	$$noid{"$R/percounter"} =	# max per counter, last has fewer
		int($total / $maxcounters + 1);		# round up to be > 0

	my $n = 0;
	my $t = $total;
	my $pctr = $$noid{"$R/percounter"};
	my $saclist = "";
	while ($t > 0) {
		$$noid{"$R/c${n}/top"} = ($t >= $pctr ? $pctr : $t);
		$$noid{"$R/c${n}/value"} = 0;		# yyy or 1?
		$saclist .= "c$n ";
		$t -= $pctr;
		$n++;
	}
	$$noid{"$R/saclist"} = $saclist;
	$$noid{"$R/siclist"} = "";
	$n--;

	dbunlock();

	#print "saclist: $$noid{"$R/saclist"}\nfinal top: "
	#	. $$noid{"$R/c${n}/top"} . "\npercounter=$pctr\n";
	#foreach $c ($$saclist) {
	#	print "$c, ";
	#}
	#print "\n";
}

# This routine produces a new identifier by taking a previously recycled
# identifier from a queue (usually, a "used" identifier, but it might
# have been pre-recycled) or by generating a brand new one.
#
# The $contact should be the initials or descriptive string to help
# track who or what was happening at time of minting.
#
# Returns undef on error.
# 
sub mint { my( $noid, $contact, $pepper )=@_;

	! defined($contact) and
		addmsg($noid, "contact undefined"),
		return undef;

	! $$noid{"$R/template"} and
		addmsg($noid, "error: this minter does not generate "
			. "identifiers (it does accept user-defined "
			. "identifier and element bindings)."),
		return undef;
	# Check if the head of the queue is ripe.  See comments under queue()
	# for an explanation of how the queue works.
	#
	my $currdate = temper();		# fyi, 14 digits long
	my $first = "$R/q/";
	my $db = $opendbtab{"bdb/$noid"};
	! (my $cursor = $db->db_cursor()) and
		addmsg($noid, "couldn't create cursor"),
		return undef;

	# The following is not a proper loop.  Normally it should run once,
	# but several cycles may be needed to weed out anomalies with the id
	# at the head of the queue.  If all goes well and we found something
	# to mint from the queue, the last line in the loop exits the routine.
	# If we drop out of the loop, it's because the queue wasn't ripe.
	# 
	my ($id, $status, $key, $qdate, $circ_svec);
	while (1) {
		$key = $first;
		$status = $cursor->c_get($key, $id, DB_SET_RANGE);
		$status and
			addmsg($noid, "mint: c_get status/errno ($status/$!)"),
			return undef;
		# The cursor, key and value are now set at the first item
		# whose key is greater than or equal to $first.  If the
		# queue was empty, there should be no items under "$R/q/".
		#
		($qdate) = ($key =~ m|$R/q/(\d{14})|);
		! defined($qdate) and			# nothing in queue
			# this is our chance -- see queue() comments for why
			($$noid{"$R/fseqnum"} > SEQNUM_MIN and
				$$noid{"$R/fseqnum"} = SEQNUM_MIN),
			last;				# so move on
		# If the date of the earliest item to re-use hasn't arrived
		$currdate < $qdate and
			last;				# move on

		# If we get here, head of queue is ripe.  Remove from queue.
		# Any "next" statement from now on in this loop discards the
		# queue element.
		#
		$db->db_del($key);
		if ($$noid{"$R/queued"}-- <= 0) {
			my $m = "error: queued count (" . $$noid{"$R/queued"}
				. ") going negative on id $id";
			addmsg($noid, $m);
			logmsg($noid, $m);
			return(undef);
		}

		# We perform a few checks first to see if we're actually
		# going to use this identifier.  First, if there's a hold,
		# remove it from the queue and check the queue again.
		#
		exists($$noid{"$id\t$R/h"}) and		# if there's a hold
			$$noid{"$R/longterm"} && logmsg($noid, "warning: id "
				. "$id found in queue with a hold placed on "
				. "it -- removed from queue."),
			next;
		# yyy this means id on "hold" can still have a 'q' circ status?

		$circ_svec = get_circ_svec($noid, $id);

		$circ_svec =~ /^i/ and
			logmsg($noid, "error: id $id appears to have been "
				. "issued while still in the queue -- "
				. "circ record is " . $$noid{"$id\t$R/c"}),
			next
		;
		$circ_svec =~ /^u/ and
			logmsg($noid, "note: id $id, marked as unqueued, is "
				. "now being removed/skipped in the queue -- "
				. "circ record is " . $$noid{"$id\t$R/c"}),
			next
		;
		$circ_svec =~ /^([^q])/ and
			logmsg($noid, "error: id $id found in queue has an "
				. "unknown circ status ($1) -- "
				. "circ record is " . $$noid{"$id\t$R/c"}),
			next
		;

		# Finally, if there's no circulation record, it means that
		# it was queued to get it minted earlier or later than it
		# would normally be minted.  Log if term is "long".
		#
		$circ_svec eq "" and
			($$noid{"$R/longterm"} && logmsg($noid, "note: "
				. "queued id $id coming out of queue on first "
				. "minting (pre-cycled)"))
		;

		# If we get here, our identifier has now passed its tests.
		# Do final identifier signoff and return.
		#
		return(set_circ_rec($noid,
			$id, 'i' . $circ_svec, $currdate, $contact));
	}

	# If we get here, we're not getting an id from the queue.
	# Instead we have to generate one.
	#
	# As above, the following is not a proper loop.  Normally it should
	# run once, but several cycles may be needed to weed out anomalies
	# with the generated id (eg, there's a hold on the id, or it was
	# queued to delay issue).
	# 
	while (1) {

		# Next is the important seeding of random number generator.
		# We need this so that we get the same exact series of
		# pseudo-random numbers, just in case we have to wipe out a
		# generator and start over.  That way, the n-th identifier
		# will be the same, no matter how often we have to start
		# over.  This step has no effect when $generator_type ==
		# "sequential".
		#
		srand($$noid{"$R/oacounter"});

		# The id returned in this next step may have a "+" character
		# that n2xdig() appended to it.  The checkchar() routine
		# will convert it to a check character.
		#
		$id = genid($noid);
		! defined($id)
			and return undef;

		# Prepend NAAN and separator if there is a NAAN.
		#
		$$noid{"$R/firstpart"} and
			$id = $$noid{"$R/firstpart"} . $id;

		# Add check character if called for.
		#
		$$noid{"$R/addcheckchar"} and
			$id = &checkchar($id);

		# There may be a hold on an id, meaning that it is not to
		# be issued (or re-issued).
		#
		exists($$noid{"$id\t$R/h"}) and		# if there's a hold
			next;				# do genid() again

		# It's usual to find no circulation record.  However,
		# there may be a circulation record if the generator term
		# is not "long" and we've wrapped (restarted) the counter,
		# of if it was queued before first minting.  If the term
		# is "long", the generated id automatically gets a hold.
		#
		$circ_svec = get_circ_svec($noid, $id);

		# A little unusual is the case when something has a
		# circulation status of 'q', meaning it has been queued
		# before first issue, presumably to get it minted earlier or
		# later than it would normally be minted; if the id we just
		# generated is marked as being in the queue (clearly not at
		# the head of the queue, or we would have seen it in the
		# previous while loop), we go to generate another id.  If
		# term is "long", log that we skipped this one.
		#
		$circ_svec =~ /^q/ and
			($$noid{"$R/longterm"} && logmsg($noid,
				"note: will not issue genid()'d $id as it's "
				. "status is 'q', circ_rec is "
				. $$noid{"$id\t$R/c"})),
			next
		;

		# If the circulation status is 'i' it means that the id is
		# being re-issued.  This shouldn't happen unless the counter
		# has wrapped around to the beginning.  If term is "long",
		# an id can be re-issued only if (a) its hold was released
		# and (b) it was placed in the queue (thus marked with 'q').
		#
		$circ_svec =~ /^i/ && ($$noid{"$R/longterm"}
					|| ! $$noid{"$R/wrap"}) and
			logmsg($noid, "error: id $id cannot be "
				. "re-issued except by going through the "
				. "queue, circ_rec " . $$noid{"$id\t$R/c"}),
			next
		;
		$circ_svec =~ /^u/ and
			logmsg($noid, "note: generating id $id, currently "
				. "marked as unqueued, circ record is "
				. $$noid{"$id\t$R/c"}),
			next
		;
		$circ_svec =~ /^([^iqu])/ and
			logmsg($noid, "error: id $id has unknown circulation "
				. "status ($1), circ_rec "
				. $$noid{"$id\t$R/c"}),
			next
		;
		#
		# Note that it's OK/normal if $circ_svec was an empty string.

		# If we get here, our identifier has now passed its tests.
		# Do final identifier signoff and return.
		#
		return(set_circ_rec($noid,
			$id, 'i' . $circ_svec, $currdate, $contact));
	}
	# yyy
	# Note that we don't assign any value to the very important key=$id.
	# What should it be bound to?  Let's decide later.

	# yyy
	# Often we want to bind an id initially even if the object or record
	# it identifies is "in progress", as this gives way to begin tracking,
	# eg, back to the person responsible.
	#
}

# Record user (":/:/...") values in admin area.
sub note { my( $noid, $contact, $key, $value )=@_;
	my $db = $opendbtab{"bdb/$noid"};
	dblock();
	my $status = $db->db_put("$R/$R/$key", $value);
	dbunlock();
	$$noid{"$R/longterm"} and
		logmsg($noid, "note: note attempt under $key by $contact"
			. ($status ? "" : " -- note failed"));
	if ($status) {
		addmsg($noid, "db->db_put status/errno ($status/$!)");
		return 0;
	}
	return 1;
}

# Convert a number to an extended digit according to $mask and $generator_type
# and return (without prefix or NAAN).  A $mask character of 'k' gets
# converted to '+' in the returned string; post-processing will eventually
# turn it into a computed check character.
#
sub n2xdig { my( $num, $mask )=@_;
	my $s = '';
	my ($div, $remainder, $c);

	# Confirm well-formedness of $mask before proceeding.
	#
	$mask !~ /^[rsz][de]+k?$/
		and return undef;

	my $varwidth = 0;	# we start in fixed width part of the mask
	my @rmask = reverse(split(//, $mask));	# process each char in reverse
	while ($num != 0 || ! $varwidth) {
		if (! $varwidth) {
			$c = shift @rmask;	# check next mask character,
			! defined($c)
				|| $c =~ /[rs]/	# terminate on r or s even if
				and last;	# $num is not all used up yet
			$c =~ /e/ and
				$div = $alphacount
			or
			$c =~ /d/ and
				$div = $digitcount
			or
			$c =~ /z/ and
				$varwidth = 1	# re-uses last $div value
				and next
			or
			$c =~ /k/ and
				next
			;
#=for later
## why is this slower?  should be faster since it does NOT use regexprs
#			! defined($c) ||	# terminate on r or s even if
#				$c eq 'r' || $c eq 's'
#				and last;	# $num is not all used up yet
#			$c eq 'e' and
#				$div = $alphacount
#			or
#			$c eq 'd' and
#				$div = $digitcount
#			or
#			$c eq 'z' and
#				$varwidth = 1	# re-uses last $div value
#				and next
#			or
#			$c eq 'k' and
#				next
#			;
#=cut
		}
		$remainder = $num % $div;
		$num = int($num / $div);
		$s = $xdig[$remainder] . $s;
	}
	$mask =~ /k$/ and		# if it ends in a check character
		$s .= "+";		# represent it with plus in new id 
	return $s;
}

# yyy templates should probably have names, eg, jk##.. could be jk4
#	or jk22, as in "./noid testdb/jk4 <command> ... "

# Reads template looking for errors and returns the total number of
# identifiers that it is capable of generating, using NOLIMIT to mean
# indefinite (unbounded).  Returns 0 on error.  Variables $prefix,
# $mask, and $generator_type are output parameters.
#
# $message will always be set; 0 return with error, 1 return with synonym

#
sub parse_template { my( $template, $prefix, $mask, $gen_type, $message )=@_;

	my $dirname;
	my $msg = \$_[4];	# so we can modify $message argument easily
	$$msg = "";

	# Strip final spaces and slashes.  If there's a pathname,
	# save directory and final component separately.
	#
	$template ||= "";
	$template =~ s|[/\s]+$||;		# strip final spaces or slashes
	($dirname, $template) = $template =~ m|^(.*/)?([^/]+)$|;
	$dirname ||= "";			# make sure $dirname is defined

	! $template || $template eq "-" and
		$$msg = "parse_template: no minting possible.",
		$_[1] = $_[2] = $_[3] = "",
		return NOLIMIT;
	$template !~ /^([^\.]*)\.(\w+)/ and
		$$msg = "parse_template: no template mask - "
			. "can't generate identifiers.",
		return 0;
	($prefix, $mask) = ($1 || "", $2);

	$mask !~ /^[rsz]/ and
		$$msg = "parse_template: mask must begin with one of "
			. "the letters\n'r' (random), 's' (sequential), "
			. "or 'z' (sequential unlimited).",
		return 0;

	$mask !~ /^.[^k]+k?$/ and
		$$msg = "parse_template: exactly one check character "
			. "(k) is allowed, and it may\nonly appear at the "
			. "end of a string of one or more mask characters.",
		return 0;

	$mask !~ /^.[de]+k?$/ and
		$$msg = "parse_template: a mask may contain only the "
			. "letters 'd' or 'e'.",
		return 0;

	# Check prefix for errors.
	#
	my $c;
	my $has_cc = ($mask =~ /k$/);
	for $c (split //, $prefix) {
		if ($has_cc && $c ne '/' && ! exists($ordxdig{$c})) {
			$$msg = "parse_template: with a check character "
				. "at the end, a mask may contain only "
				. qq@characters from "$legalstring".@;
			return 0;
		}
	}

	# If we get here, the mask is well-formed.  Now try to come up with
	# a short synonym for the template; it should start with the
	# template's prefix and then an integer representing the number of
	# letters in identifiers generated by the template.  For example,
	# a template of "ft.rddeek" would be "ft5".
	#
	my $masklen = length($mask) - 1;	# subtract one for [rsz]
	$$msg = $prefix . $masklen;
	$mask =~ /^z/ and			# "+" indicates length can grow
		$$msg .= "+";

	# r means random;
	# s means sequential, limited;
	# z means sequential, no limit, and repeat most significant mask
	#   char as needed;

	my $total = 1;
	for $c (split //, $mask) {
		# Mask chars it could be are: d e k
		$c =~ /e/ and
			$total *= $alphacount
		or
		$c =~ /d/ and
			$total *= $digitcount
		or
		$c =~ /[krsz]/ and
			next
		;
	}

	$_[1] = $prefix;
	$_[2] = $mask;
	$_[3] = $gen_type = ($mask =~ /^r/ ? "random" : "sequential");
	# $_[4] was set to the synonym already
	return ($mask =~ /^z/ ? NOLIMIT : $total);
}

# An identifier may be queued to be issued/minted.  Usually this is used
# to recycle a previously issued identifier, but it may also be used to
# delay or advance the birth of an identifier that would normally be
# issued in its own good time.  The $when argument may be "first", "lvf",
# "delete", or a number and a letter designating units of seconds ('s',
# the default) or days ('d') which is a delay added to the current time;
# a $when of "now" means use the current time with no delay.

# The queue is composed of keys of the form $R/q/$qdate/$seqnum/$paddedid,
# with the correponding values being the actual queued identifiers.  The
# Btree allows us to step sequentially through the queue in an ordering
# that is a side-effect of our key structure.  Left-to-right, it is
#
#	:/q/		$R/q/, 4 characters wide
#	$qdate		14 digits wide, or 14 zeroes if "first" or "lvf"
#	$seqnum		6 digits wide, or 000000 if "lvf"
#	$paddedid	id "value", zero-padded on left, for "lvf"
# 
# The $seqnum is there to help ensure queue order for up to a million queue
# requests in a second (the granularity of our clock).  [ yyy $seqnum would
# probably be obviated if we were using DB_DUP, but there's much conversion
# involved with that ]
#
# We base our $seqnum (min is 1) on one of two stored sources:  "fseqnum"
# for queue "first" requests or "gseqnum" for queue with a real time stamp
# ("now" or delayed).  To implement queue "first", we use an artificial
# time stamp of all zeroes, just like for "lvf"; to keep all "lvf" sorted
# before "first" requests, we reset fseqnum and gseqnum to 1 (not zero).
# We reset gseqnum whenever we use it at a different time from last time
# since sort order will be guaranteed by different values of $qdate.  We
# don't have that guarantee with the all-zeroes time stamp and fseqnum,
# so we put off resetting fseqnum until it is over 500,000 and the queue
# is empty, so we do then when checking the queue in mint().
#
# This key structure should ensure that the queue is sorted first by date.
# As long as fewer than a million queue requests come in within a second,
# we can make sure queue ordering is fifo.  To support "lvf" (lowest value
# first) recycling, the $date and $seqnum fields are all zero, so the
# ordering is determined entirely by the numeric "value" of identifier
# (really only makes sense for a sequential generator); to achieve the
# numeric sorting in the lexical Btree ordering, we strip off any prefix,
# right-justify the identifier, and zero-pad on the left to create a number
# that is 16 digits wider than the Template mask [yyy kludge that doesn't
# take any overflow into account, or bigints for that matter].
# 
# Returns the array of corresponding strings (errors and "id:" strings)
# or an empty array on error.
#
sub queue { my( $noid, $contact, $when, @ids )=@_;

	! $$noid{"$R/template"} and
		addmsg($noid,
			"error: queuing makes no sense in a bind-only minter."),
		return(());
	! defined($contact) and
		addmsg($noid, "error: contact undefined"),
		return(());
	! defined($when) || $when !~ /\S/ and
		addmsg($noid, "error: queue when? (eg, first, lvf, 30d, now)"),
		return(());
	# yyy what is sensible thing to do if no ids are present?
	scalar(@ids) < 1 and
		addmsg($noid, "error: must specify at least one id to queue."),
		return(());
	my ($seqnum, $delete) = (0, 0, 0);
	my ($fixsqn, $qdate);			# purposely undefined

	# You can express a delay in days (d) or seconds (s, default).
	#
	if ($when =~ /^(\d+)([ds]?)$/) {	# current time plus a delay
		# The number of seconds in one day is 86400.
		my $multiplier = (defined($2) && $2 eq "d" ? 86400 : 1);
		$qdate = temper(time() + $1 * $multiplier);
	}
	elsif ($when eq "now") {	# a synonym for current time
		$qdate = temper(time());
	}
	elsif ($when eq "first") {
		# Lowest value first (lvf) requires $qdate of all zeroes.
		# To achieve "first" semantics, we use a $qdate of all
		# zeroes (default above), which means this key will be
		# selected even earlier than a key that became ripe in the
		# queue 85 days ago but wasn't selected because no one
		# minted anything in the last 85 days.
		#
		$seqnum = $$noid{"$R/fseqnum"};
		#
		# NOTE: fseqnum is reset only when queue is empty; see mint().
		# If queue never empties fseqnum will simply keep growing,
		# so we effectively truncate on the left to 6 digits with mod
		# arithmetic when we convert it to $fixsqn via sprintf().
	}
	elsif ($when eq "delete") {
		$delete = 1;
	}
	elsif ($when ne "lvf") {
		addmsg($noid, "error: unrecognized queue time: $when");
		return(());
	}

	defined($qdate) and		# current time plus optional delay
		($qdate > $$noid{"$R/gseqnum_date"} and
			$seqnum = $$noid{"$R/gseqnum"} = SEQNUM_MIN,
			$$noid{"$R/gseqnum_date"} = $qdate,
		1 or
			$seqnum = $$noid{"$R/gseqnum"}),
	1 or
		$qdate = "00000000000000",	# this needs to be 14 zeroes
	1;

	my $iderror = "";
	$$noid{"$R/genonly"} and
		($iderror = validate($noid, "-", @ids)) !~ /error:/ and
			$iderror = "";
	$iderror and
		addmsg($noid, "error: queue operation not started -- one or "
			. "more ids did not validate:\n$iderror"),
		return(());
	my $firstpart = $$noid{"$R/firstpart"};
	my $padwidth = $$noid{"$R/padwidth"};
	my $currdate = temper();
	my (@retvals, $m, $idval, $paddedid, $circ_svec);
	for my $id (@ids) {
		exists($$noid{"$id\t$R/h"}) and		# if there's a hold
			$m = qq@error: a hold has been set for "$id" and @
				. "must be released before the identifier can "
				. "be queued for minting.",
			logmsg($noid, $m),
			push(@retvals, $m),
			next
		;

		# If there's no circulation record, it means that it was
		# queued to get it minted earlier or later than it would
		# normally be minted.  Log if term is "long".
		#
		$circ_svec = get_circ_svec($noid, $id);

		$circ_svec =~ /^q/ && ! $delete and
			$m = "error: id $id cannot be queued since "
				. "it appears to be in the queue already -- "
				. "circ record is " . $$noid{"$id\t$R/c"},
			logmsg($noid, $m),
			push(@retvals, $m),
			next
		;
		$circ_svec =~ /^u/ && $delete and
			$m = "error: id $id has been unqueued already -- "
				. "circ record is " . $$noid{"$id\t$R/c"},
			logmsg($noid, $m),
			push(@retvals, $m),
			next
		;
		$circ_svec !~ /^q/ && $delete and
			$m = "error: id $id cannot be unqueued since its circ "
				. "record does not indicate its being queued, "
				. "circ record is " . $$noid{"$id\t$R/c"},
			logmsg($noid, $m),
			push(@retvals, $m),
			next
		;
		# If we get here and we're deleting, circ_svec must be 'q'.

		$circ_svec eq "" and
			($$noid{"$R/longterm"} && logmsg($noid, "note: "
				. "id $id being queued before first "
				. "minting (to be pre-cycled)")),
		1 or
		$circ_svec =~ /^i/ and
			($$noid{"$R/longterm"} && logmsg($noid, "note: "
				. "longterm id $id being queued for re-issue"))
		;

		# yyy ignore return OK?
		set_circ_rec($noid, $id,
				($delete ? 'u' : 'q') . $circ_svec,
				$currdate, $contact);

		($idval = $id) =~ s/^$firstpart//;
		$paddedid = sprintf("%0$padwidth" . "s", $idval);
		$fixsqn = sprintf("%06d", $seqnum % SEQNUM_MAX);

		dblock();

		$$noid{"$R/queued"}++;
		if ($$noid{"$R/total"} != NOLIMIT	# if total is non-zero
				&& $$noid{"$R/queued"} > $$noid{"$R/oatop"}) {

			dbunlock();

			$m = "error: queue count (" . $$noid{"$R/queued"}
				. ") exceeding total possible on id $id.  "
				. "Queue operation aborted.";
			logmsg($noid, $m);
			push @retvals, $m;
			last;
		}
		$$noid{"$R/q/$qdate/$fixsqn/$paddedid"} = $id;

		dbunlock();

		$$noid{"$R/longterm"} and
			logmsg($noid, "id: "
				. $$noid{"$R/q/$qdate/$fixsqn/$paddedid"}
				. " added to queue under "
				. "$R/q/$qdate/$seqnum/$paddedid");
		push @retvals, "id: $id";
		$seqnum and		# it's zero for "lvf" and "delete"
			$seqnum++;
	}
	dblock();
	$when eq "first" and
		$$noid{"$R/fseqnum"} = $seqnum,
	1 or
	$qdate > 0 and
		$$noid{"$R/gseqnum"} = $seqnum,
	1;
	dbunlock();
	return(@retvals);
}

# Generate a sample id for testing purposes.
sub sample{ my( $noid, $num )=@_;

	my $upper;
	! defined($num) and
		$upper = $$noid{"$R/total"},
		($upper == NOLIMIT and $upper = 100000),
		$num = int(rand($upper));
	my $mask = $$noid{"$R/mask"};
	my $firstpart = $$noid{"$R/firstpart"};
	my $func = ($$noid{"$R/addcheckchar"} ? \&checkchar : \&echo);
	return &$func($firstpart . n2xdig($num, $mask));
}

sub scope { my( $noid )=@_;

	! $$noid{"$R/template"} and
		print("This minter does not generate identifiers, but it\n"
			. "does accept user-defined identifier and element "
			. "bindings.\n");
	my $total = $$noid{"$R/total"};
	my $totalstr = human_num($total);
	my $naan = $$noid{"$R/naan"} || "";
	$naan and
		$naan .= "/";

	my ($prefix, $mask, $gen_type) =
	  ($$noid{"$R/prefix"}, $$noid{"$R/mask"}, $$noid{"$R/generator_type"});

	print "Template ", $$noid{"$R/template"}, " will yield ",
		($total < 0 ? "an unbounded number of" : $totalstr),
		" $gen_type unique ids\n";
	my $tminus1 = ($total < 0 ? 987654321 : $total - 1);

	# See if we need to compute a check character.
	my $func = ($$noid{"$R/addcheckchar"} ? \&checkchar : \&echo);
	print
	"in the range "	. &$func($naan . &n2xdig( 0, $mask)) .
	", "	 	. &$func($naan . &n2xdig( 1, $mask)) .
	", "	 	. &$func($naan . &n2xdig( 2, $mask));
	28 < $total - 1 and print
	", ..., "	. &$func($naan . &n2xdig(28, $mask));
	29 < $total - 1 and print
	", "	 	. &$func($naan . &n2xdig(29, $mask));
	print
	", ... up to "
		  	. &$func($naan . &n2xdig($tminus1, $mask))
	. ($total < 0 ? " and beyond.\n" : ".\n")
	;
	$mask !~ /^r/ and
		return 1;
	print "A sampling of random values (may already be in use): ";
	my $i = 5;
	print sample($noid) . " "
		while ($i-- > 0);
	print "\n";
	return 1;
}

# Return local date/time stamp in TEMPER format.  Use supplied time (in seconds)
# if any, or the current time.
#
sub temper { my( $time )=@_;

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdat)
		= localtime(defined($time) ? $time : time());
	$year += 1900;		# add the missing the century
	$mon++;			# zero-based, so increment
	return sprintf("%04.4s%02.2s%02.2s%02.2s%02.2s%02.2s",
			$year, $mon, $mday, $hour, $min, $sec);
}

# Check that identifier matches a given template, where "-" means the
# default template for this generator.  This is a complete check of all
# characteristics _except_ whether the identifier is stored in the
# database.
#
# Returns an array of strings that are messages corresponding to any ids
# that were passed in.  Error strings # that pertain to identifiers
# begin with "iderr: ".
#
sub validate { my( $noid, $template, @ids )=@_;

	my ($first, $prefix, $mask, $gen_type, $msg);
	my @retvals;

	! @ids and
		addmsg($noid, "error: must specify a template and at least "
			. "one identifier."),
		return(());
	! defined($template) and
		# If $noid is undefined, the caller looks in errmsg(undef).
		addmsg($noid, "error: no template given to validate against."),
		return(());

	if ($template eq "-") {
		($prefix, $mask) = ($$noid{"$R/prefix"}, $$noid{"$R/mask"});
		# push(@retvals, "template: " . $$noid{"$R/template"});
		if (! $$noid{"$R/template"}) {	# do blanket validation
			my @nonulls = grep(s/^(.)/id: $1/, @ids);
			! @nonulls and
				return(());
			push(@retvals, @nonulls);
			return(@retvals);
		}
	}
	elsif (! parse_template($template, $prefix, $mask, $gen_type, $msg)) {
		addmsg($noid, "error: template $template bad: $msg");
		return(());
	}

	my ($id, @maskchars, $c, $m, $varpart);
	my $should_have_checkchar = (($m = $mask) =~ s/k$//);
	my $naan = $$noid{"$R/naan"};
	ID: for $id (@ids) {
		! defined($id) || $id =~ /^\s*$/ and
			push(@retvals,
				"iderr: can't validate an empty identifier"),
			next;

		# Automatically reject ids starting with "$R/", unless it's an
		# "idmap", in which case automatically validate.  For an idmap,
		# the $id should be of the form $R/idmap/ElementName, with
		# element, Idpattern, and value, ReplacementPattern.
		#
		$id =~ m|^$R/| and
			push(@retvals, ($id =~ m|^$R/idmap/.+|
				? "id: $id"
				: "iderr: identifiers must not start"
					. qq@ with "$R/".@)),
			next;

		$first = $naan;				# ... if any
		$first and
			$first .= "/";
		$first .= $prefix;			# ... if any
		($varpart = $id) !~ s/^$first// and
#yyy		    ($varpart = $id) !~ s/^$prefix// and
			push(@retvals, "iderr: $id should begin with $first."),
			next;
		# yyy this checkchar algorithm will need an arg when we
		#     expand into other alphabets
		$should_have_checkchar && ! checkchar($id) and
			push(@retvals, "iderr: $id has a check character error"),
			next;
		## xxx fix so that a length problem is reported before (or
		# in addition to) a check char problem

		# yyy needed?
		#length($first) + length($mask) - 1 != length($id)
		#	and push(@retvals,
		#		"error: $id has should have length "
		#		. (length($first) + length($mask) - 1)
		#	and next;

		# Maskchar-by-Idchar checking.
		#
		@maskchars = split(//, $mask);
		shift @maskchars;		# toss 'r', 's', or 'z'
		for $c (split(//, $varpart)) {
			! defined($m = shift @maskchars) and
				push(@retvals, "iderr: $id longer than "
					. "specified template ($template)"),
				next ID;
			$m =~ /e/ && $legalstring !~ /$c/ and
				push(@retvals, "iderr: $id char '$c' conflicts"
					. " with template ($template)"
					. " char '$m' (extended digit)"),
				next ID
			or
			$m =~ /d/ && '0123456789' !~ /$c/ and
				push(@retvals, "iderr: $id char '$c' conflicts"
					. " with template ($template)"
					. " char '$m' (digit)"),
				next ID
			;		# or $m =~ /k/, in which case skip
		}
		defined($m = shift @maskchars) and
			push(@retvals, "iderr: $id shorter "
				. "than specified template ($template)"),
			next ID;

		# If we get here, the identifier checks out.
		push(@retvals, "id: $id");
	}
	return(@retvals);
}

1;

__END__

=head1 NAME

Noid - routines to mint and manage nice opaque identifiers

=head1 SYNOPSIS

 use Noid;			    # import routines into a Perl script

 $dbreport = Noid::dbcreate(	    # create minter database & printable
 		$dbdir, $contact,   # report on its properties; $contact
		$template, $term,   # is string identifying the operator
		$naan, $naa, 	    # (authentication information); the
		$subnaa );          # report is printable

 $noid = Noid::dbopen( $dbname, $flags );    # open a minter, optionally
 	$flags = 0 | DB_RDONLY;		     # in read only mode

 Noid::mint( $noid, $contact, $pepper );     # generate an identifier

 Noid::dbclose( $noid );		     # close minter when done

 Noid::checkchar( $id );      # if id ends in +, replace with new check
 			      # char and return full id, else return id
			      # if current check char valid, else return
			      # 'undef'

 Noid::validate( $noid,	      # check that ids conform to template ("-"
 		$template,    # means use minter's template); returns
		@ids );	      # array of corresponding strings, errors
			      # beginning with "iderr:"

 $n = Noid::bind( $noid, $contact,	# bind data to identifier; set
		$validate, $how,	# $validate to 0 if id. doesn't
		$id, $elem, $value );	# need to conform to a template

 Noid::note( $noid, $contact, $key, $value );	# add an internal note

 Noid::fetch( $noid, $verbose,		# fetch bound data; set $verbose
 		$id, @elems );		# to 1 to return labels

 print Noid::dbinfo( $noid,		# get minter information; level
 		$level );		# brief (default), full, or dump
 Noid::getnoid( $noid, $varname );	# get arbitrary named internal
 					# variable

 Noid::hold( $noid, $contact,		# place or release hold; return
 		$on_off, @ids );	# 1 on success, 0 on error
 Noid::hold_set( $noid, $id );
 Noid::hold_release( $noid, $id );

 Noid::parse_template( $template,  # read template for errors, returning
 		$prefix, $mask,	   # namespace size (NOLIMIT=unbounded)
		$gen_type,	   # or 0 on error; $message, $gen_type,
		$message );	   # $prefix, & $mask are output params

 Noid::queue( $noid, $contact,	   # return strings for queue attempts
 		$when, @ids );	   # (failures start "error:")

 Noid::n2xdig( $num, $mask );	   # show identifier matching ord. $num

 Noid::sample( $noid, $num );	   # show random ident. less than $num

 Noid::scope( $noid );		   # show range of ids inside the minter

 print Noid::errmsg( $noid, $reset );   # print message from failed call
 	$reset = undef | 1;	   # use 1 to clear error message buffer

 Noid::addmsg( $noid, $message );  # add message to error message buffer

 Noid::logmsg( $noid, $message );  # write message to minter log

=head1 DESCRIPTION

This is very brief documentation for the B<Noid> Perl module subroutines.
For this early version of the software, it is indispensable to have the
documentation for the B<noid> utility (the primary user of these routines)
at hand.  Typically that can be viewed with

	perldoc noid

while the present document can be viewed with

	perldoc Noid

The B<noid> utility creates minters (identifier generators) and accepts
commands that operate them.  Once created, a minter can be used to produce
persistent, globally unique names for documents, databases, images,
vocabulary terms, etc.  Properly managed, these identifiers can be used as
long term durable information object references within naming schemes such
as ARK, PURL, URN, DOI, and LSID.  At the same time, alternative minters
can be set up to produce short-lived names for transaction identifiers,
compact web server session keys (cf. UUIDs), and other ephemera.

In general, a B<noid> minter efficiently generates, tracks, and binds
unique identifiers, which are produced without replacement in random or
sequential order, and with or without a check character that can be used
for detecting transcription errors.  A minter can bind identifiers to
arbitrary element names and element values that are either stored or
produced upon retrieval from rule-based transformations of requested
identifiers; the latter has application in identifier resolution.  Noid
minters are very fast, scalable, easy to create and tear down, and have a
relatively small footprint.  They use BerkeleyDB as the underlying database.

Identifiers generated by a B<noid> minter are also known as "noids" (nice
opaque identifiers).  While a minter can record and bind any identifiers 
that you bring to its attention, often it is used to generate, bringing
to your attention, identifier strings that carry no widely recognizable
meaning.  This semantic opaqueness reduces their vulnerability to era-
and language-specific change, and helps persistence by making for
identifiers that can age and travel well.

=begin later

=head1 HISTORY

Since 2002 Sep 3:
- seeded (using srand) the generator so that the same exact sequence of
    identifiers would be minted if we started over from scratch (limited
    disaster recovery assistance)
- changed module name from PDB.pm to Noid.pm
- changed variable names from pdb... to noid...
- began adding support for sequentially generated numbers as part of
    generalization step (eg, for use as session ids)
- added version number
- added copyright to code
- slightly improved comments and error messages
- added extra internal (admin) symbols "$R/..." (":/..."),
    eg, "template" broken into "prefix", "mask", and "generator_type"
- changed the number of counters from 300 to 293 (a prime) on the
    theory that it will improve the impression of randomness
- added "scope" routine to print out sample identifiers upon db creation

Since 2004 Jan 18:
- changed var names from b -> noid throughout
- create /tmp/errs file public write
- add subnaa as arg to dbopen
- changed $R/authority to $R/subnaa
- added note feature
- added dbinfo
- added (to noid) short calling form: noi (plus NOID env var)
- changed dbcreate to take term, naan, and naa
- added DB_DUP flag to enable duplicate keys

Plus many, many more changes...

=end

=head1 BUGS

Probably.  Please report to jak at ucop dot edu.

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2006 UC Regents.  BSD-type open source license.

=head1 SEE ALSO

L<dbopen(3)>, L<perl(1)>, L<http://www.cdlib.org/inside/diglib/ark/>

=head1 AUTHOR

John A. Kunze

=cut
