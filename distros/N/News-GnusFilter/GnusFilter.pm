# News::GnusFilter: based on tchrist's msgchk
# reworked for Gnus by Joe Schaefer <joe+cpan@sunstarsys.com>
# $Id: GnusFilter.pm,v 1.6 2001/09/16 04:39:55 joe Exp $

package News::GnusFilter;
$VERSION = '0.55';

use 5.006;
use strict;

=head1 NAME

News::GnusFilter - package for scoring usenet posts

Version: 0.55 ($Revision: 1.6 $)

=head1 SYNOPSIS

# I<~/.gnusfilter> - scoring script

  require 5.006;
  use strict;
  use News::GnusFilter qw/:tests groan references NSLOOKUP VERBOSE/;

  NSLOOKUP = ""; # disables nslookups for bogus_address test
  VERBOSE  = 1;  # noisier output for debugging

  my $goof = News::GnusFilter->set_score( {
                                  rethreaded     => 80,
                                  no_context     => 60,
                              } );

# standard tests - see B<MESSAGE TESTS> for details

  missing_headers;
  bogus_address;
  annoying_subject;
  cross_post;
  mimes;
  lines_too_long;
  control_characters;
  miswrapped;
  misattribution;
  jeopardy_quoted;
  check_quotes; # runs multiple tests on quoted paragraphs
  bad_signature;

# custom tests - see B<WRITING HEADERS and SCORING>

  if (check_quotes and not references) {
      $goof->{rethreaded} = groan "Callously rethreaded";
  }

  if (references and not check_quotes) {
      $goof->{no_context} = groan "Missing context";
  }

__END__

Your I<GnusFilter script> should be installed as a mime-decoder
hook for gnus.

=head1 DESCRIPTION

News::GnusFilter is a pure-Perl package for scripting an inline
message filter.  It adds "Gnus-Warning:" headers when presented with
evidence of atypical content or otherwise nonstandard formatting for
usenet messages.

News::GnusFilter should be drop-in compatible with other newsreaders
that are capable of filtering a usenet posting through an external application
prior to display.  See the B<CONFIGURATION> section below for
descriptions of tunable parameters, and the B<MESSAGE TESTS> section
for descriptions of the exported subroutines.

The strange yet powerful correlation between usenet cluelessness
and bunk-peddling is best summarised in the following quote:

"Opinions may of course differ on this topic, but wouldn't it be better
to persuade the hon. Usenaut, as a first priority, to post accurate
information, before persuading them to abandon this remarkably
accurate indicator of usenet bogosity?"

      -- Alan Flavell in comp.lang.perl.misc


=head1 CONFIGURATION

=head2 Lisp for I<.gnus> File

 (add-hook 'gnus-article-decode-hook '(lambda ()
    (gnus-article-decode-charset)
      (let ((coding-system-for-read last-coding-system-used)
	   (coding-system-for-write last-coding-system-used))
       (call-process-region (point-min) (point-max)
	   "/path/to/gnusfilter" t (current-buffer))
 )))

The recommended installation path for your script is I<~/.gnusfilter>.

=cut

##################################################
use Exporter;
use base "Exporter";

