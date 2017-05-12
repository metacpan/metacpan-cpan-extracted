use strict;

package Parse::YALALR::Read;

#BEGIN { $SIG{INT} = sub { use Carp; confess "interrupted" } };

sub read {
    my ($class, $lang, $input) = @_;
    my $self = bless { language => $lang }, ref $class || $class;
    $self->read_parser($input);
}

sub read_parser {
    my ($self, $input) = @_;

    my ($pre, $rules, $post);

    # Prolog
    $pre = eval { $self->read_pre($input); };
    die "Parse error: $@" if $@;

    # Main body
    $rules = eval { $self->read_main_body($input); };
    die "Parse error: $@" if $@;

    while (<$input>) {
	$post .= $_;
    }

    $self->{pre} = $pre;
    $self->{rules} = $rules;
    $self->{post} = $post;

    return $self;
}

sub read_pre {
    my ($self, $input) = @_;
    my $line = <$input>;

    my $pre = "";

    my $state = 'directives';

    while (1) {
	die "Parse error: Premature end of file at line $." if !defined $line;
	last if $line =~ /^\%\%/;
	$line =~ s/^\s+//;

	# Skip blank lines (often caused by something below)
	if ($line !~ /\S/) {
	    $line = <$input>;

	# Discard comments
	} elsif ($line =~ /^\/\*/) {
	    my $startline = $.;
	    $self->read_until(\$line, $input, '\*\/')
	      or die "Parse error: EOF in comment starting at line $startline";

	# Copy over any %{ ... %} sections
	} elsif ($line eq "\%{\n") {
	    $line = <$input>;
	    my $rest = $self->read_until(\$line, $input, '\%\}')
	      or die "Parse error: EOF looking for %}";
            # Don't collect final %}
	    $pre .= substr($rest, 0, -2);

        # Handle token declarations 
	} elsif ($line =~ /^\%(left|right|nonassoc|token|term)/g) {
	    my $associativity = $1;
	    $line = substr($line, 1 + pos($line));
	    $self->read_tokens(\$line, $input, $associativity);

        # Handle symbol type declarations 
	} elsif ($line =~ /^\%type\s+\<.*?\>/g) {
	    my $type = $1;
	    $line = substr($line, pos($line));
	    my @symbols = $self->read_symbols(\$line, $input);
	    $self->{symbol_type}{$_} = $type foreach (@symbols);
            if ($line =~ /^;/) { $line = substr($line, 1) };

        # Handle %start declaration
	} elsif ($line =~ /^\%start\s+(.*)/) {
	    die "Parse error line $.: \%start redefines start symbol (was $self->{start_symbol})"
	      if exists $self->{start_symbol};
	    $self->{start_symbol} = $1;
	    $line = <$input>;

	# Handle %union declaration
	} elsif ($line =~ /^\%union/) {
	    my $union = $self->read_until(\$line, $input, '\{');
#            print STDERR "<UPTO '{'>$union</UPTO>\n";
            my $depth = 1;
            while ($depth) {
                my $u;
                $union .= ($u = $self->read_until(\$line, $input, '[\{\}]'));
#                print STDERR "<UPTO depth=$depth>$u";
                if ($u =~ /\{$/) {
                    $depth++;
                } elsif ($u =~ /\}$/) {
                    $depth--;
                } else {
                    die "Parse error: EOF in %union declaration";
                }
#                print STDERR "</UPTO depth=$depth>\n";
            }
            $self->skip_ws(\$line, $input);
            $line =~ s/^;//;
	    $self->{value_union} = $union;

        # Die on anything else
	} else {
	    die "Parse error: Unrecognized directive in line $.: $line";
	}
    }

    return $pre;
}

sub read_tokens {
    my ($self, $line, $input, $associativity) = @_;

    $associativity = 'token' if $associativity eq 'term';

    my $type = '<default>';

    if ($$line =~ s/^\s*(\<.*?\>)//) {
	$type = $1;
        $self->skip_ws($line, $input);
    }

    my @tokens = $self->read_symbols($line, $input);

    $self->{token_type}{$_} = $type foreach (@tokens);
    push(@{$self->{tokens}}, @tokens);
    push(@{$self->{precedence}}, [ $associativity, \@tokens ]);
    return 1;
}

