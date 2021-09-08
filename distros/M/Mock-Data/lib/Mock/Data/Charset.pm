package Mock::Data::Charset;
use strict;
use warnings;
use Mock::Data::Util qw( _parse_context _escape_str );
require Carp;
our @CARP_NOT= ('Mock::Data::Util');
require Mock::Data::Generator;
our @ISA= ( 'Mock::Data::Generator' );

# ABSTRACT: Generator of strings from a set of characters
our $VERSION = '0.02'; # VERSION


our @generator_attrs= qw( str_len min_codepoint max_codepoint );

sub new {
	my $class= shift;
	my (%self, %parse);
	# make the common case fast
	if (@_ == 1 && !ref $_[0]) {
		qr/[$_[0]]/;
		%self= ( notation => $_[0] );
		if (ref $class) {
			$self{generator_opts} ||= { %{ $class->{generator_opts} } };
			$self{max_codepoint}  //= $class->{max_codepoint};
			$class= ref $class;
		}
		return bless \%self, $class;
	}

	%self= @_ != 1? @_ : %{$_[0]};

	# Look for fields from the parser
	$parse{classes}= delete $self{classes} if defined $self{classes};
	$parse{codepoints}= delete $self{codepoints} if defined $self{codepoints};
	$parse{codepoint_ranges}= delete $self{codepoint_ranges} if defined $self{codepoint_ranges};
	$parse{negate}= delete $self{negate} if defined $self{negate};
	if (defined $self{chars}) {
		push @{$parse{codepoints}}, map ord, @{$self{chars}};
		delete $self{chars};
	}
	if (defined $self{ranges}) {
		push @{$parse{codepoint_ranges}},
			map +( ref $_? ( ord $_->[0], ord $_->[1] ) : ord ),
				@{$self{ranges}};
		delete $self{ranges};
	}

	# If called on an object, carry over some settings
	if (ref $class) {
		if (!keys %parse && !defined $self{notation} && !$self{members} && !$self{member_invlist}) {
			@self{'_parse','notation','members','member_invlist'}=
				@{$class}{'_parse','notation','members','member_invlist'};
		}
		$self{$_} //= $class->{$_} for @generator_attrs;
		$class= ref $class;
	}

	if (defined $self{notation} && !keys %parse) {
		# want to trigger the syntax error exception now, not lazily later on
		qr/[$self{notation}]/;
	}
	elsif (keys %parse) {
		$self{_parse}= \%parse;
		Carp::croak("Charset-building options (classes, chars, codepoints, ranges, codepoint_ranges, negate)"
			." cannot be combined with members, member_invlist or notation attributes")
			if $self{members} or $self{member_invlist}; # allow notation to preserve original text
	}
	else {
		# At least one of members, member_invlist, notation, or _parse must be specified
		Carp::croak("Require at least one of members, member_invlist, notation, or charset-building options")
			unless $self{members} or $self{member_invlist};
	}
	
	return bless \%self, $class;
}

sub _parse {
	# If the '_parse' wasn't initialized, it can be derived from members or member_invlist or notation
	$_[0]{_parse} || do {
		my $self= shift;
		if (defined $self->{notation}) {
			$self->{_parse}= $self->parse($self->{notation});
		}
		elsif ($self->{members}) {
			$self->{_parse}{codepoints}= [ map ord, @{$self->{members}} ];
		}
		elsif (my $inv= $self->{member_invlist}) {
			my $i;
			for ($i= 0; $i < $#$inv; $i+= 2) {
				if ($inv->[$i] + 1 == $inv->[$i+1]) { push @{$self->{_parse}{codepoints}}, $inv->[$i] }
				else { push @{$self->{_parse}{codepoint_ranges}}, $inv->[$i], $inv->[$i+1] - 1; }
			}
			if ($i == $#$inv) {
				push @{$self->{_parse}{codepoint_ranges}}, $inv->[$i], ($self->max_codepoint || 0x10FFFF);
			}
		}
		else { die "Unhandled lazy-build scenario" }
		$self->{_parse};
	};
}


sub notation {
	$_[0]{notation} //= _deparse_charset($_[0]->_parse);
}


sub min_codepoint {
	$_[0]{min_codepoint}= $_[1] if @_ > 1;
	$_[0]{min_codepoint}
}
sub max_codepoint {
	$_[0]{max_codepoint}
}


sub str_len {
	$_[0]{str_len}= $_[1] if @_ > 1;
	$_[0]{str_len};
}


