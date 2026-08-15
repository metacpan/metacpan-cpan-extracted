#!/usr/bin/env perl
# ABSTRACT: Get basic statistical functions, like in R, but with Perl using XS for performance
require 5.010;
use strict;
package Stats::LikeR;
our $VERSION = 0.298;
require XSLoader;
use autodie ':default';
use warnings FATAL => 'all';
use Exporter 'import';
use Scalar::Util qw(reftype looks_like_number);
XSLoader::load('Stats::LikeR', $VERSION);
our @EXPORT_OK = qw(h add_data age_standardize agg anova aoh2h aoh2hoa aoh2hoh aov assign auc auroc bedroc bfill binom_test cfilter chisq_test chunk col col2col colnames concat cmh_test cor cor_test cov csort dnorm cohen_d cramers_v eta_squared drop_cols drop_duplicates dropna epi_2x2 ffill fillna filter fisher_test get_union glm group_by h2aoh hoa2aoh hoa2hoh hoh2hoa hist interpolate intersection is_equivalent kruskal_test ks_test kurtosis Lonly ljoin lm map_cell matrix max mean median melt merge min mode ncol nrow oneway_test p_adjust pivot_table pnorm power_t_test predict prop_test mcnemar_test friedman_test dunn_test prcomp ptukey qcut qtukey quantile rank roc Ronly rbind rbinom read_table rename_cols rnorm rownames runif sample scale sd select_cols seq shapiro_test skew smd sum summary survfit logrank_test coxph table_one t_test transpose TukeyHSD uniq vals value_counts var var_test vif hosmer_lemeshow view wilcox_test write_table);
our @EXPORT = @EXPORT_OK;

# ===========================================================================
# Help
#
# h() is the way in, and it works for every function in the distribution, XS
# and pure Perl alike, because it looks the name up rather than watching an
# argument list:
#
#     h('agg');    h(*agg);    h(\&agg);    h();
#
# It prints that function's own section of the documentation -- the same text
# as the matching heading in README.md -- to STDOUT, and returns.
#
# h() is the only way in.  No function reads its own arguments for a help flag:
# a bare 'h' or '?' cannot be told apart from a column, file or option value
# that really is that string, and one help route that works everywhere beats
# two that behave differently depending on whether the callee is XS or Perl.
#
# The help text is not duplicated in the source.  It is rendered from this
# file's own POD at run time (that POD is generated from README.md by
# md2pod.pl), so the help can never drift out of sync with the shipped
# documentation.  Functions without a documentation section of their own fall
# back to listing every topic that does have one.
# ===========================================================================

# Functions that share another function's section, either because they are the
# very same subroutine under a second name (rbind/concat) or because they are
# the internal engine behind a documented front end.
my %HELP_ALIAS = (
	rbind             => 'concat',
	map_cell          => 'assign',
	col               => 'filter',
	_rename_inplace   => 'rename_cols',
	_cols_select      => 'select_cols',
	_cols_drop        => 'drop_cols',
	_cols_rename      => 'rename_cols',
	_drop_dups_core   => 'drop_duplicates',
	_aoh_key_union    => 'drop_duplicates',
	_qcut_core        => 'qcut',
	_interp_column_xs => 'interpolate',
	_parse_csv_file   => 'read_table',
	_impute_prop      => 'fillna',
	_fill_seq         => 'fillna',
	_render_grid      => 'view',
	_df_shape         => 'agg',
	_xtab             => 'cramers_v',
);

# _help_show($name) -- print $name's documentation to STDOUT.  Returns the
# name it showed.
sub _help_show {
	my ($name) = @_;
	$name = defined($name) ? $name : '';
	$name =~ s/\A.*:://;                       # accept Stats::LikeR::agg
	my $old = select STDOUT; local $| = 1; select $old;
	print STDOUT _help_text($name);
	return $name;
}

# h() -- ask for documentation by name.  It never dies over the name it is
# given (an undocumented one lists the documented ones instead), and it never
# stands in the way of a call: no function here reads its arguments for a help
# flag, so a column, file or option value really named 'h' is just data.
#
#     h('bedroc');      # by name
#     h(*bedroc);       # by name, unquoted
#     h(\&bedroc);      # by reference
#     h();              # the general help, and the list of topics
#
# h(bedroc), with no quotes and no sigil, cannot be made to work: every
# function here is exported, so Perl parses the bareword as a call to bedroc()
# before h() is ever reached.  Use one of the four forms above.
#
# Returns the name whose documentation was shown.
sub h {
	my ($what) = @_;
	my $name;

	if (!@_ || !defined $what) {                 # h() -- the general help
		$name = '';
	}
	elsif (ref \$what eq 'GLOB') {               # h(*bedroc)
		($name = "$what") =~ s/\A\*//;
	}
	elsif (ref $what eq 'CODE') {                # h(\&bedroc)
		no strict 'refs';
		for my $cand (@EXPORT_OK) {
			my $slot = *{"Stats::LikeR::$cand"}{CODE};
			next unless $slot && $slot == $what;
			$name = $cand;
			last;
		}
		die "h: that code reference is not a Stats::LikeR function\n"
			unless defined $name;
	}
	elsif (ref $what) {
		die 'h: expected a function name, a glob or a code reference, not a '
		  . ref($what) . " reference\n";
	}
	else {                                       # h('bedroc'), h($name)
		$name = $what;
		$name =~ s/\A&//;                        # h('&bedroc')
	}

	$name =~ s/\A.*:://;                         # h('Stats::LikeR::bedroc')
	$name =~ s/\A\s+//; $name =~ s/\s+\z//;
	return _help_show($name);
}

# terminal width to wrap to
sub _help_width {
	my $w = $ENV{COLUMNS};
	$w = 80 unless defined($w) && $w =~ /\A[0-9]+\z/;
	$w = 40 if $w < 40;
	$w = 100 if $w > 100;
	return $w;
}

# display length of a UTF-8 byte string: count everything that is not a
# continuation byte.  Keeps wrapping honest without pulling in Encode.
sub _help_len {
	my $n = 0;
	$n++ while $_[0] =~ /[^\x80-\xbf]/g;
	return $n;
}

sub _help_text {
	my ($name) = @_;
	my $width  = _help_width();
	my $topic  = exists $HELP_ALIAS{$name} ? $HELP_ALIAS{$name} : $name;
	my @sect   = length($name) ? _pod_section($topic) : ();
	my $body   = @sect          ? _pod_render(\@sect, $width)
	           : length($name)  ? _help_fallback($name, $width)
	           :                  _help_general($width);

	my $title  = length($name) ? "Stats::LikeR::$name" : 'Stats::LikeR';
	$title .= "   (documented under \`$topic')" if $topic ne $name && @sect;
	my $rule   = '=' x $width;

	return join('',
		"\n", $rule, "\n", $title, "\n", $rule, "\n\n",
		$body,
		($body =~ /\n\n\z/ ? '' : "\n"),
		'-' x $width, "\n",
		_pod_wrap(length($name)
			? "Call h('$name') for this page at any time; h(*$name) and "
			. "h(\\&$name) are the same call, and h() lists every documented "
			. 'function.'
			: "Call h('name') for any one function's documentation -- "
			. "h('agg'), h(*agg) and h(\\&agg) are the same call.",
		          $width, 1),
		_pod_wrap("The full manual is `perldoc Stats::LikeR'.", $width, 1),
		$rule, "\n\n",
	);
}

# Recognise a heading.  Returns (level, text), or the empty list when the line
# is not one.  Text carrying braces or a fat comma is a code comment that the
# markdown-to-POD generator mistook for a heading (README.md has a few inside
# indented examples); treating those as sections would cut a function's
# documentation short, so they are ignored here.
sub _pod_heading {
	my ($line) = @_;
	return () unless defined $line && $line =~ /^=head([1-6])[ \t]+(\S.*?)\s*\z/;
	my ($level, $text) = ($1, $2);
	return () if $text =~ /[{};]|=>/;
	return ($level, $text);
}

# every =head2 in the Functions section, for the "nothing documented" path
sub _pod_topics {
	my @t;
	my $fh = _pod_open() or return @t;
	my $in = 0;
	while (my $line = <$fh>) {
		my ($level, $text) = _pod_heading($line);
		next unless defined $level;
		if ($level == 1) { $in = ($text =~ /Functions/i) ? 1 : 0; next }
		next unless $in && $level == 2;
		my $n = _pod_plain($text);
		$n =~ s/\s*\(.*\z//s;
		$n =~ s/\A\s+//; $n =~ s/\s+\z//;
		# only names a caller can actually use; this also drops the one
		# heading the POD generator mangled (_rename_inplace, a private
		# helper, comes out as I<rename>inplace)
		push @t, $n if length($n) && grep { $_ eq $n } @EXPORT_OK;
	}
	close $fh;
	return @t;
}

# the documented function names, in aligned columns
sub _help_topic_block {
	my ($width) = @_;
	my @topics = _pod_topics();
	return '' unless @topics;

	my $col = 0;
	$col = _help_len($_) > $col ? _help_len($_) : $col for @topics;
	$col += 2;
	my $per = int(($width - 2) / $col) || 1;
	my $out = '';
	my $i = 0;
	while ($i < @topics) {
		my @row = grep { defined } @topics[$i .. $i + $per - 1];
		my $line = '  ' . join('', map { $_ . ' ' x ($col - _help_len($_)) } @row);
		$line =~ s/\s+\z//;
		$out .= $line . "\n";
		$i += $per;
	}
	return $out;
}

sub _help_fallback {
	my ($name, $width) = @_;
	my $list = _help_topic_block($width);
	my $out = _pod_wrap("There is no documentation section for "
	                  . (length($name) ? "`$name'" : 'that name')
	                  . '.'
	                  . (length($list) ? '  These functions have one, and h()'
	                                   . ' will show any of them:' : ''),
	                    $width, 1);
	return length($list) ? $out . "\n" . $list . "\n" : $out;
}

# h() with nothing to look up: how to ask, then every topic.
#
# README.md's own "Getting help" section is used when the POD has been
# regenerated from it (md2pod.pl); until then the short version below stands in,
# so h() is never empty.
sub _help_general {
	my ($width) = @_;
	my @sect = _pod_section('Getting help', 1);
	my $out;
	if (@sect) {
		$out = _pod_render(\@sect, $width);
	}
	else {
		$out = _pod_wrap('Ask for a function by name, and its section of the '
		               . 'documentation is printed here:', $width, 1)
		     . "\n"
		     . "  h('quantile');   # by name\n"
		     . "  h(*quantile);    # by name, unquoted\n"
		     . "  h(\\&quantile);   # by reference\n"
		     . "\n"
		     . _pod_wrap('h() is the only way to ask: no function reads its own '
		               . 'arguments for a help flag, so a column, file or option '
		               . "value really named 'h' is just data.", $width, 1);
	}
	my $list = _help_topic_block($width);
	if (length $list) {
		$out .= "\n" . _pod_wrap('Documented functions, each of which h() will '
		                       . 'show in full:', $width, 1) . "\n" . $list . "\n";
	}
	return $out;
}

# ---------------------------------------------------------------------------
# POD extraction
# ---------------------------------------------------------------------------

our $POD_FILE;             # set only by t/help.t, to read a fixture

sub _pod_open {
	my $file = defined($POD_FILE) ? $POD_FILE : __FILE__;
	$file = $INC{'Stats/LikeR.pm'} unless defined($file) && -r $file;
	return undef unless defined($file) && -r $file;
	my $fh;
	open $fh, '<', $file or return undef;
	return $fh;
}

# Reduce a heading or a function name to a comparison key.  Dropping every
# non-alphanumeric makes the match immune to a signature in the heading
# (`hoa2hoh( \%hoa, $key )'), to C<> wrapping (`C<aoh2hoh>') and to POD
# generated from markdown that read an underscore as italics
# (`I<rename>inplace' for `_rename_inplace').
sub _pod_key {
	my ($s) = @_;
	return '' unless defined $s;
	$s =~ s/\s*\(.*\z//s;
	$s = _pod_plain($s);
	$s =~ s/[^A-Za-z0-9]+//g;
	return lc $s;
}

# the raw POD lines of the section headed $name, its subsections included.
# $want is the heading level to match, 2 (a function) unless asked otherwise.
sub _pod_section {
	my ($name, $want) = @_;
	$want = 2 unless defined $want;
	my $key = _pod_key($name);
	return () unless length $key;
	my $fh = _pod_open() or return ();
	my (@out, $in);
	while (my $line = <$fh>) {
		my ($level, $title) = _pod_heading($line);
		if (defined $level && $level <= $want) {
			if ($level == $want && _pod_key($title) eq $key) {
				$in = 1;
				push @out, $line;
				next;
			}
			last if $in;
			next;
		}
		last if $in && $line =~ /^=cut\s*$/;
		push @out, $line if $in;
	}
	close $fh;
	return @out;
}

# ---------------------------------------------------------------------------
# POD -> plain text
# ---------------------------------------------------------------------------

my %POD_ENTITY = (
	lt => '<', gt => '>', 'verbar' => '|', sol => '/', amp => '&',
	quot => '"', apos => "'", lchevron => '<<', rchevron => '>>',
	nbsp => ' ', ndash => '-', mdash => '--', 'eacute' => 'e',
);

sub _pod_seq {
	my ($code, $text) = @_;
	if ($code eq 'E') {
		return $POD_ENTITY{$text} if exists $POD_ENTITY{$text};
		return chr(hex $1)        if $text =~ /\A0?[xX]([0-9a-fA-F]+)\z/;
		return chr($text)         if $text =~ /\A[0-9]+\z/ && $text < 128;
		return $text;
	}
	if ($code eq 'L') {                     # L<text|target>, L<target>, L<#anchor>
		$text =~ s/\|.*\z//s if $text =~ /\|/;
		$text =~ s{\A/?#}{};
		$text =~ s{\A/}{};
		return $text;
	}
	return '' if $code eq 'X' || $code eq 'Z';
	return $text;                           # B, C, I, F, S and anything else
}

# strip POD formatting codes, innermost first, doubled delimiters included
sub _pod_plain {
	my ($s) = @_;
	return '' unless defined $s;
	for (1 .. 24) {
		my $before = $s;
		$s =~ s/([A-Z])<<+[ \t\n]+(.*?)[ \t\n]+>>+/_pod_seq($1, $2)/ges;
		$s =~ s/([A-Z])<([^<>]*)>/_pod_seq($1, $2)/ge;
		last if $s eq $before;
	}
	return $s;
}

sub _pod_wrap {
	my ($text, $width, $indent, $lead) = @_;
	$lead = '' unless defined $lead;
	my $pad   = ' ' x $indent;
	my $first = $pad . $lead;
	my $cont  = $pad . (' ' x _help_len($lead));
	my $limit = $width;
	my $floor = _help_len($first) + 20;
	$limit = $floor if $limit < $floor;

	my @words = grep { length } split /\s+/, $text;
	return "" unless @words;
	my $out  = '';
	my $line = $first . shift @words;
	for my $w (@words) {
		if (_help_len($line) + 1 + _help_len($w) > $limit) {
			$out .= $line . "\n";
			$line = $cont . $w;
		} else {
			$line .= ' ' . $w;
		}
	}
	return $out . $line . "\n";
}

# Split POD lines into typed blocks: command paragraphs, verbatim paragraphs,
# ordinary paragraphs and =begin/=end data blocks.
sub _pod_blocks {
	my ($lines) = @_;
	my (@blocks, $i);
	my $n = scalar @$lines;
	for ($i = 0; $i < $n; ) {
		my $line = $lines->[$i];
		if ($line =~ /^\s*$/) { $i++; next }
		if ($line =~ /^=begin\s+(\S+)/) {
			my $fmt = lc $1;
			$i++;
			my @buf;
			push @buf, $lines->[$i++] while $i < $n && $lines->[$i] !~ /^=end\b/;
			$i++ if $i < $n;
			push @blocks, { type => 'data', fmt => $fmt, lines => \@buf };
			next;
		}
		# Pod::Weaver rewrites every "=begin FMT ... =end FMT" into a single
		# "=for FMT ..." paragraph when the distribution is built, so the
		# shipped copy of this file carries the tables in that spelling.  Both
		# mean the same thing -- the rest of the paragraph is data for FMT --
		# and the help has to read the tables either way.
		if ($line =~ /^=for[ \t]+(\S+)[ \t]*(.*)$/) {
			my ($fmt, $first) = (lc $1, $2);
			$i++;
			my @buf = length($first) ? ($first . "\n") : ();
			push @buf, $lines->[$i++]
				while $i < $n && $lines->[$i] !~ /^\s*$/ && $lines->[$i] !~ /^=/;
			push @blocks, { type => 'data', fmt => $fmt, lines => \@buf };
			next;
		}
		if ($line =~ /^=/) {
			my @buf = ($line);
			$i++;
			push @buf, $lines->[$i++]
				while $i < $n && $lines->[$i] !~ /^\s*$/ && $lines->[$i] !~ /^=/;
			push @blocks, { type => 'cmd', lines => \@buf };
			next;
		}
		if ($line =~ /^[ \t]/) {                     # verbatim
			my @buf;
			while ($i < $n) {
				my $s = $lines->[$i];
				if ($s =~ /^\s*$/) {                 # keep interior blank lines
					my $j = $i;
					$j++ while $j < $n && $lines->[$j] =~ /^\s*$/;
					last if $j >= $n || $lines->[$j] !~ /^[ \t]/;
					push @buf, "\n" for $i .. $j - 1;
					$i = $j;
					next;
				}
				last if $s =~ /^=/ || $s !~ /^[ \t]/;
				push @buf, $s;
				$i++;
			}
			push @blocks, { type => 'verb', lines => \@buf };
			next;
		}
		my @buf;                                     # ordinary paragraph
		push @buf, $lines->[$i++]
			while $i < $n && $lines->[$i] !~ /^\s*$/ && $lines->[$i] !~ /^=/;
		push @blocks, { type => 'text', lines => \@buf };
	}
	return @blocks;
}

sub _pod_render {
	my ($lines, $width) = @_;
	my @out;
	my @indent = (1);                    # =over stack; 1 = one space of margin

	for my $b (_pod_blocks($lines)) {
		if ($b->{type} eq 'verb') {
			# A markdown blockquote arrives here as verbatim text, but it is
			# prose and reads far better wrapped than left at its source
			# width, so pull those out and treat them as a paragraph.
			my @body = grep { /\S/ } @{ $b->{lines} };
			if (@body && !grep { !/^\s*>/ } @body) {
				s/^\s*>\s?// for @body;
				push @out, "\n", _pod_wrap(_pod_plain(join ' ', @body),
				                           $width, $indent[-1] + 2);
				next;
			}
			push @out, "\n";
			my $pad = ' ' x $indent[-1];
			# Formatting codes are not supposed to appear in a verbatim
			# block, but the generated POD does leave a few behind; expand
			# them rather than showing C<...> to the reader.
			for my $v (@{ $b->{lines} }) {
				my $s = _pod_plain($v);
				$s =~ s/\s+\z//;
				push @out, length($s) ? $pad . $s . "\n" : "\n";
			}
			next;
		}
		if ($b->{type} eq 'text') {
			push @out, "\n", _pod_wrap(_pod_plain(join ' ', @{ $b->{lines} }),
			                           $width, $indent[-1]);
			next;
		}
		if ($b->{type} eq 'data') {
			next unless $b->{fmt} =~ /^(?:html|text)$/;
			push @out, _pod_data(join('', @{ $b->{lines} }), $b->{fmt},
			                     $width, $indent[-1]);
			next;
		}

		# ---- command paragraph ----
		my @l = @{ $b->{lines} };
		my $head = shift @l;
		$head =~ /^=(\w+)[ \t]*(.*)$/s or next;
		my ($cmd, $arg) = ($1, $2);
		$arg =~ s/\s+\z//;

		if ($cmd =~ /^head([1-6])\z/) {
			my $level = $1;
			my $t = _pod_plain(join ' ', $arg, @l);
			$t =~ s/\s+/ /g; $t =~ s/\A\s+//; $t =~ s/\s+\z//;
			next unless length $t;
			push @out, "\n";
			if ($level <= 2) {
				push @out, uc($t) . "\n";
			} else {
				push @out, $t . "\n", ('-' x _help_len($t)) . "\n";
			}
			next;
		}
		if ($cmd eq 'over') {
			my $by = ($arg =~ /([0-9]+)/) ? $1 : 4;
			$by = 2 if $by < 2;
			$by = 8 if $by > 8;
			push @indent, $indent[-1] + $by;
			next;
		}
		if ($cmd eq 'back') {
			pop @indent if @indent > 1;
			next;
		}
		if ($cmd eq 'item') {
			my $bullet = '*';
			if    ($arg =~ s/\A\*\s*//)                 { $bullet = '*' }
			elsif ($arg =~ s/\A([0-9]+\.?)(?:\s+|\z)//) {
				$bullet = $1;                    # numbered list: "1." or "1"
				$bullet .= '.' unless $bullet =~ /\.\z/;
			}
			my $t = _pod_plain(join ' ', $arg, @l);
			my $ind = $indent[-1] > 2 ? $indent[-1] - 2 : $indent[-1];
			push @out, "\n";
			if ($t =~ /\S/) {
				push @out, _pod_wrap($t, $width, $ind, "$bullet ");
			} else {
				push @out, (' ' x $ind) . $bullet . "\n";
			}
			next;
		}
		# =pod, =cut, =encoding, =begin without =end: nothing to show
	}

	my $text = join '', @out;
	$text =~ s/\A\n+//;
	$text =~ s/\n{3,}/\n\n/g;
	$text =~ s/\n*\z/\n/;
	return $text;
}

# ---------------------------------------------------------------------------
# =begin html / =begin text data blocks (and their =for spelling, which is what
# Pod::Weaver leaves behind in the built distribution).  The generated POD uses
# these for one thing only: parameter and output tables.  Render them as aligned
# plain text so the help shows the same information the HTML documentation does.
# ---------------------------------------------------------------------------

my %HTML_ENTITY = (
	amp => '&', lt => '<', gt => '>', quot => '"', apos => "'", nbsp => ' ',
	ndash => '-', mdash => '--', hellip => '...',
);

sub _html_text {
	my ($s) = @_;
	$s = '' unless defined $s;
	$s =~ s{<br\s*/?>}{ }gi;
	$s =~ s/<[^>]*>//g;
	$s =~ s/&#x([0-9a-fA-F]+);/chr(hex $1)/ge;
	$s =~ s/&#([0-9]+);/$1 < 128 ? chr($1) : '?'/ge;
	$s =~ s/&([a-zA-Z]+);/exists $HTML_ENTITY{$1} ? $HTML_ENTITY{$1} : "&$1;"/ge;
	$s =~ s/\s+/ /g;
	$s =~ s/\A\s+//; $s =~ s/\s+\z//;
	return $s;
}

sub _pod_data {
	my ($raw, $fmt, $width, $indent) = @_;
	if ($fmt eq 'text') {
		my $pad = ' ' x $indent;
		my $out = "\n";
		for my $line (split /\n/, $raw, -1) {
			$line =~ s/\s+\z//;
			$out .= length($line) ? $pad . $line . "\n" : "\n";
		}
		return $out;
	}

	my $out = '';
	my $seen = 0;
	while ($raw =~ m{<table[^>]*>(.*?)</table>}gis) {
		$out .= _html_table($1, $width, $indent);
		$seen = 1;
	}
	# HTML that is not a table carries nothing the plain-text help can use
	return $seen ? $out : '';
}

sub _html_table {
	my ($html, $width, $indent) = @_;
	my (@rows, @isheader);
	while ($html =~ m{<tr[^>]*>(.*?)</tr>}gis) {
		my $tr = $1;
		my (@cells, $hdr);
		while ($tr =~ m{<t([dh])[^>]*>(.*?)</t\1\s*>}gis) {
			$hdr = 1 if lc($1) eq 'h';
			push @cells, _html_text($2);
		}
		next unless @cells;
		push @rows, \@cells;
		push @isheader, ($hdr ? 1 : 0);
	}
	return '' unless @rows;

	# The header decides how many columns there are.  A body row with more
	# cells than that came from a markdown table whose source had an escaped
	# pipe inside a cell, so fold the strays back into the last column
	# instead of stretching the whole table to fit the accident.
	my $ncol = 0;
	for my $i (0 .. $#rows) {
		next unless $isheader[$i];
		$ncol = scalar @{ $rows[$i] };
		last;
	}
	for my $r (@rows) { $ncol = @$r if !$ncol || (!grep { $_ } @isheader) && @$r > $ncol }
	for my $r (@rows) {
		if (@$r > $ncol) {
			my @tail = splice @$r, $ncol - 1;
			$r->[$ncol - 1] = join ' ', grep { length } @tail;
		}
		$r->[$ncol - 1] = '' unless defined $r->[$ncol - 1];
	}

	# natural column widths, then shrink the widest until the table fits
	my @w = (0) x $ncol;
	for my $r (@rows) {
		for my $c (0 .. $ncol - 1) {
			my $l = _help_len(defined $r->[$c] ? $r->[$c] : '');
			$w[$c] = $l if $l > $w[$c];
		}
	}
	my $gap   = 2;
	my $avail = $width - $indent - $gap * ($ncol - 1);
	$avail = 8 * $ncol if $avail < 8 * $ncol;
	my $total = 0; $total += $_ for @w;
	while ($total > $avail) {
		my ($worst, $max) = (0, -1);
		for my $c (0 .. $ncol - 1) { ($worst, $max) = ($c, $w[$c]) if $w[$c] > $max }
		last if $w[$worst] <= 8;
		$w[$worst]--;
		$total--;
	}

	my $pad = ' ' x $indent;
	my $out = "\n";
	for my $i (0 .. $#rows) {
		# wrap every cell to its column width, then print line by line
		my @cell = map { [ _html_fold($rows[$i][$_], $w[$_]) ] } 0 .. $ncol - 1;
		my $high = 0;
		for my $c (@cell) { $high = scalar @$c if @$c > $high }
		for my $line (0 .. $high - 1) {
			my $s = $pad . join ' ' x $gap,
				map { my $t = defined $cell[$_][$line] ? $cell[$_][$line] : '';
				      $t . ' ' x ($w[$_] - _help_len($t)) } 0 .. $ncol - 1;
			$s =~ s/\s+\z//;
			$out .= $s . "\n";
		}
		if ($isheader[$i]) {
			$out .= $pad . join(' ' x $gap, map { '-' x $w[$_] } 0 .. $ncol - 1) . "\n";
		}
	}
	return $out . "\n";
}

# greedy wrap of one table cell to $w display columns
sub _html_fold {
	my ($s, $w) = @_;
	$s = '' unless defined $s;
	return ('') unless length $s;
	my @lines;
	my $cur = '';
	for my $word (split /\s+/, $s) {
		next unless length $word;
		if (!length $cur) {
			$cur = $word;
		} elsif (_help_len($cur) + 1 + _help_len($word) <= $w) {
			$cur .= ' ' . $word;
		} else {
			push @lines, $cur;
			$cur = $word;
		}
		while (_help_len($cur) > $w) {            # a single over-long word
			my $keep = $cur;
			$keep = substr $keep, 0, $w;
			$keep =~ s/[\x80-\xbf]+\z// if _help_len($keep) > $w;
			push @lines, $keep;
			$cur = substr $cur, length $keep;
		}
	}
	push @lines, $cur if length $cur;
	return @lines ? @lines : ('');
}

# colnames($df) / rownames($df)
#
# Return the column names and row names of any of the four Stats::LikeR
# frame shapes, as a list (R's colnames()/rownames()).  In scalar context
# each returns the count, so `scalar colnames($df) == ncol($df)` and
# `scalar rownames($df) == nrow($df)` on a rectangular frame.
#
# Ordering mirrors view() exactly, so what you name is what you would see:
#   * positional axes are 0-based integer indices --
#       AoA columns, and the rows of AoA / AoH / HoA
#   * key-based axes are the string-sorted union of keys --
#       AoH / HoH columns (union across every row), HoA columns,
#       and HoH rows (the outer keys)
#
# Shape is classified by _df_shape (the same detector agg() uses), so a
# ragged AoA/HoA is tolerated for enumeration: colnames() spans the widest
# row and rownames() the longest column.  Empty frames yield an empty list.
# Like agg()/view(), the classifier is ref-based (not reftype), so hand it
# an unblessed frame -- blessed frames are the one case ncol()/nrow() take
# that this family does not.

sub colnames {
	my ($df) = @_;
	die "colnames: undefined data in first position\n" unless defined $df;
	my $shape = _df_shape($df, 'colnames');
	my @cols;
	if ($shape eq 'AoA') {                       # widest row -> 0 .. m-1
		my $m = 0;
		for my $row (@$df) {
			next unless ref $row eq 'ARRAY';
			$m = scalar @$row if scalar @$row > $m;
		}
		@cols = (0 .. $m - 1);
	} elsif ($shape eq 'HoA') {                  # keys ARE the columns
		@cols = sort keys %$df;
	} else {                                     # AoH / HoH: union of row keys
		my @rows = $shape eq 'AoH' ? @$df : values %$df;
		my %seen;
		for my $row (@rows) {
			next unless ref $row eq 'HASH';
			$seen{$_} = 1 for keys %$row;
		}
		@cols = sort keys %seen;
	}
	return wantarray ? @cols : scalar @cols;
}

sub rownames {
	my ($df) = @_;
	die "rownames: undefined data in first position\n" unless defined $df;
	my $shape = _df_shape($df, 'rownames');
	my @rows;
	if ($shape eq 'HoH') {                        # outer keys ARE the rows
		@rows = sort keys %$df;
	} elsif ($shape eq 'HoA') {                   # longest column -> 0 .. n-1
		my $n = 0;
		for my $v (values %$df) {
			next unless ref $v eq 'ARRAY';
			$n = scalar @$v if scalar @$v > $n;
		}
		@rows = (0 .. $n - 1);
	} else {                                      # AoA / AoH: one row per element
		@rows = (0 .. $#$df);
	}
	return wantarray ? @rows : scalar @rows;
}

# =====================================================================
# The XSUBs _cols_select / _cols_drop / _cols_rename are PRIVATE -- do NOT
# export them.  (See select_drop_rename_cols.xs for the C side.)
#
# NAMING: `select` and `rename` are Perl core builtins, so exporting bare
# `select`/`rename` would shadow them in the caller.  The `_cols` suffix
# avoids that and reads as a trio.
# =====================================================================


# select_cols($df, @cols) | select_cols($df, \@cols)
# drop_cols($df,   @cols) | drop_cols($df,   \@cols)
# rename_cols($df, old => new, ...) | rename_cols($df, { old => new, ... })
#
# Column subset / drop / rename over the four frame shapes -- the Stats::LikeR
# form of pandas df[['a','b']] / df.drop(columns=..) / df.rename(columns=..).
#
#   * AoA  -- identifiers are 0-based integer positions; rename_cols dies
#            (an AoA has no labels; convert to AoH/HoA first).
#   * AoH  -- identifiers are the row-hash keys.
#   * HoA  -- identifiers are the top-level keys (the columns themselves).
#   * HoH  -- identifiers are the inner-row keys.
#
# VIEW SEMANTICS (fast + low RAM).  Every result is a shallow view of the
# source, so huge frames cost almost nothing to slice:
#   * the row shapes (AoH/HoH/AoA) build fresh row containers but SHARE the
#     cell scalars by reference -- no per-cell copy, no duplicate scalar
#     bodies (this is the XS path; see below);
#   * HoA shares the whole column arrayrefs (a pure-Perl alias).
# The operation never mutates the source.  But because cells/columns are
# shared, later IN-PLACE mutation of a result cell (e.g. $r->[0]{a}++) or a
# push/splice on a result HoA column reaches the source.  Assigning a whole
# cell ($r->[0]{a} = ...) is always safe.  Need an independent copy?  Clone
# the result (e.g. Storable::dclone).
#
# IN-PLACE RENAME (rename_cols only).  Called in VOID context, rename_cols
# mutates the source frame in place -- it renames the keys inside each AoH/HoH
# row, or the column keys of a HoA -- and returns nothing.  In ANY other
# context it returns a fresh view (as above) and never touches the source:
#
#     rename_cols(\%d, resolution => 'Resolution (A)'); # void   -> %d in place
#     %d = %{ rename_cols(\%d, resolution => 'Resolution (A)') }; # capture view
#
# (select_cols/drop_cols are always pure and ignore calling context -- a void
# call to either is a no-op.)  Note: `\%d = rename_cols(...)` is not valid Perl
# (a reference constructor is not an lvalue before 5.22 refaliasing); use one
# of the two forms above.
#
# The row shapes are dispatched to XS (_cols_* ), which shares cells and
# hashes each column key once instead of once per row -- ~2x (select), ~3x
# (drop), ~4x (rename) faster than the pure-Perl rebuild at scale, and lower
# peak RAM (no copied cells).  HoA/AoA-by-alias need no XS.  All validation
# stays here in Perl, so the XS never has to croak mid-build.
#
# STRICT: a missing/renamed-away column, a duplicate in a select/drop list,
# or a rename whose targets are not distinct, all die with a labelled message.
# A column present in only some AoH/HoH rows is filled with undef by
# select_cols (rectangular); drop_cols/rename_cols leave ragged frames ragged.

sub _cols_arg {                         # normalise + validate a column list
	my ($fn, @a) = @_;
	my @cols = (@a == 1 && ref $a[0] eq 'ARRAY') ? @{ $a[0] } : @a;
	die "$fn: at least one column is required\n" unless @cols;
	my %seen;
	for my $c (@cols) {
		die "$fn: column identifier is undefined\n" unless defined $c;
		die "$fn: duplicate column '$c' in the list\n" if $seen{$c}++;
	}
	return @cols;
}

sub _aoa_width { # widest row of an AoA (ragged-safe)
	my $df = shift;
	my $w = 0;
	for my $r (@$df) { $w = scalar @$r if ref $r eq 'ARRAY' && @$r > $w }
	return $w;
}

sub _aoa_int_cols { # validate integer positions in range
	my ($fn, $df, @cols) = @_;
	my $w = _aoa_width($df);
	for my $c (@cols) {
		die "$fn: AoA column '$c' is not a non-negative integer\n"
			unless $c =~ /^\d+$/;
		die "$fn: AoA column index $c out of range (max index " . ($w - 1) . ")\n"
			if $c >= $w;
	}
	return $w;
}

sub _present_keys { # union of keys over AoH/HoH rows
	my ($df, $shape) = @_;
	my @rows = $shape eq 'AoH' ? @$df : values %$df;
	my %seen;
	for my $r (@rows) { next unless ref $r eq 'HASH'; $seen{$_} = 1 for keys %$r }
	return \%seen;
}

sub _rename_inplace { # VOID-context rename: mutate the source
	my ($df, $shape, $map) = @_;
	if ($shape eq 'HoA') { # rename the column keys
		my %vals;                                   # gather-then-set = swap-safe
		for my $o (keys %$map) {
			next unless exists $df->{$o};
			$vals{ $map->{$o} } = delete $df->{$o};
		}
		$df->{$_} = $vals{$_} for keys %vals;
		return;
	}
	my @rows = $shape eq 'AoH' ? @$df : values %$df;    # AoH / HoH row hashes
	for my $row (@rows) {
		next unless ref $row eq 'HASH';
		my %vals;                                   # gather-then-set = swap-safe
		for my $o (keys %$map) {
			next unless exists $row->{$o};
			$vals{ $map->{$o} } = delete $row->{$o};
		}
		$row->{$_} = $vals{$_} for keys %vals;
	}
	return;
}

sub select_cols {# shape code passed to the XS: 1 = AoH, 2 = HoH, 3 = AoA
	my $df = shift;
	die "select_cols: undefined data in first position\n" unless defined $df;
	my @cols  = _cols_arg('select_cols', @_);
	my $shape = _df_shape($df, 'select_cols');

	if ($shape eq 'HoA') {                          # alias columns (pure Perl)
		for my $c (@cols) {
			die "select_cols: column '$c' not found\n" unless exists $df->{$c};
		}
		my %out;
		$out{$_} = $df->{$_} for @cols;
		return \%out;
	}
	if ($shape eq 'AoA') {
		_aoa_int_cols('select_cols', $df, @cols);
		return _cols_select($df, 3, [ @cols ]);
	}
	my $present = _present_keys($df, $shape);
	for my $c (@cols) {
		die "select_cols: column '$c' not found\n" unless $present->{$c};
	}
	return _cols_select($df, $shape eq 'AoH' ? 1 : 2, [ @cols ]);
}

sub drop_cols {
	my $df = shift;
	die "drop_cols: undefined data in first position\n" unless defined $df;
	my @cols  = _cols_arg('drop_cols', @_);
	my %drop  = map { $_ => 1 } @cols;
	my $shape = _df_shape($df, 'drop_cols');

	if ($shape eq 'HoA') {                          # alias survivors (pure Perl)
		for my $c (@cols) {
			die "drop_cols: column '$c' not found\n" unless exists $df->{$c};
		}
		my %out;
		for my $k (keys %$df) { next if $drop{$k}; $out{$k} = $df->{$k} }
		return \%out;
	}
	if ($shape eq 'AoA') {
		my $w    = _aoa_int_cols('drop_cols', $df, @cols);
		my @keep = grep { !$drop{$_} } 0 .. $w - 1;
		return _cols_select($df, 3, [ @keep ]);     # keep == select the rest
	}
	my $present = _present_keys($df, $shape);
	for my $c (@cols) {
		die "drop_cols: column '$c' not found\n" unless $present->{$c};
	}
	return _cols_drop($df, $shape eq 'AoH' ? 1 : 2, \%drop);
}

sub rename_cols {
	my $df = shift;
	die "rename_cols: undefined data in first position\n" unless defined $df;
	my %map;
	if (@_ == 1 && ref $_[0] eq 'HASH') {
		%map = %{ $_[0] };
	} else {
		die "rename_cols: arguments after the data frame must be old => new pairs (or one hashref)\n"
			if @_ % 2;
		%map = @_;
	}
	die "rename_cols: at least one old => new mapping is required\n" unless %map;
	for my $o (keys %map) {
		die "rename_cols: new name for '$o' is undefined\n" unless defined $map{$o};
	}
	my $shape = _df_shape($df, 'rename_cols');
	die "rename_cols: an AoA has no column names to rename (convert to AoH/HoA first)\n"
		if $shape eq 'AoA';

	my @present = $shape eq 'HoA' ? keys %$df
	                              : keys %{ _present_keys($df, $shape) };
	my %present = map { $_ => 1 } @present;
	for my $o (keys %map) {
		die "rename_cols: column '$o' not found\n" unless $present{$o};
	}
	my %final;                                      # target names stay distinct
	for my $c (@present) {
		my $nn = exists $map{$c} ? $map{$c} : $c;
		die "rename_cols: rename collides -- two columns would both become '$nn'\n"
			if $final{$nn}++;
	}

	# VOID context -> mutate the source in place and return nothing; any other
	# context returns a fresh shallow view exactly as before.
	unless (defined wantarray) {
		_rename_inplace($df, $shape, \%map);
		return;
	}

	if ($shape eq 'HoA') {                          # alias under new keys
		my %out;
		for my $k (keys %$df) {
			my $nk = exists $map{$k} ? $map{$k} : $k;
			$out{$nk} = $df->{$k};
		}
		return \%out;
	}
	return _cols_rename($df, $shape eq 'AoH' ? 1 : 2, \%map);
}

sub aoh2hoh {
	my ($aoh, $key) = @_;
	die 'aoh2hoh: first argument is undefined' unless defined $aoh;
	die 'aoh2hoh: first argument must be an arrayref of hashrefs'
	  unless ref($aoh) eq 'ARRAY';
	die 'aoh2hoh: a row key must be defined' unless defined $key;
	my %out;
	my $i = 0;
	for my $row (@$aoh) {
		die "index $i is not a hash" unless ref($row) eq 'HASH';
		die "index $i has no key \"$key\"" unless defined $row->{$key};
		my $rk = $row->{$key};
		die "aoh2hoh: duplicate key '$rk' has >= 2 occurrences"
			if exists $out{$rk};
		$out{$rk} = { %$row }; # shallow copy of the row
		$i++;
	}
	return \%out;
}

# ===========================================================================
# h2aoh / aoh2h  --  the flat hash as a two-column frame
#
# A plain hash is a two-column table that has been folded shut: every pair is
# one row, the key in one cell and the value in the other.  value_counts() and
# table() hand one back, and none of the frame functions will take it, because
# they all want nested data.  h2aoh unfolds the hash into a real AoH; aoh2h
# folds an AoH back down.  R spells this pair enframe()/deframe() (tibble);
# pandas spells it pd.Series(d).rename_axis(..).reset_index(name => ..) and
# Series.to_dict().
#
# The column names are var_name / value_name, the same two options melt() uses
# to name the columns it emits, since the shape they describe is the same.
#
# The pair are exact inverses under their defaults, so
#     is_deeply( aoh2h( h2aoh(\%h) ), \%h )
# holds for any flat hash whose keys are defined.
# ===========================================================================

# _kv_names($caller, \%arg) -- var_name / value_name, defaulted and checked.
# Shared so the two directions cannot drift apart on the names they agree on.
sub _kv_names {
	my ($caller, $arg) = @_;
	my $var   = defined $arg->{var_name}   ? $arg->{var_name}   : 'variable';
	my $value = defined $arg->{value_name} ? $arg->{value_name} : 'value';
	die "$caller: var_name and value_name must differ\n" if $var eq $value;
	return ($var, $value);
}

sub h2aoh {
	my $h = shift;
	die "h2aoh: first argument is undefined\n" unless defined $h;
	die "h2aoh: first argument must be a hashref\n" unless ref($h) eq 'HASH';
	die "h2aoh: arguments after the hash must be name => value pairs\n"
		if @_ % 2;
	my %arg   = @_;
	my %known = ( var_name => 1, value_name => 1, sort => 1 );
	my @bad   = sort grep { !$known{$_} } keys %arg;
	die "h2aoh: unknown argument(s): @bad\n" if @bad;

	my ($var_name, $value_name) = _kv_names('h2aoh', \%arg);

	# A reference value means the caller has a nested frame in hand, not a flat
	# hash, and one of the shape converters is the function they wanted.  Say
	# which, rather than quietly stringifying the ref into a cell.
	for my $k (sort keys %$h) {
		next unless ref $h->{$k};
		die "h2aoh: the value for key '$k' is a " . ref($h->{$k})
		  . " reference; h2aoh takes a flat hash (hoa2aoh converts a "
		  . "hash-of-arrays, hoh2hoa a hash-of-hashes)\n";
	}

	my $how = defined $arg{sort} ? lc $arg{sort} : 'key';
	my @keys = keys %$h;
	if ($how eq 'key') {
		# numeric when every key is a number, else string -- the rule agg()
		# already uses for its group keys
		@keys = ( grep { !looks_like_number($_) } @keys )
		      ? sort @keys
		      : sort { $a <=> $b } @keys;
	}
	elsif ($how eq 'value') {
		# biggest first for counts, which is what value_counts() output is for
		# and what pandas' Series.value_counts() gives.  Non-numeric values have
		# no such convention, so they go up in string order.  undef sorts last
		# either way, and ties break on the key so the order is total.
		my $numeric = !grep { !looks_like_number($_) }
		              grep { defined } values %$h;
		@keys = sort {
			   ( defined $h->{$a} ? 0 : 1 ) <=> ( defined $h->{$b} ? 0 : 1 )
			|| ( !defined $h->{$a} ? 0
			   : $numeric          ? $h->{$b} <=> $h->{$a}
			   :                     $h->{$a} cmp $h->{$b} )
			|| $a cmp $b
		} @keys;
	}
	elsif ($how ne 'none') {
		die "h2aoh: sort '$how' isn't allowed (key, value, none)\n";
	}

	return [ map { { $var_name => $_, $value_name => $h->{$_} } } @keys ];
}

sub aoh2h {
	my $aoh = shift;
	die "aoh2h: first argument is undefined\n" unless defined $aoh;
	die "aoh2h: first argument must be an arrayref of hashrefs\n"
		unless ref($aoh) eq 'ARRAY';
	die "aoh2h: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg   = @_;
	my %known = ( var_name => 1, value_name => 1, duplicates => 1 );
	my @bad   = sort grep { !$known{$_} } keys %arg;
	die "aoh2h: unknown argument(s): @bad\n" if @bad;

	my ($var_name, $value_name) = _kv_names('aoh2h', \%arg);
	my $dup = defined $arg{duplicates} ? lc $arg{duplicates} : 'die';
	die "aoh2h: duplicates '$dup' isn't allowed (die, first, last)\n"
		unless $dup eq 'die' || $dup eq 'first' || $dup eq 'last';

	my %out;
	my $i = 0;
	for my $row (@$aoh) {
		die "aoh2h: index $i is not a hashref\n" unless ref($row) eq 'HASH';
		die "aoh2h: index $i has no '$var_name' column\n"
			unless exists $row->{$var_name};
		die "aoh2h: index $i has no '$value_name' column\n"
			unless exists $row->{$value_name};
		my $k = $row->{$var_name};
		die "aoh2h: index $i has an undefined '$var_name'; a hash key has to "
		  . "be defined\n" unless defined $k;
		if (exists $out{$k}) {
			die "aoh2h: duplicate key '$k' has >= 2 occurrences\n"
				if $dup eq 'die';
			if ($dup eq 'first') { $i++; next }
		}
		$out{$k} = $row->{$value_name};
		$i++;
	}
	return \%out;
}
# =======================================================================
# agg / concat / rbind  --  additions to lib/Stats/LikeR.pm
# Splice these in after the dropna sub. Also add  agg concat rbind  to
# @EXPORT_OK. rbind is a true glob-alias synonym for concat.
# =======================================================================

sub _df_shape {
	my ($df, $caller) = @_;
	$caller = 'data frame' unless defined $caller;
	die "$caller: data frame must be an ARRAY (AoA/AoH) or HASH (HoA/HoH) ref\n"
		unless ref $df;
	if (ref $df eq 'ARRAY') {
		for my $e (@$df) {
			next unless defined $e;
			return 'AoA' if ref $e eq 'ARRAY';
			return 'AoH' if ref $e eq 'HASH';
			die "$caller: array elements must be ARRAY (AoA) or HASH (AoH) refs\n";
		}
		return 'AoH';                         # empty -> harmless default
	}
	# HASH: HoA vs HoH, rejecting a mix
	my ($saw_arr, $saw_hash) = (0, 0);
	for my $v (values %$df) {
		next unless ref $v;
		$saw_arr++  if ref $v eq 'ARRAY';
		$saw_hash++ if ref $v eq 'HASH';
	}
	die "$caller: hashref mixes array and hash values (ambiguous HoA/HoH)\n"
		if $saw_arr and $saw_hash;
	return 'HoH' if $saw_hash;
	return 'HoA';                             # arrays, or empty -> default
}

# ---------------------------------------------------------------------------
# agg($df, agg => { col => 'mean' | [ 'mean', 'sd', .. ] | \&code, .. }, %opts)
#
# Split-apply-combine over any of the four data-frame shapes.  With `by` it is
# the combine half of group_by (which only splits); without `by` it collapses
# the whole frame to a single row, like pandas df.agg(...).
#
# $df   : AoA | AoH | HoA | HoH.  For AoA the column identifiers in `by` and in
#         the `agg` spec are integer positions; for the other three they are
#         column names.
#
# OPTIONS
#   agg  => { col => spec, .. }   REQUIRED.  spec is one aggregator name, an
#           arrayref of names, or a coderef.  Named aggregators:
#             mean median sum sd var min max  (numeric; call the XS functions)
#             count    number of defined (non-undef) cells
#             n        number of cells, undef included
#             nunique  number of distinct defined cells
#             first    first defined cell   (undef if none)
#             last     last  defined cell   (undef if none)
#             mode     modal defined cell; ties resolved deterministically
#                      (smallest number, else lowest string)
#           A coderef is called as $code->(\@cells) with every cell for that
#           column in the group (undef included) and must return one scalar.
#   by   => $col | \@cols         optional grouping column(s).
#   skipna => 0|1                 default 1.  When 0, a numeric named aggregator
#           (mean median sum sd var mode) over a group that contains any undef
#           yields undef, matching pandas skipna=False; count/n/nunique/first/
#           last always ignore this flag.
#   sort => 0|1                   default 1.  Sort output groups by key
#           (numeric if every key looks like a number, else string); 0 keeps
#           first-seen order.
#   'output.type' => aoa|aoh|hoa|hoh    default: same family as $df.
#
# OUTPUT COLUMN ORDER is deterministic: the `by` columns in the given order,
# then the aggregated columns sorted (numerically for AoA integer columns, else
# as strings), each expanded over its aggregator list in the order supplied.  A
# column reduced by a single aggregator keeps its own name; with two or more it
# becomes "<col>_<func>" (e.g. age_mean, age_sd).  For hoh output the row label
# is the group value (multiple `by` columns joined with '.'), 'all' when there
# is no grouping, and made unique with a .N suffix on collision.
#
# Numeric aggregators need enough defined cells or the cell is undef: mean /
# median / sum / min / max need >= 1, sd / var need >= 2.  The original $df is
# never modified.
# ---------------------------------------------------------------------------
{
	my %AGG_MIN = (          # minimum defined count for the XS numeric reducers
		mean => 1, median => 1, sum => 1, min => 1, max => 1,
		sd   => 2, var    => 2,
	);
	my %AGG_NUMERIC = map { $_ => 1 } qw(mean median sum sd var mode);

	sub _agg_reduce {
		my ($func, $raw, $def, $skipna) = @_;   # $raw, $def: arrayrefs (def excl. undef)
		return $func->($raw) if ref $func eq 'CODE';
		# NA policy for numeric reducers when the caller asked for skipna => 0
		return undef if !$skipna && $AGG_NUMERIC{$func} && @$def != @$raw;
		if ($func eq 'count')   { return scalar @$def }
		if ($func eq 'n')       { return scalar @$raw }
		if ($func eq 'nunique') { my %s; @s{ @$def } = (); return scalar keys %s }
		if ($func eq 'first')   { return @$def ? $def->[0]  : undef }
		if ($func eq 'last')    { return @$def ? $def->[-1] : undef }
		if ($func eq 'mode') {
			return undef unless @$def;
			my @m = mode($def);
			return (grep { !looks_like_number($_) } @m)
				? (sort @m)[0]
				: (sort { $a <=> $b } @m)[0];
		}
		die "agg: unknown aggregator '$func'\n" unless exists $AGG_MIN{$func};
		return undef if @$def < $AGG_MIN{$func};
		return mean($def)   if $func eq 'mean';
		return median($def) if $func eq 'median';
		return sum($def)    if $func eq 'sum';
		return sd($def)     if $func eq 'sd';
		return var($def)    if $func eq 'var';
		return min($def)    if $func eq 'min';
		return max($def)    if $func eq 'max';
	}

	sub agg {
		my $df = shift;
		die 'agg: undefined data in first position' unless defined $df;
		my $shape = _df_shape($df, 'agg');
		die "agg: arguments after the data frame must be name => value pairs\n"
			if @_ % 2;
		my %arg = @_;
		my %known = ( agg => 1, by => 1, skipna => 1, sort => 1, 'output.type' => 1 );
		my @bad = sort grep { !$known{$_} } keys %arg;
		die "agg: unknown argument(s): @bad\n" if @bad;

		my $spec = $arg{agg};
		die "agg: an 'agg' spec (hashref of column => aggregator) is required\n"
			unless ref $spec eq 'HASH' and %$spec;

		my @by = !defined $arg{by}          ? ()
		       : ref $arg{by} eq 'ARRAY'    ? @{ $arg{by} }
		       :                              ( $arg{by} );
		my $skipna = exists $arg{skipna} ? ($arg{skipna} ? 1 : 0) : 1;
		my $dosort = exists $arg{sort}   ? ($arg{sort}   ? 1 : 0) : 1;
		my $otype  = defined $arg{'output.type'} ? lc $arg{'output.type'}
		           : lc $shape;
		my %ok_otype = ( aoa => 1, aoh => 1, hoa => 1, hoh => 1 );
		die "agg: output.type '$otype' isn't allowed (aoa, aoh, hoa, hoh)\n"
			unless $ok_otype{$otype};

		# columns actually needed (grouping + aggregated), classified once ---
		my @agg_cols = keys %$spec;
		{
			my $all_num = !grep { !looks_like_number($_) } @agg_cols;
			@agg_cols = $all_num ? sort { $a <=> $b } @agg_cols : sort @agg_cols;
		}
		my %need; $need{$_} = 1 for @by, @agg_cols;

		# extract each needed column ONCE, aligned to row positions 0 .. R-1.
		# access is specialised per shape (no per-cell closure); for HoA the
		# columns already are arrays, so they are aliased rather than rebuilt.
		my (%col, $R);
		if ($shape eq 'AoA') {
			my @h = grep { defined } @$df;
			$R = scalar @h;
			for my $c (keys %need) { $col{$c} = [ map { $_->[$c] } @h ] }
		} elsif ($shape eq 'AoH') {
			my @h = grep { defined } @$df;
			$R = scalar @h;
			for my $c (keys %need) { $col{$c} = [ map { $_->{$c} } @h ] }
		} elsif ($shape eq 'HoA') {
			$R = 0;
			for my $v (values %$df) { $R = @$v if ref $v eq 'ARRAY' && @$v > $R }
			for my $c (keys %need) {
				$col{$c} = ref $df->{$c} eq 'ARRAY' ? $df->{$c} : [];
			}
		} else { # HoH
			my @h = map { $df->{$_} } sort keys %$df;
			$R = scalar @h;
			for my $c (keys %need) { $col{$c} = [ map { $_->{$c} } @h ] }
		}

		# split row indices into groups, preserving first-seen order --------
		my (%group, @order, %repr);
		my $one = @by == 1 ? $by[0] : undef;   # single-key fast path
		for (my $i = 0; $i < $R; $i++) {
			my $key;
			if (!@by) {
				$key = "\0all";
			} elsif (defined $one) {
				my $v = $col{$one}[$i];
				$key = defined $v ? "v$v" : "\0";
			} else {
				$key = join "\x1e",
					map { my $v = $col{$_}[$i]; defined $v ? "v$v" : "\0" } @by;
			}
			my $g = $group{$key};
			unless ($g) {
				$group{$key} = $g = [];
				push @order, $key;
				$repr{$key} = [ map { $col{$_}[$i] } @by ];
			}
			push @$g, $i;
		}
		if ($dosort && @by) {                  # sort by the group value(s)
			my $all_num = 1;
			SORTNUM: for my $k (@order) {
				for my $v (@{ $repr{$k} }) {
					unless (defined $v && looks_like_number($v)) { $all_num = 0; last SORTNUM }
				}
			}
			if ($all_num) {
				@order = sort {
					my ($ra, $rb) = ($repr{$a}, $repr{$b});
					my $c = 0;
					for my $j (0 .. $#$ra) { last if $c = $ra->[$j] <=> $rb->[$j] }
					$c;
				} @order;
			} else {
				@order = sort {
					my ($ra, $rb) = ($repr{$a}, $repr{$b});
					my $c = 0;
					for my $j (0 .. $#$ra) {
						my $x = defined $ra->[$j] ? $ra->[$j] : '';
						my $y = defined $rb->[$j] ? $rb->[$j] : '';
						last if $c = $x cmp $y;
					}
					$c;
				} @order;
			}
		}

# output plan: by-columns pass through, then each agg column with its
# aggregator list contiguous.  A single aggregator keeps the column
# name; two or more become "<col>_<func>".
		my @agg_plan; # [ col, [funcs], [out_names] ]
		for my $c (@agg_cols) {
			my $s = $spec->{$c};
			my @funcs = ref $s eq 'ARRAY' ? @$s : ($s);
			die "agg: empty aggregator list for column '$c'\n" unless @funcs;
			my $multi = @funcs > 1;
			my @names = map {
				my $l = ref $_ eq 'CODE' ? 'fn' : $_;
				$multi ? "${c}_${l}" : $c;
			} @funcs;
			push @agg_plan, [ $c, \@funcs, \@names ];
		}
		my @out_names = ( @by, map { @{ $_->[2] } } @agg_plan );

# combine + materialise straight into the requested shape -----------
		my (@aoa_rows, @aoh_rows, %hoa, %hoh, %seen);
		if ($otype eq 'hoa') { $hoa{$_} = [] for @out_names }

		for my $key (@order) {
			my $idx = $group{$key};
			my @vals = @{ $repr{$key} };            # by-column values, in order
			for my $ap (@agg_plan) {
				my ($c, $funcs, undef) = @$ap;
				my @raw = @{ $col{$c} }[ @$idx ];   # one slice, shared by all funcs
				my @def = grep { defined } @raw;
				push @vals, _agg_reduce($_, \@raw, \@def, $skipna) for @$funcs;
			}
			if ($otype eq 'aoa') {
				push @aoa_rows, \@vals;
			} elsif ($otype eq 'aoh') {
				my %h; @h{ @out_names } = @vals; push @aoh_rows, \%h;
			} elsif ($otype eq 'hoa') {
				push @{ $hoa{ $out_names[$_] } }, $vals[$_] for 0 .. $#out_names;
			} else { # hoh
				my $label = @by
					? join('.', map { defined $_ ? $_ : '' } @{ $repr{$key} })
					: 'all';
				my $uniq = $label; my $j = 0;
				while (exists $seen{$uniq}) { $uniq = $label . '.' . (++$j) }
				$seen{$uniq} = 1;
				my %h; @h{ @out_names } = @vals; $hoh{$uniq} = \%h;
			}
		}
		return \@aoa_rows if $otype eq 'aoa';
		return \@aoh_rows if $otype eq 'aoh';
		return \%hoa      if $otype eq 'hoa';
		return \%hoh;
	}
}


# assign($df, name => \&code, name2 => \&code2, ...)
#
# Add (or overwrite) columns derived from existing ones, dplyr-mutate style.
# Each coderef is called once per row with the row as $_ (a hashref) and also
# as $_[0]; $_[1] is the 0-based row index. For HoH inputs, $_[2] is the row key.
# It returns the new cell value.
#
# Works on all three data-frame shapes:
#   AoH  [ {weight=>70, height=>1.8}, ... ]        (arrayref of row hashrefs)
#   HoA  { weight=>[70,...], height=>[1.8,...] }   (hashref of column arrayrefs)
#   HoH  { r1 => {weight=>70}, r2 => {...} }       (hashref of row hashrefs)
#
# Pairs are applied in order, so a later column may use an earlier new one.
# Modifies $df in place (lowest RAM/CPU) and returns it for chaining.
# To keep the original intact, hand it a copy: assign(clone($df), ...).
#
# A value may also be a map_cell { ... } block (see below) for an in-place
# per-cell edit of the named column, instead of a CODE ref or ready-made ARRAY.
#

# ---------------------------------------------------------------------------
# map_cell { ... }   -- in-place per-cell transform for assign().
#
# Wraps a block so assign() runs it once per row with $_ aliased to a copy of
# the NAMED column's current cell; the (possibly modified) $_ is stored back and
# the block's return value is ignored.  This makes an in-place edit read
# naturally, without the "copy, substitute, return" dance a plain sub needs
# (perl 5.10 has no s///r):
#
#   assign($tbl, 'Res.' => map_cell { s/^[A-Z]:// });   # strip a leading "X:"
#   assign($tbl, 'Res.' => map_cell { $_ = uc });        # upper-case in place
#
# The row is still available as $_[0] (and the index as $_[1]) if the transform
# needs a sibling column.  A plain sub { ... } keeps its existing meaning
# ($_ = the whole row, the return value is stored), so map_cell is purely
# additive and changes nothing for existing callers.
#
# An undef cell is left untouched (undef in -> undef out): the block never runs
# on it, so s/// and friends don't warn on uninitialized values and a missing
# cell stays missing rather than becoming ''.
# ---------------------------------------------------------------------------
sub map_cell (&) {
	my ($code) = @_;
	die "map_cell: expects a code block, e.g. map_cell { s/x//g }\n"
		unless ref $code eq 'CODE';
	return bless { code => $code }, 'Stats::LikeR::map_cell';
}

sub assign {
	my $df = shift;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	die "$current_sub: first argument is undefined" unless defined $df;
	die "$current_sub: first argument must be a data frame (AoH arrayref or HoA/HoH hashref)"
		unless ref $df;
	die "$current_sub: expected an even list of (name => value) pairs" if @_ % 2;

	my $r = ref $df;

	# Each value is CODE (per-row scalar OR whole-column list) or ARRAY (ready column).
	# CODE is probed once in list context: >1 return value => whole column.

	if ($r eq 'ARRAY') {                            # ----- AoH -----
		my $n = @$df;
		while (@_) {
			my ($name, $spec) = (shift, shift);
			my $sref = ref $spec;
			if ($sref eq 'Stats::LikeR::map_cell') {   # in-place per-cell edit; $_ = current cell
				my $code = $spec->{code};
				for my $i (0 .. $n - 1) {
					my $row = $df->[$i];
					die "$current_sub: row $i is not a hashref" unless ref $row eq 'HASH';
					local $_ = $row->{$name};
					next unless defined $_;   # undef cells pass through untouched (undef in -> undef out)
					$code->($row, $i);
					$row->{$name} = $_;
				}
				next;
			}
			die "$current_sub: value for '$name' must be a CODE or ARRAY ref"
				unless $sref eq 'CODE' or $sref eq 'ARRAY';

			if ($sref eq 'ARRAY') {                 # ready-made column
				die "$current_sub: column '$name' has " . @$spec . " values but data frame has $n rows"
					unless @$spec == $n;
				for my $i (0 .. $n - 1) {
					die "$current_sub: row $i is not a hashref" unless ref $df->[$i] eq 'HASH';
					$df->[$i]{$name} = $spec->[$i];
				}
				next;
			}

			next unless $n;                         # empty AoH: nothing to compute

			my $row0 = $df->[0];
			die "$current_sub: row 0 is not a hashref" unless ref $row0 eq 'HASH';
			my @out;
			{
				local $_ = $row0;
				@out = $spec->($row0, 0);
			}
			if (@out > 1) {                         # whole-column list (e.g. rank())
				die "$current_sub: column '$name' produced " . @out . " values but data frame has $n rows"
					unless @out == $n;
				for my $i (0 .. $n - 1) {
					die "$current_sub: row $i is not a hashref" unless ref $df->[$i] eq 'HASH';
					$df->[$i]{$name} = $out[$i];
				}
				next;
			}
			$row0->{$name} = $out[0];               # per-row: row 0 already computed
			for my $i (1 .. $n - 1) {
				my $row = $df->[$i];
				die "$current_sub: row $i is not a hashref" unless ref $row eq 'HASH';
				local $_ = $row;
				$row->{$name} = $spec->($row, $i);
			}
		}
		return $df;
	}

	if ($r eq 'HASH') {
		my $is_hoh = 0;
		for my $v (values %$df) {
			my $ref = ref $v;
			if    ($ref eq 'HASH')  { $is_hoh = 1; last }
			elsif ($ref eq 'ARRAY') { $is_hoh = 0; last }
			else { die "$current_sub: value is a \"$ref\" which is neither a HASH nor an ARRAY" }
		}

		if ($is_hoh) {                              # ----- HoH -----
			my @rk = sort keys %$df;
			my $n  = @rk;
			while (@_) {
				my ($name, $spec) = (shift, shift);
				my $sref = ref $spec;
				if ($sref eq 'Stats::LikeR::map_cell') {   # in-place per-cell edit; $_ = current cell
					my $code = $spec->{code};
					for my $i (0 .. $n - 1) {
						my $row = $df->{ $rk[$i] };
						die "$current_sub: row '$rk[$i]' is not a hashref" unless ref $row eq 'HASH';
						local $_ = $row->{$name};
						next unless defined $_;   # undef cells pass through untouched (undef in -> undef out)
						$code->($row, $i, $rk[$i]);
						$row->{$name} = $_;
					}
					next;
				}
				die "$current_sub: value for '$name' must be a CODE or ARRAY ref"
					unless $sref eq 'CODE' or $sref eq 'ARRAY';

				if ($sref eq 'ARRAY') {
					die "$current_sub: column '$name' has " . @$spec . " values but data frame has $n rows"
						unless @$spec == $n;
					for my $i (0 .. $n - 1) {
						my $row = $df->{ $rk[$i] };
						die "$current_sub: row '$rk[$i]' is not a hashref" unless ref $row eq 'HASH';
						$row->{$name} = $spec->[$i];
					}
					next;
				}

				next unless $n;

				my $row0 = $df->{ $rk[0] };
				die "$current_sub: row '$rk[0]' is not a hashref" unless ref $row0 eq 'HASH';
				my @out;
				{
					local $_ = $row0;
					@out = $spec->($row0, 0, $rk[0]);
				}
				if (@out > 1) {
					die "$current_sub: column '$name' produced " . @out . " values but data frame has $n rows"
						unless @out == $n;
					for my $i (0 .. $n - 1) {
						my $row = $df->{ $rk[$i] };
						die "$current_sub: row '$rk[$i]' is not a hashref" unless ref $row eq 'HASH';
						$row->{$name} = $out[$i];
					}
					next;
				}
				$row0->{$name} = $out[0];
				for my $i (1 .. $n - 1) {
					my $row = $df->{ $rk[$i] };
					die "$current_sub: row '$rk[$i]' is not a hashref" unless ref $row eq 'HASH';
					local $_ = $row;
					$row->{$name} = $spec->($row, $i, $rk[$i]);
				}
			}
			return $df;
		}
		else {                                      # ----- HoA -----
			my $n = 0;
			for my $v (values %$df) {
				$n = @$v if ref $v eq 'ARRAY' and @$v > $n;
			}
			while (@_) {
				my ($name, $spec) = (shift, shift);
				my $sref = ref $spec;
				if ($sref eq 'Stats::LikeR::map_cell') {   # in-place per-cell edit; $_ = current cell
					my $code = $spec->{code};
					my $tgt  = $df->{$name};
					die "$current_sub: map_cell target column '$name' must already exist as an ARRAY ref\n"
						unless ref $tgt eq 'ARRAY';
					my @keys = keys %$df;
					my @col  = map { my $c = $df->{$_}; ref $c eq 'ARRAY' ? $c : undef } @keys;
					for my $i (0 .. $n - 1) {
						my %view;
						$view{ $keys[$_] } = defined $col[$_] ? $col[$_][$i] : $df->{ $keys[$_] }
							for 0 .. $#keys;
						local $_ = $tgt->[$i];
						next unless defined $_;   # undef cells pass through untouched (undef in -> undef out)
						$code->(\%view, $i);
						$tgt->[$i] = $_;
					}
					next;
				}
				die "$current_sub: value for '$name' must be a CODE or ARRAY ref"
					unless $sref eq 'CODE' or $sref eq 'ARRAY';

				if ($sref eq 'ARRAY') {
					die "$current_sub: column '$name' has " . @$spec . " values but data frame has $n rows"
						unless @$spec == $n;
					$df->{$name} = [ @$spec ];
					next;
				}

				if (not $n) { $df->{$name} = []; next }

				# snapshot current columns once (refs, not data)
				my @keys = keys %$df;
				my @col  = map { my $c = $df->{$_}; ref $c eq 'ARRAY' ? $c : undef } @keys;
				my $view_for = sub {
					my $i = shift;
					my %view;
					$view{ $keys[$_] } = defined $col[$_] ? $col[$_][$i] : $df->{ $keys[$_] }
						for 0 .. $#keys;
					return \%view;
				};

				my $v0 = $view_for->(0);
				my @out;
				{
					local $_ = $v0;
					@out = $spec->($v0, 0);
				}
				if (@out > 1) {                     # whole-column list
					die "$current_sub: column '$name' produced " . @out . " values but data frame has $n rows"
						unless @out == $n;
					$df->{$name} = [ @out ];
					next;
				}
				my @new;
				$#new = $n - 1;                     # preallocate
				$new[0] = $out[0];
				for (my $i = 1; $i < $n; $i++) {
					my $view = $view_for->($i);
					local $_ = $view;
					$new[$i] = $spec->($view, $i);
				}
				$df->{$name} = \@new;
			}
			return $df;
		}
	}
	die "$current_sub: data frame must be an arrayref (AoH) or hashref (HoA/HoH)";
}

sub chunk {
	my ($aref, %opt) = @_;
	die "chunk: first argument must be an ARRAY reference\n"
		unless ref $aref eq 'ARRAY';

	die "chunk: pass exactly one of size => N or parts => K\n"
		if  (defined $opt{size} && defined $opt{parts})
		||  (!defined $opt{size} && !defined $opt{parts});

	my $n = scalar @$aref;
	return () unless $n; # empty input -> no groups

	my @groups;
	if (defined $opt{size}) {
		my $sz = $opt{size};
		die "chunk: size must be a positive integer\n"
			unless $sz =~ /\A[1-9][0-9]*\z/;
		for (my $i = 0; $i < $n; $i += $sz) {
			my $hi = $i + $sz - 1;
			$hi = $n - 1 if $hi > $n - 1;
			push @groups, [ @{$aref}[$i .. $hi] ];
		}
	} else {
		my $k = $opt{parts};
		die "chunk: parts must be a positive integer\n"
			unless $k =~ /\A[1-9][0-9]*\z/;
		for my $i (0 .. $k - 1) {
			my $lo = int( $i       * $n / $k );
			my $hi = int( ($i + 1) * $n / $k );
			push @groups, [ @{$aref}[$lo .. $hi - 1] ];
		}
	}
	return @groups;
}

# ---- filter DSL: col() builds a predicate via overloading (pure Perl) -------
# col('name') returns an overloaded object; comparing it (col('age') >= 18) or
# combining comparisons with & | ! builds a predicate that carries its per-row
# test in a {code} closure. filter() (XS) unwraps that closure, so col() and a
# plain coderef share one evaluation path -- no XS evaluator, no Carp.
#
# Rules: numeric ops > < >= <= == != compare as numbers; string ops gt lt ge le
# eq ne compare as strings; & | ! combine; operands may be in either order; a
# missing/undef cell (and, for numeric ops, a non-numeric cell) never matches.
sub col { Stats::LikeR::col::_new(@_) }
{
	package Stats::LikeR::col;
	use warnings;
	use Scalar::Util qw(blessed looks_like_number);
	use overload
		'>'	 => sub { _num($_[0], '>',	$_[1], $_[2]) },
		'<'	 => sub { _num($_[0], '<',	$_[1], $_[2]) },
		'>=' => sub { _num($_[0], '>=', $_[1], $_[2]) },
		'<=' => sub { _num($_[0], '<=', $_[1], $_[2]) },
		'==' => sub { _num($_[0], '==', $_[1], $_[2]) },
		'!=' => sub { _num($_[0], '!=', $_[1], $_[2]) },
		'gt' => sub { _str($_[0], 'gt', $_[1], $_[2]) },
		'lt' => sub { _str($_[0], 'lt', $_[1], $_[2]) },
		'ge' => sub { _str($_[0], 'ge', $_[1], $_[2]) },
		'le' => sub { _str($_[0], 'le', $_[1], $_[2]) },
		'eq' => sub { _str($_[0], 'eq', $_[1], $_[2]) },
		'ne' => sub { _str($_[0], 'ne', $_[1], $_[2]) },
		'&'	 => sub { _logic($_[0], '&', $_[1]) },
		'|'	 => sub { _logic($_[0], '|', $_[1]) },
		'!'	 => sub { _not($_[0]) },
		'""'   => sub { 'Stats::LikeR::col predicate' },
		'bool' => sub { 1 },
		fallback => 0;

	sub _new {
		my ($name) = @_;
		die "col(): expects a single column name\n" if !defined($name) || ref $name;
		return bless { name => $name }, __PACKAGE__;
	}

	my %NUM = (
		'>'	 => sub { $_[0] >  $_[1] }, '<'	 => sub { $_[0] <  $_[1] },
		'>=' => sub { $_[0] >= $_[1] }, '<=' => sub { $_[0] <= $_[1] },
		'==' => sub { $_[0] == $_[1] }, '!=' => sub { $_[0] != $_[1] },
	);
	my %STR = (
		'gt' => sub { $_[0] gt $_[1] }, 'lt' => sub { $_[0] lt $_[1] },
		'ge' => sub { $_[0] ge $_[1] }, 'le' => sub { $_[0] le $_[1] },
		'eq' => sub { $_[0] eq $_[1] }, 'ne' => sub { $_[0] ne $_[1] },
	);

	# Besides the closure, a comparison carries a {plan}: the same test written
	# as plain data, which filter() (XS) compiles and runs in C, so a whole
	# frame can be tested without building a row hash or entering perl once per
	# row.  The plan is [ KIND, OP, column, literal, swap ] for a comparison and
	# [ KIND, left, right ] / [ KIND, operand ] for & | !.  KIND and OP are the
	# small integers LikeR.xs knows (FLTP_*/FLTC_*); the operator ids below are
	# positional, so the two tables must keep this order.
	#
	# A plan is only built for what C can reproduce exactly: the literal must be
	# a defined non-reference (and, for a numeric test, numeric), which rules
	# out overloaded objects and the warnings a non-numeric operand raises.
	# Everything else -- ->match/->nomatch, an object operand, any expression
	# with such a part in it -- carries no plan and takes the closure path, so
	# the two paths never disagree about a row.
	my $P_NUM = 0; my $P_STR = 1; my $P_AND = 2; my $P_OR = 3; my $P_NOT = 4;
	my %NUM_ID = ('>' => 0, '<' => 1, '>=' => 2, '<=' => 3, '==' => 4, '!=' => 5);
	my %STR_ID = ('gt' => 0, 'lt' => 1, 'ge' => 2, 'le' => 3, 'eq' => 4, 'ne' => 5);

	# numeric comparison: undef OR non-numeric cells never match
	sub _num {
		my ($self, $op, $other, $swap) = @_;
		my $name = $self->{name};
		die "col(): the '$op' comparison must start from a bare column, e.g. col('x') $op ...\n"
			unless defined $name;
		my $f = $NUM{$op};
		my $code = $swap
			? sub { my $c = $_[0]{$name}; (defined($c) && looks_like_number($c)) ? ($f->($other, $c) ? 1 : 0) : 0 }
			: sub { my $c = $_[0]{$name}; (defined($c) && looks_like_number($c)) ? ($f->($c, $other) ? 1 : 0) : 0 };
		my $plan = (defined($other) && !ref($other) && looks_like_number($other))
			? [ $P_NUM, $NUM_ID{$op}, $name, $other, ($swap ? 1 : 0) ] : undef;
		return bless { code => $code, ($plan ? (plan => $plan) : ()) }, __PACKAGE__;
	}

	# string comparison: undef cells never match
	sub _str {
		my ($self, $op, $other, $swap) = @_;
		my $name = $self->{name};
		die "col(): the '$op' comparison must start from a bare column, e.g. col('x') $op ...\n"
			unless defined $name;
		my $f = $STR{$op};
		my $code = $swap
			? sub { my $c = $_[0]{$name}; defined($c) ? ($f->($other, $c) ? 1 : 0) : 0 }
			: sub { my $c = $_[0]{$name}; defined($c) ? ($f->($c, $other) ? 1 : 0) : 0 };
		my $plan = (defined($other) && !ref($other))
			? [ $P_STR, $STR_ID{$op}, $name, $other, ($swap ? 1 : 0) ] : undef;
		return bless { code => $code, ($plan ? (plan => $plan) : ()) }, __PACKAGE__;
	}

	sub _logic {
		my ($self, $op, $other) = @_;
		my $lc = $self->{code};
		die "col(): the left operand of '$op' is not a comparison (build it like (col('x') > 0))\n"
			unless ref $lc eq 'CODE';
		my $rc = (blessed($other) && $other->isa(__PACKAGE__)) ? $other->{code} : undef;
		die "col(): the right operand of '$op' must be a col() comparison too\n"
			unless ref $rc eq 'CODE';
		my $code = $op eq '&'
			? sub { ($lc->($_[0]) && $rc->($_[0])) ? 1 : 0 }
			: sub { ($lc->($_[0]) || $rc->($_[0])) ? 1 : 0 };
		my $plan = ($self->{plan} && $other->{plan})
			? [ ($op eq '&' ? $P_AND : $P_OR), $self->{plan}, $other->{plan} ] : undef;
		return bless { code => $code, ($plan ? (plan => $plan) : ()) }, __PACKAGE__;
	}

	sub _not {
		my ($self) = @_;
		my $c = $self->{code};
		die "col(): the operand of '!' is not a comparison (build it like !(col('x') > 0))\n"
			unless ref $c eq 'CODE';
		my $plan = $self->{plan} ? [ $P_NOT, $self->{plan} ] : undef;
		return bless { code => sub { $c->($_[0]) ? 0 : 1 },
		               ($plan ? (plan => $plan) : ()) }, __PACKAGE__;
	}

	# regex predicates.  Perl cannot overload =~, so col('x') =~ /re/ can never
	# be intercepted; these methods give the same deferred, composable predicate
	# instead.  The pattern is a qr// or a string (compiled with qr//); an undef
	# cell never matches (mirroring the string comparisons).
	#   filter($df, col('id')->match(qr/^5iz/));
	#   filter($df, col('id')->nomatch('^5iz'));            # string pattern ok
	#   filter($df, col('id')->match(qr/^5iz/) & (col('res') < 2.5));
	sub _match {
		my ($self, $re, $want, $how) = @_;
		die "col(): ->$how must start from a bare column, e.g. col('x')->$how(qr/.../)\n"
			unless defined $self->{name};
		die "col(): ->$how needs a pattern (a qr// or a string)\n" unless defined $re;
		my $qr   = ref $re eq 'Regexp' ? $re : qr/$re/;
		my $name = $self->{name};
		my $code = sub {
			my $c = $_[0]{$name};
			return 0 unless defined $c;
			return ( ($c =~ $qr) ? 1 : 0 ) == $want ? 1 : 0;
		};
		return bless { code => $code }, __PACKAGE__;
	}
	sub match   { _match($_[0], $_[1], 1, 'match') }
	sub nomatch { _match($_[0], $_[1], 0, 'nomatch') }
}

# ---------------------------------------------------------------------------
# concat(@frames)   /   rbind(@frames)   -- row-bind data frames (pandas concat
# axis=0, R rbind).  rbind is a true synonym (same subroutine).
#
# Every frame must be the same shape (AoA/AoH/HoA/HoH); a mix dies with a hint
# to convert first (aoh2hoa, hoa2aoh, hoh2hoa, aoh2hoh).  undef frames and
# empty frames are skipped, and shape is taken from the first non-empty frame;
# passing nothing usable dies.  A NEW top-level frame of that shape is returned;
# the original frames are never modified.
#
#   AoA  outer arrays concatenated in order (row arrayrefs reused by ref).
#        Ragged rows are kept as-is; a short row reads undef past its end.
#   AoH  rows concatenated in order (row hashrefs reused by ref).  The result is
#        the union of columns; a column absent from a given row reads undef,
#        matching this library's "missing key == undef" convention (dropna,
#        view, summary).
#   HoA  union of columns (sorted for a deterministic layout).  Each column is
#        the per-frame arrays joined in frame order; a frame lacking a column,
#        or a ragged short column, is padded with undef so every column ends up
#        the same length (= total rows).
#   HoH  outer hashes merged in frame order (inner row hashrefs reused by ref).
#        Because a Perl hash cannot hold duplicate keys, a repeated row name is
#        made unique R-style (name, name.1, name.2, ...) and a single warning is
#        emitted noting that row names collided.
# ---------------------------------------------------------------------------
sub concat {
	my @frames = grep { defined } @_;
	die "concat: needs at least one data frame\n" unless @frames;

	# reference shape = first non-empty frame; remember a fallback for all-empty
	my $ref_shape;
	for my $f (@frames) {
		my $nonempty = ref $f eq 'ARRAY' ? scalar(@$f)
		             : ref $f eq 'HASH'  ? scalar(keys %$f)
		             : die "concat: every frame must be an ARRAY or HASH ref\n";
		next unless $nonempty;
		$ref_shape = _df_shape($f, 'concat');
		last;
	}
	unless (defined $ref_shape) {           # all frames empty
		return ref $frames[0] eq 'ARRAY' ? [] : {};
	}
	# all non-empty frames must agree
	for my $f (@frames) {
		my $nonempty = ref $f eq 'ARRAY' ? scalar(@$f) : scalar(keys %$f);
		next unless $nonempty;
		my $s = _df_shape($f, 'concat');
		die "concat: cannot mix a $s frame with a $ref_shape frame; "
		  . "convert them to one shape first (aoh2hoa, hoa2aoh, hoh2hoa, aoh2hoh)\n"
			if $s ne $ref_shape;
	}

	if ($ref_shape eq 'AoA') {
		my @out;
		for my $f (@frames) {
			for my $row (@$f) {
				die "concat: AoA row is not an ARRAY ref\n" unless ref $row eq 'ARRAY';
				push @out, $row;
			}
		}
		return \@out;
	}
	if ($ref_shape eq 'AoH') {
		my @out;
		for my $f (@frames) {
			for my $row (@$f) {
				die "concat: AoH row is not a HASH ref\n" unless ref $row eq 'HASH';
				push @out, $row;
			}
		}
		return \@out;
	}
	if ($ref_shape eq 'HoA') {
		my (@cols, %seen);                  # union of columns, sorted
		for my $f (@frames) { $seen{$_} = 1 for keys %$f }
		@cols = sort keys %seen;
		my %out = map { $_ => [] } @cols;
		for my $f (@frames) {
			my $n = 0;
			for my $c (keys %$f) {
				$n = @{ $f->{$c} } if ref $f->{$c} eq 'ARRAY' && @{ $f->{$c} } > $n;
			}
			for my $c (@cols) {
				if (ref $f->{$c} eq 'ARRAY') {
					push @{ $out{$c} }, @{ $f->{$c} };
					push @{ $out{$c} }, (undef) x ($n - @{ $f->{$c} })
						if @{ $f->{$c} } < $n;   # ragged short column
				} else {
					push @{ $out{$c} }, (undef) x $n; # column absent in this frame
				}
			}
		}
		return \%out;
	}
	# HoH
	my (%out, $collided);
	for my $f (@frames) {
		for my $rk (sort keys %$f) {
			die "concat: HoH row '$rk' is not a HASH ref\n"
				unless ref $f->{$rk} eq 'HASH';
			my $label = $rk;
			my $j = 0;
			while (exists $out{$label}) { $collided = 1; $label = $rk . '.' . (++$j) }
			$out{$label} = $f->{$rk};       # reuse the row ref
		}
	}
	warn "concat: duplicate HoH row name(s) made unique with a .N suffix\n"
		if $collided;
	return \%out;
}
{ no warnings 'once'; *rbind = \&concat; }  # true synonym
#
# dropna($df, cols => \@cols, how => 'any'|'all')	# NA mode
# dropna($df, rows => \@rows)						 # literal deletion
#
# $df may be:
#	AoH	 [ { A=>.., B=>.. }, ... ]			rows are 0-based indices
#	HoA	 { A=>[..], B=>[..] }				rows are 0-based indices
#	HoH	 { r1=>{ A=>.. }, r2=>{ .. } }		rows are the outer keys
#
# cols mode (NA): inspect the named columns and drop the rows that are undef
#	in them. how => 'any' (default) drops a row when any named column is undef;
#	how => 'all' drops it only when every named column is undef. Columns that
#	are not named are untouched but stay aligned (their cell at a dropped index
#	goes too). A missing key counts as undef.
#
# rows mode: delete exactly the listed rows (indices for AoH/HoA, keys for HoH);
#	no NA check. Indices/keys that aren't present are ignored.
#
# Returns a NEW top-level data frame; the original is never modified. For HoA
# the column arrays are rebuilt (cell values copied); for AoH/HoH the surviving
# row references are reused, not deep-copied (dropna never mutates a row).
#
sub dropna {
	my $df = shift;
	die 'dropna: first argument is undefined' unless defined $df;
	die "dropna: first argument must be a data frame (HoA/HoH hashref or AoH arrayref)\n"
		unless ref $df;
	die "dropna: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;

	my %known = ( cols => 1, rows => 1, how => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "dropna: unknown argument(s): @bad\n" if @bad;

	my $have_cols = exists $arg{cols};
	my $have_rows = exists $arg{rows};
	die "dropna: pass exactly one of 'cols' or 'rows'\n"
		unless $have_cols xor $have_rows;

	my $sel = $have_cols ? $arg{cols} : $arg{rows};
	die "dropna: '" . ($have_cols ? 'cols' : 'rows') . "' must be an arrayref\n"
		unless ref $sel eq 'ARRAY';

	my $how = defined $arg{how} ? lc $arg{how} : 'any';
	die "dropna: 'how' must be 'any' or 'all'\n"
		unless $how eq 'any' or $how eq 'all';

	my $r = ref $df;

	#----- AoH -----
	if ($r eq 'ARRAY') {
		if ($have_rows) {						# literal index deletion
			my %drop = map { $_ => 1 } @$sel;
			return [ map { $df->[$_] } grep { !$drop{$_} } 0 .. $#$df ];
		}
		my @cols = @$sel;
		return [ @$df ] unless @cols;			# nothing to check -> keep all
		return [] unless @$df;				# empty frame -> empty result
		my %seen;
		for my $row (@$df) {
			next unless ref $row eq 'HASH';
			$seen{$_} = 1 for keys %$row;
		}
		for my $c (@cols) {
			die "dropna: column '$c' not found\n" unless $seen{$c};
		}
		my @keep;
		for my $i (0 .. $#$df) {
			my $row = $df->[$i];
			my $nundef = (ref $row eq 'HASH')
				? (grep { !defined $row->{$_} } @cols)
				: @cols;						# malformed row counts as all-NA
			my $drop = $how eq 'any' ? $nundef > 0 : $nundef == @cols;
			push @keep, $i unless $drop;
		}
		return [ map { $df->[$_] } @keep ];
	}

	#----- HoA vs HoH -----
	if ($r eq 'HASH') {
		my ($saw_arr, $saw_hash) = (0, 0);
		for my $v (values %$df) {
			next unless ref $v;
			$saw_arr++	if ref $v eq 'ARRAY';
			$saw_hash++ if ref $v eq 'HASH';
		}
		die "dropna: hashref mixes array and hash values (ambiguous HoA/HoH)\n"
			if $saw_arr and $saw_hash;

		#----- HoH -----
		if ($saw_hash) {
			if ($have_rows) {					# delete row keys
				my %drop = map { $_ => 1 } @$sel;
				return { map { $_ => $df->{$_} } grep { !$drop{$_} } keys %$df };
			}
			my @cols = @$sel;
			return { %$df } unless @cols;
			my %out;
			for my $rk (keys %$df) {
				my $row = $df->{$rk};
				my $nundef = (ref $row eq 'HASH')
					? (grep { !defined $row->{$_} } @cols)
					: @cols;
				my $drop = $how eq 'any' ? $nundef > 0 : $nundef == @cols;
				$out{$rk} = $row unless $drop;
			}
			return \%out;
		}

		#----- HoA (also the empty-hash fallthrough) -----
		my $n = 0;
		for my $v (values %$df) {
			$n = @$v if ref $v eq 'ARRAY' and @$v > $n;
		}
		if ($have_rows) {						# delete indices
			my %drop = map { $_ => 1 } @$sel;
			my @keep = grep { !$drop{$_} } 0 .. $n - 1;
			return { map { $_ => [ @{ $df->{$_} }[@keep] ] } keys %$df };
		}
		my @cols = @$sel;
		return { map { $_ => [ @{ $df->{$_} } ] } keys %$df } unless @cols;
		for my $c (@cols) {
			die "dropna: column '$c' not found\n" unless exists $df->{$c};
		}
		my @keep;
		for my $i (0 .. $n - 1) {
			my $nundef = grep { !defined $df->{$_}[$i] } @cols;
			my $drop = $how eq 'any' ? $nundef > 0 : $nundef == @cols;
			push @keep, $i unless $drop;
		}
		return { map { $_ => [ @{ $df->{$_} }[@keep] ] } keys %$df };
	}

	die "dropna: data frame must be an arrayref (AoH) or hashref (HoA/HoH)\n";
}

# drop_duplicates($df, subset => $col | \@cols, keep => 'first' | 'last' | 0)
#
# Remove duplicate rows, loosely modeled on pandas' DataFrame.drop_duplicates.
# Works on the three positional/columnar shapes -- AoA, AoH, HoA -- but NOT
# HoH (its rows are labeled, so "drop_duplicates" has no natural meaning; call
# hoh2aoh/hoh2hoa first).  Two rows are duplicates when their cells are equal
# in every subset column; comparison is by stringified value with a distinct
# undef (NA), exactly the key semantics merge() uses, so 1 and "1.0" differ.
#
#   subset  scalar or arrayref of the columns that define a row's identity;
#           default every column.  For AoA these are 0-based integer positions
#           (default 0 .. widest-row-1); for AoH/HoA they are column names
#           (AoH default: the sorted union of row keys; HoA: the sorted keys).
#   keep    which occurrence to keep: 'first' (default) keeps the earliest,
#           'last' the latest, 0 (or 'none') drops every row that has a dup.
#
# Row order is preserved (first-seen positions for the survivors).  Returns a
# NEW top-level frame of the same family; the original is never modified.  What
# survives is shared, not deep-copied: AoA/AoH reuse the surviving row refs,
# HoA builds new column arrays over the same cell SVs.  Assigning through a
# survivor therefore reaches the input's cell.
sub drop_duplicates {
	my $df = shift;
	die "drop_duplicates: undefined data in first position\n" unless defined $df;
	die "drop_duplicates: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( subset => 1, keep => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "drop_duplicates: unknown argument(s): @bad\n" if @bad;

	my $shape = _df_shape($df, 'drop_duplicates');
	die "drop_duplicates: an HoH data frame is not supported (convert to AoH/HoA/AoA first)\n"
		if $shape eq 'HoH';

	# keep -> code: 1 = first, -1 = last, 0 = drop every duplicate
	my $keep = exists $arg{keep} ? $arg{keep} : 'first';
	die "drop_duplicates: 'keep' is undefined (use 'first', 'last', or 0)\n"
		unless defined $keep;
	my $kc;
	if    ($keep eq 'first') { $kc =  1 }
	elsif ($keep eq 'last')  { $kc = -1 }
	elsif ($keep eq 'none' || $keep eq '' || (looks_like_number($keep) && $keep == 0)) { $kc = 0 }
	else  { die "drop_duplicates: 'keep' must be 'first', 'last', or 0 (got '$keep')\n" }

	# subset -> ordered column list
	my @sub;
	if (exists $arg{subset} && defined $arg{subset}) {
		my $s = $arg{subset};
		if    (ref $s eq 'ARRAY') { @sub = @$s }
		elsif (!ref $s)           { @sub = ($s) }
		else { die "drop_duplicates: 'subset' must be a column or an arrayref of columns\n" }
		die "drop_duplicates: 'subset' is empty\n" unless @sub;
		my %seen;
		for my $c (@sub) {
			die "drop_duplicates: undefined column in 'subset'\n" unless defined $c;
			die "drop_duplicates: duplicate column '$c' in 'subset'\n" if $seen{$c}++;
		}
	}

	if ($shape eq 'AoA') {
		if (@sub) { _aoa_int_cols('drop_duplicates', $df, @sub) }
		else      { @sub = (0 .. _aoa_width($df) - 1) }
		return _drop_dups_core($df, 3, [ @sub ], $kc);
	}
	if ($shape eq 'AoH') {
		# same union _present_keys builds, but scanned in C: on a large AoH the
		# pure-Perl walk over every key of every row cost more than the dedup
		my %present = map { $_ => 1 } @{ _aoh_key_union($df) };
		if (@sub) {
			for my $c (@sub) {
				die "drop_duplicates: column '$c' not found\n" unless $present{$c};
			}
		} else {
			@sub = sort keys %present;
		}
		return _drop_dups_core($df, 1, [ @sub ], $kc);
	}
	# HoA
	if (@sub) {
		for my $c (@sub) {
			die "drop_duplicates: column '$c' not found\n" unless exists $df->{$c};
		}
	} else {
		@sub = sort keys %$df;
	}
	return _drop_dups_core($df, 4, [ @sub ], $kc);
}
# Count rows across Stats::LikeR frame forms: AoH, AoA, HoA, HoH.

# Count columns across Stats::LikeR frame forms: AoH, AoA, HoA, HoH
# (plain vector => 1 column). Uses die, not croak. reftype => blessed frames ok.
sub ncol {
	my ($data) = @_;
	my $type = reftype $data;
	die 'ncol: expected an ARRAY or HASH ref (got '
		. (defined $data ? (ref($data) || 'non-ref scalar') : 'undef') . ")\n"
		unless defined $type && ($type eq 'ARRAY' || $type eq 'HASH');

	if ($type eq 'ARRAY') {
		return 0 unless @$data;                     # empty frame
		my $r0 = reftype $data->[0];                # element 0 decides the form

		# AoH: columns = keys per row; every row a hash ref of equal key count
		if (defined $r0 && $r0 eq 'HASH') {
			my $ncol = scalar keys %{ $data->[0] };
			for my $i (1 .. $#$data) {
				my $row = $data->[$i];
				die "ncol: AoH row $i is not a hash ref\n"
					unless defined(reftype $row) && reftype($row) eq 'HASH';
				my $k = scalar keys %$row;
				die "ncol: ragged AoH — row $i has $k columns, but row 0 has $ncol\n"
					if $k != $ncol;
			}
			return $ncol;
		}

		# AoA: columns = row length; every row an array ref of equal length
		if (defined $r0 && $r0 eq 'ARRAY') {
			my $ncol = scalar @{ $data->[0] };
			for my $i (1 .. $#$data) {
				my $row = $data->[$i];
				die "ncol: AoA row $i is not an array ref\n"
					unless defined(reftype $row) && reftype($row) eq 'ARRAY';
				my $len = scalar @$row;
				die "ncol: ragged AoA — row $i has $len columns, but row 0 has $ncol\n"
					if $len != $ncol;
			}
			return $ncol;
		}

		return 1 unless defined $r0;                # plain 1-D vector: one column

		die "ncol: array element 0 is a $r0 ref; expected HASH (AoH), ARRAY (AoA), or plain scalars (vector)\n";
	}

	# HASH: HoA (keys are columns) or HoH (keys are rows)
	return 0 unless %$data;

	my $probe;                                      # first defined value decides the form
	foreach my $k (keys %$data) {
		next unless defined $data->{$k};
		$probe = $data->{$k};
		last;
	}
	my $vtype = reftype $probe;

	# HoA: keys ARE the columns. Validate values are array refs so a malformed
	# frame dies deterministically rather than depending on which key `probe` hit.
	if (defined $vtype && $vtype eq 'ARRAY') {
		foreach my $col (keys %$data) {
			die "ncol: HoA column '$col' is not an array ref\n"
				unless defined(reftype $data->{$col}) && reftype($data->{$col}) eq 'ARRAY';
		}
		return scalar keys %$data;
	}

	# HoH: keys are rows; columns = keys of a row hash, consistent across rows
	if (defined $vtype && $vtype eq 'HASH') {
		my ($ncol, $ref_row);
		foreach my $row_key (keys %$data) {
			my $row = $data->{$row_key};
			die "ncol: HoH row '$row_key' is not a hash ref\n"
				unless defined(reftype $row) && reftype($row) eq 'HASH';
			my $k = scalar keys %$row;
			if (not defined $ncol) { $ncol = $k; $ref_row = $row_key }
			elsif ($k != $ncol) {
				die "ncol: ragged HoH — row '$row_key' has $k columns, but '$ref_row' has $ncol\n";
			}
		}
		return $ncol;
	}

	die "ncol: HASH values are neither ARRAY refs (HoA) nor HASH refs (HoH)\n";
}

sub nrow {
	my ($data) = @_;
	my $type = reftype $data;
	die 'nrow: expected an ARRAY or HASH ref (got '
		. (defined $data ? (ref($data) || 'non-ref scalar') : 'undef') . ')'
		unless defined $type;

	# AoH / AoA (and a plain vector): one top-level element per row.
	return scalar @$data if $type eq 'ARRAY';

	# HASH: HoA (keys are columns) or HoH (keys are rows).
	return 0 unless %$data;                     # empty frame, either form

	my $probe;                                  # first defined value decides the form
	foreach my $k (keys %$data) {
		next unless defined $data->{$k};
		$probe = $data->{$k};
		last;
	}
	my $vtype = reftype $probe;

	return scalar keys %$data                   # HoH: one key per row
		if defined $vtype && $vtype eq 'HASH';

	if (defined $vtype && $vtype eq 'ARRAY') {  # HoA: rows = common column length
		my ($n, $ref_col);
		foreach my $col (keys %$data) {         # verify columns agree, so a ragged
			my $vec = $data->{$col};            # frame can't return a silently-wrong
			die "nrow: HoA column '$col' is not an array ref"  # (and, given hash
				unless defined(reftype $vec) && reftype($vec) eq 'ARRAY'; # ordering,
			my $len = scalar @$vec;             # nondeterministic) count
			if (not defined $n) { $n = $len; $ref_col = $col }
			elsif ($len != $n) {
				die "nrow: ragged HoA — column '$col' has $len rows, but '$ref_col' has $n";
			}
		}
		return $n;
	}
	die 'nrow: HASH values are neither ARRAY refs (HoA) nor HASH refs (HoH)';
}
sub qcut {
	my ($data, $q, %opt) = @_;

	die "qcut: first argument must be an ARRAY reference (try h('qcut'))\n"
		unless ref $data eq 'ARRAY';

	# probability vector: q+1 evenly spaced points, or an explicit list
	my $probs;
	if (ref $q eq 'ARRAY') {
		$probs = [ sort { $a <=> $b } @$q ];
	} else {
		die "qcut: number of quantiles must be a positive integer\n"
			unless defined $q && $q =~ /\A[1-9][0-9]*\z/;
		$probs = [ map { $_ / $q } 0 .. $q ];
	}

	my $drop   = (($opt{duplicates} // 'raise') eq 'drop') ? 1 : 0;
	my $labels = $opt{labels};

	# codes are opt-in (labels imply them); edges are on unless codes asked for
	my $want_codes = ($opt{codes} || defined $labels) ? 1 : 0;
	my $want_edges = exists $opt{edges}
		? ($opt{edges} ? 1 : 0)
		: ($want_codes ? 0 : 1);
	die "qcut: nothing to return (set edges => 1 or codes => 1)\n"
		unless $want_edges || $want_codes;

	# does the column contain any NA?
	my $has_na = 0;
	for my $x (@$data) { if (!defined $x) { $has_na = 1; last } }

	my ($codes, $edges, @pos);
	if ($want_codes && $has_na) {
		# strip NA, remember positions, scatter codes back afterwards
		my @vals;
		for my $i (0 .. $#$data) {
			next unless defined $data->[$i];
			push @vals, $data->[$i] + 0;
			push @pos,  $i;
		}
		die "qcut: no non-missing values\n" unless @vals;
		($codes, $edges) = _qcut_core(\@vals, $probs, $drop, 1);
	} elsif ($has_na) {
		# edges only: drop NA so cutpoints ignore them, positions don't matter
		my @vals = grep { defined } @$data;
		die "qcut: no non-missing values\n" unless @vals;
		($codes, $edges) = _qcut_core(\@vals, $probs, $drop, 0);
	} else {
		# no NA: hand the original arrayref straight to XS (no copy)
		($codes, $edges) = _qcut_core($data, $probs, $drop, $want_codes);
	}

	# edges-only: return the flat list
	return @$edges unless $want_codes;

	# turn integer codes into requested labels, or keep the XS arrayref as-is
	my $out;
	if (defined $labels && ref $labels eq 'ARRAY') {
		my $nbin = scalar(@$edges) - 1;
		die "qcut: got $nbin bins but " . scalar(@$labels) . " labels\n"
			unless @$labels == $nbin;
		$out = [ map { $labels->[$_] } @$codes ];
	} elsif (defined $labels && $labels eq 'interval') {
		my @iv;
		for my $b (0 .. $#$edges - 1) {
			my $l = $edges->[$b];
			my $r = $edges->[$b + 1];
			$iv[$b] = $b == 0 ? "[$l, $r]" : "($l, $r]";
		}
		$out = [ map { $iv[$_] } @$codes ];
	} else {
		$out = $codes;			# reuse XS result; no copy
	}

	# scatter NA positions back in (codes path only)
	if ($has_na) {
		my @r = (undef) x scalar(@$data);
		@r[@pos] = @$out;
		$out = \@r;
	}

	return $want_edges ? ($out, $edges) : $out;
}

# summary($data, %opts) -- R-style five-number-plus-mean summary.
#
# Accepts every shape view() does and computes one statistics row per numeric
# "variable": a flat vector (one row); an AoA (one row per inner array, labelled
# by Index); a HoA (one row per key); and -- like view() -- an AoH or HoH (one
# row per column, gathered across the rows). Non-numeric and undefined cells are
# ignored (they never count toward '# values'); an all-non-numeric variable
# shows 0 values and 'na' statistics. Output, colour, and the display options
# are rendered exactly like view() via the shared _render_grid().
sub summary {
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	# options view() understands, plus the row-cap synonyms
	my %opt_key = map { $_ => 1 } qw(
		nrows nrow n rows
		na color colors max_width ellipsis gap width to return_only
	);
	my ($data, %args);
	if (@_ && ref $_[0]) {
		# summary(\@arr, ...) / summary(\%h, ...)
		$data = shift;
		%args = @_;
	} else {
		# summary(@vector) / summary(@vector, nrows => N): peel recognised
		# trailing key/value option pairs off the flat list; the rest is data.
		while (@_ >= 2 && defined $_[-2] && !ref($_[-2]) && $opt_key{ $_[-2] }) {
			my $val = pop @_;
			my $key = pop @_;
			$args{$key} = $val;
		}
		my @list = @_;
		$data = \@list;
	}
	my @bad = sort grep { !$opt_key{$_} } keys %args;
	die "$current_sub: unknown argument(s): @bad\n" if @bad;
	# row cap: nrows / nrow / n / rows are synonyms (default 10)
	my $nrows = exists $args{nrows} ? $args{nrows} : exists $args{nrow} ? $args{nrow}
			  : exists $args{n}     ? $args{n}     : exists $args{rows} ? $args{rows}
			  :                       10;
	die "$current_sub: 'nrows' must be a non-negative integer\n"
		unless defined $nrows && $nrows =~ /^\d+$/;

	my $rt = ref $data;
	die "$current_sub: data must either be a hash or an array, not \"$rt\"\n"
		unless $rt eq 'ARRAY' or $rt eq 'HASH';

	# --- resolve the data shape into (label, numeric-vector) series ---
	my (@labels, @vecs, $lab_header);
	if ($rt eq 'ARRAY') {
		my $first;
		for my $e (@$data) { if (defined $e) { $first = $e; last } }
		my $ft = ref $first;
		if ($ft eq 'HASH') {			# AoH: one series per column
			$lab_header = 'Column';
			my %seen;
			for my $row (@$data) { next unless ref $row eq 'HASH'; $seen{$_} = 1 for keys %$row }
			for my $col (sort keys %seen) {
				push @labels, $col;
				push @vecs, [ map { ref $_ eq 'HASH' ? $_->{$col} : undef } @$data ];
			}
		} elsif ($ft eq 'ARRAY') {		# AoA: one series per inner array
			$lab_header = 'Index';
			for my $i (0 .. $#$data) {
				push @labels, $i;
				push @vecs, (ref $data->[$i] eq 'ARRAY' ? [ @{ $data->[$i] } ] : []);
			}
		} else {						# flat vector: a single series
			$lab_header = '';
			push @labels, '';
			push @vecs, [ @$data ];
		}
	} else { # HASH
		my @keys = keys %$data;
		my $sample;
		for my $k (@keys) { $sample = $data->{$k}; last if defined $sample }
		my $vt = ref $sample;
		if ($vt eq 'ARRAY') {			# HoA: one series per key
			$lab_header = 'Key';
			for my $k (sort { lc $a cmp lc $b } @keys) {
				push @labels, $k;
				push @vecs, (ref $data->{$k} eq 'ARRAY' ? [ @{ $data->{$k} } ] : []);
			}
		} elsif ($vt eq 'HASH') {		# HoH: one series per column (inner key)
			$lab_header = 'Column';
			my %seen;
			for my $k (@keys) { next unless ref $data->{$k} eq 'HASH'; $seen{$_} = 1 for keys %{ $data->{$k} } }
			for my $col (sort keys %seen) {
				push @labels, $col;
				push @vecs, [ map { ref $data->{$_} eq 'HASH' ? $data->{$_}{$col} : undef } @keys ];
			}
		} else {						# flat hash: its values as one series
			$lab_header = '';
			push @labels, '';
			push @vecs, [ map { $data->{$_} } @keys ];
		}
	}

	# --- compute the statistics grid ---
	my @colnames = ('# values', 'Min.', '1st Qu.', 'Median', 'Mean', '3rd Qu.', 'Max.');
	my @raw;
	for my $vec (@vecs) {
		my @numeric = grep { defined $_ && looks_like_number($_) } @$vec;
		if (!@numeric) { push @raw, [ 0, (undef) x 6 ]; next }	# empty -> na stats
		my $q = quantile(\@numeric, probs => [0.25, 0.75]);
		# format as %.4g strings; they still look numeric, so _render_grid
		# right-aligns and colours them as numbers.
		push @raw, [
			scalar @numeric,
			sprintf('%.4g', min(\@numeric)),    sprintf('%.4g', $q->{'25%'}),
			sprintf('%.4g', median(\@numeric)), sprintf('%.4g', mean(\@numeric)),
			sprintf('%.4g', $q->{'75%'}),       sprintf('%.4g', max(\@numeric)),
		];
	}

	# cap the number of series shown (keep the true total for the "... more" note)
	my $total = scalar @labels;
	if ($nrows < $total) { $#labels = $nrows - 1; $#raw = $nrows - 1; }

	return _render_grid(
		kind => 'summary', total => $total,
		cols => \@colnames, labels => \@labels, raw => \@raw, lab_header => $lab_header,
		na          => $args{na},
		max_width   => $args{max_width},
		ellipsis    => $args{ellipsis},
		gap         => (exists $args{gap} ? ' ' x $args{gap} : undef),
		width       => $args{width},
		to          => $args{to},
		return_only => $args{return_only},
		color       => (exists $args{color} ? $args{color} : undef),
		colors      => $args{colors},
	);
}

# --- .xlsx support (pure Perl, no CPAN deps) -------------------------------
# An .xlsx file is a ZIP archive of XML parts. IO::Uncompress::Unzip is a core
# module, so we can pull the parts out and parse the (very regular) XML with
# regexes, then feed rows to read_table's callback exactly like _parse_csv_file
# does. A workbook with more than one worksheet is read into a hash keyed by
# sheet name (see read_table). Limitations: dates/times come back as their raw
# serial numbers (no style-based formatting); shared-string rich-text runs are
# concatenated.

# Return the decompressed bytes of a named archive member, or undef if absent.
sub _unzip_member {
	my ($file, $member) = @_;
	require IO::Uncompress::Unzip;
	my $z = IO::Uncompress::Unzip->new($file, Name => $member)
		or return undef;
	my $content = '';
	my $buf;
	while ((my $n = $z->read($buf)) > 0) { $content .= $buf }
	$z->close;
	return $content;
}

# Decode the five predefined XML entities plus numeric character references.
# Numeric refs are re-encoded to UTF-8 bytes so the result stays byte-consistent
# with the rest of the file (which we read, and return, as raw UTF-8 bytes).
sub _xml_unescape {
	my ($s) = @_;
	return $s unless defined $s && index($s, '&') >= 0;
	$s =~ s/&#x([0-9a-fA-F]+);/my $c = chr hex $1; utf8::encode($c); $c/ge;
	$s =~ s/&#([0-9]+);/my $c = chr $1; utf8::encode($c); $c/ge;
	$s =~ s/&lt;/</g;
	$s =~ s/&gt;/>/g;
	$s =~ s/&quot;/"/g;
	$s =~ s/&apos;/'/g;
	$s =~ s/&amp;/&/g;	# must be last so "&amp;lt;" -> "&lt;", not "<"
	return $s;
}

# "AB12" (or "AB") -> 0-based column index (A=0, Z=25, AA=26, ...).
# Hot path (called once per cell): walk the leading letters by ordinal and stop
# at the first non-letter (the row number), avoiding a regex substitution and a
# split // on every call.
sub _xlsx_col_idx {
	my ($ref) = @_;
	my $idx = 0;
	for my $i (0 .. length($ref) - 1) {
		my $o = ord(substr($ref, $i, 1));
		if    ($o >= 65 && $o <=  90) { $idx = $idx * 26 + ($o - 64) }	# A-Z
		elsif ($o >= 97 && $o <= 122) { $idx = $idx * 26 + ($o - 96) }	# a-z
		else  { last }							# reached the digits
	}
	return $idx - 1;
}

# Shared strings (optional part): each <si> may hold several <t> runs, which
# are concatenated. Returns an arrayref indexed by shared-string id.
sub _xlsx_shared_strings {
	my ($file) = @_;
	my @sst;
	if (defined(my $ss = _unzip_member($file, 'xl/sharedStrings.xml'))) {
		while ($ss =~ m{<si\b[^>]*>(.*?)</si>}gs) {
			my $si  = $1;
			my $str = '';
			$str .= _xml_unescape($1) while $si =~ m{<t\b[^>]*>(.*?)</t>}gs;
			push @sst, $str;
		}
	}
	return \@sst;
}

# The workbook's worksheets, in document order, as a list of
# { name => $sheet_name, path => 'xl/worksheets/sheetN.xml' } hashrefs. The path
# is resolved through workbook.xml.rels; a sheet with no resolvable relationship
# (or a workbook with no metadata at all) falls back to a positional sheetN.xml.
sub _xlsx_sheets {
	my ($file) = @_;
	my %target;
	if (defined(my $rels = _unzip_member($file, 'xl/_rels/workbook.xml.rels'))) {
		while ($rels =~ m{<Relationship\b([^>]*?)/?>}gs) {
			my $a = $1;
			my ($id) = $a =~ /\bId="([^"]*)"/;
			my ($tg) = $a =~ /\bTarget="([^"]*)"/;
			$target{$id} = $tg if defined $id && defined $tg;
		}
	}
	my @sheets;
	if (defined(my $wb = _unzip_member($file, 'xl/workbook.xml'))) {
		while ($wb =~ m{<sheet\b([^>]*?)/?>}gs) {
			my $a = $1;
			my ($name) = $a =~ /\bname="([^"]*)"/;
			my ($rid)  = $a =~ /\br:id="([^"]*)"/;
			my $path;
			if (defined $rid && defined $target{$rid}) {
				(my $tg = $target{$rid}) =~ s{^/}{};	# strip absolute-package "/"
				$path = $tg =~ m{^xl/} ? $tg : "xl/$tg";	# else relative to xl/
			}
			push @sheets, {
				name => defined $name ? _xml_unescape($name) : undef,
				path => $path,
			};
		}
	}
	@sheets = ({ name => undef, path => undef }) unless @sheets;	# no metadata
	# any sheet still lacking a path falls back to its positional worksheet file
	$sheets[$_]{path} //= 'xl/worksheets/sheet' . ($_ + 1) . '.xml'
		for 0 .. $#sheets;
	return \@sheets;
}

# Resolve a 'sheet' argument (undef -> first; a 1-based index; or a name) to one
# of the hashrefs from _xlsx_sheets, dying with a clear message on a bad request.
sub _xlsx_choose_sheet {
	my ($file, $sheets, $sheet) = @_;
	return $sheets->[0] unless defined $sheet;
	if ($sheet =~ /^\d+\z/) {
		die "read_table: sheet index $sheet is out of range (1..${\ scalar @$sheets}) in $file\n"
			if $sheet < 1 || $sheet > @$sheets;
		return $sheets->[$sheet - 1];
	}
	my ($chosen) = grep { defined $_->{name} && $_->{name} eq $sheet } @$sheets;
	die "read_table: sheet '$sheet' not found in $file (have: "
		. join(', ', map { defined $_->{name} ? "'$_->{name}'" : '?' } @$sheets)
		. ")\n"
		unless $chosen;
	return $chosen;
}

# Parse one worksheet, invoking $callback->(\@fields) once per non-empty row
# (header row included) with all rows padded to the same width -- the same
# contract _parse_csv_file offers read_table's callback. $sst is the shared
# strings arrayref from _xlsx_shared_strings.
sub _parse_xlsx_sheet {
	my ($file, $sst, $path, $callback) = @_;
	my $ws = _unzip_member($file, $path);
	die "read_table: could not read worksheet '$path' in $file\n"
		unless defined $ws;

	# collect cells, positioning each by its column reference so gaps stay
	# aligned, then pad every row to the widest row seen.
	my @rows;
	my $global_max = -1;
	while ($ws =~ m{<row\b[^>]*>(.*?)</row>}gs) {
		my $rowxml = $1;
		my @cells;
		my $maxc = -1;
		# The r="A1" reference is almost always the first attribute, so the
		# tokenizer captures its column letters ($1) directly -- computing the
		# index from a group the match already produced is the single biggest
		# win in this loop. If the capture misses (r= absent, not first, or a
		# non-standard lowercase ref), $cattrs still holds the full attributes
		# and we parse r= from there; only then do we fall back to sequential.
		while ($rowxml =~ m{<c(?:\s+r="([A-Z]+)\d+")?([^>]*?)(?:/>|>(.*?)</c>)}gs) {
			my ($ref, $cattrs, $cbody) = ($1, $2, $3);
			my $ci;
			if (defined $ref) {
				$ci = 0;
				$ci = $ci * 26 + (ord(substr($ref, $_, 1)) - 64)
					for 0 .. length($ref) - 1;
				$ci--;
			} elsif ($cattrs =~ /\br="([A-Za-z]+)/) {
				$ci = _xlsx_col_idx($1);
			} else {
				$ci = $maxc + 1;
			}
			# Cell type: a plain substring test on the (short) attribute run is
			# markedly cheaper than a capturing /\bt="..."/ match run once per
			# cell. Only "s" and "inlineStr" denote strings; every other type
			# value (str/b/e/n) and a missing t= take the raw <v> path, exactly
			# as the previous /\bt="..."/ dispatch did. Cell-element attribute
			# names are a fixed set (r,s,t,cm,vm,ph) whose other values are
			# numeric refs, so 't="s"' / 't="inlineStr"' can only ever appear as
			# the genuine type attribute -- no false substring match is possible.
			my $val = '';
			if (defined $cbody) {
				if (index($cattrs, 't="s"') >= 0) {		# shared-string index
					# Almost every string cell body is exactly <v>DIGITS</v>; an
					# anchored match reads it in one step, falling back to the
					# general <v ...> scan only for the rare attributed <v>.
					my $v = ($cbody =~ m{\A<v>([^<]*)</v>\z})
						? $1 : ($cbody =~ m{<v\b[^>]*>(.*?)</v>}s)[0];
					$val = (defined $v && $v =~ /^\d+\z/) ? ($sst->[$v] // '') : '';
				} elsif (index($cattrs, 't="inlineStr"') >= 0) {
					$val .= _xml_unescape($1) while $cbody =~ m{<t\b[^>]*>(.*?)</t>}gs;
				} else {			# number / formula str / bool / error
					my $v = ($cbody =~ m{\A<v>([^<]*)</v>\z})
						? $1 : ($cbody =~ m{<v\b[^>]*>(.*?)</v>}s)[0];
					$val = defined $v ? _xml_unescape($v) : '';
				}
			}
			$cells[$ci] = $val;
			$maxc = $ci if $ci > $maxc;
		}
		push @rows, \@cells;
		$global_max = $maxc if $maxc > $global_max;
	}
	undef $ws;	# free the (potentially large) worksheet XML before emitting

	# Emit each row padded to the widest row seen, consuming @rows as we go
	# (shift, not foreach) so the parsed AoA and the caller's growing structure
	# never both sit fully in memory at once. Pad and fill holes in place -- the
	# callback reads by index and never retains the ref -- so this is a light
	# touch, not a second full copy.
	while (my $cells = shift @rows) {
		$#$cells = $global_max;			# extend to the common width
		$_ //= '' for @$cells;			# fill gaps + padding in place
		next unless grep { length } @$cells;	# skip fully blank rows, as CSV does
		$callback->($cells);
	}
	return;
}

sub read_table {
	my $file = shift;
	die "read_table: \"$file\" is not a file\n"   unless -f $file;
	die "read_table: \"$file\" is not readable\n" unless -r $file;

	my %input_args = @_;
	if (exists $input_args{delim}) {
		# FIX: sep + delim together used to silently prefer delim
		die "read_table: pass either 'sep' or 'delim', not both\n"
			if exists $input_args{sep};
		$input_args{sep} = delete $input_args{delim};
	}

	my $is_xlsx = $file =~ /\.xlsx\z/i;
	my $default_sep = $file =~ /\.tsv$/i ? "\t" : ',';
	my %args = (
		sep => $default_sep, comment => '#', %input_args,
	);

	my %allowed_args = map { $_ => 1 } (
		'comment', 'output.type', 'filter', 'row.names', 'sep',
		'auto.row.names', 'sheet',
		# private, undocumented: the multi-sheet expansion passes an already
		# parsed worksheet list / shared-string table to each per-sheet recursion
		# so a big sharedStrings.xml is not re-decompressed once per worksheet.
		'_xlsx_sheets', '_sst',
	);
	my @undef_args = sort grep { !$allowed_args{$_} } keys %args;
	if (@undef_args) {
		my $current_sub = ( split /::/, (caller(0))[3] )[-1];
		die "the args \"@undef_args\" aren't defined for $current_sub\n";
	}
	my $otype = $args{'output.type'} // 'aoh';
	die "read_table: output.type \"$otype\" isn't allowed (aoh, hoa, hoh)\n"
		unless $otype =~ m/^(?:aoh|hoa|hoh)$/;

	# A multi-worksheet .xlsx with no explicit 'sheet' is returned as a hash
	# keyed by worksheet name, each value being that sheet parsed with the same
	# options (recursing one sheet at a time keeps every table's state, and any
	# hoh row.names default, independent). A single-worksheet workbook, or an
	# explicit 'sheet', still returns that one table directly.
	# Resolve the worksheet list once and reuse it below (it decompresses and
	# parses workbook.xml + its rels, so recomputing it in the main xlsx branch
	# would double that work for every single-sheet / explicit-sheet read).
	my $xlsx_sheets;
	if ($is_xlsx) {
		# Reuse a caller-supplied worksheet list (from the multi-sheet expansion
		# below) rather than re-parsing workbook.xml + its rels for every sheet.
		$xlsx_sheets = $args{_xlsx_sheets} // _xlsx_sheets($file);
		if (!defined $args{sheet} && @$xlsx_sheets > 1) {
			# Decompress + parse the shared-string table once for the whole
			# workbook and hand it to each per-sheet read, instead of every
			# recursion re-reading (a potentially large) sharedStrings.xml.
			my $sst = _xlsx_shared_strings($file);
			my %book;
			for my $i (0 .. $#$xlsx_sheets) {
				my $name = $xlsx_sheets->[$i]{name};
				$name = 'Sheet' . ($i + 1) unless defined $name;
				$book{$name} = read_table($file, %input_args,
					sheet        => $i + 1,
					_xlsx_sheets => $xlsx_sheets,
					_sst         => $sst);
			}
			return \%book;
		}
	}

# R's write.table(col.names=TRUE) default omits the header label for the
# row-names column, so a header comes out one field short of every data
# row. With 'auto.row.names' set, mirror read.table's rule: when (and only
# when) the header is exactly one field short, treat the first data field
# as an (otherwise unlabelled) row-names column. Any truthy value enables
# it; a non-1 string is used as the synthesized column name.
	my $want_auto_rn = $args{'auto.row.names'} ? 1 : 0;
	my $auto_rn_name =
		($want_auto_rn && "$args{'auto.row.names'}" ne '1')
			? $args{'auto.row.names'} : 'row_name';

	my $filter = $args{filter};
	if (defined $filter && ref($filter) eq 'CODE') {
		$filter = { 0 => $filter };
	} elsif (defined $filter && ref($filter) ne 'HASH') {
		die "'filter' must be a CODE or HASH reference\n";
	}

	my (@data, %data, @header, @uniq_header,
	    %mapped_filters, @sorted_filter_flds, %seen_rownames);
	my ($data_row, $header_seen, $header_done, $provisional_hdr) = (0, 0, 0, 0);

	# Everything that depends on the (possibly augmented) @header lives here so
	# it can run either right after the header line (strict mode) or deferred
	# to the first data row (auto.row.names mode, once the width is known).
	my $finalize_header = sub {
		if (@header && $header[0] eq '') {
			$header[0] = 'row_name';
		}
		my %seen_h;
		@uniq_header = grep { !$seen_h{$_}++ } @header;
		my @dup_cols = grep { $seen_h{$_} > 1 } @uniq_header;
		warn "read_table: duplicate column name(s) in $file: @dup_cols (later values win)\n"
			if @dup_cols;
		if ($otype eq 'hoh' && !defined $args{'row.names'}) {
			$args{'row.names'} = $header[0];
		}
		if (defined $args{'row.names'}
				&& !grep { $_ eq $args{'row.names'} } @header) {
			die "\"$args{'row.names'}\" isn't in the header of $file\n";
		}
		if ($filter) {
			%mapped_filters = ();
			for my $k (keys %$filter) {
				if ($k =~ /^\d+$/) {
					die "read_table: numeric filter key $k exceeds the "
					  . scalar(@header) . " columns of $file\n"
						if $k > @header;
					$mapped_filters{$k} = $filter->{$k};
				} else {
					my ($idx) = grep { $header[$_] eq $k } 0 .. $#header;
					if (!defined $idx && length( $args{comment} // '' )) {
						# A commented-out header has its marker (and any
						# following whitespace) stripped from the first
						# column, so a key written as it appears in the file
						# (e.g. "# PDB") won't match the clean name ("PDB").
						# Normalize the key the same way and retry.
						(my $nk = $k) =~ s/^\s*\Q$args{comment}\E\s*//;
						($idx) = grep { $header[$_] eq $nk } 0 .. $#header;
					}
					unless (defined $idx) {
						die "read_table: Filter column '$k' not found in the "
						  . "header of $file; header is: "
						  . join( ', ', map { "'$_'" } @header ) . "\n";
					}
					$mapped_filters{ $idx + 1 } = $filter->{$k};
				}
			}
			@sorted_filter_flds = sort { $a <=> $b } keys %mapped_filters;
		}
	};

	# _parse_csv_file() treats a line whose comment marker is followed by
	# whitespace (e.g. "# PDB\tscore") as a comment and drops it, so a header
	# written that way never reaches the callback and the first data row would
	# be mistaken for the header. Recover it: read the first physical line, and
	# if it is marker + whitespace and splits into >=2 fields, hold it as a
	# CANDIDATE header. It is confirmed (in the callback) only if its field
	# count matches the first data row; otherwise it was an ordinary leading
	# comment and is discarded. A marker hugging its text ("#id,val") is
	# delivered by the parser and un-commented in the callback as usual, so it
	# never reaches this branch.
	if (!$is_xlsx && length( $args{comment} // '' ) && length( $args{sep} // '' )) {
		open my $fh, '<', $file
			or die "read_table: can't open $file: $!\n";
		my $first = <$fh>;
		close $fh;
		if (defined $first && $first =~ /^\Q$args{comment}\E\s/) {
			$first =~ s/\r?\n\z//;
			my @cols = split /\Q$args{sep}\E/, $first, -1;
			if (@cols >= 2) {
				$cols[0] =~ s/^\Q$args{comment}\E\s*//;
				@header          = @cols;
				$header_seen     = 1;
				$provisional_hdr = 1;	# confirm against the first data row
			}
		}
	}

	my $on_line = sub {
		my ($line_ref) = @_;

		if (!$header_seen) {
			# --- HEADER CAPTURE (copy made only here; runs once) ---
			my @line = @$line_ref;
			$line[0] =~ s/^\Q$args{comment}\E\s*//
				if @line && defined $line[0] && length( $args{comment} // '' );
			@header      = @line;
			$header_seen = 1;
			unless ($want_auto_rn) {	# strict: finalize immediately
				$finalize_header->();
				$header_done = 1;
			}
			return;
		}

		if (!$header_done) {
			# Confirm or reject a provisionally-captured commented-out header:
			# it is a real header only if its field count matches the first
			# data row. If not, the candidate was an ordinary leading comment;
			# discard it and treat THIS delivered line as the header instead.
			if ($provisional_hdr) {
				$provisional_hdr = 0;
				if (@$line_ref != @header) {
					@header = @$line_ref;
					$header[0] =~ s/^\Q$args{comment}\E\s*//
						if @header && defined $header[0]
						&& length( $args{comment} // '' );
					unless ($want_auto_rn) {
						$finalize_header->();
						$header_done = 1;
					}
					return;	# this line WAS the header, not data
				}
				# widths match: accept the commented header, and let the
				# auto.row.names / finalize logic below run on THIS data row.
			}

# First data row in auto.row.names mode: now the data width is
# known, so decide whether the file carries an unlabelled leading
# row-names column (header exactly one field short).
			if ($want_auto_rn && @$line_ref == @header + 1) {
				unshift @header, $auto_rn_name;
			}
			$finalize_header->();
			$header_done = 1;
			# fall through and process THIS line as data
		}

# --- DATA PROCESSING (operate on $line_ref directly; no row copy)
		$data_row++;
		if (@$line_ref != @header) {
			# FIX: alignment errors now say WHICH row is ragged
			die sprintf "Alignment error on %s data row %d (%d fields vs %d headers).\n",
				$file, $data_row, scalar @$line_ref, scalar @header;
		}
		my %line_hash;
		for my $i (0 .. $#header) {
			my $v = $line_ref->[$i];
			$line_hash{ $header[$i] } = ( !defined($v) || $v eq '' ) ? undef : $v;
		}
# --- APPLY FILTERS ---
		if (@sorted_filter_flds) {
			local *_ = \%line_hash;
			my $skip = 0;
			foreach my $fld (@sorted_filter_flds) {
				local $_ = $fld == 0 ? $line_ref : $line_hash{ $header[ $fld - 1 ] };
				if ( !$mapped_filters{$fld}->( $line_ref, \%line_hash ) ) {
					$skip = 1;
					last;
				}
				if ( $fld > 0 ) {	# write back any mutation made to $_
					$line_ref->[ $fld - 1 ] = $_;
					$line_hash{ $header[ $fld - 1 ] }
						= ( !defined($_) || $_ eq '' ) ? undef : $_;
				}
			}
			return if $skip;
		}
# Populate requested data structure
		if ($otype eq 'aoh') {
			push @data, \%line_hash;
		} elsif ($otype eq 'hoa') {
			push @{ $data{$_} }, $line_hash{$_} for @uniq_header;
		} elsif ($otype eq 'hoh') {
			my $row_name = $line_hash{ $args{'row.names'} };
			die sprintf "read_table: undefined row name (column '%s') in %s data row %d\n",
				$args{'row.names'}, $file, $data_row
				unless defined $row_name;
			warn "read_table: duplicate row name '$row_name' in $file (later values win)\n"
				if $seen_rownames{$row_name}++;
			foreach my $col (@uniq_header) {
				next if $col eq $args{'row.names'};
				$data{$row_name}{$col} = $line_hash{$col};
			}
		}
	};
	if ($is_xlsx) {
		my $sst    = $args{_sst} // _xlsx_shared_strings($file);
		my $chosen = _xlsx_choose_sheet($file, $xlsx_sheets, $args{sheet});
		_parse_xlsx_sheet($file, $sst, $chosen->{path}, $on_line);
	} else {
		_parse_csv_file($file, $args{sep} // '', $args{comment} // '', $on_line);
	}
	# header-only files never hit a data row. A provisional (commented-out)
	# header was never confirmed against a data row, but with no data to
	# contradict it we accept it; either way still validate.
	$finalize_header->() if $header_seen && !$header_done;
	if ($otype eq 'aoh') {
		return \@data;
	} else { # hoa or hoh
		return \%data;
	}
}
# view($data, %opts) -- pretty-print an AoH / HoA / HoH / flat-hash table.
#
sub view {
	my $data = shift;
	if (not defined $data) {
		die 'view received undefined data';
	}
	my %args = @_;
	# --- reject unknown arguments (mirrors read_table/write_table) ---
	my %allowed = map { $_ => 1 } qw(
		n rows na max_width ellipsis gap cols columns width
		to return_only row.names row_names color colors
	);
	my @bad = sort grep { !$allowed{$_} } keys %args;
	die "view: unknown argument(s): @bad\n" if @bad;
	# --- n / rows (synonyms); reject conflicting or non-integer values ---
	die "view: pass either 'n' or 'rows', not both\n"
		if exists $args{n} && exists $args{rows};
	my $n = exists $args{rows} ? $args{rows}
		  : exists $args{n}    ? $args{n}
		  :                      6;
	die "view: 'n'/'rows' must be a non-negative integer\n"
		unless defined $n && $n =~ /^\d+$/;
	my $na    = exists $args{na}        ? $args{na}       : 'undef';
	my $maxw  = exists $args{max_width} ? $args{max_width} : 80;
	my $ell   = exists $args{ellipsis}  ? $args{ellipsis}  : '...';
	my $gap   = exists $args{gap}       ? (' ' x $args{gap}) : '  ';
	my $ucols = $args{cols} || $args{columns};
	my $fh    = $args{to};
	my $quiet = $args{return_only};
	# terminal width used to break wide tables into column chunks (R-style).
	# precedence: explicit 'width' arg -> $ENV{COLUMNS} -> 80 (R's default).
	my $tw = exists $args{width} ? $args{width}
		   : (defined $ENV{COLUMNS} && $ENV{COLUMNS} =~ /^[1-9][0-9]*\z/)
			 ? $ENV{COLUMNS}
			 : 80;
	die "view: 'width' must be a positive integer\n"
		unless defined $tw && $tw =~ /^[1-9][0-9]*\z/;
	# 'row.names' takes precedence over the row_names alias (both accepted)
	my $label_col = exists $args{'row.names'} ? $args{'row.names'}
				  : exists $args{row_names}   ? $args{row_names}
				  : undef;
	my $rt = ref $data;
	die "view: expected an ARRAY (AoH) or HASH (HoA/HoH) reference, got "
	  . ($rt || 'a non-reference') . "\n"
	  unless $rt eq 'ARRAY' or $rt eq 'HASH';
	my ($kind, @cols, @labels, @raw, $total, $lab_header);
	if ($rt eq 'ARRAY') {
		# distinguish AoA (rows are arrayrefs) from AoH (rows are hashrefs)
		# by the first defined element; an empty array stays the AoH path.
		my $first;
		for my $e (@$data) { if (defined $e) { $first = $e; last } }
		if (ref $first eq 'ARRAY') { # ---- AoA ----
			$kind  = 'AoA';
			$total = scalar @$data;
			my $show = $n < $total ? $n : $total;
			# column count from the shown rows (at least one row if any exist)
			my $scan = $show > 0 ? $show : ($total > 0 ? 1 : 0);
			my $m = 0;
			for my $i (0 .. $scan - 1) {
				my $row = $data->[$i];
				next unless ref $row eq 'ARRAY';
				$m = scalar @$row if scalar @$row > $m;
			}
			# 'cols'/'columns' selects & orders by 0-based column index
			my @idx = $ucols ? @$ucols : (0 .. $m - 1);
			# an integer 'row.names'/'row_names' names the label column index
			my $lc = (defined $label_col && $label_col =~ /^\d+$/ && $label_col < $m)
				   ? $label_col : undef;
			@idx = grep { $_ != $lc } @idx if defined $lc;
			@cols       = @idx;              # header = the 0-based array index
			$lab_header = defined $lc ? $lc : '';
			for my $i (0 .. $show - 1) {
				my $row = $data->[$i];
				$row = [] unless ref $row eq 'ARRAY';
				push @labels, defined $lc ? $row->[$lc] : $i;
				push @raw, [ map { $row->[$_] } @idx ];   # missing -> undef -> na
			}
		} else { # ---- AoH ----
			$kind  = 'AoH';
			$total = scalar @$data;
			my $show = $n < $total ? $n : $total;
			if ($ucols) {
				@cols = @$ucols;
			} else {
				my $scan = $show > 0 ? $show : ($total > 0 ? 1 : 0);
				my %seen;
				for my $i (0 .. $scan - 1) {
					my $row = $data->[$i];
					next unless ref $row eq 'HASH';
					$seen{$_} = 1 for keys %$row;
				}
				@cols = sort keys %seen;
			}
			my $lc = defined $label_col ? $label_col
				   : (grep { $_ eq 'row_name' } @cols) ? 'row_name' : undef;
			if (defined $lc) {
				@cols = grep { $_ ne $lc } @cols;
				$lab_header = $lc;
			}
			for my $i (0 .. $show - 1) {
				my $row = $data->[$i];
				$row = {} unless ref $row eq 'HASH';
				push @labels, defined $lc ? $row->{$lc} : $i;
				push @raw, [ map { $row->{$_} } @cols ];
			}
			$lab_header = '' unless defined $lab_header;
		}
	} elsif ($rt eq 'HASH') {
		my @keys = keys %$data;
		my $sample;
		for my $k (@keys) { $sample = $data->{$k}; last if defined $sample; }
		my $vt = ref $sample;
		if (!@keys) {
			$kind = 'Hash'; $total = 0; $lab_header = '';
		} elsif ($vt eq 'ARRAY') {							# ---- HoA ----
			$kind = 'HoA';
			my @allcols = $ucols ? @$ucols : sort @keys;
			$total = 0;
			for my $k (@keys) {
				next unless ref $data->{$k} eq 'ARRAY';
				my $l = scalar @{ $data->{$k} };
				$total = $l if $l > $total;
			}
			my $show = $n < $total ? $n : $total;
			my $lc = defined $label_col ? $label_col
				   : (grep { $_ eq 'row_name' } @allcols) ? 'row_name' : undef;
			@cols = grep { !defined $lc || $_ ne $lc } @allcols;
			$lab_header = defined $lc ? $lc : '';
			for my $i (0 .. $show - 1) {
				push @labels, defined $lc
					? (ref $data->{$lc} eq 'ARRAY' ? $data->{$lc}[$i] : undef)
					: $i;
				push @raw, [ map {
					ref $data->{$_} eq 'ARRAY' ? $data->{$_}[$i] : undef
				} @cols ];
			}
		} elsif ($vt eq 'HASH') {							# ---- HoH ----
			$kind = 'HoH';
			$total = scalar @keys;
			my @rk = sort @keys;
			my $show = $n < $total ? $n : $total;
			my @shown = $show > 0 ? @rk[0 .. $show - 1] : ();
			if ($ucols) { @cols = @$ucols; }
			else {
				my %seen;
				for my $rkk (@shown) {
					next unless ref $data->{$rkk} eq 'HASH';
					$seen{$_} = 1 for keys %{ $data->{$rkk} };
				}
				@cols = sort keys %seen;
			}
			@cols = grep { $_ ne $label_col } @cols if defined $label_col;
			$lab_header = defined $label_col ? $label_col : 'row_name';
			for my $rkk (@shown) {
				push @labels, $rkk;
				my $inner = ref $data->{$rkk} eq 'HASH' ? $data->{$rkk} : {};
				push @raw, [ map { $inner->{$_} } @cols ];
			}
		} else {											# ---- flat hash ----
			$kind = 'Hash'; $total = 1;
			my $show = $n < $total ? $n : $total;
			if ($ucols) { @cols = @$ucols; } else { @cols = sort @keys; }
			my $lc = defined $label_col ? $label_col
				   : (grep { $_ eq 'row_name' } @cols) ? 'row_name' : undef;
			if (defined $lc) { @cols = grep { $_ ne $lc } @cols; $lab_header = $lc; }
			$lab_header = '' unless defined $lab_header;
			for my $i (0 .. $show - 1) {
				push @labels, defined $lc ? $data->{$lc} : $i;
				push @raw, [ map { $data->{$_} } @cols ];
			}
		}
	}

	return _render_grid(
		kind => $kind, total => $total,
		cols => \@cols, labels => \@labels, raw => \@raw, lab_header => $lab_header,
		na => $na, max_width => $maxw, ellipsis => $ell, gap => $gap,
		width => $tw, to => $fh, return_only => $quiet,
		color => (exists $args{color} ? $args{color} : undef), colors => $args{colors},
	);
}

# _render_grid(%spec) -- shared, colourised table renderer used by view() and
# summary(). Given a fully-resolved grid (row labels + column headers + a
# row-major @raw of cell values) plus the display options, it produces the
# output view() has always emitted: a "# Kind: R rows x C cols" banner,
# wide-char-aware column widths, R-style column chunking to fit the terminal,
# optional Data::Printer-style colour, and a trailing "... N more rows" note.
sub _render_grid {
	my %s = @_;
	my $kind       = $s{kind};
	my $total      = $s{total};
	my @cols       = @{ $s{cols}   || [] };
	my @labels     = @{ $s{labels} || [] };
	my @raw        = @{ $s{raw}    || [] };
	my $lab_header = defined $s{lab_header} ? $s{lab_header} : '';
	my $na    = defined $s{na}        ? $s{na}        : 'undef';
	my $maxw  = defined $s{max_width} ? $s{max_width} : 80;
	my $ell   = defined $s{ellipsis}  ? $s{ellipsis}  : '...';
	my $gap   = defined $s{gap}       ? $s{gap}       : '  ';
	my $tw    = defined $s{width}     ? $s{width}     : 80;
	my $fh    = $s{to};
	my $quiet = $s{return_only};
	my $color  = $s{color};
	my $colors = $s{colors};

	# ---- display helpers (UTF-8 / wide-char aware) ----
	my $RESET = "\e[0m";
	my $decode = sub {
		my $s = shift;
		return ($s, 1) if utf8::is_utf8($s);	   # already-decoded chars: encode to bytes on output
		my $d = $s;
		return ($d, 1) if utf8::decode($d);	   # valid UTF-8 byte string -> chars
		return ($s, 0);						   # not UTF-8: leave bytes untouched
	};
	my $wide = sub {
		my $o = shift;
		return 1 if ($o >= 0x1100 && $o <= 0x115F)
				 || ($o >= 0x2E80 && $o <= 0xA4CF)
				 || ($o >= 0xAC00 && $o <= 0xD7A3)
				 || ($o >= 0xF900 && $o <= 0xFAFF)
				 || ($o >= 0xFE30 && $o <= 0xFE4F)
				 || ($o >= 0xFF00 && $o <= 0xFF60)
				 || ($o >= 0xFFE0 && $o <= 0xFFE6)
				 || ($o >= 0x1F300 && $o <= 0x1FAFF);
		return 0;
	};
	my $cwidth = sub {							# width of an already-decoded string
		my $s = shift; my $w = 0;
		for my $ch (split //, $s) { my $o = ord $ch; next if $o == 0; $w += $wide->($o) ? 2 : 1; }
		return $w;
	};
	my $dwidth = sub { my ($c) = $decode->(shift); return $cwidth->($c); };
	my $ell_w  = $dwidth->($ell);
	# stringify + sanitize + char-aware truncate; returns (output_bytes, width)
	my $prep = sub {
		my $v = shift;
		my $s = defined $v ? "$v" : $na;
		$s =~ s/\t/\\t/g; $s =~ s/\r/\\r/g; $s =~ s/\n/\\n/g;
		my ($c, $dec) = $decode->($s);
		if ($maxw && $cwidth->($c) > $maxw) {
			my $budget = $maxw - $ell_w; $budget = 0 if $budget < 0;
			my $keep = ''; my $w = 0;
			for my $ch (split //, $c) {
				my $cw = $wide->(ord $ch) ? 2 : 1;
				last if $w + $cw > $budget;
				$keep .= $ch; $w += $cw;
			}
			$c = $keep . $ell;
			$dec ||= utf8::is_utf8($ell);
		}
		my $w = $cwidth->($c);
		my $bytes = $c; utf8::encode($bytes) if $dec;
		return ($bytes, $w);
	};

	# ---- colour configuration (Data::Printer-style) ----
	my %default_colors = (
		array		=> 'bright_white',	number => 'bright_blue',
		string		=> 'bright_yellow', class  => 'bright_green',
		undef		=> 'bright_red',	hash   => 'magenta',
		caller_info => 'bright_cyan',	separator => 'white',
	);
	my %color = (%default_colors, %{ $colors || {} });
	my %fg = (
		black=>30, red=>31, green=>32, yellow=>33, blue=>34, magenta=>35, cyan=>36, white=>37,
		bright_black=>90, bright_red=>91, bright_green=>92, bright_yellow=>93,
		bright_blue=>94, bright_magenta=>95, bright_cyan=>96, bright_white=>97,
	);
	my $sgr = sub {
		my $spec = $color{ $_[0] };
		return '' unless defined $spec && length $spec;
		if ($spec =~ /^#?([0-9a-fA-F]{6})\z/) {
			my ($r, $g, $b) = map { hex } unpack 'a2a2a2', $1;
			return "\e[38;2;$r;$g;${b}m";
		}
		return "\e[$fg{$spec}m" if exists $fg{$spec};
		return "\e[$spec" . 'm'	 if $spec =~ /^\d[\d;]*\z/;
		return '';
	};
	my $want_color;
	if (!defined $color || (!ref $color && $color eq 'auto')) {
		my $target = defined $fh ? $fh : \*STDOUT;
		$want_color = (!$quiet && -t $target) ? 1 : 0;
	} else {
		$want_color = $color ? 1 : 0;
	}
	my $paint = sub {
		my ($text, $type) = @_;
		return $text unless $want_color;
		my $c = $sgr->($type);
		return length $c ? $c . $text . $RESET : $text;
	};

	# ---- column types (alignment) ----
	my @numeric = (1) x scalar @cols;
	for my $r (@raw) {
		for my $j (0 .. $#cols) {
			my $v = $r->[$j];
			next unless defined $v;
			$numeric[$j] = 0 unless looks_like_number($v);
		}
	}
	my $lab_numeric = @labels ? 1 : 0;
	for my $l (@labels) { $lab_numeric = 0, last unless defined $l && looks_like_number($l); }
	my $val_type = sub {
		my $v = shift;
		return 'undef'	unless defined $v;
		return 'number' if looks_like_number($v);
		return 'string';
	};

	# ---- prepare every cell once: [bytes, width, colour-type] ----
	my @lab_cell = map { [ $prep->($_), (!defined $_ ? 'undef' : $lab_numeric ? 'array' : 'hash') ] } @labels;
	my @row_cell;
	for my $r (@raw) {
		push @row_cell, [ map { [ $prep->($r->[$_]), $val_type->($r->[$_]) ] } 0 .. $#cols ];
	}
	my @head_cell = map { [ $prep->($_) ] } @cols;
	my ($lh_b, $lh_w) = $prep->($lab_header);

	# ---- column widths (display columns) ----
	my $lab_w = $lh_w;
	for my $c (@lab_cell) { $lab_w = $c->[1] if $c->[1] > $lab_w; }
	my @w;
	for my $j (0 .. $#cols) {
		my $width = $head_cell[$j][1];
		for my $r (@row_cell) { $width = $r->[$j][1] if $r->[$j][1] > $width; }
		$w[$j] = $width;
	}

	# ---- pad: spaces are never coloured; only the value text is ----
	my $field = sub {
		my ($bytes, $bw, $width, $right, $type) = @_;
		my $gapn = $width - $bw; $gapn = 0 if $gapn < 0;
		my $sp = ' ' x $gapn;
		my $painted = $paint->($bytes, $type);
		return $right ? $sp . $painted : $painted . $sp;
	};

	# ---- break columns into chunks that fit within $tw (R-style) ----
	# the label column (width $lab_w) is repeated at the front of every chunk.
	# $gap is spaces only, so its display width is length($gap).
	my $gap_w = length $gap;
	my @chunks;
	if (@cols) {
		my $j = 0;
		while ($j <= $#cols) {
			my $used = $lab_w;
			my @chunk;
			while ($j <= $#cols) {
				my $add = $gap_w + $w[$j];
				# always keep at least one column per chunk, even if it overflows
				last if @chunk && $used + $add > $tw;
				push @chunk, $j;
				$used += $add;
				$j++;
			}
			push @chunks, \@chunk;
		}
	} else {
		@chunks = ( [] );	# no data columns: just the label column
	}

	my @out;
	my $shown = scalar @row_cell;
	push @out, $paint->(
		sprintf("# %s: %d row%s x %d col%s	(showing %d)",
			$kind, $total, ($total == 1 ? '' : 's'),
			scalar(@cols), (@cols == 1 ? '' : 's'), $shown),
		'caller_info');

	for my $chunk (@chunks) {
		my @hcells = ( $field->($lh_b, $lh_w, $lab_w, 0, 'hash') );
		push @hcells, $field->($head_cell[$_][0], $head_cell[$_][1], $w[$_], $numeric[$_], 'hash') for @$chunk;
		push @out, join($gap, @hcells);
		for my $ri (0 .. $#row_cell) {
			my @cells = ( $field->($lab_cell[$ri][0], $lab_cell[$ri][1], $lab_w, $lab_numeric, $lab_cell[$ri][2]) );
			push @cells, $field->($row_cell[$ri][$_][0], $row_cell[$ri][$_][1], $w[$_], $numeric[$_], $row_cell[$ri][$_][2]) for @$chunk;
			push @out, join($gap, @cells);
		}
	}

	push @out, $paint->(
		sprintf("# ... %d more row%s", $total - $shown, ($total - $shown == 1 ? '' : 's')),
		'caller_info') if $shown < $total;

	my $str = join("\n", @out) . "\n";
	unless ($quiet) { defined $fh ? print {$fh} $str : print $str; }
	return $str;
}

# TukeyHSD($fit, %opts) -- Tukey Honest Significant Differences.
#
# Mirrors R's stats::TukeyHSD for the fitted objects produced by this
# module's aov(), lm() and glm().  Base R only defines TukeyHSD.aov; this
# extends the same all-pairwise studentized-range comparison to lm and glm
# outputs as well.
#
# The fitted objects here do not retain the model frame, so unlike R the
# response values and per-level replication counts are recomputed from the
# data.  Therefore the caller supplies the data frame and the response name:
#
#   my $fit = aov({ weight => \@w, group => \@g }, 'weight ~ group');
#   my $hsd = TukeyHSD($fit, data => $df, formula => 'weight ~ group');
#   # or:    TukeyHSD($fit, data => $df, response => 'weight');
#
# Options:
#   data        (required) the AoH / HoA / HoH used to fit the model
#   response    response column name; or give formula => 'y ~ ...'
#   formula     alternative to response: LHS is parsed for the response
#   which       factor name or arrayref of names (default: all factors)
#   conf.level  confidence level, default 0.95 (conf_level also accepted)
#   ordered     if true, order each factor's levels by increasing mean
#
# Returns a hashref: one entry per factor mapping to an arrayref of
# comparison hashes { comparison, diff, lwr, upr, 'p adj' } in R's
# lower-triangle order, plus the attributes 'conf.level' and 'ordered'.
#
# Scope: main-effect factors (those present in $fit->{xlevels}); a grouping
# variable must be categorical (string levels) to be treated as a factor,
# exactly as R requires factor().  MSE is the residual mean square (for glm
# this is deviance/df.residual: exact for the gaussian family, a Wald-type
# scale otherwise).  Per-level means are observed marginal means, which
# match R's model.tables means for one-way (and balanced) designs.
sub TukeyHSD {
	my ($fit, %opt) = @_;
	die 'TukeyHSD: first argument must be a fitted-model hashref (from aov/lm/glm)'
		unless ref($fit) eq 'HASH';

	my $conf = exists $opt{'conf.level'} ? $opt{'conf.level'}
	         : exists $opt{conf_level}   ? $opt{conf_level}
	         : 0.95;
	die 'TukeyHSD: conf.level must be between 0 and 1'
		unless $conf > 0 && $conf < 1;
	my $ordered = $opt{ordered} ? 1 : 0;

	my $data = $opt{data}
		or die "TukeyHSD: 'data' (the data frame used to fit the model) is required";

	# --- residual mean square (MSE) and residual d.f., per model type ---
	my ($mse, $df);
	if (ref($fit->{Residuals}) eq 'HASH') {                 # aov
		$df  = $fit->{Residuals}{Df};
		$mse = $fit->{Residuals}{'Mean Sq'};
	} elsif (exists($fit->{rss}) && exists($fit->{'df.residual'})) {         # lm
		$df  = $fit->{'df.residual'};
		$mse = ($df > 0) ? $fit->{rss} / $df : undef;
	} elsif (exists($fit->{deviance}) && exists($fit->{'df.residual'})) {    # glm
		$df  = $fit->{'df.residual'};
		$mse = ($df > 0) ? $fit->{deviance} / $df : undef;
	} else {
		die 'TukeyHSD: could not find residual MSE/df in the fit (expected aov/lm/glm output)';
	}
	die 'TukeyHSD: residual degrees of freedom must be >= 2 (got '
		. (defined($df) ? $df : 'undef') . ')'
		unless defined($df) && $df >= 2;
	die 'TukeyHSD: could not determine a positive residual mean square'
		unless defined($mse) && $mse > 0;

	# --- WIDE one-way layout ------------------------------------------------
	# data = { level => [observations], ... } with no response/formula: each
	# key is a group and its arrayref holds that group's values -- the same
	# shape aov() auto-stacks when the formula is omitted. Simpler than R's
	# long format: no stacked response column, no separate factor column.
	if (   !defined($opt{response}) && !defined($opt{formula})
		&& ref($data) eq 'HASH' && keys(%$data) >= 2
		&& (!grep { ref($_) ne 'ARRAY' } values %$data)
		&& (!grep { !grep { defined && looks_like_number($_) } @$_ } values %$data)) {
		my $label = (defined $opt{which} && !ref $opt{which}) ? $opt{which} : 'group';
		my (%sum, %cnt);
		for my $lev (keys %$data) {
			for my $yv (@{ $data->{$lev} }) {
				next unless defined($yv) && looks_like_number($yv);
				$sum{$lev} += $yv;
				$cnt{$lev}++;
			}
		}
		my @levels = grep { $cnt{$_} } sort keys %$data;  # R orders levels alphabetically
		die 'TukeyHSD: need at least 2 non-empty groups' unless @levels >= 2;
		my @means = map { $sum{$_} / $cnt{$_} } @levels;
		my @n     = map { $cnt{$_} }            @levels;
		return {
			$label       => _tukey_compare(\@levels, \@means, \@n, $mse, $df, $conf, $ordered),
			'conf.level' => $conf,
			ordered      => $ordered,
		};
	}

	# --- LONG layout (R-style): a response column + one or more factor columns
	my $resp = $opt{response};
	if (!defined($resp) && defined $opt{formula}) {
		($resp) = $opt{formula} =~ /\A\s*([^~]+?)\s*~/;
	}
	die "TukeyHSD: need the response variable; pass response => 'name' or formula => 'y ~ ...'"
		unless defined($resp) && length $resp;

	# --- factors present in the model (idx 0 of each xlevels entry = reference) ---
	my $xl = $fit->{xlevels};
	die 'TukeyHSD: no factors in the fitted model (nothing to compare)'
		unless ref($xl) eq 'HASH' && keys %$xl;

	my @which = defined($opt{which})
		? (ref($opt{which}) eq 'ARRAY' ? @{ $opt{which} } : ($opt{which}))
		: (sort keys %$xl);

	my @factors;
	for my $f (@which) {
		if (exists $xl->{$f}) { push @factors, $f }
		else { warn "TukeyHSD: '$f' is not a factor in the model and will be dropped\n" }
	}
	die "TukeyHSD: 'which' specified no factors" unless @factors;

	my $y = _tukey_col($data, $resp);

	my %out;
	for my $f (@factors) {
		my $g = _tukey_col($data, $f);
		die "TukeyHSD: response '$resp' and factor '$f' differ in length"
			unless scalar(@$y) == scalar(@$g);

		my (%sum, %cnt);
		for my $i (0 .. $#$g) {
			my $gv = $g->[$i];
			my $yv = $y->[$i];
			next unless defined($gv) && defined($yv) && looks_like_number($yv);
			$sum{$gv} += $yv;
			$cnt{$gv}++;
		}

		# canonical level order from xlevels, then any extra observed levels
		my @levels = @{ $xl->{$f} };
		my %seen = map { $_ => 1 } @levels;
		push @levels, sort grep { !$seen{$_} } keys %cnt;
		@levels = grep { $cnt{$_} } @levels;      # only levels that carry data

		die "TukeyHSD: factor '$f' needs at least 2 non-empty levels"
			unless scalar(@levels) >= 2;

		my @means = map { $sum{$_} / $cnt{$_} } @levels;
		my @n     = map { $cnt{$_} }            @levels;

		$out{$f} = _tukey_compare(\@levels, \@means, \@n, $mse, $df, $conf, $ordered);
	}

	$out{'conf.level'} = $conf;      # attributes, R-style
	$out{ordered}      = $ordered;
	return \%out;
}

# _tukey_compare(\@levels, \@means, \@n, $mse, $df, $conf, $ordered)
# Shared HSD math for one factor: builds the pairwise-comparison rows in R's
# lower-triangle, column-major order. Used by both the wide and long paths.
sub _tukey_compare {
	my ($levels, $means, $n, $mse, $df, $conf, $ordered) = @_;
	my @levels = @$levels;
	my @means  = @$means;
	my @n      = @$n;
	if ($ordered) {
		my @ord = sort { $means[$a] <=> $means[$b] } 0 .. $#means;
		@levels = @levels[@ord];
		@means  = @means[@ord];
		@n      = @n[@ord];
	}
	my $k    = scalar @means;
	my $crit = Stats::LikeR::qtukey($conf, $k, $df);    # nranges = 1
	my @rows;
	for my $j (0 .. $k - 1) {                            # column-major lower triangle
		for my $i ($j + 1 .. $k - 1) {
			my $diff  = $means[$i] - $means[$j];
			my $se    = sqrt( ($mse / 2) * (1 / $n[$i] + 1 / $n[$j]) );
			my $width = $crit * $se;
			my $est   = ($se > 0)
				? $diff / $se
				: ($diff >= 0 ? 9**9**9 : -(9**9**9));
			my $padj  = Stats::LikeR::ptukey(abs($est), $k, $df, 'lower.tail' => 0);
			push @rows, {
				comparison => "$levels[$i]-$levels[$j]",
				diff       => $diff,
				lwr        => $diff - $width,
				upr        => $diff + $width,
				'p adj'    => $padj,
			};
		}
	}
	return \@rows;
}

# =======================================================================
# melt / pivot_table / fillna / ffill / bfill
#   pure-Perl additions to lib/Stats/LikeR.pm
#
# Placement: splice the reshape pair (melt, pivot_table) in after concat/
# rbind, and the impute trio (fillna, ffill, bfill) in after dropna.  Add
#   melt pivot_table fillna ffill bfill
# to @EXPORT_OK (== @EXPORT).  All five reshape/impute at the Perl level
# only; the sole numeric work is in pivot_table, which reuses the XS
# reducers through _agg_reduce, so there is no XS/ABI surface added here.
#
# NA is undef throughout, exactly as dropna() treats it (a missing hash key
# counts as NA).  Every function returns a NEW top-level frame and never
# mutates its input.  Shape is classified by _df_shape (the agg()/view()
# detector); 'output.type' defaults to the input family, like agg().
# =======================================================================

# _frame_cols($df, $shape, \@need) -> (\%col, $R)
#
# Extract the named columns once, aligned to row positions 0 .. R-1, using
# the same per-shape access agg() uses.  For HoA the column arrays are
# aliased (read-only callers), not rebuilt; every other shape materialises
# a fresh per-column slice.  HoH rows are visited in string-sorted key
# order so a positional axis exists.  Not exported.
sub _frame_cols {
	my ($df, $shape, $need) = @_;
	my (%col, $R);
	if ($shape eq 'AoA') {
		my @h = grep { defined } @$df;
		$R = scalar @h;
		for my $c (@$need) { $col{$c} = [ map { $_->[$c] } @h ] }
	} elsif ($shape eq 'AoH') {
		my @h = grep { defined } @$df;
		$R = scalar @h;
		for my $c (@$need) { $col{$c} = [ map { $_->{$c} } @h ] }
	} elsif ($shape eq 'HoA') {
		$R = 0;
		for my $v (values %$df) { $R = @$v if ref $v eq 'ARRAY' && @$v > $R }
		for my $c (@$need) { $col{$c} = ref $df->{$c} eq 'ARRAY' ? $df->{$c} : [] }
	} else {                                     # HoH
		my @h = map { $df->{$_} } sort keys %$df;
		$R = scalar @h;
		for my $c (@$need) { $col{$c} = [ map { $_->{$c} } @h ] }
	}
	return (\%col, $R);
}

# _sort_group_keys(\@order, \%repr) -> \@sorted
#
# Order group keys by their representative value tuple, numerically when
# every tuple element (across every group) looks like a number, else as
# strings (undef sorts as ''); the same rule agg() uses for its groups.
# Not exported.
sub _sort_group_keys {
	my ($order, $repr) = @_;
	my $all_num = 1;
	SORTNUM: for my $k (@$order) {
		for my $v (@{ $repr->{$k} }) {
			unless (defined $v && looks_like_number($v)) { $all_num = 0; last SORTNUM }
		}
	}
	if ($all_num) {
		return [ sort {
			my ($ra, $rb) = ($repr->{$a}, $repr->{$b});
			my $c = 0;
			for my $j (0 .. $#$ra) { last if $c = $ra->[$j] <=> $rb->[$j] }
			$c;
		} @$order ];
	}
	return [ sort {
		my ($ra, $rb) = ($repr->{$a}, $repr->{$b});
		my $c = 0;
		for my $j (0 .. $#$ra) {
			my $x = defined $ra->[$j] ? $ra->[$j] : '';
			my $y = defined $rb->[$j] ? $rb->[$j] : '';
			last if $c = $x cmp $y;
		}
		$c;
	} @$order ];
}

# melt($df, id_vars => $col|\@cols, value_vars => $col|\@cols,
#      var_name => 'variable', value_name => 'value', 'output.type' => aoa|aoh|hoa|hoh)
#
# Wide -> long, like pandas DataFrame.melt.  Each cell of the value_vars
# columns becomes its own output row: the id_vars are copied across, the
# var_name column holds the source column identifier and the value_name
# column holds the cell.  Column identifiers are names for AoH/HoA/HoH and
# 0-based integer positions for AoA.
#
#   id_vars      scalar or arrayref; default none.
#   value_vars   scalar or arrayref; default every column not in id_vars
#                (column universe and order come from colnames()).
#   var_name     name of the variable column; default 'variable'.
#   value_name   name of the value column;    default 'value'.
#   'output.type' aoa|aoh|hoa|hoh; default the input family.  For aoa output
#                the columns are positional (id_vars.., variable, value) so
#                var_name/value_name are not used.  For hoh output the row
#                labels are reset to 0 .. N-1 (like pandas' RangeIndex).
#
# Row order is column-major, matching pandas: all rows for value_vars[0],
# then all rows for value_vars[1], and so on, preserving input row order
# within each block.  The original frame is never modified.
sub melt {
	my $df = shift;
	die 'melt: undefined data in first position' unless defined $df;
	my $shape = _df_shape($df, 'melt');
	die "melt: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( id_vars => 1, value_vars => 1, var_name => 1,
	              value_name => 1, 'output.type' => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "melt: unknown argument(s): @bad\n" if @bad;

	my @id = !defined $arg{id_vars}        ? ()
	       : ref $arg{id_vars} eq 'ARRAY'  ? @{ $arg{id_vars} }
	       :                                 ( $arg{id_vars} );
	my $var_name   = defined $arg{var_name}   ? $arg{var_name}   : 'variable';
	my $value_name = defined $arg{value_name} ? $arg{value_name} : 'value';
	my $otype = defined $arg{'output.type'} ? lc $arg{'output.type'} : lc $shape;
	my %ok_otype = ( aoa => 1, aoh => 1, hoa => 1, hoh => 1 );
	die "melt: output.type '$otype' isn't allowed (aoa, aoh, hoa, hoh)\n"
		unless $ok_otype{$otype};

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;
	my %is_id = map { $_ => 1 } @id;
	my @val = !defined $arg{value_vars}        ? ( grep { !$is_id{$_} } @universe )
	        : ref $arg{value_vars} eq 'ARRAY'  ? @{ $arg{value_vars} }
	        :                                    ( $arg{value_vars} );
	for my $c (@id, @val) {
		die "melt: column '$c' not found\n" unless $uni{$c};
	}
	# name hygiene: the emitted variable/value columns must not collide
	die "melt: var_name and value_name must differ\n"
		if $var_name eq $value_name;
	if ($otype ne 'aoa') {
		for my $c (@id) {
			die "melt: var_name '$var_name' collides with an id_vars column\n"
				if $c eq $var_name;
			die "melt: value_name '$value_name' collides with an id_vars column\n"
				if $c eq $value_name;
		}
	}

	my %need; $need{$_} = 1 for @id, @val;
	my ($col, $R) = _frame_cols($df, $shape, [ keys %need ]);

	# column-major stack: [ \@id_values, variable, value ]
	my @rec;
	for my $v (@val) {
		for (my $i = 0; $i < $R; $i++) {
			my @idvals = map { $col->{$_}[$i] } @id;
			push @rec, [ \@idvals, $v, $col->{$v}[$i] ];
		}
	}

	if ($otype eq 'aoa') {
		return [ map { [ @{ $_->[0] }, $_->[1], $_->[2] ] } @rec ];
	} elsif ($otype eq 'aoh') {
		my @out;
		for my $r (@rec) {
			my %h;
			@h{ @id } = @{ $r->[0] };
			$h{$var_name}   = $r->[1];
			$h{$value_name} = $r->[2];
			push @out, \%h;
		}
		return \@out;
	} elsif ($otype eq 'hoa') {
		my %out = map { $_ => [] } @id, $var_name, $value_name;
		for my $r (@rec) {
			push @{ $out{ $id[$_] } }, $r->[0][$_] for 0 .. $#id;
			push @{ $out{$var_name} },   $r->[1];
			push @{ $out{$value_name} }, $r->[2];
		}
		return \%out;
	} else {                                     # hoh, RangeIndex 0..N-1
		my %out;
		my $n = 0;
		for my $r (@rec) {
			my %h;
			@h{ @id } = @{ $r->[0] };
			$h{$var_name}   = $r->[1];
			$h{$value_name} = $r->[2];
			$out{ $n++ } = \%h;
		}
		return \%out;
	}
}

# pivot_table($df, index => $col|\@cols, columns => $col|\@cols,
#             values => $col|\@cols, aggfunc => 'mean', fill_value => undef,
#             skipna => 1, sort => 1, sep => '.', 'output.type' => ...)
#
# Long -> wide with aggregation, like pandas DataFrame.pivot_table.  Rows are
# the distinct `index` tuples; the distinct `columns` tuples spread into new
# output columns; each cell is `aggfunc` applied to the `values` that fall in
# that (index, columns) bucket.  This is the combine half of agg() with the
# group value spread across columns instead of down rows, and it reuses the
# same aggregator vocabulary.
#
#   index        scalar/arrayref of columns that become output rows; default
#                none (a single aggregated row).
#   columns      scalar/arrayref whose distinct value tuples become output
#                columns.  REQUIRED.  A row whose `columns` tuple has any NA
#                is skipped (no column can be named from it).
#   values       scalar/arrayref of columns to aggregate; default every column
#                not used by index/columns.
#   aggfunc      one aggregator name, an arrayref of names, or a coderef;
#                default 'mean'.  Named: mean median sum sd var min max count
#                n nunique first last mode (the agg() set).  A coderef is
#                called as $code->(\@cells) with every cell (NA included).
#   fill_value   substituted for any NA result cell (missing bucket, or an
#                aggregate that came back undef); default leaves undef.
#   skipna       0|1, default 1; forwarded to the numeric reducers as in agg.
#   sort         0|1, default 1; sort output rows and columns by their key
#                (numeric if every key looks numeric, else string).
#   sep          separator for generated column names; default '.'.
#   'output.type' aoa|aoh|hoa|hoh; default input family.  For hoh the row
#                label is the index tuple joined with '.', uniquified with .N.
#
# Generated column names join, with `sep` and in this order, only the pieces
# that vary: the aggregator name (only when >1 aggregator), the value column
# (only when >1 value), and always the `columns` tuple.  With a single value
# and single aggregator the name is exactly the `columns` tuple, matching
# pandas' flat output.  A duplicate generated name is an error (raise `sep`).
# The original frame is never modified.
sub pivot_table {
	my $df = shift;
	die 'pivot_table: undefined data in first position' unless defined $df;
	my $shape = _df_shape($df, 'pivot_table');
	die "pivot_table: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( index => 1, columns => 1, values => 1, aggfunc => 1,
	              fill_value => 1, skipna => 1, sort => 1, sep => 1,
	              'output.type' => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "pivot_table: unknown argument(s): @bad\n" if @bad;
	die "pivot_table: 'columns' is required\n" unless defined $arg{columns};

	my @index   = !defined $arg{index}       ? ()
	            : ref $arg{index} eq 'ARRAY'  ? @{ $arg{index} }
	            :                               ( $arg{index} );
	my @columns = ref $arg{columns} eq 'ARRAY' ? @{ $arg{columns} } : ( $arg{columns} );
	die "pivot_table: 'columns' must name at least one column\n" unless @columns;

	my $sep      = defined $arg{sep} ? $arg{sep} : '.';
	my $skipna   = exists $arg{skipna} ? ($arg{skipna} ? 1 : 0) : 1;
	my $dosort   = exists $arg{sort}   ? ($arg{sort}   ? 1 : 0) : 1;
	my $has_fill = exists $arg{fill_value};
	my $fill     = $arg{fill_value};
	my $otype    = defined $arg{'output.type'} ? lc $arg{'output.type'} : lc $shape;
	my %ok_otype = ( aoa => 1, aoh => 1, hoa => 1, hoh => 1 );
	die "pivot_table: output.type '$otype' isn't allowed (aoa, aoh, hoa, hoh)\n"
		unless $ok_otype{$otype};

	my $af = exists $arg{aggfunc} ? $arg{aggfunc} : 'mean';
	my @funcs = ref $af eq 'ARRAY' ? @$af : ( $af );
	die "pivot_table: empty aggfunc list\n" unless @funcs;
	my %known_agg = map { $_ => 1 }
		qw(mean median sum sd var min max count n nunique first last mode);
	for my $f (@funcs) {
		next if ref $f eq 'CODE';
		die "pivot_table: unknown aggfunc '$f'\n" unless $known_agg{$f};
	}

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;
	my %reserved = map { $_ => 1 } @index, @columns;
	my @values = !defined $arg{values}       ? ( grep { !$reserved{$_} } @universe )
	           : ref $arg{values} eq 'ARRAY'  ? @{ $arg{values} }
	           :                                ( $arg{values} );
	die "pivot_table: no value columns to aggregate\n" unless @values;
	for my $c (@index, @columns, @values) {
		die "pivot_table: column '$c' not found\n" unless $uni{$c};
	}

	my %need; $need{$_} = 1 for @index, @columns, @values;
	my ($col, $R) = _frame_cols($df, $shape, [ keys %need ]);

	# bucket every row under (index tuple, columns tuple), first-seen order
	my (%rrepr, @rorder, %rseen, %crepr, @corder, %cseen, %bucket);
	for (my $i = 0; $i < $R; $i++) {
		my @cv = map { $col->{$_}[$i] } @columns;
		next if grep { !defined } @cv;           # NA columns tuple -> unnameable
		my $ck = join "\x1e", map { "v$_" } @cv;
		unless ($cseen{$ck}) {
			$cseen{$ck} = 1; push @corder, $ck; $crepr{$ck} = [ @cv ];
		}
		my @iv = map { $col->{$_}[$i] } @index;
		my $rk = @index
			? join("\x1e", map { defined $_ ? "v$_" : "\0" } @iv)
			: "\0all";
		unless ($rseen{$rk}) {
			$rseen{$rk} = 1; push @rorder, $rk; $rrepr{$rk} = [ @iv ];
		}
		push @{ $bucket{$rk}{$ck}{$_} }, $col->{$_}[$i] for @values;
	}
	if ($dosort) {
		@rorder = @{ _sort_group_keys(\@rorder, \%rrepr) } if @index;
		@corder = @{ _sort_group_keys(\@corder, \%crepr) };
	}

	# output column plan: aggfunc-major, then value, then columns tuple
	my $multi_f = @funcs > 1;
	my $multi_v = @values > 1;
	my @colplan;                                 # [ ck, value, func, outname ]
	for my $f (@funcs) {
		my $fl = ref $f eq 'CODE' ? 'fn' : $f;
		for my $vv (@values) {
			for my $ck (@corder) {
				my $cstr = join $sep, map { defined $_ ? $_ : '' } @{ $crepr{$ck} };
				my @pieces;
				push @pieces, $fl if $multi_f;
				push @pieces, $vv if $multi_v;
				push @pieces, $cstr;
				push @colplan, [ $ck, $vv, $f, join($sep, @pieces) ];
			}
		}
	}
	my @out_names = ( @index, map { $_->[3] } @colplan );
	{
		my (%seen, @dup);
		for my $n (@out_names) { push @dup, $n if $seen{$n}++ == 1 }
		die "pivot_table: generated duplicate column name(s): @dup; "
		  . "pass a different 'sep' or rename inputs\n" if @dup;
	}

	# materialise straight into the requested shape
	my (@aoa, @aoh, %hoa, %hoh, %lseen);
	if ($otype eq 'hoa') { $hoa{$_} = [] for @out_names }
	for my $rk (@rorder) {
		my @vals = @{ $rrepr{$rk} };              # index values
		for my $cp (@colplan) {
			my ($ck, $vv, $f) = @$cp;
			my $raw = $bucket{$rk}{$ck}{$vv};
			my $cell;
			if (defined $raw && @$raw) {
				my @def = grep { defined } @$raw;
				$cell = _agg_reduce($f, $raw, \@def, $skipna);
			}
			$cell = $fill if !defined $cell && $has_fill;
			push @vals, $cell;
		}
		if ($otype eq 'aoa') {
			push @aoa, \@vals;
		} elsif ($otype eq 'aoh') {
			my %h; @h{ @out_names } = @vals; push @aoh, \%h;
		} elsif ($otype eq 'hoa') {
			push @{ $hoa{ $out_names[$_] } }, $vals[$_] for 0 .. $#out_names;
		} else {                                  # hoh
			my $label = @index
				? join('.', map { defined $_ ? $_ : '' } @{ $rrepr{$rk} })
				: 'all';
			my $uniq = $label; my $j = 0;
			while (exists $lseen{$uniq}) { $uniq = $label . '.' . (++$j) }
			$lseen{$uniq} = 1;
			my %h; @h{ @out_names } = @vals; $hoh{$uniq} = \%h;
		}
	}
	return \@aoa if $otype eq 'aoa';
	return \@aoh if $otype eq 'aoh';
	return \%hoa if $otype eq 'hoa';
	return \%hoh;
}

# fillna($df, value => $scalar | { col => val, ... }, cols => \@cols)
#
# Replace NA (undef) cells with a constant, like pandas DataFrame.fillna with
# a scalar or a dict.  `value` is REQUIRED and is either a single scalar (fill
# every NA in the frame, or only within `cols` when given) or a hashref mapping
# column => fill value (only those columns are touched; a dict key that names
# no existing column is ignored, matching pandas, and `cols` is then forbidden).
# For a scalar `value`, an explicit `cols` that names a missing column dies,
# like dropna().  Column identifiers are names for AoH/HoA/HoH and 0-based
# integer positions for AoA.
#
# A targeted column's missing hash key counts as NA and is materialised on
# fill (as in dropna's NA view).  AoA rows are not extended past their own
# length.  A structurally-undef (non-ref) row is passed through unchanged, not
# fabricated into a data row, matching ffill()/bfill().  For propagation instead
# of a constant use ffill()/bfill().  Returns
# a NEW frame (rows/columns rebuilt as needed); the original is never modified.
sub fillna {
	my $df = shift;
	die 'fillna: undefined data in first position' unless defined $df;
	my $shape = _df_shape($df, 'fillna');
	die "fillna: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( value => 1, cols => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "fillna: unknown argument(s): @bad\n" if @bad;
	die "fillna: a 'value' is required\n" unless exists $arg{value};

	my $value   = $arg{value};
	my $per_col = ref $value eq 'HASH';
	die "fillna: 'cols' cannot be combined with a per-column 'value' hashref\n"
		if $per_col && exists $arg{cols};

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;

	my (%fillmap, $scalar_fill, %tset, @targets);
	if ($per_col) {
		%fillmap = %$value;
		@targets = grep { $uni{$_} } keys %fillmap;   # ignore unknown dict keys
	} else {
		$scalar_fill = $value;
		if (exists $arg{cols}) {
			die "fillna: 'cols' must be an arrayref\n"
				unless ref $arg{cols} eq 'ARRAY';
			for my $c (@{ $arg{cols} }) {
				die "fillna: column '$c' not found\n" unless $uni{$c};
			}
			@targets = @{ $arg{cols} };
		} else {
			@targets = @universe;
		}
	}
	%tset = map { $_ => 1 } @targets;
	my $tv = sub { $per_col ? $fillmap{ $_[0] } : $scalar_fill };

	if ($shape eq 'AoH') {
		my @out;
		for my $row (@$df) {
			unless (ref $row eq 'HASH') { push @out, $row; next }
			my %h = %$row;
			for my $c (@targets) { $h{$c} = $tv->($c) unless defined $h{$c} }
			push @out, \%h;
		}
		return \@out;
	}
	if ($shape eq 'HoH') {
		my %out;
		for my $rk (keys %$df) {
			my $row = $df->{$rk};
			unless (ref $row eq 'HASH') { $out{$rk} = $row; next }
			my %h = %$row;
			for my $c (@targets) { $h{$c} = $tv->($c) unless defined $h{$c} }
			$out{$rk} = \%h;
		}
		return \%out;
	}
	if ($shape eq 'HoA') {
		my $R = 0;
		for my $v (values %$df) { $R = @$v if ref $v eq 'ARRAY' && @$v > $R }
		my %out;
		for my $c (keys %$df) {
			my $arr = ref $df->{$c} eq 'ARRAY' ? $df->{$c} : [];
			if ($tset{$c}) {
				my $fv = $tv->($c);
				$out{$c} = [ map { defined $arr->[$_] ? $arr->[$_] : $fv } 0 .. $R - 1 ];
			} else {
				$out{$c} = [ @$arr ];
			}
		}
		return \%out;
	}
	# AoA
	my @out;
	for my $row (@$df) {
		unless (ref $row eq 'ARRAY') { push @out, $row; next }
		my @r = @$row;
		for my $c (@targets) {
			$r[$c] = $tv->($c) if $c <= $#r && !defined $r[$c];
		}
		push @out, \@r;
	}
	return \@out;
}

# _fill_seq(\@vals, $dir, $limit) -> \@vals   (modifies in place)
#
# Propagate the last (dir=1, forward) or next (dir=-1, backward) defined value
# over runs of undef.  With a defined `limit`, at most `limit` consecutive
# undefs are filled per gap; the rest stay undef.  Not exported.
sub _fill_seq {
	my ($vals, $dir, $limit) = @_;
	my $n = scalar @$vals;
	my @idx = $dir > 0 ? ( 0 .. $n - 1 ) : reverse( 0 .. $n - 1 );
	my ($last, $have, $run) = (undef, 0, 0);
	for my $i (@idx) {
		if (defined $vals->[$i]) {
			$last = $vals->[$i]; $have = 1; $run = 0;
		} elsif ($have) {
			next if defined $limit && $run >= $limit;
			$vals->[$i] = $last; $run++;
		}
	}
	return $vals;
}

# _impute_prop($df, $name, $dir, %opts) -- shared core of ffill/bfill.
#
# Propagate defined values along the row axis within each targeted column.
# Row order is positional for AoA/AoH/HoA and string-sorted key order for HoH
# (the only deterministic order a HoH has).  Options: cols => \@cols (default
# every column; an unknown column dies), limit => positive int (max fills per
# gap).  Fills within each column's existing length only (ragged HoA columns
# are not extended); AoA rows are not extended past their own length.  Returns
# a NEW frame; the original is never modified.  Not exported.
sub _impute_prop {
	my $df   = shift;
	my $name = shift;
	my $dir  = shift;
	die "$name: undefined data in first position" unless defined $df;
	my $shape = _df_shape($df, $name);
	die "$name: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( cols => 1, limit => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "$name: unknown argument(s): @bad\n" if @bad;

	my $limit = $arg{limit};
	die "$name: 'limit' must be a positive integer\n"
		if defined $limit
		&& ( !looks_like_number($limit) || $limit < 1 || $limit != int $limit );

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;
	my @targets;
	if (exists $arg{cols}) {
		die "$name: 'cols' must be an arrayref\n" unless ref $arg{cols} eq 'ARRAY';
		for my $c (@{ $arg{cols} }) {
			die "$name: column '$c' not found\n" unless $uni{$c};
		}
		@targets = @{ $arg{cols} };
	} else {
		@targets = @universe;
	}
	my %tset = map { $_ => 1 } @targets;

	if ($shape eq 'AoH') {
		my @out = map { ref $_ eq 'HASH' ? { %$_ } : $_ } @$df;
		for my $c (@targets) {
			my @vals = map { ref $_ eq 'HASH' ? $_->{$c} : undef } @out;
			_fill_seq(\@vals, $dir, $limit);
			for my $i (0 .. $#out) {
				next unless ref $out[$i] eq 'HASH';
				$out[$i]{$c} = $vals[$i] if defined $vals[$i];
			}
		}
		return \@out;
	}
	if ($shape eq 'HoH') {
		my @keys = sort keys %$df;
		my %out = map {
			$_ => ( ref $df->{$_} eq 'HASH' ? { %{ $df->{$_} } } : $df->{$_} )
		} keys %$df;
		for my $c (@targets) {
			my @vals = map { ref $out{$_} eq 'HASH' ? $out{$_}{$c} : undef } @keys;
			_fill_seq(\@vals, $dir, $limit);
			for my $j (0 .. $#keys) {
				my $rk = $keys[$j];
				next unless ref $out{$rk} eq 'HASH';
				$out{$rk}{$c} = $vals[$j] if defined $vals[$j];
			}
		}
		return \%out;
	}
	if ($shape eq 'HoA') {
		my %out;
		for my $c (keys %$df) {
			my $arr = ref $df->{$c} eq 'ARRAY' ? [ @{ $df->{$c} } ] : [];
			_fill_seq($arr, $dir, $limit) if $tset{$c};
			$out{$c} = $arr;
		}
		return \%out;
	}
	# AoA
	my @out = map { ref $_ eq 'ARRAY' ? [ @$_ ] : $_ } @$df;
	for my $c (@targets) {
		my @vals = map { ref $_ eq 'ARRAY' ? $_->[$c] : undef } @out;
		_fill_seq(\@vals, $dir, $limit);
		for my $i (0 .. $#out) {
			next unless ref $out[$i] eq 'ARRAY';
			$out[$i][$c] = $vals[$i] if $c <= $#{ $out[$i] } && defined $vals[$i];
		}
	}
	return \@out;
}

# ffill($df, cols => \@cols, limit => $n)  -- forward-fill NA (last valid obs).
# bfill($df, cols => \@cols, limit => $n)  -- back-fill NA (next valid obs).
# See _impute_prop for the row-axis and shape semantics.
sub ffill { _impute_prop( shift, 'ffill',  1, @_ ) }
sub bfill { _impute_prop( shift, 'bfill', -1, @_ ) }

# The interpolate() numeric kernels now live in XS (see ip_fill_column and the
# _interp_column_xs XSUB in LikeR.xs); it is called once per target column below.

# interpolate($df, method => 'linear', cols => \@cols, x => ...,
#             order => $k, limit => $n,
#             limit_direction => 'forward'|'backward'|'both',
#             limit_area => 'inside'|'outside')
#
# Fill NA (undef) cells along the row axis, like pandas DataFrame.interpolate.
# It is the numeric sibling of ffill/bfill.  Row order and the four shapes match
# ffill/bfill (positional for AoA/AoH/HoA, sorted-key order for HoH), and it
# returns a NEW frame; the original is never modified.
#
#   method  the interpolant.  All of pandas' methods are supported:
#             linear (default), index, values, time  -- straight line; the
#               first three use `x`, 'linear' uses equal spacing.
#             slinear, nearest, zero                 -- piecewise, interior only.
#             pad/ffill, bfill/backfill              -- hold the last/next value.
#             quadratic, cubic                       -- interp1d B-splines.
#             cubicspline, pchip, akima, spline      -- SciPy-named splines.
#             polynomial, spline (need `order`)      -- degree-k spline.
#             barycentric, krogh                     -- global polynomial.
#   order   required for method 'polynomial' / 'spline' (degree 1, 2 or 3).
#   x       abscissae: an arrayref (one per row) or a column name/index whose
#           numeric values are the coordinates (default: equal spacing 0,1,2..).
#           Must be strictly increasing.  Used by every method except 'linear'.
#   limit_direction  'forward' (default), 'backward', or 'both'.
#   limit_area       'inside' fills only interior gaps, 'outside' only leading/
#                    trailing gaps, undef (default) fills both.
#   limit            max cells filled per undef run.
#   cols             columns to interpolate; default every column.
#
# The pipeline follows pandas exactly: fill every gap with the method, then
# blank the cells limit/direction/area forbid.  Only 'linear' and the hold/
# global methods reach leading/trailing gaps (the interp1d and akima methods
# are interior-only, matching SciPy).  Only numeric cells anchor a fill; a
# defined non-numeric cell is preserved (and, for the piecewise-local methods,
# blocks interpolation across it).  Interpolated cells are floats.  Fills within
# each column's existing length only; a non-ref row is passed through untouched.
sub interpolate {
	my $df = shift;
	die "interpolate: undefined data in first position" unless defined $df;
	my $shape = _df_shape($df, 'interpolate');
	die "interpolate: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( cols => 1, limit => 1, limit_direction => 1,
	              limit_area => 1, method => 1, order => 1, x => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "interpolate: unknown argument(s): @bad\n" if @bad;

	my %known_method = map { $_ => 1 } qw(
		linear index values time slinear nearest zero pad ffill bfill backfill
		quadratic cubic cubicspline pchip akima barycentric krogh polynomial spline );
	my $method = defined $arg{method} ? lc $arg{method} : 'linear';
	die "interpolate: unknown method '$method'\n" unless $known_method{$method};

	my $order = $arg{order};
	if ($method eq 'polynomial' || $method eq 'spline') {
		die "interpolate: method '$method' requires an integer 'order' >= 1\n"
			unless defined $order && looks_like_number($order)
			    && $order >= 1 && $order == int $order;
	}

	my $limit = $arg{limit};
	die "interpolate: 'limit' must be a positive integer\n"
		if defined $limit
		&& ( !looks_like_number($limit) || $limit < 1 || $limit != int $limit );

	my $dir = defined $arg{limit_direction} ? lc $arg{limit_direction} : 'forward';
	my %okdir = ( forward => 1, backward => 1, both => 1 );
	die "interpolate: 'limit_direction' must be 'forward', 'backward', or 'both'\n"
		unless $okdir{$dir};
	# the directional-hold methods pin their own direction
	$dir = 'forward'  if $method eq 'pad'   || $method eq 'ffill';
	$dir = 'backward' if $method eq 'bfill' || $method eq 'backfill';

	my $area;
	if (defined $arg{limit_area}) {
		$area = lc $arg{limit_area};
		die "interpolate: 'limit_area' must be 'inside' or 'outside'\n"
			unless $area eq 'inside' || $area eq 'outside';
	}

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;
	my @targets;
	if (exists $arg{cols}) {
		die "interpolate: 'cols' must be an arrayref\n" unless ref $arg{cols} eq 'ARRAY';
		for my $c (@{ $arg{cols} }) {
			die "interpolate: column '$c' not found\n" unless $uni{$c};
		}
		@targets = @{ $arg{cols} };
	} else {
		@targets = @universe;
	}
	my %tset = map { $_ => 1 } @targets;

	# x coordinate: arrayref, or a column key whose values are the coordinates
	my ($x_is_col, $x_col);
	if (defined $arg{x} && ref $arg{x} ne 'ARRAY') {
		$x_is_col = 1;
		$x_col = $arg{x};
		die "interpolate: x column '$x_col' not found\n" unless $uni{$x_col};
	}
	# validated coordinates of length $len; $xcolseq is the x column pulled in
	# the same row order (only consulted when x is a column key).
	my $mkcoords = sub {
		my ($len, $xcolseq) = @_;
		my @x;
		if    ($x_is_col)            {
			die "interpolate: x column '$x_col' length (${\ scalar @$xcolseq}) != column length ($len)\n"
				unless scalar @$xcolseq == $len;
			@x = @$xcolseq;
		}
		elsif (ref $arg{x} eq 'ARRAY') {
			die "interpolate: 'x' arrayref length (${\ scalar @{$arg{x}}}) != column length ($len)\n"
				unless scalar @{ $arg{x} } == $len;
			@x = @{ $arg{x} };
		} else                       { @x = (0 .. $len - 1); }
		for my $v (@x) {
			die "interpolate: 'x' coordinates must all be defined and numeric\n"
				unless defined $v && looks_like_number($v);
		}
		if (defined $arg{x}) {
			for my $i (1 .. $#x) {
				die "interpolate: 'x' coordinates must be strictly increasing\n"
					unless $x[$i] > $x[$i - 1];
			}
		}
		return \@x;
	};
	# shape dispatch mirrors _impute_prop (ffill/bfill).  The per-column numeric
	# fill (all methods, the dense solve, the preserve mask) is done in XS by
	# _interp_column_xs, which modifies the extracted @vals in place.
	# shape dispatch mirrors _impute_prop (ffill/bfill)
	if ($shape eq 'AoH') {
		my @out = map { ref $_ eq 'HASH' ? { %$_ } : $_ } @$df;
		my $xcolseq = $x_is_col ? [ map { ref $_ eq 'HASH' ? $_->{$x_col} : undef } @out ] : undef;
		my $coords = $mkcoords->(scalar @out, $xcolseq);
		for my $c (@targets) {
			my @vals = map { ref $_ eq 'HASH' ? $_->{$c} : undef } @out;
			_interp_column_xs(\@vals, $coords, $method, $order, $dir, $limit, $area);
			for my $i (0 .. $#out) {
				next unless ref $out[$i] eq 'HASH';
				$out[$i]{$c} = $vals[$i] if defined $vals[$i];
			}
		}
		return \@out;
	}
	if ($shape eq 'HoH') {
		my @keys = sort keys %$df;
		my %out = map {
			$_ => ( ref $df->{$_} eq 'HASH' ? { %{ $df->{$_} } } : $df->{$_} )
		} keys %$df;
		my $xcolseq = $x_is_col ? [ map { ref $out{$_} eq 'HASH' ? $out{$_}{$x_col} : undef } @keys ] : undef;
		my $coords = $mkcoords->(scalar @keys, $xcolseq);
		for my $c (@targets) {
			my @vals = map { ref $out{$_} eq 'HASH' ? $out{$_}{$c} : undef } @keys;
			_interp_column_xs(\@vals, $coords, $method, $order, $dir, $limit, $area);
			for my $j (0 .. $#keys) {
				my $rk = $keys[$j];
				next unless ref $out{$rk} eq 'HASH';
				$out{$rk}{$c} = $vals[$j] if defined $vals[$j];
			}
		}
		return \%out;
	}
	if ($shape eq 'HoA') {
		my %out;
		for my $c (keys %$df) {
			$out{$c} = ref $df->{$c} eq 'ARRAY' ? [ @{ $df->{$c} } ] : [];
		}
		for my $c (@targets) {
			my $arr = $out{$c};
			my $xcolseq = $x_is_col
				? [ @{ ref $df->{$x_col} eq 'ARRAY' ? $df->{$x_col} : [] } ]
				: undef;
			my $coords = $mkcoords->(scalar @$arr, $xcolseq);
			_interp_column_xs($arr, $coords, $method, $order, $dir, $limit, $area);
		}
		return \%out;
	}
	# AoA
	my @out = map { ref $_ eq 'ARRAY' ? [ @$_ ] : $_ } @$df;
	my $xcolseq = $x_is_col ? [ map { ref $_ eq 'ARRAY' ? $_->[$x_col] : undef } @out ] : undef;
	my $coords = $mkcoords->(scalar @out, $xcolseq);
	for my $c (@targets) {
		my @vals = map { ref $_ eq 'ARRAY' ? $_->[$c] : undef } @out;
		_interp_column_xs(\@vals, $coords, $method, $order, $dir, $limit, $area);
		for my $i (0 .. $#out) {
			next unless ref $out[$i] eq 'ARRAY';
			$out[$i][$c] = $vals[$i] if $c <= $#{ $out[$i] } && defined $vals[$i];
		}
	}
	return \@out;
}

# _tukey_col($data, $col) -- pull one column's cells, in row order, from any
# of the three data-frame shapes (AoH arrayref, HoA/HoH hashref).
sub _tukey_col {
	my ($data, $col) = @_;
	die 'TukeyHSD: data must be a reference (AoH / HoA / HoH)' unless ref $data;
	my $r = ref $data;
	if ($r eq 'ARRAY') {                              # AoH
		return [ map { $_->{$col} } @$data ];
	} elsif ($r eq 'HASH') {
		my ($first) = values %$data;
		if (ref($first) eq 'ARRAY') {                 # HoA
			die "TukeyHSD: column '$col' not found in data"
				unless exists $data->{$col};
			return [ @{ $data->{$col} } ];
		} else {                                      # HoH (row-name keyed)
			return [ map { $data->{$_}{$col} } sort keys %$data ];
		}
	}
	die 'TukeyHSD: unsupported data shape';
}

# ---- table_one: a stratified descriptive "Table 1" -----------------------
# Classify a column's non-missing values: 'continuous' if every one looks
# numeric, else 'categorical'.
sub _t1_classify {
	my ($vals) = @_;
	my @def = grep { defined } @$vals;
	return 'categorical' unless @def;
	for (@def) { return 'categorical' unless looks_like_number($_) }
	return 'continuous';
}

# p-value + test label for a continuous variable across >=2 groups.
# @$byg is one arrayref of (numeric, defined) values per group.
sub _t1_cont_p {
	my ($byg, $nonpar) = @_;
	my @g = grep { @$_ >= 1 } @$byg;
	return (undef, undef) if @g < 2;
	if (@g == 2) {
		my $r = $nonpar ? wilcox_test($g[0], $g[1]) : t_test($g[0], $g[1]);
		return ($r->{p_value}, $nonpar ? 'wilcoxon' : 't-test');
	}
	# >2 groups: Kruskal-Wallis (nonparametric) or one-way ANOVA
	my (@x, @lab);
	for my $i (0 .. $#g) { push @x, @{ $g[$i] }; push @lab, ("g$i") x scalar @{ $g[$i] } }
	if ($nonpar) {
		return (kruskal_test(\@x, \@lab)->{p_value}, 'kruskal-wallis');
	}
	my $aov = aov({ value => \@x, grp => \@lab }, 'value ~ grp');
	return ($aov->{grp}{'Pr(>F)'}, 'anova');
}

# p-value + test label for a categorical variable: chi-squared on the
# level-by-group contingency table.  Returns undef if the test cannot run.
sub _t1_cat_p {
	my ($table) = @_;
	# A variable with a single level gives a 1 x k table, which chisq_test
	# (like R) collapses to a goodness-of-fit test on the group sizes -- a
	# different question from the one this column asks.  There is no
	# association to test, so report none.
	return (undef, undef) if @$table < 2 || @{ $table->[0] } < 2;
	# small expected counts are worth knowing about at the call site, but
	# table_one summarises dozens of variables at once and the warning would
	# say nothing about which one
	my $r = eval {
		local $SIG{__WARN__} = sub {
			warn @_ unless $_[0] =~ /Chi-squared approximation may be incorrect/;
		};
		chisq_test($table);
	};
	return (undef, undef) if $@ || !$r;
	return ($r->{'p.value'} // $r->{p_value}, 'chi-squared');
}

sub table_one {
	my ($df, %opt) = @_;
	my %known = map { $_ => 1 } qw(by vars types nonparametric digits pct_digits);
	my @bad = sort grep { !$known{$_} } keys %opt;
	die "table_one: unknown argument(s): @bad\n" if @bad;

	my $by     = $opt{by};
	my $digits = defined $opt{digits}     ? $opt{digits}     : 2;
	my $pdig   = defined $opt{pct_digits} ? $opt{pct_digits} : 1;
	my $nonpar = $opt{nonparametric} ? 1 : 0;
	my %types  = $opt{types} ? %{ $opt{types} } : ();

	my $shape   = _df_shape($df, 'table_one');
	my @allcols = colnames($df);
	my %colset  = map { $_ => 1 } @allcols;
	die "table_one: 'by' column '$by' not found\n" if defined $by && !$colset{$by};
	my @vars = $opt{vars} ? @{ $opt{vars} }
	                      : grep { !defined $by || $_ ne $by } @allcols;
	for my $v (@vars) { die "table_one: column '$v' not found\n" unless $colset{$v} }

	my @need = (@vars, defined $by ? ($by) : ());
	my ($col, $R) = _frame_cols($df, $shape, \@need);

	my @grp = defined $by
	        ? map { defined $_ ? "$_" : 'NA' } @{ $col->{$by} }
	        : ('Overall') x $R;
	my %seen; my @groups = grep { !$seen{$_}++ } @grp;
	@groups = sort @groups if defined $by;
	my @grp_rows = map { my $g = $_; [ grep { $grp[$_] eq $g } 0 .. $R - 1 ] } @groups;

	my @out;
	for my $v (@vars) {
		my @vals = @{ $col->{$v} };
		my $type = $types{$v} || _t1_classify(\@vals);

		if ($type eq 'continuous') {
			my %row = (variable => $v, level => '', type => 'continuous');
			my @byg;
			for my $gi (0 .. $#groups) {
				my @gv = grep { looks_like_number($_) }
				         grep { defined } map { $vals[$_] } @{ $grp_rows[$gi] };
				push @byg, \@gv;
				$row{ $groups[$gi] } = @gv
					? sprintf('%.*f (%.*f)', $digits, mean(\@gv), $digits, @gv > 1 ? sd(\@gv) : 0)
					: '';
			}
			my @allv = grep { looks_like_number($_) } grep { defined } @vals;
			$row{Overall} = @allv
				? sprintf('%.*f (%.*f)', $digits, mean(\@allv), $digits, @allv > 1 ? sd(\@allv) : 0)
				: '';
			if (defined $by && @groups >= 2) {
				($row{p_value}, $row{test}) = _t1_cont_p(\@byg, $nonpar);
			}
			push @out, \%row;
		}
		else {
			my %lseen;
			my @levels = sort grep { !$lseen{$_}++ }
			             map { defined $_ ? "$_" : 'NA' } @vals;
			my %hdr = (variable => $v, level => '', type => 'categorical');
			if (defined $by && @groups >= 2) {
				my @table;
				for my $lv (@levels) {
					push @table, [ map {
						my $rows = $_;
						scalar grep { (defined $vals[$_] ? "$vals[$_]" : 'NA') eq $lv } @$rows
					} @grp_rows ];
				}
				($hdr{p_value}, $hdr{test}) = _t1_cat_p(\@table);
			}
			push @out, \%hdr;
			for my $lv (@levels) {
				my %row = (variable => $v, level => $lv, type => 'categorical');
				for my $gi (0 .. $#groups) {
					my $rows = $grp_rows[$gi];
					my $cnt  = scalar grep { (defined $vals[$_] ? "$vals[$_]" : 'NA') eq $lv } @$rows;
					my $tot  = scalar @$rows;
					$row{ $groups[$gi] } = $tot ? sprintf('%d (%.*f%%)', $cnt, $pdig, 100 * $cnt / $tot) : '0';
				}
				my $cntall = scalar grep { (defined $vals[$_] ? "$vals[$_]" : 'NA') eq $lv } 0 .. $R - 1;
				$row{Overall} = $R ? sprintf('%d (%.*f%%)', $cntall, $pdig, 100 * $cntall / $R) : '0';
				push @out, \%row;
			}
		}
	}
	return \@out;
}

# ----------------------------------------------------------------------------
# Effect sizes (Perl level; compose the XS primitives mean/var/aov).  All
# validated numerically against R.  Added to @EXPORT_OK (== @EXPORT).
# ----------------------------------------------------------------------------

# _num_pair(\@x, \@y, $who) -> (\@xn, \@yn): defined, numeric values only.
sub _num_pair {
	my ($x, $y, $who) = @_;
	die "$who: first two arguments must be array references\n"
		unless ref $x eq 'ARRAY' && ref $y eq 'ARRAY';
	my @xn = grep { defined && looks_like_number($_) } @$x;
	my @yn = grep { defined && looks_like_number($_) } @$y;
	die "$who: each group needs at least two numeric observations\n"
		if @xn < 2 || @yn < 2;
	return (\@xn, \@yn);
}

# cohen_d(\@x, \@y, hedges => 0, conf_level => 0.95)
#
# Cohen's d for two independent samples using the pooled standard deviation,
# with the Hedges' g small-sample bias correction and a large-sample
# (normal-approximation) confidence interval.
sub cohen_d {
	my ($x, $y, %opt) = @_;
	my $cl = defined $opt{conf_level} ? $opt{conf_level}
	       : defined $opt{'conf.level'} ? $opt{'conf.level'} : 0.95;
	die "cohen_d: conf.level must be between 0 and 1\n" unless $cl > 0 && $cl < 1;
	my ($xn, $yn) = _num_pair($x, $y, 'cohen_d');
	my ($n1, $n2) = (scalar @$xn, scalar @$yn);
	my ($m1, $m2) = (mean($xn), mean($yn));
	my ($v1, $v2) = (var($xn),  var($yn));
	my $sp = sqrt((($n1 - 1) * $v1 + ($n2 - 1) * $v2) / ($n1 + $n2 - 2));
	die "cohen_d: pooled standard deviation is zero\n" if $sp == 0;
	my $d  = ($m1 - $m2) / $sp;
	my $J  = 1 - 3 / (4 * ($n1 + $n2) - 9); # Hedges' correction factor
	my $se = sqrt(($n1 + $n2) / ($n1 * $n2) + $d * $d / (2 * ($n1 + $n2)));
	my $z  = _qnorm((1 + $cl) / 2);
	return {
		estimate     => $d,
		hedges_g     => $d * $J,
		pooled_sd    => $sp,
		se           => $se,
		'conf.int'   => [ $d - $z * $se, $d + $z * $se ],
		'conf.level' => $cl,
		n1           => $n1,
		n2           => $n2,
	};
}

# smd(\@x, \@y)
#
# Standardized mean difference for two continuous groups using the simple
# (unweighted) average of the group variances in the denominator -- the
# convention used for covariate-balance "Table 1" diagnostics (R's tableone /
# stddiff).  Returns the signed value.
sub smd {
	my ($x, $y) = @_;
	my ($xn, $yn) = _num_pair($x, $y, 'smd');
	my $denom = sqrt((var($xn) + var($yn)) / 2);
	die "smd: pooled standard deviation is zero\n" if $denom == 0;
	return (mean($xn) - mean($yn)) / $denom;
}

# _xtab(\@a, \@b) -> (\@table, \@rowlevels, \@collevels): contingency table
# from two parallel categorical vectors (rows = levels of a, cols = levels of b).
sub _xtab {
	my ($a, $b) = @_;
	die "cramers_v: the two vectors must have the same length\n"
		unless @$a == @$b;
	my (%rseen, %cseen, %cell);
	for my $i (0 .. $#$a) {
		next unless defined $a->[$i] && defined $b->[$i];
		my ($r, $c) = ("$a->[$i]", "$b->[$i]");
		$rseen{$r}++; $cseen{$c}++; $cell{$r}{$c}++;
	}
	my @rl = sort keys %rseen;
	my @cl = sort keys %cseen;
	my @tab = map { my $r = $_; [ map { $cell{$r}{$_} // 0 } @cl ] } @rl;
	return (\@tab, \@rl, \@cl);
}

# cramers_v(\@table)  or  cramers_v(\@x, \@y)
#
# Cramer's V for an r x c contingency table (uncorrected Pearson chi-square),
# with the Bergsma (2013) bias-corrected variant.  Accepts either a table
# (array of array refs of counts) or two parallel categorical vectors.
sub cramers_v {
	my @args = @_;
	my $tab;
	if (ref $args[0] eq 'ARRAY' && ref $args[0][0] eq 'ARRAY') {
		$tab = $args[0];
	} elsif (ref $args[0] eq 'ARRAY' && ref $args[1] eq 'ARRAY') {
		($tab) = _xtab($args[0], $args[1]);
	} else {
		die "cramers_v: expected a count table or two parallel vectors\n";
	}
	my $r = scalar @$tab;
	die "cramers_v: table needs at least two rows and columns\n" if $r < 2;
	my $c = scalar @{ $tab->[0] };
	die "cramers_v: table needs at least two rows and columns\n" if $c < 2;
	my (@rsum, @csum, $N);
	for my $i (0 .. $r - 1) {
		die "cramers_v: ragged table\n" unless @{ $tab->[$i] } == $c;
		for my $j (0 .. $c - 1) {
			my $v = $tab->[$i][$j];
			die "cramers_v: counts must be non-negative numbers\n"
				unless defined $v && looks_like_number($v) && $v >= 0;
			$rsum[$i] += $v; $csum[$j] += $v; $N += $v;
		}
	}
	die "cramers_v: table total is zero\n" unless $N;
	my $chi = 0;
	for my $i (0 .. $r - 1) {
		for my $j (0 .. $c - 1) {
			my $e = $rsum[$i] * $csum[$j] / $N;
			next unless $e > 0;
			my $diff = $tab->[$i][$j] - $e;
			$chi += $diff * $diff / $e;
		}
	}
	my $mindim = ($r < $c ? $r : $c) - 1;
	my $v = sqrt($chi / ($N * $mindim));
	# Bergsma bias-corrected V
	my $phi2  = $chi / $N;
	my $phi2c = $phi2 - ($c - 1) * ($r - 1) / ($N - 1);
	$phi2c = 0 if $phi2c < 0;
	my $rc = $r - ($r - 1) ** 2 / ($N - 1);
	my $cc = $c - ($c - 1) ** 2 / ($N - 1);
	my $mc = ($rc < $cc ? $rc : $cc) - 1;
	my $vc = $mc > 0 ? sqrt($phi2c / $mc) : 0;
	return {
		estimate       => $v,
		bias_corrected => $vc,
		chisq          => $chi,
		df             => ($r - 1) * ($c - 1),
		n              => $N,
	};
}

# eta_squared($aov_result)  or  eta_squared(\@values, \@groups)
#
# Eta-squared, partial eta-squared and omega-squared for a one-way design,
# from the ANOVA sums of squares.  Accepts an aov() result hash (single factor)
# or raw values + group labels.
sub eta_squared {
	my @args = @_;
	my $aov_res;
	if (ref $args[0] eq 'HASH') {
		$aov_res = $args[0];
	} elsif (ref $args[0] eq 'ARRAY' && ref $args[1] eq 'ARRAY') {
		die "eta_squared: values and groups must have the same length\n"
			unless @{ $args[0] } == @{ $args[1] };
		$aov_res = aov({ __value => $args[0], __group => $args[1] }, '__value ~ __group');
	} else {
		die "eta_squared: expected an aov() result or (\\\@values, \\\@groups)\n";
	}
	my $resid = $aov_res->{Residuals}
		or die "eta_squared: not an ANOVA result (no Residuals term)\n";
	my $ss_resid = $resid->{'Sum Sq'};
	my $ms_resid = $resid->{'Mean Sq'};
	# the single non-Residuals effect term
	my ($term) = grep { $_ ne 'Residuals' && ref $aov_res->{$_} eq 'HASH'
		&& exists $aov_res->{$_}{'Sum Sq'} } sort keys %$aov_res;
	die "eta_squared: could not find an effect term\n" unless defined $term;
	my $ss_eff = $aov_res->{$term}{'Sum Sq'};
	my $df_eff = $aov_res->{$term}{'Df'};
	my $ss_tot = $ss_eff + $ss_resid;
	return {
		term            => $term,
		eta_sq          => $ss_eff / $ss_tot,
		partial_eta_sq  => $ss_eff / ($ss_eff + $ss_resid),
		omega_sq        => ($ss_eff - $df_eff * $ms_resid) / ($ss_tot + $ms_resid),
	};
}

# _qnorm($p): standard-normal quantile (Acklam's rational approximation,
# ~1e-9 accuracy) for the Perl-level effect-size CIs.
sub _qnorm {
	my $p = shift;
	return -9**9**9 if $p <= 0;
	return  9**9**9 if $p >= 1;
	my @a = (-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
	          1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00);
	my @b = (-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
	          6.680131188771972e+01, -1.328068155288572e+01);
	my @c = (-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
	         -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00);
	my @d = (7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
	         3.754408661907416e+00);
	my $plow  = 0.02425;
	my $phigh = 1 - 0.02425;
	my ($q, $r, $x);
	if ($p < $plow) {
		$q = sqrt(-2 * log($p));
		$x = ((((($c[0]*$q+$c[1])*$q+$c[2])*$q+$c[3])*$q+$c[4])*$q+$c[5]) /
		     (((($d[0]*$q+$d[1])*$q+$d[2])*$q+$d[3])*$q+1);
	} elsif ($p <= $phigh) {
		$q = $p - 0.5; $r = $q * $q;
		$x = ((((($a[0]*$r+$a[1])*$r+$a[2])*$r+$a[3])*$r+$a[4])*$r+$a[5])*$q /
		     ((((($b[0]*$r+$b[1])*$r+$b[2])*$r+$b[3])*$r+$b[4])*$r+1);
	} else {
		$q = sqrt(-2 * log(1 - $p));
		$x = -((((($c[0]*$q+$c[1])*$q+$c[2])*$q+$c[3])*$q+$c[4])*$q+$c[5]) /
		      (((($d[0]*$q+$d[1])*$q+$d[2])*$q+$d[3])*$q+1);
	}
	return $x;
}

# ----------------------------------------------------------------------------
# Regression diagnostics (Perl level).  Validated numerically against R.
#
# _lgamma/_igamc/_pchisq_upper used to be pure-Perl ports of the XS igamc()
# living here.  They are now XS (see LikeR.xs), so there is one implementation
# instead of two that could disagree; _lgamma went away entirely because only
# _igamc ever called it.
# ----------------------------------------------------------------------------

# _quantile7(\@sorted_ascending, $p): R's default (type 7) sample quantile.
sub _quantile7 {
	my ($s, $p) = @_;
	my $n = scalar @$s;
	return $s->[0] if $n == 1;
	my $h = ($n - 1) * $p;
	my $lo = int($h);
	my $hi = $lo + 1 < $n ? $lo + 1 : $lo;
	return $s->[$lo] + ($h - $lo) * ($s->[$hi] - $s->[$lo]);
}

# vif($data, $formula_or_predictors)
#
# Variance inflation factors for the numeric predictors of a linear model:
# VIF_j = 1 / (1 - R^2_j), where R^2_j comes from regressing predictor j on all
# the others.  The second argument is either a formula string (its right-hand
# side terms are used) or an array reference of predictor column names.  Returns
# a hash of predictor => VIF.  (Numeric predictors only; categorical predictors
# would require a generalized VIF.)
sub vif {
	my ($data, $spec) = @_;
	die "vif: first argument must be a data reference\n" unless ref $data;
	my @preds;
	if (ref $spec eq 'ARRAY') {
		@preds = @$spec;
	} elsif (!ref $spec) {
		my ($rhs) = $spec =~ /~\s*(.*)$/
			or die "vif: expected a formula string or an array ref of predictors\n";
		$rhs =~ s/\s+//g;
		@preds = grep { length && $_ ne '1' && $_ ne '-1' } split /\+/, $rhs;
	} else {
		die "vif: expected a formula string or an array ref of predictors\n";
	}
	die "vif: need at least two predictors\n" if @preds < 2;
	my %out;
	for my $p (@preds) {
		my @others = grep { $_ ne $p } @preds;
		my $m = lm(formula => "$p ~ " . join(' + ', @others), data => $data);
		my $r2 = $m->{'r.squared'};
		$out{$p} = ($r2 >= 1) ? 9**9**9 : 1 / (1 - $r2);
	}
	return \%out;
}

# hosmer_lemeshow(\@observed, \@predicted, g => 10)
#
# Hosmer-Lemeshow goodness-of-fit test for a logistic model.  Observations are
# grouped into `g` bins by risk deciles of the predicted probabilities (R's
# cut() on type-7 quantiles, as in ResourceSelection::hoslem.test); the statistic
# compares observed and expected event counts per bin.  df = g - 2.
sub hosmer_lemeshow {
	my ($obs, $pred, %opt) = @_;
	die "hosmer_lemeshow: observed and predicted must be array references\n"
		unless ref $obs eq 'ARRAY' && ref $pred eq 'ARRAY';
	die "hosmer_lemeshow: observed and predicted must have the same length\n"
		unless @$obs == @$pred;
	my $g = defined $opt{g} ? $opt{g} : 10;
	die "hosmer_lemeshow: g must be at least 3\n" if $g < 3;

	my (@y, @p);
	for my $i (0 .. $#$obs) {
		next unless defined $obs->[$i] && defined $pred->[$i]
			&& looks_like_number($obs->[$i]) && looks_like_number($pred->[$i]);
		push @y, $obs->[$i] + 0;
		push @p, $pred->[$i] + 0;
	}
	my $n = scalar @y;
	die "hosmer_lemeshow: not enough complete observations for g=$g groups\n" if $n < $g;

	my @sorted = sort { $a <=> $b } @p;
	my @breaks = map { _quantile7(\@sorted, $_ / $g) } 0 .. $g;

	my (@O1, @O0, @E1, @E0, @ng);
	$O1[$_] = $O0[$_] = $E1[$_] = $E0[$_] = $ng[$_] = 0 for 0 .. $g - 1;
	for my $i (0 .. $n - 1) {
		# cut(..., include.lowest = TRUE): first interval closed on the left,
		# every other interval left-open / right-closed.
		my $gi = $g - 1;
		for my $j (1 .. $g) { if ($p[$i] <= $breaks[$j]) { $gi = $j - 1; last } }
		$O1[$gi] += $y[$i];
		$O0[$gi] += 1 - $y[$i];
		$E1[$gi] += $p[$i];
		$E0[$gi] += 1 - $p[$i];
		$ng[$gi]++;
	}

	my ($chi, $used) = (0, 0);
	my @groups;
	for my $j (0 .. $g - 1) {
		next unless $ng[$j];
		$used++;
		$chi += ($O1[$j] - $E1[$j]) ** 2 / $E1[$j] if $E1[$j] > 0;
		$chi += ($O0[$j] - $E0[$j]) ** 2 / $E0[$j] if $E0[$j] > 0;
		push @groups, { n => $ng[$j], observed => $O1[$j], expected => $E1[$j] };
	}
	my $df = $g - 2;
	return {
		statistic => $chi,
		parameter => $df,
		p_value   => _pchisq_upper($chi, $df),
		groups    => $used,
		table     => \@groups,
	};
}

# _qgamma($p, $shape, $scale): quantile of the gamma distribution, found by
# inverting the regularized lower incomplete gamma P(shape, x) = p (bisection).
sub _qgamma {
	my ($p, $shape, $scale) = @_;
	$scale = 1 unless defined $scale;
	return 0 if $p <= 0 || $shape <= 0;
	return 9**9**9 if $p >= 1;
	my ($lo, $hi) = (0, 1);
	$hi *= 2 while (1 - _igamc($shape, $hi)) < $p && $hi < 1e15;
	for (1 .. 300) {
		my $mid = ($lo + $hi) / 2;
		if ((1 - _igamc($shape, $mid)) < $p) { $lo = $mid } else { $hi = $mid }
		last if ($hi - $lo) <= 1e-12 * ($hi + 1e-300);
	}
	return $scale * ($lo + $hi) / 2;
}

# age_standardize(\@count, \@pop, \@stdpop, conf_level => 0.95, per => 1)
#   or age_standardize(count => \@c, pop => \@n, stdpop => \@w, ...)
#   (supply rate => \@r instead of count if you have stratum-specific rates)
#
# Directly standardized rate: reweights stratum-specific rates to a standard
# population.  The confidence interval uses the Fay-Feuer gamma method (as in
# R's epitools::ageadjust.direct), which is accurate even for rare events.
# `per` scales every reported rate (e.g. per => 100_000).  Validated against R.
sub age_standardize {
	my @a = @_;
	my (%opt, $count, $pop, $stdpop, $rate);
	if (ref $a[0] eq 'ARRAY') {
		($count, $pop, $stdpop) = (shift @a, shift @a, shift @a);
		%opt = @a;
	} else {
		%opt = @a;
		($count, $pop, $stdpop, $rate) = @opt{qw(count pop stdpop rate)};
	}
	$rate ||= $opt{rate};
	my $cl  = defined $opt{conf_level} ? $opt{conf_level}
	        : defined $opt{'conf.level'} ? $opt{'conf.level'} : 0.95;
	my $per = defined $opt{per} ? $opt{per} : 1;
	die "age_standardize: conf.level must be between 0 and 1\n" unless $cl > 0 && $cl < 1;
	die "age_standardize: 'pop' and 'stdpop' array refs are required\n"
		unless ref $pop eq 'ARRAY' && ref $stdpop eq 'ARRAY';
	die "age_standardize: supply either 'count' or 'rate'\n"
		unless ref $count eq 'ARRAY' || ref $rate eq 'ARRAY';

	my $k = scalar @$pop;
	die "age_standardize: pop and stdpop must have the same length\n" unless @$stdpop == $k;
	if (ref $count eq 'ARRAY') { die "age_standardize: count and pop length mismatch\n" unless @$count == $k; }
	else                       { die "age_standardize: rate and pop length mismatch\n"  unless @$rate  == $k; }

	my @cnt = ref $count eq 'ARRAY' ? @$count : map { $rate->[$_] * $pop->[$_] } 0 .. $k - 1;
	my ($sum_c, $sum_n, $sum_w) = (0, 0, 0);
	$sum_c += $cnt[$_],    $sum_n += $pop->[$_], $sum_w += $stdpop->[$_] for 0 .. $k - 1;
	die "age_standardize: total population and standard population must be positive\n"
		unless $sum_n > 0 && $sum_w > 0;

	my ($dsr, $var, $wmax) = (0, 0, 0);
	for my $i (0 .. $k - 1) {
		die "age_standardize: stratum $i has non-positive population\n" if $pop->[$i] <= 0;
		my $r  = $cnt[$i] / $pop->[$i];
		my $wt = $stdpop->[$i] / $sum_w;               # normalized weight
		$dsr += $wt * $r;
		$var += $wt * $wt * $cnt[$i] / ($pop->[$i] ** 2);
		my $w_over_n = $wt / $pop->[$i];
		$wmax = $w_over_n if $w_over_n > $wmax;
	}
	my $crude = $sum_c / $sum_n;

	my $alpha = 1 - $cl;
	my ($lci, $uci);
	if ($dsr > 0 && $var > 0) {
		$lci = _qgamma($alpha / 2, ($dsr ** 2) / $var, $var / $dsr);
		$uci = _qgamma(1 - $alpha / 2, (($dsr + $wmax) ** 2) / ($var + $wmax ** 2),
		               ($var + $wmax ** 2) / ($dsr + $wmax));
	} else {
		$lci = 0;
		$uci = ($dsr == 0) ? _qgamma(1 - $alpha / 2, 1, $wmax > 0 ? $wmax : 0) : $dsr;
	}

	return {
		crude_rate   => $crude * $per,
		adj_rate     => $dsr * $per,
		'conf.int'   => [ $lci * $per, $uci * $per ],
		se           => sqrt($var) * $per,
		'conf.level' => $cl,
		per          => $per,
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stats::LikeR - Get basic statistical functions, like in R, but with Perl using XS for performance

=head1 VERSION

version 0.298

=head1 Synopsis

Get basic statistical functions working in Perl as if they were part of List::Util, like C<min>, C<max>, C<sum>, etc.
I've used Artificial Intelligence tools such as Claude, Gemini, and Grok to write this as well as using my own gray matter.
There are other similar tools on CPAN, but I want speed and a form like List::Util, which I've gotten here with the help of AI, which often required many attempts to do correctly.
This is meant to call subroutines directly through eXternal Subroutines (XS) for performance and portability.

There B<are> other modules on CPAN that can do B<PARTS> of this, but this works the way that I B<want> it to.

=head1 Getting help

C<h> prints any function's section of this document to C<STDOUT> and returns, in
the spirit of R's C<?function> at the prompt. It takes the name three ways:

 h('quantile');    # by name
 h(*quantile);     # by name, unquoted
 h(\&quantile);    # by reference
 h();              # this section, and the list of documented functions

 perl -MStats::LikeR -e 'h(*agg)'   # straight from the shell

C<h> works for every function in the distribution looking the name up in the module's own POD rather than watching an argument list. That POD is generated from this file, so what C<h>
prints is what you are reading.

Note that C<h(bedroc)>, with no quotes and no sigil, cannot be made to work:
every function here is exported, so Perl parses the bareword as a call to
C<bedroc()> before C<h> is ever reached. Use one of the three forms above.

=head1 Functions/Subroutines

=head2 add_data

Add data to an existing hash or array reference. This function acts as the equivalent of adding new rows, as well as an C<ljoin> (described below). It dynamically infers your target data structure, handles deeply nested records, and seamlessly coerces mismatched data shapes to preserve the structural integrity of your primary reference.

=head3 Hash of Hashes (HoH)

When the target is a Hash of Hashes, incoming hash keys update existing rows, and new keys create new rows.

 $data = { 'Jack Smith' => { age => 30 } };

 $n = { 
     'Jack Smith' => {    # Update existing (Hash)
         dept => 'Engineering'
      },
     'Jane Doe'   => { age => 25, dept => 'Sales' }, # Add new (Hash)
     'Invalid'    => 'Not a reference'               # Edge case safety
 };

 add_data($data, $n); 

B<Resulting Structure:>

 {
     "Jack Smith":  {
         "age":  30,
         "dept": "Engineering"
     },
     "Jane Doe":    {
         "age":  25,
         "dept": "Sales"
     }
 }

=head3 Hash of Arrays (HoA)

When the target is a Hash of Arrays, incoming arrays are pushed onto the existing arrays, appending the new elements, similarly to R's C<rbind>.

 $data = { 'Project Alpha' => [ 'task1', 'task2' ] };
 $n = {
     'Project Alpha' => [ 'task3' ],         # Appends to existing array
     'Project Beta'  => [ 'task1', 'task2' ] # Creates new array row
 };
 add_data($data, $n);

B<Resulting Structure:>

 {
     "Project Alpha": [ "task1", "task2", "task3" ],
     "Project Beta":  [ "task1", "task2" ]
 }

=head3 Array of Hashes / Arrays (AoH / AoA)

C<add_data> now natively supports Array references at the root level. When targeting an Array, it iterates through the source array and merges data at the corresponding indices.

 $data = [ 
     { id => 1, name => 'Alice' } 
 ];

 $n = [ 
     { role => 'Admin' },             # Updates index 0
     { id => 2, name => 'Bob' }       # Creates index 1
 ];

 add_data($data, $n);

B<Resulting Structure:>

 [
     { "id": 1, "name": "Alice", "role": "Admin" },
     { "id": 2, "name": "Bob" }
 ]

=head3 Advanced Structural Coercion & Cross-Merging

C<add_data> strictly enforces the primary structure of your target reference (determined by inspecting its outer and inner bounds). If you mix Array and Hash types, the function automatically coerces the incoming data to match the target.

B<1. Inner Coercion (Mixing Rows):>

=over

=item * B<Target is HoH:> Source Array rows are read in pairs and converted to key-value pairs.

=item * B<Target is HoA:> Source Hash rows are flattened into key-value pairs and pushed onto the array.

=back

B<2. Root-Level Coercion (Mixing Outer Containers):>

=over

=item * B<Target is Array, Source is Hash:> The function evaluates the Hash keys as numeric indices. (e.g., source key C<"0"> merges into target array index C<[0]>). Non-numeric keys are safely ignored.

=item * B<Target is Hash, Source is Array:> The function converts the Array indices into stringified Hash keys. (e.g., source array index C<[1]> merges into target hash key C<"1">).

=back

=head3 Source is a mixed Hash. Keys dictate the target array index!

 $n = {
     '0' => { y => 20 },                 # Merges into $data->[0]
     '1' => [ 'z', 30 ],                 # Array pair coerced to Hash, creates $data->[1]
     'ignored' => { k => 'v' }           # Ignored: cannot map to an array index
 };

 add_data($data, $n);

B<Resulting Structure strictly remains an Array of Hashes:>

 [
     { "x": 10, "y": 20 },
     { "z": 30 }
 ]

NB: If C<add_data> is called on a completely empty target reference (e.g., C<$data = {}> or C<$data = []>), it will intelligently infer the required inner structure (Hashes vs Arrays) by inspecting the first valid row of the source data.

=head2 age_standardize

Directly standardized rate: reweights stratum-specific rates (e.g. age-specific
disease rates) to a standard population so rates from populations with different
age structures can be compared. The confidence interval uses the Fay-Feuer gamma
method, matching R's C<epitools::ageadjust.direct>, and is accurate even for rare
events. Validated numerically against R.

 my @count  = (5, 20, 55, 60);       # events per age stratum
 my @pop    = (1000, 3000, 4000, 2000);  # person-time / population per stratum
 my @stdpop = (2000, 3000, 3000, 2000);  # standard population weights

 my $r = age_standardize(\@count, \@pop, \@stdpop, per => 100_000);
 printf "age-adjusted rate = %.1f per 100k (95%% CI %.1f-%.1f)\n",
     $r->{adj_rate}, $r->{'conf.int'}[0], $r->{'conf.int'}[1];

Arguments may be positional (C<count>, C<pop>, C<stdpop>) or named; pass C<rate>
instead of C<count> if you already have stratum-specific rates.

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>count</code></td>
  <td><code>ArrayRef</code></td>
  <td><i>(count or rate required)</i></td>
  <td>Event count per stratum.</td>
  <td><code>\@count</code></td>
</tr>
<tr>
  <td><code>rate</code></td>
  <td><code>ArrayRef</code></td>
  <td><i>(count or rate required)</i></td>
  <td>Stratum-specific rate (alternative to <code>count</code>).</td>
  <td><code>\@rate</code></td>
</tr>
<tr>
  <td><code>pop</code></td>
  <td><code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>Population / person-time per stratum.</td>
  <td><code>\@pop</code></td>
</tr>
<tr>
  <td><code>stdpop</code></td>
  <td><code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>Standard-population weight per stratum.</td>
  <td><code>\@stdpop</code></td>
</tr>
<tr>
  <td><code>conf.level</code></td>
  <td><code>Number</code></td>
  <td><code>0.95</code></td>
  <td>Confidence level for the gamma interval.</td>
  <td><code>0.90</code></td>
</tr>
<tr>
  <td><code>per</code></td>
  <td><code>Number</code></td>
  <td><code>1</code></td>
  <td>Scale factor applied to every reported rate.</td>
  <td><code>100_000</code></td>
</tr>
</tbody>
</table>

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>crude_rate</code></td>
  <td><code>Double</code></td>
  <td>Unadjusted overall rate (× <code>per</code>).</td>
  <td><code>1400.0</code></td>
</tr>
<tr>
  <td><code>adj_rate</code></td>
  <td><code>Double</code></td>
  <td>Directly standardized rate (× <code>per</code>).</td>
  <td><code>1312.5</code></td>
</tr>
<tr>
  <td><code>conf.int</code></td>
  <td><code>ArrayRef</code></td>
  <td>Fay-Feuer gamma <code>[lower, upper]</code> (× <code>per</code>).</td>
  <td><code>[1097.8, 1569.6]</code></td>
</tr>
<tr>
  <td><code>se</code></td>
  <td><code>Double</code></td>
  <td>Standard error of the standardized rate (× <code>per</code>).</td>
  <td></td>
</tr>
<tr>
  <td><code>conf.level</code></td>
  <td><code>Double</code></td>
  <td>Confidence level used.</td>
  <td><code>0.95</code></td>
</tr>
<tr>
  <td><code>per</code></td>
  <td><code>Number</code></td>
  <td>The scale factor applied.</td>
  <td><code>100000</code></td>
</tr>
</tbody>
</table>

=head2 agg

Split-apply-combine over a data frame: split the rows into groups, apply one or
more aggregators to chosen columns, and combine the results into a new frame.
This is the I<combine> half that C<group_by> (which only splits) leaves to you,
and the analog of pandas C<df.groupby(...).agg(...)>. With no C<by> it collapses
the whole frame to a single row, like pandas C<df.agg(...)>.

C<agg> accepts all four data-frame shapes and, by default, returns the same shape
it was given:

 AoA  [ [ .. ], [ .. ] ]      array of arrayrefs   (positional columns)
 AoH  [ { .. }, { .. } ]      array of hashrefs    (the read_table default)
 HoA  { c => [ .. ], .. }     hash of arrayrefs    (column-major)
 HoH  { r => { .. }, .. }     hash of hashrefs     (named rows)

For AoA the column identifiers in C<by> and in the C<agg> spec are integer
positions; for the other three shapes they are column names. The original frame
is never modified.

=head3 Usage

 use Stats::LikeR;

 # grouped, one aggregator per column
 my $out = agg($df, by => 'sex', agg => { wt => 'mean' });

 # grouped, several aggregators, several columns
 my $out = agg($df,
     by  => 'sex',
     agg => { wt => [ 'mean', 'sd' ], age => [ 'mean', 'count' ] },
 );

 # ungrouped: the whole frame becomes one row
 my $out = agg($df, agg => { wt => 'mean', age => 'count' });

 # group on two columns and emit a hash of hashes
 my $out = agg($df,
     by            => [ 'a', 'b' ],
     agg           => { v => 'sum' },
     'output.type' => 'hoh',
 );

=head3 Arguments

C<agg> takes the data frame first, then C<< name =E<gt> value >> pairs.

=over

=item * B<agg> (required) — a hashref mapping each column to an aggregator
I<spec>. A spec is one of: a single aggregator name (string), an arrayref of
names, or a coderef. See L</"Aggregators"> below.

=item * B<by> — a single column or an arrayref of columns to group on. Omit it to
aggregate the entire frame into one row.

=item * B<skipna> — C<1> (default) drops undef cells before a numeric aggregator
runs. C<0> makes any undef in a group poison the numeric result for that group
(the cell comes back undef), matching pandas C<skipna=False>. C<count>, C<n>,
C<nunique>, C<first>, and C<last> ignore this flag.

=item * B<sort> — C<1> (default) sorts the output groups by key (numerically when
every key looks like a number, otherwise as strings); C<0> keeps first-seen
order.

=item * B<output.type> — C<aoa>, C<aoh>, C<hoa>, or C<hoh>. Defaults to the same family
as the input frame.

=back

=head3 Aggregators

Named aggregators may be combined in any order per column:

=for html <table>
<thead>
<tr>
  <th>name</th>
  <th>result</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>mean</code></td>
  <td>arithmetic mean (needs ≥ 1 defined cell, else undef)</td>
</tr>
<tr>
  <td><code>median</code></td>
  <td>median (needs ≥ 1)</td>
</tr>
<tr>
  <td><code>sum</code></td>
  <td>sum (needs ≥ 1)</td>
</tr>
<tr>
  <td><code>sd</code></td>
  <td>sample standard deviation (needs ≥ 2, else undef)</td>
</tr>
<tr>
  <td><code>var</code></td>
  <td>sample variance (needs ≥ 2, else undef)</td>
</tr>
<tr>
  <td><code>min</code></td>
  <td>minimum (needs ≥ 1)</td>
</tr>
<tr>
  <td><code>max</code></td>
  <td>maximum (needs ≥ 1)</td>
</tr>
<tr>
  <td><code>count</code></td>
  <td>number of <i>defined</i> cells</td>
</tr>
<tr>
  <td><code>n</code></td>
  <td>number of cells, undef included</td>
</tr>
<tr>
  <td><code>nunique</code></td>
  <td>number of distinct defined cells</td>
</tr>
<tr>
  <td><code>first</code></td>
  <td>first defined cell (undef if none)</td>
</tr>
<tr>
  <td><code>last</code></td>
  <td>last defined cell (undef if none)</td>
</tr>
<tr>
  <td><code>mode</code></td>
  <td>modal defined cell; ties broken deterministically</td>
</tr>
</tbody>
</table>

The numeric aggregators call the module's functions of the same name, so they
inherit their precision. C<agg> filters undef itself before calling them, so they
never croak on missing cells. C<mode> is made deterministic: on a tie it returns
the smallest number, or the lowest string when the values are not numeric.

A B<coderef> may be supplied instead of a name for full control. It is called
once per group as C<< $code-E<gt>(\@cells) >>, where C<@cells> are every cell for that
column in the group B<including undef>, and must return a single scalar:

 # count the missing values in each group
 my $out = agg($df, by => 'sex', agg => {
     age => sub {
         my $cells = shift;
         scalar grep { !defined } @$cells;
     },
 });

=head3 Output shape and column naming

Output columns are laid out deterministically: the C<by> columns first, in the
order given, then the aggregated columns sorted (numerically for AoA integer
columns, otherwise as strings), each expanded over its aggregator list in the
order supplied.

A column reduced by a B<single> aggregator keeps its own name; reduced by
B<two or more> it becomes C<< E<lt>colE<gt>_E<lt>funcE<gt> >>:

 my $df = [
     { sex => 'M', wt => 70, age => 30    },
     { sex => 'F', wt => 60, age => 25    },
     { sex => 'M', wt => 80, age => 40    },
     { sex => 'F', wt => 55, age => undef },
 ];

 my $out = agg($df,
     by  => 'sex',
     agg => { wt => [ 'mean', 'sd' ], age => [ 'mean', 'count' ] },
 );

B<Resulting Structure> (AoH in, AoH out):

 [
     {
         sex       => 'F',
         wt_mean   => 57.5,
         wt_sd     => 3.53553390593274,
         age_mean  => 25,     # the undef age was skipped
         age_count => 1,      # count excludes the undef
     },
     {
         sex       => 'M',
         wt_mean   => 75,
         wt_sd     => 7.07106781186548,
         age_mean  => 35,
         age_count => 2,
     },
 ]

=head3 Ungrouped

Without C<by>, the frame collapses to one row:

 my $out = agg($df, agg => { wt => 'mean', age => 'count' });

 # [ { wt => 66.25, age => 3 } ]

=head3 Array of Arrays (AoA)

Columns are integer positions. Grouping on column 0 and reducing column 1:

 my $aoa = [ [ 'M', 70 ], [ 'F', 60 ], [ 'M', 80 ] ];
 my $out = agg($aoa, by => 0, agg => { 1 => [ 'mean', 'max' ] });

 # [ [ 'F', 60, 60 ], [ 'M', 75, 80 ] ]
 #     ^grp  ^mean ^max

The output row is positional: the C<by> columns first, then each aggregated
column in the plan order.

=head3 Hash of Hashes (HoH) output

With C<< output.type =E<gt> 'hoh' >> the row label is the group value; multiple C<by>
columns are joined with a dot, an ungrouped result is keyed C<all>, and a
collision is made unique with a C<.N> suffix.

 my $out = agg($df, by => 'sex', agg => { wt => 'mean' }, 'output.type' => 'hoh');

 # {
 #     F => { sex => 'F', wt => 57.5 },
 #     M => { sex => 'M', wt => 75   },
 # }

=head3 Missing values

By default (C<< skipna =E<gt> 1 >>) undef cells are removed before a numeric aggregator
runs, so a group of C<(60, 55)> with a third undef still yields the mean of the
two defined values. C<count> reports only defined cells while C<n> counts undef
too. With C<< skipna =E<gt> 0 >>, a group containing any undef returns undef for the
numeric aggregators (C<mean median sum sd var mode>); the counting and
positional aggregators are unaffected.

A group without enough data yields undef rather than an error: C<sd> and C<var>
need at least two defined cells, the other numeric aggregators need at least
one.

=head3 Errors

C<agg> dies (with a trailing newline, so the message prints cleanly) when:

=over

=item * the first argument is not an ARRAY or HASH ref;

=item * no C<agg> spec is given, or it is not a non-empty hashref;

=item * an unknown option is passed;

=item * an aggregator name is not recognized;

=item * an aggregator list for a column is empty;

=item * C<output.type> is not one of C<aoa>, C<aoh>, C<hoa>, C<hoh>;

=item * the trailing arguments are not C<< name =E<gt> value >> pairs.

=back

=head3 See also

C<group_by> (the split step), C<concat> / C<rbind> (row-binding frames),
C<dropna>, C<assign>, C<value_counts>.

=head2 anova

Sequential (Type-I) ANOVA table for a linear model, in the same shape C<aov>
returns. C<anova> fits C<response ~ terms>, then decomposes the model sum of
squares one term at a time, B<in formula order>, and F-tests each term
against the residual mean square.

 anova(
 {
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,     1,   1,   0,   0,   0]
 },
 'yield ~ ctrl');

returns

 {
     ctrl        {
         Df          1,
         "F value"   25.6000000000001,
         "Mean Sq"   1.70666666666667,
         "Pr(>F)"    0.00718232855871859,
         "Sum Sq"    1.70666666666667
     },
     Residuals   {
         Df          4,
         "Mean Sq"   0.0666666666666665,
         "Sum Sq"    0.266666666666666
     }
 }

Two-way (and higher) models use the C<*> operator, which implicitly evaluates
the main effects alongside the interaction (C<a * b> expands to C<a + b + a:b>;
C<a * b * c> to the full factorial C<a + b + c + a:b + a:c + b:c + a:b:c>):

 my $res_2way = anova($data_2way, 'len ~ supp * dose');

Bare string columns are treated as factors and treatment-coded (first level =
reference); numeric columns and C<I(x^2)> enter as single regressors. It is
robust against rank deficiency: collinear terms gracefully receive 0 degrees
of freedom and 0 sum of squares, matching R's behavior.

Given two or more formulas, C<anova> compares nested models instead and returns
an B<array ref> of rows, one per model in the order supplied — R's
C<anova(m1, m2, ...)>. Each row carries C<Res.Df>, C<RSS> and C<formula>; every row
after the first adds C<Df>, C<Sum of Sq>, C<F> and C<< Pr(E<gt>F) >>:

 my $tab = anova($data, 'y ~ x1', 'y ~ x1 + x2');
 printf "adding x2: F = %.4g, p = %.4g\n", $tab->[1]{F}, $tab->[1]{'Pr(>F)'};

Both forms evaluate C<< Pr(E<gt>F) >> in the upper tail of the F distribution rather
than as C<1 - pf(F, df1, df2)>; see
L</"F and z tail p-values">.

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>data_sv</code></td>
  <td><code>HashRef</code> or <code>ArrayRef</code></td>
  <td><i>(Required)</i></td>
  <td>The dataset. A Hash of Arrays (HoA, columns) or Array of Hashes (AoH, rows) — the same forms <code>aov</code>/<code>lm</code> accept.</td>
  <td></td>
</tr>
<tr>
  <td><code>formula_sv</code></td>
  <td><code>String</code></td>
  <td><i>(Required)</i></td>
  <td>Symbolic model <code>'response ~ rhs'</code>, with <code>+</code>, <code>:</code> and <code>*</code>. Unlike <code>aov</code>, <code>anova</code> does <b>not</b> auto-stack, so a formula is mandatory.</td>
  <td><code>'yield ~ N * P'</code></td>
</tr>
</tbody>
</table>

=head3 Output Variables

A single C<HashRef>; keys are the parsed term names, so the structure varies
with the formula.

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>(Term Name)</i></td>
  <td><code>HashRef</code></td>
  <td>ANOVA-table stats for each term (<code>'ctrl'</code>, <code>'N:P'</code>, …). <code>'Mean Sq'</code>, <code>'F value'</code> and <code>'Pr(&gt;F)'</code> are omitted for 0-df (aliased) terms.</td>
  <td><code>{'Df'=&gt;1,'Sum Sq'=&gt;14.2,'Mean Sq'=&gt;14.2,'F value'=&gt;25.81,'Pr(&gt;F)'=&gt;0.0004}</code></td>
</tr>
<tr>
  <td><code>Residuals</code></td>
  <td><code>HashRef</code></td>
  <td>Residual (error) statistics; never carries an F test.</td>
  <td><code>{'Df'=&gt;10,'Sum Sq'=&gt;5.5,'Mean Sq'=&gt;0.55}</code></td>
</tr>
</tbody>
</table>

=head3 C<anova> vs C<aov> — what's the difference?

For a B<single model they compute the identical Type-I table> — in R,
C<anova(lm(f))> and C<summary(aov(f))> return the same sums of squares, and the
same holds here (C<anova(\%d,'yield ~ ctrl')> reproduces the C<aov> table
above exactly). The difference is one of role, not arithmetic:

=over

=item * B<< C<aov> is the model-I<fitting> idiom for designed experiments. >> It leans
toward factors and balanced designs, and in this module it adds two
conveniences C<anova> deliberately leaves out: it can B<auto-stack> a named
list when you omit the formula (R's C<stack()> + C<Value ~ Group>), and it
returns a C<group_stats> block of per-group means and counts alongside the
table. Reach for C<aov> when your question is "do these treatment groups
differ, and what do the groups look like?"

=item * B<< C<anova> is the model-I<table> idiom. >> It always wants an explicit formula
and returns just the decomposition — nothing descriptive. Reach for it when
you already have a model in mind and only want its term-by-term SS /
F-tests, or when you want the leaner object to feed onward.

=back

In short: same numbers for one model; C<aov> is the richer "fit + describe"
call (and the only one that stacks), C<anova> is the minimal "give me the
table" call. Note that both are B<Type-I / sequential>, so term order in the
formula matters, and both share this module's C<pf>, so p-values agree with
C<oneway_test> and the rest of Stats::LikeR.

I<< (R's C<anova> generic can additionally compare several nested models,
C<anova(m1, m2)>, giving an F/LRT between them — a capability neither this
C<anova> nor C<aov> currently provides. Ask if that would be useful.) >>

=head2 aoh2h

Fold a two-column B<array-of-hashes> back down into a plain hash. This is the
reverse of L<C<h2aoh>|/"h2aoh">, and the two are exact opposites under their
defaults.

 my $h = aoh2h($aoh);
 my $h = aoh2h($aoh, var_name => 'gene', value_name => 'n');

One column supplies the keys, the other the values; every other column in the
row is ignored. R spells this C<tibble::deframe()>; pandas spells it
C<df.set_index('k')['v'].to_dict()>.

=head3 Arguments

C<$aoh> — an array ref of hash refs. Required. Every row has to be a hash ref
carrying both named columns.

Everything after it is C<< name =E<gt> value >> pairs:

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>var_name</code></td>
  <td><code>variable</code></td>
  <td>The column holding the keys.</td>
</tr>
<tr>
  <td><code>value_name</code></td>
  <td><code>value</code></td>
  <td>The column holding the values.</td>
</tr>
<tr>
  <td><code>duplicates</code></td>
  <td><code>die</code></td>
  <td>What to do when two rows carry the same key: <code>die</code> is fatal, <code>first</code> keeps the earliest row, <code>last</code> keeps the latest.</td>
</tr>
</tbody>
</table>

C<var_name> and C<value_name> must differ.

=head3 Returns

A hash ref mapping each row's C<var_name> cell to its C<value_name> cell. An
empty array ref gives back C<{}>.

Values are assigned across, so a value that is itself a reference is shared
with the input rather than cloned — the same shallow copy C<aoh2hoa> makes.

=head3 Example

 my $aoh = [
     { gene => 'TP53',  n => 12 },
     { gene => 'BRCA1', n =>  7 },
 ];
 my $h = aoh2h($aoh, var_name => 'gene', value_name => 'n');
 # { TP53 => 12, BRCA1 => 7 }

 # keep the last of a repeated key instead of dying
 my $last = aoh2h([ { variable => 'a', value => 1 },
                    { variable => 'a', value => 9 } ], duplicates => 'last');
 # { a => 9 }

=head3 Round trip

 is_deeply( aoh2h( h2aoh(\%h) ), \%h );   # true for any flat hash

The one thing that does not survive the trip is the I<type> of a key: Perl hash
keys are strings, so a numeric key comes back as the string that prints the
same way.

=head3 Errors

C<aoh2h> dies when the first argument is undefined or not an array ref, when the
options are not C<< name =E<gt> value >> pairs, when an option is unknown, when
C<var_name> equals C<value_name>, when C<duplicates> is not one of the three
allowed words, when a row is not a hash ref, when a row is missing either named
column, when a row's key cell is C<undef>, or — under the default
C<< duplicates =E<gt> 'die' >> — when two rows share a key. Every message names the
offending row by index.

=head3 See also

L<C<h2aoh>|/"h2aoh"> is the reverse. L</"C<aoh2hoh>"> also indexes rows by a
column, but keeps the whole row as the value instead of one cell.

=head2 aoh2hoa

C<aoh2hoa($aoh)> — transpose an B<array-of-hashes> (row-major) into a B<hash-of-arrays> (column-major).

 my $hoa = aoh2hoa([ { a => 1, b => 2 }, { a => 3 } ]);
 # $hoa = { a => [1, 3], b => [2, undef] }

Rows go in, columns come out: each distinct key across the input rows becomes one output column, and the values are gathered down that column in row order.

=head3 Arguments

C<$aoh> — an array ref of hash refs, one hash per row. This is the only argument, and it is required. Passing anything that is not an array ref is fatal:

 aoh2hoa({ a => 1 });   # dies: argument must be an arrayref of hashrefs

=head3 Returns

A hash ref of array refs. Each key is a column name (the union of all keys seen across the rows); each value is an array ref holding that column's cells. Every column has exactly C<scalar @$aoh> elements, so the result is rectangular even when the input is ragged.

=head3 Behavior

The column set is the B<union> of every row's keys — a key that appears in only some rows still produces a full-length column, with C<undef> in the rows that lacked it.

Each column is padded to exactly the row count. Cells missing from a given row come through as C<undef>, including trailing gaps (a column whose last contributing row is early still runs the full length). These absent cells are cheap holes in the array, not stored SVs.

Values are B<copied> (C<newSVsv>), so the returned structure is independent of the input — mutating C<$aoh> afterward won't disturb the result. The copy is shallow: a value that is itself a reference is copied the same way C<< $col-E<gt>[$i] = $row-E<gt>{$k} >> would, i.e. the ref is duplicated but its referent is shared.

Keys are handled SV-first (C<hv_iterkeysv> / C<hv_fetch_ent>), so UTF-8 and otherwise non-trivial hash keys round-trip correctly.

A row that is B<not> a hash ref is skipped rather than fatal: it contributes C<undef> to every column at its index. So a stray C<undef> or scalar in the input thins the columns at that position instead of dying.

=head3 Notes

The output column order follows hash iteration order and is therefore not guaranteed — sort the keys if you need a stable layout. Round-tripping through C<hoa2aoh> (or the reverse) reconstructs the data but not necessarily the original key/row ordering, and rows originally absent a key will gain it as an explicit C<undef>.

=head2 C<aoh2hoh>

Index an B<A>rray-B<o>f-B<H>ashes into a B<H>ash-B<o>f-B<H>ashes, keyed by the value of one column.

 my $hoh = aoh2hoh($aoh, $key);

Where C<aoh2hoa> I<transposes> rows into columns, C<aoh2hoh> I<indexes> rows by a chosen field, turning a sequential list into a lookup table. The chosen field is treated as a B<primary key>: it must be unique across the rows, and a repeat is fatal.

=head3 Signature

=for html <table>
<thead>
<tr>
  <th>Argument</th>
  <th>Type</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>$aoh</code></td>
  <td>arrayref</td>
  <td>The rows: an arrayref of hashrefs.</td>
</tr>
<tr>
  <td><code>$key</code></td>
  <td>scalar</td>
  <td>The column name whose value indexes each row.</td>
</tr>
</tbody>
</table>

Returns a hashref. Each top-level key is a row's C<< $row-E<gt>{$key} >> value; each value is a shallow copy of that row.

 my $rows = [
     { id => 'p1', kd => 12.4, chain => 'A' },
     { id => 'p2', kd =>  3.1, chain => 'B' },
 ];

 my $by_id = aoh2hoh($rows, 'id');
 # {
 #   p1 => { id => 'p1', kd => 12.4, chain => 'A' },
 #   p2 => { id => 'p2', kd =>  3.1, chain => 'B' },
 # }

 $by_id->{p2}{kd};   # 3.1 -- O(1) lookup instead of a linear scan

=head3 Semantics

These choices are the parts most worth keeping in mind, because the AoH->HoH mapping is ambiguous where a transpose is not.

B<Duplicate keys are fatal.> If two rows share the same key value, the call dies rather than silently dropping a row:

 aoh2hoh([ { id => 'a', x => 1 }, { id => 'a', x => 9 } ], 'id');
 # dies: aoh2hoh: duplicate key 'a' has >= 2 occurrences

This makes the chosen column an enforced primary key: the result is only returned if every row maps to a distinct bucket. If your data legitimately has repeats and you want to I<keep> them, you want a hash-of-arrays-of-rows instead -- a different return shape. If you want last-wins or first-wins collapse, dedup the input before calling.

B<The key column is retained> inside each inner hash (the copy is of the whole row). Drop it deliberately if you don't want the redundancy.

B<Shallow copy.> Inner hashes are fresh, so adding or removing keys on the output never touches the input. But a I<value> that is itself a reference is shared, exactly like C<< $out{$rk}{$_} = $row-E<gt>{$_} >>:

 my $shared = [ 1, 2, 3 ];
 my $out = aoh2hoh([ { id => 'a', data => $shared } ], 'id');
 push @{ $out->{a}{data} }, 4;   # $shared now has 4 elements too

A row that is not a hashref, or that lacks a defined value at C<$key>, is fatal.

B<Numeric vs string keys collide.> Hash keys are strings, so C<1> and C<"1"> map to the same bucket and therefore trip the duplicate-key die. Normalize the key column first if a row could carry both forms.

=head3 Use cases

B<Join / enrichment lookups.> Build an index once, then attach fields from one dataset onto another by shared id without an O(n*m) nested loop -- and the duplicate-key die guarantees the join side really is keyed uniquely:

 my $meta = aoh2hoh($pdb_metadata, 'pdb_id');
 for my $hit (@$results) {
     $hit->{resolution} = $meta->{ $hit->{pdb_id} }{resolution};
 }

B<Primary-key validation.> Because a repeat is fatal, the call doubles as an assertion that a column is unique -- a cheap way to catch a malformed table (duplicate accession, duplicate peptide id) at load time rather than downstream.

B<Random-access reshaping of tabular data.> After parsing a CSV/TSV into an array of row-hashes, re-index by a primary key so downstream code can fetch a row by name rather than scanning. Pairs naturally with the CSV-parsing side of the toolkit.

B<Set membership and difference.> C<< exists $hoh-E<gt>{$k} >> gives a cheap presence test, useful for asking which ids in one table are missing from another.

=head3 Relationship to C<aoh2hoa>

=for html <table>
<thead>
<tr>
  <th>Function</th>
  <th>Output shape</th>
  <th>Indexed by</th>
  <th>Typical question it answers</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>aoh2hoa</code></td>
  <td>hash of arrayrefs</td>
  <td>column name</td>
  <td>"give me every value in column X"</td>
</tr>
<tr>
  <td><code>aoh2hoh</code></td>
  <td>hash of hashrefs</td>
  <td>a row's key val</td>
  <td>"give me the whole row whose id is Y"</td>
</tr>
</tbody>
</table>

Reach for C<aoh2hoa> when you want columns (vectors to feed a statistic or a plot); reach for C<aoh2hoh> when you want addressable rows keyed by a unique field.

=head2 aov

Warning: assumes normal distribution

 aov(
 {
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,     1,   1,   0,   0,   0]
 },
 'yield ~ ctrl');

which returns

 {
     ctrl        {
         Df          1,
         "F value"   25.6000000000001,
         "Mean Sq"   1.70666666666667,
         Pr(>F)      0.00718232855871859,
         "Sum Sq"    1.70666666666667
     },
     Residuals   {
         Df          4,
         "Mean Sq"   0.0666666666666665,
         "Sum Sq"    0.266666666666666
    }
 }

You can also perform Two-Way ANOVA with categorical interactions using the C<*> operator. The parser will implicitly evaluate the main effects alongside the interaction:

 my $res_2way = aov($data_2way, 'len ~ supp * dose');

It is robust against rank deficiency; collinear terms will gracefully receive 0 degrees of freedom and 0 sum of squares, matching R's behavior.

C<< Pr(E<gt>F) >> is evaluated in the upper tail of the F distribution rather than as
C<1 - pf(F, df1, df2)>, so a highly significant term reports its actual p-value
instead of a flat C<0>; see L</"F and z tail p-values">.

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>data_sv</code></td>
  <td><code>HashRef</code> or <code>ArrayRef</code></td>
  <td><i>(Required)</i></td>
  <td>The dataset to analyze. Accepts a Hash of Arrays (HoA) or Array of Hashes (AoH). If no formula is provided, it must be an HoA to allow automatic stacking (mimicking R's <code>stack()</code> on a named list).</td>
  <td></td>
</tr>
<tr>
  <td><code>formula_sv</code></td>
  <td><code>String</code></td>
  <td><code>undef</code></td>
  <td>A symbolic description of the model to be fitted. If omitted, the formula automatically defaults to <code>'Value ~ Group'</code> and the input data is stacked.</td>
  <td><code>'yield ~ N * P'</code></td>
</tr>
</tbody>
</table>

=head3 Output Variables

The function returns a single C<HashRef> containing the evaluated statistical results. Because the keys map dynamically to the terms parsed from your formula, the structure will vary based on your inputs.

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>(Term Name)</i></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash for each independent term in the formula (e.g., <code>'Group'</code>, <code>'N:P'</code>), containing its ANOVA table statistics.</td>
  <td><code>{'Df' =&gt; 1, 'Sum Sq' =&gt; 14.2, 'Mean Sq' =&gt; 14.2, 'F value' =&gt; 25.81, 'Pr(&gt;F)' =&gt; 0.0004}</code></td>
</tr>
<tr>
  <td><code>Residuals</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash containing the residual (error) statistics for the fitted model.</td>
  <td><code>{'Df' =&gt; 10, 'Sum Sq' =&gt; 5.5, 'Mean Sq' =&gt; 0.55}</code></td>
</tr>
<tr>
  <td><code>group_stats</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash containing descriptive statistics (<code>mean</code> and <code>size</code> / count) for every column evaluated in the original unstacked data structure.</td>
  <td><code>{'mean' =&gt; {'A' =&gt; 2.1, 'B' =&gt; 5.4}, 'size' =&gt; {'A' =&gt; 10, 'B' =&gt; 10}}</code></td>
</tr>
</tbody>
</table>

=head3 omitting formula

In the case of an omitted formula, stacking is done:

 aov(
 {
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,     1,   1,   0,   0,   0]
 },
 );

is the equivalent of:

 yield <- c(5.5, 5.4, 5.8, 4.5, 4.8, 4.2)
 ctrl <- c(1,     1,   1,   0,   0,   0)

 # Combine them into a named list (the R equivalent of your hash)
 my_list <- list(yield = yield, ctrl = ctrl)

 # Convert the list into a "long" dataframe
 # This creates two columns: "values" and "ind" (the group name)
 my_data <- stack(my_list)

 # Rename columns for clarity (optional but good practice)
 colnames(my_data) <- c("Value", "Group")
 anova_model <- aov(Value ~ Group, data = my_data)
 summary(anova_model)

in R

=head2 assign

Add new columns to a data frame, computed from the columns already there — or handed in ready-made.

=head3 Usage

 assign($df, new_name => VALUE, another => VALUE, ...);

=over

=item * B<< C<$df> >> — your data frame, in any of three shapes:

=over

=item * B<AoH> — arrayref of row hashrefs: C<< [ {weight=E<gt>70, height=E<gt>1.75}, ... ] >>

=item * B<HoA> — hashref of column arrayrefs: C<< { weight=E<gt>[70,...], height=E<gt>[1.75,...] } >>

=item * B<HoH> — hashref of row hashrefs, keyed by row name: C<< { Alice=E<gt>{weight=E<gt>65}, ... } >>

=back

=item * B<< C<< new_name =E<gt> VALUE >> >> — one or more pairs. C<VALUE> is a B<coderef> (computed from the row), an B<arrayref> (a ready-made column), or a B<< C<map_cell { ... }> >> block (an in-place edit of the named column — see below).

=back

It changes C<$df> in place and also returns it (handy for chaining).

=head3 Coderef values

A coderef is classified by what it returns in list context:

=over

=item * B<One scalar → per-row.> The sub is called once per row and that scalar is the cell.

=over

=item * C<$_> (and C<$_[0]>) is the current row as a hashref, so you read other columns with C<< $_-E<gt>{colname} >>.

=item * C<$_[1]> is the row's index (0-based).

=item * C<$_[2]> is the row key — B<HoH only>.

=item * A single arrayref return is stored I<as the cell>, so C<< sub { [split /,/, $_-E<gt>{tags}] } >> gives an arrayref-valued column.

=back

=item * B<A list of more than one value → whole column.> The list becomes the entire column, distributed positionally. This is the natural fit for column functions like C<rank>:

=back

 assign($df, 'ΔG rank' => sub { rank( vals($df, 'dG_kcal_mol') ) });
 # rank() returns a list, so the whole ranking lands in one column.

=head3 Arrayref values

Pass a column you already have and it is copied in:

 assign($df, 'ΔG rank' => [ rank( vals($df, 'dG_kcal_mol') ) ]);

This is also how you install a computed I<list> when you'd otherwise trip the "single arrayref = one cell" rule above.

=head3 In-place edits with C<map_cell>

A plain coderef stores its B<return value>, so an in-place transform of an existing column means the "copy, edit, return" dance — and C<s///r> isn't available on the older perls this module supports:

 # awkward: copy to $v, edit $v, return $v
 assign($df, 'Res.' => sub { (my $v = $_->{'Res.'}) =~ s/^[A-Z]://; $v });

C<map_cell { ... }> removes the ceremony. Inside the block, B<< C<$_> is the named column's current cell >> (not the whole row), the block's return value is B<ignored>, and the modified C<$_> is stored back:

 use Stats::LikeR;   # exports map_cell alongside assign

 assign($df, 'Res.' => map_cell { s/^[A-Z]:// });   # strip a leading "X:"
 assign($df, 'Res.' => map_cell { $_ = uc });        # upper-case in place

The row is still reachable as B<< C<$_[0]> >> for sibling columns, the index as B<< C<$_[1]> >>, and (HoH only) the row key as B<< C<$_[2]> >>:

 assign($df, label => map_cell { $_ = "$_[0]{name} ($_[1])" });

Notes:
- B<Undef cells pass through untouched> (undef in → undef out). The block never runs on an undefined or missing cell, so C<s///> and friends don't warn on uninitialized values and a missing cell stays missing rather than becoming C<''>.
- Works on all three shapes (AoH, HoA, HoH). For HoA the target column B<must already exist> (there's no column to edit otherwise) — C<map_cell> on a missing HoA column dies.
- A plain C<sub { ... }> keeps its existing meaning (C<$_> = the whole row, return value stored); C<map_cell> is purely additive and changes nothing for existing callers.

=head3 Ordering and length

=over

=item * B<AoH> distributes by array order; B<HoH> by B<sorted key order> — so any list you compute or hand in must be in C<sort keys %$df> order.

=item * Whole-column and arrayref values must have exactly one entry per row; a length mismatch dies.

=back

=head3 Example

 my $df = [
     { weight => 70, height => 1.75 },
     { weight => 90, height => 1.80 },
 ];
 assign($df, bmi => sub { $_->{weight} / $_->{height} ** 2 });
 # $df is now:
 # [ { weight=>70, height=>1.75, bmi=>22.86 },
 #   { weight=>90, height=>1.80, bmi=>27.78 } ]

=head3 Good to know

=over

=item * B<Pairs run in order>, so a later column can use one you just made:

=back

 assign($df,
     bmi   => sub { $_->{weight} / $_->{height} ** 2 },
     class => sub { $_->{bmi} > 25 ? 'high' : 'ok' },   # uses bmi
 );

=over

=item * B<Same recipe, all shapes.> The same per-row C<< sub { $_-E<gt>{weight} / ... } >> works for AoH, HoA, and HoH; you always read the row through C<$_>.

=item * B<It modifies your data frame.> If you need to keep the original, pass a copy: C<assign(clone($df), ...)>.

=item * Reusing a column name B<overwrites> that column.

=back

=head2 auc

The area under the ROC curve (the c-statistic) for scores and 0/1 labels: the
chance a random positive scores higher than a random negative. C<1.0> is perfect,
C<0.5> is a coin flip.

 use Stats::LikeR 'auc';

 my $auc = auc(\@scores, \@labels); # e.g. 0.848

Options: C<positive> (which label is the positive class, default C<1>) and
C<direction> (C<< 'E<gt>' >> = higher score is more positive, the default; C<< 'E<lt>' >> flips it).
For the full curve and a confidence interval, see L<C<roc>|/"roc">.

=head2 auroc

The same number as L<C<auc>|/"auc">, but with the argument order of Python's
C<sklearn.metrics.roc_auc_score> — B<labels first, scores second> — so code
ported from scikit-learn works unchanged. Higher score means the positive class.

 use Stats::LikeR 'auroc';

 my $a = auroc(\@labels, \@scores);          # like roc_auc_score(y, s)

Options: C<positive> (which label is the positive class, default C<1>) and
C<direction> (C<< 'E<lt>' >> treats a lower score as more positive, i.e. the same as
sklearn's C<roc_auc_score(y, -pred)>). It can also turn a numeric column into
labels for you: C<< cutoff =E<gt> x >> marks values C<< E<gt>= x >> as positive, or
C<< active_frac =E<gt> 0.1 >> with C<< active_side =E<gt> 'low'|'high' >> takes that fraction of
the extreme tail as positive.

=head2 bedroc

BEDROC — Boltzmann-Enhanced Discrimination of ROC (Truchon & Bayly, I<J. Chem.
Inf. Model.> 2007) — is an I<early-recognition> metric. Unlike L<C<auc>|/"auc">,
which weights a correct ranking equally everywhere, BEDROC rewards actives
(positives) that appear near the B<top> of a score-sorted list far more than
actives buried deep in it. That is what you want when only the first handful of
ranked candidates will ever be followed up (virtual screening, prioritised
review, triage). The result lies in C<[0, 1]>: C<1> is ideal early recognition,
C<0> is the worst possible ranking.

 use Stats::LikeR 'bedroc';

 my $r = bedroc(\@scores, \@labels, alpha => 20);
 print $r->{bedroc};             # e.g. 0.9989

C<@scores> is the ranking score for each item and the second array marks which
items are active. The single tuning knob is C<alpha>, the early-recognition
weight: larger C<alpha> concentrates the emphasis on a smaller top fraction of
the list. The Truchon–Bayly default is C<20> (roughly 80% of the score comes
from the top 8% of the ranking). Ties in the scores are resolved with average
(mid)ranks.

B<Easier to use than the usual Python implementations.> The common Python
recipes either demand a pre-built 0/1 label array (C<sklearn>-style
C<bedroc_score(y_true, scores)>) or hand-roll a bespoke "regression variant" in
each script that binarizes a continuous target by fraction. This C<bedroc> folds
both jobs into one call: hand it a raw numeric column and let C<cutoff> or
C<active_frac> (below) define the actives for you — no separate label-building
step, and it never dies just because you passed a continuous column where a 0/1
vector was expected. C<< active_frac =E<gt> 0.10, active_side =E<gt> 'low' >> reproduces the
Pep-PriML regression BEDROC (actives = strongest binders, the lowest-ΔG 10%) to
machine precision in a single line.

=head3 Options

=over

=item * B<< C<alpha> >> — early-recognition weight, must be C<< E<gt> 0 >> (default C<20>).

=item * B<< C<positive> >> — label value that marks an active, compared as a string
(default C<1>). Ignored when C<cutoff> is given.

=item * B<< C<cutoff> >> — instead of class labels, treat the second array as a numeric
column and count an item as active when its value is B<< C<< E<gt>= cutoff >> >>. Handy
when "active" is defined by a measured quantity (an affinity, a titre, an
expression level) rather than a pre-baked 0/1 label.

=item * B<< C<active_frac> >> (alias C<active>) — a fraction in C<(0, 1)>. Binarizes the
second array by marking the most extreme C<ceil(active_frac * n)> items as
active (see C<active_side>). This is the one-call convenience that removes the
"build a 0/1 label first" step; the count is clamped to C<[1, n-1]> so both
classes always exist and the call never dies for want of a label. Mutually
exclusive with C<cutoff>.

=item * B<< C<active_side> >> — which tail C<active_frac> takes: C<'high'> (default) marks
the B<largest> values active (matching C<cutoff>'s C<< E<gt>= >> sense); C<'low'> marks
the B<smallest> (e.g. actives = strongest binders when the column is ΔG).

=item * B<< C<direction> >> — C<< 'E<gt>' >> (default) means a higher score ranks first; C<< 'E<lt>' >>
flips it so lower scores rank first.

=item * B<< C<top> >> (alias C<fraction>) — a fraction in C<(0, 1]>. When given, the result
also reports classic enrichment in the top slice of the ranking (see below).

=back

=head3 Result keys

=over

=item * B<< C<bedroc> >> — the BEDROC score in C<[0, 1]>.

=item * B<< C<rie> >>, B<< C<rie_min> >>, B<< C<rie_max> >> — the underlying Robust Initial
Enhancement and its bounds for this C<alpha> and active fraction; BEDROC is
C<rie> rescaled onto C<[0, 1]>.

=item * B<< C<n> >>, B<< C<n_active> >>, B<< C<n_inactive> >> — counts.

=item * B<< C<ra> >> — the active fraction C<n_active / n>.

=item * B<< C<alpha> >>, B<< C<direction> >>, B<< C<method> >> — the settings used, echoed back.

=item * B<< C<enrichment> >> — present only when C<top> was given; a hashref with
C<fraction>, C<n_top> (compounds in the top slice, C<ceil(top * n)>),
C<active_count> (actives found there), C<expected> (actives expected by chance,
C<ra * n_top>), and C<enrichment_factor> (C<(active_count / n_top) / ra>).

=back

=head3 Examples

 # cutoff-defined actives (value >= 6.5) plus top-5% enrichment
 my $r = bedroc(\@scores, \@affinity,
     alpha  => 20,
     cutoff => 6.5,
     top    => 0.05);
 print $r->{bedroc};
 print $r->{enrichment}{enrichment_factor};   # e.g. 2.0 => 2x over random

 # fraction-defined actives straight from a raw ΔG column: the strongest-
 # binding 10% (lowest ΔG) are the actives, best predictions rank first.
 # No pre-built 0/1 label, no per-script regression variant.
 my $b = bedroc(\@predicted, \@delta_G,
     alpha       => 32.2,
     active_frac => 0.10,
     active_side => 'low',    # lowest ΔG = strongest binders = actives
     direction   => '<');     # lower predicted ΔG ranks first
 print $b->{bedroc};

 # lower score = better ranker
 bedroc(\@scores, \@labels, direction => '<');

 # string labels
 bedroc(\@scores, ['case','ctrl',...], positive => 'case');

Call C<h('bedroc')> for this section at the prompt. C<bedroc> also carries its own
short usage summary in XS, printed by C<bedroc('h')>, C<bedroc('H')> or
C<bedroc('?')>; it is the one function that reads its arguments that way. See
L</"Getting help">.

=head2 bfill

Back-fill NA (undef) cells with the next valid value seen below them along the
row axis, like C<pandas.DataFrame.bfill>. See C<ffill> for the forward direction
and C<fillna> for constant fills.

 bfill($df,
     cols  => [ 'v' ],   # restrict to these columns (default: every column)
     limit => 2,         # max consecutive fills per gap (default: unlimited)
 );

Column identifiers are names for AoH/HoA/HoH and 0-based positions for AoA. The
row axis is positional for AoA/AoH/HoA and string-sorted key order for HoH (the
only deterministic order a HoH has). Filling stays within each column's
existing length: ragged HoA columns are not extended, and AoA rows are not
extended past their own length.

C<limit> caps the number of consecutive NA cells filled in a single gap; the
remaining cells in an over-long gap stay NA, and the count resets after the
next real value. A trailing run of NA (with nothing below it) is left as NA.

Returns a NEW frame; the input is never modified.

=head3 Example

 bfill([ { v => undef }, { v => 2 }, { v => undef } ], cols => [ 'v' ]);
 # [ { v => 2 }, { v => 2 }, { v => undef } ]   # trailing NA stays

 bfill({ b => { x => undef }, a => { x => 5 }, c => { x => undef } }, cols => [ 'x' ]);
 # sorted-key order a,b,c; nothing after a to pull back, so:
 # { a => { x => 5 }, b => { x => undef }, c => { x => undef } }

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; a
C<cols> column that does not exist; or a C<limit> that is not a positive integer.

=head2 binom_test

C<binom_test> answers one question: you ran a yes/no experiment C<n> times and
got C<x> successes — is that consistent with some assumed success rate, or is it
too far off to be chance? It is the exact binomial test, the same as R's
C<binom.test>.

=head3 A toddler and two cards

Show a toddler two cards each round and ask him/her to point at the one with the
star. If he/she is only guessing, he/she will be right half the time, so the
"pure guessing" success rate is C<p = 0.5>.

You play 10 rounds and the toddler gets 6 right. Real skill, or just luck?

 use Stats::LikeR 'binom_test';

 my $r = binom_test(6, 10, p => 0.5); # 6 wins, 10 rounds, guessing rate 0.5

 print $r->{p_value};                 # 0.7539

The full result is a hashref:

 {
     statistic   => 6,            # times the toddler was right
     parameter   => 10,           # rounds played
     estimate    => 0.6,          # observed rate, 6/10
     null_value  => 0.5,          # the "pure guessing" rate we test against
     p_value     => 0.7539,
     conf_int    => [0.262, 0.878],
     conf_level  => 0.95,
     alternative => 'two.sided',
     method      => 'Exact binomial test',
 }

=head3 Reading the p-value

The p-value is the chance of seeing a result B<at least this surprising> if the
toddler were really just guessing.

Here C<p = 0.75> means no evidence of skill.

=head3 What "legit" would look like

Suppose the toddler had gone 9 for 10 instead:

 my $r = binom_test(9, 10, p => 0.5);

 print $r->{p_value};                   # 0.0215

Now C<p = 0.02>, under C<0.05>. A pure guesser almost never does that well, so
this B<is> good evidence the toddler can actually tell the cards apart.

=head3 The confidence interval

C<conf_int> is the plausible range for the toddler's true success rate. For
6/10 it runs from about C<0.26> to C<0.88> — wide, and it comfortably includes
C<0.5>. That overlap with the guessing rate is another way of seeing that luck
cannot be ruled out. For 9/10 the interval would sit well above C<0.5>.

=head3 Options

=over

=item * C<p> is the assumed success rate (default C<0.5>).

=item * C<alternative> is C<'two.sided'> (default), C<'less'>, or C<'greater'>. Use
C<'greater'> when you only care whether the toddler beats guessing, not
whether they do worse.

=item * C<conf_level> sets the interval width (default C<0.95>).

=back

You can also pass the counts as C<binom_test([6, 4])> — 6 right, 4 wrong — when
you have wins and losses instead of wins and a total.

=head2 cfilter

Select B<columns> out of a table and return it in the same shape. A column is
the inner (second-level) key of a B<hash of hashes> or an B<array of hashes>,
or the outer key of a B<hash of arrays>:

 use Stats::LikeR;
 my %hoa = ( x => [1,2,3], y => [4,5,6], z => [0,0,0] );
 cfilter(\%hoa, keep   => ['x','y']);  # { x => [1,2,3], y => [4,5,6] }
 cfilter(\%hoa, remove => ['z']);      # { x => [1,2,3], y => [4,5,6] }

C<cfilter> takes exactly one of C<keep> or C<remove>. C<keep> returns only the
matching columns; C<remove> returns everything except them. The result is the
same shape as the input (HoH → HoH, HoA → HoA, AoH → AoH), with cell values
copied and the original structure left untouched.

The selector — the value of C<keep> or C<remove> — can be given three ways:

=over

=item * an B<array ref> of exact column names,

=item * a B<< C<qr//> regex >> matched against column names,

=item * a B<predicate> (CODE ref or function name) evaluated against a column's
values.

=back

The first two select by name; the predicate is the one that looks at the data.

=head3 Selecting by name

Pass an array ref of column names. Naming a column that is not present in the
data is an error (it catches typos), and a row that happens not to contain a
kept column simply comes back without it:

 my @aoh = ( { a => 1, b => 2 }, { a => 3 } );
 cfilter(\@aoh, keep => ['b']);   # [ { b => 2 }, {} ]

=head3 Selecting by a name pattern

Pass a C<qr//> regex, and columns are kept (or removed) according to whether
their B<name> matches. This is the concise way to act on a family of columns:

 # drop every column whose name contains "step" or "bias_"
 cfilter(\%md, remove => qr/(?:step|bias_)/);
 # keep only the y0, y1, ... columns
 cfilter(\%md, keep => qr/^y\d+$/);

The pattern matches anywhere in the name (it is not anchored), exactly like
Perl's C<=~>. Unlike a named column, a pattern that matches nothing is not an
error — it simply keeps or removes nothing.

=head3 Selecting by a predicate

Instead of names, C<keep>/C<remove> accept a B<predicate> — a CODE ref or a
function name — evaluated once per column. It is called as

 $predicate->($column_values, $column_name)

where C<$column_values> is an array ref of the column's B<defined> cells (undef
and missing cells are dropped, so functions like C<sd> get clean input).
With C<keep>, columns for which the predicate is true are kept; with C<remove>,
those columns are dropped.

 # Keep only the constant columns (standard deviation zero):
 my $const = cfilter(\%hoa, keep => sub { sd($_[0]) == 0 });   # { z => [0,0,0] }
 # Drop the constant columns instead:
 my $varying = cfilter(\%hoa, remove => sub { sd($_[0]) == 0 }); # { x=>..., y=>... }
 # A bare function name resolves in Stats::LikeR:: (use a package for your own):
 cfilter(\%hoa, keep => 'some_predicate');

A bare string is always treated as a B<function name>, not a single column
name, so to keep one column by name use an array ref: C<< keep =E<gt> ['x'] >>.

=head3 Errors

C<cfilter> dies (via C<croak>) when:

=over

=item * neither C<keep> nor C<remove> is given, or both are,

=item * a named column is not present in the data,

=item * the selector is not an array ref, a C<qr//> regex, or a code ref / function
name, or the function name cannot be resolved,

=item * C<na> or C<against> is given with a by-name or regex selector (they apply only
to a value predicate),

=item * an unknown option is given, or the options are not C<< name =E<gt> value >> pairs,

=item * the data is not a hash/array reference of the expected shape (a hash of hash
refs or array refs, or an array of hash refs).

=back

=head2 chisq_test

The C<chisq_test> function performs chi-squared contingency table tests and goodness-of-fit tests. It natively accepts both arrays and hashes (1D and 2D) and mathematically mirrors R's C<chisq.test()>, returning a structured hash reference of the results.

For 2x2 matrices, Yates' Continuity Correction is applied automatically.

=head3 Signature

 my $res = chisq_test($data);
 my $res = chisq_test($data, correct     => 0);          # 2x2: no Yates' correction
 my $res = chisq_test($data, p           => $probs);     # goodness of fit against $probs
 my $res = chisq_test($data, p           => $weights,
                             'rescale.p' => 1);          # ... rescaled to sum to 1

=head3 Accepted Inputs

=for html <table>
<thead>
<tr>
  <th>Input Type</th>
  <th>Data Structure</th>
  <th>Applied Test</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>1D Array</b></td>
  <td><code>[ $v1, $v2, ... ]</code></td>
  <td>Chi-squared test for given probabilities</td>
</tr>
<tr>
  <td><b>2D Array</b></td>
  <td><code>[ [ $v1, $v2 ], [ $v3, $v4 ] ]</code></td>
  <td>Pearson's Chi-squared test (Yates' correction if 2x2)</td>
</tr>
<tr>
  <td><b>1D Hash</b></td>
  <td><code>{ key1 =&gt; $v1, key2 =&gt; $v2 }</code></td>
  <td>Chi-squared test for given probabilities</td>
</tr>
<tr>
  <td><b>2D Hash</b></td>
  <td><code>{ row1 =&gt; { c1 =&gt; $v1, c2 =&gt; $v2 } }</code></td>
  <td>Pearson's Chi-squared test (Yates' correction if 2x2)</td>
</tr>
</tbody>
</table>

Every entry must be a nonnegative, finite number, and at least one of them must be positive; anything else — an C<undef>, a string, a negative count, an infinity — is a fatal error rather than a silent zero, exactly as in R. A 2D array must not be ragged, and every row of a 2D hash must carry the same column keys.

A table with only one row or only one column is not a contingency table: as in R, it collapses to its cells and the goodness-of-fit test is run on them. So C<[[10, 20, 30]]> and C<[10, 20, 30]> give the same test, with C<df = 2> — not the vacuous C<df = 0>.

As in R, a warning is issued when any expected count falls below 5, the usual rule of thumb for the chi-squared approximation being trustworthy. Use L<C<fisher_test>|/"fisher_test"> for a small table.

=head3 Named Options

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>correct</b></td>
  <td><code>1</code></td>
  <td>Apply Yates' continuity correction. Only ever affects a 2x2 table, and is R's <code>correct</code>. Set to <code>0</code> for the uncorrected Pearson statistic.</td>
</tr>
<tr>
  <td><b>p</b></td>
  <td>uniform</td>
  <td>Null probabilities for the goodness-of-fit test. An array ref, in the order of the data, when the data is an array ref; a hash ref keyed the same as the data when the data is a hash ref. They must sum to 1 unless <code>rescale.p</code> says otherwise, and it is an error to pass them with a contingency table.</td>
</tr>
<tr>
  <td><b>rescale.p</b></td>
  <td><code>0</code></td>
  <td>Divide <code>p</code> by its own sum first, so counts, weights or percentages can be passed instead of probabilities. Also spelled <code>rescale_p</code>.</td>
</tr>
</tbody>
</table>

 # goodness of fit against a non-uniform null
 my $res = chisq_test([89, 37, 30, 28, 2],
                      p => [0.40, 0.20, 0.20, 0.19, 0.01]);
 # $res->{statistic}{'X-squared'} == 5.79470854555744, df 4, p == 0.215013095920786

 # the same, from unnormalised weights
 my $res = chisq_test([89, 37, 30, 28, 2],
                      p => [40, 20, 20, 19, 1], 'rescale.p' => 1);

 # keyed data takes keyed probabilities
 my $res = chisq_test({ A => 10, B => 20, C => 30 },
                      p => { A => 0.2, B => 0.3, C => 0.5 });

=head3 Output Object Structure

The function returns a single Hash Reference containing the following key-value pairs. The internal structure of C<expected> and C<observed> will always identically match the structure of your input.

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Data Type</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>data.name</b></td>
  <td>String</td>
  <td>Identifies the input type (e.g., <code>"Perl ArrayRef"</code> or <code>"Perl HashRef"</code>).</td>
</tr>
<tr>
  <td><b>expected</b></td>
  <td>Array/Hash Ref</td>
  <td>The expected frequencies, matching the geometry of the input.</td>
</tr>
<tr>
  <td><b>method</b></td>
  <td>String</td>
  <td>The specific statistical test applied.</td>
</tr>
<tr>
  <td><b>observed</b></td>
  <td>Array/Hash Ref</td>
  <td>The original data passed to the function.</td>
</tr>
<tr>
  <td><b>p.value</b></td>
  <td>Float</td>
  <td>The calculated p-value of the test.</td>
</tr>
<tr>
  <td><b>parameter</b></td>
  <td>Hash Ref</td>
  <td>Contains the degrees of freedom (<code>df</code>).</td>
</tr>
<tr>
  <td><b>statistic</b></td>
  <td>Hash Ref</td>
  <td>Contains the test statistic (<code>X-squared</code>).</td>
</tr>
</tbody>
</table>

=head3 Two-Dimensional Array

Passing an Array of Arrays (AoA) triggers a standard Pearson's Chi-squared test. If the input is exactly a 2x2 matrix, Yates' continuity correction is applied automatically.

 my $test_data = [
     [762, 327, 468], 
     [484, 239, 477]
 ];
 my $res = chisq_test($test_data);

B<Output:>

 {
     'data.name' => 'Perl ArrayRef',
     'expected'  => [
         [ 703.671381936888, 319.645266594124, 533.683351468988 ],
         [ 542.328618063112, 246.354733405876, 411.316648531012 ]
     ],
     'method'    => "Pearson's Chi-squared test",
     'observed'  => [
         [ 762, 327, 468 ],
         [ 484, 239, 477 ]
     ],
     'p.value'   => 2.95358918321176e-07,
     'parameter' => { 'df' => 2 },
     'statistic' => { 'X-squared' => 30.0701490957547 }
 }

=head3 1-Dimensional Array (Goodness of Fit)

Passing a flat Array Reference triggers a Goodness of Fit test, assuming equal expected probabilities across all items.

 my $data = [10, 20, 30];
 my $res = chisq_test($data);

B<Output:>

 {
     'data.name' => 'Perl ArrayRef',
     'expected'  => [ 20, 20, 20 ],
     'method'    => 'Chi-squared test for given probabilities',
     'observed'  => [ 10, 20, 30 ],
     'p.value'   => 0.00673794699908547,
     'parameter' => { 'df' => 2 },
     'statistic' => { 'X-squared' => 10 }
 }

=head3 2-Dimensional Hash (Pearson's Chi-squared)

Passing a Hash of Hashes (HoH) applies the exact same logic as a 2D Array, but preserves your nested string keys in the output. This is particularly useful when mapping data extracted directly from JSON, databases, or categorical mappings.

 my $data = {
     GroupA => { Success => 10, Failure => 15 },
     GroupB => { Success => 20, Failure => 5  }
 };

 my $res = chisq_test($data);

B<Output:>

 {
     'data.name' => 'Perl HashRef',
     'expected'  => {
     'GroupA' => { 'Failure' => 10, 'Success' => 15 },
     'GroupB' => { 'Failure' => 10, 'Success' => 15 }
 },
 'method'    => "Pearson's Chi-squared test with Yates' continuity correction",
     'observed'  => {
     'GroupA' => { 'Failure' => 15, 'Success' => 10 },
     'GroupB' => { 'Failure' => 5,  'Success' => 20 }
     },
     'p.value'   => 0.00937475878430379,
     'parameter' => { 'df' => 1 },
     'statistic' => { 'X-squared' => 6.75 }
 }

=head3 One-Dimensional Hash (Goodness of Fit)

Flat Hash References evaluate Goodness of Fit while preserving your categorical keys in the C<expected> and C<observed> output blocks.

 my $data = { 
     Apples  => 10, 
     Oranges => 20, 
     Bananas => 30 
 };

 my $res = chisq_test($data);

=head2 chunk

Split an array into contiguous, roughly equal groups by I<position>. Unlike
L<C<qcut>|/"qcut">, C<chunk> does not inspect values, sort, or compute cutpoints; it
slices the array in the order given. Use it for batching work, paginating, or
grouping non-numeric data such as strings.

=head3 Signature

 my @groups = chunk($data, size  => $n);   # fixed elements per group
 my @groups = chunk($data, parts => $k);   # fixed number of groups

=over

=item * C<$data> — an array reference. Its contents are never examined or sorted;
elements are grouped in input order.

=back

Pass exactly one of C<size> or C<parts>. Passing both, or neither, is a fatal
error — the two readings of "equal groups" differ (see below), so the caller
chooses which one is meant rather than relying on a default.

=over

=item * C<< size =E<gt> $n >> — each group holds C<$n> elements; the final group holds
whatever remains.

=item * C<< parts =E<gt> $k >> — the array is divided into C<$k> groups as equal as possible,
with any remainder spread across the leading groups.

=back

=head3 Return value

A list of array references, in input order — call it in list context:

 my @groups = chunk($data, parts => 4);

Passing more C<parts> than there are elements yields trailing empty groups
(matching C<numpy.array_split>), so no elements are ever dropped. An empty input
array returns an empty list.

=head3 Examples

C<size> fixes the elements per group; the last group is the remainder. Splitting
the 26 letters into groups of five leaves one over:

 my @groups = chunk(['a' .. 'z'], size => 5);
 # 6 groups, sizes 5,5,5,5,5,1
 # [a b c d e] [f g h i j] [k l m n o] [p q r s t] [u v w x y] [z]

C<parts> fixes the number of groups; the remainder is absorbed by the leading
groups instead:

 my @groups = chunk(['a' .. 'z'], parts => 5);
 # 5 groups, sizes 5,5,5,5,6
 # [a b c d e] [f g h i j] [k l m n o] [p q r s t] [u v w x y z]

When the split is even the two forms agree:

 my @a = chunk([1 .. 10], size  => 2);
 my @b = chunk([1 .. 10], parts => 5);
 # identical: 5 groups of 2

Order is preserved — C<chunk> never sorts. Sort the array yourself first if you
want ordered groups:

 my @groups = chunk([3, 1, 2], size => 2);
 # ([3, 1], [2])

More parts than elements gives empty trailing groups, losing nothing:

 my @groups = chunk([1, 2, 3], parts => 5);
 # 5 groups; flattening them back gives (1, 2, 3)

=head2 cmh_test

The Cochran–Mantel–Haenszel test: pool several 2×2 tables (one per I<stratum>)
into a single test of association while adjusting for the stratifying variable —
e.g. an exposure/outcome odds ratio adjusted for study site. Same as R's
C<mantelhaen.test>.

 use Stats::LikeR 'cmh_test';

 my $r = cmh_test([ [10,3,5,12],     # stratum 1 as [a,b,c,d]
                    [20,6,8,15],     # stratum 2
                    [ 7,4,9,11] ]);  # stratum 3

 print $r->{p_value};    # combined test across strata
 print $r->{estimate};   # Mantel–Haenszel common odds ratio

Each 2×2 uses the same layout as L<C<epi_2x2>|/"epi_2x2">. Options: C<correct>
(continuity correction, default C<1>) and C<conf_level> (default C<0.95>). The
result also has C<statistic> (chi-squared), C<parameter> (df = 1), C<conf_int> (for
the common OR), and C<k> (number of strata).

=head2 cohen_d

Cohen's I<d> effect size for the difference between two independent groups, using
the pooled standard deviation. It also returns the Hedges' I<g> small-sample
correction and a large-sample (normal-approximation) confidence interval.
Validated numerically against R.

 my $d = cohen_d(\@treatment, \@control);           # or conf_level => 0.90
 printf "d = %.2f (95%% CI %.2f–%.2f), Hedges g = %.2f\n",
     $d->{estimate}, $d->{'conf.int'}[0], $d->{'conf.int'}[1], $d->{hedges_g};

Compare with L</"smd">, which standardizes by the simple (unweighted) average
of the group variances and is the convention for covariate-balance tables.

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>estimate</code></td>
  <td><code>Double</code></td>
  <td>Cohen's <i>d</i> (mean₁ − mean₂ over the pooled SD).</td>
  <td><code>2.3146</code></td>
</tr>
<tr>
  <td><code>hedges_g</code></td>
  <td><code>Double</code></td>
  <td>Hedges' <i>g</i> (bias-corrected <i>d</i>).</td>
  <td><code>2.1668</code></td>
</tr>
<tr>
  <td><code>pooled_sd</code></td>
  <td><code>Double</code></td>
  <td>Pooled standard deviation.</td>
  <td><code>1.2344</code></td>
</tr>
<tr>
  <td><code>se</code></td>
  <td><code>Double</code></td>
  <td>Approximate standard error of <i>d</i>.</td>
  <td><code>0.6907</code></td>
</tr>
<tr>
  <td><code>conf.int</code></td>
  <td><code>ArrayRef</code></td>
  <td><code>[lower, upper]</code> normal-approximation CI for <i>d</i>.</td>
  <td><code>[0.96, 3.67]</code></td>
</tr>
<tr>
  <td><code>conf.level</code></td>
  <td><code>Double</code></td>
  <td>Confidence level used.</td>
  <td><code>0.95</code></td>
</tr>
<tr>
  <td><code>n1</code>, <code>n2</code></td>
  <td><code>Integer</code></td>
  <td>Group sizes.</td>
  <td><code>7</code>, <code>7</code></td>
</tr>
</tbody>
</table>

=head2 col2col

Apply a B<two-column function> to every pair of columns in a table and collect
the answers in a hash of hashes.

It's the workhorse behind things like correlation matrices: give it your data and
the name of a function that takes two columns (C<cor>, C<t_test>, …) and you get
back every column compared against every other column.

 use Stats::LikeR;

 my %data = (
     height => [ 170, 165, 180, 175 ],
     weight => [  70,  60,  85,  77 ],
     age    => [  30,  41,  25,  38 ],
 );

 my $result = col2col(\%data, 'cor');

 # $result->{height}{weight}  == correlation of height vs weight
 # $result->{height}{age}     == correlation of height vs age
 # ...and so on for every pair

========================================================================

=head3 Arguments

 col2col( $data, $command, $cols, %options )
 col2col( $data, $command, \%options )      # options in place of $cols

=for html <table>
<thead>
<tr>
  <th>Position</th>
  <th>Argument</th>
  <th>What it is</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>$data</code></td>
  <td>Your table, as a reference (see <b>Data shapes</b> below).</td>
</tr>
<tr>
  <td>2</td>
  <td><code>$command</code></td>
  <td>A code block <b>or</b> the name of a two-column function.</td>
</tr>
<tr>
  <td>3</td>
  <td><code>$cols</code></td>
  <td><i>(optional)</i> Which columns to use as the "from" side. Omit for all.</td>
</tr>
<tr>
  <td>4+</td>
  <td><code>%options</code></td>
  <td><i>(optional)</i> <code>na</code>, <code>skip.errors</code>, … (see <b>Options</b>).</td>
</tr>
</tbody>
</table>

========================================================================

=head3 Data shapes

C<col2col> understands three layouts. In every case a B<column> is the thing that
gets compared, and the result is keyed by column name.

B<Hash of arrays (HoA)> — keys are column names:

 my %hoa = ( a => [1, 2, 3], b => [4, 5, 6] );

B<Hash of hashes (HoH)> — First keys are row names, second keys are columns:

 my %hoh = (
     row1 => { a => 1, b => 4 },
     row2 => { a => 2, b => 5 },
 );

B<Array of hashes (AoH)> — each element is a row, inner keys are columns:

 my @aoh = ( { a => 1, b => 4 }, { a => 2, b => 5 } );

All three produce the same result for the same underlying numbers. Missing or
C<undef> cells are handled by the C<na> option (below).

========================================================================

=head3 The command

The second argument is the function applied to each pair of columns. It is called
as:

 $command->( $column_a, $column_b )    # two ARRAY refs

so inside a block the two columns arrive in C<@_>:

 my $result = col2col(\%data, sub {
     my ($x, $y) = @_;       # $x and $y are array refs
     cor($x, $y);
 });

You can also pass a B<function name as a string>. A bare name is looked up in
C<Stats::LikeR::>, so these two are equivalent:

 col2col(\%data, 'cor');
 col2col(\%data, sub { cor($_[0], $_[1]) });

========================================================================

=head3 The result

Always a hash of hashes: B<< C<< $result-E<gt>{from}{to} >> >>.

 for my $from (sort keys %$result) {
    for my $to (sort keys %{ $result->{$from} }) {
       printf "%s vs %s = %s\n", $from, $to, $result->{$from}{$to};
    }
 }

A column is never compared with itself, so C<< $result-E<gt>{a}{a} >> does not exist.

========================================================================

=head3 Restricting columns (C<$cols>)

By default every column is used as the "from" side. The third argument narrows
that down — handy when you only care about one variable.

 # all columns vs all columns
 my $all = col2col(\%data, 'cor');
 # just ONE column vs every other column
 my $one = col2col(\%data, 'cor', 'height');
 my $cors = $one->{height};          # { weight => ..., age => ... }
 # a FEW specific columns vs every other column
 my $few = col2col(\%data, 'cor', ['height', 'weight']);

The "to" side is always every other column; C<$cols> only limits the outer keys.

========================================================================

=head3 Options

Options can be given two ways:

 col2col(\%data, 'cor', $cols, 'skip.errors' => 0);   # after $cols
 col2col(\%data, 'cor', { 'skip.errors' => 0 });      # hash ref, no $cols needed

The hash-ref form is convenient when you have B<no> column restriction — it saves
you from passing a placeholder. (A hash ref I<replaces> C<$cols>, so you can't use
it to restrict columns at the same time; use the trailing form for that.)

=head4 C<na> — how undefined values are handled

Real data has gaps. C<na> decides what the function sees.

=for html <table>
<thead>
<tr>
  <th>Value</th>
  <th>Behaviour</th>
  <th>Use for</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>'pairwise'</code> <i>(default)</i></td>
  <td>A row is used for a pair only if <b>both</b> columns are defined there. The two columns arrive aligned and equal-length.</td>
  <td>Paired stats like <code>cor</code>.</td>
</tr>
<tr>
  <td><code>'omit'</code></td>
  <td>Each column drops <b>its own</b> undefined values independently. The two columns may end up <b>different lengths</b>.</td>
  <td>Unpaired tests like <code>t_test</code>, <code>kruskal_test</code>, where a gap in one sample shouldn't discard a value in the other.</td>
</tr>
<tr>
  <td><code>'keep'</code></td>
  <td>Every row is passed through, <code>undef</code> and all.</td>
  <td>When your function does its own missing-data handling.</td>
</tr>
</tbody>
</table>

 # correlation: keep only complete pairs (the default)
 col2col(\%data, 'cor');
 # two-sample test: each column keeps its own values
 col2col(\%data, 't_test', undef, na => 'omit');
 col2col(\%data, 't_test', { na => 'omit' });        # same, no placeholder

C<rm.undef> / C<rm.na> remain as boolean aliases for backward compatibility:
C<true> means C<'pairwise'>, C<false> means C<'keep'>. Don't combine them with C<na>.

=head4 C<skip.errors> — keep going when a pair fails I<(default: true)>

Some functions croak on degenerate input — for example C<cor> dies if a column has
zero variance. By default C<col2col> B<traps> that croak per pair: instead of
aborting the whole run, it stores the B<first line> of the error message in that
cell, so the result tells you I<which> pair failed and I<why>. Every other cell is
computed normally.

 my $r = col2col(\%data, 'cor');
 # a good pair:   $r->{a}{b} == 0.83
 # a bad pair:    $r->{a}{const} eq 'cor: standard deviation of y is 0'

To restore the old "die on the first error" behaviour, turn it off:

 col2col(\%data, 'cor', undef, 'skip.errors' => 0);
 col2col(\%data, 'cor', { 'skip.errors' => 0 });

Only errors from B<your function> are trapped. Mistakes in the call itself
(unknown column, bad data, unknown function name, unknown option) always die.

========================================================================

=head3 Worked examples

B<Full correlation matrix:>

 my $m = col2col(\%data, 'cor');

B<One variable against all others, sorted strongest first, skipping failures:>

 my $col  = 'Testosterone, total (nmol/L)';
 my $cors = col2col($hoa, 'cor', $col)->{$col};
 for my $other (sort { ($cors->{$b} // -2) <=> ($cors->{$a} // -2) } keys %$cors) {
     next unless $cors->{$other} =~ /^-?\d/;        # skip cells holding an error message
     printf "%-30s % .3f\n", $other, $cors->{$other};
 }

B<Two-sample test across columns of unequal completeness:>

 my $t = col2col($hoa, 't_test', undef, na => 'omit');

B<Find which pairs could not be computed:>

 my $m = col2col($hoa, 'cor');
 for my $from (sort keys %$m) {
     for my $to (sort keys %{ $m->{$from} }) {
         my $v = $m->{$from}{$to};
         warn "$from vs $to: $v\n" if defined $v && $v !~ /^-?\d/;   # non-numeric = error
     }
 }

========================================================================

=head3 Gotchas

=over

=item * B<Your function receives two array refs>, C<($col_a, $col_b)> — not a column and
a name. Unpack with C<my ($x, $y) = @_;>.

=item * B<< C<'pairwise'> can still hit a constant I<subset>. >> A column with overall
variance can be flat on just the rows it shares with one partner, so C<cor> may
still croak for that pair. With the default C<skip.errors>, that shows up as a
message in the single offending cell rather than killing the run.

=item * B<< C<col2col> does not modify your data. >> It reads the table and returns a new
hash of hashes.

=item * B<In the error message, "x" is the first column and "y" is the second> — i.e.
C<y> is the inner ("to") key. So C<< $result-E<gt>{A}{B} >> reading C<…deviation of y is 0>
means column C<B> is the degenerate one for that pair.

=back

=head2 colnames

Return the column names of a data frame, as a list (like R's C<colnames>).
Works on all four Stats::LikeR frame shapes and mirrors the column order
C<view> shows:

=over

=item * C<AoA> — 0-based integer indices, C<0 .. widest_row-1>

=item * C<AoH> — the string-sorted union of the keys of every row

=item * C<HoA> — the string-sorted keys (the keys I<are> the columns)

=item * C<HoH> — the string-sorted union of the inner-row keys

=back

In scalar context it returns the count, so C<scalar colnames($df)> equals
C<ncol($df)> for a rectangular frame.

 my $aoh = [ { b => 2, a => 1 }, { a => 3, c => 9 } ];
 my @cols = colnames($aoh);        # ('a', 'b', 'c')  -- union, sorted

 my $hoa = { z => [1,2], a => [3,4], m => [5,6] };
 my @cols = colnames($hoa);        # ('a', 'm', 'z')

 my $aoa = [ [1,2,3], [4,5,6] ];
 my @cols = colnames($aoa);        # (0, 1, 2)

 my $n = colnames($hoa);           # 3  (scalar context == ncol)

=head2 concat

Row-bind two or more data frames: stack their rows into one new frame, the
analog of pandas C<concat(..., axis=0)> and R's C<rbind>. C<rbind> is provided as a
true synonym (the same subroutine), so the two names are interchangeable.

C<concat> accepts all four data-frame shapes and returns a new frame of that same
shape:

 AoA  [ [ .. ], [ .. ] ]      array of arrayrefs   (positional columns)
 AoH  [ { .. }, { .. } ]      array of hashrefs    (the read_table default)
 HoA  { c => [ .. ], .. }     hash of arrayrefs    (column-major)
 HoH  { r => { .. }, .. }     hash of hashrefs     (named rows)

Every frame must be the same shape; mixing shapes dies with a hint to convert
first (C<aoh2hoa>, C<hoa2aoh>, C<hoh2hoa>, C<aoh2hoh>). undef frames and empty
frames are skipped, and the shape is taken from the first non-empty frame. The
original frames are never modified.

=head3 Usage

 use Stats::LikeR;

 my $all = concat($df1, $df2, $df3);   # any number of frames
 my $all = rbind($df1, $df2);          # identical: rbind is a synonym

=head3 Array of Arrays (AoA)

The outer arrays are concatenated in order and the row arrayrefs are reused by
reference (not copied). Ragged rows are kept as-is; reading past a short row
yields undef.

 my $a = [ [ 1, 2 ], [ 3, 4 ] ];
 my $b = [ [ 5, 6 ], [ 7 ]    ];   # ragged last row
 my $c = concat($a, $b);

B<Resulting Structure:>

 [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 7 ] ]

=head3 Array of Hashes (AoH)

The rows are concatenated in order and the row hashrefs are reused by reference.
The result is the union of columns; a column absent from a given row simply
reads as undef, matching this module's "missing key means undef" convention
(as used by C<dropna>, C<view>, and C<summary>).

 my $a = [ { id => 1, x => 10 } ];
 my $b = [ { id => 2, x => 20, y => 99 } ];   # extra column y
 my $c = concat($a, $b);

B<Resulting Structure:>

 [
     { id => 1, x => 10           },   # no 'y' key -> reads as undef
     { id => 2, x => 20, y => 99  },
 ]

=head3 Hash of Arrays (HoA)

The output columns are the union of all input columns, sorted for a
deterministic layout. Each column is the per-frame arrays joined in frame order.
Because HoA is column-major, a column missing from a frame — or a ragged short
column within a frame — is padded with undef so every output column ends up the
same length (the total number of rows).

 my $a = { g => [ 'a', 'a' ], v => [ 1, 2 ] };
 my $b = { g => [ 'b' ],      w => [ 9 ]    };   # v absent here, w is new
 my $c = concat($a, $b);

B<Resulting Structure:>

 {
     g => [ 'a',   'a',   'b' ],
     v => [ 1,     2,     undef ],   # padded for the frame that lacked 'v'
     w => [ undef, undef, 9     ],   # padded for the frame that lacked 'w'
 }

=head3 Hash of Hashes (HoH)

The outer hashes are merged in frame order and the inner row hashrefs are reused
by reference. Because a Perl hash cannot hold duplicate keys, a repeated row
name is made unique R-style — C<name>, C<name.1>, C<name.2>, … — and a single
warning is emitted noting that row names collided.

 my $a = { r => { v => 1 } };
 my $b = { r => { v => 2 } };
 my $c = concat($a, $b);
 # warns: concat: duplicate HoH row name(s) made unique with a .N suffix

B<Resulting Structure:>

 {
     r     => { v => 1 },
     'r.1' => { v => 2 },
 }

=head3 Empty and single inputs

undef and empty frames are skipped, so they can be threaded through a pipeline
harmlessly:

 concat(undef, [], [ { n => 1 } ], [ { n => 2 } ]);   # two rows

When every frame is empty the result is an empty frame matching the first
argument's reference type (C<[]> for an arrayref, C<{}> for a hashref). A single
frame round-trips unchanged.

=head3 rbind

C<rbind> is the same subroutine as C<concat>, exported under a second name for
readers who know it from R:

 my $c = rbind($df1, $df2);

 # they are literally the same code reference:
 \&Stats::LikeR::rbind == \&Stats::LikeR::concat;   # true

=head3 Errors

C<concat> (and therefore C<rbind>) dies (with a trailing newline) when:

=over

=item * no usable frame is given;

=item * a frame is neither an ARRAY nor a HASH ref;

=item * the frames are not all the same shape (the message names the two shapes and
suggests the relevant converter);

=item * an AoA element is not an arrayref, or an AoH/HoH row is not a hashref.

=back

=head3 See also

C<agg> (split-apply-combine), C<add_data> (which also appends HoA columns and
merges HoH rows), C<ljoin>, C<aoh2hoa>, C<hoa2aoh>, C<hoh2hoa>, C<aoh2hoh>.

=head2 cor

 cor($array1, $array2, $method = 'pearson'),

that is, C<pearson> is the default and will be used if C<$method> is not specified.

Just like R, C<pearson>, C<spearman>, and C<kendall> are available

If you provide an array of arrays (a matrix), C<cor> will compute the correlation matrix automatically. 

=head2 cor_test

 my $result = cor_test(
         'x'         => $x,
         'y'         => $y,
         alternative => 'two.sided',
         method      => 'pearson',
         continuity  => 1
     );

C<cor_test> safely handles C<undef> (or C<NA>) values seamlessly by computing over pairwise complete observations. 

For the C<spearman> and C<kendall> methods, C<cor_test> falls back to a
large-sample normal approximation when I<n> is large or the data contain ties
(and always when you pass C<< exact =E<gt> 0 >>). That approximation's C<p.value> is
evaluated on the tail it belongs to, so a strong rank correlation reports its
actual p-value instead of a flat C<0>; see
L</"F and z tail p-values">. Checked against R's
C<cor.test(..., exact = FALSE)> over 54 Spearman and Kendall cases spanning
I<n> = 60 to 500 and all three alternatives: C<estimate> agrees to C<3e-15>,
Kendall's C<statistic> to C<2e-15>, and C<p.value> to C<1.7e-12> — the worst of
those at a p-value of C<2.2e-297>.

Note that C<statistic> is the z of the approximation, whereas R reports
Spearman's I<S>; the two are different quantities, so compare C<estimate> and
C<p.value> rather than C<statistic> when checking against R for that method.

=head2 cov

 cov($array1, $array2, 'pearson')

or

 cov($array1, $array2, 'spearman')

or

 cov($array1, $array2, 'kendall')

=head2 coxph

Cox proportional-hazards regression: how covariates raise or lower the hazard
(the risk of an event over time). It is the survival-analysis counterpart of
L<C<glm>|/"glm"> and reports hazard ratios, like R's C<survival::coxph> (Efron ties).

Give times, an event flag (1 = event, 0 = censored), and one or more covariates
(a single C<\@x>, or C<[\@x1, \@x2, ...]>):

 use Stats::LikeR 'coxph';

 my $fit = coxph(\@time, \@status, [\@age, \@sex],
                 names => ['age', 'sex']);

 print $fit->{exp_coef}[0];    # hazard ratio for age
 print $fit->{p_value}[0];     # its p-value

Options: C<names>, C<ties> (C<'efron'> default, or C<'breslow'>), C<conf_level>
(default C<0.95>), C<maxit>. The result has parallel per-covariate arrays C<coef>
(log-HR), C<exp_coef> (HR), C<se>, C<z>, C<p_value>, C<conf_int> (HR scale), plus
model-level C<loglik>, C<lr_stat>/C<lr_p_value> (likelihood-ratio test), C<n>,
C<nevent>, and C<converged>. See L<C<survfit>|/"survfit"> and
L<C<logrank_test>|/"logrank_test">.

=head2 cramers_v

Cramér's I<V>, a measure of association for an I<r> × I<c> contingency table
derived from the (uncorrected) Pearson chi-square. Also returns the Bergsma
(2013) bias-corrected variant, which is preferable for small samples or sparse
tables. Validated numerically against R.

 # from a count table
 my $v = cramers_v([[10, 20, 30], [15, 25, 10]]);
 printf "V = %.3f (bias-corrected %.3f)\n", $v->{estimate}, $v->{bias_corrected};

 # or from two parallel categorical vectors (cross-tabulated automatically)
 my $v2 = cramers_v(\@exposure, \@outcome);

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>estimate</code></td>
  <td><code>Double</code></td>
  <td>Cramér's <i>V</i> ∈ [0, 1].</td>
  <td><code>0.3124</code></td>
</tr>
<tr>
  <td><code>bias_corrected</code></td>
  <td><code>Double</code></td>
  <td>Bergsma bias-corrected <i>V</i>.</td>
  <td><code>0.2828</code></td>
</tr>
<tr>
  <td><code>chisq</code></td>
  <td><code>Double</code></td>
  <td>Uncorrected Pearson chi-square.</td>
  <td><code>10.735</code></td>
</tr>
<tr>
  <td><code>df</code></td>
  <td><code>Integer</code></td>
  <td>Degrees of freedom, <code>(r-1)(c-1)</code>.</td>
  <td><code>2</code></td>
</tr>
<tr>
  <td><code>n</code></td>
  <td><code>Integer</code></td>
  <td>Table total.</td>
  <td><code>110</code></td>
</tr>
</tbody>
</table>

=head2 csort

Sort a data frame by a column or a custom comparator, returning a new
(sorted) copy. The input is never mutated.

 my $sorted = csort($data, $by);
 my $sorted = csort($data, $by, $output_shape);
 my $sorted = csort($hoh,  $by, 'aoh', 'row.name');   # HoH only

C<$data> may be any of four shapes:

 AoH   array-of-hashes    [ { col => val, ... }, ... ]   columns are hash keys
 HoA   hash-of-arrays      { col => [ val, ... ], ... }   columns are hash keys
 HoH   hash-of-hashes      { rowname => { col => val }, ... }
 AoA   array-of-arrays    [ [ val, ... ], ... ]           columns are integer indices

The shape is detected automatically. An array-ref whose first row is
itself an array-ref is treated as an AoA; otherwise an array-ref is an
AoH. A hash-ref whose first value is a hash-ref is a HoH (its outer keys
are folded into a row-name column, see below); any other hash-ref is a
HoA.

C<$by> selects the sort key:

 'No.'                          # a column: name (AoH/HoA/HoH) or integer index (AoA)
 2                              # AoA: sort by column index 2
 sub { $a->{'No.'} <=> $b->{'No.'} }   # comparator; $a/$b are the rows

For a column sort the values are compared numerically when every present
value looks like a number, and with string C<cmp> otherwise. For a
comparator, C<$a> and C<$b> are the row references (a hash-ref for
AoH/HoA/HoH, an array-ref for AoA), exactly as with Perl's own C<sort>.

=head3 Sorting an AoA

Columns in an AoA are addressed by non-negative integer index:

 my $rows = [
     [ 3, 30, 'gamma' ],
     [ 1, 10, 'alpha' ],
     [ 2, 20, 'beta'  ],
 ];

 my $s = csort($rows, 0);       # by column 0 -> id 1, 2, 3
 my $s = csort($rows, 2);       # by column 2 -> alpha, beta, gamma
 my $s = csort($rows, sub { $b->[1] <=> $a->[1] });   # by column 1, descending

The result reuses the original row array-refs (a reorder, not a deep
copy), so it is cheap and the caller's data is left untouched. A
non-integer or negative index croaks; an index no row contains is
reported as a missing column.

=head3 Undefined and missing values

Undefined or missing cells always sort to the end. A "missing" cell is a
row that lacks the key (AoH/HoH) or is shorter than the index (AoA); it
is treated the same as an explicit C<undef>. Defined values are ordered
first (ascending, or per the comparison type), undef/missing last, and
undef rows keep their original relative order.

 my $rows = [
     [ 1, 5 ],
     [ 2 ],           # no column 1
     [ 3, undef ],
     [ 4, 1 ],
 ];
 my $s = csort($rows, 1);       # column-0 order: 4, 1, 2, 3

This holds for every shape, for numeric and string columns, and for
B<both> a column/index sort and a comparator sort:

 # no need to guard undef yourself -- this does not warn or die,
 # even under  use warnings FATAL => 'all'
 my $s = csort($df, sub { $a->{'tau p'} <=> $b->{'tau p'} }, 'hoa');

For a comparator, csort can't see which field you key on, so it probes
each row once (comparing the row to itself) to find rows whose comparator
would read an C<undef>; those rows are moved to the end and the rest are
sorted normally, so your comparator never sees an C<undef>. A few
consequences worth knowing:

=over

=item * If your comparator reads several keys (a tie-break), a row is treated as
undef-keyed when I<any> key the comparator actually evaluates for that
row is undef. Such rows go to the bottom.

=item * A comparator that handles undef itself (e.g. C<< $a-E<gt>{v} // 0 >>) never trips
the probe, so csort leaves its ordering completely alone.

=item * A comparator that dies for a real reason still propagates that error
unchanged.

=item * The probe calls your comparator once per row, so keep comparators free
of side effects (they should be anyway).

=back

=head3 Choosing the output shape

The optional third argument picks the returned shape, one of C<'aoh'>,
C<'hoa'>, or C<'aoa'> (case-insensitive). It defaults to the input shape
(HoH defaults to AoH). Any shape can be converted to any other:

 csort($aoa, 0)               # AoA -> AoA (default)
 csort($aoa, 0, 'hoa')        # AoA -> HoA
 csort($aoh, 'No.', 'aoa')    # AoH -> AoA

When the target is AoH or HoA, an AoA's columns are keyed by their
stringified index (C<'0'>, C<'1'>, ...). When the target is AoA, the
positional column order is deterministic:

 from HoA   sorted column-key name
 from AoH   union of the rows' keys, sorted by name
 from AoA   integer index 0 .. widest-row-1 (ragged rows pad with undef)

Because Perl randomizes hash iteration order, the sort of key names is
what makes keyed-to-AoA conversions reproducible from run to run.

=head3 Sorting a HoH

For a HoH, each outer key is the row name. It is folded into a real
column so it survives into the output; the column is named C<row.name> by
default, overridable with a fourth argument:

 my $s = csort($hoh, 'score', 'aoh');           # row name in 'row.name'
 my $s = csort($hoh, 'score', 'aoh', 'sample'); # ... named 'sample' instead

=head2 dnorm

gives the density of the normal distribution, with the specified mean and standard deviation.

In other words, the predicted height of the value C<x>, given a mean, standard deviation, and whether or not to use a log value.

returns a single scalar/number if a single value is given, otherwise returns an array reference.

Usage:

 dnorm(4) # assumes a mean of 0 and standard deviation of 1

but default mean, standard deviation, and log can be passed as parameters:

 $x = dnorm(0, mean => 0, sd => 2, 'log' => 0);

=head2 drop_cols

Return a new data frame with the named columns removed and the rest kept —
C<df.drop(columns=[...])>. Same identifiers and argument forms as
C<select_cols>.

 my $hoa = { a => [1,4], b => [2,5], c => [3,6] };
 drop_cols($hoa, 'b');
 # { a => [1,4], c => [3,6] }

 my $aoa = [ [1,2,3], [4,5,6] ];
 drop_cols($aoa, 1);          # result is re-indexed 0,1
 # [ [1,3], [4,6] ]

Unlike C<select_cols>, C<drop_cols> touches only the keys a row actually has,
so a ragged frame stays ragged:

 drop_cols([ {a=>1,b=>2}, {a=>3,c=>9} ], 'a');
 # [ { b => 2 }, { c => 9 } ]

=head2 drop_duplicates

Remove duplicate rows, loosely modeled on pandas' C<DataFrame.drop_duplicates>.
Works on the three positional/columnar shapes — AoA C<[ [..], .. ]>, AoH
C<< [ {A=E<gt>..}, .. ] >>, and HoA C<< { A=E<gt>[..], .. } >> — but B<not> HoH: its rows are
labeled, so row-level de-duplication has no natural meaning (convert with
C<hoh2aoh>/C<hoh2hoa> first).

=head3 Usage

 drop_duplicates($df);                          # dedupe on every column
 drop_duplicates($df, subset => 'id');          # only look at column 'id'
 drop_duplicates($df, subset => ['a', 'b']);    # a composite key
 drop_duplicates($df, keep => 'last');          # keep the last occurrence
 drop_duplicates($df, keep => 0);               # drop EVERY duplicated row

Two rows are duplicates when their cells are equal in every C<subset> column.
Comparison is by B<stringified value with a distinct undef (NA)> — the same
key semantics C<merge> uses — so C<1> and C<"1.0"> are I<not> equal, while two
undef cells I<are> equal to each other.

=head3 C<subset> — which columns define a row's identity

Defaults to every column. Column identifiers are B<0-based integer positions>
for AoA and B<names> for AoH/HoA. Pass a single column as a scalar or several
as an arrayref. The default column set is the widest row's positions for AoA,
the sorted union of row keys for AoH, and the sorted keys for HoA.

 my $aoh = [ { id => 1, v => 'a' }, { id => 1, v => 'b' }, { id => 2, v => 'c' } ];
 drop_duplicates($aoh, subset => 'id');
 # [ { id => 1, v => 'a' }, { id => 2, v => 'c' } ]

Columns outside C<subset> are not compared, but they stay aligned — a surviving
row keeps all of its columns.

=head3 C<keep> — which occurrence survives

=over

=item * B<< C<'first'> >> (default) — keep the earliest occurrence of each row.

=item * B<< C<'last'> >> — keep the latest occurrence.

=item * B<< C<0> >> (or C<'none'>) — drop I<every> row that has a duplicate, keeping only
rows that were unique.

=back

 my $df = { id => [1, 1, 2], v => [10, 20, 30] };
 drop_duplicates($df, subset => 'id');                 # { id => [1, 2], v => [10, 30] }
 drop_duplicates($df, subset => 'id', keep => 'last'); # { id => [1, 2], v => [20, 30] }

Row order is preserved: the survivors come out in their original first-seen
positions.

=head3 Good to know

=over

=item * B<Returns a new data frame; the original is never modified.> What survives
is shared, not deep-copied: for AoA and AoH the surviving row references are
reused, and for HoA the column arrays are new but hold the same cell SVs. So
the frame, and an HoA's column arrays, can be reshaped without touching the
input — but assigning I<through> a survivor (C<< $out-E<gt>{col}[0] = ... >>, or
C<< $out-E<gt>[0]{col} = ... >> for AoA/AoH) writes to the input's cell as well.
Clone the result if you need full independence.

=item * B<It dies> on: undefined or non-ref data; an HoH frame; an unknown argument;
an empty or duplicated C<subset>; an invalid C<keep>; an AoA position that is
not a non-negative integer or is out of range; or a C<subset> name absent from
an AoH or HoA.

=item * An empty frame returns empty rather than erroring.

=back

=head2 dropna

Drop missing data from a data frame, loosely modeled on pandas' C<dropna>. Works
on all three shapes: AoH C<< [ {A=E<gt>..}, .. ] >>, HoA C<< { A=E<gt>[..], .. } >>, and
HoH C<< { r1=E<gt>{A=E<gt>..}, .. } >>.

=head3 Usage

 # NA mode: drop rows that are undef in the named columns
 dropna($df, cols => ['A', 'B']);
 dropna($df, cols => ['A', 'B'], how => 'all');
 # deletion mode: remove specific rows outright
 dropna($df, rows => [2, 5]);          # indices for AoH/HoA, keys for HoH

You pass B<exactly one> of C<cols> or C<rows>.

=head3 C<cols> — drop rows with missing values

Inspect only the named columns and drop the rows where they're undef. Columns
you don't name are never inspected, but they stay aligned (their cell at a
dropped row goes too). A missing key counts as undef.

C<how> controls the threshold:

=over

=item * B<< C<'any'> >> (default) — drop a row if I<any> named column is undef there.

=item * B<< C<'all'> >> — drop a row only if I<every> named column is undef there.

=back

 my $df = { A => [1, 2, undef], B => [1, 2, 3], C => [undef, 2, 4] };
 dropna($df, cols => ['A', 'B']);
 # { A => [1, 2], B => [1, 2], C => [undef, 2] }

Index 2 is dropped because C<A> is undef there. C<C> is not consulted, so its own
undef at index 0 doesn't trigger a drop — but index 2 is still removed from C<C>
so every column stays the same length.

=head3 C<rows> — delete specific rows

Remove exactly the rows you list — no missing-value logic. Rows are 0-based
indices for AoH and HoA, or the outer keys for HoH. Anything not present is
ignored.

 dropna({ A => [10, 20, 30] }, rows => [1]);   # { A => [10, 30] }

=head3 Good to know

=over

=item * B<Returns a new data frame; the original is never modified.> For HoA the
column arrays are rebuilt (cell values copied); for AoH and HoH the surviving
row references are reused, not deep-copied (dropna never mutates a row). Clone
the result if you need full independence.

=item * B<It dies> on: a non-ref data frame; passing both or neither of C<cols>/C<rows>;
a non-arrayref selector; a C<cols> name absent from a non-empty HoA or AoH; an
invalid C<how>; an unknown argument; or a hashref that mixes array and hash
values (ambiguous HoA vs HoH).

=item * An empty AoH or HoA returns empty rather than erroring.

=item * HoH results come back in hash order, since HoH rows are unordered.

=back

=head2 dunn_test

Dunn's (1964) post-hoc test, the standard follow-up to a significant
L</"kruskal_test"> (Kruskal-Wallis). It performs all pairwise
comparisons of group rank-means using the B<shared> ranking and tie correction
from the omnibus test, then adjusts the p-values for multiple comparisons.
Two-sided p-values are reported (the C<FSA::dunnTest> convention). Validated
numerically against the canonical formula computed in base R.

 my @values = (2.1,3.4,1.9,5.6,4.2, 6.1,7.3,5.9,8.2,6.6, 3.3,4.4,2.2,3.3,5.5);
 my @group  = ((('A') x 5), (('B') x 5), (('C') x 5));

 my $res = dunn_test(\@values, \@group, method => 'bh');
 for my $c (@$res) {
     printf "%-9s  Z=%+.3f  p=%.4f  (adj %.4f)\n",
         $c->{comparison}, $c->{Z}, $c->{p_value}, $c->{p_adjust};
 }

Values and groups are given as two parallel arrays; observations with a missing
value or group are dropped.

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>values</i></td>
  <td><code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>Numeric observations.</td>
  <td><code>\@values</code></td>
</tr>
<tr>
  <td><i>groups</i></td>
  <td><code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>Group label for each observation (same length as <i>values</i>).</td>
  <td><code>\@group</code></td>
</tr>
<tr>
  <td><code>method</code></td>
  <td><code>String</code></td>
  <td><code>'holm'</code></td>
  <td>Multiple-comparison adjustment: <code>none</code>, <code>bonferroni</code>, <code>sidak</code>, <code>holm</code>, <code>hs</code> (Holm-Sidak), <code>bh</code> (Benjamini-Hochberg / FDR), or <code>by</code> (Benjamini-Yekutieli).</td>
  <td><code>'bh'</code></td>
</tr>
</tbody>
</table>

=head3 Output

Returns an array reference with one hash per pairwise comparison (in sorted
group order), each containing:

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>comparison</code></td>
  <td><code>String</code></td>
  <td><code>"group1 - group2"</code>.</td>
  <td><code>"A - B"</code></td>
</tr>
<tr>
  <td><code>group1</code>, <code>group2</code></td>
  <td><code>String</code></td>
  <td>The two groups being compared.</td>
  <td><code>"A"</code>, <code>"B"</code></td>
</tr>
<tr>
  <td><code>Z</code></td>
  <td><code>Double</code></td>
  <td>Dunn's z statistic for the rank-mean difference.</td>
  <td><code>-2.7602</code></td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td><code>Double</code></td>
  <td>Unadjusted two-sided p-value.</td>
  <td><code>0.005777</code></td>
</tr>
<tr>
  <td><code>p_adjust</code></td>
  <td><code>Double</code></td>
  <td>p-value after the chosen adjustment.</td>
  <td><code>0.017331</code></td>
</tr>
</tbody>
</table>

=head2 epi_2x2

The standard 2×2 effect measures — odds ratio, risk ratio, and risk difference,
each with a confidence interval, plus number needed to treat — for one
exposure×outcome table. Rows are exposure, columns are outcome:

        outcome+   outcome-
 exp+       a          b
 exp-       c          d

Pass the four counts (or a C<[a,b,c,d]> / C<[[a,b],[c,d]]> array ref):

 use Stats::LikeR 'epi_2x2';

 my $r = epi_2x2(30, 70, 20, 80);
 print $r->{odds_ratio};             # 1.714
 print "@{ $r->{odds_ratio_ci} }";   # 0.895 3.285

Options: C<conf_level> (default C<0.95>) and C<correct> (add 0.5 to every cell,
done automatically when a cell is 0). Result keys: C<odds_ratio>, C<risk_ratio>,
C<risk_diff> (each with a matching C<*_ci>), C<risk_exposed>, C<risk_unexposed>, and
C<nnt>. For a significance test use L<C<fisher_test>|/"fisher_test"> or
L<C<chisq_test>|/"chisq_test">; to adjust across strata use L<C<cmh_test>|/"cmh_test">.

=head2 eta_squared

Eta-squared (η²) and related effect sizes for a one-way ANOVA, computed from the
sums of squares. Returns η², partial η² (equal to η² for a one-way design), and
ω² (omega-squared, a less biased estimator). Accepts either raw values and group
labels or an existing L<C<aov>|/"aov"> result. Validated numerically against R.

 my $e = eta_squared(\@values, \@group);            # or eta_squared($aov_result)
 printf "eta^2 = %.3f, omega^2 = %.3f\n", $e->{eta_sq}, $e->{omega_sq};

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>eta_sq</code></td>
  <td><code>Double</code></td>
  <td>η² = SS_effect / SS_total.</td>
  <td><code>0.8457</code></td>
</tr>
<tr>
  <td><code>partial_eta_sq</code></td>
  <td><code>Double</code></td>
  <td>Partial η² = SS_effect / (SS_effect + SS_resid).</td>
  <td><code>0.8457</code></td>
</tr>
<tr>
  <td><code>omega_sq</code></td>
  <td><code>Double</code></td>
  <td>ω², adjusted for bias.</td>
  <td><code>0.7743</code></td>
</tr>
<tr>
  <td><code>term</code></td>
  <td><code>String</code></td>
  <td>Name of the effect term used.</td>
  <td><code>"grp"</code></td>
</tr>
</tbody>
</table>

=head2 ffill

Forward-fill NA (undef) cells with the last valid value seen above them along
the row axis, like C<pandas.DataFrame.ffill>. See C<bfill> for the backward
direction and C<fillna> for constant fills.

 ffill($df,
     cols  => [ 'v' ],   # restrict to these columns (default: every column)
     limit => 2,         # max consecutive fills per gap (default: unlimited)
 );

Column identifiers are names for AoH/HoA/HoH and 0-based positions for AoA. The
row axis is positional for AoA/AoH/HoA and string-sorted key order for HoH (the
only deterministic order a HoH has). Filling stays within each column's
existing length: ragged HoA columns are not extended, and AoA rows are not
extended past their own length.

C<limit> caps the number of consecutive NA cells filled in a single gap; the
remaining cells in an over-long gap stay NA, and the count resets after the
next real value. A leading run of NA (with nothing above it) is left as NA.

Returns a NEW frame; the input is never modified.

=head3 Example

 ffill([ { v => 1 }, { v => undef }, { v => undef }, { v => 4 }, { v => undef } ],
     cols => [ 'v' ]);
 # [ { v => 1 }, { v => 1 }, { v => 1 }, { v => 4 }, { v => 4 } ]

 ffill([ { v => 1 }, { v => undef }, { v => undef }, { v => 4 } ],
     cols => [ 'v' ], limit => 1);
 # [ { v => 1 }, { v => 1 }, { v => undef }, { v => 4 } ]

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; a
C<cols> column that does not exist; or a C<limit> that is not a positive integer.

=head2 fillna

Replace NA (undef) cells with a constant, like C<pandas.DataFrame.fillna> with
a scalar or a dict. For propagation from neighbouring rows instead of a
constant, use C<ffill>/C<bfill>.

 fillna($df,
     value => 0,                    # scalar: fill every NA (or only within `cols`)
     value => { a => 9, b => -1 },  # dict: fill only these columns
     cols  => [ 'a', 'b' ],         # restrict a scalar fill (forbidden with a dict)
 );

C<value> is required. Column identifiers are names for AoH/HoA/HoH and 0-based
positions for AoA. A missing hash key counts as NA and is materialised when
filled (as in C<dropna>'s NA view). AoA rows are never extended past their own
length. Ragged HoA columns are extended to the longest column's length before
filling.

A B<scalar> C<value> fills every NA in the frame, or — with C<cols> — only NA
cells in the named columns. A B<hashref> C<value> fills only the columns it
names; a dict key that matches no existing column is ignored (matching
pandas), and C<cols> may not be combined with a dict.

Returns a NEW frame; the input is never modified.

=head3 Example

 fillna([ { a => 1, b => undef }, { a => undef, b => 4 } ], value => 0);
 # [ { a => 1, b => 0 }, { a => 0, b => 4 } ]

 fillna([ { a => undef, b => undef } ], value => { a => 9, Z => 1 });
 # [ { a => 9, b => undef } ]   # Z ignored, b left NA

 fillna([ { a => undef, b => undef } ], value => 7, cols => [ 'b' ]);
 # [ { a => undef, b => 7 } ]

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; a
missing C<value>; combining C<cols> with a dict C<value>; or a scalar-fill C<cols>
naming a column that does not exist.

=head2 filter

Return a new data frame containing only the rows of C<$df> that match a predicate. The original C<$df> is never modified.

 my $adults = filter($df, col('age') >= 18);

C<filter> accepts a predicate in one of two forms:

=over

=item 1. a B<< C<col()> expression >> — a small, composable comparison built with overloaded operators, and

=item 2. a B<code reference> — for anything the operators can't express (multiple columns, regexes, matching on the row name, arbitrary logic), in the same spirit as the C<filter> option of C<read_table>.

=back

Both C<filter> and C<col> are exported by default.

=head3 Arguments

=for html <table>
<thead>
<tr>
  <th>Position</th>
  <th>Name</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>$df</code></td>
  <td>The data frame: an <b>array of hashes</b> (AoH, the default <code>read_table</code> output), a <b>hash of arrays</b> (HoA), or a <b>hash of hashes</b> (HoH, e.g. <code>read_table</code> with <code>'output.type' =&gt; 'hoh'</code>).</td>
</tr>
<tr>
  <td>2</td>
  <td>predicate</td>
  <td>A <code>col()</code> comparison object <b>or</b> a <code>CODE</code> reference. A coderef receives the row as <code>$_</code> / <code>$_[0]</code> and the row identifier as <code>$_[1]</code> (see below).</td>
</tr>
<tr>
  <td>3 +</td>
  <td><code>'output.type' =&gt; 'aoh'|'hoa'</code></td>
  <td><i>Optional.</i> The shape of the returned frame. Omit it to keep the input's own shape. <code>'out'</code> and <code>'output_type'</code> are accepted aliases, and a bare <code>filter($df, $pred, 'aoh')</code> also works.</td>
</tr>
</tbody>
</table>

=head3 The C<col()> form

C<col('name')> is a deferred reference to a column. It carries no data — only the column name — so it can be compared with a literal to build a predicate that C<filter> evaluates once per row.

 filter($df, col('age') >= 18);  # keep rows where age >= 18
 filter($df, col('sex') eq 'f'); # keep rows where sex is 'f'
 filter($df, 18 <= col('age'));  # operands may be in either order

=for html <table>
<thead>
<tr>
  <th>Kind</th>
  <th>Operators</th>
  <th>Comparison</th>
</tr>
</thead>
<tbody>
<tr>
  <td>Numeric</td>
  <td><code>&gt;</code> <code>&lt;</code> <code>&gt;=</code> <code>&lt;=</code> <code>==</code> <code>!=</code></td>
  <td>numeric (cell and value compared as numbers)</td>
</tr>
<tr>
  <td>String</td>
  <td><code>gt</code> <code>lt</code> <code>ge</code> <code>le</code> <code>eq</code> <code>ne</code></td>
  <td>string (cell and value compared as strings)</td>
</tr>
</tbody>
</table>

Predicates compose with bitwise C<&> (and), C<|> (or), and C<!> (not):

 filter($df, (col('age') > 18) & (col('sex') eq 'f'));   # and
 filter($df, (col('grp') eq 'a') | (col('grp') eq 'c')); # or
 filter($df, !(col('x') > 100));                         # not

Comparison operators bind more tightly than C<&> and C<|>, so C<< (col('a') E<gt> 4) & (col('b') E<lt> 2) >> is parsed correctly, but the parentheses are recommended for readability.

A C<col()> expression is also the quick way to say it: C<filter> compiles the whole expression once and tests every row in C, without building a row hash or calling into Perl at all, which on a large frame is several times faster than the equivalent C<sub>. What C<col()> cannot express — a C<< -E<gt>match >> regex, an operand that is an object — is evaluated the same way a C<sub> is, one call per row.

 > Note: C<< col('age') E<gt> 32 >> works because C<col('age')> is an object whose C<< E<gt> >> is overloaded. A B<bare string> cannot do this — C<< 'age' E<gt> 32 >> is computed by Perl to a plain boolean (the string numifies to 0) before C<filter> is ever called, so the column name is lost. Always wrap the column in C<col(...)>.

 > C<col()> addresses B<columns only> — it has no handle on a HoH's row name (the outer key). It also cannot express a regex match: there is no C<=~> operator to overload, so C<col('name') =~ /re/> runs the match immediately on the stringified object and never reaches C<filter>. For either case, use the code-reference form below.

=head3 The code-reference form

For logic the operators can't express, pass a C<sub>. It is called once per row and is given:

=over

=item * the B<row> as a hash reference, available both as C<$_> and as the first argument C<$_[0]>, and

=item * the B<row identifier> as the second argument, C<$_[1]> — the B<outer key (the row name)> for a HoH, or the B<0-based row index> for an AoH or HoA.

=back

Return a true value to keep the row.

 filter($df, sub { $_->{x} > 4 && $_->{grp} eq 'a' });
 filter($df, sub { $_->{name} =~ /^A/ });
 filter($df, sub { $_->{age} % 2 == 0 });            # things col() has no operator for
 filter($df, sub { $_[0]{score} > $_[0]{threshold} });

For a HoA there are no row hashes to hand over, so the sub is given a C<< { column =E<gt> value, ... } >> hash built for it, and the same C<< $_-E<gt>{column} >> syntax works regardless of the input shape. That hash is reused from row to row for as long as the sub only reads it; keeping the row (or a reference to one of its cells), or adding a key to it, makes C<filter> start a fresh one, so a row you hold on to is always yours alone. A C<col()> predicate needs no row hash at all.

=head4 Filtering on the row name (C<$_[1]>)

In a HoH the row name is the B<outer key>, not a field inside each row hash — so C<< $_-E<gt>{row_name} >> is C<undef>. Match on C<$_[1]> instead:

 # HoH keyed by structure id; keep the rows named in @ids
 my $grps = join '|', @ids;
 my $keep = filter($score, sub { $_[1] =~ m/^(?:$grps)$/ });

 # combine the row name with an ordinary column test
 filter($score, sub { $_[1] =~ /^1/ && $_->{anomaly_rank} < 100 });

For an AoH or HoA, C<$_[1]> is the 0-based row index:

 filter($aoh, sub { $_[1] % 2 == 0 });   # keep even-indexed rows
 filter($hoa, sub { $_[1] < 10 });        # keep the first ten rows

=head3 Choosing the output shape

By default C<filter> returns a frame of the B<same shape> as the input (AoH → AoH, HoA → HoA, HoH → HoH). Pass C<output.type> to convert while filtering:

 my $aoh = read_table('patients.csv');                          # array of hashes
 my $hoa = filter($aoh, col('Age') >= 18, 'output.type' => 'hoa');
 # $hoa->{Age}, $hoa->{Sex}, ... are all the same length and row-aligned

The two selectable output types are C<'aoh'> and C<'hoa'>. C<'hoh'> is B<not> selectable, because producing a hash of hashes would require choosing which column becomes the row key; an HoH input keeps its keys only when the output shape is left at the default (HoH → HoH).

=head3 Examples

 use Stats::LikeR;
 my $df = read_table('patients.csv');                 # array of hashes

 my $adults = filter($df, col('Age') >= 18);          # numeric threshold
 my $target = filter($df, (col('Age') >= 18) & (col('Sex') eq 'f'));   # combine
 my $flagged = filter($df, sub { $_->{ALT} > 40 || $_->{AST} > 40 });  # coderef

 # hash of arrays in -> hash of arrays out (columns filtered in parallel)
 my $hoa = read_table('patients.csv', 'output.type' => 'hoa');
 my $sub = filter($hoa, col('Age') > 32);

 # hash of hashes in -> the same row keys, fewer of them
 my $hoh = read_table('patients.csv', 'output.type' => 'hoh');
 my $keep = filter($hoh, col('Age') > 32);

 # hash of hashes: filter on the row name (the outer key) via $_[1]
 my $grps    = join '|', qw(1cka 1d4t);
 my $by_name = filter($hoh, sub { $_[1] =~ m/^(?:$grps)$/ });

 # convert shape while filtering
 my $as_hoa = filter($df, col('Age') > 32, 'output.type' => 'hoa');

=head3 Behavior and notes

=over

=item * B<The input is never modified.> C<filter> builds and returns a new frame; C<$df> is left untouched.

=item * B<< The predicate receives the row identifier as C<$_[1]>. >> For a HoH it is the outer key (the row name); for an AoH or HoA it is the 0-based row index. In a HoH the row name lives in the I<key>, not inside each row hash, so C<< $_-E<gt>{row_name} >> is C<undef> — filter on C<$_[1]> instead. C<col()> expressions see only columns, never the row key.

=item * B<< A missing or C<undef> cell never matches a C<col()> comparison. >> C<< col('x') E<gt> 0 >> silently drops any row whose C<x> is absent or C<undef>; for numeric operators a non-numeric cell is likewise dropped. With a coderef, C<undef> is whatever your sub makes of it.

=item * B<Rows are shared, not deep-copied, wherever possible.> When an AoH or HoH row is kept (output left as AoH/HoH, or converted to C<aoh>), the returned frame references the I<same> inner row hashes as the input. Mutating such a row in the result would also change it in the original. HoA inputs and any C<hoa> output build fresh arrays and fresh cell values.

=item * B<Keep-all / keep-none are well defined.> A predicate true for every row returns the whole frame in the chosen shape; true for none returns an empty frame: C<[]> for C<aoh>, a hash of empty (but present) columns for C<hoa>, and C<{}> for C<hoh>.

=item * B<Supported shapes are AoH, HoA, and HoH.> A non-reference, an AoH element that is not a hash reference, a HoA column that is not an array reference, or a HoH row that is not a hash reference all raise a descriptive error; a bare C<col('x')> with no comparison is also an error. An empty hash C<{}> is treated as an empty frame.

=item * B<Perl 5.10 compatible.> The C<col()>/operator layer is pure Perl (operator overloading building a per-row closure); filtering and any reshaping run in XS.

=back

=head3 See also

C<read_table> (whose C<filter> option applies the same coderef convention while reading a file), C<col2col>.

=head2 fisher_test

=head3 array reference entry

 my $array_data = [
     [10, 2],
     [3, 15]
 ];
 my $res1 = fisher_test($array_data);

which returns a hash reference:

 {
 alternative   "two.sided",
 conf_int      [
     [0] 2.75343836564204,
     [1] 300.682787419401
 ],
 conf_level    0.95,
 estimate      {
     "odds ratio"   21.3053312750168
 },
 method        "Fisher's Exact Test for Count Data",
 p_value       0.000536724119143435
 }

=head3 hash reference entry

 $ft = fisher_test( {
     Guess => {
         Milk => 3, Tea => 1
     },
     Truth => {
         Milk => 1, Tea => 3
     }
 });

=head3 larger (R x C) tables

Any table of at least 2x2 counts is accepted, as either a 2D array reference or a 2D hash reference:

 my $res = fisher_test([
     [5, 3, 2],
     [1, 4, 6],
     [7, 2, 1],
 ]);

For tables larger than 2x2 the p-value is computed by exact enumeration of
every contingency table sharing the observed row and column margins (the
multivariate hypergeometric distribution), and matches R's C<fisher.test> to
full precision. Only the two-sided test is defined in this case, so
C<alternative> is ignored and the returned hash reference omits C<conf_int> and
C<estimate> (the conditional-MLE odds ratio and its confidence interval are
reported for 2x2 tables only):

 {
 alternative   "two.sided",
 conf_level    0.95,
 method        "Fisher's Exact Test for Count Data",
 p_value       0.0540892411303451
 }

As with the 2x2 case, a hash-of-hashes input orders rows by their sorted keys
and columns by the sorted keys of the first row, so the result is deterministic;
every row must expose the same set of column keys, and every row of an array
input must have the same number of columns.

Enumeration is exact but finite: a table whose margins put more completions in
the way than can be walked is refused outright,

 fisher_test: 5x7 table is too large for exact enumeration

rather than answered with an approximation. Subtrees that lie wholly inside or
wholly outside the tail are summed in closed form or dropped without being
walked, which puts most tables of practical size well inside the limit --
C<fisher_test> computes the 6x6 table of R's PR#18336, which R's own C<fisher.test>
declines with C<< hash key 5e+09 E<gt> INT_MAX >> -- but R's network algorithm (FEXACT)
still reaches tables this one cannot, such as the 5x7 6th example of Mehta &
Patel. For those, use C<chisq_test>, or R.

=head2 friedman_test

The Friedman rank-sum test, the non-parametric analog of a repeated-measures
ANOVA for an unreplicated complete block design (e.g. the same subjects measured
under several conditions, or several raters scoring the same items). It is a
faithful port of R's C<stats::friedman.test>, including the tie correction, and
was validated numerically against R.

Input is a matrix (array of array refs) with B<one block/subject per row> and
B<one treatment/condition per column>. Blocks (rows) containing any missing or
non-numeric value are dropped, mirroring R's C<complete.cases>.

 #             cond1 cond2 cond3
 my $r = friedman_test([
     [7,  9,  8],   # subject 1
     [6,  6,  7],   # subject 2
     [9, 10,  9],   # subject 3
     [8,  8,  6],   # subject 4
 ]);
 printf "chi2=%.3f  df=%d  p=%.4g\n", $r->{statistic}, $r->{parameter}, $r->{p_value};

A significant result says the conditions differ overall; follow up with pairwise
comparisons (for example L</"dunn_test"> on the paired differences, or
Wilcoxon signed-rank tests with a multiple-comparison adjustment).

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>statistic</code></td>
  <td><code>Double</code></td>
  <td>Friedman chi-squared statistic (tie-corrected).</td>
  <td><code>4.0952</code></td>
</tr>
<tr>
  <td><code>parameter</code></td>
  <td><code>Integer</code></td>
  <td>Degrees of freedom, <code>k - 1</code> (number of treatments minus one).</td>
  <td><code>2</code></td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td><code>Double</code></td>
  <td>The p-value from the chi-squared approximation.</td>
  <td><code>0.129</code></td>
</tr>
<tr>
  <td><code>n</code></td>
  <td><code>Integer</code></td>
  <td>Number of complete blocks actually used.</td>
  <td><code>7</code></td>
</tr>
<tr>
  <td><code>method</code></td>
  <td><code>String</code></td>
  <td><code>"Friedman rank sum test"</code>.</td>
  <td></td>
</tr>
</tbody>
</table>

=head2 get_union

 my @all   = get_union(\@a, \@b, \@c); # every distinct value, any list
 my $count = get_union(\@a, \@b, \@c); # how many distinct values

Takes one or more array references and returns every value that appears in at
least one of them. Duplicates collapse and the result keeps first-appearance
order. In scalar context it returns the count. Values are compared by their
string form (like Perl hash keys), so C<1>, C<"1"> and C<1.0> are one element,
while a UTF-8 flagged string stays distinct from the same bytes without the
flag. A non-array-ref argument or an C<undef> element is fatal. Mirrors
C<List::Compare>'s C<get_union>.

 my @a = (1, 2, 3, 3);
 my @b = (3, 4);
 my @u = get_union(\@a, \@b);            # (1, 2, 3, 4)

=head2 glm

takes a hash of an array as input

 my %tooth_growth = (
     dose => [qw(0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0
 1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5
 0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0
 2.0 2.0 2.0)],
     len  => [qw(4.2 11.5  7.3  5.8  6.4 10.0 11.2 11.2  5.2  7.0 16.5 16.5 15.2 17.3 22.5
 17.3 13.6 14.5 18.8 15.5 23.6 18.5 33.9 25.5 26.4 32.5 26.7 21.5 23.3 29.5
 15.2 21.5 17.6  9.7 14.5 10.0  8.2  9.4 16.5  9.7 19.7 23.3 23.6 26.4 20.0
 25.2 25.8 21.2 14.5 27.3 25.5 26.4 22.4 24.5 24.8 30.9 26.4 27.3 29.4 23.0)],
     supp => [qw(VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC
 VC VC VC VC VC OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ
 OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ)]
 );

 my $glm_teeth = glm(
     data    => \%tooth_growth,
     formula => 'len ~ dose + supp',
     family  => 'gaussian'
 );

In addition to the C<gaussian> default, it fully supports logistic regression using the C<binomial> family parameter via Iteratively Reweighted Least Squares (IRLS):

 my $glm_bin = glm(formula => 'am ~ wt + hp', data => \%mtcars, family => 'binomial');

Count outcomes are handled by the C<poisson> family (log link, for rate ratios) and the C<negbin> (negative-binomial) family, which accommodates over-dispersion. As in R's C<MASS::glm.nb>, the negative-binomial dispersion C<theta> is estimated by maximum likelihood, alternating with the IRLS fit, unless you supply a fixed value:

 my $pois = glm(formula => 'cases ~ age + sex', data => \%d, family => 'poisson');
 my $nb   = glm(formula => 'cases ~ age + sex', data => \%d, family => 'negbin');
 my $nb2  = glm(formula => 'cases ~ age + sex', data => \%d, family => 'negbin', theta => 1.7);

For every non-gaussian family, C<glm> also returns the exponentiated coefficients with their Wald confidence intervals (C<confint.default>): odds ratios for C<binomial>, and rate / incidence-rate ratios for C<poisson> and C<negbin>. The interval width is set by the C<conf.level> argument (default C<0.95>). Validated numerically against R's C<glm>, C<MASS::glm.nb>, and C<confint.default>.

 my $nb = glm(formula => 'cases ~ age + sex', data => \%d, family => 'negbin');
 printf "IRR(age) = %.2f (%.2f–%.2f)\n",
     $nb->{exp}{age}{estimate}, $nb->{exp}{age}{'conf.low'}, $nb->{exp}{age}{'conf.high'};

For the families that report a Wald C<z> (everything but C<gaussian>),
C<< Pr(E<gt>|z|) >> is computed as C<2 * pnorm(-|z|)> rather than
C<2 * (1 - pnorm(|z|))>, so a strong effect reports its actual p-value instead
of a flat C<0>; see L</"F and z tail p-values">. The
C<gaussian> family reports C<< Pr(E<gt>|t|) >> from a direct two-tail probability and was
never affected. Note that the C<z> itself comes from this module's IRLS fit and
can differ from R's in the 6th to 8th significant digit, which a p-value far
out in the tail amplifies — at C<|z| = 37> a 1.5e-5 difference in C<z> moves the
p-value by about 2%.

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>formula</code></td>
  <td><code>String</code></td>
  <td><i>None (Required)</i></td>
  <td>A symbolic description of the model to be fitted. Parsed by the same code as [<code>lm</code>](#lm)'s, so it takes the same operators: <code>+</code>, <code>:</code>, <code>*</code>, <code>^</code>, <code>.</code> for every remaining column, and <code>-1</code> / <code>+0</code> to remove the intercept.</td>
  <td><code>'am ~ wt + hp'</code>, <code>'y ~ x - 1'</code>, <code>'y ~ .'</code></td>
</tr>
<tr>
  <td><code>data</code></td>
  <td><code>HashRef</code> or <code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>The dataset containing the variables used in the formula. Accepts a Hash of Arrays (HoA), a Hash of Hashes (HoH) or an Array of Hashes (AoH). Rows are named as described under [<code>lm</code>](#lm).</td>
  <td><code>\%mtcars</code>, <code>[{x =&gt; 1, y =&gt; 2}, ...]</code></td>
</tr>
<tr>
  <td><code>family</code></td>
  <td><code>String</code></td>
  <td><code>'gaussian'</code></td>
  <td>The error distribution / link function: <code>'gaussian'</code> (identity link), <code>'binomial'</code> (logit link), <code>'poisson'</code> (log link) or <code>'negbin'</code> (negative binomial, log link).</td>
  <td><code>'poisson'</code></td>
</tr>
<tr>
  <td><code>theta</code></td>
  <td><code>Number</code></td>
  <td><i>estimated by ML</i></td>
  <td>Negative-binomial dispersion. When omitted (with <code>family =&gt; 'negbin'</code>) it is estimated by maximum likelihood as in <code>MASS::glm.nb</code>; supply a value to hold it fixed.</td>
  <td><code>1.7</code></td>
</tr>
<tr>
  <td><code>conf.level</code></td>
  <td><code>Number</code></td>
  <td><code>0.95</code></td>
  <td>Confidence level for the Wald coefficient / exponentiated-coefficient intervals.</td>
  <td><code>0.90</code></td>
</tr>
</tbody>
</table>

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>aic</code></td>
  <td><code>Double</code></td>
  <td>Akaike's Information Criterion for the fitted model (lower is better).</td>
  <td><code>123.45</code></td>
</tr>
<tr>
  <td><code>boundary</code></td>
  <td><code>Integer (Boolean)</code></td>
  <td><code>1</code> if the fitted values computationally reached the <code>0</code> or <code>1</code> boundary (specific to the binomial family), <code>0</code> otherwise.</td>
  <td><code>0</code></td>
</tr>
<tr>
  <td><code>coefficients</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping the expanded model term names to their estimated coefficient values.</td>
  <td><code>{'Intercept' =&gt; 1.5, 'wt' =&gt; -0.5}</code></td>
</tr>
<tr>
  <td><code>converged</code></td>
  <td><code>Integer (Boolean)</code></td>
  <td><code>1</code> if the Iteratively Reweighted Least Squares (IRLS) algorithm converged within the maximum iterations, <code>0</code> otherwise.</td>
  <td><code>1</code></td>
</tr>
<tr>
  <td><code>deviance</code></td>
  <td><code>Double</code></td>
  <td>The residual deviance of the fitted model.</td>
  <td><code>15.2</code></td>
</tr>
<tr>
  <td><code>deviance.resid</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping data row names to their computed deviance residuals.</td>
  <td><code>{'Mazda RX4' =&gt; 0.12}</code></td>
</tr>
<tr>
  <td><code>df.null</code></td>
  <td><code>Integer</code></td>
  <td>The residual degrees of freedom for the null model.</td>
  <td><code>31</code></td>
</tr>
<tr>
  <td><code>df.residual</code></td>
  <td><code>Integer</code></td>
  <td>The residual degrees of freedom for the fitted model.</td>
  <td><code>30</code></td>
</tr>
<tr>
  <td><code>family</code></td>
  <td><code>String</code></td>
  <td>The statistical family used to fit the model.</td>
  <td><code>"gaussian"</code></td>
</tr>
<tr>
  <td><code>fitted.values</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping data row names to the fitted mean values (the model's predictions on the scale of the response).</td>
  <td><code>{'Mazda RX4' =&gt; 0.85}</code></td>
</tr>
<tr>
  <td><code>iter</code></td>
  <td><code>Integer</code></td>
  <td>The number of IRLS iterations performed before convergence or hitting the iteration limit.</td>
  <td><code>4</code></td>
</tr>
<tr>
  <td><code>null.deviance</code></td>
  <td><code>Double</code></td>
  <td>The deviance for the null model (a baseline model containing only an intercept, or an offset of 0 if the intercept is removed).</td>
  <td><code>43.5</code></td>
</tr>
<tr>
  <td><code>rank</code></td>
  <td><code>Integer</code></td>
  <td>The numeric rank of the fitted linear model (the number of estimated, non-aliased parameters).</td>
  <td><code>2</code></td>
</tr>
<tr>
  <td><code>summary</code></td>
  <td><code>HashRef</code></td>
  <td>A nested hash mapping each term to its detailed summary statistics, including <code>Estimate</code>, <code>Std. Error</code>, <code>t value</code> / <code>z value</code>, <code>Pr(&gt; t )</code> / <code>Pr(&gt; z )</code>, and the Wald <code>CI.lower</code> / <code>CI.upper</code> (link scale). Aliased parameters return <code>"NaN"</code>.</td>
  <td><code>{'wt' =&gt; {'Estimate' =&gt; -0.5, 'Std. Error' =&gt; 0.1, ...}}</code></td>
</tr>
<tr>
  <td><code>terms</code></td>
  <td><code>ArrayRef</code></td>
  <td>An ordered list of the expanded term names included in the model matrix.</td>
  <td><code>['Intercept', 'wt', 'hp']</code></td>
</tr>
<tr>
  <td><code>conf.int</code></td>
  <td><code>HashRef</code></td>
  <td>Wald confidence interval for each coefficient on the <b>link</b> scale, as <code>[lower, upper]</code>.</td>
  <td><code>{'wt' =&gt; [-0.9, -0.1]}</code></td>
</tr>
<tr>
  <td><code>conf.level</code></td>
  <td><code>Double</code></td>
  <td>The confidence level used for <code>conf.int</code> and <code>exp</code>.</td>
  <td><code>0.95</code></td>
</tr>
<tr>
  <td><code>exp</code></td>
  <td><code>HashRef</code></td>
  <td>Non-gaussian families only: exponentiated coefficient (odds ratio for <code>binomial</code>; rate / incidence-rate ratio for <code>poisson</code> / <code>negbin</code>) with its confidence interval, as <code>{estimate, 'conf.low', 'conf.high'}</code>.</td>
  <td><code>{'wt' =&gt; {estimate =&gt; 0.6, 'conf.low' =&gt; 0.4, 'conf.high' =&gt; 0.9}}</code></td>
</tr>
<tr>
  <td><code>theta</code></td>
  <td><code>Double</code></td>
  <td><code>negbin</code> family only: the negative-binomial dispersion parameter (ML estimate, or the fixed value supplied).</td>
  <td><code>1.73</code></td>
</tr>
</tbody>
</table>

=head2 group_by

Take a hash of arrays, hash of hashes, or array of hashes, and group a column by another column.

 my $aoh_data = [
     { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
     { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
     { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
     { 'Gender' => 'Female' } # Intentional missing target value
 ];

as well as

 $hoh_data = {
     'Patient_A' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
     'Patient_B' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
     'Patient_C' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
     'Patient_D' => { 'Gender' => 'Female' }, # Intentional missing target value
     'Patient_E' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => undef } # Explicit undef
     };

and

 my $hoa_data = {
     'Gender'                       => ['Male', 'Female', 'Male', 'Female'],
     'Testosterone, total (nmol/L)' => [22.1,   2.5,      19.4,   undef   ]
 };

then run the function thus:

 group_by( $hoa_data, 'Testosterone, total (nmol/L)', 'Gender');

The output can be thought of like a hash, with the first string broken down by the second.

all become hash of arrays:

 {
     Female   [
         [0] 1.8
     ],
     Male     [
         [0] 18.2,
         [1] 20.5
     ]
 }

A column that is present in some rows but missing in others is fine (those rows
are simply skipped), but naming a target, group, or filter column that is absent
from the data entirely is fatal: C<group_by> dies with
C<< group_by: "E<lt>columnE<gt>" is not present in the dataset >>.

=head3 Filtering

Data can be further broken down with filter/subs like in C<read_table>:

 my $testosterone = group_by($d, # group testosterone by "Gender"
     'Testosterone, total (nmol/L)',
     'Gender',
     { 'Race/Hispanic origin w/ NH Asian' => sub { $_ eq $n } },# filter
     { 'Testosterone, total (nmol/L)' => sub { $_ ne 'NA' } } # filter
 );

where each filter filters on the columns, e.g. second hash keys.

=head2 h

Print a function's documentation and return. This is the module's C<?function>:
ask for a name, get the section of the manual that describes it.

 h('quantile');    # by name
 h(*quantile);     # by name, unquoted
 h(\&quantile);    # by reference
 h();              # the general help, and every documented function

 perl -MStats::LikeR -e 'h(*write_table)'   # straight from the shell

=head3 Arguments

=for html <table>
<thead>
<tr>
  <th>Form</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>h('name')</code></td>
  <td>A string. A package prefix is ignored, so <code>h('Stats::LikeR::agg')</code> works too.</td>
</tr>
<tr>
  <td><code>h(*name)</code></td>
  <td>A typeglob. The closest thing to an unquoted name that Perl will allow here.</td>
</tr>
<tr>
  <td><code>h(\&amp;name)</code></td>
  <td>A code reference to one of this module's functions. Dies if the reference is not one.</td>
</tr>
<tr>
  <td><code>h()</code></td>
  <td>No argument: prints [Getting help](#getting-help) and lists every documented function.</td>
</tr>
</tbody>
</table>

C<h(bedroc)>, with no quotes and no sigil, cannot be made to work: every function
here is exported, so Perl parses the bareword as a call to C<bedroc()> before C<h>
is ever reached.

=head3 Return value

The name whose documentation was printed, so C<h> is usable in a pipeline:

 my @shown = map { h($_) } qw(auc auroc roc);

C<h> does B<not> die, and it is the only route to a function's documentation:
no function reads its own arguments for a help flag, so a column or file really
named C<'h'> is never mistaken for a question. See
L</"Getting help">.

=head3 Where the text comes from

C<h> renders the module's own POD at run time. That POD is generated from
C<README.md>, so C<h> and this document can never disagree. A function with no
section of its own — an internal helper, or C<ptukey> / C<qtukey> — prints the
list of functions that do have one.

Output is wrapped to C<$ENV{COLUMNS}> when that is set (clamped to 40-100
columns), and to 80 otherwise. Parameter tables are rendered as aligned plain
text.

=head2 h2aoh

Unfold a plain hash into a two-column B<array-of-hashes>, one row per pair.

 my $aoh = h2aoh(\%h);
 my $aoh = h2aoh(\%h, var_name => 'gene', value_name => 'n');

A flat hash is a two-column table that has been folded shut: every pair is a
row, the key in one cell and the value in the other. C<h2aoh> unfolds it, which
turns a result that no frame function will accept — C<value_counts> hands one
back — into a data frame that all of them will:

 my $counts = value_counts($titanic, 'Pclass');   # { 1 => 216, 2 => 184, 3 => 491 }
 my $tbl    = h2aoh($counts, var_name => 'Pclass', value_name => 'n',
                    sort => 'value');
 view($tbl);
 # AoH: 3 rows x 2 cols   (showing 3)
 #    Pclass    n
 # 0       3  491
 # 1       1  216
 # 2       2  184

R spells this C<tibble::enframe()>; base R gets close with
C<stack()> or C<data.frame(name = names(x), value = unname(x))>. In pandas it is
C<pd.Series(d).rename_axis('k').reset_index(name = 'v')>, or the shorter
C<pd.DataFrame(d.items(), columns = ['k', 'v'])>.

=head3 Arguments

C<$h> — a hash ref whose values are plain scalars. Required.

Everything after it is C<< name =E<gt> value >> pairs:

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>var_name</code></td>
  <td><code>variable</code></td>
  <td>Name of the column that receives the hash keys.</td>
</tr>
<tr>
  <td><code>value_name</code></td>
  <td><code>value</code></td>
  <td>Name of the column that receives the hash values.</td>
</tr>
<tr>
  <td><code>sort</code></td>
  <td><code>key</code></td>
  <td>Row order — see below.</td>
</tr>
</tbody>
</table>

C<var_name> and C<value_name> must differ. They are the same two option names
L<C<melt>|/"melt"> uses, because they name the same two columns.

=head3 Row order

Hash iteration order is not reproducible between runs, so the rows are sorted
by default rather than left to chance.

=for html <table>
<thead>
<tr>
  <th><code>sort</code></th>
  <th>Order</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>key</code></td>
  <td>By key. Numerically when every key looks like a number, alphabetically otherwise — the rule [<code>agg</code>](#agg) uses for its group keys. This is the default.</td>
</tr>
<tr>
  <td><code>value</code></td>
  <td>By value: largest first when every defined value is a number, which is the order <code>value_counts</code> output usually wants; alphabetically ascending when they are not. <code>undef</code> values sort last, and ties break on the key.</td>
</tr>
<tr>
  <td><code>none</code></td>
  <td>Whatever order the hash iterates in. Cheapest, and the right choice when you are about to sort the result yourself with [<code>csort</code>](#csort).</td>
</tr>
</tbody>
</table>

=head3 Returns

An array ref of two-key hash refs, one per pair:

 h2aoh({ a => 1, b => 2 });
 # [ { variable => 'a', value => 1 }, { variable => 'b', value => 2 } ]

An empty hash gives back C<[]>. C<undef> values are carried through as C<undef>.

=head3 Errors

C<h2aoh> dies when the argument is undefined or not a hash ref, when the options
are not C<< name =E<gt> value >> pairs, when an option is unknown, when C<var_name>
equals C<value_name>, or when C<sort> is not one of the three allowed words.

It also dies when any value is a B<reference>, naming the key and pointing at
the converter that was probably meant: a hash of array refs is
L<C<hoa2aoh>|/"hoa2aoh">'s job, and a hash of hash refs is
L<C<hoh2hoa>|/"hoh2hoa">'s. Stringifying C<ARRAY(0x…)> into a cell would be the
only other option, and it is never what anyone wanted.

=head3 See also

L<C<aoh2h>|/"aoh2h"> is the reverse. L<C<melt>|/"melt"> does the same folding-out for
a frame that already has more than two columns.

=head2 hoa2aoh

Turn a hash-of-arrays into an array-of-hashes.

=head3 Usage

 my $aoh = hoa2aoh($hoa);

=over

=item * B<< C<$hoa> >> — a hashref whose values are arrayrefs, one per column:

=back

 { id => [1, 2, 3], name => ['a', 'b', 'c'] }

=over

=item * B<returns> — an arrayref of row hashrefs:

=back

 [
     { id => 1, name => 'a' },
     { id => 2, name => 'b' },
     { id => 3, name => 'c' }
 ]

It builds a brand-new structure and copies every cell, so the result is
completely independent of the input — changing one never affects the other.

=head3 Example

 my $hoa = { mpg => [21, 22.8, 18.1], cyl => [6, 4, 6] };
 my $aoh = hoa2aoh($hoa);
 $aoh->[1]{mpg};        # 22.8
 $hoa->{mpg}[1];        # still 22.8 — unaffected by edits to $aoh

=head3 Good to know

=over

=item * B<Row count> is the length of the longest column. If columns have different
lengths, the short ones are padded with C<undef> in the missing rows.

=item * B<< C<undef> cells >> are kept as C<undef>.

=item * An B<empty hash>, or one whose columns are all empty, gives back C<[]>.

=item * It B<dies> if the argument isn't a hashref, or if any column value isn't an
arrayref (the message names the offending column).

=back

=head3 See also

C<hoa2aoh> is the reverse of C<aoh2hoa>

=head2 hoa2hoh( \%hoa, $key )

Converts a hash-of-arrays (column-major) into a hash-of-hashes keyed by the
C<$key> column, i.e. C<< { $rowname =E<gt> { col =E<gt> value, ... } } >>. Analogous to
C<hoa2aoh>, but rows are indexed by their C<$key> value instead of positionally.

 my %hoa = (
     id => [ qw(a b c) ],
     x  => [ 1, 2, 3 ],
     y  => [ 4, 5, 6 ],
 );
 my $hoh = hoa2hoh( \%hoa, 'id' );
 # { a => { id => 'a', x => 1, y => 4 }, b => {...}, c => {...} }

The C<$key> column is retained in each inner row. Columns are copied by value.
Shorter columns are padded with C<undef>, matching C<hoa2aoh>.

Dies if: the first argument is not a hashref of arrayrefs; C<$key> is undef or
names a missing/non-array column; the C<$key> column holds an undefined value
for any row; or two rows share the same C<$key> value.

=head2 hoh2hoa

Convert a B<hash of hashes> (row-major: outer key = row, inner key = column)
into a B<hash of arrays> (column-major: key = column, value = that column's
cells down the rows).

 use Stats::LikeR;

 my %hoh = (
     'r1' => { 'a' => 1, 'b' => 2 },
     'r2' => { 'a' => 3, 'b' => 4 },
 );

 my $hoa = hoh2hoa(\%hoh);

which returns

 {
   a => [1, 3],
   b => [2, 4],
 }

=head3 Behavior

=over

=item * B<Columns> are the union of every inner key, so a key that appears in only
some rows still becomes a column.

=item * B<Rows> are emitted in sorted outer-key (row-name) order, and that one order
is used for every column, so the arrays stay aligned and the result is
reproducible regardless of hash ordering.

=item * B<Gaps> — a missing inner key, or a cell whose value is C<undef> — are filled
with the fill value (see C<undef.val> below). Every column therefore has
exactly one entry per row.

=item * Values are B<copied> into the result; the original structure is left
untouched.

=item * An B<empty> hash of hashes returns an empty hash of arrays (it is not an
error).

=back

=head3 Options

Options are passed as trailing C<< name =E<gt> value >> pairs.

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>undef.val</code></td>
  <td><code>undef</code></td>
  <td>Value used to fill a missing key or an <code>undef</code> cell. Any defined scalar works, including <code>0</code> and <code>''</code>. Passing <code>undef</code> keeps the default.</td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td><i>(none)</i></td>
  <td>If set to a string, an extra column of that name is added holding the sorted row labels, aligned with the data. Dies if the name collides with an existing column.</td>
</tr>
</tbody>
</table>

 # Ragged input with an explicit fill string:
 my %ragged = (
     'r1' => { 'a' => 1, 'b' => 2 },
     'r2' => { 'a' => 3, 'c' => 9 },
 );
 my $hoa = hoh2hoa(\%ragged, 'undef.val' => 'NA');
 # {
 #   a => [1,    3   ],
 #   b => [2,    'NA'],
 #   c => ['NA', 9   ],
 # }

 # Keep the row labels as a column:
 my $with_ids = hoh2hoa(\%ragged, 'row.names' => 'id');
 # {
 #   id => ['r1', 'r2'],
 #   a  => [1,    3   ],
 #   b  => [2,    undef],
 #   c  => [undef, 9  ],
 # }

=head3 Errors

C<hoh2hoa> dies (via C<croak>) when:

=over

=item * the argument is not a hash reference,

=item * any value in the hash is not itself a hash reference,

=item * an unknown option is given, or the options are not C<< name =E<gt> value >> pairs,

=item * C<row.names> is not a plain string, or it names an already-present column.

=back

=head2 hist

Computes the histogram of the given data values, operating in single $O(N)$ pass performance. It returns the bin counts, computed breaks, midpoints, and density. 

 my $res = hist([1, 2, 2, 3, 3, 3, 4, 4, 5], breaks => 4);

If C<breaks> is not explicitly provided, it defaults to calculating the number of bins using Sturges' formula.

=head2 hosmer_lemeshow

The Hosmer-Lemeshow goodness-of-fit test for a logistic-regression model. Given
the observed 0/1 outcomes and the model's predicted probabilities, it bins the
observations into C<g> risk groups (deciles by default) and compares observed and
expected event counts. A large p-value indicates the model fits adequately. The
grouping and statistic follow R's C<ResourceSelection::hoslem.test>, against which
it was validated numerically.

 # $fit is a binomial glm(); align observed outcomes with fitted.values
 my @obs  = map { $data{$_}{outcome} } @ids;
 my @prob = map { $fit->{'fitted.values'}{$_} } @ids;

 my $hl = hosmer_lemeshow(\@obs, \@prob, g => 10);
 printf "HL chi2=%.2f df=%d p=%.3f\n", $hl->{statistic}, $hl->{parameter}, $hl->{p_value};

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>observed</i></td>
  <td><code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>Observed binary outcomes (0/1).</td>
  <td><code>\@obs</code></td>
</tr>
<tr>
  <td><i>predicted</i></td>
  <td><code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>Model-predicted probabilities (same length).</td>
  <td><code>\@prob</code></td>
</tr>
<tr>
  <td><code>g</code></td>
  <td><code>Integer</code></td>
  <td><code>10</code></td>
  <td>Number of risk groups (quantile bins).</td>
  <td><code>10</code></td>
</tr>
</tbody>
</table>

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>statistic</code></td>
  <td><code>Double</code></td>
  <td>Hosmer-Lemeshow chi-squared statistic.</td>
  <td><code>4.3456</code></td>
</tr>
<tr>
  <td><code>parameter</code></td>
  <td><code>Integer</code></td>
  <td>Degrees of freedom, <code>g - 2</code>.</td>
  <td><code>8</code></td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td><code>Double</code></td>
  <td>Goodness-of-fit p-value (large = good fit).</td>
  <td><code>0.825</code></td>
</tr>
<tr>
  <td><code>groups</code></td>
  <td><code>Integer</code></td>
  <td>Number of non-empty groups used.</td>
  <td><code>10</code></td>
</tr>
<tr>
  <td><code>table</code></td>
  <td><code>ArrayRef</code></td>
  <td>Per-group <code>{n, observed, expected}</code> event summaries.</td>
  <td></td>
</tr>
</tbody>
</table>

=head2 interpolate

Fill NA (undef) cells along the row axis, like C<pandas.DataFrame.interpolate>.
It is the numeric sibling of C<ffill>/C<bfill>: rather than only propagating a
neighbour's value into a gap, it can fit a curve (line, spline, polynomial…)
through the surrounding numeric values and read the gap off that curve. B<Every
one of pandas' interpolation methods is supported> and matched to pandas /
scipy within C<1e-6> (see I<Method accuracy> below).

 interpolate($df,
     method          => 'cubic',      # any method below (default: 'linear')
     cols            => [ 'v' ],      # restrict to these columns (default: every column)
     order           => 3,            # degree, required by 'polynomial' / 'spline'
     x               => 't',          # abscissae: column name/index or arrayref
     limit           => 2,            # max cells filled per NA run (default: unlimited)
     limit_direction => 'forward',    # 'forward' (default), 'backward', or 'both'
     limit_area      => 'inside',     # 'inside', 'outside', or omit for both
 );

Column identifiers are names for AoH/HoA/HoH and 0-based positions for AoA. The
row axis is positional for AoA/AoH/HoA and string-sorted key order for HoH — the
same shape and ordering rules as C<ffill>/C<bfill>. Returns a NEW frame; the input
is never modified.

=head3 Methods

=for html <table>
<thead>
<tr>
  <th><code>method</code></th>
  <th>What it does</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>linear</code> <i>(default)</i></td>
  <td>straight line between the nearest anchors, rows equally spaced</td>
</tr>
<tr>
  <td><code>index</code>, <code>values</code>, <code>time</code></td>
  <td>straight line, but spaced by the <code>x</code> coordinates</td>
</tr>
<tr>
  <td><code>slinear</code></td>
  <td>piecewise linear, interior gaps only</td>
</tr>
<tr>
  <td><code>nearest</code></td>
  <td>value of the nearer anchor, interior only</td>
</tr>
<tr>
  <td><code>zero</code></td>
  <td>value of the left anchor (zero-order hold), interior only</td>
</tr>
<tr>
  <td><code>pad</code> / <code>ffill</code></td>
  <td>hold the last value forward</td>
</tr>
<tr>
  <td><code>bfill</code> / <code>backfill</code></td>
  <td>hold the next value backward</td>
</tr>
<tr>
  <td><code>quadratic</code>, <code>cubic</code></td>
  <td>degree-2 / degree-3 interpolating B-spline (scipy <code>interp1d</code>)</td>
</tr>
<tr>
  <td><code>cubicspline</code></td>
  <td>not-a-knot cubic spline (scipy <code>CubicSpline</code>)</td>
</tr>
<tr>
  <td><code>pchip</code></td>
  <td>monotone piecewise cubic Hermite (Fritsch–Carlson)</td>
</tr>
<tr>
  <td><code>akima</code></td>
  <td>Akima piecewise cubic</td>
</tr>
<tr>
  <td><code>barycentric</code>, <code>krogh</code></td>
  <td>single global polynomial through all anchors</td>
</tr>
<tr>
  <td><code>polynomial</code></td>
  <td>degree-<code>order</code> interpolating spline (<code>order</code> required)</td>
</tr>
<tr>
  <td><code>spline</code></td>
  <td>interpolating spline of degree <code>order</code> (<code>order</code> required)</td>
</tr>
</tbody>
</table>

=head3 How gaps and edges are filled

Interpolation follows pandas exactly: every gap is filled from the method, then
cells that C<limit> / C<limit_direction> / C<limit_area> forbid are blanked back to
NA. Only numeric cells B<anchor> a fill; a defined non-numeric cell is preserved
(and, for the piecewise-local methods, blocks interpolation across it).

B<Interior gaps> (anchors on both sides) are always filled. B<Leading/trailing
gaps> (an edge with anchors on one side only) behave by method family:

=over

=item * C<linear> and the hold methods (C<pad>/C<bfill>) fill the edge with the held
constant, subject to C<limit_direction>.

=item * C<barycentric>, C<krogh>, C<cubicspline>, C<pchip> B<extrapolate> the edge from
the fitted curve, again subject to C<limit_direction>.

=item * the C<interp1d> family (C<nearest>, C<zero>, C<slinear>, C<quadratic>, C<cubic>,
C<polynomial>), C<akima>, and C<spline> are B<interior-only> — they leave
leading/trailing gaps as NA, matching scipy.

=back

C<limit_direction> chooses which edge is filled (C<forward> → trailing, C<backward>
→ leading, C<both> → both) and, with C<limit>, which cells a run's cap reaches.
C<limit_area> restricts filling to C<'inside'> (interior) or C<'outside'>
(edges only). Interpolated cells are floats; filling stays within each column's
existing length (ragged HoA columns and short AoA rows are not extended).

=head3 The C<x> argument

By default rows are equally spaced (C<0, 1, 2, …>). Pass C<x> to interpolate
against real abscissae — either an arrayref (one coordinate per row) or a column
name/index whose numeric values are the coordinates. C<x> must be strictly
increasing and is used by every method except plain C<linear> semantics (use
C<index>/C<values> for a line on unequal spacing).

 # linear fit on unequal spacing
 interpolate({ v => [ 0, undef, undef, 10 ] }, method => 'index', x => [ 0, 1, 3, 4 ]);
 # { v => [ 0, 2.5, 7.5, 10 ] }

 # interpolate v against a time column t
 interpolate($df, cols => [ 'v' ], x => 't', method => 'index');

=head3 Examples

 # linear: interior interpolated, trailing held (forward default), leading NA
 interpolate({ v => [ undef, 1, undef, undef, 4, undef ] });
 # { v => [ undef, 1, 2, 3, 4, 4 ] }

 # cubic spline through four anchors that lie on x^2, so the fit is exact
 interpolate({ v => [ 0, undef, undef, 9, 16, 25 ] }, method => 'cubic', limit_direction => 'both');
 # { v => [ 0, 1, 4, 9, 16, 25 ] }

 # monotone pchip vs. a global polynomial on the same gaps
 interpolate({ v => [ 2, undef, 3, undef, undef, 2, 5, undef, 0 ] }, method => 'pchip', limit_direction => 'both');

=head3 Method accuracy

C<linear>, C<index>/C<values>/C<time>, C<slinear>, C<nearest>, C<zero>, C<pad>/C<ffill>,
C<bfill>/C<backfill>, C<quadratic>, C<cubic>, C<cubicspline>, C<pchip>, C<akima>,
C<barycentric>, C<krogh>, and C<polynomial> reproduce pandas/scipy to machine
precision (the test suite compares against pandas 2.2.3 / scipy 1.15.2).

Two deliberate departures from pandas:

=over

=item * B<< C<spline> >> is the I<interpolating> spline of degree C<order> (equivalent to
pandas' C<spline> with C<s=0>), because pandas' default C<spline> is a FITPACK
I<smoothing> spline that is not reproducible without FITPACK. It does not
extrapolate edges. C<polynomial>/C<spline> support C<order> 1, 2, or 3.

=item * A defined B<non-numeric> cell is treated as a barrier by the piecewise-local
methods; pandas has no equivalent (its columns are all-numeric).

=back

 > Performance: the per-column numeric core (every method, the linear solve and
 > the preserve mask) runs in XS. Versus the former pure-Perl kernels this is
 > roughly 5× faster for C<linear> on a large column, ~11× for C<pchip>, and ~50×
 > for the spline methods whose dense solve dominates. The fit-based methods
 > still use a dense solve, so they target modest per-column anchor counts.

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument or
method; C<polynomial>/C<spline> without an integer C<order> in 1–3; a C<cols> or C<x>
column that does not exist; too few anchors for the chosen method; an C<x> that is
not strictly increasing or whose length does not match; a C<limit> that is not a
positive integer; or an invalid C<limit_direction>/C<limit_area>.

=head2 intersection

Returns the set intersection (∩) of a list of array references: the values
that appear in B<every> array ref given.

 use Stats::LikeR;

 my @i = intersection([1, 2, 3], [2, 3, 4]);          # (2, 3)
 my @t = intersection([1, 2, 3, 4], [2, 3, 4], [3, 4]); # (3, 4)
 my $n = intersection([1, 2, 3], [2, 3, 4]);          # 2

Every argument must be an array reference: each one is treated as a set.
Unlike C<mean> and C<uniq>, bare scalars are not accepted; passing a non-reference
(or a non-array reference) croaks.

The result is B<deduplicated> and ordered by first appearance in the I<first>
array ref. Duplicate values within any single ref are counted once, so
C<intersection([1, 2, 2, 3], [2, 3, 3, 4])> is C<(2, 3)>, not C<(2, 2, 3)>.

Values are compared by stringification — the same C<eq> semantics used by
C<uniq>. C<1>, C<1.0>, and C<"1"> are treated as equal, while C<"3"> and C<"3.0">
are distinct. The UTF-8 flag is part of the comparison key, so a UTF-8 string
and a byte-identical non-UTF-8 string are kept separate.

In list context C<intersection> returns the shared values; in scalar context it
returns the cardinality (the number of shared values).

With a single array ref, the result is simply that ref's unique values. If any
ref is empty, the intersection is empty.

C<intersection> croaks on degenerate or ill-formed input, reporting the
offending position:

 intersection();              # croaks: intersection needs >= 1 array ref
 intersection([1, 2], 3);     # croaks: argument 1 is not an array ref
 intersection([1, undef, 3]); # croaks: undefined value at array ref index 1 (argument 0)

This matches the undef-handling of C<mean> and C<uniq> and the rest of the
numeric reducers in Stats::LikeR.

=head2 is_equivalent

C<is_equivalent(\@a, \@b, ...)> returns B<1> if every list holds the same
I<set> of distinct values, and B<0> otherwise. Order and duplicates don't
count — only which values are present.

Think of each list as a bag, dump each bag into its own set, and ask: are all
the sets identical?

 is_equivalent([1,2,3], [3,2,1])     # 1  same values, different order
 is_equivalent([1,1,2], [2,1])       # 1  duplicates ignored
 is_equivalent([1,2,3], [1,2])       # 0  right is missing 3
 is_equivalent([1,2],   [1,2,3])     # 0  right has an extra 4
 is_equivalent([1,2], [2,1], [1,2])  # 1  works for any number of lists

It generalises C<List::Compare>'s C<is_LequivalentR()> from two lists to N.

=head3 How it decides

Equivalence is transitive: if every list equals the first list, they all equal
each other. So the check is simple — build the distinct-value set of the
B<first> list, then hold each other list up against it. A list matches when:

=over

=item 1. it contains B<no value outside> the first set, and

=item 2. it B<covers every value> in the first set.

=back

Fail either test for any list and the answer is 0.

=head3 Edge cases

 is_equivalent([], [])        # 1  two empty sets are equal
 is_equivalent([], [1])       # 0  empty vs non-empty
 is_equivalent([1], [1], [1]) # 1

Values are compared B<as strings> (like hash keys), so C<1> and C<"1"> are the
same, but C<2> and C<"2.0"> are not.

=head3 Rules

=over

=item * Pass B<at least two> array refs. Fewer croaks.

=item * Every argument must be an B<array ref>; anything else croaks.

=item * B<< C<undef> inside a list croaks >> — decide what a missing value means before
calling, rather than letting it silently match.

=back

=head2 kruskal_test

Essentially the test determines if all groups have the same median (same distribution) (an excellent review is at https://library.virginia.edu/data/articles/getting-started-with-the-kruskal-wallis-test)

Performs a Kruskal-Wallis rank sum test, see 
https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/kruskal.test

=head3 hash of array entry

I feel that this is better, and more easily read, than what you get in R:

 my %x = (
 'normal.subjects' => [2.9, 3.0, 2.5, 2.6, 3.2],
 'obs. airway disease' => [3.8, 2.7, 4.0, 2.4],
 'asbestosis' => [2.8, 3.4, 3.7, 2.2, 2.0]
 );
 $kt = kruskal_test(\%x);

=head3 R-like array entry

 my @xk = (2.9, 3.0, 2.5, 2.6, 3.2); # normal subjects
 my @yk = (3.8, 2.7, 4.0, 2.4);      # with obstructive airway disease
 my @zk = (2.8, 3.4, 3.7, 2.2, 2.0); # with asbestosis
 my @x = (@xk, @yk, @zk);
 my @g = (
     (map {'Normal subjects'} 0..4),
     (map {'Subjects with obstructive airway disease'} 0..3),
     map {'Subjects with asbestosis'} 0..4
 );
 my $kt = kruskal_test(\@x, \@g);

=head2 ks_test

The Kolmogorov–Smirnov test checks whether two samples are drawn from the
same distribution (two-sample), or whether a single sample is drawn from a
given reference distribution (one-sample). It works by comparing the empirical
cumulative distribution functions (ECDFs) and measuring the largest gap
between them.

Two-sample form — pass two array references:

 $ks = ks_test(\@x, \@y);
 $ks = ks_test(\@x, \@y, alternative => 'greater');

One-sample form — pass one array reference and the name of a reference CDF.
Currently only C<'pnorm'> is supported, i.e. the standard normal distribution
(mean 0, standard deviation 1):

 $ks = ks_test(\@x, 'pnorm');

Arguments may be given positionally (as above) or by name:

 $ks = ks_test(x => \@x, y => \@y, alternative => 'less', exact => 1);

Non-numeric, undefined and NaN elements are silently dropped before the test
runs, matching R's C<x[!is.na(x)]>.

C<alternative> selects which gap between the ECDFs is measured:

=over

=item * C<'two.sided'> (default) — the largest gap in either direction,
D = sup |F_x − F_y|.

=item * C<'greater'> — the largest gap where x's ECDF rises above the other,
D⁺ = sup (F_x − F_y).

=item * C<'less'> — the largest gap in the other direction, D⁻ = sup (F_y − F_x).

=back

These follow R's C<ks.test> convention: C<'greater'>/C<'less'> describe which CDF
lies I<above> the other, which (because a higher CDF means smaller values) is
the opposite of which sample tends to be larger.

C<exact> controls how the p-value is computed. Omit it to let the test choose:
the exact distribution is used for small samples (two-sample when nx·ny 
10000, one-sample when n < 100) and the asymptotic (Kolmogorov limiting)
approximation otherwise. Pass C<< exact =E<gt> 1 >> to force the exact computation or
C<< exact =E<gt> 0 >> to force the asymptotic one. Exact p-values cannot be computed
when the data contain ties; if ties are present on the exact path, the test
warns and falls back to the asymptotic p-value. (The exact one-sample test is
only available for the two-sided alternative; a one-sided one-sample request
also falls back to asymptotic.) In either fallback the returned C<method> is
the asymptotic one, so it always names the p-value you actually got.

=head3 Return value

C<ks_test> returns a hash reference with four keys:

=over

=item * B<< C<statistic> >> — the KS statistic for the chosen C<alternative>: D, D⁺, or
D⁻. It is the maximum distance between the two ECDFs (or, for the one-sample
test, between the ECDF and the reference CDF), always in the range [0, 1].
Larger values mean the distributions are further apart.

=item * B<< C<p_value> >> — the probability, under the null hypothesis that the samples
share a distribution, of observing a statistic at least this large. It is
clamped to [0, 1]; a small value (e.g. < 0.05) is evidence against the null.

=item * B<< C<method> >> — a human-readable description of exactly what was run, handy
for logging or reproducing a result. One of:
C<"Two-sample Kolmogorov-Smirnov exact test">,
C<"Two-sample Kolmogorov-Smirnov test (asymptotic)">,
C<"One-sample Kolmogorov-Smirnov exact test">, or
C<"One-sample Kolmogorov-Smirnov test (asymptotic)">.

=item * B<< C<alternative> >> — the alternative hypothesis that was applied
(C<'two.sided'>, C<'greater'>, or C<'less'>), echoed back so the result is
self-describing.

=back

For example:

 my $ks = ks_test(\@x, \@y);
 if ($ks->{p_value} < 0.05) {
     printf "reject H0: D=%.4f, p=%.4g (%s)\n",
         $ks->{statistic}, $ks->{p_value}, $ks->{method};
 }

=head2 kurtosis

Sample excess kurtosis — how much of the variance sits in the tails rather than
near the shoulders. The C<3> of a normal distribution is already subtracted, so a
normal sample gives roughly C<0>, a heavy-tailed one a positive number, and a flat
or bimodal one a negative number. Add C<3> if you want the plain fourth
standardized moment. Validated numerically against R.

 kurtosis(2, 4, 4, 4, 5, 5, 7, 9);        # 0.940625

Arguments work as they do for L</"sd"> and L</"var">: plain numbers, array
references, or any mixture of the two, all flattened into one sample.

 my @x = (2, 4, 4, 4, 5, 5, 7, 9);
 kurtosis(@x);                  # a list
 kurtosis(\@x);                 # an array reference
 kurtosis([2, 4, 4], 4, [5, 5, 7, 9]);   # mixed; same sample
 kurtosis(x => \@x);            # named, if you prefer it

=head3 C<type>

There are three conventions in circulation for turning the moment ratio into a
sample statistic, and they disagree noticeably on small samples. C<type> picks
one; the default is C<2>.

=for html <table>
<thead>
<tr>
  <th><code>type</code></th>
  <th>Statistic</th>
  <th>Also known as</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>g2</code></td>
  <td>the plain moment ratio; R's <code>moments::kurtosis</code> minus 3</td>
</tr>
<tr>
  <td>2</td>
  <td><code>G2</code></td>
  <td><b>the default</b>; SAS, SPSS, Stata, Excel's <code>KURT()</code>, <code>scipy.stats.kurtosis(bias =&gt; FALSE)</code></td>
</tr>
<tr>
  <td>3</td>
  <td><code>b2</code></td>
  <td><code>e1071::kurtosis</code>'s own default</td>
</tr>
</tbody>
</table>

where, writing C<m2> and C<m4> for the second and fourth central moments (each
divided by C<n>):

 g2 = m4 / m2**2 - 3                                     # type 1
 G2 = ((n + 1) * g2 + 6) * (n - 1) / ((n - 2) * (n - 3))  # type 2, the default
 b2 = (g2 + 3) * (1 - 1 / n)**2 - 3                      # type 3

 my @x = (1, 2, 3, 10);
 kurtosis(\@x, type => 1);   # -0.7696   plain moment ratio
 kurtosis(\@x);              #  3.228    G2, the default
 kurtosis(\@x, type => 3);   # -1.7454   b2

C<< type =E<gt> 2 >> is the estimator that is unbiased for a normal sample, which is why
it is the default and why it is what every general-purpose statistics package
reports. It divides by C<n - 3>, so it needs at least four values; the other two
need at least two.

 my $shape = { skew => skew($lab), kurtosis => kurtosis($lab) };

=head3 Errors

C<kurtosis> croaks, naming the offending position, on an undefined value:

 kurtosis(1, undef, 3);
 # kurtosis: undefined value at argument index 1

 kurtosis([1, 2, undef]);
 # kurtosis: undefined value at array ref index 2 (argument 0)

and on a sample too small for the chosen C<type>, on a C<type> outside C<1 .. 3>, or
on a constant sample, which has no shape to report:

 kurtosis([7, 7, 7, 7]);
 # kurtosis: zero variance (all 4 values are equal), so kurtosis is undefined

=head3 See also

L</"skew"> for the third moment, L</"sd"> and L</"var"> for the second,
L</"shapiro_test"> to test normality rather than describe the
departure from it.

=head2 ljoin

Consider a hash: C<$h{$row}{$col}>, and another hash C<$i{$row}{$col2}>.
C<ljoin> will add information for C<$col> in C<%i> for each C<$row> to C<%h>, where C<$row> exists in both C<%h> and C<%i>.
Similar to C<cbind> in R.

For example,

 {
 "Jack Smith"   {
     age   30
 }
 }

and a second hash,

 {
     "Jack Smith"   {
         dept   "Engineering"
     },
     "Jane Doe"     {
         age   25
     }
 }

in this case, running C<ljoin(\%h, \%i)> will modify \%h to result:

 {
 "Jack Smith"   {
     age    30,
     dept   "Engineering"
 }
 }

=head2 lm

This is the linear models function.

 $lm = lm(formula =>  'mpg ~ wt + hp', data => $mtcars);

where C<$mtcars> is a hash of hashes

C<lm> also supports generating interaction terms directly within the formula using the C<*> operator:

 my $lm = lm(formula => 'mpg ~ wt * hp^2', data => \%mtcars);

Crossing is associative, so C<*> chains to any depth: C<y ~ a * b * c> expands to
every non-empty subset of the three (C<a>, C<b>, C<c>, C<a:b>, C<a:c>, C<b:c>,
C<a:b:c>), ordered by degree as R's C<terms()> orders them. Writing C<a:b> directly
gives just that one product.

Either side of an interaction may be a string (categorical) column, in which
case it expands to indicator columns the same way a main effect does:
C<len ~ dose * supp> yields C<dose>, C<suppVC> and C<dose:suppVC>.

Whether a categorical column keeps all of its levels or drops the first as a
reference follows R's margin rule: the reference level is dropped when the term
with that column removed is itself in the model. A main effect's margin is the
intercept, so C<y ~ g> drops g's first level — but C<y ~ g - 1> has no intercept
to measure against and so keeps every level, one column per group. Where two
categorical main effects both have no intercept, only the first can be coded in
full (C<y ~ a + b - 1> gives every level of C<a> and drops C<b>'s reference),
because coding both in full would be rank deficient. A bare C<y ~ a:b> with
neither main effect present codes both in full and spans the whole
cross-classification.

If your data contains missing numbers (C<NA> or C<undef>), C<lm> handles listwise deletion dynamically to ensure mathematical integrity before fitting. A row whose categorical value is missing is dropped the same way.

Three details differ from R deliberately:

=over

=item * Levels are sorted with C<strcmp>, i.e. by byte value, which is what
C<patsy>/C<pandas> does. R sorts with the collation of the running locale, so a
factor whose levels differ only in case takes a different reference level in
the two: on C<c("b", "A", "a")> R takes C<a> and C<lm> takes C<A>. Both
parameterise the same fit — residual sum of squares, rank and fitted values
agree — but the coefficient names and values differ.

=item * A term crossed with itself keeps the product, so C<wt:wt> is C<wt> squared and
C<y ~ wt*wt> fits C<y ~ wt + I(wt^2)>. R's formula algebra collapses C<a:a> to
C<a>, making the same formula mean C<y ~ wt> there.

=item * A categorical column with only one level contributes no column, so
C<y ~ x + g> fits C<y ~ x>. R refuses the model outright ("contrasts can be
applied only to factors with 2 or more levels").

=back

the dot operator also works:

 $lm = lm(formula => 'y ~ .', data => $dot_data);

C<lm> and C<glm> read their formula and their data through the same code, so
everything above holds for both, and a fit's C<terms> are the terms the other
function would have produced from the same string.

Rows are labelled from a C<row.names>, C<_row>, C<rownames> or C<.rownames> column if
the data has one (a HoH labels rows with its outer keys, which needs no such
column), and 1-based integers otherwise. Those labels are the keys of
C<fitted.values> and C<residuals>, and the row names C<predict> returns. A row-name
column is a label rather than a measurement, so C<y ~ .> leaves it out of the
predictors.

The overall model F test is returned as C<fstatistic> (an array ref of C<F>,
numerator df, denominator df) and C<f.pvalue>. C<f.pvalue> is evaluated in the
upper tail of the F distribution rather than as C<1 - pf(F, df1, df2)>, so a
strongly significant model reports its actual p-value instead of a flat C<0>;
see L</"F and z tail p-values">. The per-coefficient
C<< Pr(E<gt>|t|) >> values were already computed as a direct two-tail probability and
are unaffected.

=head2 logrank_test

The log-rank (Mantel–Cox) test: do the survival curves of two or more groups
differ? It needs no modelling assumptions. Same as R's C<survival::survdiff>.

Give times, an event flag (1 = event, 0 = censored), and a group label per row:

 use Stats::LikeR 'logrank_test';

 my $r = logrank_test(\@time, \@status, \@group);
 print $r->{p_value};

Result keys: C<statistic> (chi-squared), C<parameter> (df = groups − 1),
C<p_value>, C<observed> and C<expected> events per group, and C<groups>. See
L<C<survfit>|/"survfit"> for the curves and L<C<coxph>|/"coxph"> to adjust for
covariates.

=head2 Lonly

 my @only_first = Lonly(\@a, \@b, \@c);
 my $count      = Lonly(\@a, \@b, \@c);

Takes one or more array references and returns the values that appear in the
B<first> reference and in B<no other> reference; with a single reference it
returns that list's distinct values. Duplicates collapse, the result keeps
first-appearance order, and scalar context returns the count. Values are
compared by string form (see C<get_union>). A non-array-ref argument or an
C<undef> element is fatal. With exactly two references this is the left-only
set difference. Mirrors C<List::Compare>'s C<get_unique>, which likewise
defaults to the first list.

 my @a = (1, 2, 3);
 my @b = (3, 4, 5);
 my @c = (5, 6);
 my @u = Lonly(\@a, \@b, \@c);           # (1, 2)  -- 3 is also in @b

=head2 matrix

 my $mat1 = matrix(
     data => [1..6],
     nrow => 2
 );

You can also pass C<< byrow =E<gt> 1 >> if you want the matrix populated row-wise instead of column-wise.

Parameters do not need to be named, so that C<matrix> works more like R:

 my $d = matrix(rnorm(32000), 1000, 32);

works as C<data>, C<nrow>, and C<ncol>

=head2 max

 max(1,2,3);

or

 my @arr = 1..8;
 max(@arr, 4, 5)

max will die if any undefined values are provided

=head2 mcnemar_test

McNemar's test for paired categorical data (e.g. before/after, matched
case-control, two raters), a faithful port of R's C<stats::mcnemar.test>. It
assesses whether the off-diagonal disagreement in a square table is symmetric.
For a 2×2 table a Yates continuity correction is applied by default (toggle with
C<correct>); C<< exact =E<gt> 1 >> instead performs the two-sided exact binomial test.
Larger C<k × k> tables use the generalized chi-square (df = C<k(k-1)/2>). Validated
numerically against R.

 # counts as a square matrix: [[a, b], [c, d]]
 my $r = mcnemar_test([[794, 86], [150, 570]]);
 printf "chi2=%.2f df=%d p=%.4g\n", $r->{statistic}, $r->{parameter}, $r->{p_value};

 # small samples: exact binomial test on the discordant pairs
 my $e = mcnemar_test([[794, 86], [150, 570]], exact => 1);

 # paired observation vectors are cross-tabulated automatically
 my $v = mcnemar_test(\@before, \@after);

The first argument is either a square matrix (array of array refs) or, in the
two-argument form, two equal-length vectors of paired observations that are
cross-tabulated over their sorted union of levels.

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>table</i> / <i>x</i></td>
  <td><code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>A square <code>k × k</code> count matrix, or (two-arg form) the first vector of paired observations.</td>
  <td><code>[[794,86],[150,570]]</code></td>
</tr>
<tr>
  <td><i>y</i></td>
  <td><code>ArrayRef</code></td>
  <td><i>None</i></td>
  <td>Second vector of paired observations (two-arg form only).</td>
  <td><code>\@after</code></td>
</tr>
<tr>
  <td><code>correct</code></td>
  <td><code>Boolean</code></td>
  <td><code>1</code></td>
  <td>Apply the Yates continuity correction (2×2 only).</td>
  <td><code>0</code></td>
</tr>
<tr>
  <td><code>exact</code></td>
  <td><code>Boolean</code></td>
  <td><code>0</code></td>
  <td>Use the two-sided exact binomial test (2×2 only).</td>
  <td><code>1</code></td>
</tr>
</tbody>
</table>

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>statistic</code></td>
  <td><code>Double</code></td>
  <td>McNemar's chi-squared (or, for <code>exact</code>, the discordant success count <i>b</i>).</td>
  <td><code>16.8178</code></td>
</tr>
<tr>
  <td><code>parameter</code></td>
  <td><code>Integer</code></td>
  <td>Degrees of freedom, <code>k(k-1)/2</code> (absent for <code>exact</code>).</td>
  <td><code>1</code></td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td><code>Double</code></td>
  <td>The p-value.</td>
  <td><code>4.1e-05</code></td>
</tr>
<tr>
  <td><code>method</code></td>
  <td><code>String</code></td>
  <td>Description of the test performed.</td>
  <td><code>"McNemar's Chi-squared test with continuity correction"</code></td>
</tr>
</tbody>
</table>

=head2 mean

 mean(1,2,3);

or

 my @arr = 1..8;
 mean(@arr, 4, 5)

or

 mean([1,1], [2,2]) # 1.5

mean will die if any undefined values are provided

=head2 median

works like mean, taking array references and arrays:

 median( $test_data[$i][0] )

median will die if any undefined values are provided

=head2 melt

Reshape a wide frame to long form, like C<pandas.DataFrame.melt>. One or more
identifier columns (C<id_vars>) are repeated down the output; every other
selected column (C<value_vars>) is unpivoted into a C<variable>/C<value> pair.

 melt($df,
     id_vars      => 'A' | [ 'A', 'B' ],   # kept, repeated (default: none)
     value_vars   => 'C' | [ 'C', 'D' ],   # unpivoted (default: all non-id cols)
     var_name     => 'variable',           # name of the column-name column
     value_name   => 'value',              # name of the value column
     'output.type' => 'aoh',               # aoa|aoh|hoa|hoh (default: input family)
 );

Column identifiers are names for AoH/HoA/HoH frames and 0-based integer
positions for AoA. C<value_vars> defaults to every column not in C<id_vars>, in
C<colnames()> order.

Output row order is B<column-major>: all rows for C<value_vars[0]>, then all
rows for C<value_vars[1]>, and so on, preserving input row order within each
block. HoH output has no natural row axis, so labels are reset to a
C<0 .. N-1> range index.

Returns a NEW frame; the input is never modified.

=head3 Example

 my $df = [ { A => 'a', B => 1, C => 2 },
            { A => 'b', B => 3, C => 4 } ];
 melt($df, id_vars => 'A', value_vars => [ 'B', 'C' ]);
 # [ { A => 'a', variable => 'B', value => 1 },
 #   { A => 'b', variable => 'B', value => 3 },
 #   { A => 'a', variable => 'C', value => 2 },
 #   { A => 'b', variable => 'C', value => 4 } ]

NA cells (undef, or a missing hash key) melt through to C<< value =E<gt> undef >>.

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; an
unknown C<output.type>; a C<value_vars>/C<id_vars> column that does not exist;
C<var_name> equal to C<value_name>; or C<var_name>/C<value_name> colliding with an
C<id_vars> column name.

=head2 merge

A full relational join of two data frames, in the spirit of R's C<merge> and pandas' C<DataFrame.merge>. Where L<C<ljoin>|/"ljoin"> only does an in-place left join of a hash-of-hashes keyed by row name, C<merge> supports every common join type, single- or multi-column keys, keys with different names on each side, column-collision suffixes, and any mix of input/output shapes.

 my $joined = merge($left, $right, how => 'inner', on => 'id');

C<$left> and C<$right> may each be an B<AoH> (array of row hash references), a B<HoA> (hash of column array references), or a B<HoH> (hash of row hash references; the outer key is treated as a row and is B<not> used as a join key). Both frames are read non-destructively.

=head3 Join types (C<how>)

=over

=item * C<inner> (default) — only rows whose keys match in both frames.

=item * C<left> — every C<$left> row, plus matching C<$right> columns (unmatched C<$right> columns become C<undef>).

=item * C<right> — every C<$right> row; the mirror image of C<left>.

=item * C<outer> (alias C<full>) — the union: all rows from both frames.

=item * C<cross> — the Cartesian product of the two frames; takes no keys.

=back

=head3 Choosing the keys

=over

=item * C<< on =E<gt> 'col' >> or C<< on =E<gt> ['c1', 'c2'] >> — join on one or more columns present under the same name in both frames. C<by> is an accepted synonym (R spelling).

=item * C<< 'left.on' =E<gt> .., 'right.on' =E<gt> .. >> — keys with different names on each side (each a name or an array reference of equal length). C<by.x>/C<by.y> and C<left_on>/C<right_on> are accepted synonyms. The result carries a single key column under the B<left> name.

=item * If neither is given, C<merge> performs a B<natural join> on the sorted intersection of the two frames' column names (it dies if that intersection is empty).

=back

Keys are matched on the B<stringified> cell value. A row whose key cell is C<undef> (or absent) never matches — the pandas C<NaN> rule — so such a row is dropped by an inner/right join and appears only as a left- or right-only row in a left/outer/right join.

=head3 Colliding columns (C<suffixes>)

A non-key column that appears in B<both> frames would collide, so each copy is renamed by appending a suffix: C<.x> to the left copy and C<.y> to the right by default (R's convention). Override with C<< suffixes =E<gt> ['_left', '_right'] >>.

=head3 Output shape

By default the result matches the shape of C<$left> (a HoH left frame yields an AoH, since a joined frame has no single row-name key). Force it with C<< 'output.type' =E<gt> 'aoh' >> or C<< 'output.type' =E<gt> 'hoa' >>.

=head3 Example

 my $emp  = [ { id => 1, name => 'Alice', dept => 10 },
              { id => 2, name => 'Bob',   dept => 20 },
              { id => 3, name => 'Carol', dept => 30 } ];
 my $dept = [ { dept => 10, dname => 'Sales' },
              { dept => 20, dname => 'Engineering' } ];

 my $left = merge($emp, $dept, how => 'left', on => 'dept');
 #  [ { id => 1, name => 'Alice', dept => 10, dname => 'Sales' },
 #    { id => 2, name => 'Bob',   dept => 20, dname => 'Engineering' },
 #    { id => 3, name => 'Carol', dept => 30, dname => undef } ]

See also L<C<ljoin>|/"ljoin"> (in-place HoH left join), L<C<concat>|/"concat"> / L<C<rbind>|/"rbind"> (stacking frames row-wise), and L<C<group_by>|/"group_by">.

=head2 min

 min(1,2,3);

or

 my @arr = 1..8;
 min(@arr, 4, 5)

min will die if any undefined values are provided

=head2 mode

Takes either an array or an array reference, and returns an array of the most common scalars (numbers or strings)

 @arr = mode([1,3,3,3]); # returns (3)

 @arr = mode('a','a','c','c','z'); # returns ('a', 'c')

=head2 ncol

C<ncol($frame)> returns how many B<columns> a data frame has. Like C<nrow>, it
works on all the Stats::LikeR frame shapes, so you don't have to remember which
one you're holding:

 ncol([ [1,2,3], [4,5,6] ])         # 3   array of arrays  (AoA)
 ncol([ {a=>1,b=>2}, {a=>3,b=>4} ]) # 2   array of hashes  (AoH)
 ncol({ a=>[1,2], b=>[3,4] })       # 2   hash of arrays   (HoA)
 ncol({ r1=>{...}, r2=>{...} })     # 2   hash of hashes   (HoH)

=head3 NB

A B<column> is one field of each record. Where the fields live depends on the
shape:

=over

=item * B<Array of hashes> (AoH) — each row is a hash; the columns are its keys, so
the count is how many keys a row has.

=item * B<Array of arrays> (AoA) — each row is a list; the columns are its slots, so
the count is how long a row is.

=item * B<Hash of arrays> (HoA) — the keys I<are> the columns, so the count is the
number of keys.

=item * B<Hash of hashes> (HoH) — each value is a row hash; the columns are that
hash's keys, so the count is how many keys a row has.

=back

A plain flat list (C<[1,2,3]>) is treated as a single column.

=head3 Edge cases

 ncol([])                    # 0
 ncol({})                    # 0
 ncol({ a=>[], b=>[] })      # 2

Empty frames are 0 columns. Note the last one: a HoA still has its columns even
when they hold no rows — the keys are the columns, rows or not.

=head3 What it refuses to do

C<ncol> would rather stop than hand back a wrong number:

=over

=item * B<Ragged frame> — if the rows disagree on how many columns they have (AoH,
AoA, or HoH), there is no single column count, so it dies instead of guessing.

=item * B<Junk input> — C<undef>, a plain scalar, a SCALAR/CODE/GLOB ref, or a hash
whose values aren't all arrays (HoA) or all hashes (HoH) dies with a message
saying what it got.

=back

Blessed frames are fine — it looks at the underlying array/hash, so your
objects count just like plain refs.

=head2 nrow

C<nrow($frame)> returns how many B<rows> a data frame has. It works on all the
Stats::LikeR frame shapes, so you don't have to remember which one you're
holding:

 nrow([ [1,2,3], [4,5,6] ])       # 2   array of arrays  (AoA)
 nrow([ {a=>1}, {a=>2} ])         # 2   array of hashes  (AoH)
 nrow({ a=>[1,2,3], b=>[4,5,6] }) # 3   hash of arrays   (HoA)
 nrow({ r1=>{...}, r2=>{...} })   # 2   hash of hashes   (HoH)

=head3 NB

A B<row> is one record. Where the records live depends on the shape:

=over

=item * B<Array on the outside> (AoH, AoA, or a plain list) — each top-level
element is a row, so the count is just the array's length.

=item * B<Hash of hashes> (HoH) — each key is a row, so the count is the number of
keys.

=item * B<Hash of arrays> (HoA) — the keys are I<columns>, not rows; the row count is
how long those columns are.

=back

=head3 Edge cases

 nrow([])   # 0
 nrow({})   # 0

Empty frames are 0 rows, whatever the shape.

=head3 What it refuses to do

C<nrow> would rather stop than hand back a wrong number:

=over

=item * B<Ragged HoA> — if the columns have different lengths there is no single row
count, so it croaks instead of guessing.

=item * B<Junk input> — C<undef>, a plain scalar, or a hash whose values aren't all
arrays (HoA) or all hashes (HoH) croaks with a message saying what it got.

=back

Blessed frames are fine — it looks at the underlying array/hash, so your
objects count just like plain refs.

=head2 oneway_test

A one-way test for equality of group means that, unlike C<aov>/ANOVA, B<does not
assume equal variances>. By default it performs B<Welch's one-way test> (the
same default as R's C<oneway.test>), so the residual degrees of freedom are
usually fractional. Pass C<< var_equal =E<gt> 1 >> for the classic equal-variance form.

 use Stats::LikeR qw(oneway_test);

=head3 Input

C<oneway_test> accepts your data in one of three shapes. In every case each
I<group> is a vector of at least two numeric observations.

=for html <table>
<thead>
<tr>
  <th>Shape</th>
  <th>What it means</th>
  <th>Group labels</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>Hash of arrays</b> <code>{ a =&gt; [...], b =&gt; [...] }</code></td>
  <td>Each key is a group (R's <code>stack()</code> view of a named list)</td>
  <td>the hash keys</td>
</tr>
<tr>
  <td><b>Array of arrays</b> <code>[ [...], [...] ]</code></td>
  <td>Each element is a group</td>
  <td><code>"Index 0"</code>, <code>"Index 1"</code>, …</td>
</tr>
<tr>
  <td><b>Hash + <code>formula</code></b> <code>{ resp =&gt; [...], grp =&gt; [...] }, formula =&gt; 'resp ~ grp'</code></td>
  <td>Long-format columns split by a factor column</td>
  <td>the distinct values of the factor</td>
</tr>
</tbody>
</table>

=head3 Options

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>var_equal</code> (alias <code>var.equal</code>)</td>
  <td><code>0</code> (false)</td>
  <td><code>0</code> → Welch's test (unequal variances). <code>1</code> → pooled-variance test.</td>
</tr>
<tr>
  <td><code>formula</code></td>
  <td><i>none</i></td>
  <td><code>'response ~ factor'</code>. Only valid with a <b>hash</b> input; an error with an array of arrays.</td>
</tr>
</tbody>
</table>

=head3 Data validation

Every observation must be B<defined and numeric>; an C<undef> or non-numeric
cell makes the call C<die> with the offending group and position. This matches
the rest of C<Stats::LikeR> (C<mean>, C<sum>, C<cor>, … all die on C<undef>) and
prevents missing values from being silently treated as C<0>. All three input
shapes enforce this, C<formula> included:

 # dies: "formula: response observation 3 (group 'b') is undefined or non-numeric"
 oneway_test({ y => [1, 2, 3, undef, 5, 6], lab => [qw(a a a b b b)] },
     formula => 'y ~ lab');

Note that this differs from R, which drops incomplete cases via C<na.action>
rather than complaining. If you want R's behaviour, filter the missing values
out yourself first (see C<dropna>).

Each group needs at least two observations, and you need at least two groups.

=head3 Output

A hash reference with three top-level keys:

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Value</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>factor name</i> (<code>Group</code>, or the formula's factor, e.g. <code>supp</code>)</td>
  <td>the between-groups row: <code>Df</code>, <code>Sum Sq</code>, <code>Mean Sq</code>, <code>F value</code>, <code>Pr(&gt;F)</code></td>
</tr>
<tr>
  <td><code>Residuals</code></td>
  <td>the within-groups row: <code>Df</code>, <code>Sum Sq</code>, <code>Mean Sq</code> (<code>Df</code> is fractional under Welch)</td>
</tr>
<tr>
  <td><code>group_stats</code></td>
  <td><code>{ mean =&gt; { group =&gt; mean, … }, size =&gt; { group =&gt; n, … } }</code></td>
</tr>
</tbody>
</table>

=head3 Examples

=head4 Hash of arrays (each key is a group)

 my $res = oneway_test({
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,   1,   1,   0,   0,   0  ],
 });

 {
     Group => {
         Df        => 1,
         "Sum Sq"  => 61.6533333333333,
         "Mean Sq" => 61.6533333333333,
         "F value" => 177.504798464491,
         "Pr(>F)"  => 1.31343255150313e-07,
     },
     Residuals => {
         Df        => 9.81767348326473,   # fractional: Welch correction
         "Sum Sq"  => 3.47333333333333,
         "Mean Sq" => 0.353783749200256,
     },
     group_stats => {
         mean => { ctrl => 0.5, yield => 5.03333333333333 },
         size => { ctrl => 6,   yield => 6 },
     },
 }

=head4 Array of arrays (groups named by index)

 my $res = oneway_test([
     [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     [1,   1,   1,   0,   0,   0  ],
 ]);

Identical to the hash form, except C<group_stats> is keyed by position:

 group_stats => {
     mean => { "Index 0" => 5.03333333333333, "Index 1" => 0.5 },
     size => { "Index 0" => 6,                "Index 1" => 6   },
 }

=head4 Long format with a formula

When your data is in columns rather than pre-split groups, name the response
and factor columns with a formula. The factor's I<values> become the groups and
the factor's I<name> becomes the top-level key:

 my $res = oneway_test(
     {
         len  => [4.2, 11.5, 7.3, 16.5, 17.3, 13.6, 23.6, 18.5, 33.9],
         supp => [qw(VC VC VC OJ OJ OJ HI HI HI)],
     },
     formula => 'len ~ supp',
 );
 # $res->{supp}, $res->{Residuals}, $res->{group_stats} ...

=head3 Classic equal-variance form

 my $res = oneway_test(\%groups, var_equal => 1);   # or 'var.equal' => 1

=head3 Accuracy

C<oneway_test> is cross-validated against R's C<stats::oneway.test> (both
branches), R's C<anova(aov())> (the C<Sum Sq> / C<Mean Sq> columns),
C<statsmodels.stats.oneway.anova_oneway(use_var="unequal")> and
C<scipy.stats.f_oneway>. Across 37 data sets — R's C<chickwts>, C<InsectSprays>,
C<PlantGrowth>, C<iris>, C<ToothGrowth>, C<mtcars>, C<warpbreaks>, C<sleep>,
C<airquality>, C<CO2>, C<esoph>, C<OrchardSprays>, C<faithful> and C<quakes>, plus
numerical edge cases — the statistic, both degrees of freedom and the p-value
agree with R to within C<1.3e-12> relative error. On 2000 randomised comparisons
against R — both branches, 2 to 8 groups, group sizes 2 to 40, deliberately
heteroscedastic (per-group standard deviations spanning four orders of
magnitude) and data scales spanning 1e-4 to 1e4 — the statistic and the degrees
of freedom agree to C<1e-12> and the p-value to C<8e-11>, the worst of those being
a p-value of C<2.4e-66>.

Two places where the agreement takes some care:

=over

=item * B<Tail p-values.> C<< Pr(E<gt>F) >> is evaluated in the upper tail directly, using
the beta symmetry C<1 - I_x(a, b) = I_{1-x}(b, a)>, rather than as
C<1 - pf(F, df1, df2)>. The naive form has no resolution below the ulp of
C<1.0>, so it collapses every small p-value to a flat C<0> and loses relative
precision from about C<1e-9> downward. C<faithful> split at C<< waiting E<gt> 70 >>
gives C<1.2099104551915e-76> (Welch) and C<5.50783574504386e-103> (pooled),
matching R's C<pf(F, df1, df2, lower.tail = FALSE)>.

=item * B<Sums of squares.> These are accumulated with a two-pass mean-then-deviation
scheme, which is more accurate than R's QR-based C<aov> on badly scaled data:
for two groups near C<1e8>, C<Residuals>/C<Sum Sq> comes out at exactly C<10>
where C<anova(aov())> reports C<10.0000000521067>.

=back

=head3 Degenerate variances

A group with B<zero variance> gives it an infinite Welch weight
(C<w_i = n_i / 0>), and the test degenerates. C<oneway_test> reproduces what R
does rather than papering over it:

=for html <table>
<thead>
<tr>
  <th>Situation</th>
  <th>Welch (default)</th>
  <th><code>var_equal =&gt; 1</code></th>
</tr>
</thead>
<tbody>
<tr>
  <td>One or more groups constant, others not</td>
  <td><code>F</code>, <code>Residuals</code>/<code>Df</code>, <code>Residuals</code>/<code>Mean Sq</code> and <code>Pr(&gt;F)</code> are all <code>NaN</code>; the two <code>Sum Sq</code> entries stay finite</td>
  <td>ordinary result (<code>Residuals</code>/<code>Sum Sq</code> is unaffected by the constant group)</td>
</tr>
<tr>
  <td>Every group constant, means differ</td>
  <td><code>NaN</code></td>
  <td><code>F</code> is <code>Inf</code>, <code>Pr(&gt;F)</code> is <code>0</code></td>
</tr>
<tr>
  <td>Every observation identical</td>
  <td><code>NaN</code></td>
  <td><code>F</code> and <code>Pr(&gt;F)</code> are <code>NaN</code> (a genuine <code>0/0</code>)</td>
</tr>
</tbody>
</table>

 # one constant group: Welch has nothing to work with, exactly as in R
 my $r = oneway_test({ a => [5, 5, 5, 5], b => [1, 2, 3, 4] });
 # $r->{Group}{'F value'}, $r->{Residuals}{Df}, $r->{Group}{'Pr(>F)'} are all NaN

Test for these with C<$x != $x> (the standard C<NaN> idiom) rather than assuming
a finite number came back.

=head3 Notes

=over

=item * The default (Welch) does B<not> require equal group sizes or equal variances;
the pooled form (C<< var_equal =E<gt> 1 >>) assumes equal variances.

=item * C<formula> is only meaningful for a hash input. Passing it with an array of
arrays is an error.

=item * Group order in the output is not guaranteed for hash inputs (it follows hash
iteration order); read results by name, not position.

=item * Avoid naming a factor C<Residuals> or C<group_stats> in a formula, since those
are reserved top-level keys in the result.

=back

=head2 p_adjust

Corrects a family of p-values for multiple testing, like R's C<p.adjust>. The
methods available are C<holm> (the default), C<hochberg>, C<hommel>,
C<bonferroni>, C<BH>, C<BY>, C<fdr> (a synonym for C<BH>) and C<none>. Method names
are case-insensitive, and the full C<Benjamini-Hochberg> /
C<Benjamini-Yekutieli> spellings are accepted.

 my @q = p_adjust(\@pvalues, $method);          # array in, array out
 my $q = p_adjust($df, $method, columns => ..); # a frame in, a frame out

Given a flat arrayref of p-values it returns the adjusted values as a list, in
the order they were given. Given a data frame — AoA, AoH, HoA or HoH — it
returns a B<new> frame of the same kind, with the same rows, columns and row
labels, holding the adjusted values in the places the raw ones came from. The
input frame is never modified.

Every p-value in the frame is corrected as B<one family>, whichever shape it
arrived in, so the family size is the number of p-value cells and not the
number of rows or columns.

 my $df = [ { gene => 'BRCA1', p_value => 0.010 },
            { gene => 'TP53',  p_value => 0.040 },
            { gene => 'EGFR',  p_value => 0.030 },
            { gene => 'KRAS',  p_value => 0.200 } ];
 my $q = p_adjust($df, 'BH', columns => 'p_value');
 # [ { gene => 'BRCA1', p_value => 0.04      },
 #   { gene => 'TP53',  p_value => 0.0533333 },
 #   { gene => 'EGFR',  p_value => 0.0533333 },
 #   { gene => 'KRAS',  p_value => 0.20      } ]

=head3 columns

C<columns> (also spelled C<column>, C<cols> or C<col>) names the columns that hold
p-values; everything else is copied through untouched. It takes one name or an
arrayref of names, which are column names for AoH, HoA and HoH and 0-based
positions for AoA.

 p_adjust($aoh, 'BH', columns => 'p_value');
 p_adjust($hoh, 'BH', columns => [ 'p_raw', 'p_trend' ]);
 p_adjust($aoa, 'BH', columns => 1);              # the second column
 p_adjust($hoa, columns => 'p_value');            # method defaults to holm

Note the shape each name refers to: in a HoA a column I<is> an outer key, while
in a HoH the outer keys are row labels and the names are the inner keys.

Without C<columns>, every cell in the frame is taken to be a p-value. That is
what you want for a frame that is nothing but p-values, and an error for one
with a label column in it — a cell that is neither a number nor C<undef> dies
with a message pointing at C<columns>. A name that matches no column in the
frame also dies, rather than quietly correcting nothing.

C<columns> applies only to frames; passing it with a flat list of p-values is an
error.

=head3 Method may be positional or named

The method still reads positionally, as it always has, and may also be given as
a C<< method =E<gt> ... >> pair. These three are the same call:

 p_adjust($df, 'BH', columns => 'p_value');
 p_adjust($df, method => 'BH', columns => 'p_value');
 p_adjust($df, 'BH');                    # if every column holds p-values

=head3 Ordering and other details

=over

=item * An C<undef> cell counts toward the family as a p-value of 1, which is how the
flat form has always treated it, and comes back adjusted rather than as
C<undef>.

=item * Within a frame the family is enumerated in a fixed order — rows in order and
then columns by name for an AoA, AoH or HoH; columns by name and then rows
for a HoA; row labels in sorted order for a HoH — so tied p-values break the
same way on every run instead of following hash iteration order.

=item * An empty arrayref returns an empty list; an empty frame returns an empty
frame of the same kind.

=back

=head2 pivot_table

Aggregate a long frame into a wide one, like C<pandas.pivot_table>. Rows are
grouped by an C<index> key, spread across columns generated from a C<columns>
key, and reduced with C<aggfunc>.

 pivot_table($df,
     index       => 'city' | [ 'city', 'q' ],  # row key (default: none -> one row)
     columns     => 'year' | [ 'a', 'b' ],      # REQUIRED, generates output columns
     values      => 'temp' | [ 't', 'h' ],      # aggregated (default: all remaining cols)
     aggfunc     => 'mean' | [ 'sum', ... ] | sub { ... },
     skipna      => 1,        # 0 -> any NA in a bucket poisons a numeric reducer
     fill_value  => 0,        # substitute for NA result cells (default: leave undef)
     sort        => 1,        # 0 -> keep first-seen row/column order
     sep         => '.',      # joins pieces of generated column names
     'output.type' => 'aoh',  # aoa|aoh|hoa|hoh (default: input family)
 );

C<columns> is required. C<values> defaults to every column that is neither
C<index> nor C<columns>. Column identifiers are names for AoH/HoA/HoH and
0-based positions for AoA.

C<aggfunc> accepts the same vocabulary as C<agg()> — C<mean median sum sd var min
max count n nunique first last mode> — or a coderef (called as
C<< $code-E<gt>(\@cells) >> with every cell in the bucket, including undef), or an
arrayref of any of these. With C<< skipna =E<gt> 1 >> (default) undef cells are dropped
before a numeric reduction; C<< skipna =E<gt> 0 >> makes a numeric reducer return NA if
its bucket contains any NA.

Rows whose C<columns>-tuple contains NA are skipped (an unnameable column).
With no C<index>, all rows collapse to a single C<all> row.

=head3 Generated column names

A single value column reduced by a single function names each output column
after the C<columns>-tuple value alone (flat, pandas-like). Multiple functions
and/or multiple value columns prefix the function and/or value, joined by
C<sep>, in B<aggfunc-major> order (function, then value, then columns-tuple).
A collision between two generated names dies — pass a different C<sep> or
rename inputs.

=head3 Example

 my $df = [ { city => 'NY', year => 2020, temp => 10 },
            { city => 'NY', year => 2020, temp => 20 },
            { city => 'NY', year => 2021, temp => 30 },
            { city => 'LA', year => 2020, temp => 40 } ];
 pivot_table($df, index => 'city', columns => 'year', values => 'temp');
 # [ { city => 'LA', 2020 => 40,  2021 => undef },
 #   { city => 'NY', 2020 => 15,  2021 => 30    } ]

 pivot_table($df, index => 'city', columns => 'year', values => 'temp',
     aggfunc => [ 'count', 'sum' ]);
 # names: count.2020 count.2021 sum.2020 sum.2021

Rows and columns are sorted by default (numeric if every key is numeric, else
string); C<< sort =E<gt> 0 >> keeps first-seen order. HoH output labels come from the
C<index> values (C<'all'> with no index) and are uniquified with a numeric
suffix if two joined labels collide. Returns a NEW frame; the input is never
modified.

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; a
missing C<columns>; an C<index>/C<columns>/C<values> column that does not exist; an
unknown C<aggfunc> string; an empty C<aggfunc> list; an unknown C<output.type>; or
a generated duplicate column name.

=head2 power_t_test

 $test_data = power_t_test(
     n    => 30,    delta     => 0.5, 
     sd    => 1.0, sig_level => 0.05
 );

It also allows configuring the test type (C<< type =E<gt> 'one.sample' >>, C<'two.sample'>, C<'paired'>) and alternative hypothesis (C<< alternative =E<gt> 'one.sided' >>). You can also pass C<< strict =E<gt> 1 >> to strictly evaluate both tails of the distribution.

Exactly one of C<n>, C<delta>, C<sd>, C<power> and C<sig_level> must be C<undef>: that
is the quantity solved for. C<sd> and C<sig_level> have defaults, so solving for
either means passing it explicitly as C<undef>; C<power> has no default, so
omitting it entirely is how you ask for the power.

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>n</code></td>
  <td>Float</td>
  <td><code>undef</code></td>
  <td>Number of observations (per group for two-sample, pairs for paired). Must be at least 2.</td>
</tr>
<tr>
  <td><code>delta</code></td>
  <td>Float</td>
  <td><code>undef</code></td>
  <td>True difference in means. Used as <code>abs(delta)</code> when the test is two-sided.</td>
</tr>
<tr>
  <td><code>sd</code></td>
  <td>Float</td>
  <td>1.0</td>
  <td>Standard deviation.</td>
</tr>
<tr>
  <td><code>sig_level</code></td>
  <td>Float</td>
  <td>0.05</td>
  <td>Significance level (Type I error probability), in <code>[0, 1]</code>. Also accepts <code>sig.level</code>.</td>
</tr>
<tr>
  <td><code>power</code></td>
  <td>Float</td>
  <td><code>undef</code></td>
  <td>Power of test (1 minus Type II error probability), in <code>[0, 1]</code>.</td>
</tr>
<tr>
  <td><code>type</code></td>
  <td>String</td>
  <td><code>"two.sample"</code></td>
  <td>Type of t-test: <code>"two.sample"</code>, <code>"one.sample"</code>, or <code>"paired"</code>.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>String</td>
  <td><code>"two.sided"</code></td>
  <td>One- or two-sided test: <code>"two.sided"</code>, <code>"one.sided"</code>, <code>"greater"</code>, or <code>"less"</code>.</td>
</tr>
<tr>
  <td><code>strict</code></td>
  <td>Boolean</td>
  <td>0 (False)</td>
  <td>Use strict interpretation of two-sided power calculations.</td>
</tr>
<tr>
  <td><code>tol</code></td>
  <td>Float</td>
  <td><code>1e-12</code></td>
  <td>Relative tolerance on the root when solving for <code>n</code>, <code>delta</code>, <code>sd</code> or <code>sig_level</code>.</td>
</tr>
</tbody>
</table>

The result is a hashref carrying C<n>, C<delta>, C<sd>, C<sig.level>, C<power>,
C<alternative>, C<method>, and -- for C<two.sample> and C<paired> -- C<note>, the same
fields R's C<power.t.test> returns.

=head3 Accuracy

The power itself is computed from a noncentral I<t> CDF and agrees with R's
C<power.t.test> and with C<scipy.stats.nct.sf> to about C<1e-13> relative.

The four inverse problems are solved by regula falsi with the Illinois
correction, driven to the relative C<tol> above rather than to the width of the
bracket. R solves them with C<uniroot> at a default tolerance of
C<.Machine$double.eps^0.25> (C<1.22e-4>) measured on the bracket width, which
leaves R's own C<n>, C<delta>, C<sd> and C<sig.level> good to four or five
significant figures; C<power_t_test> matches high-precision
C<scipy.optimize.brentq> roots to about C<1e-13> instead. Expect agreement with R
to R's precision, not to this one.

Over 1200 random cases spanning all five solved-for parameters, C<n> from 2 to
5000, C<delta> from 0.01 to 5, C<sd> from 0.05 to 20 and C<sig_level> from 0.001 to
0.2, 1078 of the 1080 that all three implementations answer land within C<1e-8>
relative of the high-precision scipy value; R lands 379 of them there, and is
past C<1e-3> on 56. Neither of the two remaining is a case where R does better:
one solves a C<sig_level> of C<5.9e-10> to C<1.3e-5> relative (C<7.7e-15> absolute)
where R returns its bracket endpoint and is 83% out, and the other is C<3.4e-8>
where R is out by a factor of 300.

The one place R is still ahead is B<df past about 1e7> -- 500,000 or more
observations per group -- where it holds C<1e-14> against this C<1e-8>. What is
left there is not the noncentral I<t> CDF, which is exact to C<3e-16> in that range,
but the critical value: C<qt_tail> inverts C<incbeta> at C<x = 1 - 5e-8> with
C<a = 4e7>, right at the edge of where its continued fraction converges. That
routine is shared with C<t_test>, C<cor_test>, C<var_test> and the rest, so it is
left alone here rather than retuned for this one caller. The drift is C<1.3e-11>
at C<n = 1e6>, C<1.0e-8> at C<4e7> and C<1.5e-7> at C<1e8>.

=head3 Errors

Dies on: an odd trailing argument list; an unknown argument; anything other than
exactly one of C<n>, C<delta>, C<sd>, C<power> and C<sig_level> left C<undef>; a
C<sig_level> or C<power> outside C<[0, 1]>; an C<n> below 2 (there is no variance to
estimate below two observations); a negative C<sd>; an unrecognised C<type> or
C<alternative>; solving for C<sd> when C<delta> is 0, or for C<delta> when C<sd> is
not positive; and a target that the requested parameter cannot reach at all --
for instance a C<power> below C<sig_level / tside>, which no C<sd> attains, or one
that would need a C<sig_level> above 1. R answers those last cases with a bracket
endpoint (a C<sig.level> of 1.07, an C<n> of 1.4) or with C<uniroot>'s own "no sign
change found"; C<power_t_test> names the range it searched and the target it could
not reach.

=head2 pnorm

The normal cumulative distribution function: the probability that a normal random variable is C<< E<lt>= x >>. Ports R's C<pnorm>.
That is, take the integral from negative infinity to the point that you want.

 my $p = pnorm(1.96);            # 0.9750021  (standard normal, P(X <= 1.96))

C<x> may be a single number or an array reference; an array reference returns an array reference of the same length.

 my $ps = pnorm([-1.96, 0, 1.96]);   # [0.0249979, 0.5, 0.9750021]

=head3 Arguments

=for html <table>
<thead>
<tr>
  <th>Position</th>
  <th>Name</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>x</code></td>
  <td>—</td>
  <td>A number, or an array reference of numbers.</td>
</tr>
<tr>
  <td>2 +</td>
  <td><code>mean</code></td>
  <td><code>0</code></td>
  <td>Mean of the distribution.</td>
</tr>
<tr>
  <td></td>
  <td><code>sd</code></td>
  <td><code>1</code></td>
  <td>Standard deviation.</td>
</tr>
<tr>
  <td></td>
  <td><code>lower</code></td>
  <td><code>1</code> (true)</td>
  <td><code>1</code> = lower tail <code>P(X &lt;= x)</code>; <code>0</code> = upper tail <code>P(X &gt; x)</code>. <code>'lower.tail'</code> is an accepted alias.</td>
</tr>
<tr>
  <td></td>
  <td><code>log</code></td>
  <td><code>0</code> (false)</td>
  <td>If true, return the log of the probability. <code>'log.p'</code> is an accepted alias.</td>
</tr>
</tbody>
</table>

=head3 Examples

 pnorm(1.96);                    # lower tail:  0.9750021
 pnorm(1.96, lower => 0);        # upper tail:  0.0249979
 pnorm(1.96, log => 1);          # log lower tail: -0.02531565
 pnorm(2, mean => 1, sd => 0.5); # standardizes to z = 2: 0.9772499

Use C<< log =E<gt> 1 >> for tails that would otherwise underflow to C<0>:

 pnorm(-40);           # 0  (underflows)
 pnorm(-40, log => 1); # -804.6084

=head3 Notes

=over

=item * C<< sd =E<gt> 0 >> gives a step at the mean: C<< x E<lt> mean >> returns C<0>, otherwise C<1>.

=item * C<< sd E<lt> 0 >> returns C<NaN> and warns.

=item * A C<NaN> input (or an C<undef> element of an array reference) yields C<NaN>.

=item * C<+Inf> returns C<1>, C<-Inf> returns C<0>.

=back

=head2 prcomp

Principal Component Analysis

=head3 Options

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>center</code></td>
  <td>Boolean</td>
  <td><code>1</code> (True)</td>
  <td>If true, the variables are shifted to be zero-centered before the analysis takes place.</td>
</tr>
<tr>
  <td><code>scale</code></td>
  <td>Boolean</td>
  <td><code>0</code> (False)</td>
  <td>If true, the variables are scaled to have unit variance before the analysis takes place. <i>Note: If a column has zero variance, the function will <code>croak</code> to prevent division by zero.</i></td>
</tr>
<tr>
  <td><code>retx</code></td>
  <td>Boolean</td>
  <td><code>1</code> (True)</td>
  <td>If true, the rotated data (the original data multiplied by the rotation matrix) is returned under the key <code>x</code>.</td>
</tr>
<tr>
  <td><code>tol</code></td>
  <td>Number</td>
  <td><code>undef</code></td>
  <td>A value indicating the magnitude below which components should be omitted. Components are omitted if their standard deviation is less than or equal to <code>tol</code> times the standard deviation of the first component.</td>
</tr>
<tr>
  <td><code>rank</code></td>
  <td>Integer</td>
  <td><code>undef</code></td>
  <td>Optionally specify a strict limit on the number of principal components to return. The function will return <code>min(rank, rows, columns)</code> components.</td>
</tr>
</tbody>
</table>

=head3 Results

=head4 Returned Data Structure

The C<prcomp> function returns a HashRef containing the following keys representing the results of the Principal Component Analysis:

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Type</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>sdev</code></td>
  <td>ArrayRef[Number]</td>
  <td>The standard deviations of the principal components. Mathematically, these are the square roots of the eigenvalues of the covariance matrix.</td>
</tr>
<tr>
  <td><code>rotation</code></td>
  <td>ArrayRef[ArrayRef]</td>
  <td>A 2D array representing the matrix of variable loadings (the eigenvectors). Each inner array represents a row, and the columns correspond to the principal components.</td>
</tr>
<tr>
  <td><code>x</code></td>
  <td>ArrayRef[ArrayRef]</td>
  <td>A 2D array containing the rotated data (often referred to as PCA scores). This is the original data projected onto the principal components. <i>Note: Only present if the <code>retx</code> option is true.</i></td>
</tr>
<tr>
  <td><code>center</code></td>
  <td>ArrayRef[Number] or <code>0</code></td>
  <td>The centering values used (typically the column means). Returns false (<code>0</code>) if centering was disabled.</td>
</tr>
<tr>
  <td><code>scale</code></td>
  <td>ArrayRef[Number] or <code>0</code></td>
  <td>The scaling values used (typically the column standard deviations). Returns false (<code>0</code>) if scaling was disabled.</td>
</tr>
<tr>
  <td><code>varnames</code></td>
  <td>ArrayRef[String]</td>
  <td>The sorted names of the original variables. <i>Note: Only present if the input data carried column names, i.e. an Array of Hashes (AoH), a Hash of Arrays (HoA), or a Hash of Hashes (HoH).</i></td>
</tr>
</tbody>
</table>

C<prcomp> accepts an Array of Arrays (AoA), an Array of Hashes (AoH), a Hash of
Arrays (HoA), or a Hash of Hashes (HoH). For the named-column shapes the columns
are ordered alphabetically by name, and that order is reported in C<varnames>.
Rows that hold a non-numeric, undefined, non-finite, or absent value in any
column are dropped listwise.

=head3 Using array of arrays

 my $aoa = [ 
     [2, 4], 
     [4, 2], 
     [6, 6] 
 ];

 my $pca = prcomp($aoa);

which returns

 {
     center     [
         [0] 4,
         [1] 4
     ],
     rotation   [
         [0] [
                 [0] 0.707106781186547,
                 [1] 0.707106781186548
             ],
         [1] [
                 [0] 0.707106781186548,
                 [1] -0.707106781186547
             ]
     ],
     scale      0,
     sdev       [
         [0] 2.44948974278318,
         [1] 1.4142135623731
     ],
     x          [
         [0] [
                 [0] -1.41421356237309,
                 [1] -1.4142135623731
             ],
         [1] [
                 [0] -1.4142135623731,
                 [1] 1.41421356237309
             ],
         [2] [
                 [0] 2.82842712474619,
                 [1] 2.22044604925031e-16
             ]
     ]
 }

=head3 Array of Hashes

Each element of the array is one observation, keyed by column name. The columns
are taken from the first row hash and sorted alphabetically, so the following is
the same matrix as the AoA above and returns the same C<sdev>, C<rotation>, and
C<x> — plus C<< varnames =E<gt> ['A', 'B'] >>:

 my $aoh = [
     { B => 4, A => 2 },
     { B => 2, A => 4 },
     { B => 6, A => 6 }
 ];
 my $pca = prcomp($aoh);

Unlike a Hash of Hashes, an AoH preserves row order, so the rows of C<x> line up
with the rows of the input.

=head3 Hash of Arrays

 my $hoa = { B => [4, 2, 6], A => [2, 4, 6] };
 my $pca = prcomp($hoa);

=head2 predict

R-style prediction for the fitted objects returned by C<lm> and C<glm>. It rebuilds
each row's linear predictor from the model's coefficients and (for C<glm>) applies
the inverse link.

=head3 Usage

 my $fit  = lm(formula => 'mpg ~ wt + hp', data => $train);
 my $yhat = predict($fit, $newdata);              # predictions on new rows
 my $resp = predict($logit_fit, $newdata);        # glm: response scale (default)
 my $eta  = predict($logit_fit, $newdata, type => 'link');   # linear predictor
 my $fitted = predict($fit);                      # no newdata -> stored fitted.values

=over

=item * B<< C<$model> >> — a fitted C<lm>/C<glm> hashref. C<predict> reads its C<coefficients>
(and, for C<glm>, its C<family>).

=item * B<< C<$newdata> >> — a HoA, AoH, or HoH of new observations. Omit it (or pass
C<undef>) to get the model's own C<fitted.values> back.

=item * B<< C<type> >> — C<'response'> (default) returns predictions on the response scale
(the inverse link applied — logistic for binomial); C<'link'> returns the linear
predictor. For C<lm> and gaussian C<glm> the link is the identity, so the two are
the same.

=back

=head3 What it returns

A hashref keyed by row name → prediction, exactly like C<lm>/C<glm> key
C<fitted.values>: a C<row.names> column (or HoH key) if present, otherwise 1-based
integer labels.

 my $m = lm(formula => 'y ~ x + I(x^2)', data => $train);
 my $p = predict($m, { x => [1, 2, 3] });
 # { 1 => ..., 2 => ..., 3 => ... }

=head3 How it works

For each new row the prediction is

 eta = Intercept + Σ  coef[term] · term(row)

where each C<term> is evaluated with the same engine used to fit the model, so
interactions (C<x:z> → product) and transforms (C<I(x^2)> → power) behave
identically to fitting. Coefficients that the fit marked aliased (stored as NaN)
contribute nothing, just as they were excluded from the fitted values. For C<glm>
with C<< family =E<gt> 'binomial' >> and C<< type =E<gt> 'response' >>, C<eta> is passed through the
logistic function C<1 / (1 + exp(-eta))>; otherwise C<eta> is returned as is.

A consequence worth noting: predicting on the I<training> data reproduces the
model's C<fitted.values> for any model built from continuous terms, interactions,
or C<I()> transforms.

=head3 Good to know

=over

=item * A prediction comes back as B<NaN> when a required term can't be evaluated in
the new data (a missing column, or a value that makes the term undefined).

=item * B<Factors are a limitation.> The fitted object stores only the dummy term
I<names> (e.g. C<genderM>), not the underlying factor levels, so C<predict>
cannot re-expand a raw categorical column in new data. Either pass pre-expanded
0/1 dummy columns whose names match the coefficient names, or extend C<lm>/C<glm>
to retain the factor levels.

=item * B<It dies> on: a model that isn't a hashref or has no C<coefficients>; an
invalid C<type>; or C<newdata> that isn't a HoA/HoH hashref or AoH arrayref.

=back

=head2 prop_test

Test of proportions, a faithful port of R's C<stats::prop.test>. It compares an
observed count of successes against a target probability (one sample), tests two
proportions for equality (with a confidence interval for their difference), or
tests C<< k E<gt> 2 >> proportions for equality via a Pearson chi-square. A Yates
continuity correction is applied for one or two groups (toggle with C<correct>).
Validated numerically against R.

 # one sample vs a target probability (default 0.5)
 my $r = prop_test(83, 100);              # 83 successes in 100 trials
 printf "p-hat=%.2f  95%% CI %.3f–%.3f  p=%.4g\n",
     $r->{estimate}[0], $r->{'conf.int'}[0], $r->{'conf.int'}[1], $r->{p_value};

 # two groups: difference in proportions + CI
 my $two = prop_test([83, 90], [100, 100]);

 # k > 2 groups: chi-square test of equality (no CI)
 my $k = prop_test([83, 90, 75], [100, 100, 100]);

 # one-sample against a specified probability, one-sided, no correction
 my $g = prop_test(83, 100, p => 0.7, alternative => 'greater', correct => 0);

Pass successes and trials either as matching array references (one entry per
group) or as two scalars for a single sample.

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>successes</i></td>
  <td><code>ArrayRef</code> or <code>Number</code></td>
  <td><i>None (Required)</i></td>
  <td>Count of successes per group (positional arg 1).</td>
  <td><code>[83, 90]</code>, <code>83</code></td>
</tr>
<tr>
  <td><i>trials</i></td>
  <td><code>ArrayRef</code> or <code>Number</code></td>
  <td><i>None (Required)</i></td>
  <td>Count of trials per group (positional arg 2); same length as <i>successes</i>.</td>
  <td><code>[100, 100]</code>, <code>100</code></td>
</tr>
<tr>
  <td><code>p</code></td>
  <td><code>Number</code> or <code>ArrayRef</code></td>
  <td><code>0.5</code> (one sample) / pooled</td>
  <td>Null probability. A single value or one per group; when omitted with ≥2 groups, equality of proportions is tested against the pooled rate.</td>
  <td><code>0.7</code>, <code>[0.5, 0.6]</code></td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td><code>String</code></td>
  <td><code>'two.sided'</code></td>
  <td><code>'two.sided'</code>, <code>'less'</code>, or <code>'greater'</code>. Forced two-sided for <code>k &gt; 2</code> groups or two groups tested against a given <code>p</code>.</td>
  <td><code>'greater'</code></td>
</tr>
<tr>
  <td><code>conf.level</code></td>
  <td><code>Number</code></td>
  <td><code>0.95</code></td>
  <td>Confidence level for the interval (one or two groups).</td>
  <td><code>0.99</code></td>
</tr>
<tr>
  <td><code>correct</code></td>
  <td><code>Boolean</code></td>
  <td><code>1</code></td>
  <td>Apply the Yates continuity correction (<code>k ≤ 2</code> only).</td>
  <td><code>0</code></td>
</tr>
</tbody>
</table>

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>statistic</code></td>
  <td><code>Double</code></td>
  <td>Pearson chi-square statistic (X-squared).</td>
  <td><code>1.5414</code></td>
</tr>
<tr>
  <td><code>parameter</code></td>
  <td><code>Integer</code></td>
  <td>Degrees of freedom.</td>
  <td><code>1</code></td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td><code>Double</code></td>
  <td>The p-value.</td>
  <td><code>0.2144</code></td>
</tr>
<tr>
  <td><code>estimate</code></td>
  <td><code>ArrayRef</code></td>
  <td>Sample proportion(s), one per group.</td>
  <td><code>[0.83, 0.90]</code></td>
</tr>
<tr>
  <td><code>conf.int</code></td>
  <td><code>ArrayRef</code></td>
  <td>For one group, a Wilson score interval for the proportion; for two groups, a Wald interval for the difference <code>p1 - p2</code>. Absent for <code>k &gt; 2</code>.</td>
  <td><code>[-0.174, 0.034]</code></td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td><code>String</code></td>
  <td>The alternative hypothesis used.</td>
  <td><code>'two.sided'</code></td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td><code>Double</code></td>
  <td>The confidence level used.</td>
  <td><code>0.95</code></td>
</tr>
<tr>
  <td><code>method</code></td>
  <td><code>String</code></td>
  <td>Human-readable description of the test performed.</td>
  <td><code>'2-sample test for equality of proportions with continuity correction'</code></td>
</tr>
</tbody>
</table>

=head2 qcut

Equal-frequency binning of a numeric column, which is the analog of pandas
C<qcut>. Equal-I<width> binning slices the value range into intervals of the same
size, which dumps most of a skewed distribution into one bin; C<qcut> instead
chooses cutpoints so each bin holds roughly the same I<number> of observations.
This is the binning you usually want for ranked-list work: deciles, quartiles,
top-5% tranches.

Cutpoints are computed by linear interpolation between order statistics — the
numpy/pandas default, and the same rule L<C<quantile>|/"quantile"> uses (R's
Type 7) — so the edges match C<pandas.qcut> exactly. Bins are right-closed,
C<(a, b]>, with the lowest bin closed on both ends, C<[a, b]>, so the minimum
value is always included.

=head3 Signature

 qcut($data, $q, %options)

=over

=item * C<$data> — an array reference of numbers, in any order. C<qcut> sorts an
internal copy, so your array is left untouched and codes come back in the
order the values were given. Every defined value must be numeric: a
non-numeric string such as C<'N/A'> is a fatal C<isn't numeric> error rather
than a silent zero, so clean or C<undef> such cells first (see
L<C<dropna>|/"dropna">, L<C<fillna>|/"fillna">). At least two I<distinct> values
are needed to form a bin.

=item * C<$q> — either a positive integer (the number of equal-frequency bins) or an
array reference of probabilities in C<[0, 1]> giving explicit cut
boundaries, e.g. C<[0, 0.5, 0.95, 1]>. An explicit vector is sorted for you,
and any probability outside C<[0, 1]> is clamped into it rather than being an
error.

=back

C<undef> entries are treated as missing (NA): they are skipped when computing
cutpoints and, when codes are requested, come back as C<undef> in their original
positions.

Only the options listed below are read; a misspelled one is ignored rather than
refused, so C<< code =E<gt> 1 >> (no C<s>) quietly hands back edges instead of codes.

For a usage reminder at the prompt, call C<h('qcut')>; it prints this section to
C<STDOUT> and returns. Every function is documented that way — see
L</"Getting help">.

=head3 What it returns

=for html <table>
<thead>
<tr>
  <th>Options given</th>
  <th>Returns</th>
</tr>
</thead>
<tbody>
<tr>
  <td>none</td>
  <td>The edge vector, as a <b>flat list</b> of <code>$q + 1</code> numbers</td>
</tr>
<tr>
  <td><code>codes =&gt; 1</code></td>
  <td>One array reference: the bin codes, parallel to <code>$data</code></td>
</tr>
<tr>
  <td><code>codes =&gt; 1, edges =&gt; 1</code></td>
  <td>Two references, <code>($codes, $edges)</code></td>
</tr>
</tbody>
</table>

By default C<qcut> returns the edge vector — the cheap, common query — so call it
in list context:

 my @edges = qcut($data, 4);          # ($e0, $e1, $e2, $e3, $e4)

In B<scalar> context that flat list collapses to its element count, not to a
reference: C<my $e = qcut($data, 4)> sets C<$e> to C<5>. Assign to an array.

The per-element bin assignment (the expensive part) is opt-in. Ask for it with
C<< codes =E<gt> 1 >> and you get an array reference parallel to C<$data>:

 my $codes = qcut($data, 4, codes => 1);

Asking for codes turns the edge vector I<off>, so
C<< my ($codes, $edges) = qcut($data, 4, codes =E<gt> 1) >> leaves C<$edges> undefined.
Ask for both explicitly and they are computed in a single pass:

 my ($codes, $edges) = qcut($data, 4, codes => 1, edges => 1);

=head3 Options

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>edges =&gt; 1</code></td>
  <td>Include the edge vector. On by default, but turned off automatically when codes are requested, so pass it explicitly to get both.</td>
</tr>
<tr>
  <td><code>edges =&gt; 0</code></td>
  <td>Suppress the edge vector. With no <code>codes</code>/<code>labels</code> there would be nothing left to return, which is a fatal error.</td>
</tr>
<tr>
  <td><code>codes =&gt; 1</code></td>
  <td>Include the 0-based integer bin codes, one per element of <code>$data</code>.</td>
</tr>
<tr>
  <td><code>labels =&gt; [...]</code></td>
  <td>Map the bin codes onto your own labels (implies <code>codes =&gt; 1</code>). The list length must equal the number of bins actually produced.</td>
</tr>
<tr>
  <td><code>labels =&gt; 'interval'</code></td>
  <td>Label each element with its interval string, e.g. <code>(3.25, 5.5]</code> (also implies codes).</td>
</tr>
<tr>
  <td><code>duplicates =&gt; 'raise'</code></td>
  <td>Die when tied data makes adjacent cutpoints equal. The default, and what pandas does.</td>
</tr>
<tr>
  <td><code>duplicates =&gt; 'drop'</code></td>
  <td>Merge equal cutpoints into fewer bins instead of dying.</td>
</tr>
</tbody>
</table>

=head3 How many bins, and how full

The bin count is always C<@$edges - 1>, and codes run from C<0> to
C<@$edges - 2>. That equals C<$q> (or C<@$probs - 1>) I<unless>
C<< duplicates =E<gt> 'drop' >> merged tied cutpoints, in which case it is fewer — which
is why a C<labels> list has to match the bins you actually got, not the ones you
asked for.

Bin I<sizes> are equal only when the data permits: the count has to divide
evenly and no repeated value may straddle a cutpoint. Ties are placed by the
right-closed rule, which is why C<[1 .. 10]> into quartiles gives 3, 2, 2, 3
rather than 2.5 each — the same split pandas makes. Count the codes to see what
you got:

 my $codes = qcut($data, 10, codes => 1);
 my $sizes = value_counts($codes);        # { 0 => n0, 1 => n1, ... }

If a probability vector omits C<0> or C<1>, the end bins still stretch over the
whole range: a value below the first cutpoint lands in bin C<0>, one above the
last lands in the last bin. pandas returns NA for those, so include C<0> and C<1>
unless the stretching is what you want.

=head3 Examples

Quartile edges (the default). The cutpoints match pandas exactly:

 my @edges = qcut([1 .. 10], 4);
 # @edges = (1, 3.25, 5.5, 7.75, 10)

Bin codes. They are 0-based, and unsorted input is fine — codes come back in
input order:

 my $codes = qcut([1 .. 10], 4, codes => 1);
 # $codes = [0, 0, 0, 1, 1, 2, 2, 3, 3, 3]
 my $c2 = qcut([5, 1, 9, 3, 7], 4, codes => 1);
 # $c2 = [1, 0, 3, 0, 2]

Edges and codes together, computed in one pass:

 my ($codes, $edges) = qcut([1 .. 10], 4, codes => 1, edges => 1);

Equal frequency on clean data — 100 values into 4 bins of 25:

 my $codes = qcut([1 .. 100], 4, codes => 1);
 # 25 elements in each of bins 0, 1, 2, 3

An explicit probability vector, for an asymmetric top-5% tranche:

 my @edges = qcut([1 .. 100], [0, 0.5, 0.95, 1]);
 my $codes = qcut([1 .. 100], [0, 0.5, 0.95, 1], codes => 1);
 # bin 0: lower half (50), bin 1: next 45%, bin 2: top 5%

Named labels instead of integer codes (implies codes):

 my $labels = qcut([1 .. 10], 4, labels => [qw/Q1 Q2 Q3 Q4/]);
 # ['Q1','Q1','Q1','Q2','Q2','Q3','Q3','Q4','Q4','Q4']

Interval-string labels:

 my $iv = qcut([1 .. 10], 4, labels => 'interval');
 # $iv->[0]  eq '[1, 3.25]'
 # $iv->[-1] eq '(7.75, 10]'

Missing values are ignored for cutpoints, and (when codes are requested) pass
straight through:

 my $codes = qcut([1, 2, undef, 4, 5, 6, 7, 8, 9, 10], 4, codes => 1);
 # $codes->[2] is undef; the rest are binned as usual

Tied data and C<duplicates>. Heavy ties can make adjacent cutpoints equal; the
default raises, C<'drop'> merges the empty quantile bands:

 my @tied = ((0) x 8, 1, 2, 3, 4);
 qcut(\@tied, 4);                          # dies: bin edges are not unique
 my @edges = qcut(\@tied, 4, duplicates => 'drop');
 # @edges = (0, 1.25, 4) -- 2 bins, not 4, so labels => [qw/a b/] here

Binning a data-frame column, which is the usual reason to want codes.
L<C<vals>|/"vals"> hands C<qcut> the column and L<C<assign>|/"assign"> puts the result
back as a new one:

 my $df = { id => [1 .. 10], ldl => [90, 120, 150, 200, 80, 110, 175, 160, 95, 130] };
 my $q  = qcut(vals($df, 'ldl'), 4, labels => [qw/Q1 Q2 Q3 Q4/]);
 assign($df, ldl_quartile => $q);
 # $df->{ldl_quartile} = [qw/Q1 Q2 Q3 Q4 Q1 Q2 Q4 Q4 Q1 Q3/]

Get the documentation:

 h('qcut');   # prints this section to STDOUT and returns

=head3 Errors

C<qcut> dies when C<$data> is not an array reference, when C<$q> is neither a
positive integer nor an array reference, and when the options ask for nothing
(C<< edges =E<gt> 0 >> with no codes or labels). It dies with C<no non-missing values>
when every element is C<undef>, and C<need at least one data value> when C<$data>
is empty.

Cutpoints are the other source of failures. C<bin edges are not unique> means
ties collapsed adjacent cutpoints under the default C<< duplicates =E<gt> 'raise' >>:
either pass C<< duplicates =E<gt> 'drop' >> or ask for fewer bins. Even with C<'drop'>,
data holding a single distinct value cannot be binned at all and dies with
C<too few distinct values to form bins>. Finally, a C<labels> arrayref whose
length differs from the bin count dies naming both numbers
(C<got 2 bins but 4 labels>).

=head3 Differences from pandas

=over

=item * B<Interval printing.> pandas nudges its lowest edge 0.1% below the minimum
so every bin can be half-open, e.g. C<(0.999, 3.25]>. C<qcut> keeps the exact
minimum and closes the lowest bin on both ends, C<[1, 3.25]>. Membership is
the same; only the printed interval differs.

=item * B<Out-of-range values.> A partial probability vector makes the end bins
stretch (above), where pandas yields NA.

=item * B<Out-of-range probabilities> are clamped into C<[0, 1]> instead of raising.

=item * B<Return type.> There is no Categorical: you get edges, plain integer
codes, your own labels, or interval strings.

=back

=head3 See also

L<C<quantile>|/"quantile"> computes the same cutpoints without assigning anything
to bins. L<C<chunk>|/"chunk"> splits by I<position> instead of value, which works on
non-numeric data. L<C<value_counts>|/"value_counts"> checks how full the bins came
out, L<C<rank>|/"rank"> is the alternative when you want the whole ordering rather
than bins, and L<C<assign>|/"assign"> / L<C<vals>|/"vals"> move a binned column into
and out of a data frame.

=head2 quantile

Calculates sample quantiles using R's continuous Type 7 interpolation. 

 my $quantile = quantile('x' => [1..99], probs => [0.05, 0.1, 0.25]);

If the C<probs> parameter is omitted, it behaves identically to R by defaulting to the 0, 25, 50, 75, and 100 percentiles (C<c(0, .25, .5, .75, 1)>). The returned hash keys match R's standardized naming convention (e.g., C<"25%">, C<"33.3%">).

=head2 rank

Rank values like R's C<rank()>. Takes flat scalars and/or array refs (like C<min>), with optional trailing C<ties.method> / C<na.last> options. Returns the list of ranks in input order.

 my @r = rank(3, 1, 4, 1, 5);                           # 3, 1.5, 4, 1.5, 5
 my @r = rank([3, 1, 4, 1, 5], 'ties.method' => 'min'); # 3, 1, 4, 1, 5

Ranks are 1-based; C<average> may return half-ranks. C<undef> and NaN are treated as NA.

=head3 ties.method

How tied values share ranks (default C<average>):

=for html <table>
<thead>
<tr>
  <th>value</th>
  <th>behavior</th>
  <th><code>rank(3, 1, 4, 1, 5)</code></th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>average</code></td>
  <td>mean of the tied ranks</td>
  <td>3, 1.5, 4, 1.5, 5</td>
</tr>
<tr>
  <td><code>min</code></td>
  <td>lowest rank in the group</td>
  <td>3, 1, 4, 1, 5</td>
</tr>
<tr>
  <td><code>max</code></td>
  <td>highest rank in the group</td>
  <td>3, 2, 4, 2, 5</td>
</tr>
<tr>
  <td><code>first</code></td>
  <td>ties keep input order</td>
  <td>3, 1, 4, 2, 5</td>
</tr>
<tr>
  <td><code>last</code></td>
  <td>ties keep reverse input order</td>
  <td>3, 2, 4, 1, 5</td>
</tr>
<tr>
  <td><code>random</code></td>
  <td>ties broken randomly (srand-aware)</td>
  <td>varies</td>
</tr>
</tbody>
</table>

=head3 na.last

How C<undef>/NaN elements are placed (default C<true>):

=for html <table>
<thead>
<tr>
  <th>value</th>
  <th>behavior</th>
  <th><code>rank(5, undef, 1, ...)</code></th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>true</code></td>
  <td>NAs get the highest ranks</td>
  <td>2, 3, 1</td>
</tr>
<tr>
  <td><code>false</code></td>
  <td>NAs get the lowest ranks</td>
  <td>3, 1, 2</td>
</tr>
<tr>
  <td><code>keep</code></td>
  <td>NAs stay undef, in place</td>
  <td>2, undef, 1</td>
</tr>
<tr>
  <td><code>na</code> (or undef)</td>
  <td>NAs dropped (shorter list)</td>
  <td>2, 1</td>
</tr>
</tbody>
</table>

=head2 Ronly

 my @only_last = Ronly(\@a, \@b, \@c);
 my $count     = Ronly(\@a, \@b, \@c);

The mirror of C<Lonly>: takes one or more array references and returns the values
that appear in the B<last> reference and in B<no other> reference; with a
single reference it returns that list's distinct values. Duplicates collapse,
the result keeps the last list's first-appearance order, and scalar context
returns the count. Values are compared by string form (see C<get_union>). A
non-array-ref argument or an C<undef> element is fatal. With exactly two
references this is the right-only set difference, so C<Ronly(\@a, \@b)> equals
C<Lonly(\@b, \@a)>; more generally C<Ronly(@refs)> equals C<Lonly(reverse @refs)>.

 my @a = (1, 2, 3, 4, 5);
 my @b = (3, 4, 5, 6, 7);
 my @c = (5, 6, 7, 8);
 my @r = Ronly(\@a, \@b, \@c);           # (8)  -- 5,6,7 also appear in @a or @b

=head2 rbinom

Create a binomial distribution of numbers

 my $binom = rbinom( n => $n, prob => 0.5, size => 9);

=head2 read_table

minimal example:

 my $test_data = read_table('t/HepatitisCdata.csv');

=head3 options

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>comment</code></td>
  <td>Comment character, by default <code>#</code>; lines beginning with it are skipped</td>
  <td><code>comment =&gt; '%'</code></td>
</tr>
<tr>
  <td><code>output.type</code></td>
  <td>data type for output: array of hash, hash of array, or hash of hash</td>
  <td><code>'output.type' =&gt; 'aoh'</code></td>
</tr>
<tr>
  <td><code>filter</code></td>
  <td>Only take in rows matching a filter</td>
  <td><code>filter =&gt; { Sex =&gt; sub {$_ eq 'f'} }</code></td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td>include row names in retrieved data; off by default</td>
  <td></td>
</tr>
<tr>
  <td><code>sep</code></td>
  <td>field separator character; synonym with <code>delim</code></td>
  <td><code>sep =&gt; "\t"</code></td>
</tr>
<tr>
  <td><code>delim</code></td>
  <td>field separator character; synonym with <code>sep</code></td>
  <td><code>delim =&gt; "\t"</code></td>
</tr>
<tr>
  <td><code>sheet</code></td>
  <td>which worksheet to read from an <code>.xlsx</code> file: a 1-based index or a sheet name (default: first sheet). Ignored for text files</td>
  <td><code>sheet =&gt; 'Sheet2'</code></td>
</tr>
</tbody>
</table>

output types can be AOH (aoh), HOA (hoa), HOH (hoh)

 read_table($filename, 'output.type' => 'aoh');
 read_table($filename, 'output.type' => 'hoa');

and, like Text::CSV_XS, filters can be applied in order to save RAM on big files:

 $test_data = read_table(
     't/HepatitisCdata.csv',
     filter => {
         Sex => sub {$_ eq 'f'} # where "Sex" is the column name, and "$_" is the value for that column
     },
     'output.type' => 'aoh'
 );

the default delimiter is C<,>
Suffixes C<.csv> and C<.tsv> are automatically detected from file names, but if specified, are overridden by C<delim> and/or C<sep>. C<sep> is given priority.

=head3 commented-out headers

A header that is itself commented out is detected and used automatically, so

 # PDB    score
 1a2b    10
 3c4d    20

reads as though the header were C<PDB, score> (the comment marker and any
following whitespace are stripped from the first column). A commented line is
only taken as the header when its field count matches the data, so ordinary
leading comments are never mistaken for one. You may name such a column in a
C<filter> either as it appears in the file or by its clean name:

 read_table('ranks.tabular.tsv', filter => { '# PDB' => sub { $_ == 2 } });

=head3 Excel (.xlsx) files

A file whose name ends in C<.xlsx> is read directly, with B<no extra
dependencies> — the parser uses the core C<IO::Uncompress::Unzip> module to pull
the parts out of the (zipped) workbook and reads the XML itself. All
C<output.type>, C<filter>, and C<row.names> options work exactly as they do for
text files:

 my $data = read_table('samples.xlsx');
 my $data = read_table('samples.xlsx', sheet => 'Results');   # by name
 my $data = read_table('samples.xlsx', sheet => 2);           # 1-based index

B<Multiple worksheets.> If the workbook has more than one worksheet and no
C<sheet> is given, C<read_table> returns a B<hashref keyed by worksheet name>,
each value being that sheet parsed just as a single table would be (honouring
C<output.type>, C<filter>, etc.):

 my $book = read_table('report.xlsx');   # { Sheet1 => [...], Sheet2 => [...] }
 my $rows = $book->{Results};

A workbook with a single worksheet, or a call that names a C<sheet> explicitly,
returns that one table directly (not wrapped in a hash).

Limitations: dates and times are returned as their raw Excel serial numbers
(cell number formats are not applied); and shared-string rich-text runs are
concatenated into a single value. The C<sep>, C<delim>, and C<comment> options do
not apply to C<.xlsx> files. Tested in C<t/read_table.xlsx.t>.

=head2 rename_cols

 rename_cols($df, old => new, ...)
 rename_cols($df, { old => new, ... })

Rename one or more columns of a data frame. Works on the labelled shapes
(C<AoH>, C<HoA>, C<HoH>); an C<AoA> has no column names and dies (convert to
C<AoH>/C<HoA> first). Identifiers are the inner-row keys for C<AoH>/C<HoH> and the
top-level keys for C<HoA>.

Behaviour depends on calling context:

=over

=item * B<Non-void> (scalar or list context) returns a fresh shallow B<view> and
never mutates the source. Row shapes (C<AoH>/C<HoH>) share the cell scalars by
reference via XS; a C<HoA> aliases the whole column arrayrefs under their new
keys.

=item * B<Void> context renames the source B<in place> and returns nothing: the
edit lands in each C<AoH>/C<HoH> row hash, or on the top-level keys of a C<HoA>.

=back

<!-- -->

 # HoH: rename an inner-row key in every row, in place
 rename_cols(\%d, resolution => 'Resolution (Å)');

 # capture a fresh view instead; %d is left untouched by rename_cols itself
 %d = %{ rename_cols(\%d, resolution => 'Resolution (Å)') };

 # pairs or a single hashref; both forms are equivalent
 my $view = rename_cols($aoh, a => 'x', c => 'z');
 my $view = rename_cols($hoa, { b => 'B' });

Both the in-place and view paths are swap-safe (gather-then-set), so an
exchange renames correctly:

 rename_cols($sw, a => 'b', b => 'a');   # {a=>1,b=>2} -> {b=>1,a=>2}

Ragged C<AoH>/C<HoH> frames stay ragged: an old key that is absent from a given
row is simply skipped for that row. For a C<HoA>, the renamed key points at the
I<same> column arrayref (no copy), so a later C<push>/C<splice> on it is shared
with the source.

Dies (all validation runs B<before> any mutation, so a dying void call leaves
the source unchanged):

=over

=item * an old column that is not present anywhere in the frame,

=item * a new name that is C<undef>,

=item * a rename whose target collides with a kept column or another renamed target,

=item * an odd-length C<< old =E<gt> new >> argument list,

=item * an C<AoA> (no column names to rename).

=back

Note: C<\%d = rename_cols(...)> is B<not> valid Perl — a reference constructor
is not an lvalue before 5.22 refaliasing, which is out under the module's 5.10
back-compatibility. Use the void form or the C<%d = %{ ... }> capture idiom
above.

=head2 _rename_inplace

 _rename_inplace($df, $shape, \%map)

Private helper (not exported) that backs C<rename_cols>'s void-context path;
C<rename_cols> performs all argument checking first, so this never has to croak.
For a C<HoA> it renames the top-level column keys; for C<AoH>/C<HoH> it renames
the keys inside each row hash. It gathers the moved values before re-storing
them, which makes it swap-safe, and it only touches keys that actually C<exists>
in a given row, which preserves ragged frames. Mutates C<$df> and returns
nothing.

=head2 rnorm

Make a normal distribution of numbers, with pre-set mean C<mean>, standard deviation C<sd>, and number C<n>.

 my ($rmean, $sd, $n) = (10, 2, 9999);
 my $normals = rnorm( n => $n, mean => $rmean, sd => $sd);

=head2 roc

Build a ROC curve from predicted scores and 0/1 labels: the AUC (c-statistic)
with a DeLong confidence interval, the sensitivity/specificity at every
threshold, and the best cut-off by Youden's J. The standard way to judge how
well a score separates cases from non-cases.

 use Stats::LikeR 'roc';

 my $r = roc(\@scores, \@labels);
 print $r->{auc};                 # 0.848
 print "@{ $r->{auc_ci} }";       # 0.649 1.000
 my $cut = $r->{youden};          # best operating point
 print "$cut->{threshold}: sens=$cut->{sensitivity} spec=$cut->{specificity}";

Options: C<positive> (positive-class label, default C<1>), C<direction> (C<< 'E<gt>' >>
default, or C<< 'E<lt>' >>), C<conf_level> (default C<0.95>). Result keys: C<auc>, C<auc_se>,
C<auc_ci>, C<n_pos>, C<n_neg>, C<youden>, and C<curve> (one point per threshold). For
just the number, use L<C<auc>|/"auc">.

=head2 rownames

Return the row names of a data frame, as a list (like R's C<rownames>).
Only C<HoH> carries genuine row labels; the other shapes are positional and
so yield 0-based indices, again matching C<view>:

=over

=item * C<AoA> / C<AoH> — C<0 .. $#$df> (one index per top-level element)

=item * C<HoA> — C<0 .. longest_column-1>

=item * C<HoH> — the string-sorted outer keys (the row labels)

=back

In scalar context it returns the count, so C<scalar rownames($df)> equals
C<nrow($df)> for a rectangular frame.

 my $hoh = { r2 => { x => 1 }, r1 => { x => 2 }, r3 => { x => 3 } };
 my @rows = rownames($hoh);        # ('r1', 'r2', 'r3')  -- sorted labels

 my $aoh = [ { a => 1 }, { a => 2 } ];
 my @rows = rownames($aoh);        # (0, 1)

 my $hoa = { a => [1,2,3], b => [4,5,6] };
 my @rows = rownames($hoa);        # (0, 1, 2)

 my $n = rownames($hoh);           # 3  (scalar context == nrow)

=head3 notes

Shape is detected with the same C<_df_shape> classifier C<agg> uses, so both
functions accept exactly the frames C<agg>/C<view> accept. A ragged frame is
tolerated for enumeration: C<colnames> spans the widest row and C<rownames>
the longest column. An empty frame returns an empty list. Because the
classifier is C<ref>-based (not C<reftype>), pass an unblessed frame — blessed
frames are the one case C<ncol>/C<nrow> accept that this family does not.

=head2 runif

Make an approximately uniform distribution into an array

=head3 named arguments

 my $unif = runif( n => $n, min => 0, max => 1);

where C<n> is the number of items, the values are between C<min> and C<max>

=head3 positional args

this is to match R's behavior:

 runif( 9 )

will make 9 numbers in [0,1]

 runif(9, 0, 99)

will match C<n>, C<min>, and C<max> respectively

=head2 sample

take a sample of hash or array slices.

 my $h = sample(\%h, 4); # take 4 hash keys and their values into $h

or, alternatively, with arrays:

 my $arr = sample(\@arr, 3); # take 3 indices of an array

=head2 scale

 my @scaled_results = scale(1..5);

You can also pass an options hash to disable centering or scaling:

 my @scaled_results = scale(1..5, { center => false, scale => 1 });

It fully supports matrix operations. By passing an array of arrays, C<scale> processes the data column by column independently:

 my $scaled_mat = scale([[1, 2], [3, 4], [5, 6]]);

=head2 sd

 my $stdev = sd(2,4,4,4,5,5,7,9);

Correct answer is 2.1380899352994

C<sd> can accept both array references as well as arrays:

 my $stdev = sd([2,4,4,4,5,5,7,9]);

sd will croak/die if any undefined values are provided.

=head2 select_cols

Return a new data frame containing only the named columns, in the order
requested — the Stats::LikeR form of pandas C<df[['a','b']]>. Works on all
four frame shapes. For C<AoA> the identifiers are 0-based integer positions;
for C<AoH>, C<HoA>, and C<HoH> they are column names. Columns may be given as a
list or as a single arrayref.

 my $aoh = [ { a => 1, b => 2, c => 3 },
             { a => 4, b => 5, c => 6 } ];
 my $sub = select_cols($aoh, 'a', 'c');
 # [ { a => 1, c => 3 }, { a => 4, c => 6 } ]

 my $hoa = { a => [1,4], b => [2,5], c => [3,6] };
 my $sub = select_cols($hoa, ['c', 'a']);   # order preserved
 # { c => [3,6], a => [1,4] }

 my $aoa = [ [1,2,3], [4,5,6] ];
 my $sub = select_cols($aoa, 0, 2);
 # [ [1,3], [4,6] ]

A column that appears in only some C<AoH>/C<HoH> rows is filled with C<undef> in
the rows that lack it, so the selection comes back rectangular:

 select_cols([ {a=>1,b=>2}, {a=>3,c=>9} ], 'a', 'c');
 # [ { a => 1, c => undef }, { a => 3, c => 9 } ]

=head2 seq

Works as closely as I can to R's seq, which is very similar to Perl's C<for> loops.  Returns an array, not an array reference.

=head3 Standard integer sequence

 say 'seq(1, 5):';
 my @seq = seq(1, 5);
 say join(', ', @seq), "\n";

 say 'seq(1, 2, 0.25):';
 @seq = seq(1, 2, 0.25);

=head3 Fractional steps

 say 'seq(1, 2, 0.25):';
 @seq = seq(1, 2, 0.25);
 say join(", ", @seq), "\n";
 for (my $idx = 2; $idx >= 1; $idx -= 0.25) { # count down to pop
     is_approx(pop @seq, $idx, "seq item $idx with fractional step");
 }

=head3 Negative steps

 say 'seq(10, 5, -1):';
 @seq = seq(10, 5, -1);
 say join(", ", @seq), "\n";
 for (my $idx = 5; $idx <= 10; $idx++) { # count down to pop
     is_approx(pop @seq, $idx, "seq item $idx with negative step");
 }

=head2 shapiro_test

tests to see if an array reference is normally distributed, returns a p-value and a statistic

 my $shapiro = shapiro_test(
     [1..5]
 );

and returns the hash reference:

 {
 p.value     0.589650577093106,
 p_value     0.589650577093106,
 statistic   0.960870680168535,
 W           0.960870680168535
 }

=head2 skew

Sample skewness — the direction and degree of a distribution's asymmetry.
Positive means a long right tail (the usual shape of lab values, costs and
lengths of stay), negative a long left tail, and about zero a symmetric sample.
Validated numerically against R.

 skew(2, 4, 4, 4, 5, 5, 7, 9);        # 0.8184875533568

Arguments work as they do for L</"sd"> and L</"var">: plain numbers, array
references, or any mixture of the two, all flattened into one sample.

 my @x = (2, 4, 4, 4, 5, 5, 7, 9);
 skew(@x);                  # a list
 skew(\@x);                 # an array reference
 skew([2, 4, 4], 4, [5, 5, 7, 9]);   # mixed; same sample
 skew(x => \@x);            # named, if you prefer it

=head3 C<type>

There are three conventions in circulation for turning the moment ratio into a
sample statistic, and they disagree noticeably on small samples. C<type> picks
one; the default is C<2>.

=for html <table>
<thead>
<tr>
  <th><code>type</code></th>
  <th>Statistic</th>
  <th>Also known as</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>g1</code></td>
  <td>the plain moment ratio; R's <code>moments::skewness</code></td>
</tr>
<tr>
  <td>2</td>
  <td><code>G1</code></td>
  <td><b>the default</b>; SAS, SPSS, Stata, Excel's <code>SKEW()</code>, <code>scipy.stats.skew(bias =&gt; FALSE)</code></td>
</tr>
<tr>
  <td>3</td>
  <td><code>b1</code></td>
  <td><code>e1071::skewness</code>'s own default</td>
</tr>
</tbody>
</table>

where, writing C<m2> and C<m3> for the second and third central moments (each
divided by C<n>):

 g1 = m3 / m2**1.5                     # type 1
 G1 = g1 * sqrt(n * (n - 1)) / (n - 2) # type 2, the default
 b1 = g1 * ((n - 1) / n)**1.5          # type 3

 my @x = (1, 2, 4);
 skew(\@x, type => 1);   # 0.3818017742   plain moment ratio
 skew(\@x);              # 0.9352195296   G1, the default
 skew(\@x, type => 3);   # 0.2078265621   b1

C<< type =E<gt> 2 >> is the estimator that is unbiased for a normal sample, which is why
it is the default and why it is what every general-purpose statistics package
reports. It divides by C<n - 2>, so it needs at least three values; the other two
need at least two.

Both statistics are computed in one pass over the sample, so a whole column can
be summarized without materializing it twice:

 my $df = read_table('labs.tsv');
 printf "%-24s skew %7.3f  kurtosis %7.3f\n", $_,
     skew($df->{$_}), kurtosis($df->{$_}) for qw(alt ast bilirubin);

=head3 Errors

C<skew> croaks, naming the offending position, on an undefined value:

 skew(1, undef, 3);
 # skew: undefined value at argument index 1

 skew([1, 2, undef]);
 # skew: undefined value at array ref index 2 (argument 0)

and on a sample too small for the chosen C<type>, on a C<type> outside C<1 .. 3>, or
on a constant sample, which has no shape to report:

 skew([7, 7, 7, 7]);
 # skew: zero variance (all 4 values are equal), so skewness is undefined

=head3 See also

L</"kurtosis"> for the fourth moment, L</"sd"> and L</"var"> for the
second, L</"shapiro_test"> to test normality rather than describe the
departure from it.

=head2 smd

Standardized mean difference between two continuous groups, standardizing by the
simple (unweighted) average of the group variances — the convention used for
covariate-balance diagnostics in "Table 1" (R's C<tableone> / C<stddiff>). Returns
the signed value. Validated numerically against R.

 my $balance = smd(\@exposed_age, \@unexposed_age);   # |smd| < 0.1 is well balanced

Unlike L</"cohen_d"> (which pools by sample size), C<smd> weights the two
group variances equally, so the two diverge when the groups differ in size.

=head2 sum

returns sum, but using both arrays and array references.

 my $test_data = [1..8];
 sum($test_data)

which I prefer, compared to List::Util's required casting into an array:

 sum(@{ $test_data });

which passing a reference is shorter and much easier to read.  Stats::LikeR, however, will work for B<both>

C<sum> will cause the script to die if any undefined values are provided

=head2 summary

Analogous to R's C<summary>: a five-number-plus-mean description (C<# values>, C<Min.>, C<1st Qu.>, C<Median>, C<Mean>, C<3rd Qu.>, C<Max.>) of the data as entered (it does not summarise fitted-model objects). It produces one statistics row per numeric I<variable> and renders the table exactly like L<C<view>|/"view"> — the same colourised, wide-character-aware, terminal-fitting output — through the same internal renderer, so all of C<view>'s display options apply.

Which variable becomes a row depends on the shape (every shape C<view> accepts is accepted here):

=for html <table>
<thead>
<tr>
  <th>input</th>
  <th>one row per…</th>
  <th>label column</th>
</tr>
</thead>
<tbody>
<tr>
  <td>flat vector — <code>summary(@x)</code>, <code>summary(\@x)</code>, or a bare list</td>
  <td>the whole vector</td>
  <td><i>(none)</i></td>
</tr>
<tr>
  <td>array of arrays (AoA)</td>
  <td>inner array</td>
  <td><code>Index</code></td>
</tr>
<tr>
  <td>hash of arrays (HoA)</td>
  <td>key</td>
  <td><code>Key</code></td>
</tr>
<tr>
  <td>array of hashes (AoH) / hash of hashes (HoH)</td>
  <td>column, gathered across rows</td>
  <td><code>Column</code></td>
</tr>
</tbody>
</table>

The AoH/HoH case is the per-column summary R gives for a data frame — so the array-of-hashes that C<read_table> returns by default summarises column-by-column:

 summary(read_table('data.csv'));       # one row per column
 summary(\%hoh, nrows => 20);            # cap the rows shown
 summary(\@x, color => 1);               # force colour (default: auto on a TTY)
 my $txt = summary(\%hoa, return_only => 1);   # capture instead of printing

Non-numeric and undefined cells are ignored: they never count toward C<# values>, and a variable with no numeric values shows C<0> and C<na>. For example, C<summary> of an AoH:

 # summary: 2 rows x 7 cols    (showing 2)
 Column  # values  Min.  1st Qu.  Median  Mean  3rd Qu.  Max.
 x              3     1      1.5       2     2      2.5     3
 y              3    10       15      20    20       25    30

C<summary> prints the table (unless C<return_only> is set) and returns it as a string. C<nrows> (synonyms C<nrow>, C<n>, C<rows>) caps the rows shown, and the C<view> display options C<na>, C<color>, C<colors>, C<max_width>, C<ellipsis>, C<gap>, C<width>, C<to>, and C<return_only> all apply.

=head2 survfit

The Kaplan–Meier survival curve: the probability of surviving past each time,
estimated from right-censored data. The starting point of most survival
analysis; matches R's C<survival::survfit>.

Give times and an event flag (1 = event, 0 = censored); add C<group> for one
curve per group:

 use Stats::LikeR 'survfit';

 my $f = survfit(\@time, \@status, group => \@arm);
 my $s = $f->{strata}{treatment};    # keyed by group label ('' if no group)
 print $s->{median};                 # median survival time
 print "@{ $s->{surv} }";            # S(t) at each time

Option C<conf_level> (default C<0.95>). Each stratum has arrays C<time>, C<n_risk>,
C<n_event>, C<n_censor>, C<surv>, C<std_err>, C<lower>, C<upper>, plus C<median>, C<n>,
and C<events>. Compare curves with L<C<logrank_test>|/"logrank_test">; model
covariate effects with L<C<coxph>|/"coxph">.

=head2 table_one

The stratified descriptive "Table 1" that opens most clinical papers: for each
variable, a per-group summary — C<mean (sd)> for numbers, C<n (percent)> for
categories — plus a group-comparison p-value.

 use Stats::LikeR 'table_one';

 my $t1 = table_one(\@cohort, by => 'arm');
 print view($t1);       # returns a plain AoH you can view() or write_table()

Types are detected automatically (all-numeric = continuous, else categorical)
and the test follows: t-test / ANOVA for continuous (Wilcoxon / Kruskal with
C<< nonparametric =E<gt> 1 >>), chi-squared for categorical. Options: C<by>, C<vars>
(which columns), C<types> (override a column's type), C<nonparametric>, C<digits>,
C<pct_digits>. Each returned row has C<variable>, C<level>, one column per group,
C<Overall>, and — on a variable's row — C<p_value> and C<test>.

=head2 t_test

There are 1-sample and 2-sample t-tests, from one or two arrays:

 my $t_test = t_test( $array1, mu => 0.2334 );

or 2-sample:

 $t_test = t_test(
     $array1,    $array2,
     paired => 1
 );

returns a hash reference, which looks like:

 conf_int     => [
     -0.06672889, 0.25672889
 ],
 df        => 5,
 estimate  => 0.095,
 p_value   => 0.19143688433660,
 statistic => 1.50996688705414

the two groups compared can be specified, though not necessarily, as C<x> and C<y>, just like in R:

 $t_test = t_test(
     'x' => $array1, 'y' => $array2,
     paired => 1
 );

=head3 Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>x</code></td>
  <td>Array Reference</td>
  <td>Required</td>
  <td>The first vector of data. Must have at least 2 non-missing elements (1 is enough for the <code>y</code> of a <code>var_equal</code> test).</td>
</tr>
<tr>
  <td><code>y</code></td>
  <td>Array Reference</td>
  <td><code>undef</code></td>
  <td>The second vector of data. Required for two-sample or paired tests. An explicit <code>undef</code> means "absent", as R's <code>y = NULL</code> does; anything else that is not an array reference is a fatal error rather than a silently ignored argument.</td>
</tr>
<tr>
  <td><code>mu</code></td>
  <td>Float</td>
  <td>0.0</td>
  <td>The true value of the mean (or difference in means) for the null hypothesis. Shifts <code>statistic</code> and <code>p_value</code>; <code>conf_int</code> is centred on the estimate and does not move.</td>
</tr>
<tr>
  <td><code>paired</code></td>
  <td>Boolean</td>
  <td><code>FALSE</code></td>
  <td>If true, performs a paired t-test. <code>x</code> and <code>y</code> must be the same length.</td>
</tr>
<tr>
  <td><code>var_equal</code></td>
  <td>Boolean</td>
  <td><code>FALSE</code></td>
  <td>If true, assumes equal variances (standard two-sample). If false, performs Welch's t-test with unequal variances.</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td>Float</td>
  <td>0.95</td>
  <td>Confidence level for the returned confidence interval. Must be strictly between 0 and 1 (R also accepts the degenerate 0 and 1). See [Extreme <code>conf_level</code>](#extreme-conf_level) for the precision limit past about <code>0.9999</code>.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>String</td>
  <td><code>"two.sided"</code></td>
  <td>Direction of the alternative hypothesis: <code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>. <code>"two-sided"</code> and <code>"two_sided"</code> are accepted as <code>scipy</code>'s spelling of the same thing. Anything else is a fatal error — an unrecognised value must not quietly become a two-sided test.</td>
</tr>
</tbody>
</table>

=head3 Extreme C<conf_level>

C<conf_int> is exact to the last few digits at ordinary confidence levels, and the
t quantile behind it neither saturates nor loses accuracy as the data's scale
grows. Past about C<< conf_level =E<gt> 0.9999 >>, though, the interval's accuracy is
capped by the I<argument>, not by the quantile — and no implementation can do
better, R's included.

The reason is that C<conf_level> arrives as a float, so the tail has to be
recovered as C<(1 - conf_level) / 2>, and that subtraction discards most of the
tail it is trying to express. The nearest double to C<0.99999999> puts the tail at
C<5.0000000251e-9> rather than C<5e-9> — a relative error of C<5.0e-9> — and for
C<0.9999999999> the error is C<8.3e-8>. Since C<qt(p, 1) ~ 1/(pi * p)>, the
quantile, and therefore each interval bound, inherits that relative error
exactly.

One consequence worth knowing: the answer depends on your perl's C<nvtype>. A
C<long double> build (C<perl -V:nvtype>) represents C<0.99999999> to 19 digits and
so recovers the tail correctly, while an ordinary C<double> build cannot:

 # t_test([1, 3], conf_level => 0.99999999), upper bound minus the mean
 #   nvtype double        63661976.9168721   (5.0e-9 low)
 #   nvtype long double   63661977.2367910   (5.2e-13 low)
 #   qt(5e-9, 1, lower.tail = FALSE) in R  = 63661977.2367581

If you need a tail that small exactly, compute it yourself and work from the
quantile rather than passing a C<conf_level> that cannot hold it.

=head3 Missing values

C<undef> and C<NaN> are dropped, as R's C<t.test> drops C<NA>; infinities are kept,
as R keeps them. A one-sample or unpaired two-sample test filters each vector on
its own, so the two may lose different numbers of observations and C<df> reflects
what survived. A paired test filters on complete cases: if either side of a pair
is missing the pair goes whole, keeping the differences aligned.

=head3 Errors

Dies if:
- C<x> is missing or is not an array reference, or C<y> is defined but is not one
- C<alternative> is not one of the values above
- C<conf_level> is not strictly between 0 and 1
- C<paired> is set without a C<y>, or with an C<x> and C<y> of different lengths
- fewer than 2 observations survive: 2 in C<x> for a one-sample test, 2 complete
  pairs when C<paired>, and for two samples R's own thresholds — a Welch test
  needs 2 on each side, while C<var_equal> accepts a side of 1 (it contributes no
  sum of squares to the pooled variance) so long as the two together reach 3
- the data are essentially constant, meaning the standard error has fallen below
  C<10 * DBL_EPSILON> times the magnitude of the estimate. The comparison is
  relative, so a sample whose spread a double cannot resolve at its own scale is
  rejected instead of being reported as an enormous C<statistic>. R returns C<NaN>
  rather than raising for the exactly-zero case; this raises for both.

=head3 Return Hash

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>statistic</code></td>
  <td>The computed t-statistic.</td>
</tr>
<tr>
  <td><code>df</code></td>
  <td>Degrees of freedom for the test.</td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td>The calculated p-value based on the test directionality.</td>
</tr>
<tr>
  <td><code>conf_int</code></td>
  <td>An Array Reference containing two elements: <code>[lower_bound, upper_bound]</code>.</td>
</tr>
<tr>
  <td><code>estimate</code></td>
  <td>The estimated mean of <code>x</code> (one-sample) OR the mean of the differences (paired).</td>
</tr>
<tr>
  <td><code>estimate_x</code></td>
  <td>The estimated mean of the <code>x</code> vector (only returned in two-sample tests).</td>
</tr>
<tr>
  <td><code>estimate_y</code></td>
  <td>The estimated mean of the <code>y</code> vector (only returned in two-sample tests).</td>
</tr>
</tbody>
</table>

=head2 transpose

Transposes a two-dimensional data structure, swapping rows and columns. Accepts either an array of arrays or a hash of hashes.
Returns a new reference of the same type; the input is never modified.

=head3 Array of array input

Takes a reference to an array of array references and returns a new AoA where C<output[j][i] = input[i][j]>.

 my $matrix = [[1, 2, 3], [4, 5, 6]];
 my $t = transpose($matrix);
 # [[1, 4],
 #  [2, 5],
 #  [3, 6]]

All rows must be the same length; a ragged input is a fatal error.
C<undef> is valid as an element value and is preserved exactly. An empty outer array or an array of empty rows both return C<[]>.

Dies if:
- any inner element is not an array reference
- rows differ in length (ragged array)

=head3 Hash of hash input

Takes a reference to a hash of hash references and returns a new HoH where C<output{col}{row} = input{row}{col}>.

 my $table = { alice => { score => 97, grade => 'A' }, bob   => { score => 84, grade => 'B' } };
 my $t = transpose($table);
 # { score => { alice => 97,  bob => 84  },
 #   grade => { alice => 'A', bob => 'B' } }

Inner keys do not need to be uniform across rows. If a given column key appears in only some rows, the output hash for that column will simply contain only those rows — no padding or C<undef>-filling is performed.

 my $sparse = {
 a => { x => 1, y => 2 },
 b => { x => 3, z => 4 } };

 my $t = transpose($sparse);
 # { x => { a => 1, b => 3 },
 #   y => { a => 2 },
 #   z => { b => 4 } }

An empty outer hash or an outer hash whose inner hashes are all empty both return C<{}>.

Dies if any inner element is not a hash reference

=head2 uniq

Returns the distinct values of its arguments, in first-seen order.

 use Stats::LikeR;

 my @u = uniq(1, 2, 2, 3, 1);         # (1, 2, 3)
 my @s = uniq(qw/a b a c/);           # ('a', 'b', 'c')
 my @f = uniq(1, [2, 2, 3], [3, 4]);  # (1, 2, 3, 4)
 my $n = uniq(1, 2, 2, 3, 1);         # 3

C<uniq> accepts a flat list of scalars, array references, or any mix of the
two. Array references are expanded B<one level> — their elements are treated
as additional arguments, but nested array references are not recursed into and
are compared as opaque values.

Values are compared by stringification, the same C<eq> semantics used by
C<List::Util::uniq>: C<1>, C<1.0>, and C<"1"> all collapse to a single result, and
the first value seen is the one returned (as a fresh copy, never an alias to
the input). Order of first appearance is preserved.

In list context C<uniq> returns the distinct values. In scalar context it
returns the I<count> of distinct values, matching C<List::Util::uniq>.

The UTF-8 flag is part of the comparison key, so a UTF-8 string and a
byte-identical non-UTF-8 string are kept distinct — they are different strings.
Strings that are logically equal and consistently encoded collapse as expected.

Unlike C<List::Util::uniq>, which passes a single C<undef> through, C<uniq>
B<croaks> on any undefined value, reporting the offending argument index (and
the array-ref index, when the undef came from inside a reference):

 uniq(1, undef, 3);     # croaks: undefined value at argument index 1
 uniq([1, undef, 3]);   # croaks: undefined value at array ref index 1 (argument 0)

This matches the undef-handling of C<mean> and the other functions in Stats::LikeR.

=head2 vals

Extract a single column from a data frame as a flat array reference, similar to pandas' C<to_list>

 my $ages = vals($df, 'age');

C<vals> accepts all three data-frame shapes and always returns a new arrayref of that column's values:

=over

=item * B<AoH> (array of hashes) -- one value per row, in row order.

=item * B<HoA> (hash of arrays) -- the named column array, copied.

=item * B<HoH> (hash of hashes) -- one value per row, in B<ascending key order> (a HoH has no inherent row order, so keys are sorted as strings).

=back

=head3 Arguments

=for html <table>
<thead>
<tr>
  <th>Position</th>
  <th>Name</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>$df</code></td>
  <td>An AoH (arrayref), or a HoA/HoH (hashref). The shape is auto-detected by peeking the first hash value: a hashref value means HoH, otherwise HoA.</td>
</tr>
<tr>
  <td>2</td>
  <td><code>$col</code></td>
  <td>The column name (must be defined).</td>
</tr>
</tbody>
</table>

=head3 Behavior and notes

=over

=item * B<The result is a copy.> Every value is duplicated, so mutating the returned array never touches C<$df>, and C<undef> slots are ordinary writable scalars.

=item * B<< A missing cell is C<undef>. >> For AoH and HoH, a row that lacks the column (or isn't a hashref) yields C<undef> for that row.

=item * B<An absent column is strict only for HoA.> Because a HoA column I<is> the structure, asking for a column the hash doesn't have dies. For AoH/HoH the column is per-row, so an entirely-absent column simply yields all-C<undef> (it is not an error). This asymmetry is deliberate; pass the column name carefully for AoH/HoH, since a typo returns C<undef>s rather than dying.

=item * B<< Empty frames return C<[]> >> -- an empty AoH or an empty hash both give a clean empty arrayref.

=item * UTF-8 column names and HoH keys are handled correctly (lookups use the key SV; HoH keys sort by Perl string order).

=back

=head3 Examples

 my $aoh = read_table('patients.csv');                 # array of hashes
 my $age = vals($aoh, 'Age');                           # [ 34, 51, ... ]

 my $hoa = read_table('patients.csv', 'output.type' => 'hoa');
 my $sex = vals($hoa, 'Sex');                           # copy of the Sex column

 my $hoh = read_table('patients.csv', 'output.type' => 'hoh');
 my $age2 = vals($hoh, 'Age');                          # values in sorted row-key order

 # feed straight into the numeric routines
 my $m = mean( vals($aoh, 'Age') );

=head2 value_counts

Count the values in a given data set, return a hash reference showing how many times each particular value is present.

=head3 Scalar

 $hash = value_counts('c');

returns C<< { c =E<gt> 1 } >>

=head3 Array reference

 value_counts(['a','b','b']);

returns C<< { a =E<gt> 1, b =E<gt> 2} >>

=head3 Array

 my $value_counts = value_counts('a','b','b');

like an array reference above, returns C<< { a =E<gt> 1, b =E<gt> 2} >>

=head3 Array of hashes

 my @records = (
     { name => 'Alice', dept => 'Sales' },
     { name => 'Bob',   dept => 'Eng'   },
     { name => 'Carol', dept => 'Sales' },
 );
 my $vc = value_counts(\@records, 'dept');

with a key, the value at that key is counted in each hash, so the above returns C<< { Sales =E<gt> 2, Eng =E<gt> 1 } >>. A record that lacks the key is skipped. Passing an array of hashes without a key, or with an element that is not a hash reference, is a fatal error.

=head3 Array of arrays

 my @rows = (['a', 1], ['b', 1], ['a', 2]);
 my $vc = value_counts(\@rows, 0);

when the elements are array references, the key is treated as a numeric column index, so the above returns C<< { a =E<gt> 2, b =E<gt> 1 } >>. A non-numeric index against array-reference elements is a fatal error.

=head3 Hash

 my $value_counts = value_counts( { A => 'a', B => 'a', C => 'b' } );

returns C<< { a =E<gt> 2, b =E<gt> 1} >>

=head3 Hash of array

 my $value_counts = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']});

without a key (like above), the occurences of C<j>, C<t>, and C<v> are counted.
With a key, like C<a> for above, only values within that hash key are counted:

 my $vc = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']}, 'a');

=head3 Hash of hash (table)

 $hash = value_counts( {
     A => {
         a => 'x',
         b => 'z'
     },
     B => {
         a => 'x'
     },
     C => {
         a => 'y'
     }
 }, 'a');

the column, or second hash key, that you wish to count, is specified at the command line

The two new subsections (Array of hashes, Array of arrays) are the only additions; everything else is unchanged. They're placed after the array-container forms to keep array inputs grouped, mirroring how Hash of array / Hash of hash sit together. If you'd rather I drop this into a C<.md> file or fold it into POD (C<=head3> headers, C<< CE<lt>E<gt> >> for the inline code) for the actual module docs, say the word.

=head2 var

as simple as possible:

 var(2, 4, 5, 8, 9)

C<var> will die if any undefined values are provided

like C<min>, C<max>, etc., C<var> can accept array references, to make code simpler:

 my $ref = \@arr;
 var($ref) = var(@arr)

=head2 var_test

As described by R: Performs an F test to compare the variances of two samples from normal populations

 use Stats::LikeR;

 my @x = (2.9, 3.0, 2.5, 2.6, 3.2);
 my @y = (3.8, 2.7, 4.0, 2.4);

 my $vt = var_test(\@x, \@y);

also, conf_level can be set:

 $vt = var_test(\@x, \@y, conf_level => 0.99);

as well as a ratio (from R: the hypothesized ratio of the population variances of C<x> and C<y>:

 $test_data = var_test(\@xk, \@yk, ratio => 2);

=head2 view

An R-style C<head> for the structures C<read_table> returns. Prints the first
few rows of a dataframe as an aligned text table, with numeric columns
right-justified, string columns left-justified, and undefined cells shown as
C<NA>.

=for html <table>
<thead>
<tr>
  <th>Input type</th>
  <th>Perl structure</th>
  <th>What <code>view</code> shows</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>aoa</code></td>
  <td>array of array refs</td>
  <td>values gathered column-wise by row index</td>
</tr>
<tr>
  <td><code>aoh</code></td>
  <td>array of hash refs</td>
  <td>one line per row, sequential row numbers</td>
</tr>
<tr>
  <td><code>hoa</code></td>
  <td>hash of array refs</td>
  <td>values gathered column-wise by row index</td>
</tr>
<tr>
  <td><code>hoh</code></td>
  <td>hash of hash refs</td>
  <td>top-level keys become the row label column</td>
</tr>
</tbody>
</table>

=head3 Synopsis

 my $aoh = read_table('all.data.tsv', 'output.type' => 'aoh');

 view($aoh);                       # first 6 rows, like head()
 view($aoh, n => 20);              # first 20 rows
 view($aoh, cols => [qw(id age tt)]);   # force a column order
 view($aoh, 'row.names' => 'id');  # use column 'id' as the row label
 view($aoh, na => '.', max_width => 30);

 my $txt = view($aoh, return_only => 1);  # capture the string, print nothing
 view($aoh, to => \*STDERR);              # print somewhere other than STDOUT

=head3 Output

 # AoH: 7 rows x 3 cols  (showing 6)
 row_name  Testosterone, total (nmol/L)  age  sex
 p1                                18.2   41  M
 p2                                  NA    7  F
 p3                                1.05   33  F
 p4                                22.9   55  M
 p5                                  14   29  M
 p6                                  NA   62  F
 # ... 1 more row

The banner reports the structure type, full dimensions, and how many rows are
displayed. A footer appears only when rows are hidden.

=head3 Arguments

All arguments after the data reference are optional name/value pairs.

=for html <table>
<thead>
<tr>
  <th>Argument</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>n</code></td>
  <td><code>6</code></td>
  <td>Number of rows to show. <code>n</code> greater than the table shows everything.</td>
</tr>
<tr>
  <td><code>rows</code></td>
  <td><code>6</code></td>
  <td>Number of rows to show. <code>n</code> greater than the table shows everything  (synonymous with <code>n</code>)</td>
</tr>
<tr>
  <td><code>cols</code> / <code>columns</code></td>
  <td>—</td>
  <td>Array ref pinning column order (and which columns appear).</td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td>—</td>
  <td>Column to use as the row label (for <code>aoh</code>/<code>hoa</code>). See ordering note.</td>
</tr>
<tr>
  <td><code>na</code></td>
  <td><code>'NA'</code></td>
  <td>Token printed for undefined cells</td>
</tr>
<tr>
  <td><code>max_width</code></td>
  <td><code>80</code></td>
  <td>Truncate any cell wider than this (column names are never truncated)</td>
</tr>
<tr>
  <td><code>ellipsis</code></td>
  <td><code>'...'</code></td>
  <td>Marker appended to truncated cells</td>
</tr>
<tr>
  <td><code>gap</code></td>
  <td><code>2</code></td>
  <td>Spaces between columns</td>
</tr>
<tr>
  <td><code>to</code></td>
  <td>STDOUT</td>
  <td>Filehandle to print to.</td>
</tr>
<tr>
  <td><code>return_only</code></td>
  <td><code>0</code></td>
  <td>If true, return the string and print nothing</td>
</tr>
</tbody>
</table>

C<view> always returns the formatted string, whether or not it also prints.

=head3 A note on column order

C<read_table> stores rows as hashes, so the original CSV column order is not
preserved. C<view> therefore sorts columns by name for a stable, reproducible
layout. Two conveniences soften this:

=over

=item * A column literally named C<row_name> (the label C<read_table> assigns to a
leading blank header) is detected automatically and moved to the left as the
row label.

=item * Pass C<< cols =E<gt> [ ... ] >> to control both the order and the selection of columns
shown.

=back

When no label column is present, C<view> numbers the rows C<1, 2, 3, …>, the way
R prints row names for an unnamed data frame.

=head3 Edge cases

=over

=item * Empty input (C<[]> or C<{}>) prints a clean C<0 rows x 0 cols> banner.

=item * Tabs, carriage returns, and newlines inside a cell are escaped (C<\t>, C<\r>,
C<\n>) so one record always stays on one line.

=item * A non-reference argument, or a hash whose values are plain scalars, dies with
a clear message rather than producing garbled output.

=back

=head3 Tests

The behavior above is covered by C<view.t> (run with C<prove view.t>): the three
structure types, C<n> boundaries, alignment, C<NA> rendering, truncation,
C<row.names>/C<cols> handling, control-character escaping, the C<return_only> and
C<to> output paths, empty structures, and the error cases.

=head2 vif

Variance inflation factors, the standard multicollinearity diagnostic for a
regression model. For each predictor, C<vif> regresses it on all the other
predictors and reports C<1 / (1 - R²)>; values above ~5–10 flag problematic
collinearity. The second argument is either a formula string (its right-hand-side
terms are used) or an array reference of predictor column names. Validated
numerically against R. Numeric predictors only — categorical predictors would
need a generalized VIF.

 my $v = vif(\%data, [qw(age bmi sbp chol)]);        # or 'y ~ age + bmi + sbp + chol'
 for my $p (sort { $v->{$b} <=> $v->{$a} } keys %$v) {
     printf "%-6s VIF = %.2f\n", $p, $v->{$p};
 }

Returns a hash of C<< predictor =E<gt> VIF >>.

=head2 wilcox_test

 $test_data = wilcox_test(
     [1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
     [0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
 );

Computes the Wilcoxon rank-sum / Mann-Whitney test (two samples) or the Wilcoxon signed-rank test (one sample or paired), following R's C<wilcox.test> conventions as of R 4.6.1.
This is an alternative to the t-test, that does not assume a normal distribution.
With two array refs and no C<paired> flag it runs the two-sample rank-sum test; with a single sample, or with C<< paired =E<gt> 1 >>, it runs the signed-rank test. It calculates exact p-values by default for C<< N E<lt> 50 >>, including when there are ties or zero differences: as in R 4.6.0 and later, tied data is answered from the conditional (permutation) distribution given the observed ranks rather than falling back to the normal approximation. Optionally it also returns a Hodges-Lehmann point estimate and a distribution-free confidence interval.

=head3 Calling conventions

The first one or two array-ref arguments are taken positionally as C<x> and C<y>; everything after that is parsed as C<< key =E<gt> value >> pairs. The named forms C<< x =E<gt> >> and C<< y =E<gt> >> are also accepted and override the positional values. The flat argument list following the positional refs must contain an even number of elements, or the call dies with a usage message.

 # positional
 wilcox_test(\@x, \@y, paired => 1);

 # fully named
 wilcox_test(x => \@x, y => \@y, alternative => "greater", exact => 0);

 # with a confidence interval and point estimate
 wilcox_test(\@x, \@y, conf_int => 1, conf_level => 0.99);

Arguments that R spells with a dot are accepted with either spelling: C<conf.int> and C<conf_int>, C<conf.level> and C<conf_level>, C<digits.rank> and C<digits_rank>, C<tol.root> and C<tol_root>.

=head3 Input parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>x</code></td>
  <td>ARRAY ref</td>
  <td><i>(required)</i></td>
  <td>The first sample. Passed positionally or as <code>x =&gt;</code>. Non-numeric, undefined and <code>NaN</code> elements are silently dropped (<code>NaN</code> is R's <code>NA</code>); <code>+Inf</code> and <code>-Inf</code> are kept, since a rank test has no trouble with them. An empty or all-missing <code>x</code> is fatal. In the two-sample test <code>mu</code> is subtracted from each <code>x</code> value.</td>
</tr>
<tr>
  <td><code>y</code></td>
  <td>ARRAY ref</td>
  <td><code>undef</code></td>
  <td>The second sample. If present and <code>paired</code> is false, a two-sample rank-sum test is run. If <code>paired</code> is true, <code>y</code> is required and must be the same length as <code>x</code>. Omit it, or pass <code>undef</code>, for the one-sample signed-rank test. A <code>y</code> that is present but empty (or entirely missing) is fatal rather than silently becoming a one-sample test.</td>
</tr>
<tr>
  <td><code>paired</code></td>
  <td>boolean</td>
  <td><code>0</code> (false)</td>
  <td>Run a paired signed-rank test on the per-element differences <code>x[i] - y[i] - mu</code>. Requires <code>y</code> of equal length. A pair is dropped if either member is missing, or if the difference is <code>NaN</code> (which is what <code>Inf - Inf</code> gives).</td>
</tr>
<tr>
  <td><code>correct</code></td>
  <td>boolean</td>
  <td><code>1</code> (true)</td>
  <td>Apply the continuity correction (±0.5) when using the normal approximation. Ignored when an exact p-value is computed.</td>
</tr>
<tr>
  <td><code>edgeworth</code></td>
  <td>integer 0-3</td>
  <td><code>0</code></td>
  <td>Number of Edgeworth series terms used to refine the normal approximation, for the untied case. This is what R reaches through its integer <code>correct = 1, 2, 3</code>; see the note below on why it is spelled separately here. Ignored on the exact path, and — as in R — ignored when there are ties, or when the signed-rank test dropped a zero difference, because the series is derived for untied ranks.</td>
</tr>
<tr>
  <td><code>mu</code></td>
  <td>number</td>
  <td><code>0.0</code></td>
  <td>Null-hypothesis location shift. Subtracted from <code>x</code> (two-sample) or from each difference (one-sample / paired). Must be finite.</td>
</tr>
<tr>
  <td><code>exact</code></td>
  <td>boolean / undef</td>
  <td><code>undef</code> (auto)</td>
  <td>Tri-state. <code>undef</code> (or absent) selects exact automatically: when both group sizes are <code>&lt; 50</code> (two-sample), or <code>n &lt; 50</code> (signed-rank). A true value forces the exact test, a false value forces the approximation. Ties and zero differences no longer disable it.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>string</td>
  <td><code>"two.sided"</code></td>
  <td>One of <code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>. Selects the tail(s) used for the p-value.</td>
</tr>
<tr>
  <td><code>conf.int</code></td>
  <td>boolean</td>
  <td><code>0</code> (false)</td>
  <td>Also compute a point estimate and confidence interval for the location (one-sample) or location shift (two-sample / paired).</td>
</tr>
<tr>
  <td><code>conf.level</code></td>
  <td>number in (0,1)</td>
  <td><code>0.95</code></td>
  <td>Requested confidence level. The level a rank test can actually deliver is discrete, so the level achieved is reported back in <code>conf_level</code> and is generally not the one asked for.</td>
</tr>
<tr>
  <td><code>digits.rank</code></td>
  <td>number / undef</td>
  <td><code>undef</code> (Inf)</td>
  <td>Round each value to this many significant digits before ranking, so that ties are decided on the rounded values. R's <code>digits.rank</code>, and worth reaching for when the data are the result of arithmetic and two values that ought to tie differ in the last bit. <code>undef</code> means no rounding.</td>
</tr>
<tr>
  <td><code>tol.root</code></td>
  <td>number &gt; 0</td>
  <td><code>1e-4</code></td>
  <td>Convergence tolerance for the root search behind the <i>asymptotic</i> confidence interval. The exact interval is made of order statistics and does not use it.</td>
</tr>
</tbody>
</table>

=head3 Output

Returns a hash ref with the following keys:

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Type</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>statistic</code></td>
  <td>number</td>
  <td>The test statistic. For the two-sample test this is the Mann-Whitney <b>W</b> (the <code>x</code> rank sum minus <code>nx*(nx+1)/2</code>). For the signed-rank test it is <b>V</b>, the sum of the ranks assigned to the positive differences.</td>
</tr>
<tr>
  <td><code>statistic_name</code></td>
  <td>string</td>
  <td><code>"W"</code> or <code>"V"</code>, matching what R prints.</td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td>number</td>
  <td>The p-value for the chosen <code>alternative</code>, capped at <code>1.0</code>. Two-sided p-values are <code>2 * min(p_less, p_greater)</code>.</td>
</tr>
<tr>
  <td><code>method</code></td>
  <td>string</td>
  <td>A human-readable description of the exact test variant that was run (see below).</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>string</td>
  <td>Echoes the <code>alternative</code> actually used (<code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>).</td>
</tr>
<tr>
  <td><code>null_value</code></td>
  <td>number</td>
  <td>Echoes <code>mu</code>.</td>
</tr>
<tr>
  <td><code>null_value_name</code></td>
  <td>string</td>
  <td><code>"location shift"</code> for the two-sample and paired tests, <code>"location"</code> for the one-sample test.</td>
</tr>
<tr>
  <td><code>estimate</code></td>
  <td>number</td>
  <td><i>(only with <code>conf.int</code>)</i> The Hodges-Lehmann estimator: the median of the Walsh averages <code>(x[i] + x[j]) / 2</code> in the one-sample case, or of the pairwise differences <code>x[i] - y[j]</code> in the two-sample case. On the asymptotic path it is instead the shift at which the standardised statistic is zero, as in R.</td>
</tr>
<tr>
  <td><code>conf_int</code></td>
  <td>ARRAY ref</td>
  <td><i>(only with <code>conf.int</code>)</i> Two elements, the lower and upper limits. A one-sided alternative gives an unbounded end (<code>-Inf</code> or <code>Inf</code>).</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td>number</td>
  <td><i>(only with <code>conf.int</code>)</i> The confidence level actually achieved, which for the exact interval is a step function of the data and rarely equals <code>conf.level</code>.</td>
</tr>
</tbody>
</table>

The C<method> string reports which path executed:

=over

=item * Two-sample: C<"Wilcoxon rank sum exact test">, C<"Wilcoxon rank sum test with continuity correction">, or C<"Wilcoxon rank sum test">.

=item * One-sample / paired: C<"Wilcoxon signed rank exact test">, C<"Wilcoxon signed rank test with continuity correction">, or C<"Wilcoxon signed rank test">.

=back

=head3 Exact inference with ties

Before R 4.6.0 — and in earlier releases of this module — ties ruled out an exact p-value and the test silently fell back to the normal approximation. It no longer does. When ties are present the exact null distribution is the conditional one given the observed ranks, computed with the Streitberg-Röhmel shift algorithm, and the same holds for zero differences in the signed-rank test. Two consequences are worth knowing about:

=over

=item * p-values on tied data change from earlier versions. R's own documented example, C<wilcox_test(\@x, \@y)> on the C<?wilcox.test> data, moves from C<0.13292> (approximation) to C<0.12991> (exact).

=item * with zero differences, B<V> itself changes. The exact test ranks C<|x - mu|> over every observation and only then drops the ranks belonging to the zeroes; the approximation drops the zeroes first and ranks what is left. C<wilcox_test([-1, 0, 1])> gives C<V = 2.5> on the exact path and C<V = 1.5> with C<< exact =E<gt> 0 >>. R behaves the same way.

=back

The exact table is refused rather than attempted if it would need more than 16 million cells, with a message suggesting C<< exact =E<gt> 0 >>. This is only reachable by forcing C<< exact =E<gt> 1 >> on samples far larger than the automatic threshold.

=head3 Notes and edge cases

Missing data is handled by listwise removal of non-numeric, undefined and C<NaN> cells before ranking; in the paired case a pair is dropped if either member is missing or if the difference is not a number. An empty C<x> (or a C<y> that is present but empty) after this filtering is fatal. All-zero differences are not: C<wilcox_test([0, 0, 0, 0, 0])> returns C<V = 0>, C<p = 1>, which is what the permutation distribution over an empty set of sign flips says.

Ties are detected during ranking and trigger the tie-corrected variance in the normal approximation. When C<exact> is left on auto, the size thresholds (C<< E<lt> 50 >> per group, or C<< E<lt> 50 >> observations) are the only thing gating the exact vs. approximate decision.

=head3 Differences from R

Two, both deliberate:

=over

=item * B<< C<correct> is a boolean here. >> R 4.6.0 turned its C<correct> into an integer C<0:3>, in which numeric C<0> still applies the continuity correction and only C<FALSE> removes it. Keeping that would mean C<< correct =E<gt> 0 >> no longer meaning "off", which is what it means for every other flag in this module. So C<correct> stays a boolean and the Edgeworth terms live under C<edgeworth>: R's C<correct = k> for C<k> in C<1, 2, 3> is C<< correct =E<gt> 1, edgeworth =E<gt> k >> here, and R's C<correct = 0> is C<< correct =E<gt> 1 >>.

=item * B<A zero variance is reported, not propagated.> With C<< exact =E<gt> 0 >> and every observation tied there is nothing to divide by; R divides anyway and returns C<NaN> for the p-value, and its two-sample confidence interval then dies inside C<uniroot> with I<missing value where TRUE/FALSE needed>. This warns instead, and returns C<p = 1> and a C<NaN> interval at level C<0> — which is what R's own one-sample code does. The default path no longer reaches any of this, since the exact test handles all-tied data.

=back

Everything else is checked against R's and SciPy's own test suites in C<t/wilcox_test.R.scipy.t>.

=head2 write_table

mimics R's C<write.table>, with data as first argument to subroutine, and output file as second

 write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => 1);

C<write_table> accepts every data-frame shape: a flat hash (one row), a hash of arrays (HoA), a hash of hashes (HoH), an array of hashes (AoH), and an array of arrays (AoA). For an AoA the first inner array is taken as the header row unless C<col.names> is given, in which case every inner array is treated as data:

 write_table([[qw(gene score)], ['TP53', 0.9], ['BRCA1', 0.7]], $tmp_file, 'row.names' => 0);
 write_table([['TP53', 0.9], ['BRCA1', 0.7]], $tmp_file, 'col.names' => [qw(gene score)]);

You can also precisely filter and reorder which columns are written by passing an array reference to C<col.names>:

 write_table(\@data, $tmp_file, sep => "\t", 'col.names' => ['c', 'a']);

undefined variables are printed as C<NA> by default, but can be set as you wish using C<undef.val>

 write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan')

C<write_table> determines comma and tab-separated delimiters from the filename, but will override if C<sep> or C<delim> are explicitly set.
Args can also be accepted:

 write_table( 'data' => \%flat, 'file' => $f );

=head3 The confirmation line

Every successful write prints one line to standard output naming the file, with the name in black on cyan:

 wrote output.tsv

This is C<say 'wrote ' . colored(['black on_cyan'], $file)>, but the SGR codes (C<\e[30;46m> … C<\e[0m>) are written out inline, so the module takes no dependency on C<Term::ANSIColor>. Every format announces itself the same way — delimited, LaTeX and C<.xlsx> alike — so you always learn where a table went, in the same shape whatever you asked for. Nothing is printed when nothing is written: an empty data frame returns before a file is opened, and a write that cannot open its file croaks instead.

The colour is unconditional; it is not suppressed when standard output is a pipe or a file. If you are capturing the output and want the bytes plain, strip the escapes (C<s/\e\[[\d;]*m//g>) or send them somewhere else. Note also that the line goes to file descriptor 1 directly rather than through Perl's C<STDOUT> glob, so C<< local *STDOUT; open STDOUT, 'E<gt>', \my $buf >> will B<not> capture it — redirect the file descriptor, or run the write in a child process, if you need to.

=head3 LaTeX output (C<tex>)

C<write_table> can write the output file as a LaTeX C<tabular> instead of a delimited table. This is selected either by naming the file C<*.tex> (auto-detected) or by passing C<< tex =E<gt> 1 >>; an explicit C<< tex =E<gt> 0 >> forces a delimited file even when the name ends in C<.tex>. The LaTeX table is built from the same rows as the delimited writer, so it works for every shape above (including arrays of arrays):

 write_table(\@data_aoh, 'table.tex');            # .tex name selects LaTeX
 write_table(\@data_aoh, $tmp_file, 'tex' => 1);  # force LaTeX for any name

The file begins with a C<< %written by E<lt>cwdE<gt>/E<lt>scriptE<gt> >> provenance comment (the working directory and script name). The header row is bold and the table is ruled with C<\hline>. As with every other format, C<row.names> is B<off> unless you ask for it: pass C<< row.names =E<gt> 1 >> to prepend a label column, whose labels are the outer keys for a HoH and a 1-based index otherwise. Cell text is LaTeX-escaped: C<#>, C<_>, C<%>, and C<&> are backslash-escaped, C<< E<gt> >> becomes C<\textgreater{}>, and a cell consisting solely of C<\includesvg{...svg}> is passed through untouched. The C<tex.*> options tune the output:

 write_table(\@rows, 'table.tex',
     'tex.col.align'    => 'l',                   # 'c' (default), 'l', or 'r'
     'tex.bold.1st.col' => 0,                     # default 1: bold the first column
     'tex.format'       => 1,                     # %.4g-format numeric cells
     'tex.size'         => '\small',              # size directive after \begin{tabular}
     'tex.comment'      => ['run 3', 'q < 0.05'], # % comment line(s): string or array ref
 );

For a table that must span page breaks, C<< tex.longtable =E<gt> 1 >> writes only the table I<body> — the bold header row and the data rows, ruled with C<\hline> — but no C<\begin{tabular}>/C<\end{tabular}> and no column spec, so you can C<\input{}> it into a C<longtable> environment you write yourself. Setting C<tex.longtable> implies C<< tex =E<gt> 1 >>, so it applies to any file name (and overrides C<< tex =E<gt> 0 >>). After the provenance comment (and any C<tex.comment> lines) the file emits a C<% \begin{longtable}{...}> hint with one C<tex.col.align> character per column, so you can copy a column spec with the right count. In this mode C<tex.col.align> affects only that hint — the real alignment lives on your own C<\begin{longtable}>; the other C<tex.*> options (C<tex.bold.1st.col>, C<tex.format>, C<tex.size>, C<tex.comment>) still apply:

 write_table(\@rows, 'output.file.tex', 'tex.longtable' => 1);

writes a body-only file such as

 %written by /home/con/Scripts/stats/make_table.pl
 % \begin{longtable}{ccc}
 \hline
 \textbf{a} & \textbf{b} & \textbf{c} \\ \hline
 1 & 2 & 3\\
 \hline

which you wrap yourself:

 \begin{longtable}{ccc}
 \input{output.file.tex}
 \caption{}
 \label{}
 \end{longtable}

In that plain form the header is an ordinary first row, which is I<not> the header LaTeX freezes at the top of each page: a C<longtable> repeats only what sits inside C<\endfirsthead> / C<\endhead>. Hand-writing those blocks means retyping the column labels, and they then silently stop matching C<col.names> the first time the column order changes — the frozen header says one thing while the columns underneath say another, and the generated header shows up a second time as the first body row. C<tex.longtable.head> closes that gap by generating the repeat machinery from the same header record as the body:

 write_table(\@rows, 'output.file.tex',
     'col.names'          => ['a', 'b', 'c'],
     'tex.longtable.head' => '(continued)', # or just 1 for no continuation caption
 );
 %written by /home/con/Scripts/stats/make_table.pl
 % \begin{longtable}{ccc}
 \textbf{a} & \textbf{b} & \textbf{c} \\ \hline
 \endfirsthead
 \caption[]{(continued)}\\
 \hline
 \textbf{a} & \textbf{b} & \textbf{c} \\ \hline
 \endhead
 \hline
 \endfoot
 1 & 2 & 3\\

Setting C<tex.longtable.head> implies C<tex.longtable> (and so C<< tex =E<gt> 1 >>). A true-but-numeric value emits the machinery with no continuation caption; any other true value is the caption text for every page after the first, written verbatim so LaTeX macros survive, with an empty C<\caption[]> optional argument so the continuation stays out of the List of Tables. C<\endfoot> carries the closing C<\hline> and no C<\endlastfoot> is emitted, so every page — the last one included — gets a bottom rule. The wrapper then holds nothing that has to track the data:

 \begin{longtable}{ccc}
 \caption{}\label{}\\ \hline
 \input{output.file.tex}
 \end{longtable}

The trailing C<\hline> on the caption line is the rule above the header on the I<first> page, and it has to live there rather than in the generated file: C<\hline> expands to C<\noalign>, and TeX has already begun a table row by the time it expands your C<\input>, so a rule as the file's first token is a C<Misplaced \noalign> error. A bare C<\hline> encodes neither column order nor column count, so unlike a hand-written header it cannot go stale — drop it if you do not want a top rule. Every other C<\hline> in the generated file follows a C<\\> inside that file, where it is legal.

=head3 Excel output (C<xlsx>)

C<write_table> can write a real Excel C<.xlsx> workbook. It is selected either by naming the file C<*.xlsx> (auto-detected) or by passing C<< xlsx =E<gt> 1 >>; an explicit C<< xlsx =E<gt> 0 >> forces a delimited file even for a C<.xlsx> name. Like LaTeX, it is built from the same rows as the delimited
writer, so it works for every shape above:

 write_table(\@data_aoh, 'table.xlsx');            # .xlsx name selects Excel
 write_table(\%data_hoa, $tmp_file, 'xlsx' => 1);  # force Excel for any name

A numeric-looking cell is written as a number; every other non-empty cell as an
inline string (C<undef>/empty cells are omitted). The result reads straight back
with L<C<read_table>|/"read_table">.

Mirroring C<Excel::Writer::XLSX>'s
C<< $workbook-E<gt>set_properties(comments =E<gt> comments()) >>, the same
C<< written by E<lt>cwdE<gt>/E<lt>scriptE<gt> >> provenance line the LaTeX writer emits is stored in
the workbook's document B<comments> property (C<dc:description> in
C<docProps/core.xml>); a C<xlsx.comment> string (or array ref of strings) is
appended after it. C<xlsx.sheet> sets the worksheet name (default C<Sheet1>):

 write_table(\@rows, 'report.xlsx',
     'xlsx.sheet'   => 'Results',
     'xlsx.comment' => 'batch 9',
 );

C<xlsx.freeze.rows> and C<xlsx.freeze.cols> freeze that many leading rows/columns in place (Excel's I<freeze panes>), so they stay visible while scrolling — most often used to pin the header row:

 write_table(\@rows, 'report.xlsx', 'xlsx.freeze.rows' => 1);                        # pin the header row
 write_table(\@rows, 'report.xlsx', 'xlsx.freeze.rows' => 1, 'xlsx.freeze.cols' => 2); # pin header + first two columns

C<tex> and C<xlsx> are mutually exclusive. Note: dates/times are written as their
raw values (no cell number formats), matching the round-trip behaviour of
C<read_table>.

=head3 Options

=for html <table>
<thead>
<tr>
  <th>option</th>
  <th>default</th>
  <th>applies to</th>
  <th>meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>data</code> (1st positional, or <code>data =&gt;</code>)</td>
  <td><i>required</i></td>
  <td>both</td>
  <td>the table: flat hash, HoA, HoH, AoH, or AoA</td>
</tr>
<tr>
  <td><code>file</code> (2nd positional, or <code>file =&gt;</code>)</td>
  <td><i>required</i></td>
  <td>both</td>
  <td>output path; written as a delimited table, or as LaTeX when <code>tex</code> is on</td>
</tr>
<tr>
  <td><code>sep</code> / <code>delim</code></td>
  <td>from extension (<code>,</code> for <code>.csv</code>, tab for <code>.tsv</code>), else <code>,</code></td>
  <td>delimited</td>
  <td>field separator; the two are aliases</td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td><code>0</code> (off)</td>
  <td>both</td>
  <td>true prepends a label column (numeric 1-based index, or the outer key for a HoH); <code>0</code> omits it. Off by default in <b>every</b> format — delimited, LaTeX and <code>.xlsx</code> alike. (R's <code>write.table</code> defaults it on and this once followed suit for LaTeX; it no longer does.) For a HoA/AoH a non-numeric <i>column name</i> uses that column's values as the labels and drops it from the body</td>
</tr>
<tr>
  <td><code>col.names</code></td>
  <td>all columns, sorted</td>
  <td>both</td>
  <td>array ref selecting and ordering columns; for an AoA it also supplies the column names</td>
</tr>
<tr>
  <td><code>undef.val</code></td>
  <td><code>''</code> (empty field)</td>
  <td>both</td>
  <td>text written for an undefined/missing cell, e.g. <code>'NA'</code></td>
</tr>
<tr>
  <td><code>tex</code></td>
  <td>auto: <code>1</code> when <code>file</code> ends in <code>.tex</code>, else <code>0</code></td>
  <td>LaTeX</td>
  <td>write the output file as a LaTeX <code>tabular</code> instead of a delimited table; <code>tex =&gt; 0</code> forces delimited even for a <code>.tex</code> name</td>
</tr>
<tr>
  <td><code>tex.col.align</code></td>
  <td><code>'c'</code></td>
  <td>LaTeX</td>
  <td>per-column alignment: <code>'c'</code>, <code>'l'</code>, or <code>'r'</code>; with <code>tex.longtable</code> on it sets only the <code>% \begin{longtable}{...}</code> hint</td>
</tr>
<tr>
  <td><code>tex.bold.1st.col</code></td>
  <td><code>1</code> (on)</td>
  <td>LaTeX</td>
  <td>bold the first column of each data row</td>
</tr>
<tr>
  <td><code>tex.format</code></td>
  <td><code>0</code> (off)</td>
  <td>LaTeX</td>
  <td>render numeric cells with <code>%.4g</code></td>
</tr>
<tr>
  <td><code>tex.size</code></td>
  <td><i>(none)</i></td>
  <td>LaTeX</td>
  <td>size directive emitted after <code>\begin{tabular}</code>, e.g. <code>\small</code></td>
</tr>
<tr>
  <td><code>tex.comment</code></td>
  <td><i>(none)</i></td>
  <td>LaTeX</td>
  <td><code>%</code> comment line(s) at the top of the LaTeX file: a string, or an array ref of strings</td>
</tr>
<tr>
  <td><code>tex.longtable</code></td>
  <td><code>0</code> (off)</td>
  <td>LaTeX</td>
  <td>write only the table body (header + data rows + <code>\hline</code>, no <code>\begin{tabular}</code>/<code>\end{tabular}</code> or column spec) for <code>\input{}</code> into a caller-supplied <code>longtable</code>; implies <code>tex =&gt; 1</code>, and emits a <code>% \begin{longtable}{...}</code> hint with one <code>tex.col.align</code> char per column</td>
</tr>
<tr>
  <td><code>tex.longtable.head</code></td>
  <td><code>0</code> (off)</td>
  <td>LaTeX</td>
  <td>generate <code>longtable</code>'s repeat-header machinery (<code>\endfirsthead</code> / <code>\endhead</code> / <code>\endfoot</code>) from the table's own header, so the header frozen at every page break tracks <code>col.names</code> instead of being hand-written; a non-numeric value is the continuation caption. Implies <code>tex.longtable</code>. Put the first page's top rule on your own <code>\caption</code> line (<code>\\ \hline</code>) — a leading <code>\hline</code> in an <code>\input</code>ed file is a <code>Misplaced \noalign</code> error</td>
</tr>
<tr>
  <td><code>xlsx</code></td>
  <td>auto: <code>1</code> when <code>file</code> ends in <code>.xlsx</code>, else <code>0</code></td>
  <td>Excel</td>
  <td>write a real <code>.xlsx</code> workbook (dependency-free, built in XS) instead of a delimited table; <code>xlsx =&gt; 0</code> forces delimited even for a <code>.xlsx</code> name. Mutually exclusive with <code>tex</code></td>
</tr>
<tr>
  <td><code>xlsx.sheet</code></td>
  <td><code>'Sheet1'</code></td>
  <td>Excel</td>
  <td>worksheet name</td>
</tr>
<tr>
  <td><code>xlsx.comment</code></td>
  <td><i>(none)</i></td>
  <td>Excel</td>
  <td>extra line(s) appended after the provenance in the workbook's document <i>comments</i> property (<code>dc:description</code>): a string, or an array ref of strings</td>
</tr>
<tr>
  <td><code>xlsx.freeze.rows</code></td>
  <td><code>0</code> (none)</td>
  <td>Excel</td>
  <td>number of leading rows to freeze in place (freeze panes), e.g. <code>1</code> to pin the header row</td>
</tr>
<tr>
  <td><code>xlsx.freeze.cols</code></td>
  <td><code>0</code> (none)</td>
  <td>Excel</td>
  <td>number of leading columns to freeze in place (freeze panes)</td>
</tr>
</tbody>
</table>

=head1 Numerical accuracy

=head2 F and z tail p-values

A p-value is an upper-tail probability, and the obvious way to get one from a
CDF — subtract it from 1 — throws the answer away exactly when the answer
matters most. C<1 - pf(F, df1, df2)> cannot represent anything below the ulp of
C<1.0>, about C<2.2e-16>, so every p-value past that point comes back as a flat
C<0>, and relative precision is already eroding from roughly C<1e-9> down. The
same applies to C<2 * (1 - pnorm(|z|))> for a Wald z.

Every F and z p-value in C<Stats::LikeR> is therefore evaluated in the tail
itself:

=over

=item * B<F tests> (C<oneway_test>, C<aov>, C<anova> in both its forms, and C<lm>'s
C<f.pvalue>) use the regularized-incomplete-beta symmetry
C<1 - I_x(a, b) = I_{1-x}(b, a)>. With C<x = df1·F / (df1·F + df2)>, the
complement C<1 - x> is just C<df2 / (df1·F + df2)>, which is formed without any
subtraction, so the tail keeps full relative precision.

=item * B<Normal / z tails> (C<glm>'s C<< Pr(E<gt>|z|) >>, and C<cor_test>'s large-sample
approximation for the C<spearman> and C<kendall> methods) use
C<2 * pnorm(-|z|)> two-sided and C<pnorm(-z)> for the upper one-sided
alternative. C<pnorm> is C<0.5 * erfc(-x/√2)>, and C<erfc> is accurate deep into
its own tail, so evaluating at C<-|z|> rather than subtracting at C<+|z|> costs
nothing and loses nothing. R writes it the same way.

=item * B<Two-tailed t> (C<t_test>, C<cor_test>'s Pearson path, and the C<< Pr(E<gt>|t|) >>
columns of C<lm> and C<glm>) was always computed as a direct two-tail
incomplete-beta probability, so it never had the problem. So were the exact
permutation p-values C<cor_test> uses for small I<n>.

=back

Three functions outside this set still form a normal-tail p-value
subtractively, so a p-value from them below about C<1e-16> reads as C<0>:
C<wilcox_test> (the C<greater> alternative of the normal approximation, in both
the two-sample and the one-sample/paired branch — its C<two.sided> and C<less>
alternatives are already computed on the correct side), C<prop_test> (the
C<greater> alternative; C<two.sided> goes through the chi-squared path instead)
and C<dunn_test> (the two-sided per-comparison p-values that C<p_adjust> then
corrects).

The practical difference: C<lm> on a near-noiseless fit reports
C<f.pvalue = 7.0165242049e-220> where the subtractive form returned C<0>, and
C<anova>'s sequential table reports C<1.1543232446e-171> for the same reason.
Where the true value underflows a double even when computed correctly — a Wald
z beyond about 38.5 — the result is C<0>, and R and SciPy return C<0> there too.

Verified against R 4.6.1 (C<oneway.test>, C<anova(aov())>, C<anova(lm())>,
C<summary(lm())$fstatistic>, C<summary(glm())$coefficients>) and against SciPy's
C<f.sf> / C<norm.sf> and statsmodels' C<anova_oneway>; see
C<t/model_pvalue_tails.t> and C<t/oneway_test.R.scipy.t>.

=head1 Changes

=head2 0.298 2026-08-12 CDT

=head3 wilcox_test

A rewrite of C<wilcox_test> against R 4.6.1, driven by R's and SciPy's own test
suites rather than by cases invented here. It brings the function up to the
exact conditional inference R gained in 4.6.0, fixes six bugs — two of which
returned confidently wrong p-values on the I<default> code path — and adds the
Hodges-Lehmann estimate and confidence interval, C<digits.rank>, and the
Edgeworth series.

Everything below is checked in the new C<t/wilcox_test.R.scipy.t> (3,242 tests),
whose expected values are frozen literals with their provenance recorded in the
file header; it needs no R and no Python to run. The full suite is 120 files and
23,149 tests, and C<./test.all.perls.pl> passes on all five local perls —
C<5.10.1>, C<5.12.5> (long double), C<5.42.3>, C<5.44.0> and C<5.44.0-quadmath> —
with no warnings on any of them.

=head4 Exact p-values are now computed when there are ties

R 4.6.0 added exact (conditional) inference in the presence of ties, via Torsten
Hothorn's implementation of the Streitberg-Röhmel shift algorithm; R's
C<doc/NEWS.Rd> announces it and C<tests/reg-tests-1d.R> records the consequence at
its degenerate one-sample cases: I<< "For R >= 4.6.0 warnings for exact with ties
are gone." >> Before that, ties ruled out an exact p-value and both R and this
module fell back to the normal approximation with a warning.

C<wilcox_test> now does what R does. When ties are present the null distribution
is the conditional one given the observed ranks, and the same holds for zero
differences in the signed-rank test. The warnings are gone with them.

This changes published answers on tied data, including R's own documented
examples:

=for html <table>
<thead>
<tr>
  <th>case</th>
  <th>was</th>
  <th>is (R 4.6.1)</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>?wilcox.test</code> man-page data, <code>wilcox_test(\@x, \@y)</code></td>
  <td><code>0.13291945818531886</code></td>
  <td><code>0.12990538872891813</code></td>
</tr>
<tr>
  <td>the <code>airquality</code> Ozone example (<code>W = 127.5</code>)</td>
  <td><code>1.2080783e-04</code></td>
  <td><code>6.1087351888e-05</code></td>
</tr>
<tr>
  <td><code>wilcox_test([1,2,2,3], [4,5,5,6], exact =&gt; 1)</code></td>
  <td><code>0.02842953599879653</code> + a warning</td>
  <td><code>0.028571428571428571</code></td>
</tr>
<tr>
  <td><code>wilcox_test([1,1])</code></td>
  <td><code>0.34577858615116</code></td>
  <td><code>0.5</code></td>
</tr>
<tr>
  <td><code>wilcox_test([4,3,2], [3,2,1], paired =&gt; 1)</code></td>
  <td><code>0.14891467317876567</code></td>
  <td><code>0.25</code></td>
</tr>
</tbody>
</table>

Two further consequences are worth knowing about. B<V> itself changes when zero
differences are present, because the exact test ranks C<|x - mu|> over every
observation and only afterwards drops the ranks belonging to the zeroes, where
the approximation drops the zeroes first and ranks what is left:
C<wilcox_test([-1, 0, 1])> gives C<V = 2.5> exactly and C<V = 1.5> with
C<< exact =E<gt> 0 >>. R's two branches differ in exactly the same way. And degenerate
inputs that used to be fatal now return a result, as they must for
C<tests/reg-tests-1d.R> line 332 to pass: C<wilcox_test([0])> gives C<V = 0>,
C<p = 1>, and so does C<wilcox_test([0,0,0,0,0])>, which SciPy pins as
C<test_all_zeros_exact>.

If you need the old numbers, C<< exact =E<gt> 0 >> still asks for the approximation and
is unchanged.

=head4 The exact upper tail was returning zero, on the default path

C<p_greater> was computed as C<1 - CDF(q - 1)>. That subtraction cancels away every
significant digit once the true p falls below C<NV_EPSILON>, and then returns a
flat C<0>. It did not take a contrived input to reach: two perfectly separated
samples of 30 apiece are inside the automatic exact branch, no C<< exact =E<gt> 1 >>
required.

=for html <table>
<thead>
<tr>
  <th>m = n</th>
  <th>was</th>
  <th>is</th>
  <th>R 4.6.1</th>
</tr>
</thead>
<tbody>
<tr>
  <td>20</td>
  <td><code>7.2544192875e-12</code></td>
  <td><code>7.2544445519e-12</code></td>
  <td><code>7.2544445519e-12</code></td>
</tr>
<tr>
  <td>25</td>
  <td><code>7.8825834748e-15</code></td>
  <td><code>7.9107286024e-15</code></td>
  <td><code>7.9107286024e-15</code></td>
</tr>
<tr>
  <td>30</td>
  <td><b><code>0</code></b></td>
  <td><code>8.4556169461e-18</code></td>
  <td><code>8.4556169461e-18</code></td>
</tr>
<tr>
  <td>49</td>
  <td><b><code>0</code></b></td>
  <td><code>3.9250145965e-29</code></td>
  <td><code>3.9250145965e-29</code></td>
</tr>
</tbody>
</table>

Both tails are now summed directly. That alone is not enough for the rank-sum
table, whose Gaussian-binomial recurrence is built with subtractions, so far up
the support a count of C<1> is the difference of numbers around C<C(m+n, n)> and
has already been rounded into noise. The table is folded about its centre before
summing, so only well-conditioned entries are ever touched — the same thing R's
C<pwilcox()> does when it folds C<q> about C<m*n/2> and flips C<lower_tail>.

The signed-rank tail was accurate to C<n = 49> by luck (C<1 - 2^-49> is exactly
representable) and reached C<0> from about C<n = 53>; forcing
C<< exact =E<gt> 1 >> on C<n = 120> returned C<0> where R gives C<1.5046327690525337e-36>,
and now returns it too.

=head4 C<int m * n> overflowed, and said the samples were identical

C<exact_pwilcox> took C<int m, int n> and computed C<int max_u = m * n>. For two
separated samples of 50,000 that wraps negative, every statistic looks out of
range, and the function returns C<1.0>:

C<< perl
wilcox_test([1 .. 50000], [50001 .. 100000], exact =E<gt> 1);   # p = 1
 >>

Signed overflow is also undefined behaviour, so a different optimiser was
entitled to do something else entirely. Sizes and indices in the exact
distributions are C<size_t> now, the multiplications are checked for wrap before
they happen, and a table that would need more than 16 million cells is refused
outright with a message naming C<< exact =E<gt> 0 >> rather than attempted.

=head4 NaN was ranked instead of dropped

C<NaN> is C<NA> to R, and R drops it. C<looks_like_number> accepts it, C<d == 0.0>
is false for it, so it went into the rank buffer — and C<cmp_nv3> returns C<0> for
every comparison involving it, which leaves C<qsort> without the strict weak
ordering the C standard entitles it to.

The visible symptom is R's own regression case, C<tests/reg-tests-1d.R> line
3546, which asserts that a paired test is unaffected by pairs whose difference
is C<Inf - Inf>:

=for html <table>
<thead>
<tr>
  <th></th>
  <th>was</th>
  <th>is (and R)</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>1:5</code> vs <code>4*(0:4)</code></td>
  <td><code>V = 1</code>, <code>p = 0.125</code></td>
  <td><code>V = 1</code>, <code>p = 0.125</code></td>
</tr>
<tr>
  <td>the same with <code>+Inf</code> appended to both</td>
  <td><code>V = 1</code>, <code>p = 0.0625</code></td>
  <td><code>V = 1</code>, <code>p = 0.125</code></td>
</tr>
<tr>
  <td>the same with <code>-Inf</code> and <code>+Inf</code> on both</td>
  <td><code>V = 2</code>, <code>p = 0.046875</code></td>
  <td><code>V = 1</code>, <code>p = 0.125</code></td>
</tr>
</tbody>
</table>

C<NaN> — in either sample, and however it arises — is now dropped with the other
missing values. C<±Inf> is not missing and is kept, since a rank test has no
trouble with it; SciPy's C<test_gh_11355b> pins five cases of that and they all
agree.

=head4 An empty C<y> ran a different test

C<wilcox_test([1,2,3], [])> fell through to the one-sample branch and returned a
signed-rank result, silently answering a question nobody asked. It croaks now,
with R's message.

C<mu> was likewise unvalidated: C<< mu =E<gt> Inf >> or C<< mu =E<gt> NaN >> turned every
difference into a non-number and produced a confident answer from the wreckage.
Both croak now, as they do in R.

=head4 A dying C<$SIG{__WARN__}> handler leaked the rank buffer

The warnings in C<wilcox_test> were emitted while the C<RankInfo> and difference
buffers were held as raw pointers. A C<__WARN__> handler that dies — or C<warnings
FATAL> at the call site — longjmps straight past the C<Safefree>. Under valgrind,
500 iterations of the ties path with such a handler lost 95,616 bytes in 498
blocks. Every allocation now goes through C<Newx> plus C<SAVEFREEPV>, the idiom
C<chisq_test> in the same file already used, so it is released by the save stack
however the call unwinds. The same 500 iterations now report C<definitely lost: 0
bytes>, as does a sweep over every croak path and every branch of the function.

=head4 New: C<conf.int>, and a Hodges-Lehmann estimate

R has returned a distribution-free confidence interval and a point estimate
since PR#1150 in 2001, and C<tests/reg-tests-1a.R> has guarded them ever since
with Hollander & Wolfe's published numbers. C<wilcox_test> now computes both, by
all four of R's routes — the exact interval from the order statistics of the
Walsh averages or the pairwise differences, the exact interval conditional on
the observed ranks when there are ties, and the asymptotic interval from a root
search:

```perl
my $r = wilcox_test(\@y, \@x, paired => 1, conf_int => 1);

=head1 $r->{estimate}   == -0.46

=head1 $r->{conf_int}   == [-0.786, -0.010]

=head1 $r->{conf_level} == 0.9609375

```

Those are Hollander & Wolfe (1999) 2nd ed., pp. 40 and 53, to the digit. So are
the two-sample values from pp. 111 and 126: estimate C<-0.305>, interval
C<(-0.76, 0.15)>.

The level a rank test can actually deliver is a step function of the data, so
C<conf_level> reports what was achieved rather than echoing what was asked for —
C<0.9609375> above, not C<0.95>. C<conf.level>, C<tol.root> and R's alpha-doubling
search for a level the data can support (with its I<requested conf.level not
achievable> warning) all behave as R's do.

=head4 New: C<digits.rank>, C<edgeworth>, and more of R's result fields

C<digits.rank> rounds each value to a given number of significant digits before
ranking, so that ties are decided on the rounded values. R's man page recommends
it because tie detection is an exact C<==> on floating point, and its own worked
example shows C<(4:2)/10> against C<(3:1)/10> — three differences that ought to be
C<0.1> and are three different doubles. Ported from R's C<fprec()>, half-to-even
rounding included.

C<< edgeworth =E<gt> 1, 2, 3 >> adds up to three Edgeworth correction terms to the normal
approximation, the refinement R 4.6.0 reaches through its integer C<correct>. It
is ignored on the exact path, and — as in R — ignored when there are ties, or
when the signed-rank test dropped a zero, because the series is derived for
untied ranks.

The result hash gains C<statistic_name> (C<"W"> or C<"V">, as R prints), plus
C<null_value> and C<null_value_name>, and C<estimate> / C<conf_int> / C<conf_level>
when an interval was asked for.

=head4 Three deliberate differences from R

Each is asserted in the test file, so that changing one later is a choice rather
than a drift.

=over

=item 1. B<< C<correct> is a boolean here. >> R 4.6.0 turned its C<correct> into an integer
C<0:3>, in which numeric C<0> still applies the continuity correction and only
C<FALSE> removes it — so in R, C<correct = 0> and C<correct = FALSE> are
different tests. Keeping that would mean C<< correct =E<gt> 0 >> no longer meaning
"off", which is what it means for every other flag in this module. C<correct>
stays a boolean, and R's C<correct = k> is C<< correct =E<gt> 1, edgeworth =E<gt> k >>.

=item 2. B<A zero variance is reported, not propagated.> With C<< exact =E<gt> 0 >> and every
observation tied there is nothing to divide by. R divides anyway and returns
C<NaN>; this warns and returns C<p = 1>. The default path no longer reaches it
at all, since the exact test handles all-tied data.

=item 3. B<An all-tied interval does not raise.> R's one-sample code warns and hands
back a C<NaN> interval at level C<0>; its two-sample code warns and then dies
inside C<uniroot> with I<missing value where TRUE/FALSE needed>. We give the
one-sample answer in both places.

=back

There is one place where this module is simply more accurate than R. R's exact
p-values on tied data come from a density it normalises entry by entry;
C<wilcox_test> sums the integer permutation counts and divides once. For the
worst case in the corpus — an 11-against-12 tied rank sum whose p-value is
exactly C<4/676039> — this returns the correctly rounded double and R is
C<1.2e-11> high. Checked against exact rational arithmetic, and recorded in the
test file rather than papered over.

=head4 Testing

C<t/wilcox_test.R.scipy.t> takes its cases from the references' own suites:

=over

=item * R's C<tests/reg-tests-1a.R> (the PR#1150 Hollander & Wolfe intervals),
C<reg-tests-1b.R> (the Wolfgang Huber C<wilcox.test(1, 2:60)> case, and the
check that the asymptotic estimate does not move with C<alternative>),
C<reg-tests-1d.R> (the six degenerate one-sample calls and the C<±Inf>
identities), and the man-page examples whose printed output is pinned in
C<tests/Examples/stats-Ex.Rout.save>.

=item * SciPy 1.17.1's C<TestMannWhitneyU>, whose header reads I<"All magic numbers are
from R wilcox.test"> — C<cases_basic>, C<cases_continuity>, C<cases_9184>,
C<cases_2118>, C<test_tie_correct>, C<test_exact_U_equals_mean>,
C<test_gh_11355b> and the 30-against-20 asymptotic cases — and
C<TestWilcoxon>'s C<test_accuracy_wilcoxon>, C<test_wilcoxon_tie>,
C<test_onesided>, C<test_exact_pval>, C<test_exact_p_1>, C<test_all_zeros_exact>
and C<test_symmetry_gh19872_gh20752>.

=item * A 663-case sweep generated by C<t/wilcox_test.R.scipy.R>, committed next to the
test, crossing four data shapes against every alternative, C<exact> state,
C<correct> state, C<mu> and C<conf.int> setting.

=back

Beyond the file, 960 further randomised calls were compared against R 4.6.1 and
agree everywhere except the three divergences above.

One lesson from getting that to pass on every NV width is worth recording: the
corpus data has to be B<exactly representable>. Whether two values tie decides
which branch runs, and C<1.6 - 2 - 0.5> does not land on the same value in a
C<double>, an x87 C<long double> and a C<__float128>. A corpus of one-decimal
values passed on the default perl and failed on C<perl-5.12.5> and quadmath with
a I<different statistic>, not merely a different last digit. Every generated
value is now a whole number of quarters or of 1024ths. For the same reason the
asymptotic interval, which is only ever pinned down to C<tol.root>, is generated
at C<tol.root = 1e-12> rather than freezing wherever Brent's method happened to
stop on one machine.

A compiler-warning audit of C<LikeR.xs> for C<-Wint-conversion>, C<-Wimplicit-int>,
C<-Wreturn-mismatch> and C<-Wdeclaration-missing-parameter-type>, and a pass
tightening integer types that can only hold a count or a flag. No behaviour
changed: the full suite (116 files, 18,546 tests) passes, and every function
touched was diffed call-for-call against a build of the previous release, with
C<dnorm>, C<pnorm>, one- and two-sample C<ks_test>, C<fisher_test>, C<auc> and the set
operations re-checked against R 4.6.1 and found bit-identical.

All four of those warnings were already clean, and stay clean on a C<double>, a
C<long double> and a C<__float128> build. Two of them cannot be tested with the
GCC most systems still default to: C<-Wreturn-mismatch> and
C<-Wdeclaration-missing-parameter-type> are GCC 14 additions — where they are
errors rather than warnings — and GCC 13 rejects both as unrecognized options,
so a check that appears to pass on 13 has really only skipped them.

=head3 Dead code removed

Turning the audit up to C<-Wextra> found two branches that could never run, both
of them a test for negativity on a value whose type is unsigned:

=over

=item 1. C<r_pow_di> takes C<unsigned int n>, so its C<< if (n E<lt> 0) return 1.0 / r_pow_di(x, -n); >>
was unreachable — a leftover of R's C<R_pow_di>, which takes a signed exponent.
All three callers (in C<K2x>, for the exact one-sample Kolmogorov-Smirnov
distribution) pass a non-negative exponent, so the unsigned parameter is the
correct one and the reciprocal branch simply goes.

=item 2. C<hoa2aoh> casts C<HvUSEDKEYS> to C<U32> and then clamps with C<< if (ncols E<lt> 0) ncols = 0; >>.

=back

=head3 Types narrowed to what they can actually hold

Eighteen C<int>s that only ever hold 0 or 1 became C<bool>, a convention the file
already followed in some 219 other places; each was confirmed by reading every
call site rather than by name. The flag parameters of C<ft_pnhyper>, C<K2l>,
C<c_dnorm>, C<c_pnorm>, C<c_pnorm_both>, C<set_multiplicity> and C<roc_split>, the
C<is_cat> field of C<AnFac>, the C<lower_pos> and C<frac_low> locals of C<auc>,
C<auroc>, C<roc> and C<bedroc>, and the return types of C<mg_key> and
C<psmirnov_exact_test>. Several of these were already being handed a C<bool> by
their callers — C<dnorm>'s and C<pnorm>'s C<log> and C<lower> options, for instance —
so only the helper signatures were behind. C<c_pnorm_both>'s loop counter became
C<unsigned int>.

Two that look like flags and are not: C<c_pnorm_both>'s C<i_tail> is three-valued,
and C<set_multiplicity>'s C<gimme> carries a Perl C<G_*> context value. Both stay
C<int>.

Also six coefficient tables in C<c_pnorm_both> written C<const static double>,
which puts the storage class after the qualifier and draws
C<-Wold-style-declaration>; they are now C<static const double>.

=head3 runif argument validation, and every warning names its function

C<runif> accepts its arguments either positionally or by name, and decided which
was which by asking whether the current argument was a string I<and> whether
another argument followed it. A key at the end of the list therefore failed the
second half of that test and fell through to the positional branch, where it was
read as a number: C<runif(5, 'min')> took C<SvNV("min")>, which is 0, silently set
C<min = 0>, and returned five values. The only sign anything was wrong was perl's
own C<Argument "min" isn't numeric>, which does not say which function provoked
it. C<< runif(5, bogus =E<gt> 1) >> went the same way, taking C<bogus> as C<min> and C<1> as
C<max>. Every sibling that parses named arguments — C<rbinom>, C<binom_test>,
C<fisher_test>, C<dnorm>, C<pnorm> — rejects both of those.

C<runif> now does too. A string argument is treated as a key when it is not a
number, which is decidable from the key alone, so a dangling or misspelled key
is an error instead of a silent coercion; a numeric string is still positional,
so C<runif("9")> is unchanged. Named values are checked for numerichood before
use, which is what keeps perl's unattributed warning from being the diagnostic.

C<n> is also range-checked now. It was read straight through C<SvUV()>, so
C<runif(-1)> wrapped to 2**64-1, C<av_extend()> read that back as a negative
C<SSize_t>, and perl died with C<panic: av_extend_guts() negative count (-2)> --
which names neither the function nor the argument at fault. A negative or
over-large C<n> now croaks and says so. Non-integer C<n> still truncates toward
zero, as R's C<runif()> does, and C<runif(0)> still returns an empty list.

Separately, three warnings did not name the function emitting them, unlike every
other warning in the file: one in C<ks_test> (the 1-sided exact 1-sample case
falling back to asymptotic) and two in C<wilcox_test>'s signed-rank branch (exact
p-value abandoned for ties, and for zeroes). All three now carry the prefix
their siblings already had. The one warning left deliberately bare is the
C<warn("%s", m)> in the uninitialized-value catcher, which re-emits somebody
else's warning verbatim and must not add to it.

=head3 Argument-stack indices are now Stack_off_t

C<-Wextra> reported 58 C<-Wsign-compare> warnings, and 33 of them were one idiom:
an index declared C<size_t>, C<unsigned>, C<unsigned int> or C<unsigned short int>
and then compared against C<items>. C<items> is neither of those — XSUB.h's
C<dITEMS> declares it C<Stack_off_t items = (Stack_off_t)(SP - MARK)>, a I<signed>
type, because it is a stack-pointer difference. Every one of those comparisons
was converting the signed side to unsigned.

The indices are now C<Stack_off_t> themselves, which is the type they are
compared against: 25 declarations across 23 functions — C<binom_test>,
C<ks_test>, C<wilcox_test>, C<write_table>, C<max>, C<runif>, C<quantile>, C<mean>,
C<mode>, C<sum>, C<sd>, C<uniq>, C<var>, C<t_test>, C<median>, C<matrix>, C<fisher_test>,
C<power_t_test>, C<var_test>, C<dnorm>, C<value_counts>, C<prcomp> and C<pnorm>.
That is a retype, not a cast: writing
C<(size_t)items> at each comparison would silence the warning just as well, but
it would be wrong the day C<Stack_off_t> widens, which is exactly what it exists
to allow. C<t_test>'s index was C<unsigned short int>, which drew no warning at
all — integer promotion made the comparison signed — and was the same latent
mistake regardless.

C<Stack_off_t> arrived in perl 5.39.2 and this distribution supports 5.010, so
the preamble now carries a shim typedef guarded on C<PERL_STACK_OFFSET_DEFINED>,
the macro perl.h defines next to the typedef. On 5.10.1 and 5.12.5 neither the
macro nor the type exists and the shim supplies C<I32>, which is what the stack
offset was on every perl before that.

The 33 warnings are gone, 25 remain, and no warning category increased —
verified by compiling the before and after trees and diffing the warning sets.
The remaining 25 are unrelated signedness pairs (C<size_t> against C<ssize_t>,
C<IV> against C<size_t>, C<STRLEN> against C<ssize_t>) and are left alone. The full
suite passes on perl 5.10.1 and 5.12.5, the two builds that depend on the shim,
as well as on 5.42.3, 5.44.0 and 5.44.0-quadmath; and 94 calls covering all 23
retyped functions — positional and named forms, bare lists against arrayrefs,
C<write_table>'s emitted bytes, and the odd-argument and unknown-argument croaks
that this index arithmetic drives — produce identical output before and after.

=head3 NV was being computed at double precision on wide builds

Every libm call in C<LikeR.xs> was written bare — C<sqrt(x)>, C<log(x)>,
C<lgamma(x)> — and C has no type-generic C<< E<lt>math.hE<gt> >>. Those functions take a
C<double>, so on a perl built with C<-Duselongdouble> or C<-Dusequadmath> every one
of them converted the C<NV> down to 53 bits of mantissa, computed there, and
converted the result back. Nothing warned and nothing failed to compile; the
answers were simply less accurate than the perl running them. On perl-5.12.5
(C<long double>), C<sd(1..5)> returned exactly the double-rounded C<sqrt(2.5)>,
9.5e-17 away from the value perl's own C<sqrt> gives.

All 412 of those calls now go through C<nv_*> macros that paste on the suffix for
the width C<NV> actually is: none for C<double>, C<l> for C<long double>, C<q> for
C<__float128>. The 80 C<isnan>/C<isinf>/C<isfinite> calls became
C<Perl_isnan>/C<Perl_isinf>/C<Perl_isfinite>, which matters most where the C99
type-generic macros are absent: there C<isfinite()> is a plain C<double> function,
and narrowing a large-but-finite long double into it reports the value as
infinite rather than merely rounding it.

The long-double row is conditional. The C<l> variants are C99 but some libms —
the thinner BSD ones especially — do not ship the whole set, so C<Makefile.PL>
link-tests all twenty as a unit and defines C<LIKER_HAVE_LONG_DOUBLE_MATH> only
if every one resolves; otherwise the build falls back to the C<double> functions,
which is exactly what it did before and so cannot regress. C<__float128> needs no
probe: C<< E<lt>quadmath.hE<gt> >> and C<-lquadmath> come with the quadmath perl itself, and
the built object was checked with C<nm> — it references C<lgammaq>, C<expq>,
C<sqrtq> and no double-width libm symbol at all.

Accuracy on the long-double build, measured against values that are exact in
binary or known in closed form: C<sd(1..5)> is now bit-identical to perl's
C<sqrt(2.5)>, and C<fisher_test([[3,1],[1,3]])> moves from 1.5e-16 to 6.4e-18
relative error against the exact 17/35. The remaining 6.4e-18 is an accuracy
floor in that function's own summation, not a width problem — the C<__float128>
build lands on the same figure.

This costs time where the wide math is software-emulated: the suite takes 352s
on the quadmath perl, against 67s when it was quietly running on hardware
doubles. The other four perls are unaffected.

=head3 The build ran itself twice, and clobbered its own Makefile doing it

C<make> had to be run twice or the C<.so> came out stamped with the wrong version
and refused to load. The cause: ExtUtils::MakeMaker scans the directory for
C<*.PL> files to run during the build, and C<dev.Makefile.PL> — a local
convenience wrapper, not part of the distribution — looks like one. It was being
run mid-build as C<perl dev.Makefile.PL dev.Makefile>, and since it calls
C<WriteMakefile()> it overwrote the real C<Makefile> with its own: no C<DEFINE>, no
probed C99 flag, and a different C<VERSION>. The second C<make> then rebuilt from
that. C<< PL_FILES =E<gt> {} >> turns the scan off; nothing here is generated by a C<.PL>
file.

The version half was a stale literal: the checked-in C<Makefile.PL> pinned
C<< VERSION =E<gt> "0.28" >> while C<lib/Stats/LikeR.pm> had moved to 0.298, and
C<XSLoader::load()> passes C<$VERSION> to a C<.so> compiled with C<-DXS_VERSION>
from that literal. It now reads C<< VERSION_FROM =E<gt> lib/Stats/LikeR.pm >>. One C<make>
after C<perl Makefile.PL> is enough again, and the non-quadmath builds are about
a third faster for not doing the work twice.

=head3 Portability: Solaris, the BSDs, and vendor compilers

The C99 flag is now probed instead of guessed. C<Makefile.PL> was selecting
C<-std=gnu99> on any compiler whose name matched C</\b(?:g?cc|clang)\b/>, and
C<$Config{cc}> is plain C<cc> for Oracle Studio on Solaris and for aCC on HP-UX —
both of which reject that flag outright, so the build failed there before it
compiled a line. Each candidate is now trial-compiled and the first that works
wins: C<-std=gnu99>/C<-std=c99> for gcc and clang, C<-xc99=all> for Studio,
C<-qlanglvl=extc99> for AIX C<xlc>, C<-AC99> for HP-UX, and nothing at all for a
compiler already in C99 mode. MSVC is skipped outright, since it warns rather
than errors on switches it does not know and would make the probe settle on a
no-op.

Two things that would have failed to compile off Linux are gone. C<< E<lt>strings.hE<gt> >>
and its C<strcasecmp> — POSIX-only, absent on MSVC — are replaced by a small
C<str_ieq_ascii()>, which also drops the locale dependency: C<tolower()> under a
Turkish locale maps C<I> outside ASCII, which should never decide whether
C<"TRUE"> matches C<"true">. And bare C99 C<restrict>, used on 151 pointers here,
now has an C<#ifdef> mapping it to C<__restrict> on MSVC and C<__restrict__> on
older gcc, and defining it away where no spelling exists, rather than losing the
annotation.

C<LikeR.xs> also compiles clean under strict C<-std=c99> with no GNU extensions,
which is the closest available local proxy for a vendor compiler.

=head3 Dead code: sample()'s private PRNG

A splitmix64 generator sat at the top of the file under a comment promising a
PRNG stream separate from C<Drand01()>, seeded lazily from C</dev/urandom> with a
C<time()^PID> fallback. None of it was true: no seeding code was ever written, no
caller ever existed, and its state started at a fixed 0, so had anything called
it the "random" sample would have been the same sequence in every process.
C<sample()> draws from C<Drand01()> and always did, which is the behaviour that is
wanted — C<srand($seed)> governs it the way C<set.seed()> governs R. The generator
and its comment are removed.

=head3 Tests

Two files, 273 assertions, and both were checked against a deliberately broken
build rather than merely observed to pass.

C<t/nv_width.t> fails if the math width ever comes undone. Its sharp assertion
needs no tolerance at all: C<sd(1..5)> must be the identical NV to perl's
C<sqrt(2.5)>, which holds on any width and breaks the moment a C<double> gets in
the way. It is width-adaptive rather than skipped on a C<double> perl, computing
the NV epsilon of the running build instead of assuming one.

C<t/scale.keywords.t> covers C<scale()>'s string options — C<"mean">, C<"sd">,
C<"none">, C<"true">, C<"false">, C<""> and their case variants — which had no
coverage at all: C<t/01.t> passes only the numeric forms. Expected values come
from R 4.6.1 C<base::scale()> at C<options(digits=17)> and are frozen in the file,
so it needs no R at run time. Deleting the case fold from C<str_ieq_ascii()>
fails 11 of its assertions; usefully, all 11 are the "off" spellings, because an
unmatched string falls through to C<SvTRUE> and still means "compute it", so
C<"MEAN"> would keep working while C<"NONE"> flipped. That is recorded in the file
so the section is not trusted for more than it proves.

The suite is 118 files and 18,819 tests, passing on perl 5.10.1, 5.12.5, 5.42.3
(threaded), 5.44.0 and 5.44.0-quadmath, with no compiler warnings on any of
them.

=head2 0.297 2026-08-10 CDT

https://www.cpantesters.org/cpan/report/260534ea-9474-11f1-8ca2-bfb68deea6df bug fix

=head2 0.296 2026-08-09 CDT

fixed CPAN bug: https://www.cpantesters.org/cpan/report/fcf32c68-75a5-1014-bc87-8fe0d10910fe

write_table.announce.t ran its child perl through -e, which cannot carry double quotes or shell metacharacters on Windows; the child program now goes in a file

chisq_test now matches R 4.6.1 bit-for-bit on the statistic across 170 randomized cross-check cases, and the full suite (116 files, 18,546 tests) passes.

Bugs found and fixed in LikeR.xs

=over

=item 1. A 1×k or k×1 table returned df = 0, p = 1 — no test at all. R collapses a single-row/column matrix to a vector and runs goodness-of-fit (if (min(dim(x)) == 1L) x <- as.vector(x)); now so does this. [[10,20,30]] went from X²=0, df=0, p=1 to X²=10, df=2, p=0.006738.

=item 2. Yates' label was attached even when the correction was zero. R only says "with Yates' continuity correction" when min(0.5, |O−E|) > 0. A table sitting exactly on its expectation, and every zero-margin table, were mislabelled.

=item 3. Yates was computed per cell instead of as R's single whole-table min(0.5, abs(x-E)) — equal in theory on a 2×2, not always in the last bits.

=item 4. No input validation. Negatives, infinities, NaN, strings and undef were silently coerced to 0 and produced garbage or NaN; all-zero data returned NaN; a single element returned df = 0. All now croak with R's wording. Ragged array rows and 2D hash rows with mismatched column keys were silently zero-filled — now fatal.

=item 5. Uniform expectation used n/k instead of R's n * (1/k), and sums were accumulated in a plain NV where R uses a long double. Together these put the statistic 1–2 ulp off R on most inputs; both fixed (ct_acc_t).

=item 6. Hash input was read in Perl's randomized key order, so which row a malformed hash got blamed on was a coin toss. Rows and columns are now sorted, as fisher_test already does.

=item 7. Segfault on sparse arrays (av_fetch returns NULL for a hole) — this one I introduced during the rewrite and caught before finishing; guarded by ct_av_get

=back

Three of those cross-checks compared the statistic to R's printed value relatively, and on the tables in question R's value is not a statistic. Where a 2×2 has all four |O−E| equal, Yates' min(0.5, |O−E|) cancels every corrected residual, so the exact statistic is 0 and the exact p is 1; what R prints there — 1.4515367733818938e-24 for [[1573,3],[4,0]], 2.9347503914472165e-32 for [[1,2],[3,4]], 7.1842689582627857e-32 for [[1.5,2.5],[3.5,4.5]] — is the leftover of forming E in floating point, the four |O−E| differing in their last bits so that the minimum comes out a hair below the rest. Its size is a property of the NV rather than of the test: a double build reproduces R's digits, and a __float128 build cancels the whole way to 0. Comparing that relatively can only pass on the width R happened to use, and it failed with rel diff = 1 on the quadmath perl and on 5.12.5. Those three cases in t/chisq_test.R.scipy.t now check the statistic against 0 and the p-value against 1 with absolute tolerances of 1e-20 and 1e-11, R's numbers staying in the file as provenance. LikeR.xs is unchanged — the wide-NV answer was the more accurate one. The suite passes on perl 5.10.1, 5.12.5, 5.42.3-thr, 5.44.0 and 5.44.0-quadmath.

=head2 0.295 2026-08-08 CDT

bug fix https://www.cpantesters.org/cpan/report/0f13fed6-92f5-11f1-b043-dc326e8775ea

Removed C<restrict> where it made no difference, or was potentially dangerous

=head3 drop_duplicates, merge, value_counts

These three decide what counts as the same row, the same join key, or the same
value by a cell's Perl stringification, and on numeric columns that one
conversion was most of the work they did.

C<sv_2pv_flags()> renders an NV with C<snprintf("%.*g", NV_DIG, x)>, about 140 ns
a cell, and — unlike the IV case, where C<SvPOK_or_cached_IV> lets the C<SvPV>
macros hand back the string perl cached on the SV — it never reuses that PV, so
every pass over a column of doubles paid the conversion again. It does leave the
buffer behind, which is why keying a frame used to grow the caller's own numeric
columns by about 64 bytes a cell, permanently: reading a frame ought to be a
read.

C<nk_num_pv()> now renders bare integers and bare doubles into the caller's own
scratch buffer instead, and leaves the SV untouched. Its double path is C<%.15g>
about four times faster than the C library's, and taken only where the answer is
provably the same: the magnitude is scaled into C<[1e14, 1e15)> in C<long double> —
64 mantissa bits against the double's 53 — which bounds the scaled value's error
under 2e-4, so a fractional part further than 2e-3 from one half rounds exactly
as the true value would. About one cell in 300 lands nearer than that and goes
back through C<SvPV>, as do zero, the non-finite values, C<use locale>, an x87
control word left at double precision, and any build whose NV is not an IEEE
double. It agreed with the C library's own C<%.15g> over 90 million random bit
patterns; C<t/drop_duplicates.t>, C<t/merge.t> and C<t/value_counts.t> now group
tens of thousands of doubles both ways and require the two answers to match.

Two further changes in C<drop_duplicates> alone:

=over

=item * Its interning table started at 64 slots and doubled, so a pass over 10,000
distinct rows rehashed nine times, each one a scattered walk over a table too
big for L2. The row count is known before the pass starts and bounds the group
count, so it is now used as the hint — capped, so a large frame of few distinct
rows does not pay for a slot per row.

=item * An HoA result copied every surviving cell, while AoA and AoH already shared the
whole surviving row. It now shares the cells too. B<This is a behaviour
change.> The frame, and an HoA's column arrays, are still new, so they can be
reshaped without touching the input; but assigning I<through> a survivor —
C<< $out-E<gt>{col}[0] = ... >> — now writes to the input's cell, exactly as
C<< $out-E<gt>[0]{col} = ... >> always did for AoA and AoH. Clone the result if you need
full independence.

=back

Measured on the 10,000-row frame C<benchmark.pl> uses (five columns: two doubles,
one integer, two strings), on one machine, with only these paths toggled. Time is
the median of 25 calls in one process; RAM is C<benchmark.pl>'s own figure, the
C<VmRSS> delta of a forked child running the call once, median of nine. The string
row is there to show where the win is not: it is confined to numeric cells.

=for html <table>
<thead>
<tr>
  <th>Call</th>
  <th>Time before</th>
  <th>Time after</th>
  <th>RAM before</th>
  <th>RAM after</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>drop_duplicates($hoa)</code></td>
  <td>5.45 ms</td>
  <td>1.88 ms (2.9x)</td>
  <td>5.36 MB</td>
  <td>1.45 MB (3.7x)</td>
</tr>
<tr>
  <td><code>merge</code>, inner join on an integer key</td>
  <td>7.78 ms</td>
  <td>5.62 ms (1.4x)</td>
  <td>7.41 MB</td>
  <td>6.41 MB (1.2x)</td>
</tr>
<tr>
  <td><code>merge</code>, inner join on a double key</td>
  <td>10.28 ms</td>
  <td>5.91 ms (1.7x)</td>
  <td>7.12 MB</td>
  <td>6.42 MB (1.1x)</td>
</tr>
<tr>
  <td><code>value_counts</code> on a double column</td>
  <td>2.98 ms</td>
  <td>1.66 ms (1.8x)</td>
  <td>1.98 MB</td>
  <td>1.55 MB (1.3x)</td>
</tr>
<tr>
  <td><code>value_counts</code> on a string column</td>
  <td>0.215 ms</td>
  <td>0.220 ms</td>
  <td>0.69 MB</td>
  <td>0.71 MB</td>
</tr>
</tbody>
</table>

C<group_by> and C<pivot_table> were left alone: C<group_by> hands the cell SV
straight to C<hv_fetch_ent>, so perl does the stringification internally and
reaching it means byte-level C<hv_*> calls and a change to how UTF-8 keys are
handled, and C<pivot_table> is pure Perl.

=head2 0.294 2026-08-07 CDT

bug fixes: https://www.cpantesters.org/cpan/report/368ca238-73ee-1014-a03f-97f1b88bf904

C<binom_test> was cross-validated against R 4.6.1 C<stats::binom.test> and SciPy
1.17.1 C<scipy.stats.binomtest> using their own test suites rather than cases
invented here: SciPy's C<TestBinomTest>, R's C<binom.test(c(800,10))> from
C<tests/reg-tests-2.R>, the C<?binom.test> example, and an R-generated corpus of
383 p-values and 1560 Clopper-Pearson bounds. They are in
C<t/binom_test.R.scipy.t>. Two fixes came out of it, both in the incomplete beta
that every tail and confidence bound goes through:

=over

=item * Its continued fraction stopped after a flat 500 terms, but it needs about
0.25 sqrt(a+b) of them once the shape parameters are large, so it was quietly
cut short at big C<n>: C<< binom_test(10079990, 21000000, p =E<gt> 0.48) >> returned
0.996781946606 where R and SciPy both give 0.9966892187965, i.e. wrong in the
fourth decimal of a printed p-value. The cap now scales with sqrt(a+b), and
the front factor moved off differenced C<lgamma> onto the same saddle-point
form C<dbinom> already used here. Agreement with R over these cases went from
9.3e-5 to 3.3e-13 relative.

=item * The Clopper-Pearson bounds are found by bisection, which stopped at an
absolute width of 1e-15, so a bound far below 1 came back with only four
correct digits: C<< binom\_test(1, 1000000000, alternative =E<gt> 'greater',
conf\_level =E<gt> 0.999) >> gave 1.00053299e-12 against R's 1.00050033e-12. The
stopping rule is now relative to where the bracket sits, and such bounds now
hold about 1e-15.

=back

Both fixes also help C<t_test>, C<var_test> and C<cor_test>, which use the same
function. One limit remains, pinned by the tests rather than left to chance: the
upper bound for a handful of successes in a billion trials still carries about
1e-9 of relative error, because the complement branch of the incomplete beta
cannot resolve a tiny C<x> past the spacing of C<1-x>.

=head2 0.293 2026-08-06 CDT

Fixed quadmath error https://www.cpantesters.org/cpan/report/83bcd9a2-9123-11f1-aac1-f3cd035a6881

C<fisher_test> was cross-validated against R 4.6.1 C<stats::fisher.test> and SciPy
1.17.1 C<scipy.stats.fisher_exact> using their own test suites rather than cases
invented here: SciPy's 84-case R-generated corpus
(C<scipy/stats/tests/data/fisher_exact_results_from_r.py>, four numbers per case
over two confidence levels and all three alternatives), its
C<TestFisherExact>, R's regression suite (C<tests/reg-tests-1{a,b,d,e}.R>:
PR#644, PR#1662, PR#4688, PR#10558, PR#18336, PR#17671 and the "exact
fisher.test" entry) and the C<?fisher.test> examples. They are in
C<t/fisher_test.R.scipy.t>. Three fixes came out of it:

=over

=item * The 2x2 hypergeometric density was built by differencing C<lgamma>, which
costs the back half of a large table's p-value: at a margin of 8.4e7,
C<lgamma> is about 1.4e9, where a double's spacing is 2.4e-7, and exponentiating
that turns into a relative error of the same size. SciPy's gh-3014 case came
out right to only seven digits. The density is now assembled from Loader's
saddle-point binomial, which is how R's own C<dhyper> avoids this and which
C<binom_test> already had in the file; its three terms stay O(1) whatever the
margins are. Worst-case agreement with R over the 84-case corpus went from
2.1e-12 to 5.2e-14 relative, and gh-3014 from 2.2e-07 to 1.5e-16.

=item * The R x C enumeration charged only its leaves against its safety cap, so a
table wide enough to spend the time in the interior of the tree neither
finished nor stopped: R's PR#4688 table (4x3, N = 16442), whose whole point
upstream is that C<fisher.test> must fail rather than return C<p = Inf>, ran for
over five minutes here without doing either. Every node is now counted, and
that table is declined in about a second.

=item * The R x C enumeration now bounds each subtree before walking it. C<lgamma(x+1)>
is convex and C<< a!b! E<lt>= (a+b)! >>, which together bracket the probability of every
completion of a partial table; when the whole subtree falls inside the tail its
mass is added in closed form (C<N'! / (prod R_i! prod C_j!)>, from counting the
remaining observations into rows two ways), and when it falls outside the
subtree is dropped. The margins are also transposed and sorted first, so the
fattest row and column are the ones the enumeration gets for free. R's Job
Satisfaction 4x4 example went from 7.5s to 0.3s and PR#644's 19x2 from 1.0s to
under 0.05s, and the 6x6 table of PR#18336 -- which segfaulted R before 4.2.0
and which R 4.6.1 still declines with C<< hash key 5e+09 E<gt> INT_MAX >> -- is now
computable at 0.6322160531, agreeing with R's own 2e6-replicate
C<simulate.p.value> fallback to within its sampling error.

=back

Two behaviours that the two references disagree about are now pinned by tests
rather than left to chance: a table with an empty row or column returns R's
C<p = 1> with an odds ratio of 0 and a CI of (0, Inf), not SciPy's NaN odds ratio;
and a table with a single row or column is rejected as R rejects it, rather than
returning SciPy's C<p = 1>.

=head2 0.292 2026-08-05 CDT

fixed long-double bug https://www.cpantesters.org/cpan/report/506975f6-906a-11f1-8f30-a201c4f2440e

C<power_t_test> was cross-validated against R 4.6.1 C<power.t.test> and against
C<scipy.stats.nct> driven by C<scipy.optimize.brentq>, over a grid of 288 cases
covering all five solved-for parameters, all three types, both alternatives and
C<strict>. Three fixes came out of it:

=over

=item * The Simpson sum behind the noncentral I<t> CDF put a fixed 30000-step grid on
C<u = w/(1+w)>, and the chi density it integrates defeats that at both ends.
The density carries C<w**(df-1)>, so unless C<df> is a whole number some
derivative of it is infinite at C<w = 0> and Simpson's error bound does not
hold: two good digits at C<df = 1.2> with C<sig_level = 1e-4>, five at
C<df = 1.2>, nine at C<df = 1.8>. Substituting C<w = z**m>, with C<m> chosen so
that C<< m*df - 1 E<gt>= 3 >>, restores the bounded derivatives and brings all of
those to machine precision. It also puts the origin's contribution at zero,
which subsumes a separate bug: the sum had been dropping its C<u = 0> endpoint
term, worth 7e-7 of absolute power at C<df == 1>. C<nu> is now also floored the
way R floors it, per sample rather than in total.

=item * The same density has standard deviation C<1/sqrt(2*df)> and so narrows without
bound, while the grid did not. Past C<df> of about 1e7 the steps went clean
over the peak: C<< power_t_test(n =E<gt> 4e7, delta =E<gt> 0) >> returned 0.138 where the
answer can only be C<sig_level/2>, and a large-cohort C<n> solved 9% low. Above
C<df> of 1e3 the steps now go on C<w> across +/- 12 standard deviations of the
mode, with the chi normalisation taken from Stirling's series to keep the peak
height from cancelling away; and above 4e5, where those log terms cancel too
hard for any grid to help, the Abramowitz & Stegun 26.7.10 asymptotic form
takes over -- the same formula, at the same cut-off, that R's C<pnt.c> uses.
That is also 25 times quicker than integrating.

=item * The power was formed as C<< 1 - P(T E<lt>= t) >>, which loses most of its digits to
cancellation when the power is small. It is now integrated as the upper tail
directly.

=item * The four inverse solvers were plain bisection stopped at the bracket width,
which capped C<n>, C<delta>, C<sd> and C<sig_level> at R's own four or five
significant figures. They now use regula falsi with the Illinois correction
against a relative tolerance, so they match machine-precision C<brentq> roots
to ~1e-13 in fewer evaluations than the bisection took. The C<tol> default
moved from C<1.22e-4> to C<1e-12> to match.

=item * Nothing checked that the bracket held a root, so an unreachable target came
back as a bracket endpoint wearing the requested power: solving for C<sd> with
C<< power =E<gt> 0.01 >> returned C<delta * 1e7>, and with a negative C<delta> returned a
negative standard deviation. Unreachable targets now croak and name the range
searched. C<sig_level> and C<power> outside C<[0, 1]>, an C<n> below 2, a negative
C<sd>, and an unrecognised C<type> or C<alternative> are rejected as well --
C<< type =E<gt> 'twosample' >> used to be read silently as C<'two.sample'>.

=back

New test file C<t/power_t_test.R.scipy.t> carries the cross-validated grid.

=head2 0.291 2026-08-04 CDT

POD formatting improvements

=head3 C<lm>, C<glm>

Formula parsing and data reading are now shared between C<lm> and C<glm> too, so the
two agree on what a formula means and on what a row is called. C<lm> had the better
parser and C<glm> the better row naming; each now has both.

B<< C<lm> now names rows the way C<glm> does >> — from a C<row.names>, C<_row>,
C<rownames> or C<.rownames> column when the data has one, and 1-based integers
otherwise. C<lm> previously always used integers, so C<fitted.values> and
C<residuals> came back keyed C<1..n> for data whose rows had names, and did not
match what C<glm> or C<predict> returned for the same data; the C<predict>
documentation already described the shared behaviour. A row-name column is a label
rather than a measurement, so C<y ~ .> now excludes it in both.

Design-matrix construction is now shared between C<lm> and C<glm>, and decides a
categorical column's coding term by term using R's margin rule: the reference
level is dropped when the term with that column removed is itself in the model.
Three bugs fall out of that, all confirmed against R 4.6.1 and statsmodels
0.14.6.

=head4 Bug fixes

Four in C<glm>, from the parser it now shares with C<lm>. Three of them ended the
same way: a term that names no column evaluates to C<NaN> for every row, every row
is dropped as incomplete, and the fit dies with C<< 0 degrees of freedom (too many
NAs or parameters E<gt> observations) >> — never mentioning the formula.

=over

=item * B<< C<glm> truncated a formula at 511 characters. >> It copied the formula into a
fixed C<char[512]>, so a model with enough predictors to overrun that lost the
tail. The buffer now grows with the formula.

=item * B<< C<glm> did not understand C<.>. >> It parsed the formula before reading the data,
so there were no column names to expand C<.> into and the term stayed a literal
C<.>. Formula splitting now happens first and term expansion after the data is
read, so C<y ~ .> works in both.

=item * B<< C<glm> did not understand C<+ 0> or a leading C<0 +>. >> Only C<- 1> suppressed the
intercept; the other two spellings R accepts left a term named C<0>. All three now
work in both, as do C<+ 1> and a leading C<1 +>.

=item * B<< C<glm> read the C<-1> inside C<I(...)> as intercept suppression. >> It searched the
whole right-hand side for the substring, so C<y ~ I(x-1)> silently became
C<y ~ I(x) - 1>: a different model, fitted without complaint. The scan now steps
over C<I(...)>, leaving the term alone. C<I()> still supports only C<^power>, so
that formula is an error in both rather than a wrong answer in one.

=back

And the three that fall out of the shared design matrix:

=over

=item * B<A categorical column in a model with no intercept lost a level.> With no
intercept there is no baseline for a reference level to be measured against, so
R codes the factor in full — one column per group, each coefficient that
group's own mean. Both functions dropped the reference level anyway, so
C<len ~ supp - 1> fitted C<len ~ suppVC - 1>: a model forcing every observation
at the reference level to a fitted value of 0. On R's C<ToothGrowth> that meant
a residual sum of squares of 16056 against R's 3247, and an R² of 0.35 against
0.87. Where two categorical main effects appear with no intercept only the
first is coded in full, as in R, since coding both would be rank deficient.

=item * B<An interaction involving a categorical column could not be built.> The
interaction was looked up as a single column literally named C<dose:supp>;
finding none, it evaluated to C<NaN> for every row, every row was dropped as
incomplete, and the fit died with C<< 0 degrees of freedom (too many NAs or
parameters E<gt> observations) >>. Interactions now expand to the product of their
components' indicator columns, so C<len ~ dose * supp> gives C<dose>, C<suppVC>
and C<dose:suppVC>. C<predict> already understood such coefficient names; now
they can be produced.

=item * B<< C<a*b*c> expanded only its first C<*>. >> Crossing is associative, so
C<y ~ a * b * c> now yields every non-empty subset (C<a>, C<b>, C<c>, C<a:b>, C<a:c>,
C<b:c>, C<a:b:c>), ordered by degree as R's C<terms()> orders them. Previously the
chunk was split once, producing the unusable terms C<b*c> and C<a:b*c>, and the
fit died the same way as above. Crossing more than 16 columns now croaks rather
than expanding to 2^n terms.

=item * B<< C<predict> scored reference-level rows as if the term were absent. >> It
registered factor dummies from C<levels[1..]> only, on the assumption that a
reference level never has a coefficient — true for a factor coded by contrasts,
but not for one coded in full. Every row at the reference level of a
no-intercept model therefore came back 0.

=item * B<< C<glm> halved its IRLS step whenever the deviance rose, costing iterations and
accuracy in the standard errors. >> R truncates a step only when the deviance
comes out non-finite; a deviance that merely increases is not divergence. The
standard IRLS start puts C<mu> at C<y + 0.1>, essentially on the data, so the
initial deviance is near zero and the first real step almost always raises it —
on the nine-point poisson fit in C<t/glm.t>, from 0.016 to 1.54. That was read as
divergence and the step was halved ten times over, turning R's four iterations
into seven.

The extra iterations reached the same coefficients, so the symptom appeared
only in the standard errors. They are built from the information matrix of the
I<penultimate> iterate — in R because C<summary.glm> inverts the QR that
C<glm.fit> kept from its last weighted least squares call, and here because the
IRLS sweep leaves that inverse in place — so stopping on a different iteration
than R means reporting a different matrix. Poisson standard errors were 5e-8 to
2e-5 away from R's while the coefficients agreed to twelve digits; they now
agree to about 1e-14. Binomial standard errors were up to 6e-7 out and now
agree to 2e-14, except on a near-separable fit, where the C<varmu> floor of
1e-10 (a guard against dividing by an underflowed variance) accounts for the
remaining difference — 1.9e-9 on C<am ~ wt * hp>, where three of 32 fitted
probabilities are within 1e-12 of 0 or 1 and R itself warns. Gaussian fits are
unaffected: their weights are all 1, so the matrix is C<X'X> either way.

The same condition had its C<isfinite> test on the accepting side, so a
genuinely divergent step producing a non-finite deviance was kept rather than
truncated. That is now the one case that does trigger halving.

=item * B<The negative-binomial theta alternation stopped early and started from the
wrong place.> C<MASS::glm.nb> does not simply maximise over theta; it alternates
between an IRLS fit at the current theta and a fresh ML estimate of theta at the
current fitted means, and which fit it lands on depends on the schedule. Four
details of that schedule were wrong here, and all four are now reproduced:

=over

=item * The alternation stopped on a relative test of the log-likelihood alone,
C<< |dll| E<lt> 1e-7 * (|ll| + 0.1) >>. C<glm.nb> requires
C<< (|dLm| / d1 + |dtheta|) E<lt> 1e-8 >> with C<d1 = sqrt(2 * max(1, df.residual))>
taken from its Poisson pass — theta itself has to have settled, not just the
log-likelihood. The old test was satisfied roughly 2e-5 of log-likelihood
early, which left theta 8e-7 out and dragged the coefficients 8e-6 with it.

=item * The first pass now runs as a genuine B<Poisson> fit, as C<glm.nb>'s does,
rather than a negative-binomial fit at a large stand-in theta. That pass
supplies both the first theta and the C<d1> above.

=item * Later passes are B<warm started> from the previous pass's means
(C<etastart = log(mu)>), so they converge to the fit C<glm.nb> reaches rather
than to the same optimum approached from a cold start.

=item * Theta is re-estimated at the means each pass B<started> from, not the ones it
produced: C<glm.nb> calls C<theta.ml(Y, mu)> and only then reassigns
C<< mu E<lt>- fit$fitted.values >>. C<theta.ml> itself now also uses MASS's own stopping
rule, an absolute Newton-step tolerance of C<.Machine$double.eps^0.25>.

=back

Across eighteen fits spanning dispersion from theta 0.41 to theta 69000, theta
now agrees with C<glm.nb> to 3.4e-9, coefficients to 5.8e-9, standard errors to
8.4e-10 and deviance to 1.3e-9 — previously 8e-7, 8e-6, 3e-6 and 6e-7. The one
exception is genuinely near-Poisson data, where theta is not identified at all
(its own standard error exceeds the estimate, and C<glm.nb>'s C<theta.ml> reports
"iteration limit reached"); theta there agrees only to about 4e-6 relative,
while the coefficients still agree to 1.6e-10.

A separate consequence: a negative-binomial fit with theta supplied was
starting from the Poisson C<mustart> of C<y + 0.1>, where R's
C<negative.binomial()$initialize> sets C<y + (y == 0)/6>. Different starting
values walk different iterates, and since the standard errors come from the
penultimate one, that showed as standard errors 6e-7 from R's while the
coefficients agreed to 1e-9. Such fits now match R to 2e-15.

Note on that comparison: standard errors for a negative-binomial fit hold the
dispersion at 1, which is what C<glm.nb> and C<summary.negbin> do. R's
C<summary.glm>, handed a C<negative.binomial> family directly, instead I<estimates>
the dispersion and prints standard errors scaled by its square root — 1.0839 on
one of the test data sets, so about 4% larger. Compare against
C<summary(fit, dispersion = 1)> to see the values this module reports.

=back

=head2 0.29 2026-08-03 CDT

=head3 t_test

C<t_test> was cross-checked against R's C<stats::t.test> and C<scipy.stats> case by
case, including the cases their own suites pin: R's regression tests
(C<reg-tests-1a.R>, "t.test with one group of size one") and scipy's
C<TestTTest_1samp>, C<TestTTest_ind.test_special_cases>, C<test_ttest_rel_ci_1d>,
C<test_1samp_ci_1d> and C<test_pvalue_ci>. On 2000 randomised comparisons against
R — all four modes, all three alternatives, random C<mu> and C<conf_level>, sample
sizes 2 to 40 and data scales spanning 1e-4 to 1e4 — the statistic and the
degrees of freedom agree to 2e-11 and the p-value to 3e-9, holding to eight
digits even where the p-value is subnormal (5e-310). What the comparison did
turn up was seven ways a call could come back wrong rather than loud, all of
them now fixed and covered by C<t/t_test.t>.

=over

=item * B<< C<undef> was coerced to 0 instead of being dropped. >> This is the one worth
re-running results over. C<t_test> did not filter missing values, so a column
with gaps in it was tested with every gap counted as a zero: R gives
C<t.test(c(1,2,NA,4,5))> a C<t> of 3.286 on 3 degrees of freedom, and C<t_test>
answered 2.588 on 4. No error, no warning, and an answer close enough to the
real one to look right. C<undef> and C<NaN> are now dropped the way R drops C<NA>,
per-vector for a one-sample or unpaired test, and on complete cases when
C<paired> so a half-missing pair goes whole rather than contributing a
difference against zero.

=item * B<< A C<y> of fewer than two observations returned a silent C<NaN>. >> C<var_y>
divided by C<ny - 1>, so C<t_test(\@x, [$one_value])> propagated C<0/0> into the
statistic, the p-value and both interval bounds without raising. The two
thresholds R uses are now both in place: a Welch test needs a variance from
each side and refuses without one, while a pooled test tolerates a side of one
observation, since that side contributes no sum of squares. That second case is
what R's own regression suite pins — C<t.test(y=x[1], x=x[-1], var.equal=TRUE)>
is a well-defined test with 8 degrees of freedom, and C<t_test> now answers it
instead of returning C<NaN> in one direction and croaking in the other. An empty
C<y> is caught by the same check.

=item * B<< C<alternative> was never validated. >> The p-value helper fell through to
two-sided for any string it did not recognise, so a typo — C<'gerater'> — ran a
different test than the caller asked for and reported nothing. It is now
checked the way R's C<match.arg> checks it. C<scipy>'s C<"two-sided"> spelling is
unambiguous, so it is accepted rather than rejected.

=item * B<< A one-sided interval was wrong when C<< conf_level E<lt> 0.5 >>. >> That case needs a
negative t quantile, and C<qt_tail> searched upward from zero only, so it
returned roughly zero and collapsed the bound onto C<mu>: R puts the upper bound
of C<t.test(1:10, mu=5, conf.level=0.3, alternative="less")> at 4.9797 where
C<t_test> reported 5.0000000036. C<qt_tail> now reduces by symmetry first, so the
root it brackets is always positive.

=item * B<< C<qt_tail> silently saturated at 1e6. >> Past that its doubling loop gave up
and returned the ceiling, so C<conf_level> of 0.99999999 and 0.9999999999 came
back with the I<identical> interval, ±1048576, against R's ±6.4e7 and ±6.4e9.
The ceiling is gone; the loop now runs until C<t * t> would overflow.

=item * B<Interval accuracy no longer depends on the data's scale.> C<qt_tail>
bisected to an absolute 1e-8 on the quantile, which is 1e-8 × C<std_err> on the
interval — fine for data around 1, an error of 2 units for data around 1e9. It
now bisects to adjacent doubles. Worst interval error across the 2000
randomised cases went from 2.1e-4 to 5.3e-11 relative. At extreme
C<conf_level> this makes C<t_test> the more accurate of the two: C<t.test> asks
for C<qt(1 - alpha/2, df)>, and representing a 5e-9 tail as the double
C<1 - 5e-9> costs eight significant figures of it, so R's own interval for
C<conf.level=0.99999999> is off by 0.7 in the eighth digit. Working in the upper
tail throughout agrees with R's C<qt(alpha/2, df, lower.tail=FALSE)> to 15
digits.

=item * B<"Essentially constant" was an absolute test.> Only an exactly-zero variance
was rejected, so a spread below what a double can resolve at the data's own
magnitude was reported as a finding: four values around 1e10 differing by 1e-5
gave C<t> = 4e15 and a p-value of 3e-47. The comparison is now relative, as R's
is. The exactly-zero case, where R returns C<NaN>, raises here instead.

=item * B<< A defined non-array C<y> was ignored. >> C<< t_test(\@x, y =E<gt> 5) >> quietly ran a
one-sample test. It now raises. An explicit C<undef> still means absent, as R's
C<y = NULL> does.

=back

C<qt_tail> is shared with C<power_t_test>, which gains the same precision; it is
only ever called there with a tail below 0.5, so nothing about its behaviour
changes. C<t_test> remains allocation-free — the missing-value filtering happens
inside the same single Welford pass that was already there, and the result hash
is built after the last error check rather than before the first.

=head3 write_table: C<tex.longtable.head>

A C<longtable> freezes only the header sitting inside C<\endfirsthead> /
C<\endhead>, and C<tex.longtable> never wrote those blocks — its header was an
ordinary first body row, leaving the frozen one to be hand-written by the
caller. That header then had no link to C<col.names>: reorder the columns and
the labels at the top of every page keep the old order while the data below
them moves, and the generated header appears again as a duplicate first row.

C<tex.longtable.head> generates the repeat machinery from the table's own header
record, so it cannot drift. A true-but-numeric value emits
C<\endfirsthead>/C<\endhead>/C<\endfoot> with no continuation caption; any other
true value is the caption used on pages after the first, written verbatim.
Implies C<tex.longtable>. C<tex.longtable> on its own is unchanged.

The wrapper keeps one static token, the C<\hline> closing its C<\caption> line,
because a leading C<\hline> in an C<\input>ed file is a C<Misplaced \noalign>
error — TeX has already begun the row by the time it expands the C<\input>.

=head3 skew, kurtosis

Two new XS functions describing the shape of a sample beyond its spread:
C<skew> for the third central moment and C<kurtosis> for the fourth. Both take
arguments the way C<sd> and C<var> do — numbers, array references or a mixture,
flattened into one sample — and both also accept C<< x =E<gt> \@data >> and
C<< type =E<gt> 1|2|3 >>.

C<type> selects among the three sample conventions, which disagree noticeably on
small samples. The default is C<< type =E<gt> 2 >>: C<G1> and C<G2>, the estimators
unbiased for a normal sample, as reported by SAS, SPSS, Stata, Excel's C<SKEW()>
and C<KURT()>, and C<scipy.stats> with C<< bias =E<gt> FALSE >>. C<< type =E<gt> 1 >> is the plain
moment ratio (C<moments::skewness>) and C<< type =E<gt> 3 >> is C<b1>/C<b2>
(C<e1071::skewness>'s own default). All three, for both functions, agree with R
to about 1e-15. C<kurtosis> returns I<excess> kurtosis — 3 is already subtracted,
so a normal sample sits near 0.

=over

=item * One pass, no allocation: the third and fourth central moments accumulate
through Welford's recurrence extended to higher moments (Terriberry) rather
than the textbook expansion in raw moments. That expansion is not usable on
real data — for a column of values around 1e7, a lab value in the wrong units
or a timestamp, C<sum(x**3)/n> is about 1e21 while the third central moment is
single digits, so every significant figure cancels away.

=item * A constant sample croaks rather than returning a silent C<NaN> from C<0/0>, and
a C<type> whose denominator the sample is too small for (C<< type =E<gt> 2 >> needs
C<< n E<gt>= 3 >> for C<skew> and C<< n E<gt>= 4 >> for C<kurtosis>) says which.

=item * Both read tied arrays. C<av_fetch> on a tied array returns a deferred C<PVLV>
rather than the value, and C<SvOK> on one of those is false until its
get-magic has run, so without an C<SvGETMAGIC> every element of a tied array
looks undefined.

=back

=head3 median

C<median> now reads tied arrays too. It already had a separate C<av_fetch> path
for them — a tied array keeps nothing in C<AvARRAY>, so the fast path would read
off a null pointer — but that path was missing the C<SvGETMAGIC> described
above, so it rejected every tied array as undefined instead of computing the
answer. C<mean>, C<sd>, C<var>, C<sum>, C<min> and C<max> still reject tied arrays.
They have no C<AvARRAY> fast path to guard, so they croak rather than crash, and
the same one-line fix would make each of them work.

=head3 oneway_test

C<oneway_test> was cross-checked case by case against R's C<stats::oneway.test>
(both branches), R's C<anova(aov())> for the C<Sum Sq> / C<Mean Sq> columns,
C<statsmodels.stats.oneway.anova_oneway(use_var="unequal")> and
C<scipy.stats.f_oneway>. The 37 data sets are R's own built-ins — C<chickwts>,
C<InsectSprays>, C<PlantGrowth>, C<iris>, C<ToothGrowth>, C<mtcars>, C<warpbreaks>,
C<sleep>, C<airquality>, C<CO2>, C<esoph>, C<OrchardSprays>, C<faithful>, C<quakes> —
plus hand-built numerical edge cases. The statistic and both degrees of freedom
already matched R everywhere; what the comparison turned up was four ways a call
could come back wrong rather than loud, all now fixed and covered by
C<t/oneway_test.R.scipy.t>. Statistic, degrees of freedom and p-value now agree
with R to 1.3e-12 relative error across all 37, and on 2000 randomised
comparisons against R — both branches, 2 to 8 groups, sizes 2 to 40,
deliberately heteroscedastic, data scales 1e-4 to 1e4 — the statistic and the
degrees of freedom agree to 1e-12 and the p-value to 8e-11, the worst of those
being a p-value of 2.4e-66.

=over

=item * B<Every p-value below about 1e-16 was returned as a flat 0.> C<< Pr(E<gt>F) >> was
built as C<1 - pf(F, df1, df2)>, and 1 minus something that close to 1 has no
bits left to carry the answer: C<faithful> split at C<< waiting E<gt> 70 >> should give
C<1.2099104551915e-76> under Welch and C<5.50783574504386e-103> pooled, and
C<oneway_test> reported C<0> for both. Anything from about 1e-9 downward was
losing relative precision the same way, quietly — C<ToothGrowth> by dose came
back as C<9.99200722162641e-16> against R's C<9.53272701169993e-16>, off by 4.6%
with nothing to indicate it. The p-value is now evaluated in the upper tail
directly, via the beta symmetry C<1 - I_x(a, b) = I_{1-x}(b, a)>, so no
subtraction from 1 happens at any point, and the range down to the smallest
representable double is reported at full precision.

=item * B<< An C<F> of C<Inf> produced a p-value of C<NaN> instead of 0. >> When every group
is constant but their means differ, the within-group sum of squares is 0 and
C<F> is legitimately infinite; R reports C<p = 0>. C<pf> formed
C<df1*f/(df1*f + df2)>, which is C<Inf/Inf> — a C<NaN> that propagated straight
into C<< Pr(E<gt>F) >>. C<Inf> and C<NaN> are now handled explicitly, matching R's
C<p = 0> and C<p = NaN> respectively.

=item * B<< A C<NaN> Welch denominator df was reported as 1e300. >> A group with zero
variance gets an infinite Welch weight, which makes R's C<tmp> term C<NaN> and
its denominator df C<NaN> with it. C<oneway_test> had a C<< (tmp E<gt> 0.0) >> guard that
a C<NaN> fails, so it substituted a magic C<1e300> — a number that reads as a
real, very large degrees of freedom and would be believed as one. The guard is
gone; C<Residuals>/C<Df> and C<Residuals>/C<Mean Sq> are C<NaN> there, as in R.

=item * B<< C<formula> mode read C<undef> and non-numeric response cells as 0.0. >> The
hash and array-of-arrays shapes were already fixed to die on these (and pinned
by C<t/oneway_test.bugs.t>), but the formula path has its own fill loop and was
missed, so

=back

 oneway_test({ y => [1, 2, 3, undef, 5, 6], lab => [qw(a a a b b b)] },
     formula => 'y ~ lab');

  silently tested group C<b> as C<(0, 5, 6)> — a mean of 3.67 instead of 5.5 — and
  returned an C<F> of 0.735 with no complaint. All three input shapes now enforce
  the documented contract identically.

Two places where C<oneway_test> is the more accurate side and the reference is
not, now documented rather than treated as disagreements: the sums of squares
are accumulated two-pass, so on two groups near 1e8 C<Residuals>/C<Sum Sq> is
exactly C<10> where R's QR-based C<anova(aov())> gives C<10.0000000521067>; and
where the exact between-group sum of squares is 0, C<oneway_test> returns 0
rather than R's 1e-30-scale residue.

=head2 0.281 2026-08-03 CDT

C<median> (LikeR.xs) — the same answers in about an eighth of the time. On the
C<benchmark.pl> case (10,000 normals in one array ref) a call went from 0.83 ms
to 0.097 ms, which puts it ahead of the two implementations it was behind:
C<numpy.median> at 0.105 ms and R's C<median> at 0.196 ms, measured on the same
machine. Small samples — a per-group median under C<agg> or C<group_by>, which is
where most calls to it come from — went from 647 ns to 251 ns.

A median is the middle one or two values, so most of the sort the function used
to do was wasted work: C<qsort> orders all n elements at a cost of n log n
comparisons, every one an indirect call through a function pointer the compiler
cannot see into, to answer a question that depends on one or two of them. Those
values are now selected instead, and the sample is walked once rather than
twice.

=over

=item * The selection is introselect, the same shape numpy's C<partition> uses:
quickselect with a median-of-three pivot, an insertion sort once a range is
small, and a heapsort fallback past a depth limit, so an input crafted to
defeat the pivot choice degrades to O(n log n) rather than O(n²). The awkward
data people actually have comes out faster than random data rather than
slower — sorted, reversed, all-equal and organ-pipe samples of 100,000 values
each take about 0.25 ms against 0.90 ms for random ones. For an even count the
lower of the middle pair is the largest value left below the upper one, which
a scan of that side finds without a second selection.

=item * The counting pass is gone. It walked every element through C<av_fetch> before
any arithmetic, only to size the buffer; the array lengths give the same
count, exactly, because an undef anywhere still dies.

=item * The pass that remains reads cells through C<AvARRAY> instead of C<av_fetch>,
with tied arrays kept on the C<av_fetch> path, since only it sees their values.

=item * A sample of 256 values or fewer is copied to the C stack rather than the heap,
so the common small call no longer pays for a malloc and free at all: 10,000
of them now grow RSS by nothing. Larger samples still copy n values, which is
what leaves the caller's array in its original order — the selection reorders
whatever it works on, and C<t/median.t> checks that the input comes back
untouched.

=back

Error messages that carry an index or a count were unreadable on older perls,
in nineteen places across LikeR.xs, and now are not. C<croak> runs perl's own
formatter rather than the C library's, and that formatter does not understand
C99's C<z> length modifier: it printed the conversion literally, so
C<median(1, undef)> on perl 5.10 or 5.12 said C<undefined value at argument index
%zu> instead of naming the argument that was undefined — the one thing the
message existed to say. C<min>, C<max>, C<mode>, C<sum>, C<sd>, C<var>, C<median>,
C<mcnemar_test>, C<friedman_test>, C<hoa2hoh> and C<oneway_test> were all affected.
They now use C<UVuf>, as the rest of the file already did. The C<snprintf> calls
elsewhere in the file are unaffected and unchanged: those do go to the C
library, where C<%zu> means what it says.

New C<t/croak.messages.t> covers every one of those messages: each is triggered,
checked for the number it should name, and then swept for any conversion left
unexpanded, which is what will catch the next one written with C<%zu>. Run
against the code as it stood before this change, thirty-two of its assertions
fail on perl 5.10.

New C<t/median.t>: every length from 1 to 25 and from 254 to 258 — either side of
the insertion-sort cutoff and of the point where the buffer moves off the stack
— across sorted, reversed, all-equal, two-valued, duplicate-heavy, organ-pipe
and median-of-three-killer samples, each checked against a plain Perl sort,
together with the error messages and C<Test::LeakTrace> over the stack, heap,
mixed-argument and croak paths.

fix for threaded Perls https://www.cpantesters.org/cpan/report/2dbacf8f-7138-1014-a1ab-f0f91cf3b922

=head2 0.28 2026-08-02 CDT

C<p_adjust> (LikeR.xs) now takes a data frame as well as a flat list of
p-values, and hands the corrected values back in the shape they arrived in. An
AoA, AoH, HoA or HoH goes in and a new frame of the same kind comes out, with
the same rows, columns and row labels; the input is left alone. Everything the
flat form did is unchanged — an arrayref of p-values still returns a list, in
order, with the same numbers.

=over

=item * C<< columns =E<gt> 'p_value' >> (or an arrayref of names, or 0-based positions for an
AoA) says which columns hold p-values, and copies the rest of the frame
through untouched, so a results table with a C<gene> column no longer has to
be taken apart and put back together around the call. Without C<columns>
every cell is treated as a p-value, which is right for a frame that is
nothing but p-values; a label column in one dies with a message naming the
offending value and pointing at C<columns>, rather than correcting a string
coerced to zero.

=item * All the p-values in the frame are corrected as one family, whichever shape
they came in, so the family size is the number of p-value cells.

=item * The method still reads positionally and may now also be given as
C<< method =E<gt> ... >>. C<none>, which the function has always accepted, is now
documented along with the rest.

=item * Cells are visited in a fixed order — by row and then column name, or column
name and then row for a HoA — so tied p-values break the same way on every
run instead of following hash iteration order.

=back

C<drop_duplicates>, C<filter>, C<t_test>, C<vals>: speed/RAM improvements

B<Incompatible:> the C<'?'> / C<'h'> argument added in 0.27 is gone (lib/Stats/LikeR.pm). C<agg('h')>, C<read_table('?')> and the fifty-odd other pure-Perl functions that took it no longer print help and die — they treat the string as data, the way the XS functions always have. C<h('agg')>, C<h(*agg)> and C<h(\&agg)> are unchanged and remain the way to ask, for every function in the distribution.
- It was a help route that only half the module had, so what a lone C<'h'> meant depended on whether the callee happened to be written in XS or in Perl, and a column, file or option value really named C<'h'> needed C<$Stats::LikeR::HELP = 0> to get through. That variable is gone too; nothing reads its arguments for a help flag any more.
- C<bedroc> still prints its own short XS usage summary for C<bedroc('h' | 'H' | '?')>, which is hand-written and predates all of this.

C<merge> (LikeR.xs) — same joins, a third of the time and a fifth of the memory. Nothing about the result changes: every join type, shape combination and edge case produces exactly what it did before, and C<t/merge.t> now checks all six input/output paths against a plain-Perl reference join over a randomized corpus.

The old implementation transposed both frames into arrays of row hashes, joined those, and transposed the result back. A 10,000-row HoA joined to itself therefore built 20,000 throwaway row hashes and copied every cell three times before returning. It now reads each frame where it lies — a HoA column by column, an AoH/HoH row by row — and writes the result straight into the shape being returned, so the only cells copied are the ones the caller keeps.

=over

=item * The right frame's index is a hash of row numbers chained through a flat array, rather than an array-ref of index scalars per distinct key, and one reused buffer builds every join key instead of one scalar per row.

=item * Column names are resolved to their column (HoA) or interned once as shared hash keys (AoH/HoH) before the join starts, so the per-row work is a lookup rather than a lookup and a rehash.

=item * Measured on the C<benchmark.pl> case (two 10,000-row frames, six columns, inner join on C<id>): 0.052 s and 41.4 MB before, 0.017 s and 7.3 MB after. An outer join of the same frames went from 0.113 s to 0.008 s.

=back

C<write_table> (LikeR.xs) — two changes, one of them incompatible.
- Every format now prints the coloured C<< wrote E<lt>fileE<gt> >> confirmation line, not just LaTeX and C<.xlsx>. Delimited output (csv/tsv) was silent before. The line is identical in all cases: the file name in black on cyan, with the SGR codes inline so there is still no C<Term::ANSIColor> dependency. Nothing is announced when nothing is written.
- B<Incompatible:> C<row.names> now defaults to B<off> in every format. It previously defaulted B<on> everywhere, following R's C<write.table>, which meant a call that said nothing about row names got a label column and a leading empty header cell (C<,gene,n>) it had not asked for. Pass C<< row.names =E<gt> 1 >> for the old behaviour; C<< row.names =E<gt> 'col' >> is unchanged.

New C<h2aoh> and C<aoh2h> (lib/Stats/LikeR.pm), which add the flat hash to the shapes the conversion family understands. A plain hash is a two-column table folded shut, and until now nothing would unfold it: C<value_counts> hands one back, and no frame function would take it.
- C<< h2aoh(\%h, var_name =E<gt> .., value_name =E<gt> ..) >> unfolds a flat hash into a two-column AoH, one row per pair, under column names the caller picks. C<< sort =E<gt> 'key' | 'value' | 'none' >> fixes the row order, which hash iteration otherwise leaves to chance; C<'value'> is biggest-first for numbers, so C<value_counts> output comes out the way pandas' C<Series.value_counts()> orders it.
- C<aoh2h> folds a two-column AoH back down, with C<< duplicates =E<gt> 'die' | 'first' | 'last' >> deciding what a repeated key means. The two are exact inverses under their defaults.
- The column options are named C<var_name> / C<value_name> after C<melt>, which emits the same two columns. R spells this pair C<tibble::enframe()> / C<deframe()>; pandas spells it C<pd.Series(d).reset_index()> and C<Series.to_dict()>.

=head2 0.27 2026-07-26 CDT

New C<h> function: C<h('agg')>, C<h(*agg)> or C<h(\&agg)> prints that function's section of this document and returns, in the spirit of R's C<?function>. C<h()> lists every documented function. It covers the XS functions as well as the Perl ones, because it looks the name up in the module's POD instead of reading an argument list — see L</"Getting help">.
- The pure Perl functions also accept C<'?'> or C<'h'> in place of their arguments, which prints the same text and then dies. C<$Stats::LikeR::HELP = 0> switches that off for code that has to pass a column or file really named C<'h'>.
- C<qcut>'s hand-written usage message was replaced by its section of this document; C<qcut('h')> and C<qcut('?')> still die, but C<qcut('H')> no longer means help.

speed improvements in calculation of Kendall tau and p-value.  Improvement of writing xlsx files that won't show in time, but pure waste was removed.

Addition of C<auc>, C<auroc>, C<cmh_test>, C<epi_2x2>, C<roc> functions

C<prcomp> now accepts AoH input

glm extended (LikeR.xs)
- family => 'poisson' (log link) and family => 'negbin' — negative-binomial θ estimated by ML via a MASS::glm.nb-style outer loop, or fixed with theta =>. Matched R to ~1e-8 (coefs, deviance, null-dev, AIC, SE, θ); exact Poisson limit when data aren't over-dispersed.
- Every non-gaussian family now returns exp (odds/rate/incidence-rate ratios + conf.low/conf.high), link-scale conf.int, conf.level, and theta (negbin). Count families report z-statistics. OR/CI matched R's confint.default exactly.

New XS tests (all matched R exactly)
- prop_test — 1/2/k-sample proportions (Yates, Wilson & Wald-diff CIs)
- mcnemar_test — matrix or paired vectors; continuity correction; exact => 1 binomial
- friedman_test — repeated-measures rank test, tie-corrected
- dunn_test — post-Kruskal pairwise, 7 adjustment methods

New Perl functions (lib/Stats/LikeR.pm, matched base-R references)
- Effect sizes: cohen_d (+Hedges g, CI), smd, cramers_v (+Bergsma bias-corrected), eta_squared (η²/partial/ω²)
- vif, hosmer_lemeshow (matches hoslem.test)
- age_standardize — direct standardization + Fay–Feuer gamma CI (matches epitools::ageadjust.direct)

=head2 0.26 2026-07-20 CDT

https://www.cpantesters.org/cpan/report/fc7d01a0-83f4-11f1-b543-8a9ac547de9a
Fixed a long-double issue

=head2 0.25 2026-07-19 CDT

https://www.cpantesters.org/cpan/report/3376f80e-83bf-11f1-a5f3-44496e8775ea

Fixed a use-after-free in C<fisher_test> on the hash (HoH) input path: the "row is missing column key" error freed its scratch arrays and then read the key strings back out of them to build the croak message. This was harmless on glibc but crashed (C<SIGBUS>) under stricter allocators such as FreeBSD's, failing C<t/fisher_test.t> on CPAN smokers. The key pointers are now captured before the arrays are freed.

=head2 0.24 2026-07-19 CDT

C<interpolate>'s numeric core moved from pure Perl to XS (C<_interp_column_xs>): ~5× faster for C<linear> on large columns, ~11× for C<pchip>, and ~50× for the spline methods whose dense solve dominates. Results are unchanged (bit-for-bit versus the former Perl kernels).

C<Ronly> now accepts one or more array references (like C<Lonly>), returning the values found only in the B<last> reference; the two-argument form is unchanged, and C<Ronly(@refs)> equals C<Lonly(reverse @refs)>.

C<interpolate> gains full C<pandas.DataFrame.interpolate> method parity: C<nearest>, C<zero>, C<slinear>, C<pad>/C<ffill>, C<bfill>/C<backfill>, C<quadratic>, C<cubic>, C<cubicspline>, C<pchip>, C<akima>, C<barycentric>, C<krogh>, C<polynomial>, C<spline>, and C<index>/C<values>/C<time>, plus an C<x> argument for custom abscissae and an C<order> argument. Matched to pandas/scipy within 1e-6.

C<t/transpose.t> no longer loads C<Devel::Confess> in its leak tests: its C<$SIG{__DIE__}> stack-trace objects landed in C<$@> and were reported as leaks by C<Test::LeakTrace> on the croak paths under older perls (e.g. 5.12.3). The die-path leak checks now also clear C<$@> so the exception object cannot be miscounted.

C<cfilter> simplification, use of C<qr///> filtering on columns

C<summary> output now looks more like C<view>, and accepts HoH

C<fisher_test> can compute larger tables than just 2x2

C<read_table> reads xlsx files significantly faster and with less RAM.

Addition of C<bfill>, C<drop_duplicates>, C<ffill>, C<melt>, and C<pivot_table>

Original C<Lonly> code removed, as it was a special case of C<get_unique>, and C<get_unique> was re-named to C<Lonly>.

Removal of C<Devel::Confess> from testing and dependencies.

=head2 0.23 2026-07-10 CDT

C<rename_cols> takes HoH as input

C<write_table> prints row names as first column; writes longtable with comments

C<assign> gains C<map_cell { ... }> for in-place per-cell column edits

=head3 assign

C<assign> now accepts a third kind of column value, C<map_cell { ... }>, for editing an existing column in place — no "copy, substitute, return" boilerplate and no dependence on C<s///r> (unavailable on the older perls this module supports).

=over

=item * Inside a C<map_cell> block, C<$_> is the B<named column's current cell> (not the whole row), the block's return value is B<ignored>, and the modified C<$_> is stored back: C<< assign($df, 'Res.' =E<gt> map_cell { s/^[A-Z]:// }) >>.

=item * The row is still available as C<$_[0]> (sibling columns), the index as C<$_[1]>, and the row key as C<$_[2]> (HoH only).

=item * B<Undef/missing cells pass through untouched> (undef in → undef out): the block is skipped for them, so C<s///> never warns on an uninitialized value.

=item * Supported on all three shapes; for HoA the target column must already exist. A plain C<sub { ... }> is unchanged, so C<map_cell> is purely additive.

=item * C<map_cell> is exported alongside C<assign>.

=back

Tests: C<assign.t> (AoH + HoA) and C<assign.HoH.t> gained C<map_cell> coverage — in-place C<s///>, C<$_[0]>/C<$_[1]>/C<$_[2]> context, new-column-from-undef, the missing-HoA-column death path, and C<no_leaks_ok> guards. Verified building and passing the full suite on perl 5.10.1, 5.12.5 (long-double), and 5.42.2.

=head3 C<group_by>

Fixed group_by to honor all filter hashrefs (option 1)

Root cause: the XS captured only ST(3), so every filter hashref after the first was silently dropped — including the README's documented multi-hashref form.

Change (LikeR.xs):
- Removed the single-ST(3) capture and the filter_hv PREINIT var.
- Added a FOR_EACH_FILTER(body) macro that walks the arg stack from ST(3) to ST(items-1), iterating every { column => sub } pair and ANDing them together. It iterates the stack directly rather than heap-collecting the hashrefs, so a croaking filter sub still can't leak anything (verified). Non-hashref args are skipped.
- Rewrote the filter loop in all three branches (AoH / HoA / HoH) to use the macro, keeping each branch's own value-fetch logic.

One build wrinkle worth noting: xsubpp parses every non-# line in the inter-XSUB region as a candidate function signature, so a /* ... */ comment there breaks the build (it tried to parse column => sub / (ST(3)..) as a signature). I moved the macro's documentation into the XSUB body (real C) and left the macro comment-free, matching the existing EVAL_FILTER style.

Tests (t/group_by.HoH.filter.t, 17 assertions):
- HoH single-column filter, AND filter (both the one-hashref and separate-hashref forms now give identical results), no-match → empty hash, missing/undef target excluded despite passing the filter, and no_leaks_ok

Mentioning a non-existent column is now fatal.

=head2 0.22 2026-07-07 CDT

returned C<Devel::Confess> to required dependencies to fix for CPAN testers.

=head2 0.21 2026-07-07 CDT

Better warning message for undefined data for C<aoh2hoh>, C<assign>, C<dropna>

addition of C<agg>, C<concat>, C<drop_cols>, C<rank>, C<rename_cols>, C<select_cols> functions

Improving Kwalitee (sic): added C<[PodWeaver]> to dist.ini; as well as C<Changes> file

=head3 C<assign>

C<assign> now accepts two kinds of column value, so a function that already returns a whole column (like C<rank>) drops in without wrapping.

=over

=item * B<Per-row coderef> (unchanged): called once per row, C<$_> is the row, and the single scalar it returns is the cell. A single arrayref return is still stored I<as the cell>, so arrayref-valued columns keep working.

=item * B<Whole-column coderef> (new): if the coderef returns a I<list> of more than one value, that whole list becomes the column, laid down positionally. This is what makes C<< 'ΔG rank' =E<gt> sub { rank( vals($df, 'dG_kcal_mol') ) } >> work directly — no C<[ ... ]> needed.

=item * B<Arrayref value> (new): a ready-made column, e.g. C<< col =E<gt> [ rank(...) ] >>, copied into the frame.

=back

The coderef is probed once (row 0 for AoH/HoH, the first synthesized view for HoA) to decide per-row vs whole-column, so per-row code is never run twice on row 0. Every column value is length-checked against the row count and a mismatch dies. B<HoH> is now a supported, documented shape alongside AoH and HoA; whole-column and arrayref values align to B<sorted key order>.

Tests: C<assign.t> (AoH + HoA) and C<assign_HoH.t> were expanded to cover every shape × value-kind combination — per-row scalar, whole-column list, arrayref value, single-arrayref-as-cell, C<rank()> integration, chaining, C<$_[1]> index, C<$_[2]> row key (HoH), overwrite, ragged HoA columns, empty frames, length-mismatch and bad-value / odd-arg / non-hash-row death paths, and C<no_leaks_ok> guards on the new whole-column and arrayref paths.

=head3 C<read_table>

Fixed handling of commented-out header lines and made filter columns
referenceable by the name as it appears in the file.

=over

=item * B<Commented-out header recovery.> C<_parse_csv_file> treats a line whose
comment marker is followed by whitespace (e.g. C<< # PDBE<lt>TABE<gt>score >>) as a
comment and drops it, so a header written that way never reached the
callback and the first I<data> row was silently mistaken for the header.
C<read_table> now recovers it: the first physical line, if it is
C<marker + whitespace> and splits into two or more fields, is held as a
candidate header and confirmed only when its field count matches the first
data row. If the counts disagree the candidate was an ordinary leading
comment and is discarded, so a prose comment that happens to contain the
separator (e.g. C<# note, see README>) is never mistaken for a header. A
marker hugging its text (C<#id,val>) is delivered by the parser and
un-commented in the callback as before. The marker and any following
whitespace are stripped, so C<# PDB> is stored as the clean name C<PDB>.

=item * B<Filter columns may be named as written in the file.> Filter keys are
matched against the header by exact name first, then retried with the
leading comment marker (and surrounding whitespace) stripped, so a
commented-header column resolves whether it is referenced as C<# PDB> or by
its clean name C<PDB>:

=back

 read_table(
     'regression_rank.tabular.tsv',
     filter => { '# PDB' => sub { $_ == 2 } },
 );

=over

=item * B<Clearer "column not found" error.> The failure now names the file and
lists the actual header instead of printing it to STDOUT (a library
shouldn't print):

=back

 read_table: Filter column 'nope' not found in the header of FILE;
 header is: 'PDB', 'score'

=head2 0.20 2026-07-05 CDT

addition of C<ncol>, C<nrow>, and C<pnorm> functions

C<filter> can filter by row names with C<$_[1]>

C<view> now accepts array of arrays in addition to AoH, HoA, and HoH

=head3 csort

Two behavioural changes, both contained to the C<csort> XSUB (the C<cs_*> helpers are untouched).

B<Row names survive a Hash-of-Hashes sort.> Sorting a HoH previously discarded the outer keys. Now each row is folded into a I<fresh> row hash (a private container over aliased, read-only cells) that carries its outer key under a C<row.name> column, so the name flows into whichever shape you request:

 my $hoh = { alpha => { id => 1 }, beta => { id => 2 } };

 csort($hoh, 'id');          # AoH: each row gains a row.name field
 csort($hoh, 'id', 'hoa');   # HoA: an aligned row.name column

=over

=item * The column name defaults to C<row.name> and can be overridden with an optional 4th argument (mirroring C<hoa2hoh>'s named-key style): C<csort($df, 'id', 'aoh', 'sample')>.

=item * The outer key is authoritative — it wins over any pre-existing same-named field in the row.

=item * Once present, the column is sortable like any other: C<csort($hoh, 'row.name')>.

=item * Because rows are now I<copied> rather than shared, the caller's HoH is never mutated by the injection. (Minor behaviour change: output rows are no longer the same refs as the source rows.)

=back

B<Clearer usage message.> The signature is now C<csort(...)>, so xsubpp no longer emits the misleading auto-generated C<Usage: Stats::LikeR::csort(data, by, output=&PL_sv_undef)>. Argument count is checked by hand, and the croak now shows both real calling forms:

 Usage: csort($df, 'column.name', 'HoA')
    or  csort($df, sub { $b->{'No.'} <=> $a->{'No.'} }, 'hoa')
   (optional 4th arg names the row-name column when sorting a HoH; default 'row.name')

C<data>/C<by>/C<output> are read as C<ST(0..2)>; C<output> still defaults to matching the input shape.

B<Tightened validation messages.> The C<$data> croak now reads C<hash-ref (HoA or HoH)>, and the C<$by> croak includes a concrete example: C<< a column name (e.g. 'No.') or a comparator code-ref using $a and $b, e.g. sub { $b-E<gt>{'No.'} E<lt>=E<gt> $a-E<gt>{'No.'} } >>. Existing HoA croaks (C<unequal lengths>, C<not found>, C<not an array-ref>) are unchanged.

When sorting, undefined values in the sorting column are placed at the bottom

=head3 cor

Fixed an unsigned-integer underflow in C<kendall_tau_b> and added a regression test.

=head4 Bug

In C<kendall_tau_b>, concordant/discordant counts C<C> and C<D> are declared C<size_t> (unsigned). The numerator was computed as:

 return (NV)(C - D) / denom;

The subtraction C<C - D> happens in unsigned arithmetic I<before> the cast to C<NV>. When discordant pairs dominate (C<< D E<gt> C >>), the result wraps to a huge positive value instead of going negative.

For the arrays:

 dG_kcal_mol:  -7.765, -9.328, -10.326, -9.038, -9.608, -9.779, -9.975, -6.906
 anomaly_rank: 154, 155, 161, 188, 76, 172, 173, 69

there are C<C = 9> concordant and C<D = 19> discordant pairs (no ties). C<9 - 19> wraps to C<18446744073709551607>, so the function returned ~C<6.6e17> instead of the correct C<-10/28 = -0.3571428571>.

=head4 Fix

Cast each operand to C<NV> before subtracting, so the arithmetic is signed:

 return ((NV)C - (NV)D) / denom;

Only that one line changed. The denominator sums (C<C + D + tie_x>, C<C + D + tie_y>) are non-negative, so they were left as-is.

=head4 Regression test — C<cor.t>

=over

=item * Kendall on the offending arrays pinned to C<-0.3571428571>.

=item * Explicit C<[-1, 1]> range guard (the real backstop — the pre-fix value C<~6.6e17> blows past the bound regardless of exact magnitude), plus a negative-sign assertion.

=item * Pearson (C<-0.4889102301>), Spearman (C<-0.4761904762>), and default-method coverage of the three C<compute_cor> branches.

=item * Kendall boundary cases: perfectly concordant (C<+1>), perfectly discordant (C<-1>), self-correlation (C<+1>), and a tie case exercising C<tie_x> in the denominator.

=item * C<no_leaks_ok> per method (guarded with C<unless $INC{'Devel/Cover.pm'}>).

=item * Croak paths: length mismatch, unknown method, zero-variance input.

=back

=head3 XS refactor

Consolidate helper functions to reduce binary size, find bugs, and back the changes with tests. Every change was validated by translating the XS (C<ExtUtils::ParseXS>) and compiling the result
with the module's own C<ccflags>.

=head4 Outcome

=over

=item * B<Net change to the source:> ~154 fewer lines; helper-function count down by 4 (7 removed, 3 added).

=item * B<Genuine bugs fixed:> two instances of the same latent defect (see below). The rest of the work was behavior-preserving consolidation.

=back

=head4 Function consolidation

=for html <table>
<thead>
<tr>
  <th>Change</th>
  <th>Before</th>
  <th>After</th>
</tr>
</thead>
<tbody>
<tr>
  <td>Three-way <code>NV</code> comparator</td>
  <td><code>compare_rank</code>, <code>cmp_rank_item</code>, <code>cmp_rank_info</code>, <code>compare_NVs</code></td>
  <td>single <code>cmp_nv3</code> (reads the leading <code>NV</code> member, valid for <code>RankInfo</code>/<code>RankItem</code>/raw <code>NV</code>)</td>
</tr>
<tr>
  <td>Average-rank routine</td>
  <td><code>compute_ranks</code> + <code>compare_index</code> restoration sort</td>
  <td>existing <code>rank_data</code> (scatters ranks into <code>out[idx]</code>, no second sort)</td>
</tr>
<tr>
  <td>String comparator</td>
  <td><code>cmp_string_wt</code>, <code>lm_str_qsort</code> (byte-identical)</td>
  <td>single <code>cmp_string_wt</code></td>
</tr>
<tr>
  <td>Multiplicity filter &amp; set difference</td>
  <td><code>intersection</code> + <code>get_unique</code> (~90% shared); <code>Lonly</code>/<code>Ronly</code> duplicated bodies; a separate <code>set_difference()</code></td>
  <td>one shared <code>set_multiplicity()</code> with an "all vs. one" mode flag and a <code>from_last</code> flag: <code>intersection</code> (all), <code>Lonly</code> (one, first array), <code>Ronly</code> (one, last array)</td>
</tr>
</tbody>
</table>

All merges were confirmed behavior-preserving: the collapsed comparators are
equivalent on ordinary values, C<NaN>, and infinities, and C<compute_ranks> and
C<rank_data> produce identical average ranks.

=head4 Bugs

Two comparators stabilized their sort by returning C<< a-E<gt>idx - b-E<gt>idx >> directly,
where the index field is an unsigned C<size_t>. The subtraction wraps and is then
truncated to C<int>, which is implementation-defined and gives the wrong sign
once a difference exceeds C<INT_MAX>.

=over

=item * C<compare_index> — removed entirely (the routine that used it, C<compute_ranks>, was replaced by C<rank_data>).

=item * C<cmp_pval> — the tie-break comparator in the p-adjust path. B<Missed in the initial review; found later> via a C<-Wconversion> compile of the earlier source. Fixed to compare with the C<< (a E<gt> b) - (a E<lt> b) >> idiom.

=back

B<Caveat on severity:> on every mainstream ABI (LP64, LLP64, ILP32), the
low-word truncation happens to reproduce the correct sign for any array smaller
than ~2^31 elements, so this never produces a wrong result at realistic sizes.
It is a portability/UB issue, not a runtime failure, which is why no functional
test detects it (see "Testing", below).

 C<LikeR.xs> — consolidated helpers; C<compare_index> removed; C<cmp_pval> fixed.

=head3 C<view>

 non-ASCII characters now print

=head3 C<write_table>

new option to output to LaTeX table

=head2 0.19 2026-07-01 CDT

numerous C<SSize_t var1 = av_len(var) + 1> are changed to C<size_t var1 = av_len(var) + 1> as C<size_t>; as the result cannot be negative, in order to expand numerical range

Addition of C<hoa2hoh>, C<binom_test>, C<chunk>, C<get_union>, C<get_unique>, C<Lonly>, C<Ronly>, C<qcut>, and 3 tukey functions

Better warnings when non-array references are given to C<intersection>

C<view> now breaks columns into chunks for very wide data sets, more closely matching R's behavior

=head2 0.18  2026-06-28 CDT

C<restrict> keyword added to numerous places within C<intersection> to decrease CPU time

fix to dist.ini for dependencies

fixed POD rendering

=head2 0.17  2026-06-23 CDT (approx)

addition of C<assign>, which adds new columns based on calculations from other columns

addition of C<hoa2aoh>, transforming hash of arrays to array of hashes

addition of C<predict>, using results from C<aov>, C<glm>, and C<lm>

addition of C<aoh2hoh> transforming array of hash into hash of hashes, C<intersection>, C<uniq>, and C<vals>

=head3 C<aov>

=head4 Bug fixes

=over

=item * B<< C<size_t> underflow on empty arrays. >> Three loops were bounded by C<av_len(...)>
compared against an unsigned counter; C<av_len> returns C<-1> for an empty array,
which turned C<< k E<lt>= len >> into a C<SIZE_MAX> loop. The C<stack()> value loop, the C<.>
column-expansion loop, and the C<group_stats> column loop now use a signed
C<SSize_t> bound.

=item * B<HoH row count.> Row count for hash-of-hashes input was taken from the return
value of C<hv_iterinit>; it now uses C<HvUSEDKEYS(hv)> with a separate
C<hv_iterinit>, matching C<predict>.

=item * B<Buffer overflow in interaction parsing.> C<strcpy(right, colon + 1)> into a
fixed C<char right[256]> is now C<snprintf(right, sizeof(right), ...)>.

=back

=head4 Performance / memory

=over

=item * B<< Removed the per-row C<row_x> scratch allocation. >> Design rows are built
directly into C<X_mat[valid_n]>; C<valid_n> simply does not advance on a rejected
row. Interaction columns read their operands from the same in-progress row, so
the logic is unchanged.

=item * B<< C<row_names> is no longer dead. >> Surviving row names are transferred (pointer
move, no copy) into C<surv_names> to key C<fitted.values>; rejected rows are freed
in place.

=item * B<< Dropped a C<restrict> UB. >> C<orig_data_sv> aliases C<data_sv>; the C<restrict>
qualifier was removed.

=back

=head4 New, C<predict>-compatible output keys

=over

=item * B<< C<coefficients> >> — OLS estimates recovered by back-substitution on the R factor
left in C<X_mat> against Q'y in C<Y> (no re-derivation). Keys are the expanded term
names (C<Intercept>, continuous names, C<base.level> dummies, and C<a:b> interaction
products). Aliased columns are reported as C<NaN>, which C<predict> drops.

=item * B<< C<fitted.values> >> — C<Xb> over the non-aliased columns, keyed by surviving row
name. Computed from a snapshot of the design (C<Dsav>) taken before the QR
overwrites C<X_mat>. Costs one transient copy of the design matrix; negligible for
typical ANOVA where the column count is small.

=item * B<< C<xlevels> >> — sorted level list per factor, index 0 = reference, aligned with
the contrast coding used to build the dummies.

=item * B<< C<family> >> — C<"gaussian">.

=back

=head4 Cleanup-path correctness

=over

=item * C<xlevels_hv>, C<Dsav>, and C<surv_names> are freed on both the "0 degrees of
freedom" croak and the normal exit. The interaction-main-effects croak in
PHASE 3 also frees C<xlevels_hv>.

=back

=head4 Known limitations (unchanged)

=over

=item * The intercept-stripping string surgery (C<-1>, C<+0>, C<+1>, ...) operates on the
whole RHS and can still mangle C<I(x-1)>-style transforms; treat C<I()> with
arithmetic constants carefully.

=item * Top-level keys C<coefficients> / C<fitted.values> / C<xlevels> / C<family> /
C<group_stats> share the return hash with the ANOVA rows; a predictor literally
named one of those would collide.

=back

=head3 C<predict>

=head4 New: factor-bearing interaction terms

Previously, interaction coefficients such as C<GroupB:Sexmale> or C<GroupB:x> fell
through to the continuous C<evaluate_term> path and died on a nonexistent column.
They are now handled directly:

=over

=item * B<< C<dummy_hv> >> stores each dummy's factor base index (an C<IV>) instead of
C<&PL_sv_yes>, so a dummy name maps back to its C<(base, level)> in O(1)
(C<level == name + strlen(base)>). C<hv_exists> lookups are unaffected.

=item * During coefficient caching, any C<:> term with at least one factor-dummy component
is routed to a separate list (C<icopy> / C<ibeta>); pure-continuous interactions
(e.g. C<x:z>) stay on the existing C<evaluate_term> path, so prior behavior is
preserved.

=item * Each routed term is parsed once into flat component arrays. Factor components
store a base index and level pointer; continuous components store the term string
and get the same up-front column-existence validation as main terms.

=item * Per row, each factor's raw level is read once into C<raw_lv[]> and reused by both
main effects and interactions (no duplicate C<get_data_string_alloc>). An
interaction's value is the product of its components: a factor component
contributes C<1.0> iff the row's level matches the dummy's level (reference levels
give C<0>), continuous components go through C<evaluate_term>.

=back

This covers factor×factor, factor×continuous, continuous×continuous, and n-way
combinations.

=head4 Other

=over

=item * HoH row count uses C<HvUSEDKEYS> (already present).

=item * The unseen-factor-level croak now frees every level string already read for the
current row, not just the current one.

=back

=head3 Tests

=over

=item * B<< C<aov.t> >> — one-way ANOVA against hand-computed values (Df / Sum Sq / Mean Sq /
F / decomposition); identical results across HoA / HoH / AoH / stacked input;
simple regression; C<.> expansion; intercept removal (C<-1>); two-way with
interaction (Type I SS on a balanced design); NaN listwise deletion; all croak
paths; leak checks.

=item * B<< C<predict.t> >> — C<predict(training) == fitted.values> round-trips for one-way,
regression, factor×factor, factor×continuous, and continuous×continuous models;
explicit predicted values; agreement across HoA / AoH / HoH / flat newdata;
no-newdata path; binomial C<link> vs C<response>; gaussian identity link; all croak
paths; leak checks.

=back

Leak tests use C<no_leaks_ok> guarded by C<unless $INC{'Devel/Cover.pm'}> and skipped
when C<Test::LeakTrace> is absent.

=head4 Assumptions worth confirming

=over

=item * The NaN-deletion test relies on C<evaluate_term> returning C<NaN> for a non-finite
response value (an C<Inf - Inf> NaN is fed in deterministically).

=item * The continuous×continuous round-trip relies on C<evaluate_term("x:z")> yielding
C<x * z> — the same assumption the pre-existing C<predict> continuous-interaction
path already made. If that path was untested, this round-trip now exercises it.

=back

=head3 C<view>

now returns colored output; fixed bug with incorrect widths; undefined values show as C<undef> rather than C<NA>, as in Data::Printer

=head3 C<csort>

now accepts Hash of Hashes; addition of C<restrict> which should decrease calculation time

=head3 filter

=over

=item * B<Added hash-of-hashes (HoH) input.> In addition to AoH and HoA, C<filter> now accepts an HoH (C<< { key =E<gt> { col =E<gt> val, ... }, ... } >>); each inner hash is one row, and matching keys are preserved by default (HoH -> HoH).

=item * B<< Added C<output.type>. >> C<< filter($df, $pred, 'output.type' =E<gt> 'aoh'|'hoa') >> selects the returned shape (aliases C<out> / C<output_type>; a bare positional type also works). When omitted, the input shape is preserved. C<hoh> is not a selectable output, since it would require choosing a key column.

=item * B<< C<col()> reworked, not removed. >> Both predicate forms are kept: C<< col('age') E<gt>= 18 >> still works and is the concise/composable option, while a coderef covers everything else. Internally C<col()> is now B<pure Perl> — an overloaded class that builds a per-row closure — and C<filter> unwraps that closure so C<col()> and a coderef share one evaluation path. The previous standalone XS predicate evaluator (C<filt_eval>/C<filt_ctx>) is gone; delete it if your tree still has it. One consequence: a C<col()> comparison now costs the same per row as the equivalent coderef (a Perl call), rather than being evaluated in C.

=item * B<Unchanged guarantees:> the input frame is never modified; C<undef> (and, for numeric ops, non-numeric) cells never match a C<col()> comparison; AoH/HoH rows are shared rather than copied where possible; keep-all/keep-none shapes are well defined per output type; Perl 5.10 compatibility is retained. A latent C<SvTRUE(POPs)> double-evaluation in the per-row call helper (which crashed on perls where C<SvTRUE> is a multi-eval macro) was fixed along the way.

=back

=head3 read_table

Added an opt-in C<auto.row.names> argument so C<read_table> can read the file R
produces by default from C<write.table(x, sep="\t")>.

=head4 The problem

R's C<write.table> defaults to C<row.names=TRUE, col.names=TRUE>, which writes the
row-names column in every data row but emits B<no header label for it>. So a
frame with N columns comes out as N header fields over N+1 data fields — e.g.
C<mtcars> gives 11 headers but 12-field rows. By default C<read_table> (correctly)
rejects that as ragged:

 Alignment error on mtcars.tsv data row 1 (12 fields vs 11 headers).

=head4 The change

C<auto.row.names> turns on R's own C<read.table> rule: B<when, and only when, the
header is exactly one field short of the data rows, treat the first field of
each row as an (unlabelled) row-names column.>

 # default: the leading column is named 'row_name'
 my $df = read_table('mtcars.tsv', 'auto.row.names' => 1);

 # or give it a name
 my $df = read_table('mtcars.tsv', 'auto.row.names' => 'model');

The synthesized column behaves like any other first column: it appears in C<aoh>
and C<hoa> output, and for C<hoh> it becomes the default key (so rows are keyed by
the model name). This also lines up with the existing handling of R's
C<col.names=NA> output (a blank leading header), which still produces a
C<row_name> column with no flag needed.

=head4 What did not change

The strict alignment check is still the default. Without C<auto.row.names> the
lopsided file still croaks, and even with it, a row that is off by anything
other than exactly one field still croaks — so the corruption guard only relaxes
for the one case R itself treats specially.

Tested in C<t/read_table.2.t> (16 assertions, Perl 5.10.1 and 5.38): aoh / hoa /
hoh output, custom column name, the already-aligned file (flag is a no-op), the
C<col.names=NA> path, and the strict / ragged croak paths.

=head4 additional bugfix

 # This is a comment
 id,name,val
 1,Alice,10.5
 2,Bob,
 3,Charlie,15.2

would not be read correctly using C<read_table>, but now is read correctly

=head3 value_counts

now accepts array of hashes

=head2 0.16  2026-06-17 CDT

changes to dist.ini, the minimum Perl version disappeared when I fixed other problems

clarifications between run time and test dependencies

addition of C<csort> function to sort AoH and HoA

addition of C<aoh2hoa> to translate array of hashes into a hash of arrays

fix of long double functions: https://www.cpantesters.org/cpan/report/5d5d9836-6a5f-11f1-aadb-63fd6d8775ea

=head3 C<glm>

output residual keys now use names, not integers

=head3 C<lm>

=head3 Bug fixes

B<Memory leak on the zero-degrees-of-freedom error path.> When
C<< valid_n E<lt>= p >>, the cleanup freed the C<valid_row_names> I<array> but not the
per-row name strings it held (those had been transferred out of C<row_names>,
whose own array was already freed). The strings leaked on every such error.
Added the per-entry C<Safefree> loop before freeing the array, matching the
normal path.

B<HoH input validated only the first row.> Only the first hash value was
checked to be a C<HASHREF>; subsequent values were C<SvRV>'d unconditionally, so
a malformed row (C<< { a =E<gt> {...}, b =E<gt> 5 } >>) dereferenced a non-reference. Every
row is now validated, with the partial allocations cleaned up before the
C<croak>, mirroring the existing AoH path.

B<< C<isspace> on a possibly-signed C<char>. >> C<isspace(*src)> is undefined for
byte values ≥ 0x80 on platforms where C<char> is signed. Cast to
C<(unsigned char)> before the call.

=head3 Speed / RAM improvements

B<Formula buffer is now heap-allocated to fit.> C<char f_cpy[512]> silently
truncated any longer formula. Replaced with a buffer sized to
C<strlen(formula) + 1>, so there is no fixed limit and no truncation.

B<< C<.>-expansion buffer is now a growable heap buffer. >> C<char rhs_expanded[2048]>
silently dropped expanded terms once full. It is now a buffer that doubles on
demand. Appends also went from C<strcat> (which rescans from the start every
time — O(n²) over many columns) to an O(1) amortised append that tracks the
write position.

B<No more per-row scratch allocation in matrix construction.> The original
C<safemalloc>'d a C<row_x> buffer, filled it, copied it into C<X>, and freed it
I<for every row> — C<n> allocations plus C<n*p> copies. Each candidate row is now
written straight into C<X> at its prospective commit slot; a row that fails
listwise deletion is simply overwritten by the next candidate. This removes the
C<n> allocate/free cycles and the copy loop entirely.

B<< Categorical levels sorted with C<qsort>. >> The level list used an O(n²) bubble
sort; replaced with C<qsort> (relevant only for high-cardinality factors).

B<< Unused tail of C<X> reclaimed after listwise deletion. >> C<X> is allocated for
all C<n> rows up front (C<valid_n> is unknown until rows are scanned). When rows
are dropped, C<X> is now C<Renew>ed down to C<valid_n * p>, returning the unused
tail to the allocator before the OLS phase.

B<Minor robustness.> The argument-parsing index was widened from
C<unsigned short> to C<I32> to match C<items>, and the HoH row count now uses
C<HvUSEDKEYS> rather than relying on C<hv_iterinit>'s return value.

=head3 Known limitations (left unchanged)

=over

=item * A multi-way term such as C<a*b*c> is split only on the first C<*>, so it yields
C<a>, C<b*c>, and C<a:b*c> rather than a full three-way expansion. Deeper
interactions silently fail (the unparsable term evaluates to C<NaN> and the
rows are dropped). This matches the documented two-way C<*> support.

=item * HoA input takes the row count from the first column; columns shorter than
that simply contribute dropped rows rather than raising an error.

=back

=head3 C<oneway_test>

=head4 Bug fixes

B<Memory leaks on error paths.> Nearly every C<croak> after an allocation
leaked memory. C<croak> does a C<longjmp>, so anything allocated but not yet
freed is lost. Affected paths:

=over

=item * AoA and hash first-pass errors leaked C<sizes> and any C<gnames[]> entries
allocated so far.

=item * Formula-mode "not found as an array ref" errors leaked C<lhs> and C<rhs>.

=back

All post-allocation errors now route through a single C<fail:> label that frees
every pointer unconditionally. Pointers are initialised to C<NULL> and C<gnames>
is zero-allocated with C<Newxz>, so the cleanup is always safe to run.

B<< Undefined and non-numeric cells silently coerced to C<0.0>. >> The original
second pass used C<(svp && *svp) ? SvNV(*svp) : 0.0>, meaning an C<undef> or
non-numeric cell was quietly treated as zero, silently corrupting the
F-statistic. Each cell is now validated with C<SvOK> and C<looks_like_number>;
the call dies naming the group and observation index, consistent with the rest
of C<Stats::LikeR> (C<mean>, C<sum>, C<cor>, etc.).

B<Unsigned wraparound on empty array input.> C<k = (size_t)av_len(in_av) + 1>
cast to C<size_t> I<before> adding, so an empty array (C<av_len> returns C<-1>)
produced C<SIZE_MAX> rather than C<0>. Changed to
C<k = (size_t)(av_len(in_av) + 1)> so the C<+1> is done in signed arithmetic
before the cast.

B<< Unreliable group count from C<hv_iterinit>. >> C<hv_iterinit> returns the
number of buckets in use rather than the number of keys for tied hashes.
Replaced with C<HvUSEDKEYS>, which always returns the correct key count.

=head4 Improvements

B<< C<var.equal> accepted as an alias for C<var_equal>. >> R users write
C<var.equal>; the argument parser now accepts both spellings.

B<Perl memory API used throughout.> C<safemalloc> and manual C<memcpy> replaced
with C<Newx>, C<Newxz>, C<savepv>, and C<savepvn>. C<savepvn> additionally
preserves embedded NUL bytes in group key strings, which the previous
C<strlen>-based copies silently truncated.

=head4 Known limitations (not changed)

=over

=item * A factor column named C<Residuals> or C<group_stats> in a formula call will
collide with reserved top-level keys in the result hash.

=item * Group names containing an embedded NUL are stored correctly but are still
truncated at C<strlen> when written into the output hash keys.

=back

=head3 C<view>

default view shifted to 80 characters to match Linux window length

=head4 New features

=over

=item * B<< C<rows> is accepted as a synonym for C<n> >> (the number of rows shown).
Passing both C<n> and C<rows> is an error.

=item * B<Unknown arguments are now rejected.> C<view> validates its argument names
against the documented set (C<n>, C<rows>, C<na>, C<max_width>, C<ellipsis>,
C<gap>, C<cols>, C<columns>, C<to>, C<return_only>, C<row.names>, C<row_names>) and
dies listing any it does not recognise, so a misspelt option (e.g. C<widht>)
is caught instead of silently ignored.

=item * B<< C<n> / C<rows> is validated. >> It must be a non-negative integer; C<undef> or
a non-numeric value now dies with a clear message instead of producing
warnings and being treated as C<0>.

=item * B<flat/simple hashes are accepted as input>

=back

=head4 Bug fixes

=over

=item * B<< C<< n =E<gt> 0 >> now still prints the column header. >> Column names were collected
only from the rows being shown, so requesting zero rows produced an empty
header line. At least one row is now scanned (when data exists) so the
header always lists the columns.

=item * B<< An empty hash (C<{}>) no longer dies. >> It was rejected as
I<"neither ARRAY nor HASH">; it is now shown as an empty table
(C<0 rows x 0 cols>), matching the handling of an empty array.

=item * B<< The C<row_names> alias now drives the Hash-of-Hashes label header. >> The
header for the row-label column consulted only C<row.names>, so
C<< row_names =E<gt> 'id' >> displayed C<row_name> instead of C<id>. Both spellings are
now honoured consistently.

=item * B<Malformed nested values degrade gracefully.> A Hash-of-Arrays column or
Hash-of-Hashes row whose value is not actually an array/hash reference now
renders as empty cells rather than throwing a dereference error.

=back

=head4 Performance

=over

=item * Column gathering no longer sorts once per scanned row. Unique column names
are collected across the scanned rows and sorted a single time (same output
order), and the ellipsis length is computed once rather than per cell.

=back

=head4 Tests

=over

=item * C<t/view.t> is self-contained (the C<view> implementation is inlined; it loads
no other files) and covers the new argument handling, the bug fixes above,
and the existing AoH / HoA / HoH behaviour, alignment, truncation, and
output-path handling.

=back

=head3 C<wilcox_test>

Corrected four bugs in the C<wilcox_test> XSUB plus a portability fix in its exact signed-rank helper. Behaviour on valid input is unchanged: the R-agreement cases (unpaired C<W = 58>, C<p = 0.13292>; paired one-sided C<V = 40>, C<p = 0.019531>; separated exact C<W = 0>, C<p = 0.028571>) all still match R's C<wilcox.test>.

=head4 Bug fixes

=over

=item * B<< Invalid C<alternative> is now rejected. >> Any value other than C<less> or C<greater> previously fell through to the two-sided branch and returned a two-sided result mislabelled with the bad string, so a typo like C<< alternative =E<gt> "twosided" >> silently "worked". It now croaks unless C<alternative> is one of C<two.sided>, C<less>, C<greater>.

=item * B<Zero/negative variance is guarded.> When every observation is tied the approximation's variance collapses to 0 and the old code divided by C<sqrt(0)>: C<wilcox_test([5,5,5], [5,5,5])> returned C<p = 0> (a "significant" difference between identical samples). It now warns and returns C<p = 1>.

=item * B<< Two-sided continuity correction at C<z = 0>. >> R uses C<sign(z) * 0.5>, so the correction is C<0> when the statistic sits exactly on its mean; the old code used C<-0.5>. Example: C<< wilcox_test([1,4], [2,3], exact =E<gt> 0) >> changed from C<p = 0.698535> to C<p = 1> (matches R).

=item * B<< C<exp> no longer shadows libm. >> The local C<exp> accumulator (mean of the statistic) shadowed the C library C<exp()>; renamed to C<mean_w> (two-sample) and C<mean_v> (signed-rank). No active miscompute, removed as a latent hazard.

=back

=head4 Cosmetic

=over

=item * Collapsed a no-op ternary that assigned the same signed-rank exact method string on both branches; the C<method> field is now simply C<Wilcoxon signed rank exact test>.

=back

=head4 Portability (exact signed-rank helper)

=over

=item * B<< C<exact_psignrank> no longer calls C<powl()>. >> The C<2^n> normaliser is now built by exact repeated doubling, which has no long-double libm dependency. This fixes an C<Undefined symbol "powl"> load failure reported by a CPAN smoker (FreeBSD, perl 5.20, C<nvtype=double>) whose libm lacks the long-double math functions; the symbol resolved on glibc, which is why local builds passed. C<long double> accumulation in the DP is retained — only the C<powl> call was at fault.

=item * B<< C<int> → C<size_t> >> for C<n>, C<max_v>, and the DP loop counters, which also removes a C<size_t>-to-C<int> narrowing at the call site. The C<floor()> result (C<k>) stays signed so its negative-C<q> sentinel still fires, and is cast to C<size_t> only after the C<< k E<lt> 0 >> check.

=back

=head4 Tests

=over

=item * Added C<t/wilcox_test.t> (flat, no subtests): R-agreement cases, option handling (C<paired>, C<correct>, C<exact>, C<mu>, named/positional C<x>/C<y>, NA dropping), regressions for all four bug fixes, argument-error and C<alternative>-validation checks, output shape, and C<no_leaks_ok> coverage of the two-sample, exact, and paired allocation paths.

=back

=head2 0.15  2026-06-11 CDT

C<view> function added, similar to R's C<head>

C<read_table>:

 filter => {
     'Testosterone, total (nmol/L)' => sub { defined $_ },
 }

was broken by the change in undefined variables in 0.14, but is back to being C<undef>

C<col2col> improvement in sectioning in README

Numerous changes to prevent quadmath/long double CPAN test failures

Minimum Scalar::Util version in dist.ini is now 1.22, see https://www.cpantesters.org/cpan/report/6b682236-6567-11f1-a3bc-a055f9c4ba34

C<Digest::SHA> removed as a dependency

=head3 C<read_table>

=head4 Bug fixes

=over

=item * B<A comment-prefixed header is now read correctly.> C<read_table> strips a
leading comment marker from the header line (so a file may begin with
C<#id,val>), but that strip was dead code: the XS parser skipped I<every> line
beginning with the comment string before the callback ever saw it, so a
commented header was silently dropped and the first data row was mistaken for
the header. The parser now delivers the first content line even when it
begins with the comment marker, and only skips comment lines after the header
has been seen.

=item * B<Carriage returns inside quoted fields are preserved.> The parser stripped
C<\r> unconditionally, so a quoted value such as C<"x\ry"> lost its carriage
return and would not survive a C<write_table> -> C<read_table> round-trip. C<\r>
is now stripped only as part of a trailing CRLF line ending and as a stray CR
I<outside> quotes; inside quotes it is literal data.

=item * B<< Duplicate column names no longer corrupt C<hoa> output. >> With
C<< output.type =E<gt> 'hoa' >>, a repeated column name pushed the same cell once per
occurrence, so the affected columns came out longer than the others and the
arrays no longer lined up by row. Columns are now keyed by unique header name
(first-seen order preserved, later values win, one warning emitted).

=item * B<A defined non-CODE callback is now an error.> Passing a defined argument
that was not a CODE reference silently fell through to slurp mode and ignored
the argument; it now croaks
(I<"callback must be a CODE reference">).

=item * B<< An undefined/empty C<hoh> row-name now dies instead of keying on C<"">. >>
With C<< output.type =E<gt> 'hoh' >>, a row whose row-name column was empty/undef was
stored under the C<''> key and raised I<"uninitialized value"> warnings. It now
dies, naming the column and the offending data row.

=item * B<A numeric filter key past the last column now dies.> A 1-based numeric
filter key greater than the column count was accepted, then silently extended
every row through the C<$_> write-back. It is now rejected up front with a
message naming the column count.

=item * B<< C<sep> and C<delim> together now die. >> Supplying both silently preferred
C<delim>; passing both is now an explicit error (C<delim> remains an alias for
C<sep> when used alone).

=item * B<The library no longer prints to STDOUT.> The unknown-argument path used
C<say> to dump the offending names to STDOUT before dying; the names are now
carried in the C<die> message itself.

=back

=head4 Better diagnostics

=over

=item * Alignment errors now report B<which data row> is ragged
(I<"Alignment error on FILE data row N (X fields vs Y headers)">), instead of
only the field/header counts.

=back

=head4 Memory-leak fixes (exception paths)

The parser allocated its working buffers (C<current_row>, C<field>, and — in
slurp mode — C<data>) in the XS C<INIT:> block, i.e. I<before> any validation, and
freed them only by falling off the end of the function. Any non-local exit
therefore leaked:

=over

=item * the open-failure C<croak> leaked the row buffer and field (and the slurp
accumulator);

=item * far more commonly, a C<die> thrown B<inside the row callback> — which
C<read_table> does routinely on alignment errors, bad row names, and filter
exceptions — unwound straight out of the XS frame and leaked the field, the
current row, the line buffer, the slurp accumulator, I<and the open file
handle>.

=back

Allocations now happen in C<CODE:> after every croak-able check, and every
long-lived resource (the file handle via C<SAVEDESTRUCTOR_X>, the buffers via
C<SAVEFREESV>) is tied to the save stack, which an exception unwinds. Measured
with C<Test::LeakTrace>: a C<die> mid-file went from 5 leaked SVs to 0, and an
open failure from 2 to 0. This is the likely source of the constant-size leaks
seen in CPAN-tester reports for the exception-path tests.

=head4 Performance

=over

=item * B<~2.5x faster parsing> (57 -> 145 MB/s on a 100k-row quoted file). The core
loop appended one character at a time with C<sv_catpvn(field, &ch, 1)>; it now
scans runs of ordinary bytes with C<memchr> / a bounded scan and appends each
run in a single C<sv_catpvn>, copying field contents in bulk rather than byte
by byte.

=back

=head4 Internal / non-behavioral

=over

=item * XS declarations moved from C<INIT:> to C<PREINIT:>; allocations deferred into
C<CODE:> (see the leak fixes above).

=item * The filter loop now aliases the row hash with C<local *_ = \%line_hash>
instead of copying it with C<local %_ = %line_hash>. This removes a full
per-row hash copy for every filtered row and fixes a latent staleness bug:
after a filter mutated C<$_> and the change was written back, C<%_> still
reflected the pre-mutation copy, so a subsequent filter in the same row saw
stale values. With aliasing, C<%_> I<is> the row, so write-backs are always
visible.

=back

=head4 Known limitation (not changed)

=over

=item * B<< C<undef.val> does not round-trip back to C<undef>. >> C<write_table> renders an
C<undef> cell as an empty field by default, and C<read_table> maps an empty
field back to C<undef>, so the I<default> round-trip is clean. But if a file is
written with a token such as C<< 'undef.val' =E<gt> 'NA' >>, C<read_table> has no
inverse option and reads C<NA> back as the string C<'NA'>. C<read_table> also
cannot distinguish a deliberately quoted empty string (C<"">) from a missing
value -- both become C<undef>. Adding an C<na.strings>-style option to
C<read_table> (mapping configurable tokens and/or empty fields to C<undef>)
would close this gap.

=back

=head3 C<write_table>

=head4 Behavior change

=over

=item * B<< C<undef> cells now write as an empty field, not an empty string. >> A missing
or C<undef> value renders as nothing between separators (C<a,,c>) rather than a
quoted empty string (C<a,'',c> / C<a,"",c>). Supplying C<< 'undef.val' =E<gt> 'NA' >>
(or any other token) still overrides this, exactly as before. This is the
only change that can alter the bytes of an existing output file; if you relied
on the previous default, pass C<< 'undef.val' =E<gt> '' >> to keep an explicit empty
field, or your chosen placeholder.

=back

=head4 Bug fixes

=over

=item * B<Wide-character / UTF-8 column names and row keys now round-trip.>
Previously, cells were looked up with the raw bytes of the column name
(C<hv_fetch(..., SvPV_nolen(name), strlen(name), ...)>), which fails to match a
UTF-8-flagged hash key: the column header printed correctly but every cell
under it came back empty. All lookups now fetch by SV (C<hv_fetch_ent>), header
lists are gathered and sorted as SVs (C<sortsv> + C<sv_cmp>, preserving the
flag) instead of being round-tripped through C<char *>, and the C<row.names>
column is matched with C<sv_eq> rather than C<strcmp>. Embedded NUL bytes in
keys are handled correctly as a side effect.

=item * B<< C<< col.names =E<gt> [] >> no longer loops forever. >> An empty C<col.names> array made
C<av_len()> return C<-1>, which — compared against an unsigned C<size_t> loop
index — wrapped to C<SIZE_MAX> and ran effectively without end. This was fixed
for flat hashes previously; it was still present for hash-of-hashes,
hash-of-arrays, and array-of-hashes, plus both C<row.names> header-filtering
loops. All such loops now use a signed index.

=item * B<Tables wider than 65,535 columns no longer hang.> One header loop used an
C<unsigned short> index that silently wrapped past 65,535 and never terminated.
It now uses C<size_t> like the rest of the code.

=item * B<Flat-hash cells holding a reference now croak.> Every other input shape
rejects a nested reference with
I<"Cannot write nested reference types to table">; a flat hash instead
stringified it (e.g. C<ARRAY(0x55...)>) into the file. It now croaks
consistently.

=item * B<< C<< 'undef.val' =E<gt> undef >> is handled cleanly. >> It previously called
C<SvPV_nolen> on C<undef>, raising an I<"uninitialized value"> warning and
yielding an empty string by accident. It is now treated explicitly as an empty
field, with no warning.

=back

=head4 Memory-leak fixes (exception paths)

=over

=item * The row-key list gathered for hash-of-hashes input was leaked when the output
file could not be opened.

=item * The I<"Could not get headers"> croak on hash-of-arrays input leaked both the
already-open filehandle and the headers array.

=back

=head4 Internal / non-behavioral

=over

=item * Numeric row labels are now formatted into a reused stack buffer instead of a
per-row C<savepv()> / C<safefree()> allocation (no functional change; removes a
cast-away-C<const> and one allocation per row).

=item * Several signed/unsigned index types were made consistent (C<SSize_t> vs
C<size_t>) to match C<av_len()> and silence the conditions behind the loop bugs
above.

=back

=head4 Tests

=over

=item * C<t/write_table.t> expanded from 17 to 69 assertions. New coverage targets each
fix above: the empty-field default and C<< undef.val =E<gt> undef >> (no warning),
C<< col.names =E<gt> [] >> termination across all four input shapes, the
 >65,535-column header loop (gated behind C<EXTENDED_TESTING=1>), in-sequence
numeric row labels, nested-reference rejection, CSV quoting corners
(carriage return, separators inside column names, multi-character separators),
empty input writing no file, and UTF-8 column names and row keys. Two leak
assertions cover the exception paths above.

=back

=head2 0.14 2026-06-08 CDT

C<filter> function added for rows

C<read_table> reads undefined values to C<undef> instead of C<NA>, which makes calculations easier

C<write_table> writes undef by default as an empty string C<''>

C<hoh2hoa> transforms a hash of hashes into an hash of arrays

C<quantile> uses C<NV> instead of C<double> to allow for high-precision 128-bit floats to be used on quadmath machines when available: https://www.cpantesters.org/cpan/report/296f4868-631f-11f1-abba-ff15558d240b

Numerous switches from C<double> to C<NV> for local precision, like above

numerous changes to C<col2col> for ease of use and working with datasets with numerous undefined values

dist.ini now links to math library when compiling: https://www.cpantesters.org/cpan/report/785e26d8-6397-11f1-89c0-dc066e8775ea

C<fisher_test> now should be complete, errors with confidence intervals fixed

=head2 0.13 2026-06-07 CDT

C<read_table>: speed improvements; commented headers are now allowed

C<write_table>: fix for 

 Attempt to free temp prematurely: SV 0x56417a2ae610 at t/write_table.t line 182.
     main::wrote_ok(",age\x{a}Alice,30\x{a}Bob,25\x{a}", "row.names => 'name' uses that column as labels", HASH(0x56417a272250), "row.names", "name") called at t/write_table.t line 203
 Attempt to free unreferenced scalar: SV 0x56417a2ae610 at t/write_table.t line 183.
     main::wrote_ok(",age\x{a}Alice,30\x{a}Bob,25\x{a}", "row.names => 'name' uses that column as labels", HASH(0x56417a272250), "row.names", "name") called at t/write_table.t line 203

C<write_table> gives better warnings for incorrect types of data given

Numerous changes to dist.ini to improve CPAN testing, especially for Win32

=head2 0.12 2026-06-08 CDT

C<add_data> can also take hash of arrays, and various mixes of data types

C<ljoin>: Addition of C<restrict> keywords in many places; should improve CPU performance

Better POD formatting, correction of output hash for README's C<add_data>

C<chisq_test> can now accept hash of hashes as input

new C<transpose> function for switching 2D hash keys and 2D array indices, and C<col2col> for comparing columns against columns

removed unused function from C helpers

C<value_counts>: addition of restrict keywords in preinit, should improve CPU performance

MANIFEST.skip changed to MANIFEST.SKIP to improve CPAN testing

using C<is_deeply> for tests of C<transpose>, which may or may not work with CPAN testers (experimental)

Added function name to warnings, so I actually know which function is producing the error

C<write_table> can also take C<file> and C<data> as args, in addition to positions

fixed C<write_table> as it could hang if given empty C<col.names> or C<row.names>

Added C<__EXTENSIONS__> to source XS file for better CPAN testing

=head2 0.11 2026-06-03 CDT

better POD formatting for tables

addition of MANIFEST.skip to get better testing results on CPAN

C<glm>: bugfix for when there is no intercept in the formula, new test cases in t/glm.t

C<write_table> now accepts simple hashes as input, in addition to hash of arrays, hash of hashes, and arrays of hashes

Better documentation for t-test

=head2 0.10 2026-06-01 CDT (approx)

changes to compilation for CPAN, trying to get this work on Windows

Addition of C<prcomp> and C<value_counts>

C<matrix> will work without key names, just like in R.  Testing for C<matrix> has improved.

=head2 0.09 2026-06-01 CDT (approx)

context changes in XS C<dTHX>, C<pTHX_>, and C<aTHX_> to get better CPAN testing results

C<restrict> keywords added to C<lm> to increase speed

=head2 0.08 2026-05-26 CDT

Speed improvement in C<summary> of hashes.

Addition of C<add_data>, C<dnorm>, C<group_by>, C<ljoin>, and C<mode> functions

Chi-squared function no longer has Perl wrapper, and all code is in XS, which should result in a minor speed increase with 1 less function call.

Compiler changes for GNU source and inclusion of C<strings.h>, to ensure more CPAN testing works better.

C<read_table> now returns hash-of-hash in {row}{column}

=head2 0.07 2026-05-24 CDT

Addition of C<summary> function.

Formulas can now be omitted from C<aov>, resulting in a stacked calculation as R would think.

Addition of C<oneway_test> for multi-group comparisons that does not assume normality like C<aov> does.

C<read_table> and C<write_table> now automatically set separators for C<.csv> files as C<,> and C<.tsv> files as C<"\t">, respectively, so these values no longer need to be specified separately from the file name.

=head2 0.06 2026-05-19 CDT

Changed compiler options so that Solaris will work

signed integers changed to unsigned in C<glm>

Added restrict keywords to C<power_t_test>, and made C<int> to C<unsigned int>

=head2 0.05 2026-05-08 CDT

Leak testing for C<sample>

removal of Data::Printer dependency for easier CPAN testing

switched several C<unsigned int> variable to C<I32> so that clang doesn't complain

added restrict keyword for C<sample>

=head2 0.04 2026-5-17 CDT

addition of C<sample> function

GNU source, to maximize compatibility and ease installation

removal of JSON dependency to ease installation

=head2 0.03 2026-5-13 CDT

Compatibility back to Perl 5.10

=head2 0.02 2026-5-7 CDT

back-compatible to Perl 5.10, instead of original 5.40, ensuring more people can use it

added var_test

mean, min, sum, median, var, and max die with undefined values, and print the offending indices

"group_stats" added to aov, for TukeyHSD in the future

"cor" dies when given data with standard deviation of 0

C<write_table> now has C<undef.val> option, which shows how undefined values are printed to tables, which is C<NA> by default.

=head1 COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself

=head1 AUTHOR

David E. Condon <dec986@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026-present by David E. Condon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
