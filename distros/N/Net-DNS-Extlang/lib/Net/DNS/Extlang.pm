package Net::DNS::Extlang;

our $VERSION = '0.2';

=head1 NAME

Net::DNS::Extlang - DNS extension language


=head1 SYNOPSIS

    use Net::DNS::Extlang;

    $extobj = new Net::DNS::Extlang(
	domain   => 'arpa',
	file     => '/etc/dnsext.txt',
	lang     => 'en',
	resolver => $resobj
    )


=head1 DESCRIPTION

The Net::DNS::Extlang module reads and stores RR descriptions from files
or the DNS.  If file is provided, it reads descriptions from that file,
otherwise it looks in <name>.rrname.<domain> and <val>.rrtype.<domain>
for descriptions in the desired language.

Provide a resolver if you want other than the default resolver settings.

=cut


use strict;
use warnings;
use integer;
use Carp;


=head1 METHODS

=head2 new
					
    $extobj = new Net::DNS::Extlang(
	domain   => 'arpa',
	file     => '/etc/dnsext.txt',
	lang     => 'en',
	resolver => new Net::DNS::Resolver()
    )

Create an object corresponding to a set of extension language entries
in a file or the DNS.  Provide either a file or a domain argument.
If you provide a domain, the lang and resolver are optional.

In addition to using its methods, Net::DNS::Extlang can be accessed
by Net::DNS to create rrtype packages automatically as required.

=cut

sub new {
	my $class = shift;

	my %args = (
		lang => 'en',	domain => 'services.net.',		# defaults
		@_
		);

	my $self = bless {
		domain	 => $args{domain},
		file	 => $args{file},
		lang	 => $args{lang},
		resolver => $args{resolver},
		rrnames	 => {},					# RRs by name
		rrnums	 => {},					# RRs by number
		}, $class;

	$self->_xlreadfile( $args{file} ) if $args{file};

	return $self;
}


=head2 domain, file, lang, resolver

Access method which returns extlang configuration attribute.

=cut

sub domain { shift->{domain} }
sub file { shift->{file} }
sub lang { shift->{lang} }
sub resolver { shift->{resolver} }


# read a file, set the text parts of $self->rrnames and $self->rrnums