BEGIN {

    no strict;

()=<<'=pod'; # Abigail's pod tangler

=head2 General Parameters and Exported Symbols

These are the export lists for News::GnusFilter.  See the
B<Export> manpage for more details.

=pod

    my %parameters =
       (
	 HEADER         => "Gnus-Warning", # header added
	 NSLOOKUP       => "nslookup",     # '' avoids DNS lookups
	 PASSTHRU_BYTES => 8192,           # filter disabled
	 LINE_LEN       => 80,             # columns
	 EGO            => 10,             # self-ref's in new text
	 TOLERANCE      => 50,             # % quoted text
 	 MAX_CONTROL    => 5,              # control chars
	 MIN_LINES      => 20,             # short posts are OK
	 SIG_LINES      => 4,              # acceptable sig lines
	 NEWSGROUPS     => 2,              # spam cutoff
	 FBI            => 100,            # tolerable bogosity level

	 VERBOSE        => 0,              # toggles debugging output
       );

    @EXPORT_OK = keys %parameters;
    %EXPORT_TAGS = (
		    params => \@EXPORT_OK,
		     tests => [
			        qw/
		                   missing_headers   bogus_address
                                   annoying_subject  cross_post
                                   lines_too_long    control_characters
		                   miswrapped        check_quotes
                                   jeopardy_quoted   misattribution
                                   bad_signature     mimes
				  /
                              ],
		   );
    @EXPORT = (
	        @{$EXPORT_TAGS{tests}},
		qw/
		   groan groanf
                   lines references newsgroups head body paragraphs sig
	          /
	      );

=head2 Import Options

By default, GnusFilter exports all the standard C<:tests>.
It also provides access to the message itself via the C<head()>,
C<body()>, C<lines()>, C<paragraphs()>, and C<sig()> functions.
See B<WRITING HEADERS and SCORING> for details on C<groan()> and
C<groanf()>.

If you need to tune some of the parameters, they are not exported
by default, so you can import them either by name or all at once
with the C<:params> tag:

  use News::GnusFilter qw/ :tests :params /;
  FBI = 200;    # raise tolerable bogosity level to 200
  VERBOSE = 1;  # enable debugging output
  HEADER = "X-Filter";
  ...

The parameters are exported as lvalued subs, and is the only
place where this module uses special features of perl 5.6+.

=for perl
end of tangled pod

=cut

    #install parameters (as lvalued "constants" :)

    while ( my ($key,$val) = each %parameters ) {
	*$key = sub () :lvalue { $val };
    }

}


SCORE: {

=head1 WRITING HEADERS and SCORING

=head2 B<groan, groanf>

C<groan()> and C<groanf()> are the analogs of print
and printf, and are exported by default. The value
of the warning header may be changed globally via
HEADER:

  HEADER="X-Format-Warning"; # overrides default "Gnus-Warning"
  groan "mycheck failed" unless mycheck(body);

=cut

  sub groan {
      my $header = HEADER . ": " . shift;
      print $header, @_, "\n";
  }

  sub groanf {
      my $header = HEADER . ": " . shift;
      printf $header . "\n", @_;
  }


()=<<'=pod'; # Abigail's pod tangler

=head2 Default Score Settings

These settings are modifiable through the C<set_score> sub.
See the description in B<Scoring API> below for details.

=pod

# scoring parameters

  my %goof;                   # counts occurrence of each error type
  my %weight =                # error type => default score

 (	                      # typical range of %goof value:
  totalquote       => 100,    #
  jeopardy_quoted  =>  80,    # boolean (0-1)
  misattribution   =>  60,    #
  lines_too_long   =>  50,    #

  missing_headers  =>  50,    # 0-2
  mime_crap        =>  40,    # 0-3?     :
  annoying_subject =>  40,    # ~0-4
  cross_post       =>  30,    # 0,~2-4
  bogus_address    =>  30,    # 0-3      : 822, dns
  miswrapped       =>  30,    # ~0-5     : lines (up to 5)
  control_chars    =>  20,    # 0-5      : up to 5 chars
  ego              =>   5,    # 0,~10-20 : I me my count
  overquoted       =>   2,    # 0-50     : percentage over TOLERANCE
  bad_signature    =>   2,    # 0,5-20   : lines

  code             =>  -5,    # 0,~10-30

 );


# I<set_score> - scripter's interface to %goof and %weight

    sub set_score {
	my $href = pop @_;

	# override weight table
	@weight{ keys %$href } = values %$href if ref $href;

	return bless \%goof;
    }

# I<score> - returns Flavell Bogosity Index

    sub score {
	my $score = 0;
	$score += $goof{$_} * $weight{$_}
	    for grep {exists $weight{$_}} keys %goof;
	return $score;
    }

=head2 Scoring API - B<set_score, score>

C<set_score()> provides access to the C<%goof> and C<%weight> hashes,
which form the basis of the Flavell Bogosity Index calculator
C<score()>.  The B<SYNOPSIS> contains a sample usage.

C<score()> calculates the current bogosity index based on the rules
applied so far. Neither C<set_score> nor C<score> are importable,
so script writers should use OO-like syntax or their package-qualified
names.

B<Note:> GnusFilter is I<not> an OO package-
although C<set_score()> returns a blessed reference to C<%goof>,
the final automatic C<score()> calculation is not OO. However,
if necessary it can be disabled by setting C<FBI = 0> in your
script.

   use News::GnusFilter qw/:tests FBI/;
   FBI = 0;


=for perl
end of tangled pod

=cut

    my $end = sub {};   # dummy for END hook- replaced in AUTOLOAD
    my $check_passthru; # ensures $end hook is only installed once
    END { $end -> (); }


    sub AUTOLOAD {
	unless ($check_passthru) {
            # only enter this block one time
	    $check_passthru = 1;

	    # BEGIN
	    print News::GnusFilter::Etiquette->header_string, "\n";

	    # END hook to print body and sig
	    $end = sub {
		groanf "Flavell Bogosity Index %d exceeds %d" =>
		    ( score(), FBI )
			if FBI > 0 and score() > FBI;

		print "\n", body();
		print "\n-- \n", sig() if sig() ne '';
	    };


	    my ($body, $sig) = map {length News::GnusFilter::Etiquette->$_}
	      qw/body   sig/;

	    # CHECK PASSTHRU MODE
	    if ($body + $sig > PASSTHRU_BYTES) {
		groanf "filter disabled " .
		    "(%d bytes in message exceeds %d limit)" =>
			($body + $sig, PASSTHRU_BYTES);
		exit 0;
	    }

	}

	# fetch and install sub; update %goof value

	no strict qw/refs vars/;
	(my $field = $AUTOLOAD) =~ s/.*:://;
	my @result = News::GnusFilter::Etiquette -> $field;

	# @result ~  ( { goof => value ... }, $field's weight  )
	#               hashref is optional

	$goof{$field} += $result[-1] || 0 if exists $weight{$field};

	if (ref $result[0]) {
            my $scores = shift @result;
	    $goof{$_} += $scores->{$_} for keys %$scores;
	}

	# MEMOIZE to avoid redundant warnings and prevent
        # overcalculated %goof values
	&{*$field = sub {wantarray ? @result : join "\n", grep {defined} @result}};

    }

}



