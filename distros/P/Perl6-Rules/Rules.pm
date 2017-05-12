package Perl6::Rules;
use 5.008_003;
use re 'eval';
use Carp;
# use strict;
use charnames ':full';
use utf8;

our $VERSION = '0.03';

# Support for these properties on interpolated hashes...

our (%keymatch, %valuematch);

# Are we debugging or translating?

our ($debug, $translate) = (0,0);

# Did we get an error?

my $bad = 0;

# Turn off special $0 magic

*0 = \ my $zero;

# Reset state package variables
# (only used during filtering so no need for reentrancy)

our (@p5pat, $raw, %mod, @mark, @capindex, %caps, $nextcapindex, $rulename);
our $rule_id = 2;
our @rules = qr{(?{die "No successful <prior> rule\n"})(?!)};
our $prior = 0;
our $has_prior;

sub new {
	@p5pat = "";
	$raw = "";
	%mod = (pre=>{}, post=>{});
	@mark = ();
	@capindex = ();
	%caps = ();
	$nextcapindex = 1;
	$rulename = "";
	$has_prior = 0;
}


# Use this sub instead of C<die>, so as to allow multiple error
# messages before dying...

sub error {
	print {*STDERR} @_, "\n";
	$bad++;
}


# Print debug info only if debugging...

sub debug {
	return unless $debug;
	my $mesg = join "", map { defined $_ ? $_ : '<undef>'} @_;
	$mesg .= "\n" unless substr($mesg,-1) eq "\n";
	print STDERR $mesg;
}

sub add_debug {
    my $what = quotemeta $_[1];
    $_[0] = "(?:(?{print STDERR qq{Trying $what...\\n}})"
          . $_[0]
          . "(?{print STDERR qq{...Matched $what\\n}}))"
        if $debug==1;   # Higher value indicates inside codeblock or assertion.
}

# Remember left delimiter and predict right delimiter...

our ($ldel, $rdel);

sub delim {
	($ldel, $rdel) = ($^N)x2;
	$rdel =~ tr/{[(</}])>/;
}


# Record another component of the raw Perl 6 pattern
# and add its back-translation to the Perl 5 pattern...

sub add {
	my ($p6pat, $p5pat) = @_;
	debug "Translating /$p6pat/ back to /$p5pat/\n";
	$raw .= $p5pat;
	add_debug $p5pat, "/$p6pat/";
	push @p5pat, $p5pat;
}


# Convert internal vars in subscripts from P6 to P5 syntax...

sub translate_vars_internal {
	my ($src) = @_;
	my ($next, $newsrc);
	while (1) {
		$next = index($src,'$?');
		$next = index($src,'@?') if $next < 0;
		$next = index($src,'%?') if $next < 0;
		if ($next < 0) {
			$newsrc .= $src;
			last;
		}
		$newsrc .= substr($src,0,$next,"");		# shift off and delete
		$next=2;
		while ($next < length $src) {
			my $char = lc substr($src,$next,1);
			last unless $char ge 'a' && $char le 'z' 
						|| $char ge '0' && $char le '9'
						|| $char eq '_';
			$next++;
		}
		my $var = substr($src,0,$next,"");	# shift off and delete
		my $follow1 = substr($src,0,1);
		my $follow2 = substr($src,0,2);
		if (substr($var,0,2) eq '$?') {
			if ($follow2 eq '.{' || $follow2 eq '.[') {     #}]
				substr($src,0,1,"");			# delete optional dot
			}
			$newsrc .= "\$Perl6::Rules::d0{'$var'}";
		}
		elsif (substr($var,0,2) eq '@?') {
			if ($follow1 eq '[') {							#]
				$newsrc .= "\$Perl6::Rules::d0{'$var'}";
			}
			elsif ($follow2 eq '.[') {						#]
				$newsrc .= "\$Perl6::Rules::d0{'$var'}";
				substr($src,0,1,"");			# delete optional dot
			}
			else {
				$newsrc .= "\@{\$Perl6::Rules::d0{'$var'}}";
			}
		}
		else {   # %?var
			if ($follow1 eq '{') {							#}
				$newsrc .= "\$Perl6::Rules::d0{'$var'}";
			}
			elsif ($follow2 eq '.{') {						#}
				$newsrc .= "\$Perl6::Rules::d0{'$var'}";
				substr($src,0,1,"");			# delete optional dot
			}
			else {
				$newsrc .= "\%{\$Perl6::Rules::d0{'$var'}}";
			}
		}
	}
	return $newsrc;
}

# Record that next component of the raw Perl 6 pattern is an
# interpolated scalar, and add its back-translation to the Perl 5 pattern.
# This sub handles translation of both /$as_literal/ and /<$as_rules>/
# scalar interpolations...

sub addscalar_external {
	my ($var, $quotemeta) = @_;
	$quotemeta ||= "";

	# Record original...
	$raw .= $var;

	my $subscripts="";
	my ($p5pat, $subscriptpos);

	# Translate Perl6ish @array[...] or %hash{...}
	# to Perl5ish $array[...]/$hash{...}...
	my $special = substr($var,0,1);
	if ($special eq '@') {
		$subscriptpos = index($var,".[");
		$subscriptpos = index($var,"[") unless $subscriptpos > 0;
		$subscripts = translate_vars_internal substr($var,$subscriptpos);
		substr($var,$subscriptpos) = "";
		$p5pat = $subscripts ? '$' . substr($var,1) . $subscripts : $var;
	}
	elsif ($special eq '%') {
		$subscriptpos = index($var,".{");
		$subscriptpos = index($var,"{") unless $subscriptpos > 0;
		$subscripts = translate_vars_internal substr($var,$subscriptpos);
		substr($var,$subscriptpos) = "";
		$p5pat = $subscripts ? '$' . substr($var,1) . $subscripts : $var;
	}

	# Translate Perl6ish $ref.{...} to Perl5ish $ref->[...] ...
	elsif (($special = index($var,'.')) > 0) {
		$p5pat = substr($var,0,$special)
			   . "->"
			   . translate_vars_internal(substr($var,$special+1));
	}

	# Translate Perl6ish $ref{...} or $ref[...]
	# to Perl5ish $ref->{...} or $ref->[...]
	elsif (($special = index($var,'[')) > 0 or
	       ($special = index($var,'{')) > 0 ) {
		$p5pat = substr($var,0,$special)
			   . "->" 
			   . translate_vars_internal(substr($var,$special));
	}
	else {
		$p5pat = $var;
	}

	# Quotemeta interpolation as required...
	$p5pat = $quotemeta eq 'rw' ? $p5pat : qq{(??{$quotemeta $p5pat})};

	# Insert debugging code if appropriate...
	add_debug $p5pat, "/$var/";

	# Add back-translation...
	my $what = $quotemeta ? "literal" : "pattern";
	debug "Adding $var (as $what interpolation)\n";

	push @p5pat, $p5pat;
}

sub addscalar_internal {
	my ($var, $quotemeta) = @_;
	$quotemeta ||= "";

	my $subscripts="";

	# Record original...
	$raw .= $var;

	my ($p5pat, $subscriptpos);

	# Translate Perl6ish @?array[...] or %?hash{...}
	my $special = substr($var,0,2);
	if ($special eq '@?') {
		$subscriptpos = index($var,".[");
		$subscriptpos = index($var,"[") unless $subscriptpos > 0;
		$subscripts = translate_vars_internal substr($var,$subscriptpos);
		substr($var,$subscriptpos) = "";
		$p5pat = $subscripts ? "\$Perl6::Rules::d0{q{$var}}->$subscripts"
						     : "\@{\$Perl6::Rules::d0{q{$var}}}";
	}
	elsif ($special eq '%?') {
		$subscriptpos = index($var,".{");
		$subscriptpos = index($var,"{") unless $subscriptpos > 0;
		$subscripts = translate_vars_internal substr($var,$subscriptpos);
		substr($var,$subscriptpos) = "";
		$p5pat = $subscripts ? "\$Perl6::Rules::d0{q{$var}}->$subscripts"
						     : "\%{\$Perl6::Rules::d0{q{$var}}}";
	}

	# Translate Perl6ish $ref.{...} to Perl5ish $ref->{...} ...
	elsif (($special = index($var,'.')) > 0) {
		$subscripts = substr($var,$special+1);
		$subscripts = translate_vars_internal $subscripts;
		substr($var,$special) = "";
		$p5pat = "\$Perl6::Rules::d0{q{$var}}->$subscripts";
	}

	# Translate Perl6ish $ref{...} or $ref[...]
	# to Perl5ish $ref->{...} or $ref->[...]
	elsif (($special = index($var,'[')) > 0 or
	       ($special = index($var,'{')) > 0 ) {
		$subscripts = translate_vars_internal substr($var,$special);
		substr($var,$special) = "";
		$p5pat = "\$Perl6::Rules::d0{q{$var}}->$subscripts";
	}
	else {
		$p5pat = "\$Perl6::Rules::d0{q{$var}}";
	}

	# Quotemeta interpolation as required...
	$p5pat = $quotemeta eq 'rw' ? $p5pat : qq{(??{$quotemeta $p5pat})};

	# Insert debugging code if appropriate...
	add_debug $p5pat, "/$var/";

	# Add back-translation...
	my $what = $quotemeta ? "literal" : "pattern";
	debug "Adding $var (as $what interpolation)\n";

	push @p5pat, $p5pat;
}


# Record that next component of the raw Perl 6 pattern is an
# interpolated array, and add its back-translation to the Perl 5 pattern.
# This sub handles translation of both /@::as_literals/ and /<@::as_rules>/
# array interpolations...

sub addarray_external {
	my ($var, $quotemeta) = @_;
	$quotemeta = $quotemeta ? "map $quotemeta," : "map \$_,";

	# Record original...
	$raw .= $var;

	# Expand elements of variable, conjoining with ORs...
	my $p5pat = qq{(??{join q{|}, $quotemeta $var})};
	add_debug $p5pat, "/$var/";

	# Insert debugging code if requested...
	my $what = $quotemeta eq 'map quotemeta,' ? "literal" : "pattern";

	# Add back-translation...
	debug "Adding $var (as $what interpolation)\n";
	push @p5pat, $p5pat;
}

sub addarray_internal {
	my ($var, $quotemeta) = @_;
	$quotemeta = $quotemeta ? "map $quotemeta," : "map \$_,";

	# Record original...
	$raw .= $var;

	# Expand elements of variable, conjoining with ORs...
	my $p5pat = qq{(??{join q{|}, $quotemeta \@{\$Perl6::Rules::d0{q{$var}}}})};
	add_debug $p5pat, "/$var/";

	# Insert debugging code if requested...
	my $what = $quotemeta eq 'map quotemeta,' ? "literal" : "pattern";

	# Add back-translation...
	debug "Adding $var (as $what interpolation)\n";
	push @p5pat, $p5pat;
}


sub addhash_internal {
	my ($var, $quotemeta) = @_;
	my $hashaccess = "getcap_name(q{$var})->";

	# Construct value matcher...
	# (Properties on internal hashes are not supported, so no
	#  need to test for keymatch or valuematch)
	my $valhandler = # Match one of the keys...
		   		     '(??{exists ' . $hashaccess . '{$^R} ? '
		   			 # and match against the corresponding value, or fail
		 		   . $hashaccess . '{$^R} : "(?!)"})'
		;

	# Construct the Perl 5 equivalent...
				# Match any of the hash's keys (or its keymatch property)...
	my $p5pat = '(?> ((?> \w+ )) (?{$^N})'
				# Then match the corresponding value (or valuematch property)...
		      . $valhandler . ')';

	# Insert debugging info if requested...
	my $what = $quotemeta ? "literal" : "pattern";

	# Add back-translation...
	debug "Adding $var (as $what interpolation)\n";
	add_debug $p5pat, "/$var/";
	push @p5pat, $p5pat;
}

sub addhash_external {
	my ($var, $quotemeta) = @_;

	# Record original...
	$raw .= $var;

	# Convert to Perl5 access syntax...
	my $hashaccess = '$'.substr($var,1);

	# Construct value matcher...
	my $valhandler = $quotemeta 
		# If hash has properties controlling interpolation...
		?  '(??{exists ' . $hashaccess . '{$^N} ? "" : "(?!)"})'
		   # Get the specified value matcher and match with it...
		 . '((?> (??{Perl6::Rules::valuematch(\\' . $var. ')}) ))'
		   # Fail if no such specified value matcher or if it fails...
		 . '(??{!defined($^R)||' . $hashaccess . '{$^R} eq $^N ? "" : "(?!)"})'
		# Otherwise do normal hash interpolation...
		   # Match one of the keys...
		:  '(??{exists ' . $hashaccess . '{$^R} ? '
		   # and match against the corresponding value, or fail
		 . $hashaccess . '{$^R} : "(?!)"})'
		;

	# Construct the Perl 5 equivalent...
				# Match any of the hash's keys (or its keymatch property)...
	my $p5pat = '(?> ((?> (??{Perl6::Rules::keymatch(\\' . $var
			  . ')}) )) (?{$^N})'
				# Then match the corresponding value (or valuematch property)...
		      . $valhandler . ')';

	# Insert debugging info if requested...
	my $what = $quotemeta ? "literal" : "pattern";

	# Add back-translation...
	debug "Adding $var (as $what interpolation)\n";
	add_debug $p5pat, "/$var/";
	push @p5pat, $p5pat;
}

sub keymatch {
	my ($hashref) = @_;
	my $keymatch = exists $keymatch{$hashref}
		? eval $keymatch{$hashref}
		: qr{\w+};
	debug "Matching hash key with: $keymatch\n";
	return $keymatch;
}

sub valuematch {
	my ($hashref) = @_;
	return qr{(?{undef $^R})} unless exists $valuematch{$hashref};
	my $valuematch = eval $valuematch{$hashref};
	debug "Matching hash value with: $valuematch\n";
	return $valuematch;
}

our $wordsp = '(?:(?<=\w)(?:\s+(?=\w)|\s*(?=\W|\z))|(?<=\W)\s*|\A\s*)';
sub wordspace {
	return unless $mod{words};
	debug "Inserting space matching /$raw <-- HERE/\n";
	my $pat = '(??{$Perl6::Rules::wordsp})';
	add_debug $pat, "Skipping whitespace";
	push @p5pat, "(?:$pat)";
}