sub count {
	$_[0]{members}? scalar @{$_[0]{members}}
		: $_[0]->_invlist_index->[-1];
}


sub members {
	$_[0]{members} ||= $_[0]->_build_members;
}

sub _build_members {
	my $self= shift;
	my $invlist= $self->member_invlist;
	my @members;
	if (@$invlist > 1) {
		push @members, map chr, $invlist->[$_*2] .. ($invlist->[$_*2+1]-1)
			for 0 .. (($#$invlist-1)>>1);
	}
	# an odd number of elements means the list ends with an "include-all"
	push @members, map chr, $invlist->[-1] .. 0x10FFFF
		if 1 & @$invlist;
	return \@members;
}

sub Mock::Data::Charset::Util::expand_invlist {
	my $invlist= shift;
	my @members;
	if (@$invlist > 1) {
		push @members, $invlist->[$_*2] .. ($invlist->[$_*2+1]-1)
			for 0 .. (($#$invlist-1)>>1);
	}
	# an odd number of elements means the list ends with an "include-all"
	push @members, $invlist->[-1] .. 0x10FFFF
		if 1 & @$invlist;
	return \@members;
}

# The index is private because there's not a good way to explain it to the user
sub _invlist_index {
	my $self= shift;
	$self->{_invlist_index} ||= Mock::Data::Charset::Util::create_invlist_index($self->member_invlist);
}

sub Mock::Data::Charset::Util::create_invlist_index {
	my $invlist= shift;
	my $n_spans= (@$invlist + 1) >> 1;
	my @index;
	$#index= $n_spans-1;
	my $total= 0;
	$index[$_]= $total += $invlist->[$_*2+1] - $invlist->[$_*2]
		for 0 .. (@$invlist >> 1)-1;
	if (@$invlist & 1) { # In the case that the final range is infinite
		$index[$n_spans-1]= $total + 0x110000 - $invlist->[-1];
	}
	\@index;
}


sub member_invlist {
	if (@_ > 1) {
		$_[0]{member_invlist}= $_[1]; 
		delete $_[0]{_invlist_index};
		delete $_[0]{members};
		delete $_[0]{notation};
	}
	$_[0]{member_invlist} //= _build_member_invlist(@_);
}

sub _build_member_invlist {
	my $self= shift;
	my $max_codepoint= $self->max_codepoint;
	# If the search space is small, and there is already a regex notation, it is probably faster
	# to iterate and let perl do the work than to parse the charset.
	my $invlist;
	if (!defined $max_codepoint || $max_codepoint > 1000 || !defined $self->{notation}) {
		$max_codepoint ||= 0x10FFFF;
		$invlist= eval {
			_parsed_charset_to_invlist($self->_parse, $max_codepoint);
		}# or main::diag $@
	}
	$invlist ||= _charset_invlist_brute_force($self->notation, $max_codepoint);
	# If a user writes to the invlist, it will become out of sync with the Index,
	# leading to confusing bugs.
	if (Internals->can('SvREADONLY')) {
		Internals::SvREADONLY($_,1) for @$invlist;
		Internals::SvREADONLY(@$invlist,1);
	}
	return $invlist;
}

# Lazy-built string of all basic-multilingual-plane characters
our $_ascii_chars;
our $_unicode_chars;
sub _build_unicode_chars {
	unless (defined $_unicode_chars) {
		# Construct ranges of valid characters separated by NUL.
		# Older perls die when the regex engine encounters an invalid character
		# but newer perls just treat the invalid character as "not a member",
		# unless the set is a negation in which case non-characters *are* a member.
		# This makes the assumption that if a non-char isn't a member then \0 won't
		# be either.
		$_unicode_chars= '';
		$_unicode_chars .= chr($_) for 0 .. 0xD7FF;
		$_unicode_chars .= "\0";
		$_unicode_chars .= chr($_) for 0xFDF0 .. 0xFFFD;
		for (1..16) {
			$_unicode_chars .= "\0";
			$_unicode_chars .= chr($_) for ($_<<16) .. (($_<<16)|0xFFFD);
		}
	}
	\$_unicode_chars;
}

sub _charset_invlist_brute_force {
	my ($set, $max_codepoint)= @_;
	my $inv= (ord $set == ord '^')? substr($set,1) : '^'.$set;
	my @invlist;
	
	# optimize common case
	if ($max_codepoint < 256) {
		# Find first character of every match and first character of every non-match
		# and convert to codepoints.
		@invlist= map +(defined $_? ord($_) : ()),
			($_ascii_chars //= join('', map chr($_), 0..255))
				=~ / ( [$set] ) (?> [$set]* ) (?: \z | ( [$inv] ) (?> [$inv]* ) )/gx;
	}
	else {
		_build_unicode_chars() unless defined $_unicode_chars;
		# This got complicated while trying to support perls that can't match against non-characters.
		# The non-characters have been replaced by NULs, so need to capture the char before and after
		# each transition in case one of them is a NUL.
		my @endpoints=
			($max_codepoint < 0x10FFFF? substr($_unicode_chars,0,$max_codepoint+1) : $_unicode_chars)
				=~ /( [$set] ) ( [$set] )* ( \z | [$inv] ) ( [$inv] )* /gx;
		if (@endpoints) {
			# List is a multiple of 4 elements: (first-member,last-member,first-non-member,last-non-member)
			# We're not interested in the span of non-members at the end, so just remove those.
			pop @endpoints; pop @endpoints;
			# Iterate every transition of member/nonmember, and use the second character if present
			# and isn't a NUL, else use the first character and add 1.
			push @invlist, ord $endpoints[0];
			for (my $i= 1; $i < @endpoints; $i+= 2) {
				if (defined $endpoints[$i+1] && ord $endpoints[$i+1]) {
					push @invlist, ord $endpoints[$i+1];
				} elsif (defined $endpoints[$i]) {
					push @invlist, 1 + ord $endpoints[$i];
				} else {
					push @invlist, 1 + $invlist[-1];
				}
			}
			# substr is an estimate, because string skips characters, so remove any spurrous
			# codepoints beyond the max
			pop @invlist while @invlist && $invlist[-1] > $max_codepoint;
		}
	}
	# If an "infinite" range would be returned, but the user set a maximum codepoint,
	# list the max codepoint as the end of the invlist.
	if ($max_codepoint < 0x10FFFF and 1 & @invlist) {
		push @invlist, $max_codepoint+1;
	}
	return \@invlist;
}

sub _parsed_charset_to_invlist {
	my ($parse, $max_codepoint)= @_;
	my @invlists;
	# convert the character list into an inversion list
	if (defined (my $cp= $parse->{codepoints})) {
		my @chars= sort { $a <=> $b } @$cp;
		my @invlist= (shift @chars);
		push @invlist, $invlist[0] + 1;
		for (my $i= 0; $i <= $#chars; $i++) {
			# If the next char is adjacent, extend the span
			if ($invlist[-1] == $chars[$i]) {
				++$invlist[-1];
			} else {
				push @invlist, $chars[$i], $chars[$i]+1;
			}
		}
		push @invlists, \@invlist;
	}
	# Each range is an inversion list already
	if (my $r= $parse->{codepoint_ranges}) {
		for (my $i= 0; $i < (@$r >> 1); $i++) {
			my ($start, $limit)= ($r->[$i*2], $r->[$i*2+1]+1);
			# Try to combine the range with the most recent inversion list, if possible,
			if (@invlists && $invlists[-1][-1] < $start) {
				push @{ $invlists[-1] }, $start, $limit;
			} elsif (@invlists && $invlists[-1][0] > $limit) {
				unshift @{ $invlists[-1] }, $start, $limit;
			} else {
				# else just start a new inversion list
				push @invlists, [ $start, $limit ]
			}
		}
	}
	# Convert each character class to an inversion list.
	if ($parse->{classes}) {
		push @invlists, _class_invlist($_)
			for @{ $parse->{classes} };
	}
	my $invlist= Mock::Data::Charset::Util::merge_invlists(\@invlists, $max_codepoint);
	# Perform negation of inversion list by either starting at char 0 or removing char 0
	if ($parse->{negate}) {
		if ($invlist->[0]) { unshift @$invlist, 0 }
		else { shift @$invlist; }
	}
	return $invlist;
}


our $_compile;
sub compile {
	local $_compile= 1;
	shift->generate(@_);
}
sub generate {
	my ($self, $mock)= (shift, shift);
	my ($len, $cp_min, $cp_max, $member_count)
		= ($self->str_len, $self->min_codepoint, $self->max_codepoint, $self->count);
	if (@_) {
		my %opts= ref $_[0] eq 'HASH'? %{ shift() } : ();
		$len= @_? shift : $opts{str_len} // $opts{len} // $opts{size}; # allow some aliases for length
		$cp_min= $opts{min_codepoint} // $cp_min;
		$cp_max= $opts{max_codepoint} // $cp_max;
	}
	my ($memb_min, $memb_span)= !defined $cp_min && !defined $cp_max? (0,$member_count)
		: $self->_codepoint_minmax_to_member_range($cp_min, $cp_max);

	# If compiling, $len will be a function, else it will be an integer
	$len= !defined $len? ($_compile? sub { 1 } : 1 )
		: !ref $len? ($_compile? sub { $len } : $len)
		: ref $len eq 'ARRAY'? (
			$_compile? sub { $len->[0] + int rand ($len->[1] - $len->[0]) }
			: $len->[0] + int rand ($len->[1] - $len->[0])
		)
		: ref $len eq 'CODE'? ($_compile? $len : $len->($mock))
		: Carp::croak("Unknown str_len specification '$len'");

	# If member list is small-ish, use faster direct array access
	if ($self->{members} || $member_count < 500) {
		my $members= $self->members;
		return sub {
			my $buf= '';
			$buf .= $members->[$memb_min + int rand $memb_span]
				for 1..$len->($_[0]);
			return $buf;
		} if $_compile;
		my $buf= '';
		$buf .= $members->[$memb_min + int rand $memb_span]
			for 1..$len;
		return $buf;
	}		
	else {
		my $invlist= $self->member_invlist;
		my $index= $self->_invlist_index;
		return sub {
			my $ret= '';
			$ret .= chr _get_invlist_element($memb_min + int rand($memb_span), $invlist, $index)
				for 1..$len->($_[0]);
		} if $_compile;
		my $buf= '';
		$buf .= chr _get_invlist_element($memb_min + int rand($memb_span), $invlist, $index)
			for 1..$len;
		return $buf;
	}
}

sub _codepoint_minmax_to_member_range {
	my $self= shift;
	my ($cp_min, $cp_max)= @_;
	my $memb_min= !defined $cp_min? 0
		: do {
			my ($at, $ins)= _find_invlist_element($cp_min, $self->member_invlist, $self->_invlist_index);
			$at // $ins
		};
	my $memb_lim= !defined $cp_max? $self->count
		: do {
			my ($at, $ins)= _find_invlist_element($cp_max, $self->member_invlist, $self->_invlist_index);
			defined $at? $at + 1 : $ins;
		};
	return ($memb_min, $memb_lim-$memb_min);
}


sub parse {
	my ($self, $notation)= @_;
	return { codepoints => [] } unless length $notation;
	return { classes => ['All'] } if $notation eq '^';
	$notation .= ']';
	# parse function needs $_ to be the input string
	pos($notation)= 0;
	return _parse_charset() for $notation;
}

our $have_prop_invlist;
our %_parse_charset_backslash= (
	a => ord "\a",
	b => ord "\b",
	c => sub { die "Unimplemented: \\c" },
	d => sub { push @{$_[0]{classes}}, 'digit'; undef; },
	D => sub { push @{$_[0]{classes}}, '^digit'; undef; },
	e => ord "\e",
	f => ord "\f",
	h => sub { push @{$_[0]{classes}}, 'horizspace'; undef; },
	H => sub { push @{$_[0]{classes}}, '^horizspace'; undef; },
	n => ord "\n",
	N => \&_parse_charset_namedchar,
	o => \&_parse_charset_oct,
	p => \&_parse_charset_classname,
	P => sub { _parse_charset_classname(shift, 1) },
	r => ord "\r",
	s => sub { push @{$_[0]{classes}}, 'space'; undef; },
	S => sub { push @{$_[0]{classes}}, '^space'; undef; },
	t => ord "\t",
	v => sub { push @{$_[0]{classes}}, 'vertspace'; undef; },
	V => sub { push @{$_[0]{classes}}, '^vertspace'; undef; },
	w => sub { push @{$_[0]{classes}}, 'word'; undef; },
	W => sub { push @{$_[0]{classes}}, '^word'; undef; },
	x => \&_parse_charset_hex,
	0 => \&_parse_charset_oct,
	1 => \&_parse_charset_oct,
	2 => \&_parse_charset_oct,
	3 => \&_parse_charset_oct,
	4 => \&_parse_charset_oct,
	5 => \&_parse_charset_oct,
	6 => \&_parse_charset_oct,
	7 => \&_parse_charset_oct,
	8 => \&_parse_charset_oct,
	9 => \&_parse_charset_oct,
);
our %_class_invlist_cache= (
	'Any' => [ 0 ],
	'\\N' => [ 0, ord("\n"), 1+ord("\n") ],
);
sub _class_invlist {
	my $class= shift;
	if (ord $class == ord '^') {
		return Mock::Data::Charset::Util::negate_invlist(
			_class_invlist(substr($class,1))
		);
	}
	return $_class_invlist_cache{$class} ||= do {
		$have_prop_invlist= do { require Unicode::UCD; !!Unicode::UCD->can('prop_invlist') }
			unless defined $have_prop_invlist;
		$have_prop_invlist? [ Unicode::UCD::prop_invlist($class) ]
			: _charset_invlist_brute_force("\\p{$class}", 0x10FFFF);
	};
}
sub _parse_charset_hex {
	/\G( [0-9A-Fa-f]{2} | \{ ([0-9A-Fa-f]+) \} )/gcx
		or die "Invalid hex escape at "._parse_context;
	return hex(defined $2? $2 : $1);
}
sub _parse_charset_oct {
	--pos; # The caller ate one of the characters we need to parse
	/\G( [0-7]{3} | 0 | o\{ ([0-7]+) \} ) /gcx
		or die "Invalid octal escape at "._parse_context;
	return oct(defined $2? $2 : $1);
}
sub _parse_charset_namedchar {
	require charnames;
	/\G \{ ([^}]+) \} /gcx
#		or die "Invalid named char following \\N at '".substr($_,pos,10)."'";
		and return charnames::vianame($1);
	# Plain "\N" means every character except \n
	push @{ $_[0]{classes} }, '\\N';
	return;
}
sub _parse_charset_classname {
	my ($result, $negate)= @_;
	/\G \{ ([^}]+) \} /gcx
		or die "Invalid class name following \\p at "._parse_context;
	push @{$result->{classes}}, lc($negate? "^$1" : $1);
	undef
}
sub _parse_charset {
	my $flags= shift;
	# argument is in $_, starting from pos($_)
	my %parse;
	my @range;
	$parse{codepoints}= \my @chars;
	$parse{negate}= 1 if /\G \^ /gcx;
	if (/\G]/gc) { push @chars, ord ']' }
	while (1) {
		my $cp; # literal codepoint to be added
		# Check for special cases
		if (/\G ( \\ | - | \[: | \] ) /gcx) {
			if ($1 eq '\\') {
				/\G(.)/gc or die "Unexpected end of input";
				$cp= $_parse_charset_backslash{$1} || ord $1;
				$cp= $cp->(\%parse)
					if ref $cp;
			}
			elsif ($1 eq '-') {
				if (@range == 1) {
					push @range, ord '-';
					next;
				}
				else {
					$cp= ord '-';
				}
			}
			elsif ($1 eq '[:') {
				/\G ( [^:]+ ) :] /gcx
					or die "Invalid character class at "._parse_context;
				push @{$parse{classes}}, $1;
			}
			else {
				last; # $1 eq ']';
			}
		}
		elsif ($flags && ($flags->{x}||0) >= 2 && /\G[ \t]/gc) {
			next; # ignore space and tab under /xx
		}
		else {
			/\G(.)/gc or die "Unexpected end of input";
			$cp= ord $1;
		}
		# If no single character was found, any range-in-progress needs converted to
		# charcters
		if (!defined $cp) {
			push @chars, @range;
			@range= ();
		}
		# At this point, $cp will contain the next ordinal of the character to include,
		# but it might also be starting or finishing a range.
		elsif (@range == 1) {
			push @chars, $range[0];
			$range[0]= $cp;
		}
		elsif (@range == 2) {
			push @{$parse{codepoint_ranges}}, $range[0], $cp;
			@range= ();
		}
		else {
			push @range, $cp;
		}
		#printf "# pos %d  cp %d  range %s %s  include %s\n", pos $_, $cp, $range[0] // '(null)', $range[1] // '(null)', join(',', @include);
	}
	push @chars, @range;
	if (@chars) {
		@chars= sort { $a <=> $b } @chars;
	} else {
		delete $parse{codepoints};
	}
	return \%parse;
}

sub _ord_to_safe_regex_char {
	return chr($_[0]) =~ /[\w]/? chr $_[0]
		: $_[0] <= 0xFF? sprintf('\x%02X',$_[0])
		: sprintf('\x{%X}',$_[0])
}

sub _deparse_charset {
	my $parse= shift;
	my $str= '';
	if (my $cp= $parse->{codepoints}) {
		$str .= _ord_to_safe_regex_char($_)
			for @$cp;
	}
	if (my $r= $parse->{codepoint_ranges}) {
		for (my $i= 0; $i < (@$r << 1); $i++) {
			$str .= _ord_to_safe_regex_char($r->[$i*2]) . '-' . _ord_to_safe_regex_char($r->[$i*2+1]);
		}
	}
	if (my $cl= $parse->{classes}) {
		# TODO: reverse conversions to \h \v etc.
		for (@$cl) {
			$str .= $_ eq '\N'? '\0-\x09\x0B-\x{10FFFF}'
				: ord == ord '^'? '\P{'.substr($_,1).'}'
				: '\p{'.$_.'}';
		}
	}
	return $str;
}


sub get_member {
	$_[0]{members}? $_[0]{members}[$_[1]]
		: chr _get_invlist_element($_[1], $_[0]->member_invlist, $_[0]->_invlist_index);
}

sub get_member_codepoint {
	$_[0]{members}? ord $_[0]{members}[$_[1]]
		: _get_invlist_element($_[1], $_[0]->member_invlist, $_[0]->_invlist_index);
}

sub _get_invlist_element {
	my ($ofs, $invlist, $invlist_index)= @_;
	$ofs += @$invlist_index if $ofs < 0;
	return undef if $ofs >= $invlist_index->[-1] || $ofs < 0;
	# Binary Search to find the range that contains this numbered element
	my ($min, $max, $mid)= (0, $#$invlist_index);
	while (1) {
		$mid= ($min+$max) >> 1;
		if ($ofs >= $invlist_index->[$mid]) {
			$min= $mid+1
		}
		elsif ($mid > 0 && $ofs < $invlist_index->[$mid-1]) {
			$max= $mid-1
		}
		else {
			$ofs -= $invlist_index->[$mid-1] if $mid > 0;
			return $invlist->[$mid*2] + $ofs;
		}
	}
}


sub find_member {
	my ($self, $char)= @_;
	return _find_invlist_element(ord $char, $self->member_invlist, $self->_invlist_index);
}

sub _find_invlist_element {
	my ($codepoint, $invlist, $index)= @_;
	# Binary Search to find the range that contains this numbered element
	my ($min, $max, $mid)= (0, $#$invlist);
	while (1) {
		$mid= ($min+$max) >> 1;
		if ($mid > 0 && $codepoint < $invlist->[$mid]) {
			$max= $mid-1
		}
		elsif ($mid < $#$invlist && $codepoint >= $invlist->[$mid+1]) {
			$min= $mid+1;
		}
		else {
			return (undef, 0) unless $codepoint >= $invlist->[$mid];
			return $codepoint - $invlist->[$mid] unless $mid > 0;
			return $codepoint - $invlist->[$mid] + $index->[($mid >> 1) - 1] unless $mid & 1;
			# if $mid is an odd number, the range is excluded, and there is no match
			return undef unless wantarray;
			return (undef, $index->[($mid-1)>>1]) # return insertion point as second val
		}
	}
}


sub negate {
	my $self= shift;
	my $neg= Mock::Data::Charset::Util::negate_invlist($self->member_invlist, $self->max_codepoint);
	return $self->new(member_invlist => $neg);
}
sub Mock::Data::Charset::Util::negate_invlist {
	my ($invlist, $max_codepoint)= @_;
	# Toggle first char of 0
	$invlist= $invlist->[0]? [ 0, @$invlist ] : [ @{$invlist}[1..$#$invlist] ];
	# If max_codepoint is defined, and was the final char, remove the range starting at max_codepoint+1
	if (@$invlist & 1 and defined $max_codepoint and $invlist->[-1] == $max_codepoint+1) {
		pop @$invlist;
	}
	return $invlist;
}


sub union {
	my $self= $_[0];
	my @invlists= @_;
	ref eq 'ARRAY' || ($_= $_->member_invlist)
		for @invlists;
	my $combined= Mock::Data::Charset::Util::merge_invlists(\@invlists, $self->max_codepoint);
	return $self->new(member_invlist => $combined);
}

#=head2 merge_invlists
#
#  my $combined_invlist= $charset->merge_invlist( \@list2, \@list3, ... );
#  my $combined_invlist= merge_invlist( \@list1, \@list2, ... );
#
#Merge one or more inversion lists into a superset of all of them.
#If called as a method, the L</member_invlist> is used as the first list.
#
#The return value is an inversion list, which can be wrapped in a Charset object by passing it
#as the C<member_invlist> attribute.
#
#The current L</max_codepoint> applies to the result.  If called as a plain function, the
#C<max_codepoint> is assumed to be the Unicode maximum of C<0x10FFFF>.
#
#=cut

sub Mock::Data::Charset::Util::merge_invlists {
	my @invlists= @{shift()};
	my $max_codepoint= shift // 0x10FFFF;

	return [] unless @invlists;
	return [@{$invlists[0]}] unless @invlists > 1;
	my @combined= ();
	# Repeatedly select the minimum range among the input lists and add it to the result
	my @pos= (0)x@invlists;
	while (@invlists) {
		my ($min_ch, $min_i)= ($invlists[0][$pos[0]], 0);
		# Find which inversion list contains the lowest range
		for (my $i= 1; $i < @invlists; $i++) {
			if ($invlists[$i][$pos[$i]] < $min_ch) {
				$min_ch= $invlists[$i][$pos[$i]];
				$min_i= $i;
			}
		}
		last if $min_ch > $max_codepoint;
		# Check for overlap of this new inclusion range with the previous
		if (@combined && $combined[-1] >= $min_ch) {
			# they overlap, so just replace the end-codepoint of the range
			# if the new endpoint is larger
			my $new_end= $invlists[$min_i][$pos[$min_i]+1];
			$combined[-1]= $new_end if !defined $new_end || $combined[-1] < $new_end;
		}
		else {
			# else, simply append the range
			push @combined, @{$invlists[$min_i]}[$pos[$min_i] .. $pos[$min_i]+1];
		}
		# If the list is empty now, remove it from consideration
		if (($pos[$min_i] += 2) >= @{$invlists[$min_i]}) {
			splice @invlists, $min_i, 1;
			splice @pos, $min_i, 1;
			# If the invlist ends with an infinite range now, we are done
			if (!defined $combined[-1]) {
				pop @combined;
				last;
			}
		}
		# If this is the only list remaining, append the rest and done
		elsif (@invlists == 1) {
			push @combined, @{$invlists[0]}[$pos[0] .. $#{$invlists[0]}];
			last;
		}
	}
	while ($combined[-1] > $max_codepoint) {
		pop @combined;
	}
	# If the list ends with inclusion, and the max_codepoint is less than unicode max,
	# end the list with it.
	if (1 & @combined and $max_codepoint < 0x10FFFF) {
		push @combined, $max_codepoint+1;
	}
	return \@combined;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Charset - Generator of strings from a set of characters

=head1 SYNOPSIS

  # Export a handy alias for the constructor
  use Mock::Data::Charset 'charset';
  
  # Use perl's regex notation for [] charsets
  my $charset = charset('A-Za-z');
          ... = charset('\p{alpha}\s\d');
          ... = charset(classes => ['digit']);
          ... = charset(ranges => ['a','z']);
          ... = charset(chars => ['a','e','i','o','u']);
  
  # Test membership
  charset('a-z')->contains('a') # true
  charset('a-z')->count         # 26
  charset('\w')->count          # 
  charset('\w')->count('ascii') # 
  
  # Iterate
  my $charset= charset('a-z');
  for (0 .. $charset->count-1) {
    my $ch= $charset->get_member($_)
  }
  # this one can be very expensive if the set is large:
  for ($charset->members->@*) { ... }
  
  # Generate random strings
  my $str= $charset->generate($mockdata, 10); # 10 random chars from this charset
      ...= $charset->generate($mockdata, { min_codepoint => 1, max_codepoint => 127 }, 10);
      ...= $charset->generate($mockdata, { size => [5,10] }); # between 5 and 10 chars
      ...= $charset->generate($mockdata, { size => sub { 5 + int rand 5 }); # same

=head1 DESCRIPTION

This generator is optimized for holding sets of Unicode characters.  It behaves just like
the L<Mock::Data::Set|Set> generator but it also lets you inspect the member
codepoints, iterate the codepoints, and constrain the range of codepoints when generating
strings.

=head1 CONSTRUCTOR

=head2 new

  $charset= Mock::Data::Charset->new( %options );
  $charset= charset( %options );
  $charset= charset( $notation );

If you supply a single non-hashref argument to the constructor, it is assumed to be the
L</notation> string.  Otherwise, it is treated as key/value pairs.  You may specify the
members of the charset by one of the attributes C<notation>, C<members>, or
C<member_invlist>, or construct it from the following charset-building options:

=over

=item chars

An arrayref of literal character values to include in the set.

=item codepoints

An arrayref of Unicode codepoint numbers.

=item ranges

  ranges => [ ['a','z'], ['0', '9'] ],
  ranges => [ 'a', 'z', '0', '9' ],

An arrayref holding start/end pairs of characters, optionally with inner arrayrefs for each
start/end pair.

=item codepoint_ranges

Same as C<ranges> but with codepoint numbers instead of characters.

=item classes

An arrayref of character class names recognized by perl (such as Posix or Unicode classes).

=item negate

Negate the membership of the charset as described by C<chars>/C<ranges>/C<classes>.
This applies to the charset-building options, but has no effect on attributes.

=back

The constructor may also be given any of the keys for L</generate_opts>, which will be moved
into that attribute.

For convenience, you may export the L<Mock::Data::Util/charset> which calls this constructor.

If you call C<new> on an object, it carries over the following settings to the new object:
C<max_codepoint>, C<generator_opts>, C<member_invlist> (unless chars change).

=head1 ATTRIBUTES

=head2 notation

A Perl Regex charset notation; the text that occurs between '[...]' in a regex. (Note
that if you use backslash notations, like C<< notation => '\w' >>, you should either use a
single-quoted string, or escape them as C<< "\\w" >>.

This returns the same string that was passed to the constructor, if you gave the constructor
a regex-notation string instead of more specific attributes.  If you did not, a generic-looking
notation will be built on demand.  Read-only.

=head2 min_codepoint

Minimum codepoint to be returned from the generator.  Read/write.  This is useful if you want
to eliminate control characters (or maybe just NULs) in your output.

=head2 max_codepoint

Maximum unicode codepoint to be considered.  Read-only.  If you are only interested in a subset
of the Unicode character space, such as ASCII, you can set this to a value like C<0x7F> and
speed up the calculations on the character set.

=head2 str_len

This determines the length of string that will be returned from L<generate> if no length is
specified to that function.  This may be a plain integer, an arrayref of C<< [$min,$max] >>,
or a coderef that returns an integer: C<< sub { 5 + int rand 10 } >>.

=head2 count

The number of members in the set.  Read-only.

=head2 members

Returns an arrayref of each character in the set.  Try not to use this attribute, as building
it can be very expensive for common sets like C<< [:alpha:] >> (100K members, tens of MB
of RAM).  Use L</member_invlist> or L</get_member> instead, when possible, or set
L</max_codepoint> to restrict the set to characters you care about.

Read-only.

=head2 member_invlist

Return an arrayref holding the "inversion list" describing the members of this set.  An
inversion list stores the first codepoint belonging to the set, followed by the next higher
codepoint which does not belong to the set, followed by the next that does, etc.  This data
structure allows for efficient negation/inversion of the list.

You may write a new value to this attribute, but not modify the existing array.

=head1 METHODS

=head2 generate

  $charset->generate($mockdata, $len);
  $charset->generate($mockdata, \%options, $len);
  $charset->generate($mockdata, \%options);

Generate a string of characters from this charset.  The C<%options> may override the following
attributes: L</min_codepoint>, L</max_codepoint> (but only smaller values), and L</str_len>.
The default length is 1 character.

=head2 compile

Return a plain coderef that invokes L</generate> on this object.

=head2 parse

  my $parse_info= Mock::Data::Charset->parse('\dA-Z_');
  # {
  #   codepoints        => [ ord '_' ],
  #   codepoint_ranges  => [ ord "A", ord "Z" ],
  #   classes           => [ 'digit' ],
  # }

This is a class method that accepts a Perl-regex-notation string for a charset and returns
a hashref of the arguments that should be passed to the constructor.

This dies if it encounters a syntax error or any Perl feature that wasn't implemented.

=head2 get_member

  my $char= $charset->get_member($offset);

Return the Nth character of the set, starting from 0.  Returns undef for values
greater or equal to L</count>.  You can use negative offsets to index from the
end of the list, like in C<substr>.

=head2 get_member_codepoint

Same as L</get_member> but returns a codepoint integer instead of a character.

=head2 find_member

  my ($offset, $ins_pos)= $charset->find_member($char);

Return the index of a character within the members list.  If the character is not a member,
this returns undef, but if you call it in array context the second element gives the position
where it would be found if it was a member.

=head2 negate

  my $charset2= $charset->negate;

Return a new charset which contains exactly the opposite characters as this one, up to the
L</max_codepoint> if defined.

=head2 union

  my $charset3= $charset1->union($charset2, ...);

Merge one or more charsets.  The result contains every character of any set, but clamped to
the L<max_codepoint> of the current set.

The arguments may also be plain inversion list arrayrefs instead of charset objects.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.02

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
