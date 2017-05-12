package Pod::Hlp;

$VERSION = '1.02';

# based on Tom C's:
#package Pod::Text;
# Version 1.01

=head1 NAME

Pod::Hlp - convert POD data to formatted VMS HLP Help module text.

=head1 SYNOPSIS

    use Pod::Hlp;

    pod2hlp("perlfunc.pod",$top_help_level,*Filehandle);

Also:

    pod2hlp < input.pod

Also:

    perl pod2hlb

=head1 DESCRIPTION

Pod::Hlp is a module that can convert documentation in the POD format
(such as can be found throughout the Perl distribution) into formatted 
VMS C<*.HLP> files.  Such files can be inserted into an .HLB library 
through the C<LIBRARY/HELP/REPLACE> system call, or via the use of the 
C<pod2hlb> script supplied with the kit.  A separate F<pod2hlp> program 
is included that is primarily a wrapper for Pod::Hlp.

The single function C<pod2hlp()> can take one, two, or three arguments. 
The first should be the name of a file to read the pod from, or "<&STDIN" 
to read from STDIN.   A second argument, if provided, should be an 
integer indicating the help header level of the file as a whole where 
C<'1'> is the default.  A third argument, if provided, should be a 
filehandle glob where output should be sent.

=head1 AUTHOR

Peter Prymmer E<lt>pvhp@best.comE<gt>

based heavily on Pod::Text by:

Tom Christiansen E<lt>tchrist@mox.perl.comE<gt>

=head1 TODO

Cleanup work.  VT escapes should be substituted for the 
Term::Cap ones.  The input and output locations need to be more 
flexible.

=cut

require Exporter;
@ISA = Exporter;
#@EXPORT = qw(pod2text);

$UNDL = "\x1b[4m";
$INV = "\x1b[7m";
$BOLD = "\x1b[1m";
$NORM = "\x1b[0m";

@head1_freq_patterns            # =head1 patterns which need not be index'ed
    = ("AUTHOR","BUGS","DATE","DESCRIPTION","DIAGNOSTICS",
       "ENVIRONMENT","EXAMPLES","FILES","INTRODUCTION","NAME","NOTE",
       "SEE ALSO","SYNOPSIS","WARNING");