my @failure;
sub fallible { push @failure, 0 }
sub fail     { no warnings; debug "Failed"; $failure[-1] = 1; last FALLIBLE }
sub failed   { pop(@failure) ? '(?!)' : '' }

{ no strict 'refs'; *{caller()."::fail"} = \&fail; }

sub codeblock {
	my ($type, $nested) = @_;
	debug "Closed $type block";
	$raw .= $type;
	my $mark = pop @mark;
	my $code = join "", splice @p5pat, $mark, @p5pat-$mark;
	if ($nested) {
		push @p5pat, "{$code}";
		return;
	}
	$code = "do{$code}||fail" if $type eq ')>';
	debug "Translated $type block to '$code'";
	$code = "(??{Perl6::Rules::fallible;FALLIBLE:{$code}Perl6::Rules::failed})";
	add_debug $code, "codeblock";
	push @p5pat, $code;
}

sub alternative {
	$raw .= '|';
	push @p5pat, '|';
}

sub subrule {
	my ($subrule, $repeat, $capture, $negate) = @_;
	my $p6pat = "$subrule$repeat";
	$p6pat = "($p6pat)" if $capture;
	$raw .= $p6pat;
	$negate ||= "";

	my ($classname, $rulename);
	if ((my $index = index($subrule,'.'))>0) {
		$classname = substr($subrule,0,$index);
		$rulename  = substr($subrule,$index+1);
	}
	else {
		$classname = '__PACKAGE__';
		$rulename  = $subrule;
	}
	my $callrule;
	if ($rulename eq 'prior') {
		error "Don't know how to match inverted <-prior>" if $negate eq '-';
		$callrule = '(??{$Perl6::Rules::rules[$Perl6::Rules::prior]||"(?!)"})';
		$has_prior = 1;
	}
	elsif ($rulename eq 'self') {
		error "Don't know how to match inverted <-self>" if $negate eq '-';
		$callrule = "(?>(??{\$Perl6::Rules::rules[$rule_id]}))";
	}
	else {
		$callrule = $negate eq "-"
			?  "(??{$classname->can(q{$rulename})?$classname->$rulename(invert=>1):Perl6::Rules::stdrule(q{$subrule},1)})" 
			: "(??{$classname->can(q{$rulename})?$classname->$rulename():Perl6::Rules::stdrule(q{$subrule})})";
	}
	$repeat = trans_repeat($repeat) if $repeat;

	# Save and restore match variables...

	$callrule = "(?:(?{local \%Perl6::Rules::d0 = \%Perl6::Rules::d0;local \@Perl6::Rules::d0 = \@Perl6::Rules::d0;Perl6::Rules::save_d0})$callrule(?{Perl6::Rules::restore_d0}))";

	my $storage = "\$Perl6::Rules::d0{q{\$?$rulename}}";
	if ($repeat && $capture) {
		push @p5pat, "(?{local $storage = []})(?:$callrule(?{Perl6::Rules::apparray([$storage], \$0)}))$repeat";
	}
	elsif ($repeat) {
		push @p5pat, "$callrule$repeat";
	}
	elsif ($capture) {
		push @p5pat, "($callrule)(?{local $storage = $storage; $storage = \$0})";
	}
	else {
		push @p5pat, $callrule;
	}
	if ($negate eq '!') {
		$p5pat[-1] = "(?!$p5pat[-1])";
	}
	add_debug $p5pat[-1], "/$p6pat/";
}

my %sigil = ( '$'=>1, '%'=>1, '@'=>1 );

sub trans_repeat {
	my ($rep) = @_;
	return "" unless $rep;
	my ($from, $to);
	if (substr($rep,0,1) eq '<') {
		my $comma = index $rep, ",";
		if ($comma > 0) {
			$from = substr($rep,1,$comma-1);
			chop($to = substr($rep,$comma+1));
			error "The use of variables in repetitions is not yet supported: <$from,$to>"
				if grep { $sigil{substr($_,0,1)} } $from, $to;
		}
		else {
			chop($from = substr($rep,1));
			$to   = $from;
			error "The use of variables in repetitions is not yet supported: <$from>"
				if $sigil{substr($from,0,1)};
		}
		#SHOULD BE: $from = "(??{$from})" if substr($from,0,1) eq '$';
		#SHOULD BE: $to   = "(??{$to})"   if substr($to,0,1) eq '$';
		$rep = "{$from,$to}";
	}
	return $rep;
}

sub nobacktrack {
	$p5pat[-1] = "(?>$p5pat[-1])";
}

sub repeat {
	$raw .= $^N;
	my $rep = trans_repeat($^N);
	$p5pat[-1] = "(?:$p5pat[-1])" if length($p5pat[-1]||"") > 1;
	$p5pat[-1] .= $rep;
}

sub setcapindex {
	$nextcapindex = shift;
}

sub capmark {
	my ($name) = @_;
	my $sigil = @capindex ? substr($capindex[-1],0,1) : ""; 
	push @capindex, ($name ? $name : $nextcapindex++)
		  unless $sigil && ($sigil eq '@' || $sigil eq '%');
	push @mark, scalar @p5pat;
	$raw .= "$name := " if $name;
	$raw .= '(';
}

sub mark {
	my ($type) = @_;
	debug "Opening $type block\n";
	push @mark, scalar @p5pat;
	$raw .= $type;
}

sub lookaround {
	my ($type) = @_;
	my $mark = pop @mark;
	splice @p5pat, $mark, @p5pat-$mark, "$type@p5pat[$mark..$#p5pat])";
	$raw .= '>';
}

sub make_charset {
	$raw .= '>';
	my $mark = pop @mark;
	my (@neg, @pos);
	for (splice @p5pat, $mark, @p5pat-$mark) {
		push @neg, @{$_->[0]};
		push @pos, @{$_->[1]};
	}
	push @p5pat, '(?:';
	$p5pat[-1] .= join "", map "(?!$_)", @neg if @neg;
	$p5pat[-1] .= @pos ? '(?:' . join('|', @pos) . ')' : '(?s:.)';
	$p5pat[-1] .= ')';
	debug "Emitted char class: /$p5pat[-1]/\n";
}

sub capture_internal {
	return unless @mark;    # Implies unbalanced closing paren
	my $index = $capindex[-1];
	my $sigil = substr($index,0,1);
	my $subsigil = substr($index,1,1);
	goto &capture_external if $subsigil ne '?';
	$raw .= ')';
	my $mark = pop @mark;
	pop @capindex unless $sigil eq '@' || $sigil eq '%';
	my $action;
	my $storage = "\$Perl6::Rules::d0{q{$index}}";
	if ($sigil eq '$') {
		$action = "local $storage = \$^N";
	}
	elsif ($sigil eq '@') {
		$action = "local $storage = $storage; Perl6::Rules::apparray($storage, \$^N)";
	}
	elsif ($sigil eq '%') {
		$action = "local $storage = $storage; Perl6::Rules::apphash($storage, \$^N)";
	}
	else {
		$action = "local \$Perl6::Rules::d0[$index] = \$^N";
	}
	splice @p5pat, $mark, @p5pat-$mark, "(@p5pat[$mark..$#p5pat])(?{$action})";
}

# Translate \c[...] and \C[...] back to Perl5ish \N{...} and [^\N{...}]

my %trans = (
	'\c' => sub { '(?-x:\N{'.$_.'})' },
	'\C' => sub { '(?s-x:(?!\N{'.$_.'}).)' },
	'\x' => sub { sprintf '\x{%0.4s}', $_ },
	'\X' => sub { sprintf '[^\x{%0.4s}]', $_ },
	'\0' => sub { sprintf '\x{%0.4x}', oct $_ },
);