# Read a bunch of symbols -- tokens or nonterminals -- up to the next % or ;
sub read_symbols {
    my ($self, $line, $input) = @_;

    my @symbols;
    while (1) {
	$self->skip_ws($line, $input);
	last if ($$line =~ /^[\%;]/);
	my $symbol = $self->read_symbol($line, $input);
	push(@symbols, $symbol);
    }

    return @symbols;
}

sub read_main_body {
    my ($self, $input) = @_;
    my $line = <$input>;
    die "Parse error: Premature EOF in main body at line $." if !defined $line;

    my @rules;
    while (1) {
	my @ruleset = $self->read_ruleset(\$line, $input);
	last if @ruleset == 0;
	push(@rules, @ruleset);
    }

    return \@rules;
}

# Returns : ( [ lhs, [ symbol | code ] ] )
sub read_ruleset {
    my ($self, $line, $input) = @_;

    my @rules;

    defined $self->skip_ws($line, $input)
        or return ();

    return () if $$line =~ /^\%/;
    my $lhs = $self->read_symbol($line, $input);

    $self->skip_ws($line, $input);

    die "Parse error: colon expected in production at line $."
	if ($$line !~ /^:/);
    $$line = substr($$line, 1);

    my $sawnext;
    while (1) {
	my @rhs;
	my $precedence_progenitor = undef; # Paranoia

	defined $self->skip_ws($line, $input)
            or last;

        while (1) {
#            print "LINE=$$line\n";
	    my $startline = $.;
	    if ($$line =~ /^:/) {
                # Saw next rule; back up one symbol and remember we're done
                $$line = pop(@rhs)." $$line";
                $sawnext = 1;
                last;
	    } elsif ($$line =~ /^\%\%/) {
                # Saw %%, remember we're done
                $sawnext = 1;
                last;
	    } elsif ($$line =~ /^\|/) {
                # Saw vbar, stop this rhs
                $$line = substr($$line, 1);
                last;
	    } elsif ($$line =~ /^\;/) {
                # Saw ; (means nothing any more)
                $$line = substr($$line, 1);
	    } elsif ($$line =~ /^\{:/) {
		$$line = substr($$line, 2);
		my $code = $self->read_until($line, $input, ':\}')
		  or die "Parse error: EOF in {: code section starting at line $startline";
		$code = substr($code, 0, -2);
		push(@rhs, (bless \$code, $self->{language}.'CODE'));
	    } elsif ($$line =~ /^\{\?/) {
		my $code = $self->read_until($line, $input, '\?\}')
		  or die "Parse error: EOF in {? code section starting at line $startline";
		$code = substr($code, 0, -2);
		push(@rhs, (bless \$code, $self->{language}.'CONDITION'));
	    } elsif ($$line =~ /^\{/) {
		$$line = substr($$line, 1);
		my $code = $self->read_code($line, $input)
		  or die "Parse error: EOF in { code section starting at line $startline";
		$code = substr($code, 0, -1);
		push(@rhs, (bless \$code, $self->{language}.'CODE'));
	    } elsif ($$line =~ /^\/\*/) {
		$self->read_comment($line, $input);
	    } elsif ($$line =~ /^\%prec\s*/g) {
		$$line = substr($$line, pos($$line));
		$precedence_progenitor = $self->read_symbol($line, $input);
		# BUG(?): accepts "lhs: a b %prec x c d"
		# (equiv to "lhs: a b c d %prec x")
	    } else {
		my $sym = $self->read_symbol($line, $input);
		push(@rhs, $sym);
#                print "Got symbol $sym, line=$$line\n";
	    }
	    
	    defined $self->skip_ws($line, $input)
                or last;
	}

	push(@rules, [ $lhs, \@rhs, $precedence_progenitor ]);

	last if $sawnext;
    }

#    print "Ruleset for $lhs done $., next LINE=$$line\n";

    return @rules;
}

sub read_symbol {
    my ($self, $line, $input) = @_;

    my $symbol;
#    print "read_symbol($$line)\n";
    ($symbol) = ($$line =~ /^\s*(\w+)/)
        or ($symbol) = ($$line =~ /^(\'.*?\')/)
            or ($symbol) = ($$line =~ /^(\".*?\")/);

    die "Parse error: Expected symbol, none found at line $."
	if !defined $symbol;
    
    $$line = substr($$line, length($symbol));
    return $symbol;
}

# Assume there is a newline at the end of every line. Then this routine
# becomes the main source of input.
sub skip_ws {
    my ($self, $line, $input) = @_;
    my $ws = '';
    my $comment = 0;
    while (1) {
	if (!$comment && $$line =~ /^\s*\/\*/g) {
	    # Beginning of C style comment: /* comment
	    $ws .= substr($$line, 0, pos($$line));
	    $$line = substr($$line, pos($$line));
	    $comment = 1;
	} elsif ($comment && $$line =~ /\*\//g) {
	    # End of C style comment: */ stuff
	    $ws .= substr($$line, 0, pos($$line));
	    $$line = substr($$line, pos($$line));
	    $comment = 0;
	} elsif ($comment) {
	    # Middle of C style comment
	    $ws .= $$line;
	    $$line = <$input>;
	    die "Parse error: EOF in comment" if !defined $$line;
	} elsif ($$line =~ m,^\s*//,) {
	    # C++ style comments: // comment<newline>
	    $ws .= $$line;
	    $$line = <$input>;
	    die "Parse error: EOF in // comment at line $." if !defined $$line;
	} elsif ($$line =~ /^\S/) {
	    # Good stuff
	    return $ws;
	} else {
	    # Whitespace
	    $$line =~ s/^(\s+)//;
	    $ws .= $1;

	    if ($$line eq '') { $$line = <$input>; }
	    return undef if !defined $$line;
        }
    }
}

sub read_comment {
    my ($self, $line, $input) = @_;
    my $comment;
    if ($$line =~ /\*\//) {
	($comment) = $$line =~ s/\/\*(.*?)\*\///;
    } else {
	$$line = substr($line, 2); # Chop off leading /*
	while (1) {
	    $_ = <$input>;
	    die "Parse error: EOF in comment" if !defined $_;
	    if (/\*\//g) {
		$comment = $$line . substr($_, 0, (pos) - 2);
		$$line = substr($_, pos);
	    }
	}
    }

    return $comment;
}

sub read_code {
    my ($self, $line, $input) = @_;

    my $code = '';
    my $level = 1; # {} nesting level

    # Handle a few special things:
    # "double quoted strings"
    # 'single quoted strings'
    # { balanced {} exprs }

    while ($level > 0) {
	$self->skip_ws($line, $input);
	# Scan to next ", ', {, }, or / (the last for comment starts)
	if ($$line =~ /[\"\'\{\}\/]/g) {
	    $code .= substr($$line, 0, pos($$line));
	    my $char = substr($$line, pos($$line) - 1, 1);
	    $$line = substr($$line, pos($$line));
	    
	    if ($char eq '"') {
		if ($$line =~ /([^\"\\]|\\.)*\"/g) {
		    $code .= substr($$line, 0, pos($$line));
		    $$line = substr($$line, pos($$line));
		} else {
		    defined (my $i = <$input>)
		      or die "Parse error: EOF in double-quoted string";
		    $$input .= $i;
		}
	    } elsif ($char eq '\'') {
		if ($$line =~ /([^\'\\]|\\.)*\'/g) {
		    $code .= substr($$line, 0, pos($$line));
		    $$line = substr($$line, pos($$line));
		} else {
		    defined(my $i = <$input>)
		      or die "Parse error: EOF in single-quoted string";
		    $$line .= $i;
		}
	    } elsif ($char eq '{') {
		$level++;
	    } elsif ($char eq '}') {
		$level--;
	    }
	} else {
	    # No interesting characters found
	    $code .= $$line;
	    defined ($$line = <$input>)
	      or die "Parse error: EOF in { code section before final close brace";
	}
    }

    return $code;
}

######## UTILITY ###########

sub read_until {
    my ($self, $line, $input, $pattern) = @_;
    my $buf = $$line;
    while ($buf !~ /$pattern/) {
	$$line = <$input>;
	return undef if !defined $$line;
	$buf .= $$line;
    }
    $buf =~ /$pattern/g;
    $$line = substr($buf, pos($buf));
    return substr($buf, 0, pos($buf));
}

1;