sub pod2hlp {
local($file,$hlp_level,*OUTPUT) = @_;
$hlp_level = '1' if @_<2;
$head1_level = $hlp_level + 1;
$head2_level = $head1_level + 1;
$last_cmd = $hlp_level;
*OUTPUT = *STDOUT if @_<3;

$SCREEN = 72;

$/ = "";

$FANCY = 0;

$cutting = 1;
$DEF_INDENT = 4;
$indent = $DEF_INDENT;
$needspace = 0;

open(IN, $file) || die "Couldn't open $file: $!";

POD_DIRECTIVE: while (<IN>) {
    if ($cutting) {
	next unless /^=/;
	$cutting = 0;
    }
    1 while s{^(.*?)(\t+)(.*)$}{
	$1
	. (' ' x (length($2) * 8 - length($1) % 8))
	. $3
    }me;
    # Translate verbatim paragraph
    if (/^\s/) {
	$needspace = 1;
	output($_);
	next;
    }

sub prepare_for_output {

    s/\s*$/\n/;
    &init_noremap;

    # need to hide E<> first; they're processed in clear_noremap
    s/(E<[^<>]+>)/noremap($1)/ge;
    $maxnest = 10;
    while ($maxnest-- && /[A-Z]</) {
	unless ($FANCY) {
	    s/C<(.*?)>/`$1'/g;
	} else {
	    s/C<(.*?)>/noremap("E<lchevron>${1}E<rchevron>")/ge;
	}
        # s/[IF]<(.*?)>/italic($1)/ge;
        s/I<(.*?)>/*$1*/g;
        # s/[CB]<(.*?)>/bold($1)/ge;
	s/X<.*?>//g;
	# LREF: a manpage(3f)
	m:L<([a-zA-Z][^\s\/]+)(\([^\)]+\))?>:;
	if (defined($2)) {
	    s:L<([a-zA-Z][^\s\/]+)(\([^\)]+\))?>:the $1$2 help page:g;
	}
	else {
	    s:L<([a-zA-Z][^\s\/]+)(\([^\)]+\))?>:the $1 help page:g;
	}
	# LREF: an =item on another manpage
	s{
	    L<
		([^/]+)
		/
		(
		    [:\w]+
		    (\(\))?
		)
	    >
	} {the "$2" entry in the $1 help page}gx;

	# LREF: an =item on this manpage
	s{
	   ((?:
	    L<
		/
		(
		    [:\w]+
		    (\(\))?
		)
	    >
	    (,?\s+(and\s+)?)?
	  )+)
	} { internal_lrefs($1) }gex;

	# LREF: a =head2 (head1?), maybe on a manpage, maybe right here
	# the "func" can disambiguate
	s{
	    L<
		(?:
		    ([a-zA-Z]\S+?) / 
		)?
		"?(.*?)"?
	    >
	}{
	    do {
		$1 	# if no $1, assume it means on this page.
		    ?  "the section on \"$2\" in the $1 help page"
		    :  "the section on \"$2\""
	    }
	}gex;

        s/[A-Z]<(.*?)>/$1/g;
    }
    clear_noremap(1);
}

    &prepare_for_output;

    if (s/^=//) {
	# $needspace = 0;		# Assume this.
	# s/\n/ /g;
	($Cmd, $_) = split(' ', $_, 2);
	# clear_noremap(1);
	if ($Cmd eq 'cut') {
	    $cutting = 1;
	}
	elsif ($Cmd eq 'head1') {
	    makespace();

# Is this ugly or what?
            if ($last_cmd > $head1_level) {
                $last_cmd = $head1_level;
                goto make_head1_anyway;
            }
            for $pat (@head1_freq_patterns) {
                if (/^$pat/i) { goto freqpatt; }
            }
            make_head1_anyway:
# VMS librarian does not like to make n+2 jumps:
            if (($head1_level - $last_cmd)<=1) { 
                $last_cmd = $head1_level;
            }
            else {
                $last_cmd = $last_cmd + 1;
            }

            $hlp_line = $_;
#   The key names for help topics and subtopics can include any
#   printable ASCII characters except those used by LIBRARIAN
#   as either delimiters (space, horizontal tab, and comma) or
#   comments (exclamation point).
            if ($hlp_line =~ s/[\ \t\r\f]+/'_'/eg) {  #\s would match \n
                $hlp_line =~ s/^[_]//;               #trim lead
                $hlp_line =~ s/_$//;                 #trim trail
            }
            chomp($hlp_line);
            $hlp_line = "$last_cmd $hlp_line\n";
            print OUTPUT "$hlp_line";
            freqpatt:
	    print OUTPUT;
	    # print OUTPUT uc($_);
	}
	elsif ($Cmd eq 'head2') {
	    makespace();
	    s/(\w)/\xA7 $1/ if $FANCY;
            $hlp_line = $_;
            if ($hlp_line =~ s/[\ \t\r\f]+/'_'/eg) {  #\s would match \n
                $hlp_line =~ s/^[_]//;               #trim lead
                $hlp_line =~ s/_$//;                 #trim trail
            }
            chomp($hlp_line);

# perlpod.pod only allows for =head1 and =head2 (N.B. relaxed
# with more recent pod specs), nevertheless
# VMS librarian does not like to make n+2 jumps, which
# could still occur if the file began with =head2 e.g.:
            if (($head2_level - $last_cmd)<=1) { 
                $last_cmd = $head2_level;
            } else {
                $last_cmd = $last_cmd + 1;
            }

            $hlp_line = "$last_cmd $hlp_line\n";
            print OUTPUT "$hlp_line";
	    print OUTPUT ' ' x ($DEF_INDENT/2), $_, "\n";
	}
	elsif ($Cmd eq 'over') {
	    push(@indent,$indent);
	    $indent += ($_ + 0) || $DEF_INDENT;
	}
	elsif ($Cmd eq 'back') {
	    $indent = pop(@indent);
	    warn "Unmatched =back\n" unless defined $indent;
	    $needspace = 1;
	}
	elsif ($Cmd eq 'item') {
	    makespace();
	    # s/\A(\s*)\*/$1\xb7/ if $FANCY;
	    # s/^(\s*\*\s+)/$1 /;
	    {
		if (length() + 3 < $indent) {
		    my $paratag = $_;
		    $_ = <IN>;
		    if (/^=/) {  # tricked!
			local($indent) = $indent[$#index - 1] || $DEF_INDENT;
			output($paratag);
			redo POD_DIRECTIVE;
		    }
		    &prepare_for_output;
		    IP_output($paratag, $_);
		} else {
		    local($indent) = $indent[$#index - 1] || $DEF_INDENT;
		    output($_);
		}
	    }
	}
	else {
	    warn "Unrecognized directive: $Cmd\n";
	}
    }
    else {
	# clear_noremap(1);
	makespace();
	output($_, 1);
    }
}

close(IN);

}

#########################################################################

sub makespace {
    if ($needspace) {
	print OUTPUT "\n";
	$needspace = 0;
    }
}

sub bold {
    my $line = shift;
    return $line if $use_format;
    $line =~ s/(.)/$1\b$1/g;
    return $line;
}

sub italic {
    my $line = shift;
    return $line if $use_format;
    $line =~ s/(.)/$1\b_/g;
    return $line;
}

# Fill a paragraph including underlined and overstricken chars.
# It's not perfect for words longer than the margin, and it's probably
# slow, but it works.
sub fill {
    local $_ = shift;
    my $par = "";
    my $indent_space = " " x $indent;
    my $marg = $SCREEN-$indent;
    my $line = $indent_space;
    my $line_length;
    foreach (split) {
	my $word_length = length;
	$word_length -= 2 while /\010/g;  # Subtract backspaces

	if ($line_length + $word_length > $marg) {
	    $par .= $line . "\n";
	    $line= $indent_space . $_;
	    $line_length = $word_length;
	}
	else {
	    if ($line_length) {
		$line_length++;
		$line .= " ";
	    }
	    $line_length += $word_length;
	    $line .= $_;
	}
    }
    $par .= "$line\n" if $line;
    $par .= "\n";
    return $par;
}

sub IP_output {
    local($tag, $_) = @_;
    local($tag_indent) = $indent[$#index - 1] || $DEF_INDENT;
    $tag_cols = $SCREEN - $tag_indent;
    $cols = $SCREEN - $indent;
    $tag =~ s/\s*$//;
    s/\s+/ /g;
    s/^ //;
    no strict;
    $str = "format OUTPUT = \n"
	. (" " x ($tag_indent))
	. '@' . ('<' x ($indent - $tag_indent - 1))
	. "^" .  ("<" x ($cols - 1)) . "\n"
	. '$tag, $_'
	. "\n~~"
	. (" " x ($indent-2))
	. "^" .  ("<" x ($cols - 5)) . "\n"
	. '$_' . "\n\n.\n1";
    #warn $str; warn "tag is $tag, _ is $_";
    {
     # Avoid "redefined OUTPUT format" warnings.
     # perldiag in 5.6.1 recommends no warnings pragma but this works
     # with 5.005_03
        local $^W = 0;
        eval $str || die;
    }
    write OUTPUT;
}

sub output {
    local($_, $reformat) = @_;
    no strict;
    if ($reformat) {
	$cols = $SCREEN - $indent;
	s/\s+/ /g;
	s/^ //;
	$str = "format OUTPUT = \n~~"
	    . (" " x ($indent-2))
	    . "^" .  ("<" x ($cols - 5)) . "\n"
	    . '$_' . "\n\n.\n1";
        {
         # Avoid "redefined OUTPUT format" warnings.
         # perldiag in 5.6.1 recommends no warnings pragma but this works
         # with 5.005_03
            local $^W = 0;
	    eval $str || die;
        }
	write OUTPUT;
    } else {
	s/^/' ' x $indent/gem;
	s/^\s+\n$/\n/gm;
	print OUTPUT;
    }
}

sub noremap {
    local($thing_to_hide) = shift;
    $thing_to_hide =~ tr/\000-\177/\200-\377/;
    return $thing_to_hide;
}

sub init_noremap {
    die "unmatched init" if $mapready++;
    if ( /[\200-\377]/ ) {
	warn "hi bit char in input stream";
    }
}

sub clear_noremap {
    my $ready_to_print = $_[0];
    die "unmatched clear" unless $mapready--;
    tr/\200-\377/\000-\177/;
    # now for the E<>s, which have been hidden until now
    # otherwise the interative \w<> processing would have
    # been hosed by the E<gt>
    s {
	    E<	
	    ( [A-Za-z]+ )	
	    >	
    } {
	 do {
	     defined $HTML_Escapes{$1}
		? do { $HTML_Escapes{$1} }
		: do {
		    warn "Unknown escape: $& in $_";
		    "E<$1>";
		}
	 }
    }egx if $ready_to_print;
}

sub internal_lrefs {
    local($_) = shift;
    s{L</([^>]+)>}{$1}g;
    my(@items) = split( /(?:,?\s+(?:and\s+)?)/ );
    my $retstr = "the ";
    my $i;
    for ($i = 0; $i <= $#items; $i++) {
	$retstr .= "C<$items[$i]>";
	$retstr .= ", " if @items > 2 && $i != $#items;
	$retstr .= " and " if $i+2 == @items;
    }

    $retstr .= " entr" . ( @items > 1  ? "ies" : "y" )
	    .  " elsewhere in this document ";

    return $retstr;

}

BEGIN {

%HTML_Escapes = (
    'amp'	=>	'&',	#   ampersand
    'lt'	=>	'<',	#   left chevron, less-than
    'gt'	=>	'>',	#   right chevron, greater-than
    'quot'	=>	'"',	#   double quote
    'sol'	=>	'/',	#   solidus or forward slash
    'verbar'	=>	'|',	#   vertical bar or pipe

    "Aacute"	=>	"\xC1",	#   capital A, acute accent
    "aacute"	=>	"\xE1",	#   small a, acute accent
    "Acirc"	=>	"\xC2",	#   capital A, circumflex accent
    "acirc"	=>	"\xE2",	#   small a, circumflex accent
    "AElig"	=>	"\xC6",	#   capital AE diphthong (ligature)
    "aelig"	=>	"\xE6",	#   small ae diphthong (ligature)
    "Agrave"	=>	"\xC0",	#   capital A, grave accent
    "agrave"	=>	"\xE0",	#   small a, grave accent
    "Aring"	=>	"\xC5",	#   capital A, ring
    "aring"	=>	"\xE5",	#   small a, ring
    "Atilde"	=>	"\xC3",	#   capital A, tilde
    "atilde"	=>	"\xE3",	#   small a, tilde
    "Auml"	=>	"\xC4",	#   capital A, dieresis or umlaut mark
    "auml"	=>	"\xE4",	#   small a, dieresis or umlaut mark
    "Ccedil"	=>	"\xC7",	#   capital C, cedilla
    "ccedil"	=>	"\xE7",	#   small c, cedilla
    "Eacute"	=>	"\xC9",	#   capital E, acute accent
    "eacute"	=>	"\xE9",	#   small e, acute accent
    "Ecirc"	=>	"\xCA",	#   capital E, circumflex accent
    "ecirc"	=>	"\xEA",	#   small e, circumflex accent
    "Egrave"	=>	"\xC8",	#   capital E, grave accent
    "egrave"	=>	"\xE8",	#   small e, grave accent
    "ETH"	=>	"\xD0",	#   capital Eth, Icelandic
    "eth"	=>	"\xF0",	#   small eth, Icelandic
    "Euml"	=>	"\xCB",	#   capital E, dieresis or umlaut mark
    "euml"	=>	"\xEB",	#   small e, dieresis or umlaut mark
    "Iacute"	=>	"\xCD",	#   capital I, acute accent
    "iacute"	=>	"\xED",	#   small i, acute accent
    "Icirc"	=>	"\xCE",	#   capital I, circumflex accent
    "icirc"	=>	"\xEE",	#   small i, circumflex accent
    "Igrave"	=>	"\xCD",	#   capital I, grave accent
    "igrave"	=>	"\xED",	#   small i, grave accent
    "Iuml"	=>	"\xCF",	#   capital I, dieresis or umlaut mark
    "iuml"	=>	"\xEF",	#   small i, dieresis or umlaut mark
    "Ntilde"	=>	"\xD1",	#   capital N, tilde
    "ntilde"	=>	"\xF1",	#   small n, tilde
    "Oacute"	=>	"\xD3",	#   capital O, acute accent
    "oacute"	=>	"\xF3",	#   small o, acute accent
    "Ocirc"	=>	"\xD4",	#   capital O, circumflex accent
    "ocirc"	=>	"\xF4",	#   small o, circumflex accent
    "Ograve"	=>	"\xD2",	#   capital O, grave accent
    "ograve"	=>	"\xF2",	#   small o, grave accent
    "Oslash"	=>	"\xD8",	#   capital O, slash
    "oslash"	=>	"\xF8",	#   small o, slash
    "Otilde"	=>	"\xD5",	#   capital O, tilde
    "otilde"	=>	"\xF5",	#   small o, tilde
    "Ouml"	=>	"\xD6",	#   capital O, dieresis or umlaut mark
    "ouml"	=>	"\xF6",	#   small o, dieresis or umlaut mark
    "szlig"	=>	"\xDF",	#   small sharp s, German (sz ligature)
    "THORN"	=>	"\xDE",	#   capital THORN, Icelandic
    "thorn"	=>	"\xFE",	#   small thorn, Icelandic
    "Uacute"	=>	"\xDA",	#   capital U, acute accent
    "uacute"	=>	"\xFA",	#   small u, acute accent
    "Ucirc"	=>	"\xDB",	#   capital U, circumflex accent
    "ucirc"	=>	"\xFB",	#   small u, circumflex accent
    "Ugrave"	=>	"\xD9",	#   capital U, grave accent
    "ugrave"	=>	"\xF9",	#   small u, grave accent
    "Uuml"	=>	"\xDC",	#   capital U, dieresis or umlaut mark
    "uuml"	=>	"\xFC",	#   small u, dieresis or umlaut mark
    "Yacute"	=>	"\xDD",	#   capital Y, acute accent
    "yacute"	=>	"\xFD",	#   small y, acute accent
    "yuml"	=>	"\xFF",	#   small y, dieresis or umlaut mark

    "lchevron"	=>	"\xAB",	#   left chevron (double less than)
    "rchevron"	=>	"\xBB",	#   right chevron (double greater than)
);
}

1;