sub _xlreadfile {
	my ($self, $file) = @_;

	open(my $rrfile, "<", $file) or croak "Extlang file '$file' $!";
	my @xllist = ();

	while(<$rrfile>) {
		chomp;
		next if m/^\s*($|#)/;	# comments or blank line
		if( m/^\s/ ) {
			push @xllist, join ' ', split;
			next;
		}
		# must be a new one, store current one
		$self->xlstorerecord(@xllist) if scalar @xllist;

		@xllist = ($_);
	}
	$self->xlstorerecord(@xllist) if scalar @xllist;

	close $rrfile;
}


=head2 xlstorerecord

    $rrr = $ext->xlstorerecord( $identifier, @field )

Store a record with rrname/number and list of fields.

=cut

# only do rudimentary syntax checking here

# match head record, $1 = name, $2 = number, $3 = description
# ignores I/A third subfield
my $headpattern = qr{^ ([A-Z][-A-Z0-9]*) : (\d+)\S* \s* (.*) $}ix;


# match a field, $1 = type, $2 = quals, $3 - name, $4 = comment
my $fieldpattern = qr{^(I[124]|AAAA|AA|B32|B64|T6|X[P68]|[ANRSTXZ])
	(?:\[( (?: [CALMX]|[-A-Z0-9]+=\d+\W*)+ )\])?
	:? ([a-z][-a-z0-9]*)? \s*(.*) $}ix;


sub xlstorerecord {
	my ($self, $rr, @fieldlist) = @_;

	croak "no rr record" if !$rr;

	my ($rrname, $rrnum, $rrcomment ) = $rr =~ m{$headpattern}o;
	croak "invalid rr record $rr" if !$rrname or !$rrnum;

	# parse each field descriptor into a hash via $fieldpattern
	my @fieldstructs;
	foreach (@fieldlist) {
		m{$fieldpattern}o || croak "invalid field in $rrname: $_";
		my $q = $2 || '';
		push @fieldstructs, {
			type	=> uc($1),
			quals	=> join(',', sort split /,/, uc $q),	# alphabetize quals
			name	=> $3,
			comment	=> $4
		};
	}

	# make up an rr thing
	my $rrr = {
		mnemon => $rrname,
		number => 0 + $rrnum,
		comment => $rrcomment,
		fields => [@fieldstructs]
	};

	# stash it by name and number
	$self->{rrnames}->{$rrname} = $rrr;
	$self->{rrnums}->{$rrnum} = $rrr;
}

sub _xlstorerecord { &xlstorerecord }	## now a public method (used in RRTYPEgen and Net::DNS)


=head2 getrr

    $rrinfo = $ext->getrr(nameornumber)

Retrieve the rr description by number (if the argument is all digits)
or name (otherwise.)  $rrinfo is a reference to a hash with entries for
mnemon, number, comment, and fields: the lines in the description
stanza.  Each field is a hash with entries type (field type),
quals (optional qualifiers), name (optional field name), and comment.

Descriptions from a file are all loaded by new(), from the DNS
are fetched as needed.
If there's no description for that name or number it returns undef.

=cut

sub getrr {
	my ($self, $rrn) = @_;
	my $name;

	croak("Need rrname or rrtype in getrr") unless $rrn;
	
	if($rrn =~ m{^\d+$}) {		# look up by number
		return $self->{rrnums}->{$rrn} if $self->{rrnums}->{$rrn};
		return undef if defined $self->{file};		# not in the file
		$name = "$rrn.rrtype.$self->{domain}";		# try DNS

	} else {			# look up by name
		$rrn = uc $rrn;		# RRTYPES are UPPER CASE
		return $self->{rrnames}->{$rrn} if $self->{rrnames}->{$rrn};
		return undef if defined $self->{file};		# not in the file
		$name = "$rrn.rrname.$self->{domain}";		# try DNS
	}

	# look it up
	my $res = $self->{resolver} ||= do {
		require Net::DNS::Resolver;
		new Net::DNS::Resolver();
	};

	my $response = $res->query($name, 'TXT') || return;	# undef if nothing there

	foreach my $rr ($response->answer) {
		next if $rr->type ne 'TXT';

		my @txt = $rr->txtdata;

		next unless $txt[0] eq "RRTYPE=1";
			
		my ($trname, $trno) = $txt[1] =~ m{$headpattern}o;
		croak "invalid description $txt[1]" if !$trname or !$trno;

		# make sure it's the right rr
		croak "wrong rrtype $rrn $txt[1]" unless $txt[1] =~ m/$rrn/;
		
		shift @txt;		# get rid of desc tag
		return $self->xlstorerecord(@txt);	# will croak if bad syntax
	}
}

=head2 compile / compilerr

    $code = $ext->compile(nameornumber)
    $code = $ext->compilerr($rrr)

Compile the rr description into Net::DNS::RR:<name> and return
the perl code, suitable to pass to eval().
nameornumber is looked up, $rrr is an rr description such as getrr()
returns.

If there's no description it returns null.

Compiled methods include:

_decode_rdata, _encode_rdata, _format_rdata, _parse_rdata, _defaults

get/set for each field named to match the field, or fieldN if the field
has no name or a duplicate name.
If field names match built in names or perl keywords, the get/set
method name is prefixed with 'f'.

=cut


# $rrr is a rrinfo hash, %pats are patterns to select from based on the
# type and quals where it looks for type[quals], then type, then
# "default". When checking for quals they are alphabetized so a query
# for N[C,A] will match N[A,C]
#my $CDEBUG = 0;

sub _cchunk($@) {
	my ($rrr, %pats) = @_;
	my $type = $rrr->{type};
	my $qual = $rrr->{quals};

	if($qual) {
		my $k = $type . "[$qual]";
#		print "check $k\n" if $CDEBUG;
		return $pats{$k} if exists $pats{$k};
	}

#	print "check $type\n" if $CDEBUG;
	return exists($pats{$type}) ? $pats{$type} : $pats{"default"};
}


# substitite  #WORD# in the string with $p{WORD} in the list
# csub($string, 'FOO' => "foo", 'BAR' => "bahr", ... )
sub _csub($@) {
	my ($str, %subs) = @_;

	for ($str) {
		s/#([A-Z]+)#/$subs{$1}/eg;
		return $_;
	}
}


# names that conflict with RR methods
my %dirtywords = map { ($_, 1) } qw( new decode encode canonical print string plain token name owner next last
type class ttl dump rdatastr rdata rdstring rdlength destroy autoload );

sub compile {
	my ($self, $rrn) = @_;

	croak("Need rrname or rrtype in compile") unless $rrn;
	
	my $rrr = $self->getrr($rrn);
	$self->compilerr($rrr) if $rrr;
}

sub compilerr {
	my ($self, $rrr) = @_;

	my $rrname = uc $rrr->{mnemon};
	my $rrnum = $rrr->{number};
	my $rrcomment = $rrr->{comment} || '';
	my $rrfields = $rrr->{fields};
	
	my ($usedomainname,		# if there's an N field
	    $usetext,			# if there's an S field
	    $usemailbox,		# if theres an N[A] field
	    $usebase64,			# if there's a B32 or B64 field
	    $usetime,			# if there's a time field
	    $userrtype,			# if there's a rrtype field
	    $usensechelp,		# if there's a rrtype list field or nsec3 base32
	    %fields,			# field names in use
	    $fieldno,			# to generate fieldN names
	    $decode,			# contents of decode routine
	    $encode,			# contents of encode routine
	    $format,			# contents of format routine
	    $parse,			# contents of parse routine
	    $defaults,			# contents of defaults routine
	    $fieldfns			# functions get/set fields
	   );

	foreach my $f (@$rrfields) {
		$fieldno++;
		my ($type, $quals, $name) = ($f->{type}, $f->{quals}, lc $f->{name});

		carp("Unimplemented field type Z[$quals] in $rrname") && return if $type eq "Z";

		# censor dirty words
		$name = $f->{name} = "f$name" if $dirtywords{$name};

		# make a name if there isn't one yet
		$f->{name} = $name = "field$fieldno" if !$name or exists $fields{$name};

		$fields{$name} = $fieldno;

		if($type eq 'N') {
			$usedomainname = 1;
			$usemailbox = 1 if $quals =~ m{A};
		} elsif($type eq 'S') {
			$usetext = 1;
		} elsif($type eq "B64") {
			$usebase64 = 1;
		} elsif($type eq "B32") {
			$usensechelp = 1;
		} elsif($type eq "T" or $type eq "T6") {
			$usetime = 1;
		} elsif($type eq "R" ) {
			if( $quals eq "L" ) {
				$usensechelp = 1;
			} else {
				$userrtype = 1;
			}
		}
	}
	# now get them in order, in a perhaps overcomplex way
	my @fields = map { $_->{name} } @$rrfields;
	
	#print "fields are ",join(",", @fields), "\n";
	
	# generate per-field functions
	$fieldfns = _perfield($rrfields);
	
	# default function
	$defaults = _fielddefault($rrfields);
	$decode = _fielddecode($rrfields);
	$encode = _fieldencode($rrfields);
	$parse = _fieldparse($rrfields);
	$format = _fieldformat($rrfields);

	# other modules to include, depending on the type
	my $uses = "";
	$uses = "use Net::DNS::DomainName;\n" if $usedomainname;
	$uses .= "use Net::DNS::Mailbox;\n" if $usemailbox;
	$uses .= "use Net::DNS::Text;\n" if $usetext;
	$uses .= "use MIME::Base64;\n" if $usebase64;
	$uses .= "use Net::DNS::Extlang::Time qw(_encodetime _string2time);\n" if $usetime;
	$uses .= "use Net::DNS::Parameters qw(typebyname typebyval);\n" if $userrtype;
	$uses .= "use Net::DNS::Extlang::Nsechelp;\n" if $usensechelp;


	# glom it all together and return string
my $identifier = $rrname;
$identifier =~ s/\W/_/g;
 
	return <<"CODE";
# generated package $rrname;	$rrcomment
package Net::DNS::RR::TYPE$rrnum;
use strict;
use base qw(Net::DNS::RR);
use integer;
use Carp;
$uses

$decode

$encode

$format

$parse

$defaults

$fieldfns


{
	# also make accessible by symbolic name
	package Net::DNS::RR::$identifier;
	our \@ISA = qw(Net::DNS::RR::TYPE$rrnum);	# Avoid "use base ...;" (RT#123702)
}


1;

__END__

CODE
}


# make the per-field functions
# field function
my $ffpat = <<'EOF';
sub #FIELD# {
	my $self = shift;

	$self->{#FIELD#} = #SETVAL# if scalar @_;
	#GETVAL#;
}
EOF

# decode text of Base64
my $b64field = <<'EOF';
sub #FIELD# {
	my $self = shift;

	$self->#FIELD#_bin( MIME::Base64::decode( join "", @_ ) ) if scalar @_;
	MIME::Base64::encode( $self->#FIELD#_bin(), "" ) if defined wantarray;
}
EOF

# decode text of hex field
my $hexfield = <<'EOF';
sub #FIELD# {
	my $self = shift;

	$self->#FIELD#_bin( pack "H*", map { die "!hex!" if m/[^0-9A-Fa-f]/; $_ } join "", @_ ) if scalar @_;
	unpack "H*", $self->#FIELD#_bin() || '' if defined wantarray;

}
EOF