##################################################
# internal package

package News::GnusFilter::Etiquette;

BEGIN {News::GnusFilter->import(qw/:params groanf groan/)}

sub strip_attribution;
sub strip_signature;
sub unquote_wrap;

sub AUTOLOAD {
    no strict 'vars';
    (my $field = uc $AUTOLOAD) =~ s/.*:://;
    News::GnusFilter::Message -> get_message -> $field;
}

=head1 MESSAGE TESTS

These are the exported functions that form the basis
of a GnusFilter script.  These functions are memoized
to avoid repeat warnings and overscoring.

=over 4

=item B<misattribution>

Checks for proper attribution in quoted text.

=item B<cross_post>

Warns of newsgroup spamming (level determined by C<NEWSGROUPS>).
On an original post, it returns total number of posted groups,
on followups it just returns 1.

=cut

sub misattribution {
    length(attribution()) ? 0 :
	references() ? groan "Missing attribution" : 0
}


sub cross_post {
  for (newsgroups()) {
    return 0 unless  1 + y/,// > NEWSGROUPS;
    groan "Excessive cross-posting.";
    return  1 + (references() ? 0 : y/,// );
  }
}


=item B<bogus_address>

Validates the Reply-To: (or From:, if not present) header
using rfc822 and a dns lookup on the domain. Setting C<NSLOOKUP>
to a false value will disable the dns lookup- otherwise
C<NSLOOKUP> should point to the location of your nslookup(8)
binary.

=cut

sub bogus_address {
    my $address = reply_to() || from();

    if ($address =~ /(remove|spam)/i) {
        groan "Munged return address suspected, found `$1' in from";
    }

    my($host) = $address =~ /\@([a-zA-Z0-9_.-]+)/;
    return( 2 * ck822($address) or dns_check($host) );   # very slow!
}


=item B<control_characters>

Look for control characters in the message body.
returns their number (up to C<MAX_CONTROL>).

=cut

sub control_characters {
    my $lineno = 0;
    my $max = MAX_CONTROL;
    for (lines()) {
        $lineno++;
        if (/(?=[^\s\b])([\000-\037])/) {
            groanf "Control character (char %#o) appears at line %d of body",
                ord $1, $lineno;
        }
        if (/([\202-\257])/) {
            groanf "MS-ASCII character (char %#o) appears at line %d of body",
                ord $1, $lineno;
        }

	last if --$max <= 0;
    }
    return MAX_CONTROL - $max;
}

=item B<lines_too_long>

Check for oversized lines as set by C<LINE_LEN>.
The return value is boolean.

=cut

sub lines_too_long {
    my $line_count = scalar @{ [ lines() ] };
    my ($long_lines, $longest_line_data, $longest_line_number) = (0,'',0);
    my $lineno = 0;
    for (lines()) {
        $lineno++;
        next if /^[+-]/;  #skip patch diffs

        if (length() > LINE_LEN) {
            $long_lines++;
            if (length() > length($longest_line_data)) {
                $longest_line_data = $_;
                $longest_line_number = $lineno;
            }
        }
    }
    if ($long_lines) {
        my $warning = sprintf "%d of %d lines exceed maxlen %d," =>
           ($long_lines, $line_count, LINE_LEN);

        if (content_type()=~/multipart|mime/i) {
	    groanf "$warning longest is %d bytes" =>
		length($longest_line_data);
	} else {
	    groanf "$warning longest is #%d at %d bytes" =>
		( $longest_line_number, length($longest_line_data) );
	}
    }

    return ($long_lines > 0);
}

=item B<missing_headers>

Verifies existence of Subject: and References: header
as necessary.

=cut

sub missing_headers {
  my $result = 0;
    if (subject() !~ /\S/) {
       $result += groan "Missing required subject header";
    }
    if (newsgroups() && subject() =~ /^\s*Re:/i && !references()) {
       $result += groan "Followup posting missing required references header";
    }
  return $result;
}

=item B<miswrapped>

Tests for miswrapped lines in quoted and regular text. Returns number
of occurrences, which may be excessive for things like posted logfiles.

=cut

sub miswrapped {
    my($bq1, $bq2) = (0,0);
    for (paragraphs()) {
	next unless /\A(^\S.*){2,}\Z/ms;  # no indented blocks

	while (/^>[^\S\n]*\S.*?\n\s*[A-Za-z!;.,?].*\n>/mg) {
	    groan "Incorrectly wrapped quoted text" unless $bq1;
	    $bq1++;
	}
	next if /^(([ \w]*>|[^\w\s]+).*\n)(\2.*\n)+/m; # quoted
	my $count = 0;
	$count++ while
	  /^\s*[^>#\%\$\@].{60,}\n[^>].{1,20}[^{}();|&]\n(?=[^>].{60})/gm;

	if ($count > 0) {
	    groan "Incorrectly wrapped regular text" unless $bq2;
	    $bq2+= $count;
	}
    }

    return $bq1 + $bq2;
}

=item B<jeopardy_quoted>

Tests for upside-down posting style (newsgroup replies should follow
quoted text, not vice-versa). return value is boolean.

=cut

sub jeopardy_quoted {

    for (body(), sig()) {
	unquote_wrap;
	strip_attribution;
	strip_signature;

	# tchrist wrote:
	# check quotation at bottom but nowhere else
	# XXX: these can go superlong superlong!  i've added
	#      some more anchors and constraints to try to avoid this,
	#      but I still mistrust it
	#
	# Joe wrote:
	# beware-these ain't the original regexps, and are perhaps worse

	if (/(^\s*>.*\n){2,}\s*\Z/m && !/(\n>.*?)+(\n[^>].*?)+(\n>.*?)+/) {
	    groan "Quote follows response, Jeopardy style #1";
	    return 1;
	}

	# completely at bottom
	elsif (/^.* wr(?:ote|ites)(:|\.{3})\s*\n(>.*\n)+\s*\Z/m) {
	    groan "Quote follows response, Jeopardy style #2";
	    return 1;
	}

	# another way of saying the same
	elsif (/^(?:>+\s*)?-[_+]\s*Original Message\s*-[_+]\s.*\Z/ms) {
	    groan "Quote follows response, Jeopardy style #3";
	    return 1;
	}

	# another way of saying the same
	elsif (/^(?:>+\s*)?[_-]+\s*Reply Separator\s*[_-]+\s.*\Z/ms) {
	    groan "Quote follows response, Jeopardy style #4";
	    return 1;
	}
    }

    return 0;
}

=item B<check_quotes>

Overtaxed sub that checks for overquoted messages. Also
looks for over-opinionated text (too many I's) and lots of code
(oft considered I<a good thing> :). In scalar context, it returns the
total number of quoted lines. Resulting warnings are subject to
C<VERBOSE>, C<MIN_LINES>, C<EGO>, and C<TOLERANCE> settings.

=cut

sub check_quotes {

    # based on cfoq: check fascistly overquoted by tchrist@mox.perl.com

    my (
        $total,         # total number of lines, minus sig and attribution
        $quoted_lines,  # how many lines were quoted
        $percent,       # what percentage this in
        $pcount,        # how many in this paragraph were counted
        $match_part,    # holding space for current match
        $self,
	$code,
	%result,
   );

    $total = $quoted_lines = $pcount = $percent = $code = $self = 0;

    if (body() =~ /^-+\s*Original Message\s*-+$/m) {
        my $body = body();
        my($text,$quote) = body() =~ /(.*)(^-+\s*Original Message\s*-+.*\Z)/ms;
        ($total, $quoted_lines) = ($body =~ y/\n//, $quote =~ y/\n//);
    }
    else {
        my $multipart_crap = mimes() =~ /multipart/i;
        for (paragraphs()) {

            s/\n*\Z/\n/;
	    unquote_wrap;
	    strip_attribution;

            $total++ while  /^./mg;

            # is it a single line, quoted in the customary fashion?

            if ( /^( *>+).*\s*$/ ) {
                $quoted_lines++;
                groan " 1 line quoted with $1" if VERBOSE;
                next;
            }

            # otherwise, it's a multiline block, which may be quoted
            # with any leading repeated string that's neither alphanumeric
            # nor (space?) string (or SuperCited)

	    $pcount = 0;
            while (/^(([ \t\w]*>|[^a-zA-Z0-9\s<\-]{1,}).*\n)(\2.*\n)+/mg) { # was {2,}
                $quoted_lines += $pcount = ($match_part = $&) =~ tr/\n//;
                groanf "%2d lines quoted with $2", $pcount if VERBOSE;
            }
	    next if $pcount > 0;

	    # I's, but don't count includes, italics, regexps: -I, I<>, /./i
	    ++$self while m#(?<![-\$/])\bI\b(?!=<)#gi;

	    ++$self while m/\bme\b/gi;
	    ++$self while m/^\w.+\bmy\b/mgi; # don't count lexicals
 	    ++$self while m/\bIMN?S?H?O\b/g;

	    if ($multipart_crap) {
	      my $state = m#^Content-Type:\s*text/plain#mi ... m#^Content-Type:#mi || 0;
	      next if $state < 1 or $state =~ /E0$/; # ignore endpoints of ...
	    }

	    ++$code while /^\s*[<\%\$\@].+=|[;{}#]\s*(#.+)?$/mg;
        }
    }

    $result{code} = $code, groanf "Code heavy: $code / %s lines", $total - $quoted_lines
      if $code > MIN_LINES;

    $result{ego} = $self, groan "Grossly self-absorbed ($self times)"
      if $self > EGO;

    $percent = int($quoted_lines / $total * 100);

    if ($total == $quoted_lines) {
        $result{totalquote} = groan "All $total lines were quoted lines!";
        # not ok
    }
    elsif ($percent > TOLERANCE && $total > MIN_LINES) {
        $result{overquoted} = $percent - TOLERANCE;
	groan "Overquoted: $quoted_lines lines quoted out of $total: $percent%";
    }

    return \%result, $quoted_lines;
}


sub unquote_wrap {
    my $count = 0;
    $count += s/^(>.*)\n[^\S\n]*([\w?.!,;])/$1 $2/mg for @_ ? @_ : $_;
    return $count;
}

=item B<bad_signature>

Checks for standard signature block. If the lines
exceed C<SIG_LINES>, it returns the number of lines
in signature (up to 20). Otherwise returns 0.

+10 is added to the return value for nonstandard sig
sep's.

=cut

sub bad_signature {

    my $sig = '';
    my($is_canon, $separator);
    my $result = 0;
    my $body = body();

    # sometimes the ms idiotware quotes at the bottom this way
    $body =~ s/^-+\s*Original Message\s*-+\s.*\Z//ms;

    # first check regular signature
    if ($sig = sig()) {
        $is_canon = 1;
    }
    elsif ($body =~ /.*\n([~=_-]{2,5}[^\n\S]*)\n(.*?)\z/s) {
        $separator = $1;
        $sig = $2;
    }

    my $siglines = $sig =~ tr/\n//;

    if ($separator && ($siglines && $siglines < 20)) {
        if ($separator eq '--') {
	  groan "Double-dash in signature missing trailing space";
        } else {
	  groan "Non-canonical signature separator: `$separator'";
        }
	$result+=10;
    }

    if ($siglines > SIG_LINES && $siglines < 20) {
        groanf "Signature too long: %d lines", $siglines;
	$result += $siglines;
    }

    return $result;
}


sub strip_signature {
    my $count = 0;
    $count += s/^-- \s*\n(.*)//ms
	                ||
	       s/^([_-]{2,}\s*)\n(.*)$//ms for @_ ? @_ : $_;
    return $count;
}


=item B<attribution>

Looks for the attribution text preceding the quoted text and returns it.

=cut

sub attribution {
    return $1 if body() =~ /\A(.+\n?.+(:|\.{3}))\s*$/m;

    for (paragraphs()) {
	s/^\s*\[.*\]\s*//;  # remove [courtesy cc]
	unquote_wrap;

#	s/\n*\Z/\n/;

	if (/\A(.*?wr(?:ote|ites)\s*(:|\.{3}))\s*$/m) {
	    return $1;
	}
#	s/\A([^>].+\n>)+//m;
	if (/\A(\s*[^>].*wr(?:ote|ites):?)\s*$/m) {
	    return $1;
	}
	next if /^>/;
	if (/\A(.*\n?.*(<[^\n]+?>|\@).*\n?.*(:|\.{3}))\s*$/m) {
	    return $1;
	}
    }
    return '';
}

sub strip_attribution {
    my $count = 0;
    s/^\s*\[.*?\]\s*//xs for @_ ? @_ : $_;  # remove [courtesy cc]

    # XXX: more general patterns than those of attribution()

    $count += s/\A(.*?wr(?:ote|ites)\s*(:|\.{3}))\s*$//m ||
	s/\A(.*?(<[^\n]+?>|\@).*?(:|\.{3}))\s*$//ms ||
	    s/\A(.+\n?.+(:|\.{3}))\s*$//m for @_ ? @_ : $_;

    return $count;
}

=item B<annoying_subject>

Complains if the subject contains useless words
in it. Returns the number of faux pas if this is an
original post, otherwise returns a false value
for followups.

=cut

sub annoying_subject {
    local $_ = subject();
    s/^(\s*Re:\s*)+//i;
    my $result = 0;

    unless (/[a-z]/) {
        $result += groan "No lower-case letters in subject header";
    }

()=<<'=pod';

=pod

    my @patterns =  (
		     qr/ ( [?!]{3,} ) /x,
		     qr/ ( HELP     ) /x,
		     qr/ ( PLEASE   ) /x,
		     qr/ (NEWB[IE]{2})/xi,
		     qr/ ( GURU     ) /xi,
		    );

=for perl
end of tangled pod

=cut

    for my $regexp (@patterns) {
      next unless /$regexp/;
      $result += groan "Subject line contains annoying `$1' in it.";
    }

    return (!references() && $result);
}



=item B<mimes>

Warns if the message is MIME-encoded.

=cut


sub mimes {
    my ($mime_crap, %result) if 0; # static vars

    return \%result, $mime_crap if $mime_crap;
    $mime_crap = '';

    for (content_type()) {
        last unless defined;
	$mime_crap .= "$_";

        if (/multipart/i) {
	  ++$result{mime_crap};
	  groan "Multipart MIME detected";
        }
        elsif (/html/i) {
	  ++$result{mime_crap};
            groan "HTML encrypting detected";
        }
        elsif (! (/^text$/i || m#^text/plain#i)) {
	  ++$result{mime_crap};
            groan "Strange content type detected: $_";
        }
    }

    for (content_transfer_encoding()) {
        last unless defined;
        if (/quoted-printable/i) {
	  ++$result{mime_crap};
            groan "Gratuitously quoted-illegible MIMEing detected";
	    $mime_crap .= "$_\n";
        }
    }

    unless ($mime_crap) {
        for (body()) {
            if (/\A\s*This message is in MIME format/i) {
	      $result{mime_crap}+=5;
                groan "Gratuitous but unadvertised MIME detected";
		$mime_crap .= "MIME\n";
            }
            elsif (/\A\s*This is a multi-part message in MIME format/i) {
	      $result{mime_crap}+=5;
                groan "Unadvertised multipart MIME detected";
		$mime_crap .= "multipart MIME\n";
            }
        }
    }

    return \%result, $mime_crap;
}


sub dns_check {
    return 0 unless NSLOOKUP;
    # first try an MX record, then an A rec (for badly configged hosts)

    my $host = shift;
    return 0 if $host =~ /\.invalid$/i;

    local $/ = undef;
    local *NS;
    local $_;
    local %ENV;

    # the following is commented out for security reasons:
    #   if ( `nslookup -query=mx $host` =~ /mail exchanger/
    # otherwise there could be naughty bits in $host
    # we'll bypass system() and get right at execvp()

    my $pid;

    if ($pid = open(NS, "-|")) {
        $_ = <NS>;
        kill 'TERM', $pid if $pid;  # just in case
        close NS or groan "nslookup error: $?";
        return 0 if /mail exchanger/;
        # else fall through to next test
    } else {
        die "cannot fork: $!" unless defined $pid;
        open(SE, ">&STDERR");
        open(STDERR, ">/dev/null");
        { exec NSLOOKUP, '-timeout=1', '-query=mx', $host; }  # braces for -w
        open(STDERR, ">&SE");
        die "can't exec nslookup: $!";
    }

    if ($pid = open(NS, "-|")) {
        $_ = <NS>;
        kill 'TERM', $pid if $pid;  # just in case
        close NS or groan "nslookup error: $?";
        unless (/answer:.*Address/s || /Name:.*$host.*Address:/si) {
            groan "No DNS for \@$host in return address";
	    return 1;
        }
    } else {
        die "cannot fork: $!" unless defined $pid;
        open(SE, ">&STDERR");
        open(STDERR, ">/dev/null");
        { exec NSLOOKUP, '-timeout=1', '-query=a', $host; }  # braces for -w
        open(STDERR, ">&SE");
        die "can't exec nslookup: $!";
    }
    return 0;
}


sub ck822 {

    # ck822 -- check whether address is valid rfc 822 address
    # tchrist@perl.com
    #
    # pattern developed in program by jfriedl;
    # see "Mastering Regular Expressions" from ORA for details

    # this will error on something like "ftp.perl.com." because
    # even though dns wants it, rfc822 hates it.  shucks.

    my $what = 'address';

    my $address = shift;
    local $_;

    my $is_a_valid_rfc_822_addr;

    ($is_a_valid_rfc_822_addr = <<'EOSCARY') =~ s/\n//g;
(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n
\015()]|\\[^\x80-\xff])*\))*\))*(?:(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\
xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|"(?:[^\\\x80-\xff\n\015"
]|\\[^\x80-\xff])*")(?:(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xf
f]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*\.(?:[\040\t]|\((?:[
^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\
xff])*\))*\))*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;
:".\\\[\]\000-\037\x80-\xff])|"(?:[^\\\x80-\xff\n\015"]|\\[^\x80-\xff])*"))
*(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\
n\015()]|\\[^\x80-\xff])*\))*\))*@(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\
\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*(?:[^(\04
0)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-
\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\])(?:(?:[\040\t]|\((?
:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80
-\xff])*\))*\))*\.(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\(
(?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*(?:[^(\040)<>@,;:".\\\[\]
\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\
\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\]))*|(?:[^(\040)<>@,;:".\\\[\]\000-\0
37\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|"(?:[^\\\x80-\xf
f\n\015"]|\\[^\x80-\xff])*")(?:[^()<>@,;:".\\\[\]\x80-\xff\000-\010\012-\03
7]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\
\[^\x80-\xff])*\))*\)|"(?:[^\\\x80-\xff\n\015"]|\\[^\x80-\xff])*")*<(?:[\04
0\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]
|\\[^\x80-\xff])*\))*\))*(?:@(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x
80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*(?:[^(\040)<>@
,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]
)|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\])(?:(?:[\040\t]|\((?:[^\\
\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff
])*\))*\))*\.(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^
\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*(?:[^(\040)<>@,;:".\\\[\]\000-
\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-
\xff\n\015\[\]]|\\[^\x80-\xff])*\]))*(?:(?:[\040\t]|\((?:[^\\\x80-\xff\n\01
5()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*,(?
:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\0
15()]|\\[^\x80-\xff])*\))*\))*@(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^
\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*(?:[^(\040)<
>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xf
f])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\])(?:(?:[\040\t]|\((?:[^
\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\x
ff])*\))*\))*\.(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:
[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*(?:[^(\040)<>@,;:".\\\[\]\00
0-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x8
0-\xff\n\015\[\]]|\\[^\x80-\xff])*\]))*)*:(?:[\040\t]|\((?:[^\\\x80-\xff\n\
015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*)
?(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000
-\037\x80-\xff])|"(?:[^\\\x80-\xff\n\015"]|\\[^\x80-\xff])*")(?:(?:[\040\t]
|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[
^\x80-\xff])*\))*\))*\.(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xf
f]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*(?:[^(\040)<>@,;:".\
\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|"(?:
[^\\\x80-\xff\n\015"]|\\[^\x80-\xff])*"))*(?:[\040\t]|\((?:[^\\\x80-\xff\n\
015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*@
(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n
\015()]|\\[^\x80-\xff])*\))*\))*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff
]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\
]]|\\[^\x80-\xff])*\])(?:(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\
xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*\.(?:[\040\t]|\((?
:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80
-\xff])*\))*\))*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@
,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff
])*\]))*(?:[\040\t]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff]|\((?:[^\\\x8
0-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*>)(?:[\040\t]|\((?:[^\\\x80-\xff\n\
015()]|\\[^\x80-\xff]|\((?:[^\\\x80-\xff\n\015()]|\\[^\x80-\xff])*\))*\))*
EOSCARY

    if ($address !~ /^${is_a_valid_rfc_822_addr}$/o) {
      return groan "rfc822 failure on $address";
    }
    return 0; #address is OK
}




##################################################

package News::GnusFilter::Message;

# process <> for a message header and body
# This assumes one message per file!

sub get_message {

    my $msg if 0; # static var trick
    return $msg if $msg;

    $msg = bless {}, ref $_[0] || $_[0];

    # header

    local $/ = '';
    $msg->{HEADER_STRING} = <>;
    chomp $msg->{HEADER_STRING};
    for (split /\n(?!\s)/, $msg->{HEADER_STRING}) {
        my($tag, $value) = /^([^\s:]+):\s*(.*)\s*\Z/s;
        push @{ $msg->{HEADERS}{$tag} }, $value;
        $tag =~ tr/-/_/;
        $tag = uc($tag);
        push @{ $msg->{$tag} }, $value;
    }

    # body

    $/ = "\n-- \n";
    for ($msg->{BODY} = <>) {
        chomp;

        $msg->{PARAGRAPHS} = [ split /\n\s*\n/ ];
        $msg->{LINES}      = [ split /\n/      ];
    }

    study $msg->{BODY};

    # sig

    undef $/;
    $msg->{SIG} = <>;
    $msg->{SIG} = "" unless defined $msg->{SIG};
    return $msg;
}

sub AUTOLOAD {
    no strict 'vars';
    my $self = shift;
    my $field;
    ($field = uc($AUTOLOAD)) =~ s/.*:://;
    my $xfield = "x_" . $field;

    if (!exists $self->{$field} && exists $self->{$xfield}) {
        $field = $xfield;
    }

    unless (exists $self->{$field}) {
        return undef;
     }

    my $data = $self->{$field};
    my @data = ref $data ? @$data : $data;

    if (wantarray) {
        return @data;
    }
    else {
        return join("\n", @data);
    }
}



1;

__END__

=back

=head1 BUGS

=over

=item * Terribly slow on large messages.


=item * Etiquette rules may need adjusting
for normal e-mail.


=item * Does not (currently) look for quoted sigs


=item * manually wrapped logfiles are heavily penalized


=item * some context sensitive stuff (original, request, newsgroup, mail)
is wrong


=item * uses the C<my $x if 0;> trick.

=back

=head1 NOTES

Return values, default settings, and especially regexps
are subject to change.  Please send bug reports and patches
to the author.

=head1 AUTHOR

Joe Schaefer <joe+cpan@sunstarsys.com>. This package borrows
heavily from Tom Christiansen's I<msgchk> script.

=head1 COPYRIGHT

Copyright 2001 Joe Schaefer.  This code is free software; it is freely
modifiable and redistributable under the same terms as Perl itself.