sub transchars {
	my ($pat) = @_;

	# Positive blocky escapes...
	for my $esc (qw(\c \x \0)) {
		my $esclen = length($esc)+1;
		while (1) {
			my $from = index($pat, $esc.'[');
			last unless $from >= 0;
			my $to = index(substr($pat,$from+$esclen),']');
			error("Empty $esc\[...]") and last if $to == 0;
			substr($pat,$from,$to+$esclen+1) =
				join "", map { $trans{$esc}() }
						 map { split ';', $_  }
						 map { split '; ', $_ }
							substr($pat,$from+$esclen,$to);
		}
	}

	# Negative blocky escapes...
	for my $esc (qw(\C \X)) {
		my $esclen = length($esc)+1;
		while (1) {
			my $from = index($pat, $esc.'[');
			last unless $from >= 0;
			my $to = index(substr($pat,$from+$esclen),']');
			error("Empty $esc\[...]") and last if $to == 0;
			my @chars =  map { split ';', $_  }
						 map { split '; ', $_ }
							substr($pat,$from+$esclen,$to);
			my $after = @chars > 1
							? join("",map $trans{lc $esc}(), @chars[1..$#chars])
							: "";
			substr($pat,$from,$to+$esclen+1) =
				"(?:" . do{local $_=$chars[0]; $trans{$esc}()} . $after . ")";
		}
	}
	return $pat;
}

my ($cs_excl, $cs_incl) = (0,1);

sub transcharset {
	my ($pat, $sign) = @_;
	my $neg = $sign eq '-' ? 1 : 0;

	my @result = ([],[]);

	for my $esc ($neg ? qw(\C \X) : qw(\c \x \0)) {
		my $esclen = length($esc)+1;
		while (1) {
			my $from = index($pat, $esc.'[');
			last unless $from >= 0;
			my $to = index(substr($pat,$from+$esclen),']');
			error("Empty $esc\[...]") and last if $to == 0;
			push @{$result[$cs_incl]},
				join "", map { $trans{lc $esc}() }
				 		 map { split ';', $_  }
				 		 map { split '; ', $_ }
							 substr($pat,$from+$esclen,$to);
			substr($pat,$from,$to+$esclen+1) = "";
		}
	}

	for my $esc ($neg ? qw(\c \x \0) : qw(\C \X)) {
		my $esclen = length($esc)+1;
		while (1) {
			my $from = index($pat, $esc.'[');
			last unless $from >= 0;
			my $to = index(substr($pat,$from+$esclen),']');
			error("Empty $esc\[...]") and last if $to == 0;
			push @{$result[$cs_excl]},
				join "", map { $trans{lc $esc}() }
				 		 map { split ';', $_  }
				 		 map { split '; ', $_ }
							 substr($pat,$from+$esclen,$to);
			substr($pat,$from,$to+$esclen+1) = "";
		}
	}

	unshift @{$result[$neg ? $cs_excl : $cs_incl]}, $pat unless $pat eq '[]';
	return \@result;
}


# Handle declaration of (...) captures

sub capture_external {
    return unless @mark;    # Implies unbalanced closing paren
    $raw .= ')';
    my $mark = pop @mark;
    my $index = $capindex[-1];
    my $sigil = substr($index,0,1);
    pop @capindex unless $sigil eq '@' || $sigil eq '%';
    my $action;
    if ($sigil eq '$') {
        $action = "\$Perl6::Rules::exvar{scalar}{q{$index}}||=\\$index;"
                . "local $index = \$^N";
    }
    elsif ($sigil eq '@') {
        $action = "\$Perl6::Rules::exvar{array}{q{$index}}||=\\$index;"
                . "local $index=$index; Perl6::Rules::apparray(\\$index, \$^N)";
    }
    elsif ($sigil eq '%') {
        $action = "\$Perl6::Rules::exvar{hash}{q{$index}}||=\\$index;"
                . "local $index=$index; Perl6::Rules::apphash(\\$index, \$^N)";
    }
    else {
        $action = "local \$Perl6::Rules::d0[$index] = \$^N";
    }
    splice @p5pat, $mark, @p5pat-$mark, "(@p5pat[$mark..$#p5pat])(?{$action})";
}

my %nametype = (
    '@' => 'array',
    '%' => 'hash',
    '$' => 'scalar',
);

sub caparraymark_external {
    my ($name) = @_;
    debug "Setting $name as capture target";
    $raw .= "$name := [";
    push @capindex, $name;
    push @mark, scalar @p5pat;
    my $sigil = substr($name,0,1);
    my $save = "\$Perl6::Rules::exvar{$nametype{$sigil}}{q{$name}}||=\\$name";
    push @p5pat, "(?{$save;local $name = ($name,undef)})";
}

sub caparraymark_internal {
    my ($name) = @_;
    debug "Setting $name as capture target";
    $raw .= "$name := [";
    push @capindex, $name;
    push @mark, scalar @p5pat;
    my $storage = "\$Perl6::Rules::d0{q{$name}}";
    push @p5pat, "(?{local $storage = [\@{$storage},undef]})";
}

sub endcaparraymark {
    return unless @mark;    # Implies unbalanced closing paren
    $raw .= ']';
    my $mark = pop @mark;
    my $name = pop @capindex;
    splice @p5pat, $mark, @p5pat-$mark, "(?:@p5pat[$mark..$#p5pat])";
}

sub caphashmark_external {
    my ($name) = @_;
    debug "Setting $name as capture target";
    $raw .= "$name := [";
    push @capindex, $name;
    push @mark, scalar @p5pat;
    my $sigil = substr($name,0,1);
    my $save = "\$Perl6::Rules::exvar{$nametype{$sigil}}{q{$name}}||=\\$name";
    push @p5pat, "(?{$save;local $name = ($name, ''=>undef)})";
}

sub caphashmark_internal {
    my ($name) = @_;
    debug "Setting $name as capture target";
    $raw .= "$name := [";
    push @capindex, $name;
    push @mark, scalar @p5pat;
    my $storage = "\$Perl6::Rules::d0{q{$name}}";
    push @p5pat, "(?{local $storage = {\%{$storage}, ''=>undef}})";
}

sub endcaphashmark {
    return unless @mark;    # Implies unbalanced closing paren
    $raw .= ']';
    my $mark = pop @mark;
    my $name = pop @capindex;
    splice @p5pat, $mark, @p5pat-$mark, "(?:@p5pat[$mark..$#p5pat])";
}

sub noncapture {
    return unless @mark;    # Implies unbalanced closing square bracket
    $raw .= ']';
    debug "Closing non-capturing block\n";
    my $mark = pop @mark;
    splice @p5pat, $mark, @p5pat-$mark, "(?:@p5pat[$mark..$#p5pat])";
    add_debug $p5pat[-1], "non-capturing block";
}

sub rulename {
    $rulename = $^N;
}

sub empty {
    error "Empty pattern not allowed (use /<null>/ or /<prior>/)";
}

sub badrep {
    error "Invalid quantifier: /$raw$^N <--HERE .../";
    $raw .= $^N;
}

sub invalid {
    error "Invalid Perl 6 pattern (perhaps mismatched brackets?): $_[0]";
}

# Parser starts here...

our $comment  = q{[#][^\n]*};           # Comment

our $ws    = qr{(?:$comment|\s)+};      # WhiteSpace
our $ows   = qr{(?:$comment|\s)*};      # Optional WhiteSpace
our $ident = qr{(?>[^\W\d]\w*)};        # Identifier
our $int   = qr{(?:\d+|\$$ident)};      # Integer for range
our $rrep  = qr{<$int(?:,$int?)?>};     # Range repeater

our $qualident = qr{(?> $ident? (?: :: $ident)+ )}x;     # Qualified identifier
our $callident = qr{(?> $ident (::$ident)* (?:\.$ident)? )}x;
                                                        # Qualified Perl6 call

our $rep   = qq{((?:[*+?]|$rrep)[?]?)};
our $orep  = qq{((?:[*+?]|$rrep)?[?]?)};
our $stdrep  = qq{$orep (?{repeat})};   # Optional repeater

our $sliteral = q{[-\w~`!=;"',]};       # Literal for a Slash-delimited pattern
our $bliteral = q{[-\w~`!=;"',/]};      # Literal for a Bracketed pattern

our $bracket = q{\[|\]|\{|\}|\<|\>|\(|\)};     # Any bracket

our $squareblock = qr{ \[ (?: (?> (?:[^][]|\\.)+ ) | (??{$squareblock}) )* \] }x;
our $braceblock  = qr{ \{ (?: (?> (?:[^{}]|\\.)+ ) | (??{$braceblock}) )* \} }x;
our $parenblock  = qr{ \( (?: (?> (?:[^()]|\\.)+ ) | (??{$parenblock}) )* \) }x;
our $angleblock  = qr{ \< (?: (?> (?:[^<>]|\\.)+ ) | (??{$angleblock}) )* \> }x;
our $slashblock  = qr{        (?> (?:[^/]|\\.)*  ) / }x;

our $delimblock  = qr{ $braceblock
                 | $squareblock
                 | $parenblock
                 | $angleblock
                 }x;

our $charset = qr{ \[ \]? (?:\\[cCxX]\[ [^]]* \]|\\.|[^]])* \] }xs;

our $mods = qr{ (?> (?: : \w+ (?: $parenblock? ) )* ) }x;

# These would be preferrable, but are not reliable...
# 	our $newline    = qr{(?:\015\012?|[\012\x85\x2028])};
#	our $notnewline = qr{(?:(?!\015\012?|[\012\x85\x2028])[\s\S])};
# So we cheat with these instead...

our $newline    = qr{\n};
our $notnewline = qr{[^\n]};

our %ews = (                # Explicit WhiteSpace
    q{\h}   => q{[ \t\r]},
    q{\v}   => $newline,
    q{\s}   => q{(?:\015\012?|[\s\012\x85\x2028])},
    q{<ws>} => q{(?:\s+)},
    q{<sp>} => q{[ ]},
);

our $ews = '(?:' . join('|',map quotemeta, keys %ews) . ')';

# Internal scalars...
our $i_scalar   = qr{ (?: \$ \? $ident
                        | \@ \? $ident $squareblock
                        | \% \? $ident $braceblock
                      )
                      (?: \.? (?>$squareblock|$braceblock) )*
                    }x;
our $i_array    = qr{ \@ \? $ident }x;
our $i_hash     = qr{ \% \? $ident }x;

# External scalars...
our $e_scalar   = qr{ (?: \$ $qualident
                        | \@ $qualident $squareblock
                        | \% $qualident $braceblock
                      )
                    (?: (?:\.)? (?>$squareblock|$braceblock) )*
                  }x;
our $e_array    = qr{ \@ $qualident }x;
our $e_hash     = qr{ \% $qualident }x;

# Unqualified externals not allowed...

our $bad_var    = qr{ [\$\@%] $ident (?! :) }x;

our $codeblock = qr{
    (?{$debug = 2 if $debug})
    (\{) (?{mark($^N)})
    (?>
        (?: ($i_scalar) (?{addscalar_internal $^N, 'rw'})
          | ($e_scalar) (?{addscalar_external $^N, 'rw'})
          | ($i_array)  (?{addarray_internal $^N, 'rw'})
          | ($e_array)  (?{addarray_external $^N, 'rw'})
          | ($i_hash)   (?{addhash_internal $^N, 'rw'})
          | ($e_hash)   (?{addhash_external $^N, 'rw'})
          | \$ (\d+)    (?{add '$'.$^N, "\$Perl6::Rules::d0[$^N]"})
          | ((?:\$\^\w+|[^{}\$]|\\[{}\$])+) (?{add $^N, $^N})
          | (??{$nestedcodeblock})
        )*
    )
    (?{$debug = 1 if $debug})
    (\}) (?{codeblock($^N)})
    |
    (??{$debug=1 if $debug;'(?!)'})
}x;

our $nestedcodeblock = qr{
    (\{) (?{mark($^N)})
    (?>
        (?: ($i_scalar) (?{addscalar_internal $^N, 'rw'})
          | ($e_scalar) (?{addscalar_external $^N, 'rw'})
          | ($i_array)  (?{addarray_internal $^N, 'rw'})
          | ($e_array)  (?{addarray_external $^N, 'rw'})
          | ($i_hash)   (?{addhash_internal $^N, 'rw'})
          | ($e_hash)   (?{addhash_external $^N, 'rw'})
          | ($bad_var)  (?{error("Can't use unqualified variable ($^N)")})
          | \$ (\d+)    (?{add '$'.$^N, "\$Perl6::Rules::d0[$^N]"})
          | ((?:\$\^\w+|[^{}\$]|\\[{}\$])+) (?{add $^N, $^N})
          | (??{$nestedcodeblock})
        )*
    )
    (\}) (?{codeblock($^N,'nested')})
}x;

our $assertblock = qr[
    (?{$debug=2 if $debug})
    (<\() (?{mark($^N)})
    (?>
        (?: ($i_scalar) (?{addscalar_internal $^N, 'rw'})
          | ($e_scalar) (?{addscalar_external $^N, 'rw'})
          | ($i_array)  (?{addarray_internal $^N, 'rw'})
          | ($e_array)  (?{addarray_external $^N, 'rw'})
          | ($i_hash)   (?{addhash_internal $^N, 'rw'})
          | ($e_hash)   (?{addhash_external $^N, 'rw'})
          | ($bad_var)  (?{error("Can't use unqualified variable ($^N)")})
          | \$ (\d+)    (?{add '$'.$^N, "\$Perl6::Rules::d0[$^N]"})
          | ((?:\$\^\w+|[^{\)\$]|\\[{\)\$])+) (?{add $^N, $^N})
          | (??{$nestedcodeblock})
        )*
    )
    (?{$debug=1 if $debug})
    (\)>) (?{codeblock($^N)})
    |
    (??{$debug=1 if $debug;'(?!)'})

]x;


our $bspat = qr{                # Bracketed and Slashed patterns

 # Explicit whitespace (possibly repeated)...

      $ows ($ews)
            (?{add $^N, $ews{$^N}})
      $stdrep $ows

 # Actual whitespace (insert :words spacing if in appropriate mode)...

    | $ws
            (?{wordspace}) 

 # Backreference as literal (interpolated $1, $2, etc.)...

    | \$ (\d+)
            (?{add '$'.$^N, "(??{quotemeta \$Perl6::Rules::d0[$^N]})"})
      $stdrep

 # Interpolated variable as literal...

    | ($i_scalar) (?{ addscalar_internal $^N, 'quotemeta' }) $stdrep
    | ($i_array)  (?{ addarray_internal $^N, 'quotemeta' })  $stdrep
    | ($i_hash)   (?{ addhash_internal $^N, 'quotemeta' })   $stdrep
    | ($e_scalar) (?{ addscalar_external $^N, 'quotemeta' }) $stdrep
    | ($e_array)  (?{ addarray_external $^N, 'quotemeta' })  $stdrep
    | ($e_hash)   (?{ addhash_external $^N, 'quotemeta' })   $stdrep
    | ($bad_var)  (?{error("Can't use unqualified variable ($^N)")})

 # Character class...

    | < (?: ([+-]?) (?{$^N||""}) ($charset)
            (?{mark ""; add "<$^R.$^N", transcharset($^N, $^R)})
		|   ([+-]?) (?{$^N||""}) < ([-!]? $ident) >
            (?{mark ""; add "<$^R.$^N", getprop($^N, $^R)})
		)
        (?: ([+-]?) (?{$^N||""}) ($charset)
            (?{add "$^R.$^N", transcharset($^N, $^R)})
		|   ([+-]?) (?{$^N||""}) < ([-!]? $ident) >
            (?{add "$^R.$^N", getprop($^N, $^R)})
		)*
      > 
            (?{make_charset})
      $stdrep

 # <(...)> assertion block...

    | $assertblock

 # Backreference as pattern (interpolated <$1>, <$2>, etc.)...

    | <(\$ \d+)>
            (?{add "<$^N>", error("Cannot interpolate $^N as pattern")})

 # Interpolate variable as pattern...

    | <($i_scalar)> (?{addscalar_internal $^N}) $stdrep
    | <($i_array)>  (?{addarray_internal $^N})  $stdrep
    | <($i_hash)>   (?{addhash_internal $^N})   $stdrep
    | <($e_scalar)> (?{addscalar_external $^N}) $stdrep
    | <($e_array)>  (?{addarray_external $^N})  $stdrep
    | <($e_hash)>   (?{addhash_external $^N})   $stdrep
    | <($bad_var)>  (?{error("Can't use unqualified variable (<$^N>)")})

 # Code block as action...

    | $codeblock

 # Code block as interpolated pattern...

    | <($braceblock)>
            (?{add $^N, "(??{Perl6::Rules::ispat do$^N})"}) 

 # Literal in <'...'> format...

    | <' ( [^'\\]* (\\. [^'\\])* ) '>
            (?{add "<'$^N'>", "\Q$^N\E"}) 

 # Match any Unicode character, regardless of :uN level...

    | (< \. >)
            (?{add $^N, '(?:\X)'})

 # Match newline or anything-but-newline...

    | \\n
            (?{add '\n', $newline}) $stdrep
    | \\N
            (?{add '\N', $notnewline}) $stdrep

 # Quotemeta's literal (\Q[...])...

    | \\Q ( $squareblock )
            (?{add "\\Q$^N", quotemeta substr($^N,1,-1)}) $stdrep

 # Named and numbered characters (\c[...], \C[...], \x[...], \0[...], etc)...

    | ( \\[cCxX0] $squareblock
      | \\[xX][0-9A-Fa-f]+
      | \\0[0-7]+
      )
            (?{add $^N,  transchars($^N)}) $stdrep

	| (\\[cCxX0] \[) (?{$^N}) ((?>.*))
			(?{error "Untermimated $^R...] escape: $^R$^N"})

 # Literal dot...

    | (\\.)
            (?{add $^N, $^N}) $stdrep

 # Backtracking limiter...

    | : (?=\s|\z)
            (?{nobacktrack})

 # Lexical insensitivity...

    | :i
            (?{add ":i", '(?i)'})

 # Continuation marker...

    | :c (?{add '\G'})

 # Other lexical flags (NOT YET IMPLEMENTED)...

    | :(u0|u1|u2|u3|w|p5)
            (?{error "In-pattern :$^N not yet implemented"})

 # Match any character...

    | \.
            (?{add '.', '[\s\S]'}) $stdrep

 # Start of line marker...

    | \^\^
            (?{add '^^', '(?:(?<=\n)|(?<=\A))'})

 # End of line marker...

    | \$\$
            (?{add '$$', '(?:(?<=\n)|(?=\z))'})

 # Start of string marker...

    | \^
            (?{add '^', '\A'})

 # End of string marker...

    | \$
            (?{add '$', '\z'})

 # Non-capturing subrule or property...

    | < ($callident) >
            (?{subrule($^N,"")}) $stdrep

    | < - ($callident) >
            (?{subrule($^N,"","","-")}) $stdrep

    | < ! ($callident) >
            (?{subrule($^N,"","","!")}) $stdrep

 # Capturing subrule...

    | < \? ($callident) >
            (?{$Perl6::Rules::srname=$^N})
      $ows $rep
            (?{ subrule($Perl6::Rules::srname, $^N, "cap")})
    | < \? ($callident) >
            (?{ subrule($^N, "", "cap")})

 # Alternative marker...

    | \|
            (?{alternative})

 # Comment...

    | $comment

 # Unattached repetition marker...

    | ($orep)
            (?{$^N&&badrep()})

}x;


our $spat   = qr{               # Slash-delimited pattern
 
 # A literal character...

    (?: ($sliteral)
            (?{add $^N, $^N}) $stdrep

 # Lookahead and lookbehind...

    |   (<before $ws)
            (?{mark $^N})
        (??{$spat}) >
            (?{lookaround('(?=')})

    |   (<!before $ws)
            (?{mark $^N})
        (??{$spat}) >
            (?{lookaround('(?!')})

    |   (<after $ws)
            (?{mark $^N})
        (??{$spat}) >
            (?{lookaround('(?<=')})

    |   (<!after $ws)
            (?{mark $^N})
        (??{$spat}) >
            (?{lookaround('(?<!')})

 # Named capture...

    |   \$ (\d+) $ows := $ows \(
            (?{setcapindex $^N; capmark})
        (??{$spat}) \)
            (?{capture_internal $^R})

    |   ($i_scalar) $ows := $ows \(
            (?{capmark $^N})
        (??{$spat}) \)
            (?{capture_internal $^R})

    |   ($e_scalar) $ows := $ows \(
            (?{capmark $^N})
        (??{$spat}) \)
            (?{capture_external $^R})

    |   ($i_array) $ows := $ows \(
            (?{caparraymark_internal $^N; capmark;})
        (??{$spat}) \)
            (?{capture_internal; endcaparraymark;})
        $stdrep

    |   ($e_array) $ows := $ows \(
            (?{caparraymark_external $^N; capmark;})
        (??{$spat}) \)
            (?{capture_external; endcaparraymark;})
        $stdrep

    |   ($i_array) $ows := $ows \[
            (?{caparraymark_internal $^N})
        (??{$spat}) \]
            (?{endcaparraymark})
        $stdrep

    |   ($e_array) $ows := $ows \[
            (?{caparraymark_external $^N})
        (??{$spat}) \]
            (?{endcaparraymark})
        $stdrep

    |   ($i_hash) $ows := $ows \(
            (?{caphashmark_internal $^N; capmark;})
        (??{$spat}) \)
            (?{capture_internal; endcaphashmark;})
        $stdrep

    |   ($e_hash) $ows := $ows \(
            (?{caphashmark_external $^N; capmark;})
        (??{$spat}) \)
            (?{capture_external; endcaphashmark;})
        $stdrep

    |   ($i_hash) $ows := $ows \[
            (?{caphashmark_internal $^N})
        (??{$spat}) \]
            (?{endcaphashmark})
        $stdrep

    |   ($e_hash) $ows := $ows \[
            (?{caphashmark_external $^N})
        (??{$spat}) \]
            (?{endcaphashmark})
        $stdrep

 # Other non-delimiter-specific constructs (as defined by $bspat above)...

    |   $bspat

 # Nameless capture...

    |   \(
            (?{capmark})
        (??{$spat}) \)
            (?{capture_internal})
        $stdrep

 # Non-capturing group...

    |   \[
            (?{mark '['})
        (??{$spat}) \]
            (?{noncapture})
        $stdrep
    )+
}x;

our $bpat   = qr{               # Bracketed pattern
    (?: 
 
 # A literal character...

        ($bliteral) (?{add $^N, $^N}) $stdrep

 # Lookahead and lookbehind...

    |   (<before $ws)
            (?{mark $^N})
        (??{$bpat}) >
            (?{lookaround('(?=')})

    |   (<!before $ws)
            (?{mark $^N})
        (??{$bpat}) >
            (?{lookaround('(?!')})

    |   (<after $ws)
            (?{mark $^N})
        (??{$bpat}) >
            (?{lookaround('(?<=')})

    |   (<!after $ws)
            (?{mark $^N})
        (??{$bpat}) >
            (?{lookaround('(?<!')})

 # Named capture...

    |   \$ (\d+) $ows := $ows \(
            (?{setcapindex $^N; capmark})
        (??{$bpat}) \)
            (?{capture_internal $^R})

    |   ($i_scalar) $ows := $ows \(
            (?{capmark $^N})
        (??{$bpat}) \)
            (?{capture_internal $^R})

    |   ($e_scalar) $ows := $ows \(
            (?{capmark $^N})
        (??{$bpat}) \)
            (?{capture_external $^R})

    |   ($i_array) $ows := $ows \(
            (?{caparraymark_internal $^N; capmark;})
        (??{$bpat}) \)
            (?{capture_internal; endcaparraymark;})
        $stdrep

    |   ($e_array) $ows := $ows \(
            (?{caparraymark_external $^N; capmark;})
        (??{$bpat}) \)
            (?{capture_external; endcaparraymark;})
        $stdrep

    |   ($i_array) $ows := $ows \[
            (?{caparraymark_internal $^N})
        (??{$bpat}) \]
            (?{endcaparraymark})
        $stdrep

    |   ($e_array) $ows := $ows \[
            (?{caparraymark_external $^N})
        (??{$bpat}) \]
            (?{endcaparraymark})
        $stdrep

 # Other non-delimiter-specific constructs (as defined by $bspat above)...

    |   $bspat

 # Nameless capture...

    |   \(
            (?{capmark})
        (??{$bpat}) \)
            (?{capture_internal})
        $stdrep

 # Non-capturing group...

    |   \[
            (?{mark '['})
        (??{$bpat}) \]
            (?{noncapture})
        $stdrep
    )+
}x;

our $rx = qr{

# Nameless rule requires {...} delimiters...

      \b rule $ows ($mods) (?{mods}) $ows
      (?> (\{) (?{delim}) (?: $ows \} (?{empty})|$bpat \} )
        | ( (?:\{|\[|\<|/) .*) (?{invalid('rx'.$^N)})
      )
      
# Nameless rx allows /.../ or any bracket delimiters...

    | \b rx   $ows ($mods) (?{mods}) $ows
      (?> (\{) (?{delim}) (?: $ows \} (?{empty})|$bpat \} )
        | (\[) (?{delim}) (?: $ows \] (?{empty})|$bpat \] )
        | (\<) (?{delim}) (?: $ows \> (?{empty})|$bpat \> )
        | (/)  (?{delim}) (?: $ows /  (?{empty})|$spat /  )
        | ( (?:\{|\[|\<|/) .*) (?{invalid('rx'.$^N)})
      )
}x;


our $match = qr{

# Match construct allows /.../ or any bracket delimiters...

      \b m \b $ows ($mods) (?{mods}) $ows
      (?> (\{) (?{delim}) (?: $ows \} (?{empty})|$bpat \} )
        | (\[) (?{delim}) (?: $ows \] (?{empty})|$bpat \] )
        | (\<) (?{delim}) (?: $ows \> (?{empty})|$bpat \> )
        | (/)  (?{delim}) (?: $ows /  (?{empty})|$spat /  )
        | ( (?:\{|\[|\<|/) .*) (?{invalid('m'.$^N)})
      )
}x;

our $subst = qr{

# Substitution construct allows /.../ or any bracket delimiters...

 \b s $ows ($mods) (?{mods}) $ows
 (?> (\{) (?{delim}) (?: $ows \} (?{empty})|$bpat \} ) ($delimblock)
   | (\[) (?{delim}) (?: $ows \] (?{empty})|$bpat \] ) ($delimblock)
   | (\<) (?{delim}) (?: $ows \> (?{empty})|$bpat \> ) ($delimblock)
   | (/)  (?{delim}) (?: $ows /  (?{empty})|$spat /  ) ($slashblock|$delimblock)
   | ( (?:\{|\[|\<|/) .*) (?{invalid('s'.$^N)})
 )
}x;


# Unimplemented modifiers...

my %unimpl;
@unimpl{qw(u0 u1 u2 u3 once p5 perl5)} = ();

# Limit interpolated rules to precompiled regexes
# (at least, until recursive rule translation can be made to work)...

sub ispat {
    my ($pat) = @_;
    warn qq{Cannot interpolate raw string "$pat" as pattern\n} and exit(1)
        unless (ref($pat)||"") eq 'Regexp';
    return $pat;
}

sub arepat { 
    ispat($_) for @_;
}


# Extract and translate rule modifiers

sub mods {
    my @mods = split ":", $^N;
    while (defined(my $mod = shift @mods)) {
        if ($mod eq 'words' || $mod eq 'w') {
            debug "Found skip-whitespace modifier (:$mod)\n";
            $mod{words} = 1;
        }
        elsif ($mod eq 'globally' || $mod eq 'g') {
            debug "Found match-all modifier (:$mod)\n";
            $mod{post}{g} = 1;
        }
        elsif ($mod eq 'exhaustive' || $mod eq 'e') {
            debug "Found match-every-way modifier (:$mod)\n";
            $mod{exhaust} = 1;
			error "Can't specify both :exhaustive and :overlap on the same rule"
				if $mod{overlap};
        }
        elsif ($mod eq 'overlap' || $mod eq 'o') {
            debug "Found match-overlapping modifier (:$mod)\n";
            $mod{overlap} = 1;
			error "Can't specify both :exhaustive and :overlap on the same rule"
				if $mod{exhaust};
        }
        elsif ($mod eq 'ignore' || $mod eq 'i') {
            debug "Found ignore-case modifier (:$mod)\n";
            $mod{post}{i} = 1;
        }
        elsif ($mod eq 'cont' || $mod eq 'c') {
            debug "Found match continuation modifier (:$mod)\n";
            $mod{pre}{'\G'} = 1;
            $mod{post}{gc}  = 1;
        }
        elsif (length $mod > 5 && substr($mod,0,4) eq 'nth(' && substr($mod,-1) eq ')') {
            $mod{nth} = substr($mod,4,-1);
            debug "Found $mod{nth}th repetition modifier (:$mod)\n";
        }
        elsif ( length $mod > 2 && substr($mod,0,1) ne 'n' &&
			    (substr($mod,-2) eq 'th' || substr($mod,-2) eq 'st' 
			    || substr($mod,-2) eq 'nd' || substr($mod,-2) eq 'rd')
			  ) {
            $mod{nth} = substr($mod,0,-2);
            debug "Found $mod{nth}th repetition modifier (:$mod)\n";
        }
        elsif (length $mod > 3 && substr($mod,0,2) eq 'x(' && substr($mod,-1) eq ')' ) {
            $mod{rep} = substr($mod,2,-1);
            debug "Found $mod{rep}-times repetition modifier (:$mod)\n";
        }
        elsif (length $mod > 1 && substr($mod,-1) eq 'x' ) {
            $mod{rep} = substr($mod,0,-1);
            debug "Found $mod{rep}-times repetition modifier (:$mod)\n";
        }
        elsif (substr($mod,0,3) eq "nth" or substr($mod,0,1) eq "x") {
            error "Missing parens after :$mod modifier";
        }
        elsif (exists $unimpl{$mod}) {
            error "The :$mod modifier is not currently implemented";
        }
        elsif (length($mod) > 1) {
            debug "Unknown modifier (:$mod). Trying to split.\n";
            unshift @mods, substr($mod,-1,1,"") while length $mod;
        }
        elsif (length $mod) {
            error "Unknown modifier (:$mod)"
        }
    }
}

# STD RULES AND PROPERTIES

my %stdrules = (
     alpha => qr{[^\W\d_]},
    -alpha => qr{[\W\d_]},
     space => qr{\s},
    -space => qr{\S},
     digit => qr{\d},
    -digit => qr{\D},
	 alnum => qr{[^\W_]},
	-alnum => qr{[\W_]},
	 ascii => qr{\p{InBasicLatin}},
	-ascii => qr{\P{InBasicLatin}},
	 blank => qr{[ \t\r]},
	-blank => qr{[^ \t\r]},
	 cntrl => qr{[[:cntrl:]]},
	-cntrl => qr{[^[:cntrl:]]},
	  ctrl => qr{[[:cntrl:]]},
	 -ctrl => qr{[^[:cntrl:]]},
	 graph => qr{[[:graph:]]},
	-graph => qr{[^[:graph:]]},
	 lower => qr{\p{Ll}},
	-lower => qr{\P{Ll}},
	 print => qr{[[:print:]]},
	-print => qr{[^[:print:]]},
	 punct => qr{\p{P}},
	-punct => qr{\P{P}},
	 upper => qr{\p{Lu}},
	-upper => qr{\P{Lu}},
	 word  => qr{\w},
	-word  => qr{\W},
	xdigit => qr{\p{HexDigit}},
   -xdigit => qr{\P{HexDigit}},

     ident => qr{[^\W\d]\w*},
      null => qr{(?=)},
);

# Locate back-translation for a std rule (like <alpha>)...

sub stdrule {
    my ($name, $invert) = @_;
	my $iname = $invert ? -$name : $name;
    my $stdrule = $stdrules{$iname};
	if (defined $stdrule) {
		debug "Matching <$iname> with subrule /$stdrule/\n";
		return qr{($stdrule) (?{$0=$^N})}x;
	}
	elsif (index($name,'.') >= 0) {
		die "Cannot match unknown named rule: <$iname>\n";
	}
	elsif ($invert) {
		$name = 'L&' if $name eq 'Lr';
		debug "Matching <$iname> with property \\P{$name}\n";
		return qr{\P{$name}};
	}
	else {
		$name = 'L&' if $name eq 'Lr';
 		debug "Matching <$iname> with property \\p{$name}\n";
		return qr{\p{$name}};
	}
}

# Locate back-translation for a std properties in a charset
# such as: <<alpha>+<digit>>...

my %stdprop = (
    alpha => '[^\W\d_]',
    digit => '\d',
	space => '\s',
	alnum => '[^\W_]',
	ascii => '\p{InBasicLatin}',
	blank => '[ \t\r]',
	cntrl => '[[:cntrl:]]',
	 ctrl => '[[:cntrl:]]',
	graph => '[[:graph:]]',
	lower => '\p{Ll}',
	print => '[[:print:]]',
	punct => '\p{P}',
	upper => '\p{Lu}',
	word  => '\w',
	xdigit => '\p{HexDigit}',
);

sub getprop {
	my ($name, $sign) = @_;
	my $neg = $sign eq '-' ? 1 : 0;
	my $insign = substr($name,0,1);
	my @result = ([],[]);

	if ($insign eq '-') {
		substr($name,0,1) = "";
		$neg = 1-$neg;
	}
	elsif ($insign eq '!') {
		substr($name,0,1) = "";
		error "Can't use negative lookahead <!$name> inside character class. "
		    . "Did you mean <-$name>?";
		return \@result;
	}

	$name = 'L&' if $name eq 'Lr';
	$result[$neg ? $cs_excl : $cs_incl][0] = $stdprop{$name} || "\\p{$name}";
	return \@result;
}


# Filter source to translate rules...

use Filter::Simple; our @CARP_NOT = 'Filter::Simple';
FILTER {
    return unless $_;
    $debug = 1 if grep /-debug\b/, @_;
    $translate = 1 if grep /-translate\b/, @_;
    $bad = 0;

    # Convert Perl6ish traits to Perl5ish attributes...

    s[ is $ws (keymatch|valuematch) $ows \( $ows (?:rx|rule) $ows ]
     [ :\u$1(]gx;

    # Convert Perl6ish grammars to Perl5ish packages

    s[grammar $ws ($qualident|$ident) (?: $ws is $ws ($qualident|$ident))? $ows \{ ]
     [ $2 ? "{ package $1; use base '$2'; no warnings 'regexp';"
          : "{ package $1; no warnings 'regexp';"
     ]gex;

    # Convert Perl6ish named rules to Perl5ish named subroutines...

    s[(?{new}) \b rule $ws ($ident) (?{rulename})
                       $ows ($mods?) (?{mods})
               $ows (\{) (?{delim}) $bpat \}
     ]
     [to_rule()]gex;

    # Convert Perl6ish unnamed rules and rx's to Perl5ish qr's...

    s[(?{new})($rx)]
     [to_qms('qr')]gex;

    # Convert Perl6ish matches to Perl5ish matches...

    s[(?{new})$match]
     [to_qms('m')]gex;

    # Convert Perl6ish substitutions to Perl5ish substitutions...

    s[(?{new})$subst]
     [to_qms('s',undef,$^N)]gex;

    # Convert references to $1, $2, $3, etc. to $0->[1], $0->[2], $0->[3], etc.

    our $curlies = qr/\{ (?: (?> [^}{]+) | (??{$curlies}))* \}/x;
    our $parens  = qr/\( (?: (?> [^)(]+) | (??{$parens }))* \)/x;
    our $squares = qr/\[ (?: (?> [^][]+) | (??{$squares}))* \]/x;
    our $angles  = qr/\< (?: (?> [^><]+) | (??{$angles }))* \>/x;

    my $non_interp_str = qr{ 
                         ' [^'\\]* (?: \\. [^'\\]* )*  '
      | q (?: [wxr]? \s* ' [^'\\]* (?: \\. [^'\\]* )*  '
            | w?     \s* / [^/\\]* (?: \\. [^/\\]* )*  /
            | w?     \s* ! [^!\\]* (?: \\. [^!\\]* )*  !
            | w?     \s* \# [^#\\]* (?: \\. [^#\\]* )* \#
            | w?     \s* \| [^|\\]* (?: \\. [^|\\]* )* \|
            | w?     \s* (?: $curlies | $parens | $squares | $angles)
          )
    }xs;

    s/ ( $non_interp_str )
     | (?<!\\) \$ ([1-9]\d*) (?=[^[{]) / $1 ? $1 : "\$0->[$2]"/gesx;

    # Fail if any errors were detected in any of that...

    if ($bad) {
        warn "Fatal error", ($bad>1?"s":""), " in one or more Perl 6 rules\n";
        exit($bad);
    }

    # Turn of regex warnings in the resulting filtered code
    # ('cos we did some wicked evil things in those back-translated regexes)...

    $_ = "no warnings 'regexp';use re 'eval';$_";

    # Show the resulting source if we're translating

    if ($translate) {
        warn "Source translated to:\n__START__\n" if $debug;
        print;
        print "\n__END__\n" if $debug;
        exit unless $debug;
    }
};

# Implement the C<is keymatch> and C<is valuematch> traits on hashes...

use Attribute::Handlers;

sub UNIVERSAL::Keymatch :ATTR(HASH,RAWDATA) {
    my ($package, $symbol, $referent, $attr, $data) = @_;

    # Prepend the anonymous pattern marker, if necessary...
    $data =~ s/^\s*(?!rx)/rx/;

    # Back-translate the resulting pattern...
    $data =~ s[(?{new})($rx)][to_qms('qr')]gex
        or croak 'Usage: %var : Keymatch(/pattern/)';

    # Cache the result...
    $keymatch{$referent} = $data;
}

sub UNIVERSAL::Valuematch :ATTR(HASH,RAWDATA) {
    my ($package, $symbol, $referent, $attr, $data) = @_;

    # Prepend the anonymous pattern marker, if necessary...
    $data =~ s/^\s*(?!rx)/rx/;

    # Back-translate the resulting pattern...
    $data =~ s[(?{new})($rx)][to_qms('qr')]gex
        or croak 'Usage: %var : Valuematch(/pattern/)';

    # Cache the result...
    $valuematch{$referent} = $data;
}

# Build a named Perl5ish subroutine/method that
# implements a named Perl6ish rule...

sub to_rule {
    local $" = "";
    my $trans = "sub $rulename { ". to_qms('qr',$rulename) . " }";
    return $trans;
}

# Wrap the back-translated elements of a Perl6ish pattern
# in the necessary Perl5ish regex magic...

sub to_qms {
    my ($type,$name,$repl) = @_;
    local $" = "";

    # /gc flag not possible on Perl5ish qr's...

    delete $mod{post}{gc} if $type eq "qr";

    # Default to a temporary name, if Perl6ish pattern is unnamed...

    $name ||= "anon_$type";



    # Prepare "decorations" for the back-translation...

    my $priorness = $has_prior ? "" : "\$Perl6::Rules::prior = $rule_id;";

	my $repcontrol =
		exists $mod{nth} && ($mod{post}{g} || $mod{post}{gc}) ?
				q[)(??{++$Perl6::Rules::count%].$mod{nth}.q[==0?'':'(?!)'})]
	  : exists $mod{nth} ?
				q[)(??{++$Perl6::Rules::count==].$mod{nth}.q[?'':'(?!)'})]
	  : exists $mod{rep} && $type eq 'm' ?
			(exists $mod{post}{gc}
				?  q[){].$mod{rep}.q[}]
				:  q[(?s:.*?)){].$mod{rep}.q[}]
			)
	  : exists $mod{rep} && $type eq 's' ?
				q[)(??{++$Perl6::Rules::count<=].$mod{rep}.q[?'':'(?!)'})]
	  :         q{};

	if (exists $mod{rep} && ($mod{post}{g} || $mod{post}{gc})) {
		error "Can't specify both :globally and :x($mod{rep}) on the same rule";
	}
	$mod{post}{g} = 1 if $repcontrol && $type eq 's' && !$mod{post}{gc};

	my $repprecontrol = !$repcontrol                     ? ''
					  : exists $mod{rep} && $type eq 'm' ? '('
					  :                                    '(?>';
	my $reppostcontrolcode = $repcontrol && $type eq 'm'
				? '$Perl6::Rules::count=0;' : '';
	my $reppostcontrolpat = $repcontrol ? '|\z(?{$Perl6::Rules::count=0})(?!)' : '';

	error('The :nth modifier can only be used with m/.../ or s/.../.../')
		if exists $mod{nth} && $type ne 'm' && $type ne 's';
	error('The :x modifier can only be used with m/.../ or s/.../.../')
		if exists $mod{rep} && $type ne 'm' && $type ne 's';

    # "pre" modifiers are things like \G that go at the start of the
    # back-translated Perl5ish regex.
    # "post" modifiers are things like /gimsox that go after the
    # back-translated Perl5ish regex.

    my $pre  = join "", keys %{$mod{pre}};
    my $post = join "", keys %{$mod{post}};


    # Decorate the back-translation and cache...

    my $setup = ($mod{exhaust} || $mod{overlap})
					? ';eval q{@0=()}if!$Perl6::Rules::comb++;'
			  		: "";
    my $cleanup = $mod{exhaust} ?  "(?{Perl6::Rules::Match::_success('next')})(?!)|\\z(??{if(\@0){Perl6::Rules::Match::_success('done');$reppostcontrolcode$priorness}else{${reppostcontrolcode}Perl6::Rules::Match::_failure}\@0?'':'(?!)'})"
                : $mod{overlap} ?  "(?{Perl6::Rules::Match::_success('next','overlap')})(?!)|\\z(??{if(\@0){Perl6::Rules::Match::_success('done');$reppostcontrolcode$priorness}else{${reppostcontrolcode}Perl6::Rules::Match::_failure}\@0?'':'(?!)'})"
                : "(?{Perl6::Rules::Match::_success();$reppostcontrolcode$priorness})$reppostcontrolpat|(?{Perl6::Rules::Match::_failure})(?!)";

    my $trans = "(?xm)$repprecontrol(?{local (\@Perl6::Rules::d0,\%Perl6::Rules::d0);local\$Perl6::Rules::startpos=pos;$setup})($pre(?:@p5pat))$repcontrol$cleanup";

    $rules[$rule_id] = do { no warnings 'regexp'; qr{$trans}; }
        unless $translate || $bad;
	$rule_id++;

    $trans = "$type$ldel$trans$rdel";

    # If there's a replacement string (i.e. it's a substitution)...

    if ($repl) {

        # Find the start and end of the (single) interpolator...
        # (This ought to be done with a nested substitution, in which
        #  case we could allow multiple interpolators)

        my $from_s = index($repl, '$(');
        my $from_l = index($repl, '@(');
        my $to   = rindex($repl, ')');

        # Back-translate the interpolator, if any...

        if ($from_s>=0 && $to>=0) {
            my $len  = $to-$from_s+1;
            substr($repl,$from_s,$len) =
                '@{[scalar(' . substr($repl,$from_s+2,$len-3) . ')]}';
        }
        elsif ($from_l>=0 && $to>=0) {
            my $len  = $to-$from_l+1;
            substr($repl,$from_l,$len) =
                '@{[' . substr($repl,$from_l+2,$len-3) . ']}';
        }

        # Append the replacement string to the back-translated regex...

        $trans .= $repl;
    }

    # Return the back-translated regex, appending any flags...

    return "$trans$post";
}


# Append multiple captures to the same array, changing 
# value type as necessary

sub apparray {
    my ($arrayref, $newval) = @_;
    $arrayref = $_[0] = [undef] unless $arrayref and @$arrayref; # EXPERIMENTAL
    debug "Appending ", $newval, " to array";
    for ($arrayref->[-1]) {
           if (!defined)       { $_ = $newval }
        elsif (ref ne 'ARRAY') { $_ = [ $_, $newval ] }
        else                   { push @$_, $newval }
    }
}

# Create entry and subsequently assign multiple captures to the same hash
# element, changing value type as necessary

sub apphash {
    my ($hashref, $newval) = @_;
    debug "Appending ", $newval, " to hash";
    if (!defined $hashref->{""}) {      # "Appending" a key
                                        # ($hash{""} stores current "focus" key
        $hashref->{""} = $newval;
        $hashref->{$newval} = undef;
    }
    else { # Appending a value
        for ($hashref->{$hashref->{""}}) {
               if (!defined)       { $_ = $newval }
            elsif (ref ne 'ARRAY') { $_ = [ $_, $newval ] }
            else                   { push @$_, $newval }
        }
    }
}


# Save a restore internal variable sets on subrules 
# (because localized variables "bleed" into qr/.../s that
# are interpolated via (??{...})

my @d0_stack;
our ($startpos, $lastpos, @d0, %d0);

sub save_d0 {
    debug "Saving internal state (", 0+@d0_stack, ")";
    push @d0_stack, [$startpos, $lastpos,\@d0, \%d0];
}

sub restore_d0 {
    ($startpos, $lastpos, *d0, *d0) = @{pop @d0_stack};
    debug "Restoring internal state (", 0+@d0_stack, ")";
}

package Perl6::Rules::Match;

my %data;

sub _failure {
    $0 = bless \(my $anon);
    $data{overload::StrVal $0} = { b=>0, a=>[], h=>{} };
}

sub _success {
    my ($exhaust,$overlap) = (@_,"","");
	return if $overlap && $exhaust ne 'done' && $Perl6::Rules::startpos <= $Perl6::Rules::lastpos;
    $Perl6::Rules::d0[0] = $^N unless defined $Perl6::Rules::d0[0];
    my %hash;
    for my $var (keys %Perl6::Rules::d0) {
        my $sigil = substr($var,0,1);
        my $subsigil = substr($var,1,1);
        if ($sigil eq '$') {
            if ($subsigil eq '?') {     # Internal scalar -> cut off sigils
                $Perl6::Rules::d0{substr($var,2)} =
                    delete $Perl6::Rules::d0{$var};
            }
            else {                      # External scalar -> assign
                eval "$var = q{$Perl6::Rules::d0{$var}}";
            }
        }
        elsif ($sigil eq '@' && $subsigil eq '?') {
            @{$Perl6::Rules::d0{$var}} = grep defined, @{$Perl6::Rules::d0{$var}};
        }
        elsif ($sigil eq '%' && $subsigil eq '?') {
            delete $Perl6::Rules::d0{$var}{''};
        }
        elsif ($subsigil ne '?') {      # External array or hash -> assign
			eval "$var = q{$Perl6::Rules::d0{$var}}";
        }
    }
    while (my ($exvar,$exvarref) = each %{$Perl6::Rules::exvar{scalar}}) {
        $$exvarref = eval $exvar;
    }
    while (my ($exvar,$exvarref) = each %{$Perl6::Rules::exvar{hash}}) {
        %$exvarref = eval $exvar;
        delete $exvarref->{''};
    }
    while (my ($exvar,$exvarref) = each %{$Perl6::Rules::exvar{array}}) {
        @$exvarref = eval $exvar;
    }
    $0 = bless \(my $anon);
    if ($exhaust ne 'done') {
        $data{overload::StrVal $0} = {
            b=>1,
			a=>[@Perl6::Rules::d0],
			h=>{%Perl6::Rules::d0},
			p=>$Perl6::Rules::startpos,
        };
        if ($exhaust) {
            push @0, $0;
            Perl6::Rules::debug "Adding alternative match: ", $0;
            @Perl6::Rules::d0 = ();
            %Perl6::Rules::d0 = ();
			$Perl6::Rules::lastpos = $Perl6::Rules::startpos;
        }
    }
    else {
        $data{overload::StrVal $0} = {
            b=>1, a=>\@0, h=>{}, p=>$Perl6::Rules::startpos,
        };
        Perl6::Rules::debug "Finalizing alternative matches: ", 0+@0;
        $Perl6::Rules::comb=0;
        $Perl6::Rules::lastpos=-1;
    }
}

use overload 
    q{bool} => sub { $data{overload::StrVal $_[0]}{b} },
    q{""}   => sub { $data{overload::StrVal $_[0]}{a}[0] },
    q{@{}}  => sub { $data{overload::StrVal $_[0]}{a} },
    q{%{}}  => sub { $data{overload::StrVal $_[0]}{h} },
    fallback => 1,
;

sub _flatten {
    my ($val) = @_;
    if (ref $val eq 'Perl6::Rules::Match') {
        return _flatten({
            'SCALAR'.($val?'(true)':'(false)') => "$val",
            ARRAY  => \@$val,
            HASH   => \%$val,
			POS    => $val->pos,
        });
    }
    elsif (ref $val eq 'ARRAY') {
        return [ map { _flatten($_) } @$val ];
    }
    elsif (ref $val eq 'HASH') {
        return { map { ($_=>_flatten($val->{$_})) } keys %$val };
    }
    elsif (!defined $val) {
        return "<undef>";
    }
    else {
        return $val;
    }
}

sub pos {
	my ($self) = @_;
	return $data{overload::StrVal $self}{p};
}

sub dump {
    my ($self,$level) = @_;
    use YAML;
    local ($YAML::UseAliases, $YAML::UseHeader)
          =       0,          0;
    my $dump = Dump _flatten($self);
    return $dump if defined wantarray;
    print $dump;
}

# Placate the mysterious regex gods...

$Perl6::Rules::lastpos=-1;
$Perl6::Rules::startpos=-1;
Perl6::Rules::save_d0;
_success();
Perl6::Rules::restore_d0;

1;

__END__

=head1 NAME

Perl6::Rules - Implements (most of) the Perl 6 regex syntax


=head1 SYNOPSIS

    # Perl 5 code...

    use Perl6::Rules;

    grammar HTML {
        rule doc  :iw { \Q[<HTML>]  <?head>  <?body>  \Q[</HTML>] }
        rule head :iw { \Q[<HEAD>]  <?head_tag>+  \Q[<HEAD>] }
        # etc.
    }

    $text =~ s:globally:2nd/ <?HTML.doc> /$0{doc}{head}/;

    rule subj  { <noun> }
    rule obj   { <noun> }
    rule noun  { time | flies | arrow }
    rule verb  { flies | like | time }
    rule adj   { time }
    rule art   { an? }
    rule prep  { like }

    "time flies like an arrow" =~
        m:words:exhaustive/^ [ <?adj>  <?subj> <?verb> <?art> <?obj>
                             | <?subj> <?verb> <?prep> <?art> <?noun> 
                             | <?verb> <?obj>  <?prep> <?art> <?noun>
                             ]
                          /;

    print "Found interpretation:\n", $_->dump
        for @$0;


    $dna_seq =~ m:overlap{ A <[CT]> <[AG]><3,7> <before: C> };

    print "Found sequence: $_ starting at " $_->pos
        for @$0;

    # etc.


=head1 DESCRIPTION

This module implements a close simulation of the Perl 6 rule and grammar
constructs, translating them back to Perl 5 regexes via a source filter.
(And hence suffers from all the usual limitations of a source filter,
including the ability to translate complex code spectacularly wrongly).

See L<LIMITATIONS> for a summary of those features that are not
currently supported.

When it is C<use>'d, the module expects that any subsequent match (C<m/.../>)
or substitution (C<s/.../.../>) in the rest of the source file will be in
Perl 6 syntax. It then translates every such pattern back to the equivalent
Perl 5 syntax (where possible).

When one of these translated matches/substitutions is executed, it
generates a "match object", which is available as C<$0> (and so, if you
use Perl6::Rules, the program name is no longer available as C<$0>).
This match object can be treated as a boolean (in which case it returns
true if the match succeeded, and false if it did not), or as a string
(in which case it returns the complete substring that the match
matched), or as an array (in which case it contains all of the numbered
captures -- C<$1>, C<$2>, etc. -- from the successful match), or as a
hash (in which case it contains all of the L<internal variables|"Named
captures to internal variables"> created during the match).


=head2 Atoms

Except for the special characters:

    #  $  @  %  ^  &  *  +  ?  (  )  {  }  [  ]  <  >  .  |  \

whitespace, and certain special character sequences (see below),
any character in a rule matches itself.

Special characters can be made to match themselves by
backslashing them:

    \#  \$  \@  \%  \^  \&  \*  \+  \?  \(  \)  \{  \}  \[  \]  \<  \>  \.  \|  \\

or by using one of the Perl 6 L<quoting constructs|
Interpolated literal strings>.


=head2 Quantifiers

Quantifiers control how often a particular atom matches. Without a quantifier
an atom must match exactly once. The Perl 6 quantifiers are:

    atom?           Match the atom zero or one times
                    preferring to match once, if possible

    atom??          Match the atom zero or one times 
                    preferring to match zero times, if possible

    atom*           Match the atom zero or more times
                    preferring to match as many times as possible

    atom*?          Match the atom zero or more times
                    preferring to match as few times as possible

    atom+           Match the atom one or more times
                    preferring to match as many times as possible

    atom+?          Match the atom one or more times
                    preferring to match as few times as possible

    atom<7>         Match the atom exactly 7 times
                    (Any positive integer can be used)

    atom<7,11>      Match the atom between 7 and 11 times
                    preferring to match as many times as possible.
                    (Any positive integers can be used)

    atom<7,11>?     Match the atom between 7 and 11 times
                    preferring to match as few times as possible.
                    (Any positive integers can be used)

    atom<4,>        Match the atom 4 or more times
                    preferring to match as many times as possible.
                    (Any positive integers can be used)

    atom<4,>?       Match the atom 4 or more times
                    preferring to match as few times as possible.
                    (Any positive integers can be used)

B<Note: Perl 6 also allows the numbers in these ranges to be specified
as interpolated variables, but due to limitations of the Perl 5 regex engine,
the Perl6::Rules module does not currently support this feature.>


=head2 Alternatives

The C<|> operator separates two alternative subpatterns. The resulting pattern 
matches if either of the alternatives matches:

    $animal =~ m/ cat | dog | fish | bird /;

B<Note: Perl 6 also provides an C<&> operator, but this is not yet 
supported by Perl6::Rules.>


=head2 Special metasequences

A dot (C<.>) matches any character at all (including a newline).

There are numerious backslashed metasequences, that match a particular
single character, usually belonging to a particular class of characters:

    \d   Match a single digit
    \D   Match any single character except a digit
    \e   Match a single escape character
    \E   Match any single character except an escape character
    \f   Match a single formfeed
    \F   Match any single character except a formfeed
    \h   Match a single horizontal whitespace
    \H   Match any single character except a horizontal whitespace
    \n   Match a single newline
    \N   Match any single character except a newline
    \r   Match a single carriage return
    \R   Match any single character except a carriage return
    \s   Match a single whitespace character
    \S   Match any single character except a whitespace
    \t   Match a single tab character
    \T   Match any single character except a tab character
    \v   Match a single vertical whitespace
    \V   Match any single character except a vertical whitespace
    \w   Match a single "word" character (alpha, digit, or underscore)
    \W   Match any single character except a "word" character


=head2 Specifying characters by name or code

Any character can be specified by (Unicode) name, using the C<\c> escape.
For example:

    \c[LF]
    \c[ESC]
    \c[CARRIAGE RETURN]
    \c[ARABIC LIGATURE TEH WITH MEEM WITH JEEM INITIAL FORM]
    \c[HEBREW POINT HIRIQ]
    \c[LOWER HALF INVERSE WHITE CIRCLE]

Two or more such named characters can be specified in the same set of
square brackets, separated by a comma:

    \c[CR;LF]
    \c[ESC;LATIN CAPITAL LETTER Q]

The C<\C> escape produces the complement of the character:

    \C[LF]                  Any character except LINE FEED
    \C[ESC]                 Any character except ESCAPE
    \C[CARRIAGE RETURN]     Any character except CARRIAGE RETURN

The square brackets are always required for named characters.

Characters and character sequences can also be specified by hexadecimal or
octal Unicode code:

    \x[A]           LINE FEED
    \0[12]          LINE FEED
    \x[1EA2]        LATIN CAPITAL LETTER A WITH HOOK ABOVE
    \0[17242]       LATIN CAPITAL LETTER A WITH HOOK ABOVE
    \x[1EA2;A]      LATIN CAPITAL LETTER A WITH HOOK ABOVE; LINE FEED
    \0[17242;12]    LATIN CAPITAL LETTER A WITH HOOK ABOVE; LINE FEED

Hexadecimal codes may also be complemented:

    \X[A]           Any character except LINE FEED
    \X[1EA2]        Any character except LATIN CAPITAL LETTER A WITH HOOK ABOVE

For single coded characters, the square brackets are not required
(except to avoid ambiguity):

    \xA             LINE FEED
    \012            LINE FEED
    \x1EA2          LATIN CAPITAL LETTER A WITH HOOK ABOVE
    \017242         LATIN CAPITAL LETTER A WITH HOOK ABOVE
    \XA             Any character except LINE FEED
    \X1EA2          Any character except LATIN CAPITAL LETTER A WITH HOOK ABOVE


=head2 Anchors and assertions

Anchors and assertions do not match any characters in the string, but instead
test whether a particular condition is true, and cause the match to fail if 
it is not.

Perl6::Rules supports the following Perl 6 rule assertions:

     ^   Currently matching at the start of the entire string
    ^^   Currently matching at the start of a line within the string
     $   Currently matching at the end of the entire string
    $$   Currently matching at the end of a line within the string

Note that neither C<$> nor C<$$> allows for an optional newline before
the "end" in question. Use C<\n?$> and C<\n?$$> if you require
those semantics more forgiving semantics.

    <before: subpat>    The current match position is immediately
                        before the specified subpattern
    <!before: subpat>   The current match position is not immediately
                        before the specified subpattern

    <after: subpat>     The current match position is immediately
                        after the specified subpattern
    <!after: subpat>    The current match position is not immediately
                        after the specified subpattern

    \b   The current match position is in the middle of a \w\W or \W\w
         sequence (i.e. <after:\w><before:\W> | <after:\W><before:\w> )
    \B   The current match position is in the middle of a \w\w or \W\W
         sequence (i.e. <after:\w><before:\w> | <after:\W><before:\W> )


B<Note: Due to limitations in the Perl 5 regex engine, the C<< <after:...> >>
assertion requires that the subpattern always match a substring of fixed
length.>


=head2 Grouping

To group a sequence of characters and have them treated as an atom, use 
square brackets:

    $status =~ m/ [in]?valid /;

Square brackets group, but do not capture.


=head2 Capturing

To group a sequence of characters and have the matching substring captured as
well, use parentheses instead of square brackets. Each parenthesis captures
into a successive "numeric" variable:

    $name =~ m/ (Mr|Mrs|Ms|Dr|Prof|Rev) (.+)  /;

    print "Title: $1\n";
    print "Name:  $2\n";



=head2 Whitespace indifference

Whitespace is not significant in a rules and is usually ignored
when matching a pattern. For example, this:

    m/ <ident> = \N+ /;

matches exactly the same set of strings as:

    m/<ident>=\N+/;

To match actual whitespace in a string, use the appropriate backslash escape:

    m/ <ident> \h* = \s* \N+/;

or named characters:

    m/ <ident> <ws> = <sp>+ \N+/;


=head2 Making whitespace meaningful

Just because whitespace is not significant in a rule doesn't mean it's not
significant in the string that a rule is matching. For example:

    $str = "module_name = Perl6::Rules";

    $str =~ m/ <ident> = \N+ /;

will not match, because there is nothing in the rule to match the whitespace
in the string between C<"module_name"> and C<"=">.

However, you can tell a rule to ignore whitespace in the I<string>, by
specifying the C<:w> or C<:words> modifier:

    $str = "module_name = Perl6::Rules";

    $str =~ m:words/ <ident> = \N+ /;

This modifier causes each whitespace sequence in the rule to be automagically
replaced by a C<\s*> or C<\s+> subpattern. That is:

    m:words/ next cmd  = \h* <condition>/

Is the same as:

    m/ \s* next \s+ cmd \s* = \h* <condition>/

If the whitespace is between two "word" atoms -- as it is between C<next>
and C<cmd> in the above example -- then a C<\s+> (mandatory whitespace) is
inserted. If the whitespace is between a "word" and a "non-word" atom --
as it is between C<cmd> and C<=> above -- then a C<\s*> (optional whitespace) is
inserted. If the atom on either side of the whitespace would itself match
whitespace -- as for C<=> and C<\h*>, and C<\h*> and C<< <condition> >> --
then no extra whitespace matching is inserted.

The overall effect is that, under C<:words>, any whitespace in the rule
matches any whitespace in the string, in the most reasonable way possible.


=head2 Comments

Any unbackslashed C<#> character in a pattern starts a comment which
runs to the end of the current line.

    m/ <ident>  # name of environment variable
       \h*      # optional whitespace, but stay on the same line
       =        # indicates that the variable is being set
       \s*      # optional whitespace, can be on separate lines
       \N+      # everything else up to the end-of-line is the value
     /;


=head2 Evaluated substitutions

When performing a substitution it is possible to interpolate code
into the replacement string using the Perl 6 C<$(...)> or C<@(...)>
interpolators:

    s/ (<sentence>) /On a dit: $( traduisez($1) )/

B<Note: Perl6::Rules currently only allows substitutions to have a single
C<$(...)> or C<@(...)> in the replacement string.>


=head2 Repeated matches and substitutions

To cause a match or substitution to match or substitute as many times as
possible, specify the C<:g> or C<:globally> modifier before the pattern:

    $str =~ s:g{foo}{bar};          # s/foo/bar/ as many times as possible
    $str =~ s:globally{foo}{bar};   # Ditto

To cause a match or substitution to match or substitute a particular number
of times, specify the C<:x(...)> modifier:

    $str =~ s:x(2){foo}{bar};       # s/foo/bar/ only the first two times 
                                    # "foo" is found

    $str =~ s:x(7){foo}{bar};       # s/foo/bar/ only the first seven times 
                                    # "foo" is found

The repetition count can be a variable:

    for my $n (2..7) {
        $str[$n] =~ s:x($n){foo}{bar};  # s/foo/bar/ only the first $n times 
                                        # "foo" is found
    }

If the repetition count is a constant, the C<:x(...)> modifier can also
be written as a suffix:

    $str =~ s:2x{foo}{bar};     # s/foo/bar/ only the first two times 
                                # "foo" is found

    $str =~ s:7x{foo}{bar};     # s/foo/bar/ only the first seven times 
                                # "foo" is found


If you only want the 2nd (or 7th, or C<$n>-th, etc.) occurance changed,
you can use the C<nth(...)> modifier instead:

    $str =~ s:nth(2){foo}{bar};     # s/foo/bar/ only for the second occurance
                                    # of "foo" in the string

    $str =~ s:nth(7){foo}{bar};     # s/foo/bar/ only for the seventh occurance
                                    # of "foo" in the string

    $str =~ s:nth($ord){foo}{bar};  # s/foo/bar/ only for the $ord-th occurance
                                    # of "foo" in the string

If the ordinal number is a constant, the C<:nth(...)> modifier can also
be written as a suffix:

    $str =~ s:2nd{foo}{bar};        # s/foo/bar/ only the first two times 
                                    # "foo" is found

    $str =~ s:7th{foo}{bar};        # s/foo/bar/ only the first seven times 
                                    # "foo" is found

You can also combine C<:globally> with an ordinal modifier. For example, to 
replace every third occurance of "foo" with "bar":

    $str =~ s:globally:3rd{foo}{bar}


=head2 Variations on global matching

Rules that match C<:globally> do so by matching once, then restarting their
search at the first character after the end of the previous match. But there
are (at least) two other alternative restart strategies for global matching,
both of which Perl 6 (and Perl6::Rules) supports. 

Matching C<:globally> will never find overlapping matches. For example:

    $dna = "ACGTAGTCATGACGTACCA";

    $dna =~ m:globally{ A [ACGT]* T };

will only match:

    "ACGTAGTCATGACGT"

after which it will try again on the remainder of the string ("ACCA") and
fail. 

But if you actually wanted overlapping matches from every possible start
position:

    "ACGTAGTCATGACGT"
        "AGTCATGACGT"
            "ATGACGT"
               "ACGT"

then you need to specify C<:o> or C<:overlap>, instead of C<:globally>:

    $dna =~ m:overlap{ A [ACGT]* T };

This works just like C<:globally>, except that, instead of restarting the
search from the first character after the end of the previous match, it
restarts the search from the first character after the I<start> of the
previous match. Hence it will only ever find one match from any given starting
position in the string, but it will find matches from every possible starting
position, including those matched that overlap.

Even that may not be enough. Rather than one match at every starting position,
you may require every possible match at every starting position:

    "ACGTAGTCATGACGT"
    "ACGTAGTCAT"     
    "ACGTAGT"
    "ACGT"
        "AGTCATGACGT"
        "AGTCAT"     
        "AGT"        
            "ATGACGT"
            "AT"     
               "ACGT"

To match in this way, use the C<:e> or C<:exhaustive> modifier:

    $dna =~ m:exhaustive{ A [ACGT]* T };


Note that, when either C<:overlap> or C<:exhaustive> are specified, the match
result returned in C<$0> changes in structure. For a non-overlapping match
C<$0> consists of:

     $0     # Complete substring matched
    @$0     # Unnamed captures: ($0, $1, $2, ...)
    %$0     # Named captures

For an overlapping/exhaustive match, C<$0> consists of:

     $0     # undef
    @$0     # The complete $0 of each successive overlapping match
    %$0     # Empty hash



=head2 Ignoring case

If you use the C<:i> or C<:ignorecase> modifier, the match ignores upper and
lower case distinctions:

    $str =~ m:i/perl/;      # Match "Perl" or "perl" or "pErL", etc.

The C<:i> marker can also be placed inside a rule, to turn off case 
sensitivity in only part of the rule:

    $title =~ m/The <sp> [:i journal <sp> of <sp> the ] <sp> ACM /;
    #
    #   match: The Journal Of The ACM
    #      or: The journal of the ACM
    # but not: The journal of the acm


=head2 Backtracking control

In Perl 6 a single colon is ignored when matching (or, in other words, it
matches zero characters).

However, should the pattern subsequently fail to match and I<backtrack> over 
the single colon, it will I<not> retry the preceding atom. So if you write:

    $str =~ m:words/ \( <expr>  [ , <expr> ]* :  \) /

and the match fails to find the closing parenthesis (and hence starts
backtracking), it will not attempt to rematch C<[ , <expr> ]*> with one
fewer repetition,but will continue backtracking and ultimately fail.
This is a useful optimization since a match with one less comma'd
expression still wouldn't have a parenthesis after it, so trying it
would be a waste of time).

B<Note: Due to the opaque nature of backtracking in the Perl 5 regex engine,
Perl6::Rules cannot efficiently implement the "higher level" backtracking
control features: C<::>, C<:::>, C<commit>, and C<cut>. So these constructs
are not currently supported.>


=head2 Starting position

Normally a rule attempts to match from the start of a string. But you can
tell the rule to match from the current <pos> of the string by specifying the 
C<:c> (or C<:cont>) modifier:

    $str =~ m:c/ pattern /  # start where the previous match on $str finished



=head2 Code blocks

You can place a Perl code block inside a rule. It will be executed when
the rule reaches that point in its matching. Code execution does not
usually affect the match; it is typically only used for side-effects:

    m/ (\S+) { warn "string not blank..."; $text=$1; }
        \s+  { warn "...but does contain whitespace" }
     /

Note that variables accessed within a code block (or indeed anywhere else
inside a Perl 6 rule) must be accessed in Perl 6 syntax. So, this:

    m:g/ (\S+) { $::found{$1}++ } /;

is equivalent to the Perl 5:

       / (\S+) (?{ $::found->{$^N}++ }) /g;

and to increment an entry in C<%::found> we'd need the correct Perl 6
syntax:

    m:g/ (\S+) { %::found{$1}++ } /;


A code block can be made to cause a match to fail, if it calls the
C<fail> function (which is automatically exported from Perl6::Rules):

    $count =~ / (\d+): {$1<256 or fail} /

By the way, that "no backtracking" colon is critical there. If C<$count>
contained C<1000>, then C<$1> would be C<"1000">, the code would execute
C<fail> and the rule would backtrack. The colon prevents the C<\d+>
pattern from then rematching just C<"100"> instead of the full C<"1000">,
which would erroneously allow the pattern to match.


=head2 Code assertions

Blocks of the form C<{ sometest() or fail }> are so common that Perl 6 rules
(and hence Perl6::Rules) provide a shorthand. Any expression in a
C<< <(...)> >> is treated as a code assertion, which causes a match to fail
and backtrack if it is not true at that point in the match. For example, you
could rewrite:

    $count =~ m/ (\d+): {$1<256 or fail} /

more simply as:

    $count =~ m/ (\d+): <($1<256)> /;


=head2 Literal variable interpolation

Variables that appear in a  Perl 6 rule interpolate differently to variables
that appear in a Perl 5 regex. Specifically, in Perl 5:

    $dir = "lost+found";
    $str =~ /$dir/;

is the same as:

    $str =~ /lost+found/;

which would match:

    "lostfound"
    "losttfound"
    "lostttfound"
    "losttttfound"
    etc.

In Perl 6, an interpolated scalar variable C<eq> matches its contents against
the string. So:

    use Perl6::Rules;
    $dir = "lost+found";
    $str =~ m/$::dir/;

would treat the contents of C<$dir> as a literal sequence of characters to
match, and hence (only) match:

    "lost+found"

An interpolated array:

    use Perl6::Rules;
    @cmds = ('get','put','save','load','dump','quit');
    $str =~ m/ @::cmds /;

matches if any of its elements C<eq> matches the string at that point. 
So the above example is equivalent to:

    $str =~ /get|put|save|load|dump|quit/;


An interpolated hash matches a C</\w+/> sequence and then requires that
that sequence is a valid key of the hash. So:

    use Perl6::Rules;

    my %cmds = ( get=>'Shorty', put=>'down', quit=>'griping' );

    $str =~ m/ %::cmds /;

is a shorthand for:

    / (\w+) { fail unless exists %::cmds{$1} } /

Note that the actual values in the hash are ignored.

However, if the hash being interpolated has a C<keymatch> trait:

    use Perl6::Rules;

    my %cmds is keymatch(rx/<alpha>+:/)
        = ( get=>'Shorty', put=>'down', quit=>'griping' );
    
then the rule into which it's interpolated uses that trait's value instead
of C<\w+> as the required subpattern. In which case: 

    $str =~ m/ %::cmds /;

would become a shorthand for:

    / (<alpha>+:) { fail unless exists %::cmds{$1} } /

instead.

Furthermore, if the interpolated hash also has a C<valuematch> trait:

    use Perl6::Rules;

    my %cmds is keymatch(rx/<alpha>+:/)
             is valuematch(rx/\s+ <alpha>+:/)
        = ( get=>'Shorty', put=>'down', quit=>'griping' );

then, after the key has been successfully matched, the rule attempts to match
the C<valuematch> pattern, and requires that this secondary match be equal to
the value for the previously matched key. That is, with a C<valuematch> trait
as well, this:

    $str =~ m/ %::cmds /;

would become a shorthand for:

    / (<alpha>+:)     { fail unless exists %::cmds{$1} }
      (\s+ <alpha>+:) { fail unless $2 eq %::cmds{$1}  }
    /

In other words, when both traits are specified, an interpolated hash has
to match one of its keys, followed by that key's value.


=head2 Non-literal variable interpolation

Sometimes it would be more useful to interpolate a variable not as a literal
sequence of characters to be matched, but rather as a subpattern to be matched
(i.e. the way Perl 5 does).

To interpolate a variable in that way in a Perl 6 rule, place the variable in
angle brackets. That is:

    use Perl6::Rules;
    $exclamation = rx/Shee+sh/;
    $str =~ m/ <$::exclamation> /;

would treat the contents of C<$::exclamation> as a subpattern (rather than as
a literal sequence of characters to match) and hence match:

    "Sheesh"
    "Sheeesh"
    "Sheeeesh"
    etc.

but not:

    "Shee+sh"

An angle-bracketed interpolated array:

    use Perl6::Rules;
    @cmds = ( rx/<[gs]>et/, rx/put/, rx/save?/, rx/q[uit]?/ );
    $str =~ m/ <@::cmds> /;

treats each of its elements as a subpattern, and matches if any of them
matches at that point.  So the above example is equivalent to:

    $str =~ m/ <[gs]>et | put | save? | q[uit]?/;

(i.e. with the metasequences left intact).

An angle-bracketed interpolated hash first matches a C</\w+/> sequence and
requires that that sequence is a valid key of the hash. It then treats the
corresponding hash value as a subpattern and requires that that subpattern
match too. So:

    use Perl6::Rules;

    my %cmds =
        ( get=>rx/\s+ <ident>/, put=>rx:i/\s+down/, quit=>rx/[\s+ griping]?/);

    $str =~ m/ %::cmds /;

is a shorthand for:

    $str =~ m/ (\w+) { fail unless exists %::cmds{$1} }
               <%::cmds{$1}>
             /

Once again, if the hash being interpolated has a C<keymatch> trait
that trait's value is used instead of C<\w+> to match the key.
However, any C<valuematch> trait on an angle-bracketed hash is ignored.

B<Note: due to limitations of nesting pattern matches, Perl6::Rules requires
that any value in an angle-bracketed hash or array must be a precompiled
pattern (i.e. either a Perl5-ish C<qr/.../> or a Perl6-ish C<rx/.../>), not
a string.>


=head2 Predefined named rules

Certain named rules are predefined by Perl 6 (and hence by the Perl6::Rules
module). They are:

    <ws>        Match any sequence of whitespace
    <ident>     Match an identifier (alpha or underscore, followed by \w*)
    <prior>     Match using the most recent successful rule
    <self>      Match this entire pattern (recursively)
    <sp>        Match a single space char
    <null>      Match zero characters (i.e. unconditionally)
    <alpha>     Match a single alphabetic character
    <space>     Match a single whitespace character
    <digit>     Match a single digit
    <alnum>     Match a single alphabetic or digit
    <ascii>     Match a single ASCII character
    <blank>     Match a single space or tab 
    <cntrl>     Match a single control character
    <ctrl>      Match a single control character
    <graph>     Match a single non-control character
    <lower>     Match a single lower-case character
    <print>     Match a single printable character
    <punct>     Match a single punctuation character
    <upper>     Match a single upper-case character
    <word>      Same as \w
    <xdigit>    Match a single hexadecimal digit

In addition, every long- or short-form Unicode property name is a valid
predefined subrule. For example:

    <L> or <Letter>             Match any letter
    <Lu> or <UppercaseLetter>   Match any upper-case letter

    <Sm> or <MathSymbol>        Match any mathematical symbol

    <BidiWS>                    Match any bidirectional whitespace

    <Greek>                     Match any Greek character
    <Mongolian>                 Match any Mongolian character
    <Ogham>                     Match any Ogham character

    <Any>                       Match any character

    <InArrows>                  Match any character in the "Arrows" block
    <InCurrencySymbols>         Match any character in the "CurrencySymbols" block

    etc.

In addition, Perl6::Rules supports the Perl-specific C<< <Lr> >> property,
which replaces the non-standard Perl5-specific C<< <L&> >> property,
which matches any upper-, lower-, or title-case letter.

Note that any such named subrule that matches exactly one character may also
be used inside a L<character class|"Character classes">.


=head2 Code interpolations

uormally code blocks don't actually match against anything. To make them do
so, put the code block in angle-brackets. For example:

    / (@::cmds)  <{ get_body_for_cmd($1) }> /

This first matches one of the elements of C<@cmds> (as a literal substring).
It then calls the C<get_body_for_cmd> subroutine, passing it that substring.
The value returned by that call is then used as a subpattern, which must match
at that point.

B<Note: due to limitations of nesting pattern matches, Perl6::Rules requires
that any C<< <(...)> >> block must return a precompiled
pattern (i.e. either a Perl5-ish C<qr/.../> or a Perl6-ish C<rx/.../>), not
a string.>


=head2 Character classes

A character class is an enumerated set of characters and/or properties.
In Perl 6, character classes are specified by square brackets inside angle
brackets:

    $str =~ m/ <[A-Za-z_]> <[A-Za-z0-9_]>* /    # Match an ASCII identifier

A normal character class can also be indicated by a leading plus sign,
whilst a complemented character class (i.e. "any character except...")
is indicated by a leading minus sign:

    $str =~ m/ <[aeiou]> /      # Match a vowel
    $str =~ m/ <+[aeiou]> /     # Match a vowel
    $str =~ m/ <-[aeiou]> /     # Match a character that isn't a vowel

Two or more square-bracketed sets (including their optional signs)
can be placed in the same angle brackets:

    $str =~ m/ <[aeiou][tlc]> /     # Match a vowel or 't' or 'l' or 'c'
    $str =~ m/ <[aeiou]+[tlc]> /    # Match a vowel or 't' or 'l' or 'c'
    $str =~ m/ <[a-x]-[aeiou]> /    # Match a letter between 'a' and 'x'
                                    # but not a vowel

Named properties, subrules and backslashed escapes that match a single
character can also be placed in the character set:

    $str =~ m/ <<alpha>-[aeiou]> /  # Match a non-vowel alphabetic
    $str =~ m/ <[\w]-<digit>> /     # Match first letter of an identifier


=head2 Interpolated literal strings

Any single-quoted string in angle brackets is treated as a literal sequence
of characters to be matched at that point. Whitespace and other
metacharacters within the string must match literally.

For example:

    $text =~ m/ .*? <'# # # # #'> /;    # Match to first '# # # # #'

Another way to get the same effect is to use a "quotemeta" block:

    $text =~ m/ .*? \Q[# # # # #] /;    # Match to first '# # # # #'

The subpattern inside the square brackets following the C<\Q> is treated
as a literal string, to be C<eq> matched.


=head2 Backreferences

Because variables are interpolated at match-time in Perl 6 rules,
backreferences to earlier captures are written as variables, not as
backslashed numbers. So, to remove doubled words:

    $text =~ s:words:globally{( <alpha>+) $1}{$1};


=head2 Anonymous rule constructors

Under Perl6::Rules, if you use C<qr> to create an anonymous rule 
you get the Perl 5 interpretation of the pattern:

    use Perl6::Rules;

    my $pat = qr/[a-z+]:\0[123]/;

    #  [a-z+]   Match one lower-case alpha or a '+',
    #  :        Match a literal colon,
    #  \0       Match a null byte,
    #  [123]    Match a '1', a '2', or a '3'

To get the Perl 6 interpretation, use the Perl 6 anonymous rule constructor
(C<rx>) instead:

    use Perl6::Rules;

    my $pat = rx/[a-z+]:\0[123]/;

    #  [        Without capturing...
    #    a-     Match 'a-',
    #    z+     Match 'z' one or more times
    #  ]        End of group
    #  :        Don't backtrack into previous group on failure
    # \0[123]   Match an 'S' (specified via octal code)


You can also use the keyword C<rule> there:

    my $pat = rule {[a-z+]:\0[123]};

B<Note: The C<rx> keyword allows C<{...}>, C<[...]>, C<< <...> >>, or
C</.../> as pattern delimiters. The C<rule> keyword allows only C<{...}>.>

If either needs modifiers, they go before the opening delimter, as
for matches and substitutions:

    my $pat = rule :wi { my name is (.*) };
    my $pat = rx:wi/ my name is (.*) /;



=head2 Named Rules

The C<rule> keyword can also be used to create new named rules, by
adding the rule name immediately after the keyword:

    rule alpha_ident { <alpha> \w* }

    # and later...

    @ids = grep m/<alpha_ident>/, @strings;

In the Perl6::Rules implementation such a C<rule> declaration actually creates 
a subroutine of the same name within the current Perl 5 namespace.

B<Note: Due to bugs in the current Perl 5 regex engine, captures that
occur in named rules that are called as subrules from other rules may not work
correctly under Perl6::Rules, and will frequently lead to segfaults
and bus errors.>


=head2 Named captures to external variables

Any set of capturing parentheses can be prefixed with the name of a 
variable followed by C<:=>. The variable is then used as the destination
of the captured substring, I<instead> of assigning it to the next numbered
variable. 

For example, after:

    $input =~ / [ $::num  := (\d+)
                | $::alpha:= (<alpha>+)
                | $::other:=(.)
                ]
              /

then one of C<$::num>, C<$::alpha>, or C<$::other> with have been 
assigned the captured substring from whichever subpattern actually matched.
But none of C<$1>, C<$2>, C<$3> will have been set (since the named
capture overrides the normal numbered capture mechanism).

You can, however, explicitly assign to a numeric variable (for example, to 
reorder them in some fiendish way):

    $pair =~  m:words{ $1:=(\w+) =\> $2:=(.*)
                     | $2:=(.*?) \<= $1:=(\w+)
                     };

B<Note: due to unreliable interactions between Perl 5 regexes and
lexical variables in the current Perl 5 regex engine, under this version
of Perl6::Rules only explicitly-qualified package variables and unqualified
numeric variables may be used in rules.>

Repeated captures can be bound to arrays:

    $list =~ m/ @::values:=[ (.*?) , ]* /;

in which case each captured substring will be pushed onto C<@::values>.

Pairs of repeated captures can be bound to hashes:

    $opts =~ m:words/ %::options:=[ (<ident>) = (\N+) ]* /;

in which case the first capture in each repetition becomes the key
and the second capture becomes the value. If there are more than two
captures, the value for that key becomes an array reference, and
the second and subsequent captures are stored in that array.

If a single repeated capture is bound to a hash, each captured substring
becomes a key of the hash (and the corresponding values are C<undef>):

    $opts =~ m:words/ %::options:=[ (<ident>) = \N+ ]* /


=head2 Named captures to internal variables

Perl 6 rules also have their own internal namespace, with their own internal
variables. Those variables are marked by a secondary '?' sigil. For example:

    $input =~ / [ $?num  := (\d+)
                | $?alpha:= (<alpha>+)
                | $?other:=(.)
                ]
              /

After this match succeeds, one of the three internal variables will have been
set. To access these variables, treat C<$0> as a hash reference:

       if (exists $0->{num})   { print "Got number: $0->{num}\n" }
    elsif (exists $0->{alpha}) { print "Got alpha:  $0->{alpha}\n" }
    elsif (exists $0->{other}) { print "Got other:  $0->{other}\n" }

Scalar internal variables are stored under a key that is the name of
the variable stripped of its leading C<$?>. Array and hash internal variables
are stored under their full variable name. For example:

    $list =~ m/ @?values:=[ (.*?) , ]* /;

    for (@{ $0->{'@?values'} }) {
        print "Another values was: $_\n";
    }


Named subrules can also capture their result into an internal scalar
variable of same name. To do so, prefix the rule name inside the angle-
brackets with a question-mark:

    $pair =~ m:words/ <?key> =\> <?value> /;

    print "Key was: $0->{key}\n";
    print "Val was: $0->{value}\n";

Naturally enough, internal variables can also be accessed within the
rule itself. For example:

    $pair =~ m:words/ <?key> =\> <?value> { $?first = substr($?key,0,1) /;
    print "Key starts:  $0->{first}";
    print "Key was:     $0->{key}\n";
    print "Val was:     $0->{value}\n";


=head2 Return values from matches

In Perl 6, a match always returns a "match object", which is also available
as (lexical) C<$0>. This match object evaluates differently in
different contexts:

=over 

=item *

In a boolean context it evaluates true or false (i.e. did the match succeed?)

    m/<ident>/;
    if ($0) {
        print "Success!\n";
    }

=item * 

In a string context it evaluates to the captured substring:

    do {
        $text =~ m:cont/,? (<ident>)/ and print $hash{$0};
    } while $0;

=item * 

When used as an array reference, C<$0> provides a reference to an
array containing the numbered captures:

    $text =~ m:words/ (<ident>) \: (\N+)/;

    print "Option was:   $0->[0]\n";    # $0->[0] same as "$0"
    print "Option name:  $0->[1]\n";    # $0->[1] same as  $1
    print "Option value: $0->[2]\n";    # $0->[2] same as  $2
                                        # etc.

=item * 

When used as a hash reference, C<$0> provides a reference to a
hash containing its internal named variables:

    $text =~ m:words/ <?ident> \: @?vals:=[\s* (\S+)]+ /;

    print "Option name: ", $0->{ident}, "\n";
    print "Option vals: ", @{ $0->{'@?vals'} }, "\n";


=back

Since it is not feasible to intercept the return value of a Perl 5 regex
match, under Perl6::Rules, the return value is still the Perl 5 return
value. However, C<$0> I<is> set to the polymorphic match object shown above.

Note that I<within> a regex, C<$0> acts like an internal variable, so you can
capture or assign to it to control the overall substring that is returned.
For example:

    use Perl6::Rules;

    $quoted_str =~ m{ (<["'`]>) ([\\?.]*?) $1 }
    #
    # default behaviour: "$0" includes delimiters


    $quoted_str =~ m{ (<["'`]>) $0:=([\\.|<!$1>]*) $1 }
    #
    # "$0" now excludes delimiters because it was
    # explicitly bound only to contents of quoted string



=head2 Grammars

Named rules can be placed in a particular namespace, called a "grammar".
For example:

    grammar Identity {
        rule name :words { Name \: (\N+) }
        rule age  :words { Age  \: (\d+) }
        rule addr :words { Addr \: (\N+) }
        rule desc :words { <name> <age> <addr> }

        # etc.
    }

Then, to access these named rules, call them as if they were (Perl 6) 
methods:

    $id =~ m/ <Identity.desc> /;

B<Note: Perl6::Rules uses a regular package for each grammar you specify,
adding each rule as a subroutine of that package. Be careful not to clobber
your existing packages and classes when defining new grammars>.

Like classes, grammars can inherit:

    grammar Letter {
        rule text     { <greet> <body> <close> }

        rule greet :w { [Hi|Hey|Yo] $to:=(\S+?) , $$}

        rule body     { <line>+ }

        rule close :w { Later dude, $from:=(.+) }

        # etc.
    }

    grammar FormalLetter is Letter {

        rule greet :w { Dear $to:=(\S+?) , $$}

        rule close :w { Yours sincerely, $from:=(.+) }

    }

This syntax is fully supported by Perl6::Rules.

B<Note: Due to bugs in the Perl 5 regex engine, captures that occur in
rules or subrules called in from other grammatical namespaces
may not work correctly under Perl6::Rules, and will frequently
lead to segfaults and bus errors.>


=head1 DEBUGGING

If the module is loaded with the C<-translate> flag:

    use Perl6::Rules -translate;

it translates any subsequent Perl 6 rules back to Perl 5 syntax,
prints the translated source file, and exits before attempting to 
compile it.


If the module is loaded with the C<-debug> flag:

    use Perl6::Rules -debug;

it adds a considerable number of debugging statements into each translated
rule, producing extensive tracking of the construction and matching of each
rule.


The match object (C<$0>) also provides a C<dump> method that shows the
various values that were retrieved from the match.


=head1 LIMITATIONS

This module implements most, but not all, of the proposed Perl 6 semantics.
Generally speaking, a Perl 6 feature has been omitted only where there is
no way (or no efficient way) to implement it within the constraints of the
Perl 5 regex engine.

=over

=item *

Only one C<$(...)> or C<@(...)> is allowed in the replacement text of a
substitution. And the closing paren must be last closing paren of
the string. That is:

    s/ <?ident> <?rnum> /marker for $(lookup($?ident).' '.from_roman($?rnum)) here/

is fine, but:

    s/ <?ident> <?rnum> /marker for $(lookup $?ident) $(from_roman $?rnum) here/

is not.

=item *

The C<:first> (i.e. match once only between resets) modifier is not
implemented.


=item *

The C<:u0>, C<:u1>, C<:u2>, C<:u3> modifiers are not implemented.


=item *

The C<:perl5> modifier is not supported. If you want a Perl 5 pattern
under C<use Perl6::Rules>, just use C<qr/.../> or a raw C</.../>
(i.e. no C<m> before the delimiters).


=item *

"Bare" Perl 6 patterns are not supported. Every Perl 6 pattern must be
specified with an explicit C<rx>, C<m>, C<s>, or C<rule> keyword.
Bare C</.../> patterns and C<qr/.../> patterns are treated as Perl 5 patterns.


=item *

The match string's C<pos> is only set correctly
when the C<:cont> modifier is specified.


=item *

You cannot use arbitrary delimiters when specifying a rule.
Only C<m{...}>, C<m[...]>, C<< m<...> >>, and C<m/.../>
are supported. Likewise for C<rx>, C<rule>, and C<s>.


=item *

Lookbehinds (<after...> and <!after...>) are restricted to fixed length
patterns.


=item *

Repetitions must be statically defined (i.e. a variable can't be used in
an <n,m> qualifier).


=item *

The C<&> operator is not yet implemented.


=item *

Variables used anywhere in a rule/rx pattern must be specified in Perl 6
syntax (i.e. $a[0] always means $a->[0])


=item *

Any subpattern interpolated by a C<< <$scalar> >>, C<< <@array> >>,
C<< <%hash> >>, or C<< <{block}> >> construct must be precompiled
regular expression, not a raw string.


=item *

<.> does not always work correctly (esp. for combining characters) due
to bugs in Perl 5.8.3


=item *

Due to bugs in the handling of match-time interpolations
in the Perl 5.8.3 regex engine, subrules that capture may
produce segfaults during or immediately after the match.


=item *

Due to problems in Perl 5.8.3's handling of lexical variables in
patterns (and especially in code blocks inside patterns), the module
does not allow lexical variables to be used in Perl 6 rules. To 
enforce this, all variables used in a Perl 6 rule must include at
least one explicit C<::> in their name. That is:

    our ($keyword, %valid);

    # and later...

    m/ $::keyword:=(<ident>) <( %::valid{$::keyword} )> /

but not:

    my ($keyword, %valid);

    # and later...

    m/ $keyword:=(<ident>) <( %valid{$keyword} )> /


=item *

The Perl 5 nonstandard C<L&> property (which is equivalent to C<Lu> + C<Ll> +
C<Lt>) has been renamed to C<Lr> (mnemonic: I<L>etter-I<r>egular).
  

=item *

The various "cut" operators (except for C<:>) are not implemented.
That is, C<::>, C<:::>, C<< <commit> >>, and C<< <cut> >> are not 
supported.


=item *

Rules cannot be specified with parameter lists. 
Consequently subrules cannot be called with arguments.


=head1 WARNING

The syntax and semantics of Perl 6 is still being finalized
and consequently is at any time subject to change. That means the
same caveat applies to this module.


=head1 DEPENDENCIES

Filter::Simple
Attribute::Handlers


=head1 AUTHOR

Damian Conway (DCONWAY@cpan.org)


=head1 BUGS AND IRRITATIONS

No doubt there are many. You are strongly advised not to use this module in
production code yet.

Comments, suggestions, and patches are welcome, but due to the volume of
email I now receive from Nigerian widows and dispossessed heirs to mining
fortunes, I have some very tight mail filters deployed. If you'd like
me to actually see your message regarding this module, please include
the marker:

    [P6R]

somewhere in your subject line.

Also please be patient if I am not able to respond immediately (i.e. within
a few months) to your bug report.


=head1 SPONSORSHIP

This module was developed under a grant from The Perl Foundation.
Hence it was made possible by the generosity of people like yourself.
Thank-you.

If you'd like to help the Foundation continue to work for the betterment of 
the entire Perl community you can find out how at:

    http://www.perlfoundation.org/index.cgi?page=contrib


=head1 COPYRIGHT

 Copyright (c) 2004, The Perl Foundation. All Rights Reserved.
 This module is free software. It may be used, redistributed
    and/or modified under the same terms as Perl itself.