# counted hex field
#my $hexone = <<'EOF';
#sub #FIELD# {
#	my ($self) = @_;

#	if(scalar @_) {
#		my $arg = shift;
#		die "!hex!" if $arg =~ m/[^0-9A-Fa-f]/;
#		$self->{#FIELD#} = pack "H*", $arg;
#	}
#	unpack "H*", $self->{#FIELD#} if defined wantarray;

#}
#EOF

# integer field with named values
my $ivalfield = <<'EOF';
my %#FIELD#_vals = #VALMAP#;
sub #FIELD# {
	my $self = shift;

	return $self->{#FIELD#} unless scalar @_;

	my $newval = shift || 0;
	return $self->{#FIELD#} = $newval unless $newval =~ /\D/;

	my $typenum = $#FIELD#_vals{$newval};
	$typenum || croak "unknown #FIELD# $newval";  # handle or'ed together fields someday
	$self->{#FIELD#} = $typenum;
}
EOF

# AAAA field
my $aaaafield = <<'EOF';
sub #FIELD#_long {
	my $addr = pack 'a*@16', grep defined, shift->{#FIELD#};
	sprintf '%x:%x:%x:%x:%x:%x:%x:%x', unpack 'n8', $addr;
}

sub #FIELD#_short {
	my $addr = pack 'a*@16', grep defined, shift->{#FIELD#};
	for ( sprintf ':%x:%x:%x:%x:%x:%x:%x:%x:', unpack 'n8', $addr ) {
		s/(:0[:0]+:)(?!.+:0\1)/::/;			# squash longest zero sequence
		s/^:// unless /^::/;				# prune LH :
		s/:$// unless /::$/;				# prune RH :
		return $_;
	}
}

sub #FIELD# {
	my $self = shift;

	return #FIELD#_long($self) unless scalar @_;

	my $addr = shift;
	my @parse = split /:/, "0$addr";

	if ( (@parse)[$#parse] =~ /\./ ) {			# embedded IPv4
		my @ip4 = split /\./, pop(@parse);
		my $rhs = pop(@ip4);
		my @ip6 = map { /./ ? hex($_) : (0) x ( 7 - @parse ) } @parse;
		return $self->{#FIELD#} = pack 'n6 C4', @ip6, @ip4, (0) x ( 3 - @ip4 ), $rhs;
	}

	# Note: pack() masks overlarge values, mostly without warning.
	my @expand = map { /./ ? hex($_) : (0) x ( 9 - @parse ) } @parse;
	$self->{#FIELD#} = pack 'n8', @expand;
}
EOF



# bin field for hex or b64 or b32
sub _bn($$$) {
	my ($type, $name, $quals) = @_;

	return "${name}_bin" if $type eq "B64" or ($type eq "X" and not $quals);
	$name;
}

sub _perfield {
	my ($rrfields) = @_;
	my $fieldfns = '';
	  
	foreach my $f (@$rrfields) {
		my ($type, $quals, $name) = ($f->{type}, $f->{quals}, $f->{name});
		# make a field function

		# if it's an integer field with named values
		if($type =~ m{I\d} and $quals) {
			my $valmap = "(" . join(",", map { my ($n, $v) = split /=/,$_,2; " '$n' => $v"; } split /,/,$quals) . ")";
			$fieldfns .= _csub($ivalfield, FIELD => $name, VALMAP => $valmap);
			next;
		}

		# if it's AAAA
		if($type eq "AAAA") {	# setter, long and short setter
			$fieldfns .= _csub($aaaafield, FIELD => $name );
			next;
		}

		# call it fieldbin if it's a base64
		my $setval = _cchunk($f,
				'N' => 'new Net::DNS::DomainName(shift)',
				'N[C]' => 'new Net::DNS::DomainName1035(shift)',
				'N[A]' => 'new Net::DNS::Mailbox1035(shift)',
				'N[A,C]' => 'new Net::DNS::Mailbox1035(shift)',
				'A' => 'pack "C4", split /\./,shift',
				'AA' =>  'pack "n4", map hex($_), split /:/, shift', 
				'S[M]' => '[map Net::DNS::Text->new($_), @_]',
				'S' => ' Net::DNS::Text->new(shift)',
				'T' => '_string2time(shift)',
				'R' => 'typebyname(shift)',
				'R[L]' => '_type2bm(@_)',
				'X6' => 'pack "C6", map hex($_), split /[:-]/, shift',
				'X8' => 'pack "C8", map hex($_), split /[:-]/, shift',
				'B32' => '_decode_base32(shift)',
				'X[C]' => 'pack "H*", shift',
				'default' => 'shift');

		# FN in getval means it's a function, not just part of an expression
		my $getval = _cchunk($f,
				'default' => ' || undef',
				'I1' => ' || 0',
				'I2' => ' || 0',
				'I4' => ' || 0',
				'N' => "->name if \$self->{$name}",
				'N[A]' => "->address if \$self->{$name}",
				'N[A,C]' => "->address if \$self->{$name}",
				'A' => "FNjoin '.', unpack 'C4', \$self->{$name} if \$self->{$name}",
				'AA' => "FNsprintf '%x:%x:%x:%x', unpack 'n4',\$self->{$name} if \$self->{$name}",
				'S[M]' => '|| []',
				'S' => ' || ""',
				'T' => "FN_encodetime(\$self->{$name})",
				'R' => "FNtypebyval(\$self->{$name})",
				'R[L]' => "FN_bm2type(\$self->{$name})",
				'X6' => "FNjoin '-', unpack 'H2H2H2H2H2H2', \$self->{$name}",
				'X8' => "FNjoin '-', unpack 'H2H2H2H2H2H2H2H2', \$self->{$name}",
				'B32' => "FN_encode_base32(\$self->{$name})",
				'X[C]' => "FNunpack 'H*', \$self->{$name}",

			
				    );
		if(substr($getval, 0,2) eq "FN") {
			$getval = substr($getval,2);
		} else {
			$getval = "\$self->{" . _bn($type, $name, $quals) . "} $getval";
		}
		$fieldfns .= _csub($ffpat, FIELD => _bn($type, $name, $quals), SETVAL => $setval, GETVAL => $getval);

		if($type eq "B64") {	# extra set/get function for text version of the field
			$fieldfns .= _csub($b64field, FIELD => $name );
		}
		if( $type eq "X" and not $quals ) {	# extra set/get function for text version of the field
			$fieldfns .= _csub($hexfield, FIELD => $name );
		}
	}
	$fieldfns;
}

sub _fielddefault {
	my ($rrfields) = @_;
	my ($defaults);

	foreach my $f (@$rrfields) {
		my ($type, $quals, $name) = ($f->{type}, $f->{quals}, $f->{name});

		my $defval =  _cchunk($f,
				default => q(''),
				'I1'	=> q(0),
				'I2'	=> q(0),
				'I4'	=> q(0),
				'A'	=> q('0.0.0.0'),
				'AA'	=> q('00:00:00:00'),
				'AAAA'	=> q('::'),
				'N'	=> q(''),
				'N[A]'	=> q('<>'),
				'R'	=> q('NULL'),
				'S'	=> q(''),
				'S[M]'	=> q('', ''),
				'T'	=> q(0),
				     );

		$defaults .= _csub("	\$self->#FIELD#(#DEFVAL#);\n",
			FIELD => _bn($type, $name, $quals),
			DEFVAL => $defval);
	}

	return $defaults ? <<"CODE" : '';
sub _defaults {				## specify RR attribute default values
	my \$self = shift;

	## Note that this code is executed once only after module is loaded.
$defaults}
CODE
}


# extract fields from binary data
# triple of unpack code, size or 0 or -1, code string with #O# offset
# and #F# binary field name
my $stringdecode = <<'EOF';
	my $limit = $offset + $self->{rdlength};
	my $text;
	my $txtdata = $self->{#F#} = [];
	while ( $offset < $limit ) {
		( $text, $offset ) = decode Net::DNS::Text( $data, $offset );
		push @$txtdata, $text;
	}
	croak('corrupt TXT data') unless $offset == $limit;	# more or less FUBAR
EOF

# single trailing string for S[X]
my $onestringdecode = <<'EOF';
	my $limit = $origoffset + $self->{rdlength};
	$self->{#F#} = decode Net::DNS::Text( $data, $offset, $limit - $offset );
EOF

# counted field
my $countdecode = <<'EOF';
my $#F#_len = unpack "\@$offset C", $$data;
	$self->{#F#} = unpack "\@$offset x a$#F#_len", $$data;
	$offset += 1 + $#F#_len;
EOF


sub _fielddecode {
	my ($rrfields) = @_;
	my ($decode);
	my $offoff = 0;
	  
	foreach my $f (@$rrfields) {
		my ($type, $quals, $name) = ($f->{type}, $f->{quals}, $f->{name});

		my $cch = _cchunk($f, 'default' => [ '???', '???', -1 ],
			'I1' => [ 'C', 1, undef ],
			'I2' => [ 'n', 2, undef ],
			'I4' => [ 'N', 4, undef ],
			'A' => [ 'a4', 4, undef ],
			'AA' => ['a8', 8, undef ],
			'AAAA' => ['a16', 8, undef ],
			'N' => [ undef, 0, '($self->{#F#}, $offset) = decode Net::DNS::DomainName( $data, $offset, @opaque );'],
			'N[C]' => [ undef, 0, '($self->{#F#}, $offset) = decode Net::DNS::DomainName1035( $data, $offset, @opaque );'],
			'N[A,C]' => [ undef, 0, '($self->{#F#}, $offset) = decode Net::DNS::DomainName1035( $data, $offset, @opaque );'],
			'S' => [ undef, 0, '( $self->{#F#}, $offset ) = decode Net::DNS::Text( $data, $offset );' ],
			'S[M]' => [ undef, -1, $stringdecode ],
			'S[X]' => [ undef, -1, $onestringdecode ],
			'B64' => [ undef, -1, '$self->{#F#_bin} = substr $$data, $offset, $self->{rdlength} - ($offset-$origoffset);'],
			'X' => [ undef, -1, '$self->{#F#_bin} = substr $$data, $offset, $self->{rdlength} - ($offset-$origoffset);'],
			'X[C]' => [ undef, 0, $countdecode ],
			'B32' => [ undef, 0, $countdecode ],
			'R[L]' => [ undef, -1, '$self->{#F#} = substr $$data, $offset, $self->{rdlength} - ($offset-$origoffset);'],
			'T' => [ 'N', 4, undef ],
			'R' => [ 'n', 2, undef ],
			'X6' => [ 'a6', 6, undef ],
			'X8' => [ 'a8', 8, undef ],
				
				 );
		
		my ($pat, $size, $code) = @$cch;
		croak "$name field after end of decoded data" if $offoff < 0;

		if($pat) {
			$decode .= "\t\$self->{$name} = unpack \"\\\@\$offset $pat\",\$\$data;\n\t\$offset += $size;\n";
			$offoff += $size;
		} else {
			$decode .= _csub("\t$code\n", F => $name);
			if($size < 0) { $offoff = -1; }
			else { $offoff += $size; } # 0 for offset updated, -1 for not so this has to be last
		}
	}

	return $decode ? <<"CODE" : '';
sub _decode_rdata {			## decode rdata from wire-format octet string
	my (\$self, \$data, \$offset, \@opaque ) = \@_;
	my \$origoffset = \$offset;
	## \$data	reference to a wire-format packet buffer
	## \$offset	location of rdata within packet buffer

$decode}
CODE
}


# turn fields into binary data
# triple of pack codes, and code to create the stuff to pack, size
# default code is the field
# size of -1 means unknown, will fail if something later wants it
# stores the data into $encdata

sub _fieldencode {
	my ($rrfields) = @_;
	my ($packpat, @args, $packcode);
	  
	foreach my $f (@$rrfields) {
		my ($type, $quals, $name) = ($f->{type}, $f->{quals}, $f->{name});

		my $cch = _cchunk($f, 'default' => [ '???', '???', -1 ],
			'I1' => [ 'C', undef, 1 ],
			'I2' => [ 'n', undef, 2 ],
			'I4' => [ 'N', undef, 4 ],
			'A' => [ 'a4', undef, 4 ],
			'AA' => [ 'a8', undef, 8 ],
			'AAAA' => [ 'a16', undef,16 ],
			'N' => [ 'a*', '#F#->encode(#O#, @opaque)', -1 ],
			'N[A]' => [ 'a*', '#F#->encode(#O#, @opaque)', -1 ],
			'N[A,C]' => [ 'a*', '#F#->encode(#O#, @opaque)', -1 ],
			'S' => [ 'a*', ' #F#->encode', -1 ],  # encode provides the length
			'S[X]' => [ 'a*', '#F#->raw', -1 ],
			'S[M]' => [ 'a*', 'join("", map( $_->encode, @{#F#}))', -1 ],
			'B64' => [ 'a*', undef, -1 ],
			'X[C]' => [ 'Ca*', 'length(#F#),#F#', -1 ],
			'B32' => [ 'Ca*', 'length(#F#),#F#', -1 ],
			'X' => [ 'a*', undef, -1 ],
			'T' => [ 'N', undef, 4 ],
			'R' => [ 'n', undef, 2 ],
			'R[L]' => [ 'a*', undef, -1 ],
			'X6' => [ 'a6', undef, 6 ],
			'X8' => [ 'a8', undef, 8 ],
				 );
		
		my ($pat, $field, $size) = @$cch;
		$field = '#F#' unless $field;

		# handle names that need to know the offset
		if($field =~ m{#O#}) {
			if($packpat) {	# flush out any pending stuff
				if($packcode) {
					$packcode .= "\t\$encdata .= ";
				} else {
					$packcode = "\t\$encdata = ";
				}
				if($packpat =~ m{^(a\*)+$}) { # all a's, just concat
					$packcode .= join(" . ", @args) . ";\n";
				} else {
					$packcode .= "pack '$packpat'," . join(", ", @args) . ";\n";
				}
				$packpat = ""; @args = ();
			}
			if($packcode) {
				$field =~ s{#O#}{\$offset+(length \$encdata)};
			} else {
				$field =~ s{#O#}{\$offset}; # first field, plain offset
			}
		}
		$packpat .= $pat;

		for ($field) {
			s/#F#/join('', '$self->{', _bn($type, $name, $quals), '}')/eg;
			push @args, $_;
		}
	}
	# now generate the code
	if($packpat) {
		if($packcode) {
			$packcode .= "\t\$encdata .= ";
		} else {
			$packcode = "\t\$encdata = ";
		}
		if($packpat =~ m{^(a\*)+$}) { # all a's, just concat
			$packcode .= join(" . ", @args) . ";\n";
		} else {
			$packcode .= "pack '$packpat'," . join(", ", @args) . ";\n";
		}
	}

	return $packcode ? <<"CODE" : '';
sub _encode_rdata {			## encode rdata as wire-format octet string
	my (\$self, \$offset, \@opaque) = \@_;
	my \$encdata = '';

$packcode}
CODE
}


# parse arguments to make a new RR
sub _fieldparse {
	my ($rrfields) = @_;
	my ($decode, $eaten);		# $eaten means all the arguments have been eaten
	  
	foreach my $f (@$rrfields) {
		my ($type, $quals, $name) = ($f->{type}, $f->{quals}, $f->{name});

		carp("Field with no argument $name") if $eaten;

		#print "parse $type $name ";
		# check for a field that takes multiple arguments
		my $val = _cchunk($f, 'default' => 'shift',
			'S[M]' => '@_',
			'B64' => '@_',
			'X' => '@_',
			'X[C]' => 'shift',
			'R[L]' => '@_',
			       );
		#print "$val\n";
		$eaten = 1 if $val =~ m'@_';
		$decode .= _csub("	\$self->#FIELD#(#VAL#);\n",
			FIELD => $name,
			VAL => $val);
	}

	return $decode ? <<"CODE" : '';
sub _parse_rdata {			## populate RR from rdata in argument list
	my \$self = shift;

$decode}
CODE
}


# format RR fields into an array
sub _fieldformat {
	my ($rrfields) = @_;
	my (@rdata);		# $eaten means all the arguments have been eaten
	  
	foreach my $f (@$rrfields) {
		my ($type, $quals, $name) = ($f->{type}, $f->{quals}, $f->{name});

		my $fmt = _cchunk($f, 'default' => '$self->{#FIELD#}',
			'N' => '$self->{#FIELD#}->string',
			'N[C]' => '$self->{#FIELD#}->string',
			'N[C,A]' => '$self->#FIELD#}->string',
			'S' => '$self->{#FIELD#}->string',
			'S[M]' => '(map $_->string, @{$self->{#FIELD#}})',
			'A' => '$self->#FIELD#()',
			'AA' => "sprintf('%x:%x:%x:%x', unpack 'n4',\$self->{#FIELD#})",
			'AAAA' => '$self->#FIELD#_short',
			'B64' => 'split(/\s+/, encode_base64( $self->{#FIELD#_bin}))',
			'B32' => '$self->#FIELD#()',
			'X' => '$self->#FIELD#()',
			'R' => '$self->#FIELD#()', # same as R[L]
			'T' => '$self->#FIELD#()',
			'X6' => '$self->#FIELD#()',
			'X8' => '$self->#FIELD#()',
				 );
		push @rdata, _csub($fmt, FIELD => $name);
	}

	my $format = "(" . join(",\n\t", @rdata) . "\n\t)";

	return scalar(@rdata) ? <<"CODE" : '';
sub _format_rdata {			## format rdata portion of RR string.
	my \$self = shift;

	$format
}
CODE
}


=head1 Field types

=head2 I1, I2, I4  -- bigendian integers

Display is unsigned integer

=head2 R, R[L] - 16 bit RRTYPE, or NSEC grouped bitmap of RRTYPEs

Display is symbolic RRTYPE or typeN, or list thereof

=head2 A, AA, AAAA - 32, 64, 128 bit address

Display is 1.1.1.1 or xx:xx::xx

=head2 N - regular and compressed domain name, mailbox domain name

Display is a domain name.  Option C means RFC1035 compression, option A
means it's really a mailbox.
Options only for the last field in a record: O means the name is optional.

=head2 S, S[M], S[X] - string, multiple strings, uncounted final string

Quoted string or strings.  M and X must be last field.

=head2 B32/64  - base32/64

Display is string.
B32 is preceded in the record by a length byte.
B64 is uncounted so must be last field, display can have embedded spaces.

=head2 X, X[C] - hex, hex with one byte count.

Uncounted X must be the last field, display can contain spaces.

=head2 X6, X8 - EUI48 and EUI64

Display is six or eight bytes of hex with optional hyphens.

=head2 T. T6 - unix timestamp

T is four bytes, T6 is six bytes.
Display is number of seconds since 1970 or yyyymmddhhmmss.

=head2 Z[...] - special cases

Defined in the spec but not implemented

=cut
1;
__END__

=head1 COPYRIGHT

Copyright 2017 John R. Levine. 

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the above copyright notice appear in all copies and that both that
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<perl>, L<Net::DNS:RR>,
draft-levine-dnsextlang
 
=cut
