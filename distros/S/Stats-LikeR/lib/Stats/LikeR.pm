#!/usr/bin/env perl
# ABSTRACT: Get basic statistical functions, like in R, but with Perl using XS for performance
require 5.010001;
use strict;
package Stats::LikeR;
our $VERSION = '0.3216';	# quoted: a bare version ending in 0, such as 0.320, is the number 0.32, which the dist would be named
require XSLoader;
use warnings FATAL => 'all';
use Exporter 'import';
use Scalar::Util qw(reftype looks_like_number);
XSLoader::load('Stats::LikeR', $VERSION);
our @EXPORT_OK = qw(h add_data age_standardize agg anova aoh2h aoh2hoa aoh2hoh aov assign auc auroc avals bedroc bfill binom_test cfilter chisq_test chunk col col2col colnames concat cmh_test cor cor_test cov csort density bw_nrd0 bw_nrd bw_ucv bw_bcv bw_sj dnorm cohen_d cramers_v eta_squared drop_cols drop_duplicates dropna epi_2x2 ffill fillna filter fisher_test get_union glm group_by h2aoh hoa2aoh hoa2hoh hoh2hoa hist interpolate intersection is_equivalent kruskal_test ks_test kurtosis Lonly ljoin lm map_cell matrix max mean median melt merge min mode ncol nrow oneway_test p_adjust pivot_table pnorm pt qt pchisq qchisq pf qf pbinom qnorm power_t_test predict prop_test mcnemar_test friedman_test dunn_test prcomp ptukey qcut qtukey quantile rank roc Ronly rbind rbinom read_table rename_cols rnorm rownames runif sample scale sd select_cols seq shapiro_test skew smd sum summary survfit logrank_test coxph table_one t_test transpose TukeyHSD uniq vals value_counts var var_test vif hosmer_lemeshow view wilcox_test write_table zerotrunc hurdle svyglm ivreg lmer);
our @EXPORT = @EXPORT_OK;

# File operations: failure reporting
#
# Before 0.316 this file ran under `use autodie ':default';', which replaced
# open() and close() with versions that threw an autodie::exception the moment
# either failed.  0.316 drops the dependency; _open_read() and _close() take its
# place, raising the same failure at the same points with the same text, so a
# caller's eval sees the message it has always seen.  The one visible difference
# is that $@ is now a plain string rather than an autodie::exception object,
# which nothing in the module, the tests or the documentation ever inspected.
#
# The wording is autodie::exception 2.37's: _format_open() (through
# _FORMAT_OPEN and _format_open_with_mode()) for the open, _format_close() for
# the close, each followed by add_file_and_line().  That last method is where the
# trailing newline comes from, and it is also what stops perl appending a second,
# differently punctuated " at ... line ..." of its own.

# autodie reported the caller's file and line, not its own, so build the message
# one frame up.
sub _io_die {
	my ($msg) = @_;
	my (undef, $file, $line) = caller(1);
	die sprintf("%s at %s line %d\n", $msg, $file, $line);
}

sub _open_read {
	my ($file) = @_;
	my $fh;
	open $fh, '<', $file
		or _io_die("Can't open '$file' for reading: '$!'");
	return $fh;
}

sub _close {
	my ($fh) = @_;
	close $fh or _io_die("Can't close($fh) filehandle: '$!'");
	return;
}

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

# Functions that share another function's section, either because they are the
# very same subroutine under a second name (rbind/concat) or because they are
# the internal engine behind a documented front end.
my %HELP_ALIAS = (
	rbind             => 'concat',
	bw_nrd0           => 'density',
	bw_nrd            => 'density',
	bw_ucv            => 'density',
	bw_bcv            => 'density',
	bw_sj             => 'density',
	map_cell          => 'assign',
	_hoa_assign       => 'assign',
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
	# The eight R distribution functions share one section, since what is
	# worth saying about tails, log_p and accuracy is the same for all of
	# them; pnorm and dnorm keep their own, older sections.
	qnorm             => 'Distribution functions',
	pt                => 'Distribution functions',
	qt                => 'Distribution functions',
	pchisq            => 'Distribution functions',
	qchisq            => 'Distribution functions',
	pf                => 'Distribution functions',
	qf                => 'Distribution functions',
	pbinom            => 'Distribution functions',
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
	_close($fh);
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

# POD extraction

our $POD_FILE;             # set only by t/help.t, to read a fixture

sub _pod_open {
	my $file = defined($POD_FILE) ? $POD_FILE : __FILE__;
	$file = $INC{'Stats/LikeR.pm'} unless defined($file) && -r $file;
	return undef unless defined($file) && -r $file;
	return _open_read($file);
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
	_close($fh);
	return @out;
}

# POD -> plain text

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

		# command paragraph
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

# =begin html / =begin text data blocks (and their =for spelling, which is what
# Pod::Weaver leaves behind in the built distribution).  The generated POD uses
# these for one thing only: parameter and output tables.  Render them as aligned
# plain text so the help shows the same information the HTML documentation does.

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
		# `for my $row (@$df)` walks the array in place; `my @rows = @$df`
		# flattens a copy of every row reference in the frame first, which on a
		# million-row AoH is eight megabytes of list that is read once and
		# thrown away.  Two loops, no copy.
		my %seen;
		if ($shape eq 'AoH') {
			for my $row (@$df) {
				next unless ref $row eq 'HASH';
				$seen{$_} = 1 for keys %$row;
			}
		} else {
			for my $row (values %$df) {
				next unless ref $row eq 'HASH';
				$seen{$_} = 1 for keys %$row;
			}
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

# The XSUBs _cols_select / _cols_drop / _cols_rename are PRIVATE -- do NOT
# export them.  (See select_drop_rename_cols.xs for the C side.)
#
# NAMING: `select` and `rename` are Perl core builtins, so exporting bare
# `select`/`rename` would shadow them in the caller.  The `_cols` suffix
# avoids that and reads as a trio.


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
	my %seen;                                   # no whole-frame list copy: see colnames
	if ($shape eq 'AoH') {
		for my $r (@$df)        { next unless ref $r eq 'HASH'; $seen{$_} = 1 for keys %$r }
	} else {
		for my $r (values %$df) { next unless ref $r eq 'HASH'; $seen{$_} = 1 for keys %$r }
	}
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
	my $one = sub {                                 # AoH / HoH row hashes
		my ($row) = @_;
		return unless ref $row eq 'HASH';
		my %vals;                                   # gather-then-set = swap-safe
		for my $o (keys %$map) {
			next unless exists $row->{$o};
			$vals{ $map->{$o} } = delete $row->{$o};
		}
		$row->{$_} = $vals{$_} for keys %vals;
	};
	if ($shape eq 'AoH') { $one->($_) for @$df }        # no list copy: see colnames
	else                 { $one->($_) for values %$df }
	return;
}

sub select_cols {# shape code passed to the XS: 1 = AoH, 2 = HoH, 3 = AoA
	my $df = _untied(shift);
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
	my $df = _untied(shift);
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
	$df = _untied($df) if defined wantarray;   # void context renames the frame itself
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
# agg / concat / rbind  --  additions to lib/Stats/LikeR.pm
# Splice these in after the dropna sub. Also add  agg concat rbind  to
# @EXPORT_OK. rbind is a true glob-alias synonym for concat.

# A tied frame, as a plain copy of it; anything else, as it is. Each pass over a
# tied frame -- _df_shape, _present_keys, the XS read -- FETCHes every row or
# column again, so a read-only function copies it once, here, and makes its
# passes over the copy. The copy holds the same row and column references.
# Only for functions that leave the frame unchanged: one that writes to it
# must write to the frame it was given.
sub _untied {
	my $df = shift;
	return { %$df } if ref $df eq 'HASH'  && tied %$df;
	return [ @$df ] if ref $df eq 'ARRAY' && tied @$df;
	return $df;
}

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

# agg($df, agg => { col => 'mean' | [ 'mean', 'sd', .. ] | \&code, .. }, %opts)
#
# Split-apply-combine over any of the four data-frame shapes.  With `by` it is
# the combine half of group_by (which only splits); without `by` it collapses
# the whole frame to a single row, like pandas df.agg(...).
#
# $df   : AoA | AoH | HoA | HoH.  For AoA the column identifiers in `by` and in
#         the `agg` spec are integer positions (negative from the end); for the
#         other three they are column names.  A column no row has dies.
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
#           A coderef is called as $code->(\@cells), in scalar context, with a
#           copy of every cell for that column in the group (undef included).
#   by   => $col | \@cols         optional grouping column(s).
#   skipna => 0|1                 default 1.  When 0, a numeric named aggregator
#           (mean median sum sd var min max mode) over a group with any undef
#           yields undef, matching pandas skipna=False; count/n/nunique/first/
#           last always ignore this flag.
#   sort => 0|1                   default 1.  Sort output groups by key, each
#           by column numerically if all its values look like numbers, else as
#           strings, undef last (see _sort_group_keys); 0 keeps first-seen order.
#   'output_type' => aoa|aoh|hoa|hoh    default: same family as $df.
#
# OUTPUT COLUMN ORDER is deterministic: the `by` columns in the given order,
# then the aggregated columns sorted (numerically for AoA integer columns, else
# as strings), each expanded over its aggregator list in the order supplied.  A
# column reduced by a single aggregator keeps its own name; with two or more, or
# when it is also a `by` column, it becomes "<col>_<func>" (e.g. age_mean,
# age_sd), a coderef's func being fn (fn1, fn2, .. for several).  A name
# generated twice dies, except for positional aoa output.  For hoh output the row label
# is the group value (multiple `by` columns joined with '.'), 'all' when there
# is no grouping, and made unique with a .N suffix on collision.
#
# Numeric aggregators need enough defined cells or the cell is undef: mean /
# median / sum / min / max need >= 1, sd / var need >= 2.  Ungrouped, a frame with
# no rows is still one row.  The original $df is never modified.  The split itself
# is the XS _agg_split(); see the comment above ag_set in LikeR.xs.
{
	my %AGG_MIN = (          # minimum defined count for the XS numeric reducers
		mean => 1, median => 1, sum => 1, min => 1, max => 1,
		sd   => 2, var    => 2,
	);
	# the reducers an undef poisons under skipna => 0 (pandas skipna=False)
	my %AGG_NUMERIC = map { $_ => 1 } qw(mean median sum sd var min max mode);
	my %AGG_OTHER   = map { $_ => 1 } qw(count n nunique first last mode);
	# reducers that stringify their cells: a cell they read is copied, not shared
	# with the caller's frame, because stringifying caches a PV on the SV
	my %AGG_STRINGIFY = ( mode => 1, nunique => 1 );

	sub _agg_reduce {
		my ($func, $raw, $def, $skipna) = @_;   # $raw, $def: arrayrefs (def excl. undef)
		# scalar: a coderef returning a list, or nothing, would otherwise shift
		# every later column of the row
		return scalar $func->($raw) if ref $func eq 'CODE';
		return _agg_reduce_named($func, $def, @$raw - @$def, $skipna);
	}

	# a named reducer over the defined cells $def, of which the group had $nna
	# more that were undef
	sub _agg_reduce_named {
		my ($func, $def, $nna, $skipna) = @_;
		# NA policy for numeric reducers when the caller asked for skipna => 0
		return undef if !$skipna && $nna && $AGG_NUMERIC{$func};
		if ($func eq 'count')   { return scalar @$def }
		if ($func eq 'n')       { return @$def + $nna }
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
		my $df = _untied(shift);
		die "agg: undefined data in first position\n" unless defined $df;
		my $shape = _df_shape($df, 'agg');
		die "agg: arguments after the data frame must be name => value pairs\n"
			if @_ % 2;
		my %arg = @_;
		my %known = ( agg => 1, by => 1, skipna => 1, sort => 1, 'output_type' => 1 );
		my @bad = sort grep { !$known{$_} } keys %arg;
		die "agg: unknown argument(s): @bad\n" if @bad;

		my $spec = $arg{agg};
		die "agg: an 'agg' spec (hashref of column => aggregator) is required\n"
			unless ref $spec eq 'HASH' and %$spec;

		my @by = !defined $arg{by}          ? ()
		       : ref $arg{by} eq 'ARRAY'    ? @{ $arg{by} }
		       :                              ( $arg{by} );
		die "agg: 'by' contains an undefined column\n" if grep { !defined } @by;
		my $skipna = exists $arg{skipna} ? ($arg{skipna} ? 1 : 0) : 1;
		my $dosort = exists $arg{sort}   ? ($arg{sort}   ? 1 : 0) : 1;
		my $otype  = defined $arg{'output_type'} ? lc $arg{'output_type'}
		           : lc $shape;
		my %ok_otype = ( aoa => 1, aoh => 1, hoa => 1, hoh => 1 );
		die "agg: output_type '$otype' isn't allowed (aoa, aoh, hoa, hoh)\n"
			unless $ok_otype{$otype};

		my @agg_cols = keys %$spec;
		{
			my $all_num = !grep { !looks_like_number($_) } @agg_cols;
			@agg_cols = $all_num ? sort { $a <=> $b } @agg_cols : sort @agg_cols;
		}
		if ($shape eq 'AoA') {           # positions; Perl's own negative indexing
			for my $c (@by, @agg_cols) {
				die "agg: AoA columns are integer positions, not '$c'\n"
					unless $c =~ /\A-?[0-9]+\z/;
			}
		} elsif ($shape eq 'HoA') {
			for my $c (@by, @agg_cols) {
				die "agg: column '$c' not found\n" unless exists $df->{$c};
				die "agg: column '$c' is not an ARRAY reference\n"
					unless ref $df->{$c} eq 'ARRAY';
			}
		}

# output plan: by-columns pass through, then each agg column with its
# aggregator list contiguous.  A single aggregator keeps the column name; two
# or more, or a column that is also a `by` column, become "<col>_<func>".  More
# than one coderef on a column are numbered fn1, fn2, ..; one is just fn.
		my %is_by = map { $_ => 1 } @by;
		my (@agg_plan, @how);    # [ col, [funcs], [out_names] ]; @how: _agg_split's modes
		for my $c (@agg_cols) {
			my $s = $spec->{$c};
			my @funcs = ref $s eq 'ARRAY' ? @$s : ($s);
			die "agg: empty aggregator list for column '$c'\n" unless @funcs;
			for my $f (@funcs) {
				next if ref $f eq 'CODE';
				die "agg: aggregator for column '$c' must be a name or a coderef\n"
					if !defined $f || ref $f;
				die "agg: unknown aggregator '$f'\n"
					unless exists $AGG_MIN{$f} || $AGG_OTHER{$f};
			}
			my $ncode = grep { ref $_ eq 'CODE' } @funcs;
			my $ci    = 0;
			my $multi = @funcs > 1 || $is_by{$c};
			my @names = map {
				my $l = ref $_ ne 'CODE' ? $_ : $ncode > 1 ? 'fn' . ++$ci : 'fn';
				$multi ? "${c}_${l}" : $c;
			} @funcs;
			push @agg_plan, [ $c, \@funcs, \@names ];
			push @how, ( grep { ref $_ eq 'CODE' } @funcs )   ? 0  # cells incl. undef, copied
			         : ( grep { $AGG_STRINGIFY{$_} } @funcs ) ? 1  # defined cells, copied
			         :                                          2; # defined cells, shared
		}
		my @out_names = ( @by, map { @{ $_->[2] } } @agg_plan );
		if ($otype ne 'aoa') {           # aoa is positional: a repeat costs nothing
			my (%seen, @dup);
			for my $n (@out_names) { push @dup, $n if $seen{$n}++ == 1 }
			die "agg: output column name(s) generated twice: @dup\n" if @dup;
		}

# split, in XS: every row's group, and each aggregated cell dropped straight
# into its group's array -- every cell for a column a coderef reads, only the
# defined ones otherwise, with the undef cells counted instead
		my ($src, $code) = $shape eq 'AoA' ? ( $df, 3 )
		                 : $shape eq 'AoH' ? ( $df, 1 )
		                 : $shape eq 'HoA' ? ( $df, 4 )
		                 : ( [ @{$df}{ sort keys %$df } ], 1 );   # HoH: its rows, key order
		my ($groups, $seen) = @{ _agg_split($src, $code, [ @by ], [ @agg_cols ], \@how) };
		if (@$groups) {                  # a frame with no rows has no columns to miss
			my @all = ( @by, @agg_cols );
			for my $j (0 .. $#all) {
				die "agg: column '$all[$j]' not found\n" unless $seen->[$j];
			}
		} elsif (!@by) {                 # ungrouped: always one row, as pandas df.agg
			push @$groups, [ [], [ (0) x @agg_cols ], map { [] } @agg_cols ];
		}

		my @order = 0 .. $#$groups;
		if ($dosort && @by && @order > 1) {
			my %repr = map { $_ => $groups->[$_][0] } @order;
			@order = @{ _sort_group_keys(\@order, \%repr) };
		}

# combine + materialise straight into the requested shape
		my (@aoa_rows, @aoh_rows, %hoa, %hoh, %seen_label);
		if ($otype eq 'hoa') { $hoa{$_} = [] for @out_names }

		for my $gi (@order) {
			my ($repr, $nna, @cells) = @{ $groups->[$gi] };
			$groups->[$gi] = undef;      # this group's cells go once it is reduced
			my @vals = @$repr;           # by-column values, in order
			for my $j (0 .. $#agg_plan) {
				my ($c, $funcs) = @{ $agg_plan[$j] };
				my $cells = $cells[$j];
				my $def = $how[$j] || !$nna->[$j] ? $cells : [ grep { defined } @$cells ];
				for my $f (@$funcs) {
					if (ref $f eq 'CODE') {
						push @vals, scalar $f->($cells);   # see _agg_reduce
						next;
					}
					my $v = eval { _agg_reduce_named($f, $def, $nna->[$j], $skipna) };
					if (!defined $v && $@) {
						my $where = @by
							? 'group (' . join(', ', map {
								"$by[$_] = " . (defined $repr->[$_] ? "'$repr->[$_]'" : 'undef')
							  } 0 .. $#by) . ')'
							: 'the whole frame';
						die "agg: $f of column '$c' over $where: $@";
					}
					push @vals, $v;
				}
			}
			if ($otype eq 'aoa') {
				push @aoa_rows, \@vals;
			} elsif ($otype eq 'aoh') {
				my %h; @h{ @out_names } = @vals; push @aoh_rows, \%h;
			} elsif ($otype eq 'hoa') {
				push @{ $hoa{ $out_names[$_] } }, $vals[$_] for 0 .. $#out_names;
			} else { # hoh
				my $label = @by
					? join('.', map { defined $_ ? $_ : '' } @$repr)
					: 'all';
				my $uniq = $label; my $j = 0;
				while (exists $seen_label{$uniq}) { $uniq = $label . '.' . (++$j) }
				$seen_label{$uniq} = 1;
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
# It is called in list context on every row and returns the new cell value; a
# list of more than one value from row 0 is the whole column instead.
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
	my $shape;                                      # 'AoH', 'HoA' or 'HoH'
	if ($r eq 'ARRAY') {
		$shape = 'AoH';
	} elsif ($r eq 'HASH') {
		# Every value is looked at, not just the first one values() yields: a
		# HoA may carry scalar (or undef) entries, which the row view passes
		# through unchanged, and deciding on whichever value came first made the
		# same frame work or die from one run to the next with hash order.
		#
		# For a HoH the same pass is the row check: every value has to be a
		# hash, and counting them here saves a second pass over the rows, which
		# on 200000 rows cost 0.039s -- a fifth of the whole call.
		# A statement-modifier count runs in 0.013s on 200000 rows, against 0.019s
		# for the same test written as a loop with if/elsif.
		my %kind;                                   # ref() of each value => how many
		$kind{ ref $_ }++ for values %$df;
		my $saw_arr = $kind{ARRAY} || 0;
		my $n_hash  = $kind{HASH}  || 0;
		die "$current_sub: hashref mixes array and hash values (ambiguous HoA/HoH)"
			if $saw_arr and $n_hash;
		die "$current_sub: hashref holds no ARRAY (HoA) or HASH (HoH) values"
			if %$df and not $saw_arr and not $n_hash;
		$shape = $n_hash ? 'HoH' : 'HoA';        # empty hash -> HoA
		if ($n_hash and @_ and $n_hash != keys %$df) {
			# Name the first bad row in visiting (sorted) order, as the row loops would.
			for my $k (sort keys %$df) {
				die "$current_sub: row '$k' is not a hashref" unless ref $df->{$k} eq 'HASH';
			}
		}
	} else {
		die "$current_sub: data frame must be an arrayref (AoH) or hashref (HoA/HoH)";
	}

	# Row count. For a HoA it is the longest column; with no column at all yet
	# (an empty hash) it is undef until the first arrayref value fixes it.
	my (@rk, $n);                                   # @rk: HoH row keys, in visiting order
	if ($shape eq 'AoH') {
		$n = @$df;
	} elsif ($shape eq 'HoH') {
		@rk = sort keys %$df;
		$n  = @rk;
	} else {
		for my $v (values %$df) {
			next unless ref $v eq 'ARRAY';
			$n = @$v if not defined $n or @$v > $n;
		}
	}

	# Everything that can be checked before the first cell is written is checked
	# here, so that a bad row or a bad third pair cannot leave the first two
	# applied and the frame half-modified.
	my %hoa_col;                                    # HoA: columns that exist by each pair
	if ($shape eq 'HoA') {
		$hoa_col{$_} = 1 for grep { ref $df->{$_} eq 'ARRAY' } keys %$df;
	}
	for (my $p = 0; $p < @_; $p += 2) {
		my ($name, $spec) = @_[$p, $p + 1];
		my $sref = ref $spec;
		if ($sref eq 'Stats::LikeR::map_cell') {
			die "$current_sub: map_cell target column '$name' must already exist as an ARRAY ref\n"
				if $shape eq 'HoA' and not $hoa_col{$name};
			next;
		}
		die "$current_sub: value for '$name' must be a CODE or ARRAY ref"
			unless $sref eq 'CODE' or $sref eq 'ARRAY';
		if ($sref eq 'ARRAY') {
			$n = @$spec unless defined $n;
			die "$current_sub: column '$name' has " . @$spec . " values but data frame has $n rows"
				unless @$spec == $n;
		}
		$n = 0 unless defined $n;                    # a coderef on a column-less HoA sees no rows
		$hoa_col{$name} = 1;
	}
	$n = 0 unless defined $n;
	if ($shape ne 'HoA' and @_) {
		# A HoH's rows were checked by the shape scan above.
		if ($shape eq 'AoH') {
			for my $i (0 .. $n - 1) {
				die "$current_sub: row $i is not a hashref" unless ref $df->[$i] eq 'HASH';
			}
		}
	}

	# One save of $_ for the whole call; each row below only stores into it.
	# Assigning to the localized $_ copies the row reference, so a block that
	# writes to $_ changes nothing in $df.
	local $_;

	# A coderef is called in list context for every row, row 0 included. Row 0
	# used to be called in list context (to tell a whole-column return from a
	# per-row one) and every later row in scalar context, so any expression that
	# answers differently in the two -- a match with captures, a bare match, an
	# array -- gave row 0 one kind of value and the rest another:
	# sub { $_->{s} =~ /(\d+)/ } stored the digits in row 0 and 1 everywhere else.
	#
	# The store is a list assignment, (($cell) = $spec->(...)), whose value in
	# scalar context is how many values the call returned. That keeps list
	# context for the price of one comparison: on 200000 rows it ran 7% behind
	# the old scalar-context store, which hoisting `local $_` out of the row
	# loop (8%) more than pays for.
	my $too_many = sub {
		my ($name, $got, $i) = @_;
		die "$current_sub: '$name' returned $got values for row $i; a per-row coderef "
		  . "must return one value per row (a whole-column list is told apart on row 0)";
	};

	if ($shape ne 'HoA') {                          # ----- AoH / HoH -----
		my $is_hoh = $shape eq 'HoH';
		while (@_) {
			my ($name, $spec) = (shift, shift);
			my $sref = ref $spec;
			if ($sref eq 'Stats::LikeR::map_cell') {   # in-place per-cell edit; $_ = current cell
				my $code = $spec->{code};
				for my $i (0 .. $n - 1) {
					my $row = $is_hoh ? $df->{ $rk[$i] } : $df->[$i];
					$_ = $row->{$name};
					next unless defined $_;   # undef cells pass through untouched (undef in -> undef out)
					$is_hoh ? $code->($row, $i, $rk[$i]) : $code->($row, $i);
					$row->{$name} = $_;
				}
				next;
			}
			if ($sref eq 'ARRAY') {                 # ready-made column
				if ($is_hoh) { $df->{ $rk[$_] }{$name} = $spec->[$_] for 0 .. $n - 1 }
				else         { $df->[$_]{$name}        = $spec->[$_] for 0 .. $n - 1 }
				next;
			}
			next unless $n;                         # empty frame: nothing to compute

			my $row0 = $is_hoh ? $df->{ $rk[0] } : $df->[0];
			$_ = $row0;
			my @out = $is_hoh ? $spec->($row0, 0, $rk[0]) : $spec->($row0, 0);
			if (@out > 1) {                         # whole-column list (e.g. rank())
				die "$current_sub: column '$name' produced " . @out . " values but data frame has $n rows"
					unless @out == $n;
				if ($is_hoh) { $df->{ $rk[$_] }{$name} = $out[$_] for 0 .. $n - 1 }
				else         { $df->[$_]{$name}        = $out[$_] for 0 .. $n - 1 }
				next;
			}
			$row0->{$name} = $out[0];               # per-row: row 0 already computed
			# Two copies of the loop so the hot path does not test $is_hoh per row.
			if ($is_hoh) {
				for my $i (1 .. $n - 1) {
					my $row = $df->{ $rk[$i] };
					$_ = $row;
					my $got = (($row->{$name}) = $spec->($row, $i, $rk[$i]));
					$too_many->($name, $got, $i) if $got > 1;
				}
			} else {
				for my $i (1 .. $n - 1) {
					my $row = $df->[$i];
					$_ = $row;
					my $got = (($row->{$name}) = $spec->($row, $i));
					$too_many->($name, $got, $i) if $got > 1;
				}
			}
		}
		return $df;
	}

	# ----- HoA -----
	# The block sees each row as a hash built from the columns. Array columns
	# supply cell $i; any other value (a scalar, undef) is passed through as is.
	#
	# _hoa_assign (LikeR.xs) runs the loop with one view whose values alias the
	# frame's cells, so a write through $_->{col} lands in the frame, as it does
	# for an AoH or HoH. A tied frame or column keeps the perl loop below, which
	# hands the block copies: aliasing a tied element would alias the proxy SV
	# FETCH returns, not the element.
	my $tied = tied(%$df)
		|| grep { ref $df->{$_} eq 'ARRAY' and tied @{ $df->{$_} } } keys %$df;
	my $snapshot = sub {
		my (@akeys, @acols, @skeys, @svals);
		for my $k (keys %$df) {
			my $c = $df->{$k};
			if (ref $c eq 'ARRAY') { push @akeys, $k; push @acols, $c }
			else                   { push @skeys, $k; push @svals, $c }
		}
		return (\@akeys, \@acols, \@skeys, \@svals);
	};
	while (@_) {
		my ($name, $spec) = (shift, shift);
		my $sref = ref $spec;
		if ($sref eq 'ARRAY') {
			$df->{$name} = [ @$spec ];   # copied, so the caller's array stays theirs
			next;
		}
		if (not $n and $sref eq 'CODE') { $df->{$name} = []; next }

		if (not $tied) {
			if ($sref eq 'Stats::LikeR::map_cell') {
				_hoa_assign($df, $name, $spec->{code}, $n, 1);
				next;
			}
			my ($whole, $col) = _hoa_assign($df, $name, $spec, $n, 0);
			die "$current_sub: column '$name' produced " . @$col . " values but data frame has $n rows"
				if $whole and @$col != $n;
			$df->{$name} = $col;
			next;
		}

		# The perl loop, for a tied frame only (see $tied above).
		my ($akeys, $acols, $skeys, $svals) = $snapshot->();
		if ($sref eq 'Stats::LikeR::map_cell') {   # in-place per-cell edit; $_ = current cell
			my $code = $spec->{code};
			my $tgt  = $df->{$name};
			# One row view, refilled per row, and only for the rows the block
			# will actually see.
			#
			# Assembling it was the whole cost of the call: on a 64-column frame
			# of 20000 rows, a target column that is entirely undef -- so the
			# block never runs once -- still took 0.161s of the 0.165s a full
			# pass took, every bit of it spent building views that were then
			# thrown away unread, because the "is this cell undef" test sat after
			# the build instead of before it.
			#
			# The key set is the same for every row, so the hash is refilled
			# rather than reallocated. The block therefore sees one hash for the
			# whole pass instead of a fresh one per row, which is the shape the
			# other two frame layouts already have: the AoH and HoH branches above
			# hand the block the row hash itself, not a copy of it.
			my %view;
			for my $i (0 .. $n - 1) {
				$_ = $tgt->[$i];
				next unless defined $_;   # undef cells pass through untouched (undef in -> undef out)
				@view{@$akeys} = map { $_->[$i] } @$acols;
				@view{@$skeys} = @$svals;
				$code->(\%view, $i);
				$tgt->[$i] = $_;
			}
			next;
		}

		# Unlike the map_cell view above, this one is a fresh hash every row:
		# a plain coderef may keep the hash it is given (return it, push it
		# somewhere), and a reused one would then change under it.
		my %v0;
		@v0{@$akeys} = map { $_->[0] } @$acols;
		@v0{@$skeys} = @$svals;
		$_ = \%v0;
		my @out = $spec->(\%v0, 0);
		if (@out > 1) {                     # whole-column list
			die "$current_sub: column '$name' produced " . @out . " values but data frame has $n rows"
				unless @out == $n;
			$df->{$name} = \@out;           # @out is this pair's own array: no second copy
			next;
		}
		my @new;
		$#new = $n - 1;                     # preallocate
		$new[0] = $out[0];
		for my $i (1 .. $n - 1) {
			my %view;
			@view{@$akeys} = map { $_->[$i] } @$acols;
			@view{@$skeys} = @$svals;
			$_ = \%view;
			my $got = (($new[$i]) = $spec->(\%view, $i));
			$too_many->($name, $got, $i) if $got > 1;
		}
		$df->{$name} = \@new;
	}
	return $df;
}

sub chunk {
	my ($aref, @rest) = @_;
	die "chunk: first argument must be an ARRAY reference\n"
		unless ref $aref eq 'ARRAY';
	# Own the message for an odd argument list.  Falling straight into a hash
	# assignment left perl to report it, and under `warnings FATAL => 'all'`
	# chunk($aref, 2) died as "Odd number of elements in hash assignment at
	# LikeR.pm line 1686" -- naming neither chunk nor the option it wanted.
	die "chunk: arguments after the array reference must be name => value "
	  . "pairs; pass exactly one of size => N or parts => K\n"
		if @rest % 2;
	my %opt = @rest;

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

# filter DSL: col() builds a predicate via overloading (pure Perl)
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

	#AoH
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

	#HoA vs HoH
	if ($r eq 'HASH') {
		my ($saw_arr, $saw_hash) = (0, 0);
		for my $v (values %$df) {
			next unless ref $v;
			$saw_arr++	if ref $v eq 'ARRAY';
			$saw_hash++ if ref $v eq 'HASH';
		}
		die "dropna: hashref mixes array and hash values (ambiguous HoA/HoH)\n"
			if $saw_arr and $saw_hash;

		#HoH
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

		#HoA (also the empty-hash fallthrough)
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
	my $df = _untied(shift);
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

	# resolve the data shape into (label, numeric-vector) series
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

	# compute the statistics grid
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

# .xlsx support (pure Perl, no CPAN deps)
# An .xlsx file is a ZIP archive of XML parts. IO::Uncompress::Unzip is a core
# module, so we can pull the parts out and parse the (very regular) XML with
# regexes, then feed rows to read_table's callback exactly like _parse_csv_file
# does. A workbook with more than one worksheet is read into a hash keyed by
# sheet name (see read_table). Limitations: dates/times come back as their raw
# serial numbers (no style-based formatting); shared-string rich-text runs are
# concatenated.

# The decompressed bytes of a named archive member as a SCALAR REFERENCE, or
# undef if the member is absent.
#
# The reference is the point.  Returning the string itself costs a full copy of
# it -- perl cannot hand back the pad slot of a lexical, so `return $content'
# copies, and on the 36 MB worksheet part of a 21,845 x 50 workbook that was
# 34 MB of peak RSS for nothing: 82.4 MB against 48.5 MB for the reference, and
# 81 MB still resident afterwards against 13 MB, the difference being heap the
# allocator never gave back.  Every caller dereferences; `$$ws' on an argument
# list pushes the SV itself, so the part reaches the XS parser without a copy
# either.
#
# _unzip_member_fast() handles the archives Excel, LibreOffice and openpyxl
# actually write; the loop below is the fallback for everything else, and is
# what every member went through up to 0.316.
#
# The read appends onto the end of $content rather than going through a second
# scalar: IO::Uncompress::Base::read() turns its truncating substr() into a
# no-op when the offset is already the buffer's length, so the string is
# extended in place instead of being copied by a concatenation. On the 36 MB
# worksheet part of a 21,845 x 50 workbook that is 0.171 s against 0.243 s for
# `$content .= $buf`, over three runs each in a fresh process, and it leaves
# behind none of the ~25 MB of realloc slack the concatenation did.
# Do NOT reach for BlockSize => 1<<20 instead: measured at 0.262 s on the same
# part against 0.174 s for the default. (The 2.08 s this comment used to quote
# does not reproduce here, but its conclusion does.)
sub _unzip_member {
	my ($file, $member) = @_;
	my ($handled, $ref) = _unzip_member_fast($file, $member);
	return $ref if $handled;
	require IO::Uncompress::Unzip;
	my $z = IO::Uncompress::Unzip->new($file, Name => $member)
		or return undef;
	my $content = '';
	my ($off, $n) = (0, 0);
	while (($n = $z->read($content, 1 << 20, $off)) > 0) { $off += $n }
	$z->close;
	return \$content;
}

# The same member, read straight out of the archive with Compress::Raw::Zlib
# instead of through IO::Uncompress::Unzip.
#
# Returns a two-element list: (1, \$bytes) for a member it read, (1, undef) for
# an archive it understood that does not hold the member, and (0, undef) for
# anything it declines -- at which point _unzip_member falls back and the old
# path decides. Declining is never an error: this reads the central directory
# and one deflate stream and nothing else, and hands everything beyond that to
# the module that has been ported to all of it.
#
# Why bother: with the worksheet parser in XS since 0.316, decompression is what
# a read of an .xlsx now spends its time on -- 0.239 s of the 0.413 s a
# 21,845 x 50 workbook takes, against 0.015 s to parse its 117,870 shared
# strings. IO::Uncompress::Unzip needs 0.174 s for the 36 MB worksheet part
# where inflating it directly needs 0.052 s, plus 0.004 s to read the 5.5 MB of
# compressed bytes.
#
# Most of that gap is one thing. Unzip.pm's ckParams() sets `crc32 => 1'
# unconditionally ("unzip always needs crc32"), so every byte is run through
# Compress::Raw::Zlib::crc32() -- 0.076 s on this part, more than the inflate
# itself -- and then the comparison against the stored CRC happens only under
# `Strict', which defaults to 0. The check is paid for and not made. This path
# does not compute it either, which is the same answer for the same money;
# asking Inflate for -CRC32 => 1 costs the identical 0.076 s (it is the same
# per-chunk call), so turning it on here would want `Strict'-like behaviour --
# a croak on mismatch -- to be worth anything, and that is a change in what
# read_table does with a damaged file rather than a speed decision.
#
# Bufsize 1<<16: 0.052 s against 0.063 s at the 4 KB default on that part, and
# flat from there (1<<18 through 1<<22 all measure 0.052 s).
#
# Layout constants are ECMA-376's container, i.e. PKWARE's APPNOTE.TXT 6.3.10:
# section 4.3.16 for the end-of-central-directory record, 4.3.12 for a central
# directory entry, 4.3.7 for a local file header.
sub _unzip_member_fast {
	my ($file, $member) = @_;
	require Compress::Raw::Zlib;
	my $fh;
	open $fh, '<', $file or return (0, undef);
	binmode $fh;
	my $size = -s $fh;
	return (0, undef) unless defined $size && $size >= 22;

	# The EOCD is 22 bytes plus a comment of up to 65535, so it begins no
	# earlier than 65557 from the end. Its signature can also occur inside the
	# comment (or inside compressed data, for an archive with no comment), so
	# a candidate counts only when the record it starts ends exactly at the end
	# of the file.
	my $want = $size < 65557 ? $size : 65557;
	seek $fh, $size - $want, 0 or return (0, undef);
	my $tail = '';
	return (0, undef) unless read($fh, $tail, $want) == $want;
	my ($ncd, $cdsz, $cdoff);
	my $at = length($tail) - 22;
	while ($at >= 0) {
		$at = rindex($tail, "PK\5\6", $at);
		last if $at < 0;
		my ($d1, $d2, $nd, $nt, $sz, $off, $cmt)
			= unpack('x' . ($at + 4) . ' v v v v V V v', $tail);
		if ($at + 22 + $cmt == length $tail) {
			# a split archive has its directory somewhere this cannot reach
			return (0, undef) if $d1 || $d2 || $nd != $nt;
			# the zip64 sentinels: the real values are in a record this does
			# not read, so hand the whole archive back
			return (0, undef)
				if $nt == 0xFFFF || $sz == 0xFFFFFFFF || $off == 0xFFFFFFFF;
			($ncd, $cdsz, $cdoff) = ($nt, $sz, $off);
			last;
		}
		$at--;
	}
	return (0, undef) unless defined $cdoff;
	return (0, undef) if $cdoff + $cdsz > $size;
	seek $fh, $cdoff, 0 or return (0, undef);
	my $cd = '';
	return (0, undef) unless read($fh, $cd, $cdsz) == $cdsz;

	# Walk the directory to the member. Entries are in the order the local
	# headers are, so stopping at the first match is what Unzip.pm's own
	# sequential scan would have found.
	my ($gp, $method, $csz, $usz, $lho);
	my $p = 0;
	for (my $i = 0; $i < $ncd; $i++) {
		return (0, undef) if $p + 46 > $cdsz;
		return (0, undef) unless substr($cd, $p, 4) eq "PK\1\2";
		my ($g, $m, $cs, $us, $nl, $el, $cl, $lo)
			= unpack('x' . ($p + 8) . ' v v x8 V V v v v x8 V', $cd);
		return (0, undef) if $p + 46 + $nl + $el + $cl > $cdsz;
		if (substr($cd, $p + 46, $nl) eq $member) {
			($gp, $method, $csz, $usz, $lho) = ($g, $m, $cs, $us, $lo);
			last;
		}
		$p += 46 + $nl + $el + $cl;
	}
	return (1, undef) unless defined $lho;	# the archive has no such member

	# bit 0 is encryption and bit 6 strong encryption; bit 3 only moves the
	# sizes into a trailing descriptor, and the directory's copies (which is
	# what is read here) are authoritative either way.
	return (0, undef) if $gp & 0x41;
	return (0, undef) if $method != 0 && $method != 8;	# 0 stored, 8 deflate
	return (0, undef) if $csz == 0xFFFFFFFF || $usz == 0xFFFFFFFF
	                  || $lho == 0xFFFFFFFF;		# zip64 again
	return (0, undef) if $lho + 30 > $size;

	# The local header repeats the name and carries its own extra field, which
	# need not be the directory's: only its two lengths are read here, to step
	# over them to the data.
	seek $fh, $lho, 0 or return (0, undef);
	my $lh = '';
	return (0, undef) unless read($fh, $lh, 30) == 30;
	return (0, undef) unless substr($lh, 0, 4) eq "PK\3\4";
	my ($lnl, $lel) = unpack('x26 v v', $lh);
	my $data = $lho + 30 + $lnl + $lel;
	return (0, undef) if $data + $csz > $size;
	seek $fh, $data, 0 or return (0, undef);
	my $comp = '';
	return (0, undef) unless read($fh, $comp, $csz) == $csz;
	close $fh or return (0, undef);

	if ($method == 0) {
		return (0, undef) unless length($comp) == $usz;
		return (1, \$comp);
	}
	my ($inf, $st) = Compress::Raw::Zlib::Inflate->new(
		-WindowBits => -Compress::Raw::Zlib::MAX_WBITS(),
		-Bufsize    => 1 << 16);
	return (0, undef) unless $inf;
	my $out = '';
	# inflate() eats $comp as it goes, so the two are never both whole
	$st = $inf->inflate($comp, $out);
	return (0, undef) unless $st == Compress::Raw::Zlib::Z_STREAM_END()
	                      || $st == Compress::Raw::Zlib::Z_OK();
	return (0, undef) unless length($out) == $usz;
	return (1, \$out);
}

# Decode the five predefined XML entities plus numeric character references,
# the latter as UTF-8 bytes so the result stays byte-consistent with the rest of
# the file (which we read, and return, as raw UTF-8 bytes). The decoding is
# xlsx_xml_uncat() in LikeR.xs, the one the cells go through: up to 0.320 this
# was five substitutions in a row, and a reference the first one produced was
# decoded again by a later one, so "&#38;lt;" came back as "<".
sub _xml_unescape {
	my ($s) = @_;
	return $s unless defined $s && index($s, '&') >= 0;
	return _xml_unescape_xs($s);
}

# The start tags of every element called $local in $xml, under any namespace
# prefix, as their attribute runs. Comments are taken out first, so that a
# commented-out <sheet> or <Relationship> is not read as one, and a tag is
# matched quote by quote, so that a '>' inside an attribute value -- which XML
# allows unescaped -- does not end it.
#
# Both this and _xml_attr() compile their pattern once per name and keep it.
# Interpolated into the match, it was recompiled on every call (the callers
# alternate names), and perl 5.32's regcomp leaks the inversion lists it builds
# for \s and \w on each compile: 0.3214 failed 14 leak subtests on a 5.32.1
# smoker that no perl in the local matrix could reproduce. The keys are the
# literal names the xlsx reader passes, so the caches stay a few entries long,
# and the qr// is evaluated only on a miss, never inside a warmed leak check
# (5.10.0's pp_qr() leaks an SV each time one is).
my (%xml_tag_re, %xml_attr_re);
sub _xml_start_tags {
	my ($xml, $local) = @_;
	$xml =~ s/<!--.*?-->//gs if index($xml, '<!--') >= 0;
	my $re = $xml_tag_re{$local}
		||= qr{<(?:[\w.-]+:)?\Q$local\E\b((?:[^>"']|"[^"]*"|'[^']*')*)>};
	my @tags;
	while ($xml =~ /$re/g) {
		(my $at = $1) =~ s{/\z}{};	# the "/" of a self-closing tag
		push @tags, $at;
	}
	return @tags;
}

# The value of the attribute whose name matches $name (a pattern, so that the
# r:id of a <sheet> can be found under whatever prefix its writer bound) in an
# attribute run from _xml_start_tags, or undef. XML lets a value be quoted with
# '"' or with "'", and up to 0.3213 only the first was read: a workbook written
# with single quotes lost every sheet name, and its sheets were then read by
# file position rather than through their relationships.
sub _xml_attr {
	my ($attrs, $name) = @_;
	my $re = $xml_attr_re{$name}
		||= qr/(?:\A|\s)$name\s*=\s*(?:"([^"]*)"|'([^']*)')/;
	return undef unless $attrs =~ $re;
	return defined $1 ? $1 : $2;
}

# A relationship's Target as the name of the archive member it points at. A
# target is a URI reference resolved against the part that holds the
# relationship (ECMA-376 Part 2, Open Packaging Conventions), so it is relative
# to xl/, where workbook.xml lives, unless it starts with "/", which makes it
# relative to the package root; "." and ".." segments are resolved. A
# target that already starts with "xl/" is taken as rooted, which is how this
# has always read one.
sub _xlsx_part_path {
	my ($tg) = @_;
	my $path = $tg =~ s{\A/+}{} ? $tg : $tg =~ m{\Axl/} ? $tg : "xl/$tg";
	my @seg;
	for my $s (split m{/}, $path) {
		next if $s eq '' || $s eq '.';
		if ($s eq '..') { pop @seg; next }
		push @seg, $s;
	}
	return join '/', @seg;
}

# The relationships of xl/workbook.xml, from xl/_rels/workbook.xml.rels:
# { target => { $id => $member, ... }, sst => $member or undef }. 'sst' is the
# shared-string part, found by its relationship Type -- the transitional
# .../officeDocument/2006/relationships/sharedStrings or the strict
# .../officeDocument/relationships/sharedStrings, both ending in
# "/sharedStrings" -- rather than by its usual name: the name is the writer's
# choice, and up to 0.3213 a workbook that stored the part as
# xl/SharedStrings.xml read every string cell as empty.
sub _xlsx_rels {
	my ($file) = @_;
	my (%target, $sst);
	my $rels = _unzip_member($file, 'xl/_rels/workbook.xml.rels');
	if (defined $rels) {
		for my $at (_xml_start_tags($$rels, 'Relationship')) {
			my $tg = _xml_attr($at, 'Target');
			next unless defined $tg;
			$tg = _xlsx_part_path(_xml_unescape($tg));
			my $id   = _xml_attr($at, 'Id');
			my $type = _xml_attr($at, 'Type');
			$target{$id} = $tg if defined $id;
			$sst = $tg if !defined $sst && defined $type && $type =~ m{/sharedStrings\z};
		}
	}
	return { target => \%target, sst => $sst };
}

# Shared strings (optional part): each <si> may hold several <t> runs, which
# are concatenated. Returns an arrayref indexed by shared-string id. The parse
# is xlsx_sst_parse() in LikeR.xs; the two nested regexes it replaces cost
# 0.205 s on an 8 MB table of 117,870 strings. $rels, from _xlsx_rels(), says
# where the part is; a workbook whose relationships do not name one is tried at
# xl/sharedStrings.xml, the name Excel gives it, as it always was.
sub _xlsx_shared_strings {
	my ($file, $rels) = @_;
	$rels ||= _xlsx_rels($file);
	my $ss = _unzip_member($file, $rels->{sst} // 'xl/sharedStrings.xml');
	return defined $ss ? _xlsx_sst_xs($$ss) : [];
}

# The workbook's worksheets, in document order, as a list of
# { name => $sheet_name, path => 'xl/worksheets/sheetN.xml' } hashrefs. The path
# is resolved through workbook.xml.rels ($rels, from _xlsx_rels(), read here
# when it is not given); a sheet with no resolvable relationship (or a workbook
# with no metadata at all) falls back to a positional sheetN.xml.
#
# An element may carry a namespace prefix -- <x:sheet>, as the Open XML SDK
# writes them -- and the relationship id is matched by its local name, since
# the prefix bound to the relationships namespace is the writer's choice. See
# xlsx_ns_prefix() in LikeR.xs for the worksheet side of the same thing.
sub _xlsx_sheets {
	my ($file, $rels) = @_;
	$rels ||= _xlsx_rels($file);
	my $target = $rels->{target};
	my @sheets;
	if (defined(my $wb = _unzip_member($file, 'xl/workbook.xml'))) {
		for my $at (_xml_start_tags($$wb, 'sheet')) {
			my $name = _xml_attr($at, 'name');
			my $rid  = _xml_attr($at, '[\w.-]+:id');
			push @sheets, {
				name => defined $name ? _xml_unescape($name) : undef,
				path => defined $rid ? $target->{$rid} : undef,
			};
		}
	}
	@sheets = ({ name => undef, path => undef }) unless @sheets;	# no metadata
	# any sheet still lacking a path falls back to its positional worksheet file
	$sheets[$_]{path} //= 'xl/worksheets/sheet' . ($_ + 1) . '.xml'
		for 0 .. $#sheets;
	return \@sheets;
}

# Resolve a 'sheet' argument (undef -> first; a name; or a 1-based index) to one
# of the hashrefs from _xlsx_sheets, dying with a clear message on a bad request.
#
# A name is tried first. A workbook read whole comes back keyed by sheet name,
# and up to 0.3213 any all-digit 'sheet' was an index, so of sheets "2024" and
# "2023" neither key could be asked for again ("sheet index 2023 is out of
# range"), and with sheets "2" and "1", sheet => '1' quietly returned "2". The
# name is compared as bytes (see _as_bytes), which is how it was read.
sub _xlsx_choose_sheet {
	my ($file, $sheets, $sheet) = @_;
	return $sheets->[0] unless defined $sheet;
	my $want = _as_bytes($sheet);
	my ($chosen) = grep { defined $_->{name} && $_->{name} eq $want } @$sheets;
	return $chosen if $chosen;
	if ($want =~ /\A[0-9]+\z/) {
		die "read_table: sheet index $want is out of range (1..${\ scalar @$sheets}), "
		  . "and no sheet is named '$want', in $file\n"
			if $want < 1 || $want > @$sheets;
		return $sheets->[$want - 1];
	}
	die "read_table: sheet '$want' not found in $file (have: "
		. join(', ', map { defined $_->{name} ? "'$_->{name}'" : '?' } @$sheets)
		. ")\n";
}

# Parse one worksheet, invoking $callback->(\@fields) once per non-empty row
# (header row included) with all rows padded to the same width -- the same
# contract _parse_csv_file offers read_table's callback, and the same $plan
# fast path: once read_table has filled the plan in, the rows are assembled in
# XS and the callback is not called again. $sst is the shared strings arrayref
# from _xlsx_shared_strings.
#
# The part is decompressed here and parsed by xlsx_ws_scan() in LikeR.xs, which
# is also where the reason it is not done in perl any more is written down.
sub _parse_xlsx_sheet {
	my ($file, $sst, $path, $callback, $plan) = @_;
	my $ws = _unzip_member($file, $path);
	die "read_table: could not read worksheet '$path' in $file\n"
		unless defined $ws;
	_parse_xlsx_sheet_xs($$ws, $sst, $callback, $plan);
	return;
}

# True when a sep regex is pandas' whitespace-delimited spelling. pandas reads
# sep=r"\s+" as delim_whitespace, not as a plain re.split(): leading and
# trailing whitespace on a line make no empty field (pandas 3.0.4,
# tests/io/parser/common/test_common_basic.py, test_ignore_leading_whitespace
# and test_whitespace_regex_separator). R's read.table(sep = "") and Perl's own
# split ' ' treat whitespace the same way. Only the pattern text counts, so
# qr/\s+/x qualifies and qr/[ \t]+/ does not.
sub _sep_re_is_ws {
	my ($re) = @_;
	my ($pat) = re::regexp_pattern($re);
	return defined $pat && $pat eq '\s+';
}

# Compressed input for read_table
#
# A gzip or bzip2 file is recognised by its first bytes, not its name, the way
# R's file() recognises one for read.table: do_url() in src/main/connections.c
# calls comp_type_from_memory() on the first bytes of a file opened "r" or
# "rt" (R-devel 4.7.0, r-source commit b3c233dd). pandas' compression='infer'
# goes by the extension instead; sniffing reads every file pandas would, and a
# compressed one that has lost its suffix too.
#
# The magic numbers are that function's:
#   gzip   1f 8b, RFC 1952 section 2.3.1's ID1 and ID2. A method other than
#          deflate after them is reported by zlib as corrupt data, as R's
#          gzio.h check_header() refuses it.
#   bzip2  "BZh" and a block size of '1'..'9', then the 48-bit magic of either
#          the first block (0x314159265359, BCD pi) or the end-of-stream
#          marker (0x177245385090, BCD sqrt(pi)), which is all an empty stream
#          holds -- bzip2 1.0.8 compress.c, BZ_HDR_h/BZ_HDR_0 and the
#          bsPutUChar() runs. R added the last six bytes in PR#18768, after a
#          text file that began "BZh" was taken for bzip2.
# Neither is how text begins: 0x1f is a control character, 0x8b is not ASCII
# and cannot start a UTF-8 sequence, and the bzip2 test runs to ten bytes.
#
# The same function also recognises four formats this module cannot inflate,
# and they are sniffed only so that read_table can say so: up to 0.3213 an
# .xz file was parsed as text and reported as "Alignment error on x.csv.xz data
# row 2", which sent the reader looking for a ragged row. Their magic numbers
# are comp_type_from_memory()'s as well:
#   xz     fd "7zXZ"           (the .xz container)
#   lzma   ff "LZMA", or 5d 00 00 80 00  (the two legacy LZMA headers)
#   zstd   28 b5 2f fd         (RFC 8878 section 3.1.1's Magic_Number)
#   lzop   89 "LZO"
# Each begins with a byte that no text file does, or, for the 5d header, holds
# NUL bytes, which no text file does either.
sub _sniff_compression {
	my ($file) = @_;
	open my $fh, '<', $file or return '';	# read_table's own open reports it
	binmode $fh;
	my $got = read $fh, my $head, 10;
	close $fh;
	return '' unless $got;
	return 'gzip' if $head =~ /\A\x1f\x8b/;
	return 'bzip2'
		if $head =~ /\ABZh[1-9](?:\x31\x41\x59\x26\x53\x59|\x17\x72\x45\x38\x50\x90)/;
	return 'xz'   if $head =~ /\A\xFD7zXZ/;
	return 'lzma' if $head =~ /\A(?:\xFFLZMA|\x5D\x00\x00\x80\x00)/;
	return 'zstd' if $head =~ /\A\x28\xB5\x2F\xFD/;
	return 'lzop' if $head =~ /\A\x89LZO/;
	return '';
}

# True when $file's lines end in a bare CR, as classic Mac OS wrote them.
# R's scan() and pandas' C tokenizer both take a lone CR as a line end (R
# 4.6.1 tests/reg-tests-1a.R, PR#2469; pandas 3.0.4
# tests/io/parser/test_textreader.py, test_cr_delimited); _parse_csv_file()
# reads LF and CRLF only, and handed such a file back as one long header.
#
# The file is taken for one only when what is read of it holds a CR and no LF
# at all, so an LF or CRLF file with a stray CR in its first line still reads
# as it always has. A CR that ends the block may be the first half of a CRLF,
# so the block is extended past it. 64 KB is one read; reading stops at 1 MB,
# which bounds the cost for a file with no line end in its first megabyte, and
# reads that one as LF, as it was read before.
sub _eol_is_cr {
	my ($file, $codec) = @_;
	# not on a compressed handle: it is opened :raw already, and a bare binmode
	# is :raw, which can pop the via layer that is doing the decompressing
	my $fh = $codec ? _open_decompressed($file, $codec) : _open_read($file);
	binmode $fh unless $codec;
	my $buf = '';
	my $eof = 0;
	while (length $buf < 1 << 20) {
		my $got = read $fh, $buf, 1 << 16, length $buf;
		if (!$got) { $eof = 1; last }
		last if index($buf, "\n") >= 0;
		last if index($buf, "\r") >= 0 && substr($buf, -1) ne "\r";
	}
	_close($fh);
	return 0 if index($buf, "\n") >= 0;
	return 0 if index($buf, "\r") < 0;
	return 1 if $eof || substr($buf, -1) ne "\r";
	return 0;	# 1 MB ending in a CR whose partner was not read: as before
}

# An input handle on the decompressed text of $file, streamed through the
# PerlIO::via layer below, so a multi-gigabyte .tsv.gz is inflated a buffer
# at a time as the parser reads it rather than into memory first. Both halves
# are core: PerlIO::via since 5.8, Compress::Raw::Zlib since 5.9.4 and
# Compress::Raw::Bzip2 since 5.10.1, the oldest perl this supports. The bzip2
# one is still loaded only when a bzip2 file is read, and its absence reported
# as what it is: some vendors' perls ship core modules as separate packages.
sub _open_decompressed {
	my ($file, $codec) = @_;
	require PerlIO::via;
	my $layer;
	if ($codec eq 'gzip') {
		require Compress::Raw::Zlib;
		$layer = 'Stats::LikeR::_Gunzip';
	} else {
		eval { require Compress::Raw::Bzip2; 1 }
			or die "read_table: \"$file\" is bzip2-compressed, and reading it "
			     . "needs Compress::Raw::Bzip2, which is not installed\n";
		$layer = 'Stats::LikeR::_Bunzip2';
	}
	# PUSHED is given no file name, so it reads this one while the open runs.
	local $Stats::LikeR::_Decompress::name = $file;
	my $fh;
	open $fh, "<:raw:via($layer)", $file
		or _io_die("Can't open '$file' for reading: '$!'");
	return $fh;
}

# A copy of $s as the bytes read_table compares it with. Every field comes
# back from the file as the bytes it holds -- UTF-8 ones for an .xlsx and for
# any CSV written as UTF-8 -- and a literal sep or comment marker already meets
# them that way, since the parser takes its bytes from SvPV. A name or token
# the caller holds as characters (under `use utf8`, or decoded from anywhere)
# is encoded the same way here before it is compared with a field. Up to
# 0.3213 na_strings => "\x{2014}", sheet => "Donn\x{e9}es" and a filter or
# row_names key of the same kind never matched what the file plainly held. A
# string perl holds as bytes is returned as it is.
sub _as_bytes {
	my ($s) = @_;
	utf8::encode($s) if defined $s && utf8::is_utf8($s);
	return $s;
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
	# One option, three names: 'na_strings' is R's na.strings, 'na_values' is
	# pandas', and 'undef_val' is what write_table calls the same token on the
	# way out, so a round trip can be written with one spelling on both halves.
	# Only one may be given, for the same reason 'sep' and 'delim' may not both
	# be. The names are checked in a fixed order so the message is
	# deterministic. The dotted 'na.strings' and 'undef.val' are refused as
	# unknown arguments.
	{
		my @given = grep { exists $input_args{$_} }
			qw(na_strings na_values undef_val);
		die "read_table: pass only one of 'na_strings', 'na_values' or "
		  . "'undef_val'; got " . join(', ', map { "'$_'" } @given) . "\n"
			if @given > 1;
		$input_args{'na_strings'} = delete $input_args{ $given[0] } if @given;
	}

	# An Excel workbook by its name: .xlsx, and the macro-enabled .xlsm and the
	# two template forms .xltx and .xltm, which hold their sheets in the same
	# parts (ECMA-376 differs only in the main part's content type). Up to
	# 0.3213 only .xlsx was recognised, and an .xlsm was read as text and
	# reported as an alignment error in a ragged row.
	my $is_xlsx = $file =~ /\.xl(?:sx|sm|tx|tm)\z/i;
	my $codec   = $is_xlsx ? '' : _sniff_compression($file);
	die "read_table: \"$file\" is $codec-compressed, which read_table cannot "
	  . "decompress; decompress it first, or recompress it with gzip or bzip2\n"
		if $codec =~ /\A(?:xz|lzma|zstd|lzop)\z/;
	my $cr_eol  = $is_xlsx ? 0  : _eol_is_cr($file, $codec);	# lines end in a bare CR
	my $eol     = $cr_eol ? "\r" : "\n";
	# The extension only picks the default sep, and a compressed file's is
	# that of the text inside it: x.tsv.gz is tab-separated.
	(my $sep_name = $file) =~ s/\.(?:gz|bgz|bz2)\z//i if $codec;
	$sep_name = $file unless $codec;
	# A VCF (VCF 4.2/4.3 spec, section 1: "##" meta-information lines, then
	# one "#CHROM POS ID REF ALT QUAL FILTER INFO [FORMAT sample...]" header
	# line, then tab-separated data) is read with its own defaults: sep is a
	# tab, the comment marker is "##" so that only the meta lines are
	# comments, and the "#" in front of CHROM comes off (see $finalize_header).
	my $is_vcf = $sep_name =~ /\.vcf\z/i;
	my $default_sep = $is_vcf || $sep_name =~ /\.tsv\z/i ? "\t" : ',';
	my %args = (
		sep => $default_sep, comment => $is_vcf ? '##' : '#', %input_args,
	);

	my %allowed_args = map { $_ => 1 } (
		'comment', 'output_type', 'filter', 'row_names', 'sep',
		'auto_row_names', 'sheet', 'na_strings', 'header', 'col_names', 'quote',
		'explode', 'colClasses',
		# private, undocumented: the multi-sheet expansion passes an already
		# parsed worksheet list / shared-string table to each per-sheet recursion
		# so a big sharedStrings.xml is not re-decompressed once per worksheet.
		'_xlsx_sheets', '_sst', '_sheet_ix',
		# private, for t/read_table.filter.t: keep every row in the perl
		# closure, which is the reference the parser's filter path is held to
		'_closure',
	);
	my @undef_args = sort grep { !$allowed_args{$_} } keys %args;
	if (@undef_args) {
		my $current_sub = ( split /::/, (caller(0))[3] )[-1];
		die "the args \"@undef_args\" aren't defined for $current_sub\n";
	}
	# explode => 1, the default for a VCF read with its header: every sample
	# column is split on ':' into one column per FORMAT key, and the table is
	# a hoh keyed by CHROM:POS:REF:ALT (see _vcf_explode). Without a header
	# there is no FORMAT column to split by, so header => 0 reads it plain.
	if (exists $args{explode}) {
		die "read_table: 'explode' applies only to a VCF (.vcf, .vcf.gz or "
		  . ".vcf.bgz), and \"$file\" is not named as one\n"
			unless $is_vcf;
		die "read_table: 'explode' must be 0 or 1\n"
			unless defined $args{explode} && !ref $args{explode}
				&& $args{explode} =~ /\A[01]?\z/;
	}
	my $explode = $is_vcf && ($args{explode} // 1)
		&& !(exists $args{header} && defined $args{header} && !$args{header});
	my $otype = $args{'output_type'} // ($explode ? 'hoh' : 'aoh');
	die "read_table: output_type \"$otype\" isn't allowed (aoa, aoh, hoa, hoh)\n"
		unless $otype =~ m/^(?:aoa|aoh|hoa|hoh)$/;
	# Only a hoh is keyed by a column. An aoa is positional, and an aoh or hoa
	# keeps every column as data, so a row_names column would only be a column
	# like any other. Up to 0.3213 an aoh or hoa checked the name against the
	# header and then ignored it, which read as though it had done something.
	die "read_table: 'row_names' has no meaning for output_type \"$otype\"; "
	  . "the row names column is read as an ordinary column\n"
		if $otype ne 'hoh' && defined $args{'row_names'};
	# compared with the header's bytes, both here and in _vcf_explode()
	$args{'row_names'} = _as_bytes($args{'row_names'}) if defined $args{'row_names'};
	# 'sheet' picks a worksheet, which only an .xlsx has; it was ignored on
	# any other file up to 0.3213, as 'explode' is refused on a non-VCF.
	die "read_table: 'sheet' applies only to an .xlsx, and \"$file\" is not "
	  . "named as one\n"
		if defined $args{sheet} && !$is_xlsx;
	# A qr// separator is found by perl's regex engine; any other sep is
	# a literal string, as it has always been. A regex is not looked at for an
	# .xlsx, where a literal sep is not either.
	if (ref $args{sep} && ref $args{sep} ne 'Regexp') {
		die "read_table: 'sep' must be a string or a qr// regex, not a "
		  . ref($args{sep}) . " reference\n";
	}
	my $sep_re = (ref $args{sep} && !$is_xlsx) ? $args{sep} : undef;
	# Refused before the file is read, so that qr/\s*/ fails the same way
	# whatever the file holds. A pattern that matches nothing but an empty
	# string -- a bare lookahead, say -- passes this, and is refused where it
	# first matches one anywhere but at the start of a line.
	die "read_table: the sep regex $sep_re matches an empty string; it must "
	  . "match at least one character\n"
		if $sep_re && '' =~ /\A(?:$sep_re)\z/;
	# header => 0 is R's header = FALSE and pandas' header=None: the first line
	# is data, and the columns are named by 'col_names' or, as R names them,
	# V1, V2, ... 'col_names' with a header renames its columns, as in R.
	# '' is allowed as well as 0, since that is what perl's own false is:
	# header => ($n > 0) must not be refused when it is false.
	my $want_header = 1;
	if (exists $args{header}) {
		die "read_table: 'header' must be 0 or 1\n"
			unless defined $args{header} && !ref $args{header}
				&& $args{header} =~ /\A[01]?\z/;
		$want_header = $args{header} ? 1 : 0;
	}
	my $col_names = $args{'col_names'};
	if (defined $col_names) {
		die "read_table: 'col_names' must be an ARRAY reference of names\n"
			unless ref $col_names eq 'ARRAY' && @$col_names;
		for my $n (@$col_names) {
			die "read_table: 'col_names' may only hold defined, plain strings\n"
				if !defined $n || ref $n;
		}
	}
	# quote => '' is R's quote = "" and pandas' quoting=QUOTE_NONE: '"' is
	# ordinary text. Only '"' can quote, so it is the only other value; R's
	# read.table would also take "'", which neither parser here knows.
	my $quote = 1;
	if (exists $args{quote}) {
		die "read_table: 'quote' must be '\"' (the default) or '' (no quoting)\n"
			unless defined $args{quote} && !ref $args{quote}
				&& ($args{quote} eq '' || $args{quote} eq '"');
		$quote = $args{quote} eq '"' ? 1 : 0;
	}

	# The file is read plain, as an aoa, with every option but the output
	# type and row_names, so 'filter' sees the file's own columns (FORMAT and
	# each sample's unsplit text), and is then exploded into the shape asked
	# for. Each raw row is released as it is exploded.
	if ($explode) {
		my %raw_args = (%input_args, explode => 0, 'output_type' => 'aoa');
		delete $raw_args{'row_names'};
		my $raw = read_table($file, %raw_args);
		my %na = map { _as_bytes($_) => 1 } !defined $args{'na_strings'} ? ()
			: ref $args{'na_strings'} ? @{ $args{'na_strings'} }
			: ($args{'na_strings'});
		# _vcf_explode() in LikeR.xs; its comment says what the columns are
		my %mode = (aoh => 0, hoa => 1, hoh => 2, aoa => 3);
		return _vcf_explode($raw, $mode{$otype}, $args{'row_names'}, $file,
			%na ? \%na : undef);
	}

	# A multi-worksheet .xlsx with no explicit 'sheet' is returned as a hash
	# keyed by worksheet name, each value being that sheet parsed with the same
	# options (recursing one sheet at a time keeps every table's state, and any
	# hoh row_names default, independent). A single-worksheet workbook, or an
	# explicit 'sheet', still returns that one table directly.
	# Resolve the worksheet list once and reuse it below (it decompresses and
	# parses workbook.xml + its rels, so recomputing it in the main xlsx branch
	# would double that work for every single-sheet / explicit-sheet read).
	my ($xlsx_sheets, $xlsx_rels);
	if ($is_xlsx) {
		# Reuse a caller-supplied worksheet list (from the multi-sheet expansion
		# below) rather than re-parsing workbook.xml + its rels for every sheet.
		if ($args{_xlsx_sheets}) {
			$xlsx_sheets = $args{_xlsx_sheets};
		} else {
			$xlsx_rels   = _xlsx_rels($file);
			$xlsx_sheets = _xlsx_sheets($file, $xlsx_rels);
		}
		if (!defined $args{sheet} && !defined $args{_sheet_ix}
				&& @$xlsx_sheets > 1) {
			# Decompress + parse the shared-string table once for the whole
			# workbook and hand it to each per-sheet read, instead of every
			# recursion re-reading (a potentially large) sharedStrings.xml.
			my $sst = _xlsx_shared_strings($file, $xlsx_rels);
			# A sheet with no name is keyed "SheetN", N its position -- or the
			# next N no other sheet is named, since up to 0.3213 an unnamed
			# first sheet and a sheet called "Sheet1" were both keyed "Sheet1",
			# and one of the two tables was silently lost.
			my %taken = map { defined $_->{name} ? ($_->{name} => 1) : () }
				@$xlsx_sheets;
			my %book;
			for my $i (0 .. $#$xlsx_sheets) {
				my $name = $xlsx_sheets->[$i]{name};
				if (!defined $name) {
					my $n = $i + 1;
					$n++ while $taken{"Sheet$n"};
					$name = "Sheet$n";
					$taken{$name} = 1;
				}
				# by position, privately: 'sheet' takes a name before a
				# number, so sheets named "2" and "1" would swap places
				$book{$name} = read_table($file, %input_args,
					_sheet_ix    => $i,
					_xlsx_sheets => $xlsx_sheets,
					_sst         => $sst);
			}
			return \%book;
		}
	}

# R's write.table(col.names=TRUE) default omits the header label for the
# row-names column, so a header comes out one field short of every data
# row. With 'auto_row_names' set, mirror read.table's rule: when (and only
# when) the header is exactly one field short, treat the first data field
# as an (otherwise unlabelled) row-names column. Any truthy value enables
# it; a non-1 string is used as the synthesized column name.
	my $want_auto_rn = $args{'auto_row_names'} ? 1 : 0;
	my $auto_rn_added = 0;	# the row-names column was put in front of @header
	my $auto_rn_name =
		($want_auto_rn && "$args{'auto_row_names'}" ne '1')
			? $args{'auto_row_names'} : 'row_name';

	my $filter = $args{filter};
	if (defined $filter && ref($filter) eq 'CODE') {
		$filter = { 0 => $filter };
	} elsif (defined $filter && ref($filter) ne 'HASH') {
		die "'filter' must be a CODE or HASH reference\n";
	}
	# The parser calls the subs itself (see $plan below), and it takes a code
	# reference only. Asked up front, so a bad one is not first noticed on
	# whichever row reaches it.
	for my $k (sort keys %{ $filter || {} }) {
		die "read_table: filter '$k' must be a CODE reference\n"
			unless (reftype($filter->{$k}) // '') eq 'CODE';
	}

# colClasses, R's: a column declared numeric or integer is stored as an NV or
# an IV rather than as its text. On a 300,000 x 5 CSV with three of its five
# columns declared, a hoa took 74 MB instead of 116 MB on perl 5.44.0, about
# 47 bytes less for each of the 900,000 cells converted. R's spellings:
# one class for every column, a list by position (recycled when short, as R
# recycles it), or a hash by name, where a name that is no column is warned
# about, in R's words, and otherwise ignored. undef (R's NA) and 'character'
# leave a column as read. Each name is checked here, before the file is
# opened; which field gets which class waits for the header.
#   %cls_code: 1 = numeric (an NV), 2 = integer (an IV), 0 = as read
	my %cls_code = (numeric => 1, double => 1, real => 1, integer => 2, character => 0);
	my $cls_arg = $args{colClasses};
	my $cls_of = sub {
		my ($c) = @_;
		return 0 unless defined $c;
		die "read_table: colClasses '$c' is not one read_table reads: it takes "
		  . "'numeric' (or 'double' or 'real'), 'integer', 'character' or undef\n"
			unless exists $cls_code{$c};
		return $cls_code{$c};
	};
	if (defined $cls_arg) {
		my $r = ref $cls_arg;
		die "read_table: 'colClasses' must be a string, an ARRAY reference or a "
		  . "HASH reference\n" if $r && $r ne 'ARRAY' && $r ne 'HASH';
		$cls_of->($_) for $r eq 'ARRAY' ? @$cls_arg : $r eq 'HASH' ? values %$cls_arg : $cls_arg;
		die "read_table: 'colClasses' is an empty list\n" if $r eq 'ARRAY' && !@$cls_arg;
	}
	my @cls;	# per field of @header, once it is fixed: a %cls_code value

# na_strings / na_values / undef_val -- field texts that mean "missing", mapped
# to undef exactly as an empty field already is. Every spelling has been folded
# into 'na_strings' above, so only that one is read from here on.
#
# Off by default. R's read.table defaults to na.strings = "NA" and pandas
# recognises a whole list, but this module has always handed a literal "NA"
# back as real data, and t/read_table.t pins that, so turning it on for
# everyone is a maintainer's call rather than a bug fix. What was a bug is that
# there was no way to ask for it at all: write_table renders undef with
# 'undef_val' (documented under write_table as not round-tripping back to
# undef), so read_table could not read back what its own sibling had written.
#
# The match is on the exact field text, case-sensitively and without trimming
# whitespace, so " NA" is not "NA"; list both spellings if a file has both.
	my %na_string;
	{
		my $ns = $args{'na_strings'};
		my @ns = !defined($ns)       ? ()
		       : ref($ns) eq 'ARRAY' ? @$ns
		       : ref($ns)            ? die "read_table: 'na_strings' must be a "
		                                 . 'string or an ARRAY reference, not a '
		                                 . ref($ns) . " reference\n"
		       :                       ($ns);
		for my $s (@ns) {
			die "read_table: 'na_strings' may not contain an undefined value\n"
				unless defined $s;
			$na_string{ _as_bytes($s) } = 1;
		}
	}
	my $has_na = %na_string ? 1 : 0;   # skip the hash lookup in the common case

	# @field_wins: per field, TRUE when it is the last to carry its name
	my (@data, %data, @header, @uniq_header, @hoa_cols, @field_wins,
	    %mapped_filters, @sorted_filter_flds, %seen_rownames);
	my ($data_row, $header_seen, $header_done, $provisional_hdr) = (0, 0, 0, 0);
	# hoh: rows whose name an earlier row already had, and the first of them as
	# [name, data row]. Counted and warned about once, after the parse.
	my ($n_dup_rn, $first_dup_rn) = (0, undef);

# Once the header is fixed there is nothing left for the row closure below to
# decide, so the parser is given a plan and builds the rest of the table
# itself. That closure, called once per row, used to be about four fifths of
# read_table's wall clock -- on a 300,000 x 5 CSV, 0.42 s of 0.53 s -- doing in
# perl what C can do from the fields it has already cut.
#
# A 'filter' goes this way too: its subs are handed over in the plan and the
# parser calls them, with the same $_, %_ and arguments the closure below
# gives them (S_filter_row() in LikeR.xs). Up to 0.3212 a filter kept every row
# in the closure, and a filtered read of a 300,000 x 5 CSV took 0.58 s to
# 1.07 s against 0.08 s to 0.18 s unfiltered. The closure still applies them to
# any data row it handles itself, before the plan is installed. 'hoh' went
# through the closure too until 0.319, which on a 300,000 x 5 CSV cost 0.91 s;
# it now takes 0.20 s. An .xlsx goes through a different parser (_parse_xlsx_sheet_xs)
# but the same plan: both hand a finished row to the same S_fast_row().
# A qr// sep goes this way too: _parse_csv_file() matches it with perl's regex
# engine, from C, so only how a separator is found changes.
#
# See csv_plan in LikeR.xs for what each key means. install_plan() runs exactly
# once, from wherever $header_done is first set, and writes 'out' last because
# that is the key the parser tests for.
	my $plan = $args{_closure} ? undef : {};
	my $install_plan = sub {
		return if !$plan || %$plan;
		# A repeated column name resolves to its LAST field, which is what
		# "later values win" means when %line_hash is built below.
		my %last;
		$last{ $header[$_] } = $_ for 0 .. $#header;
		$plan->{keys} = \@uniq_header;
		$plan->{idx}  = [ map { $last{$_} } @uniq_header ];
		$plan->{ncol} = scalar @header;
		$plan->{file} = $file;
		$plan->{na}   = $has_na ? \%na_string : undef;
		if (@cls) {
			$plan->{cls} = [ @cls ];
			$plan->{hdr} = [ @header ];
		}
		# in the order the closure below runs them
		for my $fld (@sorted_filter_flds) {
			for my $sub (@{ $mapped_filters{$fld} }) {
				push @{ $plan->{flt_fld} }, $fld;
				push @{ $plan->{flt_sub} }, $sub;
			}
		}
		# a reference, not a copy: the parser reads it when it picks the plan
		# up, by which time $on_line may have emitted a data row of its own.
		$plan->{row}  = \$data_row;
		if ($otype eq 'aoh') {
			$plan->{mode} = 0;
			$plan->{out}  = \@data;
		} elsif ($otype eq 'aoa') {
			$plan->{mode} = 3;
			$plan->{out}  = \@data;
		} elsif ($otype eq 'hoa') {
			$plan->{mode} = 1;
			$plan->{out}  = [ @hoa_cols ];
		} else {
			# $finalize_header has already checked that row_names is a column
			my ($rn) = grep { $uniq_header[$_] eq $args{'row_names'} }
				0 .. $#uniq_header;
			$plan->{mode} = 2;
			$plan->{rn}   = $rn;
			$plan->{out}  = \%data;
		}
	};

	# Everything that depends on the (possibly augmented) @header lives here so
	# it can run either right after the header line (strict mode) or deferred
	# to the first data row (auto_row_names mode, once the width is known).
	my $finalize_header = sub {
		# A VCF header line is "#CHROM\tPOS...": under the default "##" marker it
		# is not a comment, so it arrives with its "#" on. Read with
		# comment => '#' instead, the marker is already off and this is a no-op.
		# Its first column, not $header[0], since auto_row_names may have put a
		# row-names column in front of it.
		$header[$auto_rn_added] =~ s/\A#//
			if $is_vcf && $want_header && defined $header[$auto_rn_added];
		# R's read.table: 'col.names' replaces a header's names, and a header
		# of another length is warned about ("header and 'col.names' are of
		# different lengths") and then the names are used all the same.
		if ($col_names && $want_header) {
			my $n = @header - $auto_rn_added;
			warn "read_table: header and 'col_names' are of different lengths "
			  . "($n and " . scalar(@$col_names) . ") in $file\n"
				if $n != @$col_names;
			splice @header, $auto_rn_added, $n, @$col_names;
		}
		if (@header && $header[0] eq '') {
			$header[0] = 'row_name';
		}
		my %seen_h;
		@uniq_header = grep { !$seen_h{$_}++ } @header;
		# Name each repeated column, with how many fields carry it and which
		# ones (1-based, as a spreadsheet or `cut -f` counts them). A bare
		# list of the names is not enough to find them: a merged banner row
		# repeats the *empty* name, which prints as nothing at all, and a name
		# repeated three times reads the same as one repeated twice.
		my %at;
		push @{ $at{ $header[$_] } }, $_ + 1 for 0 .. $#header;
		# 12 positions is what fits on one terminal line beside the name and
		# the count; a merged banner row can repeat the empty name across
		# every field of the sheet (66 of them in the file this was written
		# for), and the count still says how many there are in total.
		my @dup_cols = map {
			my @f = @{ $at{$_} };
			my $more = @f > 12 ? ', ...' : '';
			splice @f, 12 if @f > 12;
			"'$_' x $seen_h{$_} (fields " . join(', ', @f) . "$more)"
		} grep { $seen_h{$_} > 1 } @uniq_header;
		# an aoa keeps every field, so a repeated name loses nothing there
		warn "read_table: duplicate column name(s) in $file (later values win): "
			. join('; ', @dup_cols) . "\n"
			if @dup_cols && $otype ne 'aoa';
		# An aoa's first row is the header -- the shape write_table reads an
		# AoA as -- in file order and with any repeated name kept.
		@data = ([ @header ]) if $otype eq 'aoa';
		if ($otype eq 'hoh' && !defined $args{'row_names'}) {
			$args{'row_names'} = $header[0];
		}
		if (defined $args{'row_names'}
				&& !grep { $_ eq $args{'row_names'} } @header) {
			die "\"$args{'row_names'}\" isn't in the header of $file\n";
		}
		# A repeated name resolves to its last field, which is the one
		# %line_hash keeps, so only that field's filter writes $_ back into it.
		my %last_field;
		$last_field{ $header[$_] } = $_ for 0 .. $#header;
		@field_wins = map { $last_field{ $header[$_] } == $_ } 0 .. $#header;
		if ($filter) {
			# Each key is resolved to a field before any filter runs: '0' to
			# the whole row; a column's name to the last field carrying it;
			# and any other number to that field, counting from 1. A name
			# comes before a number, so a column named "2021" can be filtered
			# on -- up to 0.3213 that key was a field number and died as out
			# of range. A field named by two keys (1 and its name, say) runs
			# both, in key order; one used to replace the other, and which
			# depended on hash order, so the rows kept changed between runs.
			%mapped_filters = ();
			for my $k (sort keys %$filter) {
				my $fld;
				if ($k eq '0') {
					$fld = 0;
				} else {
					my $kb = _as_bytes($k);
					my $idx = $last_field{$kb};
					if (!defined $idx && length( $args{comment} // '' )) {
						# A commented-out header has its marker (and any
						# following whitespace) stripped from the first
						# column, so a key written as it appears in the file
						# (e.g. "# PDB") won't match the clean name ("PDB").
						# Normalize the key the same way and retry.
						(my $nk = $kb) =~ s/^\s*\Q$args{comment}\E\s*//;
						$idx = $last_field{$nk};
					}
					if (defined $idx) {
						$fld = $idx + 1;
					} elsif ($k =~ /\A[0-9]+\z/) {
						die "read_table: numeric filter key $k exceeds the "
						  . scalar(@header) . " columns of $file, and no column "
						  . "is named '$k'\n"
							if $k > @header;
						$fld = $k + 0;
					} else {
						die "read_table: Filter column '$k' not found in the "
						  . "header of $file; header is: "
						  . join( ', ', map { "'$_'" } @header ) . "\n";
					}
				}
				push @{ $mapped_filters{$fld} }, $filter->{$k};
			}
			@sorted_filter_flds = sort { $a <=> $b } keys %mapped_filters;
		}
		if (defined $cls_arg) {
			my $r = ref $cls_arg;
			if ($r eq 'HASH') {
				my %by = map { _as_bytes($_) => $cls_of->( $cls_arg->{$_} ) } keys %$cls_arg;
				@cls = map { $by{$_} // 0 } @header;
				my %have = map { $_ => 1 } @header;
				warn "read_table: not all columns named in 'colClasses' exist\n"
					if grep { !$have{$_} } keys %by;
			} elsif ($r eq 'ARRAY') {
				die "read_table: 'colClasses' has " . scalar(@$cls_arg) . " entries "
				  . "for the " . scalar(@header) . " columns of $file\n"
					if @$cls_arg > @header;
				@cls = map { $cls_of->( $cls_arg->[ $_ % @$cls_arg ] ) } 0 .. $#header;
			} else {
				@cls = ( $cls_of->($cls_arg) ) x @header;
			}
			@cls = () unless grep { $_ } @cls;
		}
		# The column arrays are made once and held, so neither the fast path
		# nor the row loop below has to fetch them out of %data (and
		# autovivify them) once per column per row.
		@hoa_cols = map { $data{$_} ||= [] } @uniq_header if $otype eq 'hoa';
	};

	# _parse_csv_file() treats a line whose comment marker is followed by
	# whitespace (e.g. "# PDB\tscore") as a comment and drops it, so a header
	# written that way never reaches the callback and the first data row would
	# be mistaken for the header. Recover it: read the first physical line, and
	# if it is marker + whitespace and splits into >=2 fields, hold it as a
	# CANDIDATE header. It is confirmed (in the callback) only if its field
	# count matches the first line the parser delivers and that line looks
	# like data rather than a header (see $is_data below); otherwise it was an
	# ordinary leading comment and is discarded. A marker hugging its text ("#id,val") is
	# delivered by the parser and held as a candidate in the same way by the
	# callback, so it never reaches this branch.
	if ($want_header && !$is_xlsx && length( $args{comment} // '' )
			&& length( $args{sep} // '' )) {
		# $/ is the caller's, and under a `local $/;` this read the whole
		# file; _parse_csv_file() splits on "\n" (or "\r", see _eol_is_cr)
		# whatever $/ is, and so does this. A UTF-8 byte-order mark is dropped
		# here as the parser drops it.
		my $fh    = $codec ? _open_decompressed($file, $codec)
		                   : _open_read($file);
		my $first = do { local $/ = $eol; <$fh> };
		_close($fh);
		$first =~ s/\A\xEF\xBB\xBF// if defined $first;
		if (defined $first && $first =~ /^\Q$args{comment}\E\s/) {
			if ($cr_eol) { $first =~ s/\r\z// } else { $first =~ s/\r?\n\z// }
			# The marker and the blanks after it come off before the cut, so
			# that neither can become a field: a tab after "#" in a
			# tab-separated file made an empty first column of "#\tid\tval",
			# whose three names then failed to match two-field data rows.
			(my $body = $first) =~ s/^\Q$args{comment}\E\s*//;
			# The rest is cut by _parse_csv_file() itself, through an in-memory
			# handle, so it is split by exactly the rules the data will be:
			# up to 0.3213 a perl split() ignored quoting, and # "x,y",z came
			# out as three names. Both mismatches promoted the first data row
			# to the header without a word. Quoting is left off for a comment
			# with an odd number of '"', which no one-line row of quoted
			# fields has, so that prose like 5'10" is not taken for a quoted
			# field running to the end of the file; and a sep regex that
			# croaks on this line leaves it as no candidate at all, since the
			# parser drops it as a comment and would never have seen it.
			my @cols;
			if (length $body) {
				my $q = $quote && !(($body =~ tr/"//) % 2);
				my $rows = eval {
					open my $mfh, '<', \$body
						or die "read_table: could not read the commented-out header\n";
					_parse_csv_file($file, $sep_re ? '' : $args{sep}, '', undef,
						undef, $q, 0, $sep_re,
						$sep_re && _sep_re_is_ws($sep_re) ? 1 : 0, $mfh, 0);
				};
				@cols = @{ $rows->[0] } if $rows && @$rows;
			}
			if (@cols >= 2) {
				@header          = @cols;
				$header_seen     = 1;
				$provisional_hdr = 1;	# confirm against the first data row
			}
		}
	}

	# $quote_note is the parser's account of a quoted field that ran this row
	# across lines (S_quote_note() in LikeR.xs), undef for a one-line row; it
	# only ever goes into the alignment message. $first_quoted is true when the
	# row's first field was written in '"' (S_emit_row()), so that a comment
	# marker at its start is text, never a commented-out header's.
	my $on_line = sub {
		my ($line_ref, $quote_note, $first_quoted) = @_;

		# quote => '' on a file whose first line has every field in '"' keeps
		# the quote marks in every name or value: R's write.csv() writes
		# exactly that header, and it is read as intended only with the
		# default quote. 'quote' means nothing to an .xlsx, so it is not checked.
		if (!$header_seen && !$quote && !$is_xlsx && @$line_ref
				&& !grep { !defined || !/\A".*"\z/s } @$line_ref) {
			warn "read_table: every field on the first line of $file is "
				. "wrapped in '\"', and quote => '' keeps the quote marks as "
				. "part of the text; leave 'quote' out to read them as quoting\n";
		}

		if (!$header_seen && !$want_header) {
			# header => 0: this line is the first data row, so it only sets the
			# width; the names come from 'col_names' or are V1, V2, ... It falls
			# through to be finalized and read as data below.
			@header = $col_names ? @$col_names : map { "V$_" } 1 .. @$line_ref;
			$header_seen = 1;
		}
		# A line whose marker hugs its text ("#id,val") is not dropped by the
		# parser, since it may be a commented-out header. It is held as a
		# CANDIDATE, as the "# id,val" form read above is, and a later one
		# replaces it, so in a run of them it is the last -- the one next to
		# the data -- that is tried. Up to 0.3213 the first was taken for the
		# header on the spot, so a VCF's 140 "##" meta lines became one
		# column called "fileformat=VCFv4.2" and the "#CHROM" line an
		# alignment error. Only while no real header has been taken: after
		# that, such a line is data, as it has always been.
		# Not in an .xlsx, where 'comment' has never applied: a first cell
		# such as "#id" or "# of items" is a cell, and treating it as a
		# commented-out header lost "#a1"-style data rows wholesale up to 0.3213.
		# Nor in a quoted first field: R's read.table() reads a comment
		# character inside quotes as text, and up to 0.3213 "#a",b came back
		# as a column named a -- or, where the next row was text as well, not
		# at all, that row being taken for the header in its place.
		if ((!$header_seen || $provisional_hdr) && !$is_xlsx && !$first_quoted
				&& length( $args{comment} // '' )
				&& @$line_ref && defined $line_ref->[0]
				&& index($line_ref->[0], $args{comment}) == 0) {
			@header = @$line_ref;
			$header[0] =~ s/^\Q$args{comment}\E\s*//;
			$header_seen     = 1;
			$provisional_hdr = 1;	# confirm against the first data row
			return;
		}

		if (!$header_seen) {
			# HEADER CAPTURE (copy made only here; runs once). A commented
			# line never gets here: it was taken as a candidate just above.
			@header      = @$line_ref;
			$header_seen = 1;
			unless ($want_auto_rn) {	# strict: finalize immediately
				$finalize_header->();
				$header_done = 1;
				$install_plan->();
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
				# Under auto_row_names a header one field short of the data is
				# the shape being looked for, not a mismatch; refusing it here
				# made the first data row the header (0.320 and before).
				my $one_short = $want_auto_rn && @$line_ref == @header + 1;
				# The same width is not enough on its own. "# written by foo,
				# v2" before "id,val" has two fields too, and up to 0.3213 that
				# comment became the header and "id,val" the first data row,
				# without a word. A row the same width is taken for data only
				# when one of its fields is a number or an na_strings token, or
				# every field is empty, which no header is; otherwise it is the
				# file's own header, as R and pandas read it, and the comment
				# is a comment.
				my $is_data = (!grep { defined && length } @$line_ref)
					|| grep {
						defined && length
						&& (looks_like_number($_) || ($has_na && $na_string{$_}))
					} @$line_ref;
				if (!$one_short && (@$line_ref != @header || !$is_data)) {
					# not commented: a commented line is a candidate above
					@header = @$line_ref;
					unless ($want_auto_rn) {
						$finalize_header->();
						$header_done = 1;
						$install_plan->();
					}
					return;	# this line WAS the header, not data
				}
				# widths match and the row is data: accept the commented
				# header, and let the auto_row_names / finalize logic below
				# run on THIS data row.
			}

# First data row in auto_row_names mode: now the data width is
# known, so decide whether the file carries an unlabelled leading
# row-names column (header exactly one field short).
			if ($want_auto_rn && @$line_ref == @header + 1) {
				unshift @header, $auto_rn_name;
				$auto_rn_added = 1;
			}
			$finalize_header->();
			$header_done = 1;
			$install_plan->();
			# fall through and process THIS line as data
		}

# --- DATA PROCESSING (operate on $line_ref directly; no row copy)
		$data_row++;
		if (@$line_ref != @header) {
			# FIX: alignment errors now say WHICH row is ragged
			die sprintf "Alignment error on %s data row %d (%d fields vs %d headers)%s.\n",
				$file, $data_row, scalar @$line_ref, scalar @header,
				defined $quote_note ? "; $quote_note" : '';
		}
		my %line_hash;
		for my $i (0 .. $#header) {
			my $v = $line_ref->[$i];
			$line_hash{ $header[$i] }
				= ( !defined($v) || $v eq ''
				    || ( $has_na && $na_string{$v} ) ) ? undef : $v;
		}
# APPLY FILTERS
		if (@sorted_filter_flds) {
			local *_ = \%line_hash;
			foreach my $fld (@sorted_filter_flds) {
				for my $sub (@{ $mapped_filters{$fld} }) {
					# The field's value as %line_hash holds it, which is what
					# an earlier filter may have changed -- except for a field
					# whose name a later field repeats, whose own value is not
					# in %line_hash at all; that one is read from the row by
					# the rule %line_hash is built by.
					local $_ = $fld == 0 ? $line_ref
						: $field_wins[ $fld - 1 ] ? $line_hash{ $header[ $fld - 1 ] }
						: do {
							my $v = $line_ref->[ $fld - 1 ];
							( !defined($v) || $v eq ''
							  || ( $has_na && $na_string{$v} ) ) ? undef : $v
						};
					return if !$sub->( $line_ref, \%line_hash );
					next if $fld == 0;
					# write back any mutation made to $_
					$line_ref->[ $fld - 1 ] = $_;
					# na_strings applies to a written-back value too, so the
					# empty-string rule and the NA rule stay the same rule.
					# A field whose name a later field repeats is not the one
					# %line_hash holds, so it does not overwrite it.
					$line_hash{ $header[ $fld - 1 ] }
						= ( !defined($_) || $_ eq ''
						    || ( $has_na && $na_string{$_} ) ) ? undef : $_
						if $field_wins[ $fld - 1 ];
				}
			}
		}
# colClasses, after the filters and on %line_hash itself, as the parser does it
# (S_filter_row() in LikeR.xs); a key a filter deleted stays deleted. An aoa's
# fields are converted as they are copied, below.
		if (@cls && $otype ne 'aoa') {
			for my $f (grep { $cls[$_] && $field_wins[$_] } 0 .. $#header) {
				my $name = $header[$f];
				$line_hash{$name} = _cell_class($line_hash{$name}, $cls[$f],
					$file, $data_row, $name, $f + 1)
					if exists $line_hash{$name};
			}
		}
# Populate requested data structure
		if ($otype eq 'aoh') {
			push @data, \%line_hash;
		} elsif ($otype eq 'aoa') {
			# from the fields rather than %line_hash, so a repeated name keeps
			# every one of its fields, as the fast path's mode 3 does
			push @data, [ map {
				my $v = $line_ref->[$_];
				$v = undef if !defined($v) || $v eq '' || ( $has_na && $na_string{$v} );
				( defined $v && @cls && $cls[$_] )
					? _cell_class($v, $cls[$_], $file, $data_row, $header[$_], $_ + 1)
					: $v
			} 0 .. $#$line_ref ];
		} elsif ($otype eq 'hoa') {
			my $c = 0;
			push @{ $hoa_cols[ $c++ ] }, $line_hash{$_} for @uniq_header;
		} elsif ($otype eq 'hoh') {
			my $row_name = $line_hash{ $args{'row_names'} };
			die sprintf "read_table: undefined row name (column '%s') in %s data row %d\n",
				$args{'row_names'}, $file, $data_row
				unless defined $row_name;
			if ($seen_rownames{$row_name}++) {
				$n_dup_rn++;
				$first_dup_rn ||= [ $row_name, $data_row ];
			}
			# made up front, so that a file whose only column is the row name
			# still has its rows -- as empty hashes, the way R's read.table
			# gives it a data frame of n rows and 0 columns -- rather than none
			my $row = $data{$row_name} ||= {};
			foreach my $col (@uniq_header) {
				next if $col eq $args{'row_names'};
				$row->{$col} = $line_hash{$col};
			}
		}
	};
	if ($is_xlsx) {
		# the sheet first, so a bad 'sheet' is refused before the whole
		# shared-string table has been inflated and parsed for nothing
		my $chosen = defined $args{_sheet_ix} ? $xlsx_sheets->[ $args{_sheet_ix} ]
		           : _xlsx_choose_sheet($file, $xlsx_sheets, $args{sheet});
		my $sst    = $args{_sst} // _xlsx_shared_strings($file, $xlsx_rels);
		_parse_xlsx_sheet($file, $sst, $chosen->{path}, $on_line, $plan);
	} else {
		my $fh = $codec ? _open_decompressed($file, $codec) : undef;
		_parse_csv_file($file, $sep_re ? '' : $args{sep} // '',
			$args{comment} // '', $on_line, $plan, $quote,
			$want_header ? 0 : 1, $sep_re,
			$sep_re && _sep_re_is_ws($sep_re) ? 1 : 0, $fh, $cr_eol);
		_close($fh) if $fh;
	}
	# A hoh's repeated row names, from this closure and from the fast path
	# (S_plan_report() in LikeR.xs) together. One warning for the file: up to
	# 0.3213 there was one per repeated row, 40,820 of them for a 300,000-row
	# file. A single repeat keeps the words it has always had.
	if ($plan && $plan->{dup_n}) {
		$n_dup_rn += $plan->{dup_n};
		$first_dup_rn ||= [ $plan->{dup_first}, $plan->{dup_row} ];
	}
	if ($n_dup_rn == 1) {
		warn "read_table: duplicate row name '$first_dup_rn->[0]' in $file "
		   . "(later values win)\n";
	} elsif ($n_dup_rn) {
		warn "read_table: $n_dup_rn rows of $file repeat an earlier row's name "
		   . "(later values win); the first is '$first_dup_rn->[0]', on data "
		   . "row $first_dup_rn->[1]\n";
	}
	# header-only files never hit a data row. A provisional (commented-out)
	# header was never confirmed against a data row, but with no data to
	# contradict it we accept it; either way still validate.
	$finalize_header->() if $header_seen && !$header_done;
	# A hoa's column arrays are now made when the header is finalized rather
	# than by the first push into them, so a file with a header and no data
	# rows would come back as one empty array per column. It has always come
	# back as {}, the way an aoh comes back as [], so keep it that way.
	%data = () if $otype eq 'hoa' && @hoa_cols && !@{ $hoa_cols[0] };
	if ($otype eq 'aoh' || $otype eq 'aoa') {
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
	# reject unknown arguments (mirrors read_table/write_table)
	my %allowed = map { $_ => 1 } qw(
		n rows na max_width ellipsis gap cols columns width
		to return_only row_names color colors
	);
	my @bad = sort grep { !$allowed{$_} } keys %args;
	die "view: unknown argument(s): @bad\n" if @bad;
	# n / rows (synonyms); reject conflicting or non-integer values
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
	my $label_col = $args{row_names};
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
			# an integer 'row_names' names the label column index
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

	# display helpers (UTF-8 / wide-char aware)
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

	# colour configuration (Data::Printer-style)
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

	# column types (alignment)
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

	# prepare every cell once: [bytes, width, colour-type]
	my @lab_cell = map { [ $prep->($_), (!defined $_ ? 'undef' : $lab_numeric ? 'array' : 'hash') ] } @labels;
	my @row_cell;
	for my $r (@raw) {
		push @row_cell, [ map { [ $prep->($r->[$_]), $val_type->($r->[$_]) ] } 0 .. $#cols ];
	}
	my @head_cell = map { [ $prep->($_) ] } @cols;
	my ($lh_b, $lh_w) = $prep->($lab_header);

	# column widths (display columns)
	my $lab_w = $lh_w;
	for my $c (@lab_cell) { $lab_w = $c->[1] if $c->[1] > $lab_w; }
	my @w;
	for my $j (0 .. $#cols) {
		my $width = $head_cell[$j][1];
		for my $r (@row_cell) { $width = $r->[$j][1] if $r->[$j][1] > $width; }
		$w[$j] = $width;
	}

	# pad: spaces are never coloured; only the value text is
	my $field = sub {
		my ($bytes, $bw, $width, $right, $type) = @_;
		my $gapn = $width - $bw; $gapn = 0 if $gapn < 0;
		my $sp = ' ' x $gapn;
		my $painted = $paint->($bytes, $type);
		return $right ? $sp . $painted : $painted . $sp;
	};

	# break columns into chunks that fit within $tw (R-style)
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
#   conf_level  confidence level, default 0.95 (the dotted conf.level is
#               refused as an unknown option)
#   ordered     if true, order each factor's levels by increasing mean
#
# Returns a hashref: one entry per factor mapping to an arrayref of
# comparison hashes { comparison, diff, lwr, upr, 'p adj' } in R's
# lower-triangle order, plus the attributes 'conf_level' and 'ordered'.
#
# Scope: main-effect factors (those present in $fit->{xlevels}); a grouping
# variable must be categorical (string levels) to be treated as a factor,
# exactly as R requires factor().  MSE is the residual mean square (for glm
# this is deviance/df_residual: exact for the gaussian family, a Wald-type
# scale otherwise).  Per-level means are observed marginal means, which
# match R's model.tables means for one-way (and balanced) designs.
sub TukeyHSD {
	my ($fit, %opt) = @_;
	die 'TukeyHSD: first argument must be a fitted-model hashref (from aov/lm/glm)'
		unless ref($fit) eq 'HASH';
	my %known = map { $_ => 1 } qw(conf_level data formula ordered response which);
	my @bad = sort grep { !$known{$_} } keys %opt;
	die "TukeyHSD: unknown argument(s): @bad\n" if @bad;

	my $conf = exists $opt{conf_level} ? $opt{conf_level} : 0.95;
	die 'TukeyHSD: conf_level must be between 0 and 1'
		unless $conf > 0 && $conf < 1;
	my $ordered = $opt{ordered} ? 1 : 0;

	my $data = $opt{data}
		or die "TukeyHSD: 'data' (the data frame used to fit the model) is required";

	# residual mean square (MSE) and residual d.f., per model type
	my ($mse, $df);
	if (ref($fit->{Residuals}) eq 'HASH') {                 # aov
		$df  = $fit->{Residuals}{Df};
		$mse = $fit->{Residuals}{'Mean Sq'};
	} elsif (exists($fit->{rss}) && exists($fit->{'df_residual'})) {         # lm
		$df  = $fit->{'df_residual'};
		$mse = ($df > 0) ? $fit->{rss} / $df : undef;
	} elsif (exists($fit->{deviance}) && exists($fit->{'df_residual'})) {    # glm
		$df  = $fit->{'df_residual'};
		$mse = ($df > 0) ? $fit->{deviance} / $df : undef;
	} else {
		die 'TukeyHSD: could not find residual MSE/df in the fit (expected aov/lm/glm output)';
	}
	die 'TukeyHSD: residual degrees of freedom must be >= 2 (got '
		. (defined($df) ? $df : 'undef') . ')'
		unless defined($df) && $df >= 2;
	die 'TukeyHSD: could not determine a positive residual mean square'
		unless defined($mse) && $mse > 0;

	# WIDE one-way layout
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
			'conf_level' => $conf,
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

	# factors present in the model (idx 0 of each xlevels entry = reference)
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

	$out{'conf_level'} = $conf;      # attributes, R-style
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
			my $padj  = Stats::LikeR::ptukey(abs($est), $k, $df, 'lower_tail' => 0);
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
# detector); 'output_type' defaults to the input family, like agg().

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
# Order group keys by their representative value tuple.  Each tuple position
# is compared on its own terms: numerically when every defined value in that
# position (across every group) looks like a number, else as strings.  Within a
# position undef sorts last, as pandas puts its NaN group, and a NaN sorts after
# every number and before undef -- `<=>` has no answer for it, and under this
# module's FATAL warnings a sort comparator that returns undef dies.
#
# Up to 0.3212 one numeric-or-string decision covered every position and any
# undef made it "string", so by => ['sex', 'age'], or a single missing key,
# sorted the numbers 10, 2, 9.  Used by agg() and pivot_table().  Not exported.
sub _sort_group_keys {
	my ($order, $repr) = @_;
	return [ @$order ] unless @$order;
	my $width = @{ $repr->{ $order->[0] } };
	my @num = (1) x $width;
	for my $k (@$order) {
		my $t = $repr->{$k};
		for my $j (0 .. $width - 1) {
			$num[$j] = 0 if $num[$j] && defined $t->[$j] && !looks_like_number($t->[$j]);
		}
	}
	# per position: [ class, value ]; class 0 = value, 1 = NaN, 2 = undef
	my %key;
	for my $k (@$order) {
		my $t = $repr->{$k};
		$key{$k} = [ map {
			my $v = $t->[$_];
			!defined $v  ? ( 2, 0 )
			: !$num[$_]  ? ( 0, $v )
			: $v != $v   ? ( 1, 0 )
			:              ( 0, 0 + $v )
		} 0 .. $width - 1 ];
	}
	return [ sort {
		my ($ka, $kb) = ($key{$a}, $key{$b});
		my $c = 0;
		for my $j (0 .. $width - 1) {
			my $i = 2 * $j;
			last if $c = $ka->[$i] <=> $kb->[$i]
			          || ( $num[$j] ? $ka->[$i + 1] <=> $kb->[$i + 1]
			                        : $ka->[$i + 1] cmp $kb->[$i + 1] );
		}
		$c;
	} @$order ];
}

# melt($df, id_vars => $col|\@cols, value_vars => $col|\@cols,
#      var_name => 'variable', value_name => 'value', 'output_type' => aoa|aoh|hoa|hoh)
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
#   'output_type' aoa|aoh|hoa|hoh; default the input family.  For aoa output
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
	              value_name => 1, 'output_type' => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "melt: unknown argument(s): @bad\n" if @bad;

	my @id = !defined $arg{id_vars}        ? ()
	       : ref $arg{id_vars} eq 'ARRAY'  ? @{ $arg{id_vars} }
	       :                                 ( $arg{id_vars} );
	my $var_name   = defined $arg{var_name}   ? $arg{var_name}   : 'variable';
	my $value_name = defined $arg{value_name} ? $arg{value_name} : 'value';
	my $otype = defined $arg{'output_type'} ? lc $arg{'output_type'} : lc $shape;
	my %ok_otype = ( aoa => 1, aoh => 1, hoa => 1, hoh => 1 );
	die "melt: output_type '$otype' isn't allowed (aoa, aoh, hoa, hoh)\n"
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

	# Column-major, straight into the requested shape.  This used to build the
	# whole long frame first, as one arrayref-of-arrayrefs record per output
	# row, and then walk it again to materialise -- so a melt of R rows over V
	# value columns held R*V records, each with a nested arrayref of the id
	# values, alive at the same time as the result it was about to become.  On
	# a million-row frame with ten value columns that is ten million throwaway
	# containers, and none of them is anything the output needs.  Emitting as
	# the loops go keeps only the result.
	my (@aoa, @aoh, %hoa, %hoh);
	if ($otype eq 'hoa') { $hoa{$_} = [] for @id, $var_name, $value_name }
	my $n = 0;
	for my $v (@val) {
		my $vcol = $col->{$v};
		for (my $i = 0; $i < $R; $i++) {
			if ($otype eq 'aoa') {
				push @aoa, [ (map { $col->{$_}[$i] } @id), $v, $vcol->[$i] ];
			} elsif ($otype eq 'hoa') {
				push @{ $hoa{ $id[$_] } }, $col->{ $id[$_] }[$i] for 0 .. $#id;
				push @{ $hoa{$var_name} },   $v;
				push @{ $hoa{$value_name} }, $vcol->[$i];
			} else {                             # aoh and hoh share the row
				my %h;
				@h{ @id } = map { $col->{$_}[$i] } @id;
				$h{$var_name}   = $v;
				$h{$value_name} = $vcol->[$i];
				if ($otype eq 'aoh') { push @aoh, \%h }
				else                 { $hoh{ $n++ } = \%h }   # hoh: RangeIndex
			}
		}
	}
	return \@aoa if $otype eq 'aoa';
	return \@aoh if $otype eq 'aoh';
	return \%hoa if $otype eq 'hoa';
	return \%hoh;
}

# pivot_table($df, index => $col|\@cols, columns => $col|\@cols,
#             values => $col|\@cols, aggfunc => 'mean', fill_value => undef,
#             skipna => 1, sort => 1, sep => '.', 'output_type' => ...)
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
#   'output_type' aoa|aoh|hoa|hoh; default input family.  For hoh the row
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
	              'output_type' => 1 );
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
	my $otype    = defined $arg{'output_type'} ? lc $arg{'output_type'} : lc $shape;
	my %ok_otype = ( aoa => 1, aoh => 1, hoa => 1, hoh => 1 );
	die "pivot_table: output_type '$otype' isn't allowed (aoa, aoh, hoa, hoh)\n"
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

# table_one: a stratified descriptive "Table 1"
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
		return ($r->{'p_value'}, $nonpar ? 'wilcoxon' : 't-test');
	}
	# >2 groups: Kruskal-Wallis (nonparametric) or one-way ANOVA
	my (@x, @lab);
	for my $i (0 .. $#g) { push @x, @{ $g[$i] }; push @lab, ("g$i") x scalar @{ $g[$i] } }
	if ($nonpar) {
		return (kruskal_test(\@x, \@lab)->{'p_value'}, 'kruskal-wallis');
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
	return ($r->{'p_value'}, 'chi-squared');
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
	# One pass that buckets every row, rather than a full scan of the frame per
	# group: the row lists were built by O(groups x rows) greps, which is the
	# same shape as the O(levels x groups x rows) counting further down that
	# this file already records having replaced with a single pass.
	my %gpos; @gpos{ @groups } = 0 .. $#groups;
	my @grp_rows = map { [] } @groups;
	for my $r (0 .. $R - 1) { push @{ $grp_rows[ $gpos{ $grp[$r] } ] }, $r }

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
				($row{'p_value'}, $row{test}) = _t1_cont_p(\@byg, $nonpar);
			}
			push @out, \%row;
		}
		else {
			my %lseen;
			my @levels = sort grep { !$lseen{$_}++ }
			             map { defined $_ ? "$_" : 'NA' } @vals;
			# Every count below comes from one pass per group plus one over the
			# frame, looked up by level afterwards.
			#
			# They used to come from a `grep` over a group's rows for each
			# (level, group) pair -- run twice, once to build the table
			# _t1_cat_p() sees and again to format the output rows -- plus one
			# more scan of every row per level for the Overall column. That is
			# O(levels x groups x rows), and on 20000 rows it cost 0.021s at 5
			# levels against 0.120s at 40, growing without bound in the number
			# of levels where one pass is flat in it.
			#
			# $lab[$r] is the level row $r contributes, indexed over 0 .. $R-1
			# rather than over @vals so that a column shorter than the frame
			# still reads as 'NA' past its end, exactly as indexing $vals[$_]
			# out of range did. @levels stays derived from @vals, so a level
			# that no row in range carries still prints, with a count of 0.
			my @lab = map { defined $vals[$_] ? "$vals[$_]" : 'NA' } 0 .. $R - 1;
			my @gcnt;                         # $gcnt[$gi]{$level} = rows in that group
			for my $gi (0 .. $#grp_rows) {
				my %c;
				$c{ $lab[$_] }++ for @{ $grp_rows[$gi] };
				$gcnt[$gi] = \%c;
			}
			my %allcnt;
			$allcnt{$_}++ for @lab;
			my %hdr = (variable => $v, level => '', type => 'categorical');
			if (defined $by && @groups >= 2) {
				my @table;
				for my $lv (@levels) {
					push @table, [ map { $gcnt[$_]{$lv} || 0 } 0 .. $#grp_rows ];
				}
				($hdr{'p_value'}, $hdr{test}) = _t1_cat_p(\@table);
			}
			push @out, \%hdr;
			for my $lv (@levels) {
				my %row = (variable => $v, level => $lv, type => 'categorical');
				for my $gi (0 .. $#groups) {
					my $cnt = $gcnt[$gi]{$lv} || 0;
					my $tot = scalar @{ $grp_rows[$gi] };
					$row{ $groups[$gi] } = $tot ? sprintf('%d (%.*f%%)', $cnt, $pdig, 100 * $cnt / $tot) : '0';
				}
				my $cntall = $allcnt{$lv} || 0;
				$row{Overall} = $R ? sprintf('%d (%.*f%%)', $cntall, $pdig, 100 * $cntall / $R) : '0';
				push @out, \%row;
			}
		}
	}
	return \@out;
}

# Effect sizes (Perl level; compose the XS primitives mean/var/aov).  All
# validated numerically against R.  Added to @EXPORT_OK (== @EXPORT).

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

# cohen_d(\@x, \@y, conf_level => 0.95)
#
# Cohen's d for two independent samples using the pooled standard deviation,
# with the Hedges' g small-sample bias correction and a large-sample
# (normal-approximation) confidence interval.
sub cohen_d {
	my ($x, $y, %opt) = @_;
	my @bad = sort grep { $_ ne 'conf_level' } keys %opt;
	die "cohen_d: unknown argument(s): @bad\n" if @bad;
	my $cl = defined $opt{conf_level} ? $opt{conf_level} : 0.95;
	die "cohen_d: conf_level must be between 0 and 1\n" unless $cl > 0 && $cl < 1;
	my ($xn, $yn) = _num_pair($x, $y, 'cohen_d');
	my ($n1, $n2) = (scalar @$xn, scalar @$yn);
	my ($m1, $m2) = (mean($xn), mean($yn));
	my ($v1, $v2) = (var($xn),  var($yn));
	my $sp = sqrt((($n1 - 1) * $v1 + ($n2 - 1) * $v2) / ($n1 + $n2 - 2));
	die "cohen_d: pooled standard deviation is zero\n" if $sp == 0;
	my $d  = ($m1 - $m2) / $sp;
	my $J  = 1 - 3 / (4 * ($n1 + $n2) - 9); # Hedges' correction factor
	my $se = sqrt(($n1 + $n2) / ($n1 * $n2) + $d * $d / (2 * ($n1 + $n2)));
	my $z  = qnorm((1 + $cl) / 2);
	return {
		estimate     => $d,
		hedges_g     => $d * $J,
		pooled_sd    => $sp,
		se           => $se,
		'conf_int'   => [ $d - $z * $se, $d + $z * $se ],
		'conf_level' => $cl,
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

# Regression diagnostics (Perl level).  Validated numerically against R.
#
# _lgamma/_igamc/_pchisq_upper used to be pure-Perl ports of the XS igamc()
# living here.  They are now XS (see LikeR.xs), so there is one implementation
# instead of two that could disagree; _lgamma went away entirely because only
# _igamc ever called it.  _qnorm went the same way in 0.303: it was Acklam's
# rational approximation, good to about 1e-9, and cohen_d's interval is now
# built from the XS qnorm() that every other confidence limit in the
# distribution uses.

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
		my $r2 = $m->{'r_squared'};
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
		'p_value'   => _pchisq_upper($chi, $df),
		groups    => $used,
		table     => \@groups,
	};
}

# _qgamma($p, $shape, $scale): quantile of the gamma distribution, found by
# inverting the regularized lower incomplete gamma P(shape, x) = p (bisection).
#
# The bisection compares against _pgamma_lower, which is the XS igam() and
# computes the lower tail directly.  It used to form that tail as
# `1 - _igamc($shape, $x)`, and subtracting from 1 is precisely the
# cancellation igam() was added to avoid: below a lower tail of about
# NV_EPSILON the difference can only be a multiple of NV_EPSILON, so every
# candidate the bisection tried compared equal and the search converged on
# noise.  age_standardize() reaches this with p = alpha/2, so it is the lower
# confidence limit at a high conf_level that was affected -- conf_level =>
# 0.9999 asks for the 5e-5 quantile, and 1 - _igamc could not resolve one.
sub _qgamma {
	my ($p, $shape, $scale) = @_;
	$scale = 1 unless defined $scale;
	return 0 if $p <= 0 || $shape <= 0;
	return 9**9**9 if $p >= 1;
	my ($lo, $hi) = (0, 1);
	$hi *= 2 while _pgamma_lower($shape, $hi) < $p && $hi < 1e15;
	for (1 .. 300) {
		my $mid = ($lo + $hi) / 2;
		last if $mid <= $lo || $mid >= $hi;      # adjacent NVs: nothing left
		if (_pgamma_lower($shape, $mid) < $p) { $lo = $mid } else { $hi = $mid }
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
	my %known = map { $_ => 1 } qw(count pop stdpop rate per conf_level);
	my @bad = sort grep { !$known{$_} } keys %opt;
	die "age_standardize: unknown argument(s): @bad\n" if @bad;
	$rate ||= $opt{rate};
	my $cl  = defined $opt{conf_level} ? $opt{conf_level} : 0.95;
	my $per = defined $opt{per} ? $opt{per} : 1;
	die "age_standardize: conf_level must be between 0 and 1\n" unless $cl > 0 && $cl < 1;
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
		'conf_int'   => [ $lci * $per, $uci * $per ],
		se           => sqrt($var) * $per,
		'conf_level' => $cl,
		per          => $per,
	};
}


# anova($fit0, $fit1, ..., test => 'Chisq' | 'LRT' | 'F', dispersion => $phi)
#
# Nested-model comparison on fits that already exist -- R's anova(m0, m1) --
# for lm() and glm() results, and MASS's likelihood-ratio table for
# negative-binomial fits whose theta was estimated.  The XS anova() compares
# models it fits itself from a data set and formulas; this is the same
# question asked of fits the caller already has, which is what a first-stage
# F on excluded instruments or a joint test of a block of terms needs.  Any
# call whose first argument is not a fitted model goes to the XS function
# unchanged.
#
# The arithmetic is R's: anova.lmlist() for lm, anova.glmlist() and
# stat.anova() for glm, anova.negbin() for glm.nb.  Rows come back in the
# order given (MASS's negbin table is sorted by residual df, as it sorts it),
# each a hash; every row after the first carries the comparison with the row
# before it.
{
	my $xs_anova = \&anova;
	# The XS anova() is prototyped ($@), which would put anova(@fits) in
	# scalar context and hand it the number of fits; the replacement has no
	# prototype, which changes nothing for the XS call forms.
	no warnings qw(redefine prototype);
	*anova = sub {
		return _anova_fits(@_) if @_ && _is_fit($_[0]);
		goto &$xs_anova;
	};
}

sub _is_fit {
	my $f = shift;
	return ref $f eq 'HASH' && exists $f->{coefficients} && exists $f->{'df_residual'}
		&& !ref $f->{'df_residual'} && (exists $f->{rss} || exists $f->{deviance});
}

sub _anova_fits {
	my @m;
	push @m, shift while @_ && _is_fit($_[0]);
	die "anova: options after the models must be name => value pairs\n" if @_ % 2;
	my %opt = @_;
	for (keys %opt) {
		die "anova: unknown argument '$_'\n" unless /^(?:test|dispersion)$/;
	}
	die "anova: give at least two fitted models to compare\n" if @m < 2;
	my $is_glm = exists $m[0]{family};
	for (@m) {
		die "anova: cannot compare lm() and glm() fits in one table\n"
			if (exists $_->{family}) != $is_glm;
		die "anova: models are not all of the same family\n"
			if $is_glm && $_->{family} ne $m[0]{family};
	}
	# anova.lmlist / anova.glmlist: "models were not all fitted to the same
	# size of dataset"
	my @n = map { $is_glm ? $_->{nobs} : $_->{'df_residual'} + $_->{rank} } @m;
	for (@n) {
		die "anova: models were not all fitted to the same size of dataset\n"
			unless defined $_ && $_ == $n[0];
	}
	my $fam = $is_glm ? $m[0]{family} : 'lm';
	$fam = 'negbin' if $fam eq 'negative.binomial' || $fam eq 'nb';
	if ($fam eq 'negbin' && !grep { !exists $_->{'SE_theta'} } @m) {
		# MASS anova.negbin(): theta was estimated in every model, so the
		# models differ in theta too and only the likelihood-ratio test is
		# valid.  MASS sorts by residual df, largest first.
		die "anova: negbin models are compared by the likelihood-ratio test only\n"
			if defined $opt{test} && $opt{test} !~ /^(?:Chisq|LRT)$/;
		my @o = sort { $b->{'df_residual'} <=> $a->{'df_residual'} } @m;
		my @rows;
		for my $i (0 .. $#o) {
			my %r = (theta => $o[$i]{theta}, 'Resid. df' => $o[$i]{'df_residual'},
			         '2 x log-lik.' => $o[$i]{twologlik});
			if ($i) {
				my $df = $o[$i - 1]{'df_residual'} - $o[$i]{'df_residual'};
				my $lr = $o[$i]{twologlik} - $o[$i - 1]{twologlik};
				$r{df} = $df;
				$r{'LR stat.'} = $lr;
				# MASS: 1 - pchisq(x2, df); the upper tail directly here
				$r{'Pr(Chi)'} = pchisq($lr, $df, lower => 0);
			}
			push @rows, \%r;
		}
		return \@rows;
	}
	my @resdf  = map { $_->{'df_residual'} } @m;
	my @resdev = map { $is_glm ? $_->{deviance} : $_->{rss} } @m;
	my ($big) = sort { $resdf[$a] <=> $resdf[$b] } 0 .. $#m;   # order(resdf)[1]
	my ($test, $scale, $df_scale);
	if (!$is_glm) {
		# anova.lmlist: an F test on the largest model's residual mean square
		$test = defined $opt{test} ? $opt{test} : 'F';
		$scale = defined $opt{dispersion} ? $opt{dispersion} : $resdev[$big] / $resdf[$big];
		$df_scale = $resdf[$big];
	} else {
		# anova.glmlist: family$dispersion is 1 for binomial and poisson and
		# NA for gaussian; a negbin at a fixed theta has its variance fully
		# specified, and is treated like poisson (see glm's dispersion).
		my $known = $fam ne 'gaussian';
		$test = defined $opt{test} ? $opt{test} : ($known ? 'Chisq' : 'F');
		$scale = defined $opt{dispersion} ? $opt{dispersion} : $m[$big]{dispersion};
		$df_scale = (defined $opt{dispersion} ? $opt{dispersion} == 1 : $known)
		          ? 9**9**9 : $resdf[$big];
		if ($test eq 'F' && $df_scale == 9**9**9) {
			warn(($fam eq 'binomial' || $fam eq 'poisson')
			     ? "anova: using F test with a '$fam' family is inappropriate\n"
			     : "anova: using F test with a fixed dispersion is inappropriate\n");
		}
	}
	die "anova: test must be 'F', 'Chisq' or 'LRT'\n" unless $test =~ /^(?:F|Chisq|LRT)$/;
	my @rows;
	for my $i (0 .. $#m) {
		my %r = $is_glm ? ('Resid. Df' => $resdf[$i], 'Resid. Dev' => $resdev[$i])
		                : ('Res_Df' => $resdf[$i], 'RSS' => $resdev[$i]);
		if ($i) {
			my $df = $resdf[$i - 1] - $resdf[$i];
			my $dv = $resdev[$i - 1] - $resdev[$i];
			$r{Df} = $df;
			$r{ $is_glm ? 'Deviance' : 'Sum of Sq' } = $dv;
			# stat.anova(): a zero or negative statistic has no p-value (NA)
			if ($test eq 'F') {
				my $F = ($df != 0) ? ($dv / $df) / $scale : undef;
				$F = undef if defined $F && $F < 0;
				$r{F} = $F;
				$r{'Pr(>F)'} = defined $F
					? ($df_scale == 9**9**9 ? pchisq($F * abs($df), abs($df), lower => 0)
					                        : pf($F, abs($df), $df_scale, lower => 0))
					: undef;
			} else {
				my $v = ($df != 0) ? ($dv / $scale) * ($df <=> 0) : undef;
				$v = undef if defined $v && $v < 0;
				$r{'Pr(>Chi)'} = defined $v ? pchisq($v, abs($df), lower => 0) : undef;
			}
		}
		push @rows, \%r;
	}
	return \@rows;
}

# The PerlIO::via layers _open_decompressed() reads a compressed file through.
# PerlIO::via calls FILL whenever the parser's sv_gets() has used up the
# buffer, and FILL returns the next piece of decompressed text, or undef at
# the end.
#
# A file may hold several compressed members one after another, and every one
# of them is read: `cat a.gz b.gz' is a valid gzip file (RFC 1952 section 2.2)
# holding both, bgzip -- the BGZF format of tabix and every .vcf.gz -- writes
# nothing else, and pbzip2 does the same with bzip2 streams. Stopping at the
# first would drop all but the first 64 KB of a bgzip file without a word. NUL
# bytes between or after members are skipped, as Python's gzip module skips
# them (Lib/gzip.py, _GzipReader._read_eof(): "Gzip files can be padded with
# zeroes and still have archives"); anything else there is an error, as it is
# in Python, rather than being passed on as text, as R's gzio.h does
# ("transparent" mode).
#
# Each member's own check is made: zlib compares a gzip member's CRC-32 and
# length against its trailer, bzip2 its block and stream CRCs, and a mismatch
# comes back as corrupt data.
package Stats::LikeR::_Decompress;

our $name;	# the file being opened; see _open_decompressed()

# 1<<16, as a read of both the compressed bytes and the text made per call.
# read_table of a 2,000,000 x 5 CSV (110 MB, 47 MB gzipped) took 1.50 s from
# the .gz against 0.82 s from the plain file, three runs each; 1<<12 took
# 1.66 s, 1<<14 1.60 s, and 1<<18 and 1<<20 both 1.45 s. `zcat' alone takes
# 0.69 s, so the layer adds almost nothing to the inflate itself, and the last
# 3% is not worth four times the buffer. The .bz2 took 4.47 s, against 3.69 s
# for `bzip2 -dc' alone.
my $BUFSIZE = 1 << 16;

sub PUSHED {
	my ($class) = @_;
	return bless { name => $name, in => '', eof => 0, z => undef,
		members => 0 }, $class;
}

sub FILL {
	my ($self, $fh) = @_;
	my $magic = $self->MAGIC;
	for (;;) {
		if (!$self->{z}) {	# at the start of a member, or past the last
			$self->{in} =~ s/\A\0+// if $self->{members};
			if (length $self->{in} < length($magic) && !$self->{eof}) {
				$self->_more($fh);
				next;
			}
			return undef if !length $self->{in} && $self->{members};
			die "read_table: \"$self->{name}\" has data after its last "
			  . $self->CODEC . " member that is not " . $self->CODEC . "\n"
				unless substr($self->{in}, 0, length $magic) eq $magic;
			$self->{z} = $self->NEW;
		}
		my $before = length $self->{in};
		my $out = '';
		my ($status, $ended) = $self->INFLATE($out);
		die "read_table: \"$self->{name}\" is not valid " . $self->CODEC
		  . " data ($status)\n" unless defined $ended;
		if ($ended) {
			$self->{z} = undef;
			$self->{members}++;
		}
		return $out if length $out;
		next if $ended || length $self->{in} != $before;
		# no progress: the member wants more input than has been read
		die "read_table: \"$self->{name}\" ends in the middle of its "
		  . $self->CODEC . " data; it is truncated\n" if $self->{eof};
		$self->_more($fh);
	}
}

sub _more {
	my ($self, $fh) = @_;
	my $n = read $fh, $self->{in}, $BUFSIZE, length $self->{in};
	die "read_table: could not read \"$self->{name}\": $!\n" unless defined $n;
	$self->{eof} = 1 unless $n;
	return;
}

package Stats::LikeR::_Gunzip;
our @ISA = ('Stats::LikeR::_Decompress');

sub CODEC { 'gzip' }
sub MAGIC { "\x1f\x8b" }

sub NEW {
	# WANT_GZIP: a gzip wrapper, header and trailer, around each deflate
	# stream. LimitOutput caps what one call makes at about Bufsize, so one
	# 64 KB read of a highly compressible member cannot inflate into hundreds
	# of megabytes at once.
	my ($z, $err) = Compress::Raw::Zlib::Inflate->new(
		-WindowBits   => Compress::Raw::Zlib::WANT_GZIP(),
		-Bufsize      => $BUFSIZE,
		-ConsumeInput => 1,
		-LimitOutput  => 1);
	die "read_table: could not start inflating: $err\n" unless $z;
	return $z;
}

# (status, 1) at the end of a member, (status, 0) to go on, (status, undef) on
# corrupt data. Z_BUF_ERROR is "no progress possible", which with LimitOutput
# and ConsumeInput is how the stream asks for more input, not an error.
sub INFLATE {
	my ($self) = @_;
	my $status = $self->{z}->inflate($self->{in}, $_[1]);
	return ($status, 1) if $status == Compress::Raw::Zlib::Z_STREAM_END();
	return ($status, 0) if $status == Compress::Raw::Zlib::Z_OK()
		|| $status == Compress::Raw::Zlib::Z_BUF_ERROR();
	return ("$status", undef);
}

package Stats::LikeR::_Bunzip2;
our @ISA = ('Stats::LikeR::_Decompress');

sub CODEC { 'bzip2' }
sub MAGIC { 'BZh' }

sub NEW {
	# appendOutput 0, consumeInput 1, small 0, verbosity 0, limitOutput 1:
	# the same streaming contract as _Gunzip's.
	my ($z, $err) = Compress::Raw::Bunzip2->new(0, 1, 0, 0, 1);
	die "read_table: could not start bunzipping: $err\n" unless $z;
	return $z;
}

sub INFLATE {
	my ($self) = @_;
	my $status = $self->{z}->bzinflate($self->{in}, $_[1]);
	return ($status, 1) if $status == Compress::Raw::Bzip2::BZ_STREAM_END();
	return ($status, 0) if $status == Compress::Raw::Bzip2::BZ_OK();
	return ("$status", undef);
}

# The PerlIO::via layers write_table writes a .gz or .bz2 file through. The XS
# opens the file as for plain text and pushes :raw:via(<class>):perlio onto it
# (:crlf in place of :perlio where perl is a CRLF shop, so that Windows gets
# the CRLF a plain file would), and the rows reach WRITE 8 KB at a time from
# that buffer above rather than a field or a character at a time.
#
# The end of the stream -- zlib's final block and the gzip trailer, bzip2's
# end-of-stream marker -- cannot be written from FLUSH or CLOSE. The :perlio
# buffer above calls FLUSH after every 8 KB it hands down, so FLUSH does not
# mean "done", and PerlIO::via calls CLOSE only once the layer below has been
# closed (PerlIOVia_close() runs PerlIOBase_close() first; perl 5.10.1 and
# 5.42.0 ext/PerlIO-via/via.xs). So once the last row is written, the XS pops
# the :perlio layer and then this one, and POPPED finishes the stream while
# the file is still open.
#
# A write that croaks partway closes the handle without the pops, and then
# CLOSE runs before POPPED: the stream is left unfinished, on purpose, so that
# the file is a truncated .gz that read_table refuses rather than a complete
# one holding half the table.
#
# A failure goes back the PerlIO way, as -1 from PUSHED or WRITE; the XS turns
# it into a croak naming the file. PUSHED leaves its reason in $error.
package Stats::LikeR::_Compress;

our $error;

sub PUSHED {
	my ($class) = @_;
	my $z = eval { $class->NEW };
	if (!$z) {
		$error = $@ || 'could not start compressing';
		$error =~ s/\n\z//;
		return -1;
	}
	return bless { z => $z, closed => 0 }, $class;
}

sub WRITE {
	my ($self, $buf, $fh) = @_;
	my $out = '';
	return -1 unless $self->DEFLATE($buf, $out);
	return -1 if length $out && !print {$fh} $out;
	return length $buf;
}

sub FLUSH { 0 }

sub CLOSE {
	$_[0]{closed} = 1;
	return 0;
}

sub POPPED {
	my ($self, $fh) = @_;
	return if $self->{closed} || !$self->{z};
	my $out = '';
	# a failure here shows up as the error flag or the close of the layer
	# below, which is what the XS checks next
	print {$fh} $out if $self->FINISH($out) && length $out;
	$self->{z} = undef;
	return;
}

package Stats::LikeR::_Gzip;
our @ISA = ('Stats::LikeR::_Compress');

# Level 6 is Z_DEFAULT_COMPRESSION, the level of gzip(1) and of R's
# gzfile(compression = 6). zlib's gzip wrapper writes a header with no name
# and an mtime of 0, so the same table always makes the same bytes.
sub NEW {
	require Compress::Raw::Zlib;
	my ($z, $err) = Compress::Raw::Zlib::Deflate->new(
		-WindowBits => Compress::Raw::Zlib::WANT_GZIP(),
		-Level      => Compress::Raw::Zlib::Z_DEFAULT_COMPRESSION());
	die "could not start gzip compression: $err\n" unless $z;
	return $z;
}

sub DEFLATE {
	$_[0]{z}->deflate($_[1], $_[2]) == Compress::Raw::Zlib::Z_OK();
}

sub FINISH {
	$_[0]{z}->flush($_[1]) == Compress::Raw::Zlib::Z_OK();
}

package Stats::LikeR::_Bzip2;
our @ISA = ('Stats::LikeR::_Compress');

# appendOutput 1, blockSize100k 9, workfactor 0 (the default, 30), verbosity
# 0. 9 is bzip2(1)'s default and R's bzfile(compression = 9). Output is
# appended because DEFLATE may make it in two calls; WRITE and POPPED each pass
# an empty buffer.
sub NEW {
	require Compress::Raw::Bzip2;
	my ($z, $err) = Compress::Raw::Bzip2->new(1, 9, 0, 0);
	die "could not start bzip2 compression: $err\n" unless $z;
	return $z;
}

# bzip2 writes nothing until it has a whole 900 KB block, so a write that
# croaked before then would leave an empty file, and an empty file reads as an
# empty table rather than a broken one. The first WRITE therefore ends its
# block at once, which puts the stream header and that block on disk, and a
# file that is never finished is then a truncated bzip2 file, as a gzip one
# already is from its first write. It costs one short block at the start.
sub DEFLATE {
	my ($self) = @_;
	return 0 unless $self->{z}->bzdeflate($_[1], $_[2])
		== Compress::Raw::Bzip2::BZ_RUN_OK();
	return 1 if $self->{started}++;
	return $self->{z}->bzflush($_[2]) == Compress::Raw::Bzip2::BZ_RUN_OK();
}

sub FINISH {
	$_[0]{z}->bzclose($_[1]) == Compress::Raw::Bzip2::BZ_STREAM_END();
}

package Stats::LikeR;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stats::LikeR - Get basic statistical functions, like in R, but with Perl using XS for performance

=head1 VERSION

version 0.3216

=head1 Synopsis

Get basic statistical functions working in Perl as if they were part of List::Util, like C<min>, C<max>, C<sum>, etc.

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
     $r->{adj_rate}, $r->{'conf_int'}[0], $r->{'conf_int'}[1];

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
  <td><code>conf_level</code></td>
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
  <td><code>conf_int</code></td>
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
  <td><code>conf_level</code></td>
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
positions (a negative one counts from the end, as C<< $row-E<gt>[-1] >> does); for the
other three shapes they are column names. A column that no row has is an error,
so a misspelled name dies rather than coming back as a column of undef. An undef
row of an AoA or AoH is skipped. The original frame is never modified, down to
its scalars: a numeric cell is not given a cached string, nor a string cell a
cached number.

The split is done in C, in one pass that hashes each row's C<by> cells into its
group and a second that drops each aggregated cell straight into its group's
array, sharing the frame's own scalars wherever only the numeric aggregators
read them. On a million-row AoH in a thousand groups it takes about a quarter of
the time the pure-Perl split it replaced did, in about a fifth of the extra
memory.

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
     'output_type' => 'hoh',
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
(the cell comes back undef), matching pandas C<skipna=False>; that covers
C<mean>, C<median>, C<sum>, C<sd>, C<var>, C<min>, C<max> and C<mode>. C<count>, C<n>,
C<nunique>, C<first>, and C<last> ignore this flag.

=item * B<sort> — C<1> (default) sorts the output groups by key; C<0> keeps first-seen
order. Each C<by> column is compared on its own terms: numerically when every
value in it looks like a number, otherwise as strings. Within a column an
undef key sorts last (where pandas puts its NaN group) and a NaN sorts after
every number.

=item * B<output_type> — C<aoa>, C<aoh>, C<hoa>, or C<hoh>. Defaults to the same family
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
column in the group B<including undef>, and must return a single scalar. It
is called in scalar context, so C<sub { grep { .. } @{ $_[0] } }> returns a
count. The cells are copies; changing them does not change the frame:

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
B<two or more> it becomes C<< E<lt>colE<gt>_E<lt>funcE<gt> >>. A coderef's C<< E<lt>funcE<gt> >> is C<fn>, or
C<fn1>, C<fn2>, .. when a column has more than one. A column that is also a C<by>
column is always named C<< E<lt>colE<gt>_E<lt>funcE<gt> >>, so C<< by =E<gt> 'g', agg =E<gt> { g =E<gt> 'count' } >>
gives C<g> and C<g_count>. Any name that would still be generated twice is an
error, except under C<< output_type =E<gt> 'aoa' >>, whose columns are positional:

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

That holds for a frame with no rows too, as for pandas C<df.agg>: C<count> and C<n>
are 0 and the numeric aggregators undef. A grouped empty frame has no groups.

=head3 Array of Arrays (AoA)

Columns are integer positions. Grouping on column 0 and reducing column 1:

 my $aoa = [ [ 'M', 70 ], [ 'F', 60 ], [ 'M', 80 ] ];
 my $out = agg($aoa, by => 0, agg => { 1 => [ 'mean', 'max' ] });

 # [ [ 'F', 60, 60 ], [ 'M', 75, 80 ] ]
 #     ^grp  ^mean ^max

The output row is positional: the C<by> columns first, then each aggregated
column in the plan order.

=head3 Hash of Hashes (HoH) output

With C<< output_type =E<gt> 'hoh' >> the row label is the group value; multiple C<by>
columns are joined with a dot, an ungrouped result is keyed C<all>, and a
collision is made unique with a C<.N> suffix.

 my $out = agg($df, by => 'sex', agg => { wt => 'mean' }, 'output_type' => 'hoh');

 # {
 #     F => { sex => 'F', wt => 57.5 },
 #     M => { sex => 'M', wt => 75   },
 # }

=head3 Missing values

By default (C<< skipna =E<gt> 1 >>) undef cells are removed before a numeric aggregator
runs, so a group of C<(60, 55)> with a third undef still yields the mean of the
two defined values. C<count> reports only defined cells while C<n> counts undef
too. With C<< skipna =E<gt> 0 >>, a group containing any undef returns undef for the
numeric aggregators (C<mean median sum sd var min max mode>); the counting and
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

=item * an aggregator list for a column is empty, or holds something that is
neither a name nor a coderef;

=item * C<output_type> is not one of C<aoa>, C<aoh>, C<hoa>, C<hoh>;

=item * the trailing arguments are not C<< name =E<gt> value >> pairs;

=item * a column in C<by> or in the spec is undef, is in no row, is not an integer
position (AoA), or is not an arrayref (HoA);

=item * a row of an AoA or AoH is defined but not an ARRAY or HASH ref;

=item * two output columns would get the same name (see above);

=item * a numeric aggregator meets a cell that is not a number. The message names
the aggregator, the column and the group, as in
C<agg: mean of column 'v' over group (g = 'F'): mean: non-numeric value ..>.

=back

=head3 See also

C<group_by> (the split step), C<concat> / C<rbind> (row-binding frames),
C<dropna>, C<assign>, C<value_counts>.

=head2 anova

Sequential (Type-I) ANOVA table for a linear model, in the same shape C<aov>
returns. C<anova> fits C<response ~ terms>, then decomposes the model sum of
squares one term at a time, B<in R's term order> -- main effects first, then
two-way interactions, and so on, each group in formula order -- and F-tests
each term against the residual mean square. The formula is read by the same
parser C<lm> and C<glm> use.

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

Each term's C<Sum Sq> is what it adds to the terms before it in the formula,
not what it would explain alone. When the regressors are correlated, as in
C<anova.lm>'s own example on R's C<LifeCycleSavings>, reversing the formula
moves sum of squares from one term to another and changes their p-values. The
total of the terms and the C<Residuals> row do not move. In a balanced design
such as C<warpbreaks> the terms are orthogonal, so the order changes nothing.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/anova.order.png" alt="anova term order: the Sum Sq of sr ~ pop15 + pop75 + dpi + ddpi and of the reversed formula as stacked bars that differ term by term but share one total and one Residuals, beside breaks ~ wool + tension and tension + wool, which are identical" width="100%" /></p>

Two-way (and higher) models use the C<*> operator, which implicitly evaluates
the main effects alongside the interaction (C<a * b> expands to C<a + b + a:b>;
C<a * b * c> to the full factorial C<a + b + c + a:b + a:c + b:c + a:b:c>):

 my $res_2way = anova($data_2way, 'len ~ supp * dose');

Bare string columns are treated as factors; numeric columns, C<I(x^2)> and
C<log(x)> enter as single regressors. A factor is coded by treatment contrasts
or by a full set of indicators exactly as R decides it (its "margin rule"), so
nested and per-group-slope models come out as in R: C<y ~ a + a:b> gives C<a:b>
C<levels(a) * (levels(b) - 1)> degrees of freedom, and C<y ~ g + g:x> fits a
separate slope of C<x> in each group. C<- 1>, C<+ 0> and C<0 +> remove the
intercept, C<.> stands for every other column (taken in sorted order, since a
hash has no column order), C<offset(z)> is subtracted from the response, and
C<a:b> and C<b:a> are the same term. A term with no estimable column -- one that
is collinear with the terms before it -- is kept with 0 degrees of freedom and
0 sum of squares, where R leaves it out of the table. A column is judged
collinear by R's own rule: when what the earlier columns leave of it has a
norm below C<1e-7> of its own.

The fit keeps memory independent of the number of rows: it rotates one row at
a time into a C<p>-by-C<p> triangular factor (C<p> the number of design columns),
so a 100,000-row model with 801 columns needs about 2.5 MB rather than a
640 MB design matrix.

Given two or more formulas, C<anova> compares nested models instead and returns
an B<array ref> of rows, one per model in the order supplied — R's
C<anova(m1, m2, ...)>. Each row carries C<Res_Df>, C<RSS> and C<formula>; every row
after the first adds C<Df> and C<Sum of Sq>, the drops from the row before it,
and C<F> and C<< Pr(E<gt>F) >>:

 my $tab = anova($data, 'y ~ 1', 'y ~ x1', 'y ~ x1 + x2');
 printf "adding x2: F = %.4g, p = %.4g\n", $tab->[2]{F}, $tab->[2]{'Pr(>F)'};

C<F> is the C<Sum of Sq> per C<Df> over the residual mean square of the model with
the fewest residual degrees of freedom, and its p-value is taken on the
absolute C<Df>, so models listed largest first are tested too. As in R's
C<stat.anova>, C<F> and C<< Pr(E<gt>F) >> are left out where C<Df> is 0 or C<F> would be
negative (models that are not nested), and also where that residual mean
square is 0. Every model is fitted on the same rows: those complete for all of
them. As R's C<anova.lmlist> does, a model whose response differs from the
first model's is dropped with a warning, and if only one model is left, its
single-model table is returned.

Below, C<warpbreaks> is fitted as four nested formulas, each adding one term.
Each row's C<Sum of Sq> is the drop in C<RSS> from the row before it. Because
every C<F> is taken over the largest model's residual mean square, the chain
gives the same F values as the single-model table of the largest formula.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/anova.compare.png" alt="anova of nested formulas on warpbreaks: the RSS of breaks ~ 1, + wool, + tension and + wool:tension as bars, each drop labelled as that row's Sum of Sq and Df, and each drop per Df over the largest model's RSS / Res_Df giving an F equal to the one-model anova table's" width="100%" /></p>

Given two or more B<fitted models> instead -- C<lm> or C<glm> fits (or
C<negbin> C<glm> fits) of the same response on the same rows -- C<anova> compares
them as R's C<anova(m0, m1, ...)> does, and also returns an array ref of rows
in the order supplied. For C<lm> fits it is C<anova.lmlist>'s F test, on the
largest model's residual mean square (C<Res_Df>, C<RSS>, C<Df>, C<Sum of Sq>, C<F>,
C<< Pr(E<gt>F) >>). For C<glm> fits it is C<anova.glmlist>'s table (C<Resid. Df>,
C<Resid. Dev>, C<Df>, C<Deviance>) with a test chosen as R chooses it: a
likelihood-ratio C<< Pr(E<gt>Chi) >> for the families with a known dispersion, an F on
the largest model's dispersion for C<gaussian>; ask for one with
C<< test =E<gt> 'Chisq' >>, C<'LRT'> or C<'F'>, or fix the scale with C<dispersion>.
C<negbin> fits give C<MASS::anova.negbin>'s likelihood-ratio table (C<theta>,
C<Resid. df>, C<2 x log-lik.>, C<df>, C<LR stat.>, C<Pr(Chi)>), whose rows
are ordered by residual degrees of freedom.

 my $m0 = glm(formula => 'y ~ age',         data => \%d, family => 'poisson');
 my $m1 = glm(formula => 'y ~ age + hours', data => \%d, family => 'poisson');
 my $t  = anova($m0, $m1);
 printf "LR test for hours: p = %.3g\n", $t->[1]{'Pr(>Chi)'};

This is also how a first-stage F on a block of instruments is had without
L<C<ivreg>|/"ivreg">.

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
  <td>The dataset. A Hash of Arrays (HoA, columns, all the same length), Hash of Hashes (HoH) or Array of Hashes (AoH, rows) — the forms <code>lm</code> accepts.</td>
  <td></td>
</tr>
<tr>
  <td><code>formula_sv</code></td>
  <td><code>String</code></td>
  <td><i>(Required)</i></td>
  <td>Symbolic model <code>'response ~ rhs'</code>, with <code>+</code>, <code>:</code>, <code>*</code>, <code>.</code>, <code>- 1</code>/<code>0 +</code> and <code>offset()</code>, as <code>lm</code> reads it. Unlike <code>aov</code>, <code>anova</code> does <b>not</b> auto-stack, so a formula is mandatory. Give two or more to compare models.</td>
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
  <td>ANOVA-table stats for each term (<code>'ctrl'</code>, <code>'N:P'</code>, …), named as R names them: an interaction's variables in the order they first appear in the formula. <code>'Mean Sq'</code>, <code>'F value'</code> and <code>'Pr(&gt;F)'</code> are omitted for 0-df (aliased) terms.</td>
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
table" call. Note that both are B<Type-I / sequential>, so the order of terms
of the same degree matters, and both share this module's C<pf>, so p-values
agree with C<oneway_test> and the rest of Stats::LikeR. Both read the formula
with C<lm>'s parser and fit it the same way, so any formula one accepts the
other fits identically.

Comparing nested models -- C<anova(m1, m2)> in R -- is done by giving C<anova>
two or more formulas, or two or more fitted models; see above.

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

With one factor, the table is built like this. The factor's C<Sum Sq> is how
far its group means lie from the grand mean, and the C<Residuals> C<Sum Sq> is
how far the observations lie from their own group's mean, each squared and
summed. Each is divided by its C<Df> to
give its C<Mean Sq>. C<F value> is the term's C<Mean Sq> over the residual one,
and C<< Pr(E<gt>F) >> is the area of the F distribution on those two C<Df> beyond it.
Below, R's C<PlantGrowth> is given as a named list of three groups, which C<aov>
stacks into C<Value ~ Group>. The vertical lines on the left are the two kinds
of deviation: blue for each group's mean from the grand mean, grey for each
observation from its group's mean. The right-hand panel magnifies the tail
that C<< Pr(E<gt>F) >> measures, which is too thin to see at full scale.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/aov.what.png" alt="aov on PlantGrowth: the stacked observations with their group means and the grand mean, the Sum Sq split into Group and Residuals and divided by Df into Mean Sq and F, and Pr(&gt;F) as the tail of F(2, 27) beyond F = 4.846, also shown magnified" width="100%" /></p>

You can also perform Two-Way ANOVA with categorical interactions using the C<*> operator. The parser will implicitly evaluate the main effects alongside the interaction:

 my $res_2way = aov($data_2way, 'len ~ supp * dose');

The formula is read by C<lm>'s parser, the same one C<anova> uses, so it
accepts everything C<lm> does: C<+>, C<:>, C<*> (C<a*b*c> is every main effect and
interaction), C<.>, C<- 1>/C<0 +> and C<offset()>. Factors are coded by R's margin
rule, so an interaction need not have its main effects: C<y ~ a:b> spans every
cell, C<y ~ a + a:b> nests b in a, and C<y ~ g + g:x> fits a slope per group.
Terms are taken in R's order (main effects, then two-way interactions, …),
and C<a:b> and C<b:a> are one term, named as R names it. A column of strings is
a factor with its levels sorted; a column of numbers is a covariate.

It is robust against rank deficiency: a column is aliased when what the
earlier columns leave of it has a norm below 1e-7 of its own, R's C<lm.fit>
rule, and a term left with no columns stays in the table with 0 degrees of
freedom and 0 sum of squares. R's C<anova()> leaves such a term out.

The fit is Gentleman's Givens rotations, one row at a time, as C<anova> and
R's C<biglm> fit, so memory does not grow with the number of rows beyond the
row names that C<fitted_values> is keyed by. C<y ~ g*h + x> over 100,000 rows
with a 50-level C<g> takes 1.8 s and 52 MB.

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
  <td>A symbolic description of the model to be fitted. If omitted, the formula automatically defaults to <code>'Value ~ Group'</code> and the input data is stacked, with <code>Group</code> a factor whatever its names look like.</td>
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
  <td>A nested hash for each term of the model (e.g., <code>'Group'</code>, <code>'N:P'</code>), containing its ANOVA table statistics. <code>'Mean Sq'</code> is omitted for a 0-df (aliased) term, and <code>'F value'</code> and <code>'Pr(&gt;F)'</code> wherever there are no residual degrees of freedom or the fit is exact (R's <code>NA</code>).</td>
  <td><code>{'Df' =&gt; 1, 'Sum Sq' =&gt; 14.2, 'Mean Sq' =&gt; 14.2, 'F value' =&gt; 25.81, 'Pr(&gt;F)' =&gt; 0.0004}</code></td>
</tr>
<tr>
  <td><code>Residuals</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash containing the residual (error) statistics for the fitted model. <code>'Mean Sq'</code> is omitted when there are no residual degrees of freedom.</td>
  <td><code>{'Df' =&gt; 10, 'Sum Sq' =&gt; 5.5, 'Mean Sq' =&gt; 0.55}</code></td>
</tr>
<tr>
  <td><code>group_stats</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>The response's mean and count in each level of each factor of the model, over the rows the model was fitted on. With one factor -- the stacked form's <code>Group</code>, or <code>y ~ g</code> -- <code>mean</code> and <code>size</code> are keyed by level, the shape <code>oneway_test</code> returns; with several, by factor and then level. A model with no factor has none, and both are empty. A stacked group with no usable value has size 0 and a <code>NaN</code> mean.</td>
  <td><code>{'mean' =&gt; {'A' =&gt; 2.1, 'B' =&gt; 5.4}, 'size' =&gt; {'A' =&gt; 10, 'B' =&gt; 10}}</code>, or <code>{'mean' =&gt; {'wool' =&gt; {'A' =&gt; 31.04, 'B' =&gt; 25.26}, 'tension' =&gt; {...}}, ...}</code></td>
</tr>
<tr>
  <td><code>coefficients</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>The coefficients, under treatment contrasts and with R's names (<code>Intercept</code>, <code>woolB</code>, <code>woolB:tensionL</code>). An aliased one is <code>NaN</code>, R's <code>NA</code>.</td>
  <td><code>{'Intercept' =&gt; 2, 'gB' =&gt; 3}</code></td>
</tr>
<tr>
  <td><code>fitted_values</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>Fitted values, offsets included, keyed by row name: the HoH key, a <code>row_names</code> column, or 1..n. Rows dropped for a missing value have none.</td>
  <td><code>{'1' =&gt; 2, '2' =&gt; 2}</code></td>
</tr>
<tr>
  <td><code>xlevels</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>Each factor's levels, sorted, the reference level first; with <code>family</code> (<code>'gaussian'</code>), what <code>predict</code> reads.</td>
  <td><code>{'g' =&gt; ['A', 'B', 'C']}</code></td>
</tr>
</tbody>
</table>

The coefficients are steps away from one reference cell, which is the first
level of each factor in C<xlevels>. Because the levels are sorted, R's
C<warpbreaks> under C<breaks ~ wool * tension> has tension C<H> as its reference,
not C<L>. C<Intercept> is that cell's mean. Every other cell adds a main effect
for each of its non-reference levels and an interaction for each
non-reference pair, and the sum is the cell's fitted value. In a full
factorial such as this one, that fitted value is the cell mean.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/aov.coefficients.png" alt="aov coefficients on warpbreaks: for each of the six wool-by-tension cells, a staircase of Intercept, tension, wool and interaction coefficients that ends on that cell's fitted value" width="100%" /></p>

C<group_stats> is something else again. It holds each factor's own means, each
averaged over the other factors, so the cell means above are not among them.
The table has one row per term in R's order, followed by C<Residuals>, which
has no F test of its own.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/aov.outputs.png" alt="aov group_stats and table on warpbreaks: the marginal mean and size of each wool and tension level against the grand mean, and the Sum Sq, Df, Mean Sq, F value and Pr(&gt;F) of wool, tension, wool:tension and Residuals" width="100%" /></p>

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

A coderef is called in list context, on every row, and is classified by what it returns for the first row:

=over

=item * B<One scalar → per-row.> The sub is called once per row and that scalar is the cell.

=over

=item * C<$_> (and C<$_[0]>) is the current row as a hashref, so you read other columns with C<< $_-E<gt>{colname} >>.

=item * C<$_[1]> is the row's index (0-based).

=item * C<$_[2]> is the row key — B<HoH only>.

=item * A single arrayref return is stored I<as the cell>, so C<< sub { [split /,/, $_-E<gt>{tags}] } >> gives an arrayref-valued column.

=item * List context holds for every row, not just the first: C<< sub { $_-E<gt>{id} =~ /(\d+)/ } >> stores the captured digits in each row, and a match that fails returns the empty list, so its cell is C<undef>. A later row that returns more than one value dies.

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

C<map_cell { ... }> removes the ceremony. Inside the block, B<< C<$_> is the named column's current cell >> (not the whole row), the block's return value is B<ignored>, and the modified C<$_> is stored back -- for a HoA, C<$_> aliases the cell itself, so the edit is made where the cell lies:

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

=item * A B<HoA> may also hold plain scalar (or C<undef>) entries; each row view carries them through unchanged. An empty hash is an empty HoA, and its first arrayref value sets the row count, so C<< assign({}, x =E<gt> [1, 2, 3], y =E<gt> sub { $_-E<gt>{x} * 2 }) >> builds a frame from nothing.

=item * Rows, value types, arrayref lengths and C<map_cell> targets are all checked before anything is written, so a call that dies on one of those leaves C<$df> as it found it. A coderef that dies part-way through does not roll back the rows already written.

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

=item * B<< C<$_> is the real row, in every shape. >> For an AoH or HoH it is the row hash itself. For a HoA it is a view: one hash for the whole call, whose values I<are> the frame's cells for the current row, not copies of them. Either way, a write through C<< $_-E<gt>{col} >> changes the frame:

=back

 assign($hoa, z => sub { $_->{x} *= 10; $_->{x} + 1 });   # x is now 10 times bigger too

  For a HoA, that one view is re-pointed at each row in turn. A key the block adds to it is gone on the next row and never reaches the frame; a key it deletes comes back, and the column stays. Writing to a cell past the end of a short column is dropped rather than growing the column. A block that I<keeps> C<$_> (pushes it somewhere, or returns it) keeps that one view, which shows whichever row was visited last. A tied HoA, or one with a tied column, is the exception: its view is a fresh hash of copies on every row.
- B<It modifies your data frame.> If you need to keep the original, pass a copy: C<assign(clone($df), ...)>.
- Reusing a column name B<overwrites> that column.

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

=head2 avals

L<C<vals>|/"vals"> as a list. C<avals> takes the same two arguments, accepts the
same three data-frame shapes, uses the same shape detection, copies every cell
the same way and dies with the same messages — it only differs in the return,
pushing the column's values onto the stack instead of wrapping them in an array
reference:

 use Stats::LikeR qw(avals vals);

 my @ages =    avals($df, 'age');
 my @same = @{  vals($df, 'age') };   # identical, one arrayref later

Reach for it wherever the column is going straight into a list — another
function's arguments, a C<sort>/C<map>/C<grep> chain, a C<push>, an array or hash
slice:

 my @sorted = sort { $a <=> $b } avals($df, 'ldl');
 push @pooled, avals($df, 'ldl');

The functions that take a column I<by reference> still want L<C<vals>|/"vals">:
C<mean(vals($df, 'age'))> is right, and C<mean(avals($df, 'age'))> hands C<mean> a
bare list instead of the arrayref it expects.

An empty frame — an empty AoH, or an empty hash — yields the empty list. In
scalar context a list return collapses to its last element, which for a column
is almost never what was meant; assign to an array, or use L<C<vals>|/"vals">.

See L<C<vals>|/"vals"> for the argument table, the AoH / HoA / HoH detection rules,
the sorted key order of a HoH, and the missing-column behavior: apart from the
return, they are the same function.

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
 print $r->{enrichment}{'enrichment_factor'}; # e.g. 2.0 => 2x over random

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

 print $r->{'p_value'};               # 0.7539

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

 print $r->{'p_value'};                 # 0.0215

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
copied and the original structure left untouched. That includes the position
of an C<each> loop you are part-way through on the data or on one of its rows,
which carries on where it was. Tied hashes and arrays are accepted anywhere in
the data.

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

where C<$column_values> is an array ref of a copy of B<every> cell in the
column, in row order, with undef standing in for an undef or missing cell.
With C<keep>, columns for which the predicate is true are kept; with C<remove>,
those columns are dropped.

Two options change what the predicate is given, for functions that cannot take
undef:

=over

=item * C<< na =E<gt> 'omit' >> drops the undef and missing cells, so a one-column function
such as C<sd> gets clean input. C<< na =E<gt> 'keep' >> is the default described above.

=item * C<< against =E<gt> 'col' >> compares every column with the column named C<col>. The
predicate is called with three arguments,
C<< $predicate-E<gt>($column_values, $col_values, $column_name) >>, and both arrays
hold only the rows where B<both> columns are defined (pairwise complete),
so a two-column function such as C<cor> can take them directly.

=back

C<na> and C<against> cannot be given together.

 # Keep only the constant columns (standard deviation zero):
 my $const = cfilter(\%hoa, keep => sub { sd($_[0]) == 0 });   # { z => [0,0,0] }
 # Drop the constant columns instead:
 my $varying = cfilter(\%hoa, remove => sub { sd($_[0]) == 0 }); # { x=>..., y=>... }
 # A bare function name resolves in Stats::LikeR:: (use a package for your own):
 cfilter(\%hoa, keep => 'some_predicate');
 # Drop the constant columns of data with gaps: sd() gets only defined cells
 cfilter(\%gappy, remove => sub { sd($_[0]) == 0 }, na => 'omit');
 # Keep the columns strongly correlated with y (y itself included)
 cfilter(\%hoa, keep => sub { abs(cor($_[0], $_[1])) > 0.9 }, against => 'y');

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
to a value predicate), both are given, C<na> is not C<'keep'> or C<'omit'>, or
the C<against> column is not present in the data,

=item * the predicate itself dies, or replaces a row or column of the data with
something of the wrong shape while C<cfilter> is running,

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
                             'rescale_p' => 1);          # ... rescaled to sum to 1

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
  <td>Null probabilities for the goodness-of-fit test. An array ref, in the order of the data, when the data is an array ref; a hash ref keyed the same as the data when the data is a hash ref. They must sum to 1 unless <code>rescale_p</code> says otherwise, and it is an error to pass them with a contingency table.</td>
</tr>
<tr>
  <td><b>rescale_p</b></td>
  <td><code>0</code></td>
  <td>Divide <code>p</code> by its own sum first, so counts, weights or percentages can be passed instead of probabilities. R's dotted <code>rescale.p</code> is refused as an unknown argument.</td>
</tr>
</tbody>
</table>

 # goodness of fit against a non-uniform null
 my $res = chisq_test([89, 37, 30, 28, 2],
                      p => [0.40, 0.20, 0.20, 0.19, 0.01]);
 # $res->{statistic}{'X-squared'} == 5.79470854555744, df 4, p == 0.215013095920786

 # the same, from unnormalised weights
 my $res = chisq_test([89, 37, 30, 28, 2],
                      p => [40, 20, 20, 19, 1], 'rescale_p' => 1);

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
  <td><b>data_name</b></td>
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
  <td><b>p_value</b></td>
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
     'data_name' => 'Perl ArrayRef',
     'expected'  => [
         [ 703.671381936888, 319.645266594124, 533.683351468988 ],
         [ 542.328618063112, 246.354733405876, 411.316648531012 ]
     ],
     'method'    => "Pearson's Chi-squared test",
     'observed'  => [
         [ 762, 327, 468 ],
         [ 484, 239, 477 ]
     ],
     'p_value'   => 2.95358918321176e-07,
     'parameter' => { 'df' => 2 },
     'statistic' => { 'X-squared' => 30.0701490957547 }
 }

=head3 1-Dimensional Array (Goodness of Fit)

Passing a flat Array Reference triggers a Goodness of Fit test, assuming equal expected probabilities across all items.

 my $data = [10, 20, 30];
 my $res = chisq_test($data);

B<Output:>

 {
     'data_name' => 'Perl ArrayRef',
     'expected'  => [ 20, 20, 20 ],
     'method'    => 'Chi-squared test for given probabilities',
     'observed'  => [ 10, 20, 30 ],
     'p_value'   => 0.00673794699908547,
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
     'data_name' => 'Perl HashRef',
     'expected'  => {
     'GroupA' => { 'Failure' => 10, 'Success' => 15 },
     'GroupB' => { 'Failure' => 10, 'Success' => 15 }
 },
 'method'    => "Pearson's Chi-squared test with Yates' continuity correction",
     'observed'  => {
     'GroupA' => { 'Failure' => 15, 'Success' => 10 },
     'GroupB' => { 'Failure' => 5,  'Success' => 20 }
     },
     'p_value'   => 0.00937475878430379,
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

 print $r->{'p_value'};  # combined test across strata
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
     $d->{estimate}, $d->{'conf_int'}[0], $d->{'conf_int'}[1], $d->{hedges_g};

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
  <td><code>conf_int</code></td>
  <td><code>ArrayRef</code></td>
  <td><code>[lower, upper]</code> normal-approximation CI for <i>d</i>.</td>
  <td><code>[0.96, 3.67]</code></td>
</tr>
<tr>
  <td><code>conf_level</code></td>
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
  <td><i>(optional)</i> <code>na</code>, <code>skip_errors</code>, … (see <b>Options</b>).</td>
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

 col2col(\%data, 'cor', $cols, 'skip_errors' => 0);   # after $cols
 col2col(\%data, 'cor', { 'skip_errors' => 0 });      # hash ref, no $cols needed

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

C<rm_undef> / C<rm_na> remain as boolean aliases for backward compatibility:
C<true> means C<'pairwise'>, C<false> means C<'keep'>. Don't combine them with C<na>.
The old dotted spellings C<rm.undef> and C<rm.na> are refused as unknown options.

=head4 C<skip_errors> — keep going when a pair fails I<(default: true)>

Some functions croak on degenerate input — for example C<cor> dies if a column has
zero variance. By default C<col2col> B<traps> that croak per pair: instead of
aborting the whole run, it stores the B<first line> of the error message in that
cell, so the result tells you I<which> pair failed and I<why>. Every other cell is
computed normally.

 my $r = col2col(\%data, 'cor');
 # a good pair:   $r->{a}{b} == 0.83
 # a bad pair:    $r->{a}{const} eq 'cor: standard deviation of y is 0'

To restore the old "die on the first error" behaviour, turn it off:

 col2col(\%data, 'cor', undef, 'skip_errors' => 0);
 col2col(\%data, 'cor', { 'skip_errors' => 0 });

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
still croak for that pair. With the default C<skip_errors>, that shows up as a
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
(and always when you pass C<< exact =E<gt> 0 >>). That approximation's C<p_value> is
evaluated on the tail it belongs to, so a strong rank correlation reports its
actual p-value instead of a flat C<0>; see
L</"F and z tail p-values">. Checked against R's
C<cor.test(..., exact = FALSE)> over 54 Spearman and Kendall cases spanning
I<n> = 60 to 500 and all three alternatives: C<estimate> agrees to C<3e-15>,
Kendall's C<statistic> to C<2e-15>, and C<p_value> to C<1.7e-12> — the worst of
those at a p-value of C<2.2e-297>.

=head3 Spearman: which method, and what C<statistic> holds

C<spearman> follows R's C<cor.test> exactly: C<exact> defaults to true, and an
exact request is served by permutation enumeration for I<n> ≤ 9, by the AS 89
Edgeworth series for 10 ≤ I<n> ≤ 1290, and by the asymptotic I<t> above that or
whenever the data contain ties. Passing C<< exact =E<gt> 1 >> never enumerates past
I<n> = 9, because I<n>! is 6.2 × 10²³ by I<n> = 24.

C<statistic> is Spearman's I<S> on every one of those paths, formed the way R
forms it — C<(n³ − n)(1 − ρ)/6>, which is the sum of squared rank differences
only when there are no ties. One difference from R remains, and it is not about
the mathematics: at a perfect correlation R's C<cor()> returns a ρ that is
2.2e-16 short of 1, so R reports C<3.6637359812630166e-14> for an exact 0 at
I<n> = 10 where the Welford accumulation here returns exactly 1 and so gives
exactly 0. Pinned in C<t/cor_test.spearman.R.t>.

=head3 Kendall: ties, and the confidence interval

C<kendall>'s normal approximation carries R's full tie correction —

 var_S = (v0 − vt − vu)/18 + v1/(2n(n−1)) + v2/(9n(n−1)(n−2))

built from the tie-group sizes of each vector. That branch is reached exactly
when there are ties (without them, and below I<n> = 50, the exact distribution
is used instead), so the correction is never idle. The counts behind it come
from Knight's O(I<n> log I<n>) algorithm, the same one L<C<cor>|/"cor"> uses, which
is why a Kendall C<cor_test> on 64 000 points takes 0.014 s rather than 15.

C<pearson> reports a C<conf_int>, and it follows C<alternative>: a one-sided test
gets a one-sided interval, with the open end at exactly −1 or 1, as R's does.
There is no interval below I<n> = 4, again as in R — Fisher's I<z> has
1/√(n−3) for its standard error, so there is nothing to report. C<spearman> and
C<kendall> return no interval at all, which is also R's behaviour.

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

 print $fit->{'exp_coef'}[0];  # hazard ratio for age
 print $fit->{'p_value'}[0];   # its p-value

Or name the columns of a data set in a formula, as C<survival::coxph> does. The
response is C<Surv(time, status)>, or C<Surv(start, stop, status)> for
counting-process data; covariates expand as they do for L<C<lm>|/"lm"> and
L<C<glm>|/"glm"> (factors, interactions, C<I()>, C<log()>), and C<strata(g)> and
C<cluster(id)> terms are taken out of the covariates and used as below:

 my $fit = coxph(formula => 'Surv(tstart, tstop, event) ~ hours + age + strata(tech)',
                 data => \%d, cluster => 'child_id');

B<Counting-process data> -- one row per interval C<(start, stop]> over which a
subject's covariates are constant -- is what a time-varying covariate and late
entry both need. A subject is at risk at an event time only in the interval
that covers it. In the positional form give the start times as C<< start =E<gt> \@t0 >>.
Intervals that span no event contribute nothing and are skipped, as
C<survival>'s C<agreg.fit> skips them.

B<Strata> (C<strata(g)> in a formula, or C<< strata =E<gt> \@g >>) give each level its
own baseline hazard, with the covariate effects shared.

B<Robust variance.> With a cluster (C<cluster(id)>, or C<< cluster =E<gt> \@id >> or a
column name), C<se> is the grouped-jackknife (dfbeta) robust standard error that
C<coxph(..., cluster = id)> reports, and the model-based one moves to
C<naive_se>. C<< robust =E<gt> 1 >> without a cluster makes each row its own cluster,
which C<(start, stop]> data does not allow: a subject's intervals have to be
grouped by a cluster.
C<weights> are case weights and C<offset> a term with coefficient fixed at 1.

B<A changepoint profile> needs no function of its own: refit over a grid of
candidate thresholds and keep each C<loglik>. The maximum is the estimate; the
thresholds within C<qchisq(0.95, 1) / 2 = 1.92> of it are a likelihood-ratio
interval, which for a changepoint is only approximate, since the profile is a
step function of C<c> and the usual regularity conditions do not hold.

 my @grid = map { 40 + $_ } 0 .. 30;
 my %ll;
 for my $c (@grid) {
     $d{above} = [ map { $_ > $c ? 1 : 0 } @{ $d{hours} } ];
     $ll{$c} = coxph(formula => 'Surv(tstart, tstop, event) ~ above + age + strata(tech)',
                     data => \%d)->{loglik};
 }
 my ($best) = sort { $ll{$b} <=> $ll{$a} } @grid;
 my @ci = grep { $ll{$best} - $ll{$_} <= 1.92 } @grid;

=head3 Options

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
  <td><code>names</code></td>
  <td><code>x1</code>, <code>x2</code>, ...</td>
  <td>Covariate names in the positional form.</td>
</tr>
<tr>
  <td><code>ties</code></td>
  <td><code>'efron'</code></td>
  <td><code>'efron'</code> or <code>'breslow'</code>.</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td><code>0.95</code></td>
  <td>Level of <code>conf_int</code>.</td>
</tr>
<tr>
  <td><code>maxit</code></td>
  <td><code>20</code></td>
  <td>Newton iteration limit (R's <code>iter.max</code>, also accepted as <code>iter_max</code>; the dotted spelling is refused).</td>
</tr>
<tr>
  <td><code>eps</code></td>
  <td><code>1e-9</code></td>
  <td>Convergence tolerance on the relative log-likelihood change, <code>coxph.control(eps = )</code>.</td>
</tr>
<tr>
  <td><code>start</code></td>
  <td><i>none</i></td>
  <td>Positional form: interval start times, for <code>(start, stop]</code> data.</td>
</tr>
<tr>
  <td><code>strata</code></td>
  <td><i>none</i></td>
  <td>Positional form: one stratum label per row.</td>
</tr>
<tr>
  <td><code>cluster</code></td>
  <td><i>none</i></td>
  <td>One cluster label per row, or (formula form) a column name.</td>
</tr>
<tr>
  <td><code>weights</code></td>
  <td><i>none</i></td>
  <td>Case weights.</td>
</tr>
<tr>
  <td><code>offset</code></td>
  <td><i>none</i></td>
  <td>One offset per row.</td>
</tr>
<tr>
  <td><code>robust</code></td>
  <td><code>0</code>, or <code>1</code> with a cluster</td>
  <td>Report the robust variance.</td>
</tr>
</tbody>
</table>

=head3 Result

Parallel per-covariate arrays C<coef> (log-HR), C<exp_coef> (HR), C<se>, C<z>,
C<p_value> and C<conf_int> (HR scale), with C<names>; C<coefficients> by name;
C<var> (a matrix) and C<vcov> (a hash of hashes by name), the covariance the standard errors
come from; model-level C<loglik> (at the fit) and C<loglik_null>,
C<lr_stat>/C<lr_df>/C<lr_p_value> (likelihood-ratio test), C<score_test> and
C<wald_test>, C<n>, C<nevent>, C<iterations> and C<converged>. With a robust
variance it adds C<naive_se> and C<naive_var>, C<robust_score_test>, and
C<n_clusters>; with strata, C<strata> lists their labels. See
L<C<survfit>|/"survfit"> and L<C<logrank_test>|/"logrank_test">.

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
 my $sorted = csort($hoh,  $by, 'aoh', 'row_name');   # HoH only

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

 csort($aoa, 0)            # AoA -> AoA (default)
 csort($aoa, 0, 'hoa')     # AoA -> HoA
 csort($aoh, 'No.', 'aoa') # AoH -> AoA

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
column so it survives into the output; the column is named C<row_name> by
default, overridable with a fourth argument:

 my $s = csort($hoh, 'score', 'aoh');           # row name in 'row_name'
 my $s = csort($hoh, 'score', 'aoh', 'sample'); # ... named 'sample' instead

=head2 density

Kernel density estimation — a smooth curve through a sample, the continuous
answer to what C<hist> answers in bars. This is a port of R's C<density()>, down
to the algorithm: the mass of the sample is dispersed over a regular grid of at
least 512 points, that grid is convolved with a discretised kernel using the
fast Fourier transform, and the result is interpolated back onto the points you
asked for. It returns the same grid, the same bandwidth and the same estimate R
would.

 my $d = density(\@x);
 printf "%g\t%g\n", $d->{x}[$_], $d->{y}[$_] for 0 .. $#{ $d->{x} };

What that computes is one kernel — a little bump of area C<1/n> — centred on
every observation, added together. On the left below, seven observations and
their seven gaussian kernels; the blue curve through them is what C<density>
returns. On the right, the same thing over R's C<faithful$eruptions>, against
the histogram of the same sample: the two answer the same question, one in
bars and one as a curve.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/density.what.png" alt="density() is the sum of one kernel per observation, and the smooth counterpart of a histogram" width="100%" /></p>

Arguments may be given positionally (the sample first) or by name. Names use
underscores where R's use a dot (C<na_rm>, C<old_coords>, C<give_rkern>); R's
dotted spellings (C<na.rm>, C<old.coords>, C<give.Rkern>) are refused as unknown
arguments. R's C<warnWbw> is accepted as well as C<warn_wbw>.

 my $d = density(x => \@x, bw => 'SJ', kernel => 'epanechnikov', n => 1024);

=head3 Arguments

=over

=item * B<< C<x> >> — the sample, an array reference. Required (except with
C<give_rkern>). A missing value (C<undef> or C<NaN>) is an error unless
C<na_rm> is set; anything else non-numeric is always an error. An infinite
observation is treated as a point mass at ±∞, so it is counted in C<n> and
takes its share of the mass with it, leaving a sub-density on (−∞, ∞).

=item * B<< C<bw> >> — the smoothing bandwidth, which is the standard deviation of the
kernel. Either a positive number, or the name of a rule to choose one:
C<'nrd0'> (the default), C<'nrd'>, C<'ucv'>, C<'bcv'>, C<'SJ'> / C<'SJ-ste'>, or
C<'SJ-dpi'>. Rule names are case-insensitive. The five rules are also
available on their own as C<bw_nrd0>, C<bw_nrd>, C<bw_ucv>, C<bw_bcv> and
C<bw_sj>, described below.

=item * B<< C<adjust> >> — the bandwidth actually used is C<adjust * bw>, so
C<< adjust =E<gt> 0.5 >> asks for half the default smoothing. Defaults to 1.

=item * B<< C<kernel> >> — one of C<'gaussian'> (the default), C<'epanechnikov'>,
C<'rectangular'>, C<'triangular'>, C<'biweight'>, C<'cosine'> or C<'optcosine'>.
Any unambiguous abbreviation will do, so a single letter is enough for every
one of them, and the match is case-insensitive. All seven are scaled so that
C<bw> is the kernel's standard deviation, which is why changing the kernel
barely changes the estimate.

=item * B<< C<window> >> — an alias for C<kernel>, for compatibility with S. An explicit
C<kernel> wins.

=item * B<< C<width> >> — also for compatibility with S, where the argument is the
I<length of the kernel's support> rather than a multiple of its standard
deviation (for the gaussian, four standard deviations). Consulted only when
C<bw> is not given. A string names a rule, exactly as C<bw> does.

=item * B<< C<weights> >> — an array reference of non-negative observation weights, one
per element of C<x> — including the missing ones, so it is always the same
length as C<x> was to begin with. The default is C<1/nx> each. Weights that do
not sum to 1 give a I<sub>-density and draw a warning; pass C<< subdensity =E<gt> 1 >>
if that is what you meant. If C<na_rm> removes observations and the original
weights summed to one, the survivors are rescaled so they still do.
Bandwidth I<rules> ignore the weights, and say so; C<< warn_wbw =E<gt> 0 >> silences
that, and it is silent anyway when the weights do not vary.

=item * B<< C<n> >> — the number of equally spaced points at which to estimate. Defaults
to 512. Values above 512 are rounded up to a power of two internally (that
is what makes the FFT cheap) and the result is interpolated back to exactly
the C<n> you asked for, so a power of two is the efficient choice.

=item * B<< C<from>, C<to> >> — the ends of the output grid. The defaults are C<cut>
bandwidths outside the range of the data.

=item * B<< C<cut> >> — how many bandwidths past the extremes of the data the default
C<from> and C<to> reach, so that the estimate has room to fall to about zero.
Defaults to 3.

=item * B<< C<ext> >> — how many further bandwidths the internal FFT grid extends beyond
C<from> and C<to>. Defaults to 4. Do not change it unless you know why you are
changing it; it does not move the output grid, only the accuracy of the
values on it.

=item * B<< C<na_rm> >> — drop missing values instead of failing on them. Defaults to
off, which is R's default too.

=item * B<< C<subdensity> >> — suppress the "weights do not sum to one" warning, because
a sub-density is what was wanted.

=item * B<< C<warn_wbw> >> — whether to warn that an automatic bandwidth ignored the
weights. Defaults on when the weights vary.

=item * B<< C<old_coords> >> — reproduce the pre-R-4.4.0 grid, whose values are too
large by a factor of about C<1 + 1/(2n-2)>. For reproducing old results only.

=item * B<< C<give_rkern> >> — return R(K), the kernel's I<canonical bandwidth>, and no
density at all. See below.

=item * B<< C<nb> >> — the number of bins the C<'ucv'>, C<'bcv'> and C<'SJ'> rules use for
their pair counts. Defaults to 1000, as in R.

=back

=head3 What the arguments do

C<bw> is the whole ballgame. It is the standard deviation of the kernel, so it
sets how wide each bump is, and C<adjust> multiplies it: C<< adjust =E<gt> 0.5 >> is half
the default smoothing. Too little and the estimate follows the individual
observations (the ticks along the bottom are the sample); too much and the two
modes of C<eruptions> melt into one. C<bw> is reported back in the return value,
so the number in each label below is C<< $d-E<gt>{bw} >>.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/density.bandwidth.png" alt="the same sample at four bandwidths, from far too small to far too large" width="100%" /></p>

C<kernel> chooses the shape of the bump. All seven are scaled so that C<bw> is
the kernel's standard deviation, which is why they are interchangeable in
practice. Each panel below is one kernel on a common scale, drawn by asking for
the density of a single observation at zero — C<< density([0], bw =E<gt> 1) >> I<is> the
kernel — and titled with the R(K) that C<give_rkern> returns. The last panel
puts all seven over one sample at one bandwidth, where they are hard to tell
apart.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/density.kernels.png" alt="the seven kernels on a common scale, and the near-identical estimates they give" width="100%" /></p>

C<from>, C<to> and C<cut> decide only where the grid stops: C<cut> bandwidths past
the extremes of the data, three by default. Changing it moves the ends of
C<< $d-E<gt>{x} >> (marked below) and nothing else — the estimate itself is the same
function. C<weights>, on the other hand, changes the estimate: each observation
takes its own share of the mass rather than C<1/n>, which is how a sample that
was collected with unequal probabilities gets its population back.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/density.grid.weights.png" alt="cut moves only the ends of the grid, while weights change the estimate itself" width="100%" /></p>

=head3 Return value

A hash reference:

=over

=item * B<< C<x> >> — the C<n> grid points at which the density was estimated, an array
reference, strictly increasing from C<from> to C<to>.

=item * B<< C<y> >> — the estimated density there, an array reference of the same
length. Never negative, though it can be zero.

=item * B<< C<bw> >> — the bandwidth actually used, i.e. C<adjust> times whatever C<bw>
resolved to. Worth reading back when a rule chose it.

=item * B<< C<n> >> — the sample size after missing values were removed. Infinite
observations still count.

=item * B<< C<kernel> >> — the kernel that was used, spelled out in full, so an
abbreviation comes back resolved.

=item * B<< C<old_coords> >>, B<< C<has_na> >> — echoes of the corresponding R fields;
C<has_na> is always 0.

=back

 my $d = density(\@x, bw => 'SJ');
 printf "bandwidth %.4f over %d observations\n", $d->{bw}, $d->{n};

With C<< give_rkern =E<gt> 1 >> the return is instead a plain number: R(K) = ∫K²(t)dt
for the chosen kernel, the scale-invariant quantity that says how efficient
that kernel is. No data is needed, and any that is given is ignored.

 my $rk = density(kernel => 'epanechnikov', give_rkern => 1);   # 0.2683283

Bandwidths that are "exactly equivalent" across kernels are then
C<(R(K_gaussian)/R(K))**0.2> times each other — the adjustment is within about
1% either way, which is why the choice of kernel rarely matters.

=head3 The bandwidth rules: C<bw_nrd0>, C<bw_nrd>, C<bw_ucv>, C<bw_bcv>, C<bw_sj>

The five rules C<density>'s C<< bw =E<gt> >> string can name are also callable in their
own right, and are ports of R's C<bw.nrd0>, C<bw.nrd>, C<bw.ucv>, C<bw.bcv> and
C<bw.SJ>. Each takes the sample the same two ways C<density> does and returns a
plain number.

 my $h = bw_nrd0(\@x);
 my $h = bw_sj(x => \@x, method => 'dpi');

They disagree, and on a bimodal sample they disagree by a factor of four. Each
panel below is C<eruptions> at the bandwidth that rule chose, over the same
histogram: C<nrd0> and C<nrd> assume one mode and oversmooth this sample, C<ucv>
goes the other way, and the two C<SJ> variants land in between.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/density.bw.rules.png" alt="the same sample under each of the six bandwidth rules" width="100%" /></p>

=over

=item * B<< C<bw_nrd0> >> — Silverman's rule of thumb, C<0.9 * min(sd, IQR/1.34) *
n**-0.2>, and C<density>'s default. It is the default for historical reasons
rather than because it is the best choice.

=item * B<< C<bw_nrd> >> — Scott's variation on the same rule, with 1.06 in place of 0.9.

=item * B<< C<bw_ucv> >>, B<< C<bw_bcv> >> — unbiased (least-squares) and biased
cross-validation. Both minimise a criterion over a range of bandwidths and
warn, as R does, if the minimum turned up at one end of that range.

=item * B<< C<bw_sj> >> — the Sheather & Jones (1991) selector, usually the one to
reach for. C<< method =E<gt> 'ste' >> (the default) solves the equation;
C<< method =E<gt> 'dpi' >> plugs in directly. These are what C<< bw =E<gt> 'SJ' >> and
C<< bw =E<gt> 'SJ-dpi' >> select.

=back

The three that search also accept C<nb> (the number of bins for the pair
counts, 1000 by default), C<lower> and C<upper> (the range searched) and C<tol>
(where the search stops, C<0.1 * lower> by default). Unlike C<density>, these
five want a clean numeric sample: a missing or infinite value is an error, not
something to drop.

Validated against R 4.6.1 — its own regression suite, the examples in
C<?density> and C<?bw.nrd>, and their pinned output — by C<t/density.R.scipy.t>,
which also cross-checks the whole binning/FFT/interpolation pipeline against
SciPy's exact C<gaussian_kde>.

The figures above are drawn by C<density.plots.pl> in the repository, from the
same C<eruptions> and C<precip> samples that test file uses. It is an author-only
script — it is not installed, and it needs C<Matplotlib::Simple>, C<python3> and
C<matplotlib> — so re-run it only when a figure needs to change.

=head2 Distribution functions

C<pnorm> and C<dnorm> have never had company: there was no way to ask for a
quantile, or for any distribution but the normal, so a confidence bound or a
custom test statistic could not be finished outside the module. These eight
close that, with R's names, R's argument order and R's semantics:

=for html <table>
<thead>
<tr>
  <th>function</th>
  <th>R's</th>
  <th>what it gives</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>qnorm($p, mean =&gt; 0, sd =&gt; 1)</code></td>
  <td><code>qnorm</code></td>
  <td>the normal quantile — the inverse of [<code>pnorm</code>](#pnorm)</td>
</tr>
<tr>
  <td><code>pt($q, $df)</code></td>
  <td><code>pt</code></td>
  <td>Student <i>t</i> CDF</td>
</tr>
<tr>
  <td><code>qt($p, $df)</code></td>
  <td><code>qt</code></td>
  <td>Student <i>t</i> quantile</td>
</tr>
<tr>
  <td><code>pchisq($q, $df)</code></td>
  <td><code>pchisq</code></td>
  <td>chi-square CDF</td>
</tr>
<tr>
  <td><code>qchisq($p, $df)</code></td>
  <td><code>qchisq</code></td>
  <td>chi-square quantile</td>
</tr>
<tr>
  <td><code>pf($q, $df1, $df2)</code></td>
  <td><code>pf</code></td>
  <td><i>F</i> CDF</td>
</tr>
<tr>
  <td><code>qf($p, $df1, $df2)</code></td>
  <td><code>qf</code></td>
  <td><i>F</i> quantile</td>
</tr>
<tr>
  <td><code>pbinom($q, $size, $prob)</code></td>
  <td><code>pbinom</code></td>
  <td>binomial CDF</td>
</tr>
</tbody>
</table>

Every one takes its distribution parameters B<either positionally or by name>,
because R is called both ways:

 pt(2.5, 10);              pt(2.5, df => 10);
 pf(3, 2, 10);             pf(3, df2 => 10, df1 => 2);
 pbinom(3, 10, 0.25);      pbinom(3, size => 10, prob => 0.25);

and every one takes the same two flags L<C<pnorm>|/"pnorm"> does, under both
spellings:

=for html <table>
<thead>
<tr>
  <th>option</th>
  <th>meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>lower</code> / <code>lower_tail</code></td>
  <td><code>1</code> (default) for the lower tail, <code>0</code> for the upper</td>
</tr>
<tr>
  <td><code>log</code> / <code>log_p</code></td>
  <td>on a <code>p<i></code> function, return the log of the probability; on a <code>q</i></code> function, the probability <i>argument</i> is a log</td>
</tr>
</tbody>
</table>

R's dotted C<lower.tail> and C<log.p> are refused as unknown arguments.

The first argument may be a single number or an array reference, and an array
reference comes back the same length and in the same order — again as C<pnorm>
does. An C<undef> element becomes C<NaN>.

 my $z  = qnorm(0.975);                 # 1.959963984540054
 my $zs = qnorm([0.025, 0.5, 0.975]);   # [-1.9599639845, 0, 1.9599639845]

=head3 What each one does, in one picture

The same identity read from two ends: a C<p*> function is given the boundary and
returns the shaded area; the matching C<q*> function is given the area and
returns the boundary. Each figure shades the region it integrates and writes the
integral it evaluates. Regenerate them all with
C<perl -Iblib/lib -Iblib/arch distribution.plots.pl>.

C<qnorm> — given an area under the normal density, return the cut-point:

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/qnorm.what.png" alt="qnorm: the standard normal density with the left 0.90 of its area shaded, the integral from minus infinity to q equals 0.90 written above it, and the boundary q = 1.281552 marked in orange as the answer" width="100%" /></p>

C<pt> — the area of the I<t> density to the left of a I<t> statistic:

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/pt.what.png" alt="pt: the t density on 10 degrees of freedom with the area left of t = 2.5 shaded, annotated with the integral from minus infinity to 2.5 of f(t) dt = 0.98428, and a note that the unshaded upper tail is 0.01572" width="100%" /></p>

C<qt> — the I<t> that leaves a given area to its left, which is where the 1.96 of
a confidence interval comes from:

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/qt.what.png" alt="qt: the t density on 10 degrees of freedom with 0.975 of its area shaded, the integral set equal to 0.975 with the upper limit unknown, and the boundary t = 2.228139 marked in orange as the answer" width="100%" /></p>

C<pchisq> — the chi-square tail beyond an observed statistic, which is what every
chi-square test reports as its p-value:

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/pchisq.what.png" alt="pchisq: the chi-square density on 3 degrees of freedom with the tail beyond 7.81 shaded, annotated with the integral from 7.81 to infinity of f(x) dx = 0.05011" width="100%" /></p>

C<qchisq> — the critical value that cuts off a tail of a given size:

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/qchisq.what.png" alt="qchisq: the chi-square density on 3 degrees of freedom with an upper tail of area 0.05 shaded, the integral from q to infinity set equal to 0.05, and the boundary q = 7.814728 marked in orange as the answer" width="100%" /></p>

C<pf> — the I<F> tail beyond an observed I<F>, the C<< Pr(E<gt>F) >> column of an ANOVA
table:

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/pf.what.png" alt="pf: the F density on 2 and 10 degrees of freedom with the tail beyond F = 4.1 shaded, annotated with the integral from 4.1 to infinity of f(F) dF = 0.04983" width="100%" /></p>

C<qf> — the I<F> that cuts off a given upper tail, the number an I<F> table used to
be printed for:

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/qf.what.png" alt="qf: the F density on 2 and 10 degrees of freedom with an upper tail of area 0.05 shaded, the integral from q to infinity set equal to 0.05, and the boundary q = 4.102821 marked in orange as the answer" width="100%" /></p>

C<pbinom> — the one that is B<not> an integral. A binomial is discrete, so its
lower tail is a finite sum of bar heights, and the figure says so rather than
drawing an integral sign over a histogram:

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/pbinom.what.png" alt="pbinom: the binomial probability mass function for size 10 and prob 0.5 drawn as bars, with the bars from 0 to 3 shaded and the rest grey, annotated with the sum from i = 0 to 3 of the binomial terms equalling 0.171875" width="100%" /></p>

=head3 Why you want them

A Wald interval, or any p-value the module does not already package, becomes a
one-liner instead of a table lookup:

 my $z  = qnorm(1 - (1 - 0.95) / 2);          # 1.959963984540054
 my ($lo, $hi) = ($est - $z * $se, $est + $z * $se);

 # a likelihood-ratio test between two nested glm fits
 my $lr = $small->{deviance} - $big->{deviance};
 my $p  = pchisq($lr, $small->{'df_residual'} - $big->{'df_residual'},
                 lower => 0);

=head3 The tail you ask for is the tail that gets computed

No tail is ever formed as C<1 -> the other one. That subtraction costs every
digit below machine epsilon, which is exactly the range a p-value is
interesting in, so each function is routed to the parameterisation that
computes the requested side directly:

 pchisq(1e-30, 1);            # 7.978845608028654e-16, not 0
 pt(-75, 15);                 # 5.4e-21, from the lower tail itself

C<qnorm>, C<qchisq> and C<qf> reflect a probability above C<0.5> onto C<1 - p>
before inverting, for the same reason in the other direction — that keeps the
root-finder comparing small numbers instead of numbers that agree to fifteen
places. The reflection is free rather than a trade: for C<< p E<gt>= 0.5 >> the two
operands of C<1 - p> lie within a factor of two of each other, so Sterbenz's
lemma makes that subtraction exact, and nothing is given up in exchange for
what it removes. Measured against C<mpmath> at 60 digits, at the C<p> that
C<1 - (1 - conf_level) / 2> actually forms:

=for html <table>
<thead>
<tr>
  <th>conf_level</th>
  <th>z, unreflected</th>
  <th>z, reflected</th>
</tr>
</thead>
<tbody>
<tr>
  <td>0.95</td>
  <td>0.4 ulp</td>
  <td>0.1 ulp</td>
</tr>
<tr>
  <td>0.99</td>
  <td>3.0 ulp</td>
  <td>0.1 ulp</td>
</tr>
<tr>
  <td>0.999</td>
  <td>37 ulp</td>
  <td>0.3 ulp</td>
</tr>
<tr>
  <td>0.9999</td>
  <td>254 ulp</td>
  <td>0.4 ulp</td>
</tr>
</tbody>
</table>

The error grows with the confidence level because that is where C<p> and
C<pnorm(z)> agree to the most places, so it is the intervals a cautious caller
asks for that were losing the most digits.

=head3 The same critical value every interval in the module is built from

C<qnorm> is not a second opinion about the normal quantile. Since 0.303 it is
the I<same> call — C<std_qnorm()> in C<LikeR.xs> — that C<glm>, C<cor_test>,
C<prop_test>, C<epi_2x2>, C<cmh_test>, C<roc>, C<survfit>, C<coxph>, C<wilcox_test>,
C<cohen_d> and C<shapiro_test> build their own numbers from. So a bound written
by hand lands on the bound the function reports:

 my $m  = glm(data => \%d, formula => 'y ~ x', family => 'binomial');
 my $se = $m->{summary}{x}{'Std. Error'};
 my $z  = qnorm(1 - (1 - 0.95) / 2);
 $m->{summary}{x}{'Estimate'} - $z * $se;   # is $m->{'conf_int'}{x}[0]

bit for bit on a C<double> build. On the wider NVs the only thing that can
separate them is the compiler's freedom to contract C<est - z * se> into a
single FMA where perl rounds twice, which is one ulp.

C<t/qnorm.crit.R.scipy.t> asserts that, and goes the other way as well: it
recovers the critical value back out of each function's I<reported> interval —
undoing the C<exp> for C<coxph> and C<epi_2x2>'s odds ratio, the C<tanh> for
C<cor_test> — and requires it to be the one C<qnorm> returns, at conf_level 0.8
through 0.9999. C<cmh_test> is the one site not covered, because recovering its
C<z> would mean reimplementing the Robins-Breslow-Greenland variance it does not
report, which would test the reimplementation.

Against C<mpmath> at C<mp.dps = 60>, bisecting the defining equation
C<erfc(-z/sqrt(2)) / 2 = p> rather than calling a library inverse, worst relative
error over those six confidence levels:

=for html <table>
<thead>
<tr>
  <th></th>
  <th>worst relative error</th>
  <th></th>
</tr>
</thead>
<tbody>
<tr>
  <td>R 4.6.1 <code>qnorm</code> (Wichura's AS 241)</td>
  <td>4.8e-16</td>
  <td>2.1 ulp</td>
</tr>
<tr>
  <td>SciPy 1.18.0 <code>norm.ppf</code> (Cephes <code>ndtri</code>)</td>
  <td>1.5e-16</td>
  <td>0.7 ulp</td>
</tr>
<tr>
  <td>this module</td>
  <td>8.2e-17</td>
  <td>0.4 ulp</td>
</tr>
</tbody>
</table>

C<t/std_qnorm.mpmath.py> is the arbiter and prints that table, along with the
frozen rows of the test it generates. Like the other generators it is committed
next to its test and nothing in the suite calls it.

=head3 Accuracy, and the one place C<log> is not R's

These are glue over routines the module already had — C<normal_quantile_hp>,
C<pt_upper>/C<qt_tail>, the incomplete gamma and beta — whose series and
continued fractions stop at a relative C<1e-15> on every build. So they are
double-accurate on a long-double or C<__float128> perl too, rather than more
accurate there, and they agree with R to about C<1e-14> relative.

Two things are deliberately not R:

=over

=item * B<< C<< log =E<gt> 1 >> on a C<p*> function returns C<log()> of the probability already
computed >>, not a log carried through the series. A tail that underflowed
to C<0> therefore logs to C<-Inf>, and a tail that rounded to C<1> logs to C<0>
rather than to the tiny negative number R reports. R's C<pt>/C<pchisq>/C<pf>
carry C<log_p> through and can do better; C<pnorm> here does too, because R's
Cody algorithm was ported whole. The C<q*> functions take C<log_p> properly:
the argument is exponentiated, which is exact, and lets you name quantiles
the linear scale cannot — C<< qnorm(-800, log_p =E<gt> 1) >> is reachable where
C<exp(-800)> is just C<0>.

=item * B<< C<qf> disagrees with R in the far tail of I<F>, and is right. >> At
C<qf(2^-20, 1, 10)> R is 9.9e-4 away from the 60-digit value and this module
is 1.0e-15 away; R's own C<pf> confirms it, inverting this module's answer to
1.6e-15 and its own to 4.9e-4. Thirteen such rows are pinned in
C<t/distributions.R.scipy.t> against mpmath at C<mp.dps = 60>, each asserted
both to be right I<and> to still disagree with R, so the divergence cannot
quietly change.

=back

Non-centrality (C<ncp>) is not implemented; nor is C<qbinom>. Everything is
cross-validated in C<t/distributions.R.scipy.t> (2041 tests) against a frozen
table of R 4.6.1 values, SciPy 1.18.0's own mpmath reference cases, and R's own
round-trip identities from C<tests/d-p-q-r-tests.R>.

=head2 dnorm

gives the density of the normal distribution, with the specified mean and standard deviation.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/dnorm.what.png" alt="dnorm: the standard normal density curve with a vertical orange line at x = 1 reaching the curve, a dotted line across to the y axis, and the label dnorm(1) = 0.241971 -- a height, with nothing shaded, because dnorm integrates nothing" width="100%" /></p>

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
 $aoa = drop_cols($hoa, 'b');
 # { a => [1,4], c => [3,6] }

 my $aoa = [ [1,2,3], [4,5,6] ];
 $aoa = drop_cols($aoa, 1); # result is re-indexed 0,1
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

=item * B<A tied HoA column is the one exception>: its cells have no independent
existence to share — the tie hands them out one temporary at a time — so
they are copied, and the result is independent of the input for that column.
A tied AoA/AoH row is still shared, because the row itself is a real
reference whatever the array holding it does.

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
         $c->{comparison}, $c->{Z}, $c->{'p_value'}, $c->{'p_adjust'};
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
 print $r->{'odds_ratio'};           # 1.714
 print "@{ $r->{'odds_ratio_ci'} }"; # 0.895 3.285

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
  <td>The data frame: an <b>array of hashes</b> (AoH, the default <code>read_table</code> output), a <b>hash of arrays</b> (HoA), or a <b>hash of hashes</b> (HoH, e.g. <code>read_table</code> with <code>'output_type' =&gt; 'hoh'</code>).</td>
</tr>
<tr>
  <td>2</td>
  <td>predicate</td>
  <td>A <code>col()</code> comparison object <b>or</b> a <code>CODE</code> reference. A coderef receives the row as <code>$_</code> / <code>$_[0]</code> and the row identifier as <code>$_[1]</code> (see below).</td>
</tr>
<tr>
  <td>3 +</td>
  <td><code>'output_type' =&gt; 'aoh'|'hoa'</code></td>
  <td><i>Optional.</i> The shape of the returned frame. Omit it to keep the input's own shape. <code>'out'</code> is an accepted alias (the dotted <code>'output.type'</code> is refused as an unknown argument), and a bare <code>filter($df, $pred, 'aoh')</code> also works.</td>
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

By default C<filter> returns a frame of the B<same shape> as the input (AoH → AoH, HoA → HoA, HoH → HoH). Pass C<output_type> to convert while filtering:

 my $aoh = read_table('patients.csv');                          # array of hashes
 my $hoa = filter($aoh, col('Age') >= 18, 'output_type' => 'hoa');
 # $hoa->{Age}, $hoa->{Sex}, ... are all the same length and row-aligned

The two selectable output types are C<'aoh'> and C<'hoa'>. C<'hoh'> is B<not> selectable, because producing a hash of hashes would require choosing which column becomes the row key; an HoH input keeps its keys only when the output shape is left at the default (HoH → HoH).

=head3 Examples

 use Stats::LikeR;
 my $df = read_table('patients.csv');                 # array of hashes

 my $adults = filter($df, col('Age') >= 18);          # numeric threshold
 my $target = filter($df, (col('Age') >= 18) & (col('Sex') eq 'f'));   # combine
 my $flagged = filter($df, sub { $_->{ALT} > 40 || $_->{AST} > 40 });  # coderef

 # hash of arrays in -> hash of arrays out (columns filtered in parallel)
 my $hoa = read_table('patients.csv', 'output_type' => 'hoa');
 my $sub = filter($hoa, col('Age') > 32);

 # hash of hashes in -> the same row keys, fewer of them
 my $hoh = read_table('patients.csv', 'output_type' => 'hoh');
 my $keep = filter($hoh, col('Age') > 32);

 # hash of hashes: filter on the row name (the outer key) via $_[1]
 my $grps    = join '|', qw(1cka 1d4t);
 my $by_name = filter($hoh, sub { $_[1] =~ m/^(?:$grps)$/ });

 # convert shape while filtering
 my $as_hoa = filter($df, col('Age') > 32, 'output_type' => 'hoa');

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
 printf "chi2=%.3f  df=%d  p=%.4g\n", $r->{statistic}, $r->{parameter}, $r->{'p_value'};

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

For every non-gaussian family, C<glm> also returns the exponentiated coefficients with their Wald confidence intervals (C<confint.default>): odds ratios for C<binomial>, and rate / incidence-rate ratios for C<poisson> and C<negbin>. The interval width is set by the C<conf_level> argument (default C<0.95>). Validated numerically against R's C<glm>, C<MASS::glm.nb>, and C<confint.default>.

 my $nb = glm(formula => 'cases ~ age + sex', data => \%d, family => 'negbin');
 printf "IRR(age) = %.2f (%.2f–%.2f)\n",
     $nb->{exp}{age}{estimate}, $nb->{exp}{age}{'conf_low'}, $nb->{exp}{age}{'conf_high'};

For the families that report a Wald C<z> (everything but C<gaussian>),
C<< Pr(E<gt>|z|) >> is computed as C<2 * pnorm(-|z|)> rather than
C<2 * (1 - pnorm(|z|))>, so a strong effect reports its actual p-value instead
of a flat C<0>; see L</"F and z tail p-values">. The
C<gaussian> family reports C<< Pr(E<gt>|t|) >> from a direct two-tail probability and was
never affected. Note that the C<z> itself comes from this module's IRLS fit and
can differ from R's in the 6th to 8th significant digit, which a p-value far
out in the tail amplifies — at C<|z| = 37> a 1.5e-5 difference in C<z> moves the
p-value by about 2%.

=head3 Offsets, prior weights, robust covariance and absorbed factors

An B<offset> is a term whose coefficient is fixed at 1 rather than estimated,
which is how a count model is put on a per-person-time scale. Write it into the
formula, as R does, or pass it as C<offset> (a column name, an expression over
columns, or an array ref with one value per row); the two forms add together.
The negative-binomial C<theta> search sees the offset too, as C<MASS::glm.nb>'s
does, and the null deviance is that of an intercept-plus-offset fit:

 my $rate = glm(formula => 'admits ~ hours + age + offset(log(persontime))',
                data => \%d, family => 'poisson');
 my $same = glm(formula => 'admits ~ hours + age', offset => 'log(persontime)',
                data => \%d, family => 'poisson');

B<Prior weights> (C<weights>, a column name or an array ref) are R's
C<glm(weights = )>. A binomial fit whose weights make a non-integer number of
successes warns C<non-integer #successes in a binomial glm!>, as R does. A row
with weight 0 is kept out of the fit and out of C<nobs>.

C<< vcov =E<gt> 'HC0' >> (through C<'HC3'>) replaces the model-based covariance by a
heteroskedasticity-consistent sandwich, C<sandwich::vcovHC()>, and C<cluster>
by a cluster-robust one, C<sandwich::vcovCL()>. Naming a cluster alone implies
C<HC0>, which is C<vcovCL()>'s own default for a glm; C<HC1> adds the
C<(n - 1)/(n - k)> factor. C<< cluster =E<gt> 'firm + year' >> clusters two ways (up to
four) by inclusion-exclusion, as C<vcovCL(cluster = ~ firm + year)> does. The
C<summary> standard errors, C<z>, p-values and both kinds of confidence interval
are then all computed from the robust covariance, as C<lmtest::coeftest()>
would. A C<poisson> fit on a 0/1 outcome with C<< vcov =E<gt> 'HC0' >> is the
"modified Poisson" risk-ratio regression (Zou 2004, I<Am J Epidemiol> 159:702):

 my $rr = glm(formula => 'readmit ~ hours + age', data => \%d,
              family => 'poisson', vcov => 'HC0', cluster => 'child_id');
 printf "RR = %.3f (%.3f-%.3f)\n", @{ $rr->{exp}{hours} }{qw(estimate conf_low conf_high)};

A factor with thousands of levels (a within-subject comparison) can be
B<absorbed> instead of expanded into dummy columns: put it after a C<|> in the
formula, as C<fixest> does, or name it in C<absorb>. The fit then demeans within
groups (weighted, by alternating projections for more than one factor) and
reports only the remaining coefficients, which equal those of the
full-dummy fit. As C<fixest::feglm()> does, a group whose outcome is constant at
a boundary (all zeros for C<poisson>/C<negbin>, all 0 or all 1 for C<binomial>)
carries no information and is dropped; C<fe_removed> counts the rows that goes
with. HC2/HC3 are not available with absorbed factors.

 my $fe = glm(formula => 'visits ~ hours | child_id + year', data => \%d,
              family => 'poisson', cluster => 'child_id');

C<maxit> (default 25) and C<epsilon> (default C<1e-8>) are C<glm.control()>'s.

A B<control-function> IV estimate for a count outcome is two calls: fit the
first stage with L<C<lm>|/"lm">, add its residuals to the data, and include them
as a regressor in the C<poisson>/C<negbin> C<glm>. The coefficient of the
residual is a test of exogeneity, but the second-stage standard errors do not
account for the first stage having been estimated; bootstrap the pair of fits
for those. For a continuous outcome use L<C<ivreg>|/"ivreg">, whose standard
errors are right as they stand.

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
  <td>A symbolic description of the model to be fitted. Parsed by the same code as [<code>lm</code>](#lm)'s, so it takes the same operators: <code>+</code>, <code>:</code>, <code>*</code>, <code>^</code>, <code>.</code> for every remaining column, and <code>-1</code> / <code>+0</code> to remove the intercept. It may also hold <code>offset()</code> terms, and factors to absorb after a <code>|</code>.</td>
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
  <td><code>conf_level</code></td>
  <td><code>Number</code></td>
  <td><code>0.95</code></td>
  <td>Confidence level for the Wald coefficient / exponentiated-coefficient intervals.</td>
  <td><code>0.90</code></td>
</tr>
<tr>
  <td><code>offset</code></td>
  <td><code>String</code> or <code>ArrayRef</code></td>
  <td><i>none</i></td>
  <td>A column, an expression over columns such as <code>'log(t)'</code>, or one value per row, added to the linear predictor with coefficient 1. Adds to any <code>offset()</code> terms in the formula.</td>
  <td><code>'log(persontime)'</code></td>
</tr>
<tr>
  <td><code>weights</code></td>
  <td><code>String</code> or <code>ArrayRef</code></td>
  <td><i>none</i></td>
  <td>Prior weights, R's <code>glm(weights = )</code>: a column name, or one value per row. Must be non-negative.</td>
  <td><code>'w'</code></td>
</tr>
<tr>
  <td><code>vcov</code></td>
  <td><code>String</code></td>
  <td><code>'model'</code></td>
  <td><code>'model'</code>, or a sandwich: <code>'HC0'</code>, <code>'HC1'</code>, <code>'HC2'</code> or <code>'HC3'</code> (<code>sandwich::vcovHC</code>). Also accepted as <code>vcov_type</code>.</td>
  <td><code>'HC0'</code></td>
</tr>
<tr>
  <td><code>cluster</code></td>
  <td><code>String</code> or <code>ArrayRef</code></td>
  <td><i>none</i></td>
  <td>Cluster variable(s) for <code>sandwich::vcovCL</code>: a column name, <code>'a + b'</code> for multiway clustering, or one label per row. Implies <code>vcov =&gt; 'HC0'</code> unless <code>'HC1'</code> is given.</td>
  <td><code>'child_id'</code></td>
</tr>
<tr>
  <td><code>absorb</code></td>
  <td><code>String</code> or <code>ArrayRef</code></td>
  <td><i>none</i></td>
  <td>Factor(s) to absorb as fixed effects rather than expand, like the formula's <code>| f1 + f2</code> part.</td>
  <td><code>'child_id'</code></td>
</tr>
<tr>
  <td><code>maxit</code></td>
  <td><code>Integer</code></td>
  <td><code>25</code></td>
  <td>IRLS iteration limit, as <code>glm.control(maxit = )</code>.</td>
  <td><code>50</code></td>
</tr>
<tr>
  <td><code>epsilon</code></td>
  <td><code>Number</code></td>
  <td><code>1e-8</code></td>
  <td>IRLS convergence tolerance on the relative deviance change, as <code>glm.control(epsilon = )</code>.</td>
  <td><code>1e-10</code></td>
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
  <td><code>deviance_resid</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping data row names to their computed deviance residuals.</td>
  <td><code>{'Mazda RX4' =&gt; 0.12}</code></td>
</tr>
<tr>
  <td><code>df_null</code></td>
  <td><code>Integer</code></td>
  <td>The residual degrees of freedom for the null model.</td>
  <td><code>31</code></td>
</tr>
<tr>
  <td><code>df_residual</code></td>
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
  <td><code>fitted_values</code></td>
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
  <td><code>null_deviance</code></td>
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
  <td>A nested hash mapping each term to its detailed summary statistics, including <code>Estimate</code>, <code>Std. Error</code>, <code>t value</code> / <code>z value</code>, <code>Pr(&gt; t )</code> / <code>Pr(&gt; z )</code>, and the Wald <code>CI_lower</code> / <code>CI_upper</code> (link scale). Aliased parameters return <code>"NaN"</code>.</td>
  <td><code>{'wt' =&gt; {'Estimate' =&gt; -0.5, 'Std. Error' =&gt; 0.1, ...}}</code></td>
</tr>
<tr>
  <td><code>terms</code></td>
  <td><code>ArrayRef</code></td>
  <td>An ordered list of the expanded term names included in the model matrix.</td>
  <td><code>['Intercept', 'wt', 'hp']</code></td>
</tr>
<tr>
  <td><code>conf_int</code></td>
  <td><code>HashRef</code></td>
  <td>Wald confidence interval for each coefficient on the <b>link</b> scale, as <code>[lower, upper]</code>.</td>
  <td><code>{'wt' =&gt; [-0.9, -0.1]}</code></td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td><code>Double</code></td>
  <td>The confidence level used for <code>conf_int</code> and <code>exp</code>.</td>
  <td><code>0.95</code></td>
</tr>
<tr>
  <td><code>exp</code></td>
  <td><code>HashRef</code></td>
  <td>Non-gaussian families only: exponentiated coefficient (odds ratio for <code>binomial</code>; rate / incidence-rate ratio for <code>poisson</code> / <code>negbin</code>) with its confidence interval, as <code>{estimate, 'conf_low', 'conf_high'}</code>.</td>
  <td><code>{'wt' =&gt; {estimate =&gt; 0.6, 'conf_low' =&gt; 0.4, 'conf_high' =&gt; 0.9}}</code></td>
</tr>
<tr>
  <td><code>theta</code></td>
  <td><code>Double</code></td>
  <td><code>negbin</code> family only: the negative-binomial dispersion parameter (ML estimate, or the fixed value supplied).</td>
  <td><code>1.73</code></td>
</tr>
<tr>
  <td><code>loglik</code></td>
  <td><code>Double</code></td>
  <td>The log-likelihood, as R's <code>logLik()</code>.</td>
  <td><code>-120.3</code></td>
</tr>
<tr>
  <td><code>dispersion</code></td>
  <td><code>Double</code></td>
  <td>The dispersion the standard errors use: estimated (Pearson) for <code>gaussian</code>, 1 for the other families.</td>
  <td><code>1</code></td>
</tr>
<tr>
  <td><code>nobs</code></td>
  <td><code>Integer</code></td>
  <td>Rows in the fit (non-missing, non-zero weight, and not dropped with an absorbed group).</td>
  <td><code>98</code></td>
</tr>
<tr>
  <td><code>vcov</code></td>
  <td><code>HashRef</code></td>
  <td>The coefficient covariance, model-based or robust as <code>vcov_type</code> says, as a hash of hashes by term.</td>
  <td><code>{'wt' =&gt; {'wt' =&gt; 0.01, ...}}</code></td>
</tr>
<tr>
  <td><code>vcov_type</code></td>
  <td><code>String</code></td>
  <td><code>'model'</code>, <code>'HC0'</code>, <code>'HC1'</code>, <code>'HC2'</code> or <code>'HC3'</code>.</td>
  <td><code>'HC0'</code></td>
</tr>
<tr>
  <td><code>n_clusters</code></td>
  <td><code>Integer</code> or <code>ArrayRef</code></td>
  <td>With <code>cluster</code>: the number of clusters, or one count per variable when clustering several ways.</td>
  <td><code>120</code></td>
</tr>
<tr>
  <td><code>absorb</code></td>
  <td><code>HashRef</code></td>
  <td>With absorbed factors: each factor's number of groups in the fit.</td>
  <td><code>{'child_id' =&gt; 812}</code></td>
</tr>
<tr>
  <td><code>fe_removed</code></td>
  <td><code>Integer</code></td>
  <td>With absorbed factors: rows dropped because their group's outcome was constant at a boundary.</td>
  <td><code>14</code></td>
</tr>
<tr>
  <td><code>offset_terms</code></td>
  <td><code>ArrayRef</code></td>
  <td>With an offset: the expressions it is made of, which [<code>predict</code>](#predict) re-evaluates on new data.</td>
  <td><code>['log(persontime)']</code></td>
</tr>
<tr>
  <td><code>twologlik</code></td>
  <td><code>Double</code></td>
  <td><code>negbin</code> only: twice the log-likelihood, as <code>MASS::glm.nb</code>.</td>
  <td><code>-240.6</code></td>
</tr>
<tr>
  <td><code>SE_theta</code></td>
  <td><code>Double</code></td>
  <td><code>negbin</code> with <code>theta</code> estimated: its standard error.</td>
  <td><code>0.41</code></td>
</tr>
</tbody>
</table>

=head2 group_by

 group_by($data, $value_column, $group_column, @filters)

Split the values of one column by the levels of another, as R's C<split(x, f)>
does. B<The column of values comes first and the grouping column second> --
the reverse of dplyr's C<group_by(df, g)> or pandas' C<df.groupby('g')>, which
take only the grouping column. C<group_by($mtcars, 'mpg', 'cyl')> is "mpg,
split by cyl", and returns a hash of arrays keyed by the levels of C<cyl>:

 {
     4   [ 22.8, 24.4, 22.8, ... ],   # the 11 four-cylinder cars' mpg
     6   [ 21,   21,   21.4, ... ],   # 7
     8   [ 18.7, 14.3, 16.4, ... ]    # 14
 }

That is the shape C<aov> stacks when it is given no formula, so C<aov($gb)> runs
a one-way ANOVA of the values across the groups.

The data may be an array of hashes, a hash of hashes, or a hash of arrays:

 my $aoh_data = [
     { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
     { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
     { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
     { 'Gender' => 'Female' } # Intentional missing target value
 ];

 my $hoh_data = {
     'Patient_A' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
     'Patient_B' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
     'Patient_C' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
     'Patient_D' => { 'Gender' => 'Female' }, # Intentional missing target value
     'Patient_E' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => undef } # Explicit undef
 };

 my $hoa_data = {
     'Gender'                       => ['Male', 'Female', 'Male', 'Female'],
     'Testosterone, total (nmol/L)' => [22.1,   2.5,      19.4,   undef   ]
 };

Each is called the same way:

 group_by($aoh_data, 'Testosterone, total (nmol/L)', 'Gender');

and each returns a hash of arrays. A row whose value is missing or C<undef> is
left out, so the second Female row contributes nothing. C<$aoh_data> gives

 {
     Female   [
         [0] 1.8
     ],
     Male     [
         [0] 20.5,
         [1] 18.2
     ]
 }

and C<$hoa_data> gives

 {
     Female   [
         [0] 2.5
     ],
     Male     [
         [0] 22.1,
         [1] 19.4
     ]
 }

The values are not sorted. From an array of hashes or a hash of arrays they
come in row order; from a hash of hashes they come in Perl's hash order, which
differs from run to run, so C<$hoh_data> gives C<Male> as either C<[20.5, 18.2]>
or C<[18.2, 20.5]>. Sort them, or use an array of hashes, if the order matters.

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
with the fill value (see C<undef_val> below). Every column therefore has
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
  <td><code>undef_val</code></td>
  <td><code>undef</code></td>
  <td>Value used to fill a missing key or an <code>undef</code> cell. Any defined scalar works, including <code>0</code> and <code>''</code>. Passing <code>undef</code> keeps the default.</td>
</tr>
<tr>
  <td><code>row_names</code></td>
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
 my $hoa = hoh2hoa(\%ragged, 'undef_val' => 'NA');
 # {
 #   a => [1,    3   ],
 #   b => [2,    'NA'],
 #   c => ['NA', 9   ],
 # }

 # Keep the row labels as a column:
 my $with_ids = hoh2hoa(\%ragged, 'row_names' => 'id');
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

=item * C<row_names> is not a plain string, or it names an already-present column.

=back

=head2 hist

Computes the histogram of the given data values. It returns the bin counts,
computed breaks, midpoints, and density.

 my $res = hist([1, 2, 2, 3, 3, 3, 4, 4, 5], breaks => 4);

C<breaks> is a I<suggested> number of intervals, not a count to be obeyed — the
breakpoints are R's C<pretty()> over the range of the data, so they fall on
round numbers and the axis is rounded outwards past the extremes. Ask for 5
bins over C<c(1,2,2,3,4,7,9,10,11,15)> and you get eight, at 0, 2, 4 … 16, which
is what R's C<hist()> gives for the same request. When C<breaks> is omitted the
suggestion is R's C<nclass.Sturges>, ⌈log₂ I<n> + 1⌉.

Counts are of right-closed intervals with the lowest included — C<(a, b]>,
except the first, which is C<[a₀, b₁]> — carrying R's 1e-7 fuzz, so a value that
lands a rounding error above a breakpoint still counts in the bin below it.
C<density> is C<counts / (n × width)> over the unfuzzed breaks. Pinned against R
across thirteen datasets and eight C<breaks> settings in C<t/hist.R.t>.

=head2 hosmer_lemeshow

The Hosmer-Lemeshow goodness-of-fit test for a logistic-regression model. Given
the observed 0/1 outcomes and the model's predicted probabilities, it bins the
observations into C<g> risk groups (deciles by default) and compares observed and
expected event counts. A large p-value indicates the model fits adequately. The
grouping and statistic follow R's C<ResourceSelection::hoslem.test>, against which
it was validated numerically.

 # $fit is a binomial glm(); align observed outcomes with fitted_values
 my @obs  = map { $data{$_}{outcome} } @ids;
 my @prob = map { $fit->{'fitted_values'}{$_} } @ids;

 my $hl = hosmer_lemeshow(\@obs, \@prob, g => 10);
 printf "HL chi2=%.2f df=%d p=%.3f\n", $hl->{statistic}, $hl->{parameter}, $hl->{'p_value'};

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

=head2 hurdle

A two-part count model, C<pscl::hurdle()> (also C<countreg::hurdle()>): a binary
model for whether the count is zero, and a L<zero-truncated|/"zerotrunc"> count
model for how large it is given that it is positive. The typical use is an
outcome such as inpatient days, where "any stay" and "how long" have different
explanations.

 use Stats::LikeR 'hurdle';

 my $h = hurdle(formula => 'days ~ hours + age | hours', data => \%d,
                dist => 'negbin');
 print $h->{coefficients}{count}{hours};    # log rate ratio, given a stay
 print $h->{coefficients}{zero}{hours};     # log odds of any stay

The regressors after C<|> are the zero part's; without a bar both parts use the
same ones. The likelihood separates into the two parts, so they are fitted
separately, as both packages do by default.

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
  <td><code>formula</code></td>
  <td><i>(required)</i></td>
  <td><code>'y ~ count regressors'</code> or <code>'y ~ count regressors | zero regressors'</code>; <code>offset()</code> terms are allowed in either part.</td>
</tr>
<tr>
  <td><code>data</code></td>
  <td><i>(required)</i></td>
  <td>HoA, AoH or HoH.</td>
</tr>
<tr>
  <td><code>dist</code></td>
  <td><code>'poisson'</code></td>
  <td>The count part: <code>'poisson'</code>, <code>'negbin'</code> or <code>'geometric'</code>.</td>
</tr>
<tr>
  <td><code>zero_dist</code></td>
  <td><code>'binomial'</code></td>
  <td>The zero part: <code>'binomial'</code> (a logit), or a count distribution censored at 1, <code>'poisson'</code>, <code>'negbin'</code> or <code>'geometric'</code>.</td>
</tr>
<tr>
  <td><code>link</code></td>
  <td><code>'logit'</code></td>
  <td>The binomial zero part's link; only <code>'logit'</code> is implemented.</td>
</tr>
<tr>
  <td><code>offset</code></td>
  <td><i>none</i></td>
  <td>A column, an expression or an array ref, added to the count part only, as <code>pscl</code>'s <code>offset = </code> is; an <code>offset()</code> term in the zero part's formula offsets that part.</td>
</tr>
<tr>
  <td><code>weights</code></td>
  <td><i>none</i></td>
  <td>Case weights.</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td><code>0.95</code></td>
  <td>Level of the Wald intervals in <code>summary</code>.</td>
</tr>
</tbody>
</table>

The result holds C<coefficients>, C<summary> (with C<Estimate>, C<Std. Error>,
C<z value>, C<< Pr(E<gt>|z|) >>, C<CI_lower>, C<CI_upper>), C<vcov> and C<terms>, each split
into C<count> and C<zero> halves; C<loglik> and its two parts C<loglik_count> and
C<loglik_zero>, C<aic>, C<df_residual>, C<nobs>, C<converged>, C<iter> and
C<iter_zero>; C<theta> and C<SE_logtheta> for a C<negbin> count part, and
C<theta_zero>/C<SE_logtheta_zero> for a C<negbin> zero part; and C<fitted_values>,
the fitted mean C<< P(y E<gt> 0) mu / (1 - f(0)) >>. Validated against C<pscl> and
C<countreg> on their documented examples, with a third opinion from C<mpmath>.

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

=head2 ivreg

Instrumental-variables regression by two-stage least squares, C<ivreg::ivreg()>
(and C<AER::ivreg()>), with C<summary(fit, diagnostics = TRUE)>'s tests. The
standard errors are the proper 2SLS ones, from the residuals of the structural
equation with the original regressors, not the naive ones that come from
running the two stages as separate C<lm> fits.

 use Stats::LikeR 'ivreg';

 # regressors | instruments: exogenous regressors appear on both sides
 my $iv = ivreg(formula => 'log(packs) ~ log(rprice) + log(rincome) | log(rincome) + tdiff + rtax',
                data => \%cig);
 # or three parts: exogenous | endogenous | excluded instruments
 my $iv3 = ivreg(formula => 'log(packs) ~ log(rincome) | log(rprice) | tdiff + rtax',
                 data => \%cig, cluster => 'state');

 my $d = $iv->{diagnostics};
 printf "first-stage F = %.1f\n", $d->{weak}{'log(rprice)'}{statistic};

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
  <td><code>formula</code></td>
  <td><i>(required)</i></td>
  <td><code>'y ~ regressors | instruments'</code>, or <code>'y ~ exogenous | endogenous | instruments'</code>. Terms expand as for [<code>lm</code>](#lm).</td>
</tr>
<tr>
  <td><code>data</code></td>
  <td><i>(required)</i></td>
  <td>HoA, AoH or HoH.</td>
</tr>
<tr>
  <td><code>weights</code></td>
  <td><i>none</i></td>
  <td>Weights, as <code>ivreg(weights = )</code>.</td>
</tr>
<tr>
  <td><code>vcov</code></td>
  <td><code>'model'</code></td>
  <td><code>'model'</code>, <code>'HC0'</code> or <code>'HC1'</code>; the diagnostics use the same covariance, as when <code>summary.ivreg</code> is given <code>vcov. = </code>.</td>
</tr>
<tr>
  <td><code>cluster</code></td>
  <td><i>none</i></td>
  <td>A cluster variable (column name or array ref) for <code>sandwich::vcovCL</code>; implies <code>'HC0'</code>.</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td><code>0.95</code></td>
  <td>Level of <code>conf_int</code>.</td>
</tr>
</tbody>
</table>

The result holds C<coefficients>, C<summary> (per term C<Estimate>,
C<Std. Error>, C<t value>, C<< Pr(E<gt>|t|) >>), C<vcov>, C<vcov_type>, C<conf_int>,
C<terms>, C<endogenous> and C<instruments> (the terms each role was given),
C<fitted_values>, C<residuals>, C<sigma>, C<rss>, C<r_squared>, C<adj_r_squared>,
C<df_residual>, C<rank>, C<nobs>, C<n_clusters> with a cluster, and C<waldtest>, the
F test of every coefficient but the intercept. C<diagnostics> has

=over

=item * C<weak>: per endogenous regressor, the first-stage F test of the excluded
instruments (C<statistic>, C<df1>, C<df2>, C<p_value>);

=item * C<wu_hausman>: the test of whether the endogenous regressors are in fact
exogenous: an F test of the first-stage residuals added to the
structural regression;

=item * C<sargan>: with more instruments than endogenous regressors, the test of
overidentifying restrictions (C<statistic>, C<df>, C<p_value>).

=back

Validated against C<ivreg>'s tests and documented examples, and against Stata
C<ivreg2> output that C<statsmodels> pins. For a count outcome, see the
control-function note under L<C<glm>|/"glm">.

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

=head3 missing values, and groups with no data

Non-numeric, undefined and C<NaN> elements are silently dropped before the test
runs, matching R's C<complete.cases(x, g)> — C<NaN> is C<NA> to R, so it goes too.
C<+Inf> and C<-Inf> are neither, and a rank test has no trouble with them, so
they are kept and ranked.

A group left with no usable observation is refused rather than guessed at, as
R's list interface does: C<kruskal_test> croaks C<all groups must contain data>.
That covers an empty array reference and one whose every element was dropped.
Counting such a group would inflate the degrees of freedom, and testing only
the groups that do have data under a C<df> that counts one that does not is not
a test of anything. (SciPy takes the other side of this and returns C<NaN>.)

A sample with no variation at all gives a tie correction of exactly zero, so
the statistic is C<0/0>: like R, C<statistic> and C<p_value> come back as C<NaN>.

=head3 returned fields

C<statistic>, C<parameter> (the degrees of freedom) and C<method> are R's C<htest>
fields; the p-value is C<p_value> (R's dotted C<p.value> is not a key). On top of
those, C<group_stats> holds C<size> and C<mean> sub-hashes keyed by your own group
labels, computed over the same observations the statistic used.

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
 if ($ks->{'p_value'} < 0.05) {
     printf "reject H0: D=%.4f, p=%.4g (%s)\n",
         $ks->{statistic}, $ks->{'p_value'}, $ks->{method};
 }

=head2 kurtosis

Sample excess kurtosis — how much of the variance sits in the tails rather than
near the shoulders. The C<3> of a normal distribution is already subtracted, so a
normal sample gives roughly C<0>, a heavy-tailed one a positive number, and a flat
or bimodal one a negative number. Add C<3> if you want the plain fourth
standardized moment. Validated numerically against R.

 kurtosis(2, 4, 4, 4, 5, 5, 7, 9);        # 0.940625

Kurtosis is the fourth moment, so what it describes is the tails. Below, three
samples standardized to mean C<0> and standard deviation C<1> — a uniform sample,
which has no mass at all left for the extremes; a normal sample; and a scale
mixture of two normals, one observation in ten drawn with three times the spread
— each against the same C<N(0, 1)> curve in grey, so that the only thing that
differs between the panels is shape. On a linear axis (the top row) the
heavy-tailed sample looks like little more than a sharper peak; the bottom row
is the same three estimates on a logarithmic density, where the tail that the
positive number is reporting is visible over three decades.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/kurtosis.what.png" alt="a flat-shouldered, a normal and a heavy-tailed sample, and the tails behind the kurtosis of each" width="100%" /></p>

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

Rows are labelled from a C<row_names>, C<_row>, C<rownames> or C<.rownames> column if
the data has one (a HoH labels rows with its outer keys, which needs no such
column), and 1-based integers otherwise. Those labels are the keys of
C<fitted_values> and C<residuals>, and the row names C<predict> returns. A row-name
column is a label rather than a measurement, so C<y ~ .> leaves it out of the
predictors.

The overall model F test is returned as C<fstatistic> (an array ref of C<F>,
numerator df, denominator df) and C<f_pvalue>. C<f_pvalue> is evaluated in the
upper tail of the F distribution rather than as C<1 - pf(F, df1, df2)>, so a
strongly significant model reports its actual p-value instead of a flat C<0>;
see L</"F and z tail p-values">. The per-coefficient
C<< Pr(E<gt>|t|) >> values were already computed as a direct two-tail probability and
are unaffected.

=head2 lmer

Linear mixed-effects regression, C<lme4::lmer()>, fitted by REML (the default)
or maximum likelihood, with the Satterthwaite degrees of freedom and t tests
that C<lmerTest> adds to its summary.

 use Stats::LikeR 'lmer';

 # a random intercept and a random slope for Days, correlated, per Subject
 my $m = lmer(formula => 'Reaction ~ Days + (Days | Subject)', data => \%sleepstudy);
 printf "Days: %.2f (SE %.2f, df %.1f)\n",
     @{ $m->{summary}{Days} }{'Estimate', 'Std. Error', 'df'};
 printf "subject sd of the slope: %.2f\n", $m->{varcor}[0]{sd}{Days};

Random-effects terms are written as in C<lme4>: C<(1 | g)> a random intercept,
C<(x | g)> a correlated intercept and slope, C<(0 + x | g)> a slope alone, so that
C<(1 | g) + (0 + x | g)> is the uncorrelated pair; several grouping factors,
crossed or nested, are allowed, and C<(1 | a/b)> expands to C<(1 | a) + (1 | a:b)>.
The fixed part is expanded as for L<C<lm>|/"lm">.

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
  <td><code>formula</code></td>
  <td><i>(required)</i></td>
  <td>Fixed effects plus one or more <code>( terms | group )</code> random-effects terms.</td>
</tr>
<tr>
  <td><code>data</code></td>
  <td><i>(required)</i></td>
  <td>HoA, AoH or HoH.</td>
</tr>
<tr>
  <td><code>REML</code></td>
  <td><code>1</code></td>
  <td><code>0</code> for a maximum-likelihood fit (needed to compare fixed effects by likelihood ratio).</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td><code>0.95</code></td>
  <td>Level of <code>conf_int</code>, from the Satterthwaite t.</td>
</tr>
</tbody>
</table>

The result holds C<coefficients>, C<summary> (per term C<Estimate>,
C<Std. Error>, C<df>, C<t value>, C<< Pr(E<gt>|t|) >>), C<vcov>, C<conf_int>, C<terms>,
C<fitted_values> (including the predicted random effects), C<sigma> (residual
sd), C<theta> (C<lme4>'s relative covariance factor, C<getME(fit, "theta")>),
C<REML> or C<deviance> (the criterion minimised), C<loglik>, C<AIC>, C<BIC>,
C<nobs>, C<reml>, C<converged> and C<singular> (a variance component on its
boundary, C<lme4>'s "singular fit"). C<varcor> is C<VarCorr()>: one entry per
random-effects term, in formula order, each with C<group>, C<levels>, C<names>,
C<sd> by name and the correlation matrix C<corr>.

The criterion is C<lme4>'s profiled deviance, minimised by Nelder-Mead and
then polished by Newton steps, so the estimates are those of a tightly
converged C<lme4> fit; C<lme4>'s default optimiser stops about 1e-6 short in
theta, which moves the standard errors in their fifth digit. Validated against
C<lme4>, C<lmerTest> and C<statsmodels>' mixed-model corpora.

=head2 logrank_test

The log-rank (Mantel–Cox) test: do the survival curves of two or more groups
differ? It needs no modelling assumptions. Same as R's C<survival::survdiff>.

Give times, an event flag (1 = event, 0 = censored), and a group label per row:

 use Stats::LikeR 'logrank_test';

 my $r = logrank_test(\@time, \@status, \@group);
 print $r->{'p_value'};

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

max will die if any undefined values are provided. A C<NaN> anywhere in the input makes the answer C<NaN>, as it does in R.
See L</"Compared with List::Util"> under C<sum> for the other ways it differs from List::Util's C<max>.

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
 printf "chi2=%.2f df=%d p=%.4g\n", $r->{statistic}, $r->{parameter}, $r->{'p_value'};

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
     'output_type' => 'aoh',               # aoa|aoh|hoa|hoh (default: input family)
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
unknown C<output_type>; a C<value_vars>/C<id_vars> column that does not exist;
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

=item * C<< 'left_on' =E<gt> .., 'right_on' =E<gt> .. >> — keys with different names on each side (each a name or an array reference of equal length). C<by_x>/C<by_y> are accepted synonyms; the dotted spellings (C<left.on>, C<right.on>, C<by.x>, C<by.y>) are refused as unknown arguments. The result carries a single key column under the B<left> name.

=item * If neither is given, C<merge> performs a B<natural join> on the sorted intersection of the two frames' column names (it dies if that intersection is empty).

=back

Keys are matched on the B<stringified> cell value. A row whose key cell is C<undef> (or absent) never matches, so such a row is dropped by an inner/right join and appears only as a left- or right-only row in a left/outer/right join. This is SQL's rule for C<NULL> keys, and R's C<merge(..., incomparables = NA)>; note that it is I<not> what either reference does by default — R's default (C<incomparables = NULL>) and pandas both match a missing key to a missing key.

=head3 Colliding columns (C<suffixes>)

A non-key column that appears in B<both> frames would collide, so each copy is renamed by appending a suffix: C<.x> to the left copy and C<.y> to the right by default (R's convention). Override with C<< suffixes =E<gt> ['_left', '_right'] >>.

Under C<left_on>/C<right_on> the same applies to a right-hand non-key column named after the B<left key>, since the single output key column carries the left name: it is suffixed too, as R does with C<no.dups = TRUE>. If the suffixes still leave two output columns sharing a name, C<merge> dies rather than return a frame with a column missing.

=head3 Output shape

By default the result matches the shape of C<$left> (a HoH left frame yields an AoH, since a joined frame has no single row-name key). Force it with C<< 'output_type' =E<gt> 'aoh' >> or C<< 'output_type' =E<gt> 'hoa' >>.

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

min will die if any undefined values are provided. A C<NaN> anywhere in the input makes the answer C<NaN>, as it does in R.
See L</"Compared with List::Util"> under C<sum> for the other ways it differs from List::Util's C<min>.

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
  <td><code>var_equal</code></td>
  <td><code>0</code> (false)</td>
  <td><code>0</code> → Welch's test (unequal variances). <code>1</code> → pooled-variance test. The dotted <code>var.equal</code> is refused as an unknown argument.</td>
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
 # $res->{supp}, $res->{Residuals}, $res->{'group_stats'} ...

=head3 Classic equal-variance form

 my $res = oneway_test(\%groups, var_equal => 1);   # 'var.equal' is refused

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
     'output_type' => 'aoh',  # aoa|aoh|hoa|hoh (default: input family)
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

Rows and columns are sorted by default, the same way C<agg> sorts its groups:
each key column numerically when every value in it is numeric, else as strings,
with undef last and NaN after every number; C<< sort =E<gt> 0 >> keeps first-seen
order. HoH output labels come from the
C<index> values (C<'all'> with no index) and are uniquified with a numeric
suffix if two joined labels collide. Returns a NEW frame; the input is never
modified.

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; a
missing C<columns>; an C<index>/C<columns>/C<values> column that does not exist; an
unknown C<aggfunc> string; an empty C<aggfunc> list; an unknown C<output_type>; or
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
  <td>Significance level (Type I error probability), in <code>[0, 1]</code>. R's dotted <code>sig.level</code> is refused as an unknown argument.</td>
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

The result is a hashref carrying C<n>, C<delta>, C<sd>, C<sig_level>, C<power>,
C<alternative>, C<method>, and -- for C<two.sample> and C<paired> -- C<note>, the
fields R's C<power.t.test> returns, with C<sig.level> spelled C<sig_level>.

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

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/pnorm.what.png" alt="pnorm: the standard normal density with the area left of q = 1.28 shaded orange, annotated with the integral from minus infinity to 1.28 of f(x) dx = 0.89973, and a note that lower =&gt; 0 shades the other side and computes it as its own integral rather than by subtracting" width="100%" /></p>

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
  <td><code>1</code> = lower tail <code>P(X &lt;= x)</code>; <code>0</code> = upper tail <code>P(X &gt; x)</code>. <code>'lower_tail'</code> is an accepted alias; R's dotted <code>'lower.tail'</code> is refused.</td>
</tr>
<tr>
  <td></td>
  <td><code>log</code></td>
  <td><code>0</code> (false)</td>
  <td>If true, return the log of the probability. <code>'log_p'</code> is an accepted alias; R's dotted <code>'log.p'</code> is refused.</td>
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
 my $fitted = predict($fit);                      # no newdata -> stored fitted_values

=over

=item * B<< C<$model> >> — a fitted C<lm>/C<glm> hashref. C<predict> reads its C<coefficients>
(and, for C<glm>, its C<family>).

=item * B<< C<$newdata> >> — a HoA, AoH, or HoH of new observations. Omit it (or pass
C<undef>) to get the model's own C<fitted_values> back.

=item * B<< C<type> >> — C<'response'> (default) returns predictions on the response scale
(the inverse link applied — logistic for binomial); C<'link'> returns the linear
predictor. For C<lm> and gaussian C<glm> the link is the identity, so the two are
the same.

=back

A C<glm> fitted with an offset -- C<offset()> in the formula or a named C<offset>
column -- has the offset re-evaluated on each new row and added to the linear
predictor, so a rate model predicts counts at the new rows' exposure. An offset
given as an array ref has nothing to be re-evaluated from, and a model with
absorbed factors has no estimates of their effects to predict with; C<predict>
croaks on either rather than quietly leaving them out. C<poisson> and C<negbin>
fits are put on the response scale with C<exp>.

=head3 What it returns

A hashref keyed by row name → prediction, exactly like C<lm>/C<glm> key
C<fitted_values>: a C<row_names> column (or HoH key) if present, otherwise 1-based
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
model's C<fitted_values> for any model built from continuous terms, interactions,
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
     $r->{estimate}[0], $r->{'conf_int'}[0], $r->{'conf_int'}[1], $r->{'p_value'};

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
  <td><code>conf_level</code></td>
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
  <td><code>conf_int</code></td>
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

A probability that lands a hair outside C<[0, 1]> — the usual result of computing
one rather than writing it down — is clamped to the endpoint rather than
refused, within the same C<100 * eps> that R allows; anything further out is an
error. C<undef> values in C<x> are dropped.

=head2 rank

Rank values like R's C<rank()>. Takes flat scalars and/or array refs (like C<min>), with optional trailing C<ties_method> / C<na_last> options. Returns the list of ranks in input order.

 my @r = rank(3, 1, 4, 1, 5);                           # 3, 1.5, 4, 1.5, 5
 my @r = rank([3, 1, 4, 1, 5], 'ties_method' => 'min'); # 3, 1, 4, 1, 5

Ranks are 1-based; C<average> may return half-ranks. C<undef> and NaN are treated as NA.

=head3 ties_method

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

=head3 na_last

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
  <td>Comment marker, by default <code>#</code> (<code>##</code> for a VCF); lines beginning with it are skipped. It may be more than one character</td>
  <td><code>comment =&gt; '%'</code></td>
</tr>
<tr>
  <td><code>output_type</code></td>
  <td>data type for output: array of hash (the default; hash of hash for a VCF), array of array, hash of array, or hash of hash</td>
  <td><code>'output_type' =&gt; 'aoh'</code></td>
</tr>
<tr>
  <td><code>filter</code></td>
  <td>Only take in rows matching a filter; see below for how a key picks its column</td>
  <td><code>filter =&gt; { Sex =&gt; sub {$_ eq 'f'} }</code></td>
</tr>
<tr>
  <td><code>row_names</code></td>
  <td><code>hoh</code> only: the column whose values key the rows (default: the first column). An error with any other <code>output_type</code>, where the column is read as an ordinary one</td>
  <td><code>'row_names' =&gt; 'id'</code></td>
</tr>
<tr>
  <td><code>auto_row_names</code></td>
  <td>read R's default <code>write.table</code> output, where the header is one field short of every data row because R writes no label for the row-names column: the leading field of each row becomes a row-names column. <code>1</code> names it <code>row_name</code>, a string names it whatever you pass. Off by default, so a genuinely ragged file is still an error</td>
  <td><code>'auto_row_names' =&gt; 1</code></td>
</tr>
<tr>
  <td><code>sep</code></td>
  <td>field separator: a literal string, or a <code>qr//</code> regex (see below); synonym with <code>delim</code></td>
  <td><code>sep =&gt; "\t"</code>, <code>sep =&gt; qr/\s+/</code></td>
</tr>
<tr>
  <td><code>delim</code></td>
  <td>field separator: a literal string, or a <code>qr//</code> regex; synonym with <code>sep</code></td>
  <td><code>delim =&gt; "\t"</code></td>
</tr>
<tr>
  <td><code>header</code></td>
  <td><code>1</code> (the default): the first line holds the column names. <code>0</code>, or perl's false <code>''</code>: the first line is data, as R's <code>header = FALSE</code> and pandas' <code>header=None</code></td>
  <td><code>header =&gt; 0</code></td>
</tr>
<tr>
  <td><code>col_names</code></td>
  <td>an array reference of column names. With <code>header =&gt; 0</code> it names the columns, which are otherwise <code>V1</code>, <code>V2</code>, … as in R; with a header it replaces the header's names</td>
  <td><code>'col_names' =&gt; ['id', 'name']</code></td>
</tr>
<tr>
  <td><code>quote</code></td>
  <td><code>'"'</code> (the default): a double quote starts a quoted field. <code>''</code>: quotes are ordinary text, as R's <code>quote = ""</code> and pandas' <code>quoting=csv.QUOTE_NONE</code></td>
  <td><code>quote =&gt; ''</code></td>
</tr>
<tr>
  <td><code>sheet</code></td>
  <td>which worksheet to read from an <code>.xlsx</code> file: a sheet name, or a 1-based index when no sheet has that name (default: first sheet). An error for any other file</td>
  <td><code>sheet =&gt; 'Sheet2'</code></td>
</tr>
<tr>
  <td><code>na_strings</code></td>
  <td>field texts that mean "missing"; a string or an array reference of strings, mapped to <code>undef</code>. Off by default</td>
  <td><code>'na_strings' =&gt; 'NA'</code></td>
</tr>
<tr>
  <td><code>na_values</code></td>
  <td>pandas' spelling of <code>na_strings</code></td>
  <td><code>na_values =&gt; ['NA', 'N/A']</code></td>
</tr>
<tr>
  <td><code>undef_val</code></td>
  <td><code>write_table</code>'s spelling of <code>na_strings</code>, so a round trip can use one name on both halves</td>
  <td><code>'undef_val' =&gt; 'NA'</code></td>
</tr>
<tr>
  <td><code>explode</code></td>
  <td>VCF only. <code>1</code> (the default): split each sample column into one column per <code>FORMAT</code> key, and return a hoh keyed by <code>CHROM:POS:REF:ALT</code>; <code>0</code>: the file's own columns. See [VCF files](#vcf-files)</td>
  <td><code>explode =&gt; 0</code></td>
</tr>
<tr>
  <td><code>colClasses</code></td>
  <td>R's: store the columns you name as numbers rather than text, which takes about a third of the memory. A hash by column name, a list by position, or one class for every column. See [numeric columns](#numeric-columns-colclasses)</td>
  <td><code>colClasses =&gt; { age =&gt; 'integer', bmi =&gt; 'numeric' }</code></td>
</tr>
</tbody>
</table>

output types can be AOH (aoh), AOA (aoa), HOA (hoa), HOH (hoh)

 read_table($filename, 'output_type' => 'aoh');
 read_table($filename, 'output_type' => 'aoa');
 read_table($filename, 'output_type' => 'hoa');

An AoA's first row is the header, then one array per data row, every row in file column order. That is the shape C<write_table> reads an AoA as, so the two round-trip. It is also the only output type that keeps every field when the header repeats a name, so it does not give the "later values win" warning. Nothing labels an AoA's rows, so C<row_names> is an error with it; a row-names column is read as an ordinary column.

 read_table('taxa.tsv', 'output_type' => 'aoa');
 # [ ['taxid', 'genus', 'species'], ['10090', undef, 'Mus musculus'], ['9606', 'Homo', 'Homo sapiens'] ]

and, like Text::CSV_XS, filters can be applied in order to save RAM on big files:

 $test_data = read_table(
     't/HepatitisCdata.csv',
     filter => {
         Sex => sub {$_ eq 'f'} # where "Sex" is the column name, and "$_" is the value for that column
     },
     'output_type' => 'aoh'
 );

A key of C<filter> picks its column this way:

=over

=item * C<0> is the whole row: C<$_> is the array of the row's fields.

=item * A column's name is that column. When the header repeats a name, it is the
last column with it, the one whose value the row keeps.

=item * Any other number is a field, counting from 1, as in Text::CSV_XS. A name
is tried first, so a column called C<2021> is filtered on as
C<< filter =E<gt> { 2021 =E<gt> ... } >> whatever its position.

=item * Two keys for the same column, such as C<1> and its name, both run, in the
order of their keys sorted as strings. A row is kept only if every filter
returns true.

=back

Each filter is also passed the row's fields and a hash of the row by name, as
C<$_[0]> and C<$_[1]>, and a change it makes to C<$_> is written back into the
row. Inside a filter C<%_> is that same hash.

The filters are called from the parser itself, so a filtered read costs little
more than the filter calls: a 300,000-row, 5-column CSV read as an array of
hashes takes about 0.25 s with one filter and 0.13 s with none. Up to 0.3212
the same filtered read took 0.63 s.
the default delimiter is C<,>
Suffixes C<.csv>, C<.tsv> and C<.vcf> are automatically detected from file names, but if specified, are overridden by C<delim> and/or C<sep>. C<sep> is given priority. A C<.vcf> also changes the default C<comment>; see L</"VCF files">.

A UTF-8 byte-order mark at the start of a text file, which Excel's "CSV UTF-8"
export writes, is dropped rather than read as part of the first column's name,
as pandas' C<read_csv> drops it.

A file is read as bytes and its fields come back as bytes; nothing is decoded.
Text you pass in to be compared with a field — a C<sep>, a C<comment> marker, an
C<na_strings> token, a C<filter> key, C<row_names> or a C<sheet> name — is
compared as UTF-8 bytes when perl holds it as characters, as it does under
C<use utf8> or for a string you have decoded. So C<< 'na_strings' =E<gt> '—' >> under
C<use utf8> matches an em dash in a UTF-8 file. A C<qr//> separator holding such
characters matches each line as UTF-8 instead, and a line that is not valid
UTF-8 is then an error rather than misread. Lines always end at a newline whatever C<$/> is
set to, so a C<local $/;> in the calling code does not change what is read.
Lines may end in LF or CRLF, and a file whose lines end in a bare CR, as
classic Mac OS wrote them, is read as R and pandas read it. The start of the
file is read 64 KB at a time, up to 1 MB, until a CR turns up; if no LF has by
then, the file is split on CR. In any other file a lone CR outside quotes is
dropped.
With C<< 'output_type' =E<gt> 'hoh' >> a file whose only column is the row name gives
one empty hash per row, as R's C<read.table> gives a data frame of zero columns.
Rows that repeat an earlier row's name overwrite it, later values winning, and
C<read_table> warns once for the file, with how many rows did it and the first
of them.

=head3 regular-expression separators

A string C<sep> is always a literal: C<< sep =E<gt> '\s+' >> splits on the three
characters backslash, C<s> and plus. Pass a C<qr//> to split on a pattern instead:

 my $d = read_table('aligned.txt', sep => qr/\s+/);      # whitespace-aligned columns
 my $d = read_table('messy.csv',   sep => qr/\s*,\s*/);  # commas, with blanks around them
 my $d = read_table('mixed.txt',   sep => qr/[;,]/);      # either of two characters

Everything else reads as it does with a literal separator: quoted fields
(a separator inside quotes is text, C<""> is one quote, a quoted field may run
over lines), comments and commented-out headers, blank lines, a byte-order
mark, CRLF and CR line ends, C<filter>, C<row_names>, C<auto_row_names>, C<na_strings> and
all four output types. Details worth knowing:

=over

=item * B<< C<qr/\s+/> is whitespace-delimited >>, as C<sep=r"\s+"> is in pandas and
C<sep = ""> in R's C<read.table>: leading and trailing whitespace on a line make
no field, so indented or right-padded columns read cleanly. This is decided by
the pattern text alone, so C<qr/\s+/x> qualifies and C<qr/[ \t]+/> does not.

=item * B<< Any other pattern cuts as C<split> does >>: a separator at the start of a line
leaves an empty first field, and one at the end an empty last field, just as a
literal separator would.

=item * Capture groups in the pattern are not returned as fields, unlike with C<split>,
and the pattern keeps its own flags (C<qr/x/i>) and its own group numbers, so a
backreference works: C<qr/(:)\1/> splits on C<::>.

=item * A pattern that can match the empty string, such as C<qr/\s*/>, is refused,
since it would cut between every character.

=item * In a whitespace-delimited file, a comment line with as many words as the data
has columns can be taken for a commented-out header, since that is how one
is recognised; see I<commented-out headers> below for when it is.

=item * A pattern under Unicode rules -- C</u>, which C<use v5.12> or later puts on
every C<qr//>, or one using C<\p{...}> -- and one under C</a> reads characters:
a line that is valid UTF-8 is matched as UTF-8, so C<qr/\s+/u> splits on a
U+00A0 or U+2003 between fields and never inside a character such as C<à>.
A line that is not valid UTF-8 is matched as bytes. The fields are the file's
bytes either way. A pattern under the default rules is matched as bytes, so
C<qr/\xe2\x80\x94/> finds an em dash's three bytes; write C<\h> or C<\p{...}>
in such a pattern with C</u> to have it read characters. Plain C<qr/\s+/>
splits on ASCII blanks only, as R's C<sep = ""> and pandas' C<sep=r"\s+"> do.

=item * An C<.xlsx> file ignores C<sep> and C<quote>, whether a string or a pattern.

=item * The separators are found by perl's regex engine, called from the same C
parser a literal separator uses, so a regex read costs little more than a
literal one: on a 300,000 x 5 CSV, C<qr/,/> takes 0.17 s and C<','> 0.14 s. A
string is still the faster choice for a fixed separator, and a pattern that
has to backtrack, such as C<qr/\s*,\s*/> (0.34 s), costs more.

=back

=head3 files with no header, and files with stray quotes (C<header>, C<col_names>, C<quote>)

C<< header =E<gt> 0 >> reads the first line as data. The columns are named by
C<col_names>, or else C<V1>, C<V2>, … as R names them, counted from the first row:

 my $d = read_table('pairs.csv', header => 0);                 # V1, V2, ...
 my $d = read_table('pairs.csv', header => 0, 'col_names' => ['id', 'score']);

C<col_names> with a header (the default) renames the header's columns instead;
if the two differ in length, C<read_table> warns, as R does, and uses
C<col_names>. With C<< header =E<gt> 0 >>, a line starting with the comment marker is
always a comment, even C<#text> with no space after the marker, as in R; with a
header, such a line can be a commented-out header, as described below.

C<< quote =E<gt> '' >> turns quoting off: a C<"> is kept as ordinary text wherever it
appears. By default a C<"> anywhere in a field opens a quoted field that runs to
the next C<">, possibly many lines later, so a file whose quotes are not CSV
quoting -- a name such as C<'Beach rock 4+5"'> -- would have every line up to the
next C<"> read into one cell.

C<read_table> cannot tell a stray C<"> from CSV quoting by looking at the bytes,
and neither can R or pandas. It does say when the file looks like it has one,
and names the line where the quote opened:

=over

=item * If the file ends inside a quoted field, C<read_table> warns and keeps what it
read, as R's C<scan()> does. pandas raises an error here instead.

=item * If a C<"> in the middle of a field, such as C<5'10">, opens a quoted field that
runs past the end of its line, C<read_table> warns, once per file. R reads such
a field the same way; pandas keeps a C<"> in the middle of a field as text.

=item * An C<Alignment error> on a row that a quoted field ran across lines in says so.

=item * C<< quote =E<gt> '' >> warns when every field on the first line is wrapped in C<">, as
R's C<write.csv()> writes them, because those quote marks would then stay in
every name.

=back

A quoted cell that starts at the beginning of its field and holds a line break
is ordinary CSV, and is read without a warning.

Formats that never quote, such as NCBI's taxonomy dumps, want both options:

 # NCBI fullnamelineage.dmp: "id\t|\tname\t|\tlineage\t|", no header
 my $lineage = read_table('fullnamelineage.dmp',
     sep => qr/\t\|\t?/, header => 0, quote => '',
     'col_names' => [qw(tax_id tax_name lineage end)],   # 'end' is the empty field after the last "\t|"
     'output_type' => 'hoa');

On that 3,015,956-line, 900 MB file this takes 2.6 s. A literal
C<< sep =E<gt> "\t|\t" >> takes 1.6 s, but leaves each line's closing C<"\t|"> on the
lineage.

=head3 compressed files (gzip, bzip2)

A gzip- or bzip2-compressed file is read as the text inside it; there is no
option to set:

 my $d = read_table('cohort.tsv.gz');                  # tab-separated, from the .tsv
 my $v = read_table('variants.tsv.bgz');               # bgzip / BGZF
 my $b = read_table('export.csv.bz2');

=over

=item * B<The bytes decide, not the name>, as with R's C<read.table>: a
compressed file without a C<.gz> suffix is still read, and a plain file
named C<.gz> is still text. The name does still pick the default C<sep>,
from the part before C<.gz>, C<.bgz> or C<.bz2>, so C<x.tsv.gz> is
tab-separated.

=item * B<It is streamed>, inflated 64 KB at a time as the rows are read, so a
large compressed file takes no more memory than the plain one would.

=item * B<Every member is read.> bgzip (every C<.vcf.gz>), C<pbzip2>, R's
C<gzfile(, "a")> and C<cat a.gz b.gz> all write files of several
compressed members, and all of them come back whole.

=item * B<Damage is an error, not a short read>: a truncated file, a bad
checksum, or anything but NUL padding after the last member dies naming
the file.

=item * Both need only core modules (C<Compress::Raw::Zlib> and
C<Compress::Raw::Bzip2>). xz, LZMA, zstd and lzop files are recognised by
their first bytes, as R recognises them, and refused with a message that
names the format, rather than read as text. C<.zip> is not read either (an
C<.xlsx>, which is a zip archive, is).

=item * L<C<write_table>|/"write_table"> writes C<.gz> and C<.bz2> files that read
back through this.

=back

=head3 VCF files

A file named C<.vcf>, C<.vcf.gz> or C<.vcf.bgz>, in any case, is read as a VCF
with no options. Each sample's column is split ("exploded") into one column per
C<FORMAT> key, and the records come back as a hash of hashes keyed by
C<CHROM:POS:REF:ALT>:

 my $variants = read_table('calls.vcf.gz');
 # { '20:14370:G:A' => {
 #       CHROM => '20', POS => '14370', ID => 'rs6054257', REF => 'G', ALT => 'A',
 #       QUAL => '29.1', FILTER => '.', INFO => 'NS=3;DP=14;AF=0.5;HOMSEQ;DB',
 #       'NA00001.GT' => '0|0', 'NA00001.GQ' => '48', 'NA00001.DP' => '1',
 #       'NA00001.HQ' => '25,30', 'NA00001.CNL' => '10,20',
 #       'NA00002.GT' => '1|0', ...  },
 #   '20:17330:T:A' => { ..., 'NA00001.CNL' => undef, ... },   # no CNL in this record's FORMAT
 #   ... }

=over

=item * B<Defaults.> C<sep> is a tab and C<comment> is C<##>, so the C<##>
meta-information lines are skipped and the C<#CHROM POS ID ...> line is the
header. The C<#> comes off C<#CHROM>, so the first column is C<CHROM>.

=item * B<The columns.> The eight fixed columns come first, then
C<< E<lt>sampleE<gt>.E<lt>keyE<gt> >> for every sample and every key. C<FORMAT> can differ from
record to record (GATK writes C<GT:AD:DP:GQ:PL> on most and
C<GT:AD:DP:GQ:PGT:PID:PL> on phased ones), so the keys are those of every
record read, in the order each first appears. A key missing from a
record's C<FORMAT> is C<undef>, and so is a value a sample leaves off the end,
which the VCF spec allows (C<./.> under C<GT:AD:DP> is C<GT> alone). C<FORMAT>
and the unsplit sample columns are not returned. A sample with I<more>
values than its C<FORMAT> has keys is an error.

=item * B<Values are text.> C<0/1>, C<34,7> and C<73,0,1043> are returned as
written: C<AD>, C<PL> and C<INFO> are not split further, and C<.> is not
missing unless you pass C<< 'na_strings' =E<gt> '.' >>, which then applies to the
split values as well as to whole fields.

=item * B<The key.> C<CHROM:POS:REF:ALT> identifies a record in practice; C<ID> is
usually C<.>. A key that repeats is warned about once, later records
winning, as with any hoh. C<< 'row_names' =E<gt> 'POS' >>, or any other column
including an exploded one, keys the hash by that column instead.

=item * B<Other shapes.> C<'output_type'> still gives an aoa, aoh or hoa of the
same columns. An aoa is the one to hand to C<write_table>.

=item * B<< C<filter> runs before the split >>, while the file is read, so it sees the
file's own columns: C<FORMAT> and each sample's text whole
(C<< filter =E<gt> { FORMAT =E<gt> sub { /PGT/ } } >>), not C<NA00001.GT>. The columns
are the keys of the records it kept.

=item * B<< C<col_names> >> renames the file's columns before the split, so a
renamed sample names its exploded columns.

=item * B<< C<< explode =E<gt> 0 >> >> returns the file's own columns instead, an aoh by
default, with C<FORMAT> and the samples unsplit. C<< header =E<gt> 0 >> reads the
file that way too, having no C<FORMAT> column to split by, and its
C<#CHROM> line is the first data row, C<#> and all. C<explode> is refused for
a file not named as a VCF.

=back

Passing C<sep> or C<comment> overrides the VCF default, and C<< comment =E<gt> '#' >>
reads the same table. Under any other name, such as C<.tsv> or C<.txt>, the file
is not a VCF to C<read_table>: with C<< comment =E<gt> '##' >> the meta lines are still
skipped, but the first column is C<#CHROM> and nothing is split.

The split is done in C. On a 3,499,678-record single-sample GATK C<.vcf.gz>,
the exploded hoh takes 11.7 s, against 9.1 s for the file's own columns as a
hoh, and an exploded aoa 8.4 s, against 7.0 s for the plain one.

=head3 numeric columns (C<colClasses>)

Every field is read as text unless you say otherwise. On a 64-bit perl a
short number held as text costs about 70 bytes, and held as a number about
24. C<colClasses> takes R's
spelling and R's meaning: name the columns that are numbers, and they are
stored as numbers as the file is read.

 my $d = read_table('cohort.csv', colClasses => { age => 'integer', bmi => 'numeric' });
 my $d = read_table('cohort.csv', colClasses => [ 'character', 'integer', 'numeric' ]);
 my $d = read_table('counts.tsv', colClasses => 'integer');

=for html <table>
<thead>
<tr>
  <th>class</th>
  <th>stored as</th>
  <th>accepts</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>numeric</code> (also <code>double</code>, <code>real</code>)</td>
  <td>a floating-point number</td>
  <td>a decimal number with an optional sign and exponent, or <code>Inf</code>, <code>Infinity</code> or <code>NaN</code> in any case, with blanks either side allowed</td>
</tr>
<tr>
  <td><code>integer</code></td>
  <td>an integer</td>
  <td>an optional sign and digits, a leading blank allowed and nothing after them, within perl's integer range</td>
</tr>
<tr>
  <td><code>character</code>, or <code>undef</code></td>
  <td>the text</td>
  <td>anything (the default)</td>
</tr>
</tbody>
</table>

=over

=item * A hash names columns; one the file does not have is warned about, as R
warns about it, and otherwise ignored. A list goes by position and is
recycled when it is short, as R recycles it; a single class applies to every
column. In a hoh the row-name column counts, and a declared one keys each row
by its number, so C<004> becomes the row named C<4>.

=item * An empty field and an C<na_strings> token are C<undef> in any column. C<NA> is
missing only when C<na_strings> names it.

=item * A field that is not a number of the kind declared is an error naming the
column, the data row and the text, rather than a silent C<0> or C<undef>.

=item * A C<filter> still sees each field's text; the rows it keeps are converted.

=item * Where it differs from R: an integer may be anything that fits perl's integer
(64 bits on most perls), where R's stops at 2147483647; a hexadecimal
number such as C<0x1A> is refused, where R reads it; and an exponent must
have digits, where R reads C<1e> as C<1>.

=back

On a 300,000-row CSV with three of its five columns declared, the table took
74 MB instead of 116 MB, and the read 0.095 s instead of 0.086 s.

=head3 missing values (C<na_strings> / C<na_values> / C<undef_val>)

An empty field is always read as C<undef>. Any I<other> text that a file uses to
mean "missing" — C<NA>, C<N/A>, C<NULL>, C<->, C<-999> — has to be named. It is one
option under three names, so you can spell it whichever way the rest of your
code already does:

=for html <table>
<thead>
<tr>
  <th>spelling</th>
  <th>whose</th>
  <th>use it when</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>na_strings</code></td>
  <td>R's <code>read.table</code></td>
  <td>porting R, or with no reason to prefer another</td>
</tr>
<tr>
  <td><code>na_values</code></td>
  <td>pandas' <code>read_csv</code></td>
  <td>porting Python</td>
</tr>
<tr>
  <td><code>undef_val</code></td>
  <td>this module's <code>write_table</code></td>
  <td>reading back a file this module wrote</td>
</tr>
</tbody>
</table>

All three take a string or an array reference of strings, all three mean
exactly the same thing, and passing more than one is an error, exactly as C<sep>
and C<delim> together are:

 my $d = read_table('cohort.csv', 'na_strings' => 'NA');
 my $d = read_table('cohort.csv', na_values    => ['NA', 'N/A', 'NULL', '-']);
 my $d = read_table('cohort.csv', 'undef_val'  => 'NA');

This matters because the tokens are otherwise ordinary strings, and Perl
numifies a string to C<0>: an unnamed C<NA> in a numeric column does not stop
C<mean> or C<sd>, it silently drags the answer toward zero (with a warning, which
is fatal under C<< warnings FATAL =E<gt> 'all' >> and easy to miss otherwise). It also
gives L<C<write_table>|/"write_table">'s C<undef_val> an inverse, so a file this
module wrote can be read back with its missing cells intact — which is what the
third spelling is for, letting both halves of the round trip name the token the
same way:

 write_table($rows, 'out.csv', 'undef_val' => 'NA');
 my $back = read_table('out.csv', 'undef_val' => 'NA');   # undef again

Note that C<write_table>'s C<undef_val> is one token, being what it writes, while
C<read_table>'s accepts a list, being every token it should recognise.

Details worth knowing:

=over

=item * B<Off by default.> R's C<read.table> defaults to C<na.strings = "NA"> and
pandas recognises a whole list, but C<read_table> recognises nothing beyond
the empty field unless you ask, so a literal C<NA> stays a string in code
that predates this option.

=item * B<Your list replaces the set, it does not extend one> — R's behaviour.
C<< 'na_strings' =E<gt> 'baz' >> maps C<baz> and leaves C<NA> and C<NaN> alone.
pandas would map all three.

=item * B<The match is on the exact field text>, case-sensitively and with no
whitespace stripped, which is also R's rule: C<' NA'> is not C<'NA'>, and
C<'-999.000'> is not C<'-999.0'> (pandas numifies and would match both).
List every spelling a file actually uses.

=item * The header is never mapped, so a column may legitimately be named C<NA>.

=item * A C<filter> runs I<after> the mapping, so it sees C<undef> rather than the
token; select the present rows with C<sub { defined $_ }>.

=item * It applies to C<.xlsx> reads too, and to all three C<output_type> shapes. For
C<hoh>, a mapped row-name cell is a missing row name and is refused the same
way an empty one is.

=back

=head3 commented-out headers

A header that is itself commented out is detected and used automatically, so

 # PDB    score
 1a2b    10
 3c4d    20

reads as though the header were C<PDB, score> (the comment marker and any
following whitespace are stripped from the first column). A commented first
line is only taken as the header when its field count matches the line after
it, and that line looks like data: a number or an C<na_strings> token in one of
its fields, or nothing but empty fields. So

 # written by foo, v2
 id,val
 1,2

reads with the header C<id, val>, as R and pandas read it: the comment is as
wide as the header, but C<id,val> has no number in it, so it is the header and
the comment is a comment. The rule cannot tell a commented-out header over rows
with no numbers in them from a comment, and reads the first of those rows as
the header.

When several comment lines come before the header, it is the last of them,
the one next to the data, that is tried as the header, and the rest are
comments:

 #written by foo
 #id,val
 1,2

reads with the header C<id, val>. If the last one fails the test above, the
line after the comments is the header, so R's own

 #comment
 #another
 C1    C2    C3
 "Panel"    "Area Examined"    "# Blemishes"

reads with the header C<C1, C2, C3>, as C<read.table(header = TRUE)> reads it.
Only lines before the header are looked at this way: a line starting with the
comment marker I<after> the header, if the marker hugs its text (C<#3,4>), is a
data row, while one with a blank after the marker (C<# note>) is a comment
wherever it is.

A marker inside quotes is text, as R's C<read.table> reads it: a header written
C<"#a",b> has the columns C<#a> and C<b>, and a quoted C<"#x"> or C<"# x"> is a
field like any other, never a comment. C<write_table> quotes a first field that
starts with C<#> for this reason, so that it reads back as written.

You may name a commented-out header's column in a C<filter> either
as it appears in the file or by its clean name:

 read_table('ranks.tabular.tsv', filter => { '# PDB' => sub { $_ == 2 } });

=head3 Excel (.xlsx) files

A file whose name ends in C<.xlsx> — or C<.xlsm>, C<.xltx> or C<.xltm>, the
macro-enabled and template workbooks, which hold their sheets the same way —
is read directly, with B<no extra
dependencies> — the core C<IO::Uncompress::Unzip> module pulls the parts out of
the (zipped) workbook and the worksheet XML is parsed in XS, through the same
fast path a delimited file takes: C<read_table> reads the header in Perl and the
rows are assembled in C. All C<output_type>, C<filter>, and C<row_names> options
work exactly as they do for text files:

 my $data = read_table('samples.xlsx');
 my $data = read_table('samples.xlsx', sheet => 'Results');   # by name
 my $data = read_table('samples.xlsx', sheet => 2);           # 1-based index

A C<sheet> is looked up as a name first and as a number only when no sheet has
that name. So in a workbook whose sheets are C<2024> and C<2023>,
C<< sheet =E<gt> 2023 >> is the sheet named C<2023>, and C<< sheet =E<gt> 2 >> is the second.

B<Multiple worksheets.> If the workbook has more than one worksheet and no
C<sheet> is given, C<read_table> returns a B<hashref keyed by worksheet name>,
each value being that sheet parsed just as a single table would be (honouring
C<output_type>, C<filter>, etc.):

 my $book = read_table('report.xlsx');   # { Sheet1 => [...], Sheet2 => [...] }
 my $rows = $book->{Results};

A workbook with a single worksheet, or a call that names a C<sheet> explicitly,
returns that one table directly (not wrapped in a hash). A worksheet with no
name is keyed C<SheetN>, C<N> its position, or the next number no other sheet is
named with, so it never replaces a sheet that really has that name.

The XML is read as an XML parser would read it: comments are skipped (a
commented-out row is not data), a CDATA section is its literal text, and a
line end written as CR LF or a lone CR is LF, while one written as C<&#13;>
stays a CR. Rich-text runs are concatenated into a single value, and the
phonetic guide (C<< E<lt>rPhE<gt> >>, the furigana Japanese Excel records for text typed
through the input method) is left out of it, as openpyxl leaves it out. The
shared-string table is found through the workbook's relationships, so it is
read whatever the writer named it. Excel's own escape for a character XML
cannot hold, C<_x> and four hex digits and C<_> (C<_x0000_> for NUL, C<_x005F_>
for a literal underscore), is decoded in string cells as Excel and LibreOffice
decode it, so a control character that C<write_table> wrote reads back as
itself; a formula's cached result is left as written.

Limitations: dates and times are returned as their raw Excel serial numbers
(cell number formats are not applied); a cell that has formatting but no value is a
blank, whether it is written C<< E<lt>c s="2"/E<gt> >>, C<< E<lt>c s="2"E<gt>E<lt>/cE<gt> >> or with an empty
C<< E<lt>vE<gt>E<lt>/vE<gt> >>, and blanks past a row's last value do not add columns (readxl and
pandas leave them out too); and two things the format does not allow are
read as if they were not there — a cell reference past C<XFD>, the last of the
16,384 columns a worksheet has, places the cell in the next column instead, and
a numeric character reference to something XML does not allow as a character
— C<&#0;> and the other control characters but tab, LF and CR, a UTF-16
surrogate, C<&#xFFFE;>, C<&#xFFFF;>, or anything past C<&#x10FFFF;> — is left in
the text rather than decoded. The C<sep>, C<delim>, and C<comment> options do not
apply to C<.xlsx> files, so a cell such as C<#id> is read as it is. A workbook
whose elements carry a namespace prefix (C<< E<lt>x:rowE<gt> >>, as the Open XML SDK writes
them) is read like any other. Tested in C<t/read_table.xlsx.t>,
C<t/read_table.xlsx.parser.t> and C<t/read_table.xlsx.xml.t>.

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
 print "@{ $r->{'auc_ci'} }";     # 0.649 1.000
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

The sample is drawn without replacement, so C<n> may not exceed the number of
elements or keys there are to draw from; asking for more is an error, as it is
in R (I<cannot take a sample larger than the population when 'replace = FALSE'>):

 sample([1, 2, 3], 10);   # dies: cannot take a sample of 10 from a population of 3

Through 0.314 the two shapes disagreed about this and neither said so — a hash
quietly returned fewer keys than were asked for, and an array padded the result
out to C<n> with C<undef>, so C<sample([1,2,3], 10)> came back as three values and
seven undefs that no caller could tell apart from real data.

=head2 scale

 my @scaled_results = scale(1..5);

You can also pass options, either as a trailing hash reference or as trailing
name/value pairs — the two are equivalent:

 my @scaled_results = scale(1..5, { center => 0, scale => 1 });
 my @scaled_results = scale(1..5, center => 0, scale => 1);

C<center> and C<scale> each take a number to use instead of the mean or the
standard deviation, or one of C<mean>/C<sd>, C<true>/C<false>, C<none>, C<1>/C<0> and
the empty string, matched case-insensitively. With C<< center =E<gt> 0 >> the divisor
is R's: the root mean square about zero, C<sqrt(sum(x^2)/(n-1))>, not the
standard deviation.

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

Works as closely as I can to R's C<seq>, which is very similar to Perl's C<for>
loops.  Returns an array, not an array reference.

Specifically it mirrors C<base::seq.default>, which is what R's C<seq()>
dispatches to, and I<not> the C<seq.int()> primitive: the two do not agree, and
the disagreements are visible from Perl.  Takes C<from>, C<to>, and an optional
C<by>.

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

=head3 Leaving C<by> out

Without a C<by>, C<seq> is R's C<from:to>: unit steps in whichever direction C<to>
lies.  So C<seq(5, 1)> is C<5 4 3 2 1>, the same as R.  Only an explicit C<by>
whose sign disagrees with the direction of travel is an error.

C<from:to> is also a different function from C<by = 1>, with a looser fuzz
factor, which is worth knowing before you supply a C<by> you think is
redundant:

 scalar @{[ seq(1, 4.9999999)    ]};   # 5  -- 1 2 3 4 5
 scalar @{[ seq(1, 4.9999999, 1) ]};   # 4  -- 1 2 3 4

R does the same thing, for the same reason: C<1:4.9999999> adds
C<1 + FLT_EPSILON> before truncating, and C<seq(1, 4.9999999, by = 1)> adds
C<1e-10>.

=head3 How many values you get

Nothing accumulates: element I<i> is C<from + i * by>, and the count is
C<int((to - from)/by + 1e-10) + 1>.  Both formulae are R's.  The C<1e-10> is
why C<seq(0, 1, 0.1)> has eleven values and not ten — C<(1 - 0)/0.1> is not
quite 10 in binary floating point.  The last value is then pinned to C<to>
if the fuzz carried it past, which R added in 2.9.0, so

 (seq(0, 1, 0.00025 + 5e-16))[-1];     # exactly 1, not 1 + 2e-12

=head3 When one value comes back instead of many

Three cases collapse to a single value rather than raising an error, all
following R:

=over

=item * C<by> is C<0> and C<from == to>, which returns C<from>;

=item * C<to - from> is C<0> and C<to> is C<0>, which returns C<to> whatever C<by> is;

=item * C<from> and C<to> are indistinguishable at the working precision — that is,
C<abs(to - from) / max(abs(to), abs(from))> is below C<100 * DBL_EPSILON>.
This is why C<seq(1e15, 1e15 + 20, 2)> is the single value C<1e15> and not
eleven values: at that magnitude a C<double> cannot tell C<1e15> from
C<1e15 + 20> well enough for the step to mean anything.  Widen the gap and
the sequence comes back — C<seq(1e15, 1e15 + 200, 2)> is 101 values.

=back

=head3 Errors

All five messages are R's own wording:

=over

=item * C<from> or C<to> is C<NaN> or infinite — C<seq: 'from' must be a finite number>,
or the same for C<'to'>.

=item * C<by> has the wrong sign for the direction of travel —
C<seq: wrong sign in 'by' argument>.

=item * C<by> is C<0> with C<from != to>, or C<by> is C<NaN> —
C<seq: invalid '(to - from)/by'>.

=item * the sequence would have more than C<INT_MAX> values —
C<seq: 'by' argument is much too small>.

=item * C<from:to> would span more than C<INT_MAX> —
C<seq: result would be too long a vector>.

=back

The fourth of these used to be silent: up to 0.314 a count that overflowed
C<size_t> returned the empty list, so C<seq(0, 1e30, 1)> and C<seq(0, 1, 1e-11)>
both handed back nothing at all, and C<seq(NaN, 5)> died inside perl with
C<panic: stack_grow() negative count>.  C<seq(5, 1)> croaked
C<wrong sign in 'by' argument> in that release too.

=head3 Integers come back as integers

When every value in the sequence is an exact integer no larger than C<2**53>,
C<seq> returns Perl integers (IVs) rather than floats — which is also what R
returns for the same call, an integer vector.  The numbers are identical
either way, but the representation is much cheaper to use: stringifying the
result never goes through C<Gconvert>, so on this machine

 join ',', seq(1, 1_000_000);

dropped from 409 ns per element to 83, and building the list itself from 16.3
to 12.7, putting C<seq> level with perl's own C<1 .. 1_000_000>.  A sequence
with a fractional step stays floating point, as it must.

One consequence is cosmetic: a large integral value now prints in full rather
than in exponent form, so C<seq(1e15, 1e15 + 200, 2)> starts
C<1000000000000000> where it used to start C<1e+15>.

=head3 Context

C<seq> is a list function and the array is the point of it, but the other two
contexts are cheap rather than wasteful: in void context it builds nothing,
and in scalar context it builds only the value the caller can see, which is
the last one — what perl gives for any list-returning sub.  So

 seq(1, 10_000_000);          # costs nothing
 my $last = seq(1, 10);       # 10, without ten million SVs behind it

There is no C<length.out> and no one-argument form; C<seq(17)> is an error
rather than R's C<1:17>.

=head2 shapiro_test

tests to see if an array reference is normally distributed, returns a p-value and a statistic

 my $shapiro = shapiro_test(
     [1..5]
 );

and returns the hash reference:

 {
 p_value     0.96717393596804,
 statistic   0.986762155447719,
 W           0.986762155447719
 }

matching R's C<shapiro.test(1:5)> to the last digit it prints. Values that are
C<undef> or C<NaN> are dropped first, exactly as R's C<complete.cases()> drops
them, and the remaining sample must hold between 3 and 5000 values.

=head2 skew

Sample skewness — the direction and degree of a distribution's asymmetry.
Positive means a long right tail (the usual shape of lab values, costs and
lengths of stay), negative a long left tail, and about zero a symmetric sample.
Validated numerically against R.

 skew(2, 4, 4, 4, 5, 5, 7, 9);        # 0.8184875533568

Below, three samples standardized to mean C<0> and standard deviation C<1>, each
against the same C<N(0, 1)> curve in grey: a log-normal sample mirrored into a
long left tail, a normal sample, and the log-normal itself. The sign of C<skew>
is which side of the median the mean has ended up on — the long tail pulls the
mean towards itself and leaves the median behind, which is why a skewed lab
value is usually better summarized by its median than by its mean.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/skew.what.png" alt="a left-tailed, a symmetric and a right-tailed sample, with the mean and median of each" width="100%" /></p>

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
 skew(\@x, type => 1); # 0.3818017742   plain moment ratio
 skew(\@x);            # 0.9352195296   G1, the default
 skew(\@x, type => 3); # 0.2078265621   b1

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

=head3 Compared with List::Util

C<min>, C<max> and C<sum> pass List::Util's own tests for the same names
(C<t/min.max.sum.ListUtil.t> carries them) except where the two differ on
purpose:

=for html <table>
<thead>
<tr>
  <th></th>
  <th>List::Util</th>
  <th>Stats::LikeR</th>
</tr>
</thead>
<tbody>
<tr>
  <td>an array reference</td>
  <td>a number (its address)</td>
  <td>its elements, read as data</td>
</tr>
<tr>
  <td>a blessed array reference that overloads <code>0+</code></td>
  <td>one number</td>
  <td>still its elements, read as data</td>
</tr>
<tr>
  <td>no arguments</td>
  <td><code>undef</code></td>
  <td>dies: <code>sum needs &gt;= 1 element</code> (and likewise for <code>min</code> and <code>max</code>)</td>
</tr>
<tr>
  <td>a string that is not a number, such as <code>'abc'</code></td>
  <td>0</td>
  <td>dies, naming the argument</td>
</tr>
<tr>
  <td><code>NaN</code> anywhere</td>
  <td>depends on where it is: <code>min(NaN, 1, 2)</code> is <code>NaN</code> but <code>min(1, 2, NaN)</code> is 1</td>
  <td><code>NaN</code>, wherever it is, as in R</td>
</tr>
<tr>
  <td>the result</td>
  <td>an IV while every value fits one, so <code>sum(1&lt;&lt;60, 1)</code> is exact</td>
  <td>an NV, so on a <code>double</code> perl <code>sum(1&lt;&lt;60, 1) == 1&lt;&lt;60</code>, as R's <code>sum</code> gives too</td>
</tr>
<tr>
  <td>a Math::BigInt</td>
  <td>a Math::BigInt</td>
  <td>the NV its <code>0+</code> overload gives</td>
</tr>
</tbody>
</table>

Anything else that is a number is taken as one: an object that overloads C<0+>
(when it is not a blessed array reference), a tied scalar, C<$#array>, or a
C<substr()> lvalue. Each is fetched once. The same rules hold for C<mean>,
C<median>, C<sd>, C<var>, C<mode>, C<uniq>, C<scale>, C<skew> and C<kurtosis>.

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

=head2 svyglm

Design-based regression for survey data, C<survey::svyglm()> on a
C<survey::svydesign()>: point estimates weighted by the sampling weights, and
standard errors by Taylor linearization that respect the strata and the
clustering into primary sampling units (PSUs). Putting the sampling weights
into L<C<glm>|/"glm">'s C<weights> gives the same point estimates but standard
errors that are wrong for a complex sample.

 use Stats::LikeR 'svyglm';

 my $s = svyglm(formula => 'api00 ~ ell + meals + mobility', data => \%apistrat,
                weights => 'pw', strata => 'stype');
 my $c = svyglm(formula => 'sch.wide ~ ell', data => \%apiclus1, family => 'quasibinomial',
                weights => 'pw', cluster => 'dnum', fpc => 'fpc');

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
  <td><code>formula</code></td>
  <td><i>(required)</i></td>
  <td>Formula as for [<code>glm</code>](#glm), with <code>offset()</code> terms allowed.</td>
</tr>
<tr>
  <td><code>data</code></td>
  <td><i>(required)</i></td>
  <td>HoA, AoH or HoH.</td>
</tr>
<tr>
  <td><code>family</code></td>
  <td><code>'gaussian'</code></td>
  <td><code>'gaussian'</code>, <code>'binomial'</code>, <code>'quasibinomial'</code>, <code>'poisson'</code> or <code>'quasipoisson'</code>. The <code>quasi</code> names give the same fit, as in <code>survey</code>.</td>
</tr>
<tr>
  <td><code>weights</code></td>
  <td>1</td>
  <td>Sampling weights (<code>svydesign(weights = )</code>): a column name or an array ref.</td>
</tr>
<tr>
  <td><code>strata</code></td>
  <td><i>none</i></td>
  <td>Stratum of each row.</td>
</tr>
<tr>
  <td><code>cluster</code></td>
  <td>one PSU per row</td>
  <td>The PSU of each row (<code>svydesign(ids = )</code>); also accepted as <code>ids</code>, <code>id</code> or <code>psu</code>.</td>
</tr>
<tr>
  <td><code>fpc</code></td>
  <td><i>none</i></td>
  <td>Finite population correction: the population size of the stratum, or the sampling fraction (a value at most 1), as <code>svydesign(fpc = )</code> reads it.</td>
</tr>
<tr>
  <td><code>nest</code></td>
  <td><code>0</code></td>
  <td><code>svydesign(nest = TRUE)</code>: PSU labels are only unique within a stratum.</td>
</tr>
<tr>
  <td><code>offset</code></td>
  <td><i>none</i></td>
  <td>A column, an expression or an array ref.</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td><code>0.95</code></td>
  <td>Level of <code>conf_int</code>.</td>
</tr>
</tbody>
</table>

The result holds C<coefficients>, C<summary> (per term C<Estimate>, C<Std. Error>,
C<t value>, C<< Pr(E<gt>|t|) >>), C<vcov>, C<conf_int>, C<terms>, C<fitted_values>,
C<deviance>, C<dispersion> (C<summary.svyglm>'s), C<df_residual>, C<degf> (the
design degrees of freedom, PSUs minus strata, which the t tests use), C<rank>,
C<nobs>, C<n_psu>, C<n_strata>, C<converged> and C<iter>. Only single-stage designs
are implemented (the first stage's PSUs and strata, as C<survey> uses by
default). Validated against C<survey>'s own tests on the C<api> data.

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

=head3 What the test is asking

Every t-test is the same three numbers. C<estimate> is what the data say — a
mean, or a difference of means. C<mu> is what the null hypothesis says. The
standard error is how far apart those two would ordinarily drift by chance
alone, and C<statistic> is the distance from C<mu> to C<estimate> measured in
standard errors:

 statistic = (estimate - mu) / SE

C<df> says which t distribution that statistic would follow if the null were
true, and C<p_value> is the area of that distribution further out than the
statistic — the chance of landing this far from C<mu>, or further, when C<mu> is
right. Below, R's C<sleep> data as a paired test: ten patients, each measured on
two drugs, so the ten paired differences are one sample and C<mu = 0> is "the two
drugs are the same". The middle panel is the whole p-value; the right panel is
one of its two tails, magnified until it can be seen.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/t.test.what.png" alt="the estimate, mu and the standard error, and the null distribution the p-value is an area under" width="100%" /></p>

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
  <td>The first vector of data. Must have at least 2 non-missing elements, except in a <code>var_equal</code> test, where either <code>x</code> or <code>y</code> may have 1.</td>
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
  <td>If true, assumes equal variances (standard two-sample). If false, performs Welch's t-test with unequal variances. The dotted <code>var.equal</code> is refused as an unknown argument.</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td>Float</td>
  <td>0.95</td>
  <td>Confidence level for the returned confidence interval, from 0 to 1 inclusive, as in R: 1 gives <code>(-Inf, Inf)</code> and 0 a point at the estimate (or an infinite point for a one-sided test). The dotted <code>conf.level</code> is refused as an unknown argument. See [Extreme <code>conf_level</code>](#extreme-conf_level) for the precision limit past about <code>0.9999</code>.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>String</td>
  <td><code>"two.sided"</code></td>
  <td>Direction of the alternative hypothesis: <code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>. <code>"two-sided"</code> and <code>"two_sided"</code> are accepted as <code>scipy</code>'s spelling of the same thing. Anything else is a fatal error — an unrecognised value must not quietly become a two-sided test.</td>
</tr>
</tbody>
</table>

=head3 C<conf_int>

C<conf_int> is the estimate plus and minus a multiple of the same standard error
the statistic divides by, and C<conf_level> picks the multiple — the t quantile
at that level and C<df>. Nothing else goes into it. On the left below, the whole
interval taken apart: for the paired C<sleep> test, C<2.26216 * 0.38896 = 0.87989>
either side of C<-1.58>. On the right, the same interval at six confidence
levels. A wider C<conf_level> needs a bigger quantile and so gives a wider
interval, and the level at which the interval first reaches C<mu> is exactly
C<1 - p_value> — the second panel from the bottom, whose upper bound lands on
zero.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/t.test.conf.int.png" alt="conf_int is the estimate plus or minus a t quantile times the standard error, and conf_level sets the quantile" width="100%" /></p>

=head3 C<alternative>

C<alternative> decides which part of the null distribution counts against the
null, and therefore both C<p_value> and C<conf_int>. C<"two.sided"> counts both
tails beyond C<|statistic|>, C<"less"> counts only what lies below the statistic,
and C<"greater"> only what lies above; the two one-sided p-values always add to
1, and each is half the two-sided one when it is the smaller. The interval
follows: a one-sided alternative gives a one-sided interval, with the other
bound infinite. The example is C<t_test($drug1, $drug2)> on C<sleep> — the same
twenty numbers as above, but unpaired.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/t.test.alternative.png" alt="the three alternatives, the region of the null distribution each one counts, and the interval that goes with it" width="100%" /></p>

=head3 C<mu>, C<p_value> and C<conf_int> say one thing

C<conf_int> is the set of C<mu> the test would not reject. Sweep C<mu> across the
line and re-run the test at each value: the p-value peaks at 1 where C<mu> equals
the estimate, and falls through C<1 - conf_level> at precisely the two bounds of
C<conf_int>. That is what "the interval excludes zero" and "p is below 0.05" both
mean — they are one statement, not two pieces of evidence.

Which is also why C<mu> never moves C<conf_int>. Changing C<mu> changes which
hypothesis is being tested, so C<statistic> and C<p_value> move with it; the
interval is built around the estimate and stays where it is.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/t.test.duality.png" alt="p_value as a function of mu, crossing 1 - conf_level exactly at the two bounds of conf_int" width="100%" /></p>

=head3 What a falling p-value looks like

The same thing seen from the data's side: two samples drawn from two different
distributions, pulled steadily apart. Each column below is one C<t_test> of the
C<sleep> groups with drug 1 shifted — the top panel is the two distributions, by
this module's own L<C<density>|/"density">, and the bottom panel is the C<conf_int>
that comes back. The columns are four p-values five orders of magnitude apart.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/t.test.p.and.ci.png" alt="two distributions separating, and the conf_int retreating from mu as the p-value falls" width="100%" /></p>

Only one thing about the interval changes: where it sits. C<df> stays at
C<17.7765> and its width stays at C<3.5710> down the whole row, because shifting a
sample changes neither the spread nor C<n>, and those are all the standard error
is made of. What moves is the distance from C<mu> — and the second column is the
hinge: at C<p_value = 0.05> the interval's upper bound is C<0.0000>, sitting
exactly on C<mu>, because "p below 0.05" and "the 95% interval clear of C<mu>" are
the same event.

Reading the two together is the point. C<p_value> reports the distance from C<mu>
in standard errors and nothing else, so it says how surely the difference is not
zero, never how big it is; C<conf_int> reports the difference itself, in hours of
sleep. The other route to a small p is a smaller standard error — more
observations, or less spread — and that one drives C<p_value> down by narrowing
the interval around an estimate that has not moved at all.

=head3 C<paired> and C<var_equal>

The same twenty numbers give three different answers depending on what is
assumed about them. C<< paired =E<gt> 1 >> says the two vectors are two measurements of
the same ten subjects and tests the ten differences, which removes the
subject-to-subject variation and here turns C<p = 0.079> into C<p = 0.0028>.
Unpaired, C<< var_equal =E<gt> 1 >> pools the two variances into one and spends
C<n(x) + n(y) - 2> degrees of freedom; the default Welch test does not pool, and
buys that safety with a fractional C<df> from the Welch–Satterthwaite equation.

Welch's C<df> is at most C<n(x) + n(y) - 2>, reaching it only when the two spreads
match, and falls toward C<n - 1> of whichever sample dominates the standard error
as they separate. The middle and right panels sweep C<t.test(1:10, 7:20)> — the
other example in R's C<?t.test> — scaling the spread of C<y> about its own mean:
C<var_equal> keeps claiming 22 degrees of freedom throughout, and pays for the
claim with a p-value that is wrong by three orders of magnitude at the left-hand
edge.

=for html <p><img src="https://raw.githubusercontent.com/hhg7/stats/main/img/t.test.designs.png" alt="paired, var_equal and Welch on the same data, and the Welch degrees of freedom as the two spreads separate" width="100%" /></p>

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
- C<conf_level> is below 0, above 1, or C<NaN>
- C<mu> or C<conf_level> is C<undef> or a reference (R's "must be a single
  number"), or C<mu> is C<NaN>; an object that overloads numification is a number
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
<tr>
  <td><code>stderr</code></td>
  <td>The standard error <code>statistic</code> divides by, as R has returned it since 3.6.0.</td>
</tr>
</tbody>
</table>

=head3 Accuracy

The variance is R's: a mean, a correction by the mean of the residuals, then
the squared deviations about it. Two things go beyond R. The deviations are
also summed and their square taken back out (the Chan–Golub–LeVeque
correction), and that same sum is carried into C<statistic> as the part of the
mean no double can hold. That keeps C<statistic> accurate on a sample whose
spread is a few dozen ulps of its mean, where R's is out in the third digit.
The data are also scaled by a power of two before squaring, so a sample whose
squares pass C<DBL_MAX> still gets a finite variance and Welch C<df>, where R's
Welch C<df> is C<NaN>. On ordinary data the two agree to about 1e-13.

Tied arrays, tied elements and tied scalars holding the array reference are
all read through their C<FETCH>, once each.

Validated against R 4.6.1's C<stats::t.test> and against C<scipy.stats>, by
C<t/t_test.R.scipy.t> and C<t/t_test.tails.R.t>. The R cases are every C<t.test()>
call in R's own sources: the examples of C<?t.test>, C<?sleep>, C<?ks.test>,
C<?array2DF> and C<?pairwise.t.test>, R-intro, the tcltk demo, and
C<reg-tests-1a.R>, C<reg-tests-1e.R> and C<reg-tests-2.R>. Each is checked against
R's pinned C<.Rout.save> output and crossed over every alternative,
C<var_equal>, C<mu> and C<conf_level>. The far tails are checked against
C<d-p-q-r-tst-2.R>'s C<pt()> cases. The SciPy cases come from C<TestTTest_1samp>,
C<TestTTestIndMore>, C<TestTTestRel> and C<TestTTestCI>.

The figures above are drawn by C<t.test.plots.pl> in the repository, from the
two examples in R's C<?t.test>: the C<sleep> data (C<t = -1.8608>, C<df = 17.776>,
C<p-value = 0.07939> unpaired, C<t = -4.0621>, C<df = 9>, C<p-value = 0.002833>
paired) and C<t.test(1:10, y = c(7:20))>. Every number annotated on them comes
back out of C<t_test> itself, so a figure cannot drift away from the module. It
is an author-only script — it is not installed, and it needs
C<Matplotlib::Simple>, C<python3> and C<matplotlib> — so re-run it only when a
figure needs to change.

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

This is where C<uniq> parts company with R's C<unique()> and pandas'
C<pd.unique()>, which compare doubles by value. On a build whose C<NV> is a double,
C<0.1 + 0.2> and C<0.3> are two different doubles that both print C<0.3>, so they
are one value here and two there; C<1000000000000000> and C<1e15> are the same
number, printed C<1000000000000000> and C<1e+15>, so they are two values here and
one there. Which pairs fall which way moves with the width of the C<NV>, because
the printing does — C<uniq> follows C<eq> on every build.
Compare doubles by value — with a C<%.17g> C<sprintf>, or by rounding — before
calling C<uniq> if that is what you need.

In list context C<uniq> returns the distinct values. In scalar context it
returns the I<count> of distinct values, matching C<List::Util::uniq>. Scalar
context is the cheaper of the two: it never builds the result list.

The UTF-8 flag is part of the comparison key, so a UTF-8 string and a
byte-identical non-UTF-8 string are kept distinct — they are different strings.
Strings that are logically equal and consistently encoded collapse as expected:
a UTF-8 string whose every character is below C<\x{100}> is compared against the
bytes it downgrades to, so C<"\x{e9}"> and C<"\xe9"> are one value, exactly as
C<eq> and a Perl hash key both have it.

The input is left alone. C<uniq> renders a plain number into its own buffer
rather than asking Perl for the number's string, so it does not leave a cached
C<PV> on the caller's SVs — taking the distinct values of a large numeric column
no longer grows that column. Tied arrays and tied elements are read through
their C<FETCH>.

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

=item * B<< A missing cell is C<undef>. >> For AoH and HoH, a row that lacks the column yields C<undef> for that row, as long as at least one row has it. A row that isn't a hashref dies, naming the row.

=item * B<An absent column dies, in every shape.> When no row of an AoH or HoH has the column, or a HoA has no such key, C<vals> dies with C<vals: no column named "Method"> (and C<avals> with C<avals: no column named "Method">) instead of returning a column of C<undef>s, which almost always meant a misspelt name. A column that exists but holds only C<undef> is not absent, and neither is a HoA column whose value is not an arrayref, which dies with its own message.

=item * B<< Empty frames return C<[]> >> -- an empty AoH or an empty hash both give a clean empty arrayref.

=item * UTF-8 column names and HoH keys are handled correctly (lookups use the key SV; HoH keys sort by Perl string order).

=back

=head3 Examples

 my $aoh = read_table('patients.csv');                 # array of hashes
 my $age = vals($aoh, 'Age');                           # [ 34, 51, ... ]

 my $hoa = read_table('patients.csv', 'output_type' => 'hoa');
 my $sex = vals($hoa, 'Sex');                           # copy of the Sex column

 my $hoh = read_table('patients.csv', 'output_type' => 'hoh');
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

The two new subsections (Array of hashes, Array of arrays) are the only additions; everything else is unchanged. They're placed after the array-container forms to keep array inputs grouped, mirroring how Hash of array / Hash of hash sit together.

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

 my $aoh = read_table('all.data.tsv', 'output_type' => 'aoh');

 view($aoh);                       # first 6 rows, like head()
 view($aoh, n => 20);              # first 20 rows
 view($aoh, cols => [qw(id age tt)]);   # force a column order
 view($aoh, 'row_names' => 'id');  # use column 'id' as the row label
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
  <td><code>row_names</code></td>
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
C<row_names>/C<cols> handling, control-character escaping, the C<return_only> and
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

Arguments that R spells with a dot take an underscore here: C<conf_int>, C<conf_level>, C<digits_rank> and C<tol_root>. R's dotted spellings (C<conf.int>, C<conf.level>, C<digits.rank>, C<tol.root>) are refused as unknown arguments.

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
  <td><code>conf_int</code></td>
  <td>boolean</td>
  <td><code>0</code> (false)</td>
  <td>Also compute a point estimate and confidence interval for the location (one-sample) or location shift (two-sample / paired).</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td>number in (0,1)</td>
  <td><code>0.95</code></td>
  <td>Requested confidence level. The level a rank test can actually deliver is discrete, so the level achieved is reported back in <code>conf_level</code> and is generally not the one asked for.</td>
</tr>
<tr>
  <td><code>digits_rank</code></td>
  <td>number / undef</td>
  <td><code>undef</code> (Inf)</td>
  <td>Round each value to this many significant digits before ranking, so that ties are decided on the rounded values. R's <code>digits.rank</code>, and worth reaching for when the data are the result of arithmetic and two values that ought to tie differ in the last bit. <code>undef</code> means no rounding.</td>
</tr>
<tr>
  <td><code>tol_root</code></td>
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
  <td><i>(only with <code>conf_int</code>)</i> The Hodges-Lehmann estimator: the median of the Walsh averages <code>(x[i] + x[j]) / 2</code> in the one-sample case, or of the pairwise differences <code>x[i] - y[j]</code> in the two-sample case. On the asymptotic path it is instead the shift at which the standardised statistic is zero, as in R.</td>
</tr>
<tr>
  <td><code>conf_int</code></td>
  <td>ARRAY ref</td>
  <td><i>(only with <code>conf_int</code>)</i> Two elements, the lower and upper limits. A one-sided alternative gives an unbounded end (<code>-Inf</code> or <code>Inf</code>).</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td>number</td>
  <td><i>(only with <code>conf_int</code>)</i> The confidence level actually achieved, which for the exact interval is a step function of the data and rarely equals <code>conf_level</code>.</td>
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

The exact confidence interval on tied data is found as R finds it, by trying the shift between each pair of neighbouring pairwise differences, up to C<m * n> of them, each with its own conditional distribution. That distribution depends only on the ranks, so it is rebuilt only when a shift changes them. Two samples of 49 five-point scores, which take the exact path by default, get their interval in about 0.03 seconds; R 4.6.1 takes 10.

=head3 Notes and edge cases

Missing data is handled by listwise removal of non-numeric, undefined and C<NaN> cells before ranking; in the paired case a pair is dropped if either member is missing or if the difference is not a number. An empty C<x> (or a C<y> that is present but empty) after this filtering is fatal. All-zero differences are not: C<wilcox_test([0, 0, 0, 0, 0])> returns C<V = 0>, C<p = 1>, which is what the permutation distribution over an empty set of sign flips says. A tied array is read like any other, one C<FETCH> per element.

C<Inf> and C<-Inf> are values, not missing data, and a rank test has no trouble with them. In a confidence interval, a difference of two infinities of the same sign (C<Inf - Inf>) is C<NaN>, and it is left out of the differences (or Walsh averages) the estimate and the interval are read from, just as R's C<sort()> leaves it out.

Ties are detected during ranking and trigger the tie-corrected variance in the normal approximation. When C<exact> is left on auto, the size thresholds (C<< E<lt> 50 >> per group, or C<< E<lt> 50 >> observations) are the only thing gating the exact vs. approximate decision.

=head3 Differences from R

Three, all deliberate:

=over

=item * B<< C<correct> is a boolean here. >> R 4.6.0 turned its C<correct> into an integer C<0:3>, in which numeric C<0> still applies the continuity correction and only C<FALSE> removes it. Keeping that would mean C<< correct =E<gt> 0 >> no longer meaning "off", which is what it means for every other flag in this module. So C<correct> stays a boolean and the Edgeworth terms live under C<edgeworth>: R's C<correct = k> for C<k> in C<1, 2, 3> is C<< correct =E<gt> 1, edgeworth =E<gt> k >> here, and R's C<correct = 0> is C<< correct =E<gt> 1 >>.

=item * B<A zero variance is reported, not propagated.> With C<< exact =E<gt> 0 >> and every observation tied there is nothing to divide by; R divides anyway and returns C<NaN> for the p-value, and its two-sample confidence interval then dies inside C<uniroot> with I<missing value where TRUE/FALSE needed>. This warns instead, and returns C<p = 1> and a C<NaN> interval at level C<0> — which is what R's own one-sample code does. The default path no longer reaches any of this, since the exact test handles all-tied data.

=item * B<Infinite observations get an answer or a reason, never an error.> The asymptotic interval has no finite bracket to search when an observation is infinite. R's two-sample code dies in C<uniroot> with I<invalid 'xmin' value>, and its one-sample code returns a C<NaN> interval at level C<0>. Both give that C<NaN> interval here, with a warning. The exact one-sample interval on data holding both C<Inf> and C<-Inf> stops R with I<missing value where TRUE/FALSE needed>; here it is computed, ranking the C<NaN> those make last, as R's C<rank()> does.

=back

Everything else is checked against R's and SciPy's own test suites in C<t/wilcox_test.R.scipy.t>.

=head2 write_table

mimics R's C<write.table>, with data as first argument to subroutine, and output file as second

 write_table(\@data_aoh, $tmp_file, sep => "\t", 'row_names' => 1);

C<write_table> accepts every data-frame shape: a flat hash (one row), a hash of arrays (HoA), a hash of hashes (HoH), an array of hashes (AoH), and an array of arrays (AoA). For an AoA the first inner array is taken as the header row unless C<col_names> is given, in which case every inner array is treated as data:

 write_table([[qw(gene score)], ['TP53', 0.9], ['BRCA1', 0.7]], $tmp_file, 'row_names' => 0);
 write_table([['TP53', 0.9], ['BRCA1', 0.7]], $tmp_file, 'col_names' => [qw(gene score)]);

A data row longer than the header is not cut short: the header is widened with empty cells over the extra columns, the shape pandas gives C<DataFrame([[1, 2], [4, 5, 6]])>, and C<write_table> warns, naming the first long row.

You can also precisely filter and reorder which columns are written by passing an array reference to C<col_names>:

 write_table(\@data, $tmp_file, sep => "\t", 'col_names' => ['c', 'a']);

undefined values are written as empty fields by default, but can be set as you wish using C<undef_val>

 write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef_val' => 'nan')

A hash of hashes keeps its outer keys as a leading column by default, since that is the only place they exist. Name that column with C<row_names>, or drop it with C<< row_names =E<gt> 0 >>:

 my %taxa = (9606 => { species => 'Homo sapiens' }, 10090 => { species => 'Mus musculus' });
 write_table(\%taxa, 'taxa.tsv', 'row_names' => 'taxid');   # taxid  species

Leaving that column unnamed writes an empty first header cell, and every reader then has to invent a name for it (C<read_table> calls it C<row_name>, pandas C<Unnamed: 0>). C<write_table> therefore warns and suggests C<row_names>. It also warns when any data column has an empty name, whatever the shape. The empty label cell that C<< row_names =E<gt> 1 >> writes for the other shapes is R's own layout, and nothing can name it, so that one is not warned about.

For a hash of arrays or an array of hashes, C<< row_names =E<gt> 'col' >> takes the labels from column C<col> and heads the label column C<col>, as pandas heads an index with its name:

 write_table(\%hoa, 'out.csv', 'row_names' => 'gene');   # gene,score / TP53,0.9 / ...

A hash of arrays without a column C<col> is an error. An array of hashes may lack it in some rows: those rows are labelled with C<undef_val>, and one warning gives their count.

An array of arrays and a flat hash have no named column to take labels from, so for them C<< row_names =E<gt> 'name' >> heads their C<1..n> label column C<name>, as it heads a HoH's key column. As for a HoH, a name that is already a column's is an error.

A hash of arrays has as many rows as the longest of the arrays it writes; an array that C<col_names> leaves out does not add rows.

An empty C<{}> or C<[]> is a table with no rows, and is written as one: the header C<col_names> and C<row_names> give, if any, and otherwise a single empty record. C<< write_table([], 'out.csv', 'col_names' =E<gt> ['A'], 'row_names' =E<gt> 1) >> writes C<,A>, as pandas writes C<DataFrame({"A": []}).to_csv()>.

Every cell of delimited output is written whole, including one holding a NUL byte, and a cell of a tied hash or array (such as C<Tie::IxHash>) is read through its C<FETCH>. A number is formatted the way perl formats it, but in a copy, so writing a table does not add a string buffer to every numeric scalar in it. Nor does finding an AoH's or a HoH's columns leave an iterator on every row hash, as walking them with C<keys> would. A row that is a restricted hash (C<Hash::Util::lock_keys>) may lack some of the columns; those cells are written empty, where they used to die with I<Attempt to access disallowed key>.

A field is quoted when it holds a quote (which is doubled), a line break or the separator, as Python's C<csv.writer> quotes, and in two more places where C<read_table> would otherwise not see the record at all. A record of a single field that is empty, C<undef> or nothing but spaces and tabs is written quoted, C<""> or C<"  ">, because a blank line is skipped on reading; C<csv.writer> writes C<['']> and C<[None]> the same way. The first field of a record is quoted when it starts with C<#>, C<read_table>'s default comment character.

A reference anywhere in the table is an error, in a header cell (C<col_names>, or an AoA's first row) as in a data cell. For an AoA, an C<undef> in C<col_names> is an empty header cell in its place, since an AoA's columns are positional; for every other shape, which looks its columns up by name, it is skipped.

C<write_table> determines comma and tab-separated delimiters from the filename, but will override if C<sep> or C<delim> are explicitly set. A separator may be more than one character, but not empty, and may not contain a NUL, a quote, a CR or a LF: a file written with one of those could not be split into its fields again. A file name containing a NUL is an error too, as it is to perl's C<open>.
Args can also be accepted:

 write_table( 'data' => \%flat, 'file' => $f );

=head3 compressed files (C<.gz>, C<.bz2>)

A file name ending in C<.gz> is written gzip-compressed, and one ending in
C<.bz2> bzip2-compressed:

 write_table(\@rows, 'cohort.tsv.gz');     # tab-separated, then gzipped
 write_table(\@rows, 'cohort.csv.bz2');

=over

=item * B<The rest of the name means what it always did>: the default C<sep>
comes from the part before the suffix, so C<cohort.tsv.gz> is
tab-separated. The text inside is exactly what the plain file would
hold.

=item * B<It is streamed>, compressed as the rows are written, at gzip's and
bzip2's default levels (6 and 9, as R's C<gzfile> and C<bzfile> use).
A gzip file's header carries no name or time, so the same table always
makes the same bytes.

=item * B<A write that fails partway leaves a truncated file>, which
L<C<read_table>|/"read_table"> refuses, never one that looks whole. A
compressed write also croaks if the file cannot be finished.

=item * B<Only delimited text is compressed.> A name such as C<table.tex.gz> or
C<book.xlsx.bz2>, or C<tex>/C<xlsx> with a compressed name, is an error.

=item * Both use core modules only. A C<.bgz> name is an error: it promises
bgzip's BGZF, which tabix can index and plain gzip is not. Write C<.gz>,
and run C<bgzip> on the plain file if you need BGZF.

=back

=head3 The confirmation line

Every successful write prints one line to standard output naming the file, with the name in black on cyan:

 wrote output.tsv

This is C<say 'wrote ' . colored(['black on_cyan'], $file)>, but the SGR codes (C<\e[30;46m> … C<\e[0m>) are written out inline, so the module takes no dependency on C<Term::ANSIColor>. Every format announces itself the same way — delimited, LaTeX and C<.xlsx> alike — so you always learn where a table went, in the same shape whatever you asked for. Nothing is printed when nothing is written: a write that cannot open its file, or that loses data on the way to it, croaks instead. That includes a full disk, which a buffered write only discovers at the close; every format checks for it, as R's C<write.table> does. The message gives the system's reason, so a full disk reads C<write_table: could not finish writing 'out.csv': No space left on device>, and a quota or an I/O error says so instead; C<$!> is left set to it. A file that cannot be opened gives its reason the same way (C<Permission denied>, C<No such file or directory>). An empty data frame is written, and so announced.

The colour is unconditional; it is not suppressed when standard output is a pipe or a file. Pass C<< quiet =E<gt> 1 >> to suppress the line altogether, which is what a script writing to a pipe or a data file usually wants:

 write_table(\@rows, 'out.tsv', quiet => 1);   # writes the file, says nothing

C<quiet> silences the line rather than decolouring it, because the coloured form is the one contract every format shares. If you want the line but not the escapes, strip them (C<s/\e\[[\d;]*m//g>) or send them somewhere else. Note also that the line goes to file descriptor 1 directly rather than through Perl's C<STDOUT> glob, so C<< local *STDOUT; open STDOUT, 'E<gt>', \my $buf >> will B<not> capture it — redirect the file descriptor, or run the write in a child process, if you need to.

=head3 LaTeX output (C<tex>)

C<write_table> can write the output file as a LaTeX C<tabular> instead of a delimited table. This is selected either by naming the file C<*.tex> (auto-detected) or by passing C<< tex =E<gt> 1 >>; an explicit C<< tex =E<gt> 0 >> forces a delimited file even when the name ends in C<.tex>. The LaTeX table is built from the same rows as the delimited writer, so it works for every shape above (including arrays of arrays):

 write_table(\@data_aoh, 'table.tex');            # .tex name selects LaTeX
 write_table(\@data_aoh, $tmp_file, 'tex' => 1);  # force LaTeX for any name

The file begins with a C<< %written by E<lt>cwdE<gt>/E<lt>scriptE<gt> >> provenance comment (the working directory and script name). The header row is bold and the table is ruled with C<\hline>. As with every other format, C<row_names> is B<off> unless you ask for it, except for a HoH: pass C<< row_names =E<gt> 1 >> to prepend a label column of 1-based indices. A HoH writes its outer keys as that column by default, and C<< row_names =E<gt> 0 >> drops them. Cell text is LaTeX-escaped: C<#>, C<_>, C<%>, and C<&> are backslash-escaped, C<< E<lt> >> and C<< E<gt> >> become C<\textless{}> and C<\textgreater{}> (in LaTeX's default font encoding a bare C<< E<lt> >> prints as C<¡>; inside C<$...$> the two macros still print, with a LaTeX warning), and a cell consisting solely of C<\includesvg{...svg}> is passed through untouched. The other LaTeX specials — C<\>, C<$>, C<{>, C<}>, C<^> and C<~> — are left alone on purpose, so that a cell can hold LaTeX of its own: inline math such as C<$p^2$>, or a macro such as C<\textit{x}>. A cell that means one of them literally writes it escaped (C<\$>, C<\{>, C<\textasciicircum{}>). A table with no columns at all is an error, since LaTeX rejects one, and it is refused before the file is opened. The C<tex_*> options tune the output:

 write_table(\@rows, 'table.tex',
     'tex_col_align'    => 'l',                   # 'c' (default), 'l', or 'r'
     'tex_bold_1st_col' => 0,                     # default 1: bold the first column
     'tex_format'       => 1,                     # %.4g-format numeric cells
     'tex_size'         => '\small',              # size directive after \begin{tabular}
     'tex_comment'      => ['run 3', 'q < 0.05'], # % comment line(s): string or array ref
 );

For a table that must span page breaks, C<< tex_longtable =E<gt> 1 >> writes only the table I<body> — the bold header row and the data rows, ruled with C<\hline> — but no C<\begin{tabular}>/C<\end{tabular}> and no column spec, so you can C<\input{}> it into a C<longtable> environment you write yourself. Setting C<tex_longtable> implies C<< tex =E<gt> 1 >>, so it applies to any file name (and overrides C<< tex =E<gt> 0 >>). After the provenance comment (and any C<tex_comment> lines) the file emits a C<% \begin{longtable}{...}> hint with one C<tex_col_align> character per column, so you can copy a column spec with the right count. In this mode C<tex_col_align> affects only that hint — the real alignment lives on your own C<\begin{longtable}>; the other C<tex_*> options (C<tex_bold_1st_col>, C<tex_format>, C<tex_size>, C<tex_comment>) still apply:

 write_table(\@rows, 'output.file.tex', 'tex_longtable' => 1);

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

In that plain form the header is an ordinary first row, which is I<not> the header LaTeX freezes at the top of each page: a C<longtable> repeats only what sits inside C<\endfirsthead> / C<\endhead>. Hand-writing those blocks means retyping the column labels, and they then silently stop matching C<col_names> the first time the column order changes — the frozen header says one thing while the columns underneath say another, and the generated header shows up a second time as the first body row. C<tex_longtable_head> closes that gap by generating the repeat machinery from the same header record as the body:

 write_table(\@rows, 'output.file.tex',
     'col_names'          => ['a', 'b', 'c'],
     'tex_longtable_head' => '(continued)', # or just 1 for no continuation caption
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

Setting C<tex_longtable_head> implies C<tex_longtable> (and so C<< tex =E<gt> 1 >>). A true-but-numeric value emits the machinery with no continuation caption; any other true value is the caption text for every page after the first, written verbatim so LaTeX macros survive, with an empty C<\caption[]> optional argument so the continuation stays out of the List of Tables. C<\endfoot> carries the closing C<\hline> and no C<\endlastfoot> is emitted, so every page — the last one included — gets a bottom rule. The wrapper then holds nothing that has to track the data:

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

A number is written as a number cell, and every other non-empty cell as an
inline string (C<undef>/empty cells are omitted). A value perl holds as a number
is a number cell, unless it is infinite or C<NaN>, which are written as text. A
string is a number cell only when Excel would show it as it stands: a plain
decimal (an optional C<->, digits with at most one C<.>, an optional exponent),
with no leading zeros but the one in C<0> or C<0.5>, at most 15 significant
digits, and a magnitude Excel holds (up to C<9.99999999999999E+307>). So C<007>,
C<+5> and a 20-digit accession number stay text, where Excel used to show them
as C<7>, C<5> and C<1.23457E+19>; pandas likewise writes a C<str> as a string. The
result reads straight back with L<C<read_table>|/"read_table">.

XML 1.0 cannot hold a NUL, most other control characters, the noncharacters
U+FFFE and U+FFFF, or a surrogate, and a workbook holding one is refused by its
readers. In a cell each is written as Excel's own escape, C<_xHHHH_> (C<\r> is
C<_x000D_>), which Excel and LibreOffice turn back into the character, as
XlsxWriter does. A literal C<_x0041_> in a cell is written C<_x005F_x0041_> so
that it is not mistaken for one, and so is every other underscore that would
open an escape, overlapping ones included, so that a reader decoding left to
right gets back exactly the text written.
In the sheet name and C<xlsx_comment> such characters are dropped. A code point
above U+10FFFF, which no Unicode encoding has, is an error.

Excel's limits are enforced rather than written past: a worksheet holds 1048576
rows (header included) and 16384 columns, and a cell 32767 characters, the
checks XlsxWriter and pandas (I<This sheet is too large!>) make. A table that is
too long is refused before the file is opened, except a hash of arrays, whose
length is only known as its rows are written.

The worksheet is streamed to the file as the rows are formatted, so writing a
workbook takes little memory beyond the data itself: a 200000 x 20 array of
hashes needs 30 MB for a 308 MB workbook, where it used to need 1.1 GB. Like
delimited output, a write that croaks partway (a nested reference in a late row,
say) leaves a truncated file behind. A file that cannot seek, such as a pipe,
still works; its worksheet is gathered in memory first. A workbook larger than
4 GB, the most a ZIP archive holds without ZIP64, is refused.

Mirroring C<Excel::Writer::XLSX>'s
C<< $workbook-E<gt>set_properties(comments =E<gt> comments()) >>, the same
C<< written by E<lt>cwdE<gt>/E<lt>scriptE<gt> >> provenance line the LaTeX writer emits is stored in
the workbook's document B<comments> property (C<dc:description> in
C<docProps/core.xml>); a C<xlsx_comment> string (or array ref of strings) is
appended after it. C<xlsx_sheet> sets the worksheet name (default C<Sheet1>). As
in openpyxl, a name that is empty or holds any of C<\ * ? : / [ ]> is an error, and
one longer than 31 characters draws a warning, since Excel cannot read it:

 write_table(\@rows, 'report.xlsx',
     'xlsx_sheet'   => 'Results',
     'xlsx_comment' => 'batch 9',
 );

C<xlsx_freeze_rows> and C<xlsx_freeze_cols> freeze that many leading rows/columns in place (Excel's I<freeze panes>), so they stay visible while scrolling — most often used to pin the header row. They go up to 1048575 and 16383, one short of the sheet's limits:

 write_table(\@rows, 'report.xlsx', 'xlsx_freeze_rows' => 1);                        # pin the header row
 write_table(\@rows, 'report.xlsx', 'xlsx_freeze_rows' => 1, 'xlsx_freeze_cols' => 2); # pin header + first two columns

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
  <td>field separator; the two are aliases. Not empty, and no NUL, quote, CR or LF</td>
</tr>
<tr>
  <td><code>row_names</code></td>
  <td><code>0</code> (off); <code>1</code> (on) for a HoH</td>
  <td>both</td>
  <td>true prepends a label column (numeric 1-based index, or the outer key for a HoH); <code>0</code> omits it. Off by default in <b>every</b> format — delimited, LaTeX and <code>.xlsx</code> alike — for every shape but a HoH. (R's <code>write.table</code> defaults it on and this once followed suit for LaTeX; it no longer does.) A HoH defaults it on, because its outer keys are the row identifiers and exist nowhere else. For a HoA/AoH a non-numeric <i>column name</i> uses that column's values as the labels and drops it from the body; a HoA without that column dies, and AoH rows without it are labelled <code>undef_val</code>, with a warning. For a HoH, an AoA or a flat hash a non-numeric string <i>names</i> the label column (the outer keys, or <code>1..n</code>), so <code>row_names =&gt; 'taxid'</code> heads it <code>taxid</code> instead of leaving the header cell empty; it dies if that name is also a column being written. A reference dies</td>
</tr>
<tr>
  <td><code>col_names</code></td>
  <td>all columns, sorted</td>
  <td>both</td>
  <td>array ref selecting and ordering columns; for an AoA it also supplies the column names</td>
</tr>
<tr>
  <td><code>undef_val</code></td>
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
  <td><code>tex_col_align</code></td>
  <td><code>'c'</code></td>
  <td>LaTeX</td>
  <td>per-column alignment: <code>'c'</code>, <code>'l'</code>, or <code>'r'</code>; with <code>tex_longtable</code> on it sets only the <code>% \begin{longtable}{...}</code> hint</td>
</tr>
<tr>
  <td><code>tex_bold_1st_col</code></td>
  <td><code>1</code> (on)</td>
  <td>LaTeX</td>
  <td>bold the first column of each data row</td>
</tr>
<tr>
  <td><code>tex_format</code></td>
  <td><code>0</code> (off)</td>
  <td>LaTeX</td>
  <td>render numeric cells with <code>%.4g</code></td>
</tr>
<tr>
  <td><code>tex_size</code></td>
  <td><i>(none)</i></td>
  <td>LaTeX</td>
  <td>size directive emitted after <code>\begin{tabular}</code>, e.g. <code>\small</code></td>
</tr>
<tr>
  <td><code>tex_comment</code></td>
  <td><i>(none)</i></td>
  <td>LaTeX</td>
  <td><code>%</code> comment line(s) at the top of the LaTeX file: a string (an object is stringified), or an array ref of strings. Every line of each is a comment: a line break inside one opens a new <code>% </code> line</td>
</tr>
<tr>
  <td><code>tex_longtable</code></td>
  <td><code>0</code> (off)</td>
  <td>LaTeX</td>
  <td>write only the table body (header + data rows + <code>\hline</code>, no <code>\begin{tabular}</code>/<code>\end{tabular}</code> or column spec) for <code>\input{}</code> into a caller-supplied <code>longtable</code>; implies <code>tex =&gt; 1</code>, and emits a <code>% \begin{longtable}{...}</code> hint with one <code>tex_col_align</code> char per column</td>
</tr>
<tr>
  <td><code>tex_longtable_head</code></td>
  <td><code>0</code> (off)</td>
  <td>LaTeX</td>
  <td>generate <code>longtable</code>'s repeat-header machinery (<code>\endfirsthead</code> / <code>\endhead</code> / <code>\endfoot</code>) from the table's own header, so the header frozen at every page break tracks <code>col_names</code> instead of being hand-written; a non-numeric value is the continuation caption. Implies <code>tex_longtable</code>. Put the first page's top rule on your own <code>\caption</code> line (<code>\\ \hline</code>) — a leading <code>\hline</code> in an <code>\input</code>ed file is a <code>Misplaced \noalign</code> error</td>
</tr>
<tr>
  <td><code>xlsx</code></td>
  <td>auto: <code>1</code> when <code>file</code> ends in <code>.xlsx</code>, else <code>0</code></td>
  <td>Excel</td>
  <td>write a real <code>.xlsx</code> workbook (dependency-free, built in XS) instead of a delimited table; <code>xlsx =&gt; 0</code> forces delimited even for a <code>.xlsx</code> name. Mutually exclusive with <code>tex</code></td>
</tr>
<tr>
  <td><code>xlsx_sheet</code></td>
  <td><code>'Sheet1'</code></td>
  <td>Excel</td>
  <td>worksheet name</td>
</tr>
<tr>
  <td><code>xlsx_comment</code></td>
  <td><i>(none)</i></td>
  <td>Excel</td>
  <td>extra line(s) appended after the provenance in the workbook's document <i>comments</i> property (<code>dc:description</code>): a string (an object is stringified), or an array ref of strings</td>
</tr>
<tr>
  <td><code>xlsx_freeze_rows</code></td>
  <td><code>0</code> (none)</td>
  <td>Excel</td>
  <td>number of leading rows to freeze in place (freeze panes), e.g. <code>1</code> to pin the header row; at most 1048575</td>
</tr>
<tr>
  <td><code>xlsx_freeze_cols</code></td>
  <td><code>0</code> (none)</td>
  <td>Excel</td>
  <td>number of leading columns to freeze in place (freeze panes); at most 16383</td>
</tr>
</tbody>
</table>

=head1 Numerical accuracy

=head2 zerotrunc

A count regression truncated at zero, C<countreg::zerotrunc()>: the model for a
count that is only observed when it is at least 1, such as length of stay among
those admitted. Fitting an ordinary Poisson or negative binomial to such data
underestimates the mean at low counts, because it expects zeros that can never
be seen.

 use Stats::LikeR 'zerotrunc';

 my $z = zerotrunc(formula => 'days ~ hours + age', data => \%admitted,
                   dist => 'negbin');
 printf "theta = %.3f\n", $z->{theta};

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
  <td><code>formula</code></td>
  <td><i>(required)</i></td>
  <td>Formula as for [<code>glm</code>](#glm), with <code>offset()</code> terms allowed.</td>
</tr>
<tr>
  <td><code>data</code></td>
  <td><i>(required)</i></td>
  <td>HoA, AoH or HoH. The response must be positive integers.</td>
</tr>
<tr>
  <td><code>dist</code></td>
  <td><code>'poisson'</code></td>
  <td><code>'poisson'</code>, <code>'negbin'</code> or <code>'geometric'</code>.</td>
</tr>
<tr>
  <td><code>theta</code></td>
  <td><i>estimated</i></td>
  <td>For <code>negbin</code>, a fixed dispersion instead of an estimated one, as <code>countreg</code>'s <code>theta = </code>.</td>
</tr>
<tr>
  <td><code>offset</code></td>
  <td><i>none</i></td>
  <td>A column, an expression, or an array ref.</td>
</tr>
<tr>
  <td><code>weights</code></td>
  <td><i>none</i></td>
  <td>Case weights.</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td><code>0.95</code></td>
  <td>Level of the Wald intervals in <code>summary</code>.</td>
</tr>
</tbody>
</table>

The result holds C<coefficients>, C<summary> (per term C<Estimate>, C<Std. Error>,
C<z value>, C<< Pr(E<gt>|z|) >>, C<CI_lower>, C<CI_upper>), C<vcov>, C<terms>, C<loglik>,
C<aic>, C<df_residual>, C<df_null>, C<nobs>, C<converged> and C<iter>; C<theta> and
C<SE_logtheta> for C<negbin>, as C<countreg> reports them; C<fitted_values>, the
truncated mean C<mu / (1 - f(0))>, and Pearson-style C<residuals>. The fit is a
damped Newton iteration on the exact likelihood and its analytic Hessian.
Validated against C<countreg> and against C<mpmath> at 60 digits.

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

=item * B<F tests> (C<oneway_test>, C<aov>, C<anova> in both its forms, C<lm>'s
C<f_pvalue>, and C<var_test>) use the regularized-incomplete-beta symmetry
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
C<f_pvalue = 7.0165242049e-220> where the subtractive form returned C<0>, and
C<anova>'s sequential table reports C<1.1543232446e-171> for the same reason.
Where the true value underflows a double even when computed correctly — a Wald
z beyond about 38.5 — the result is C<0>, and R and SciPy return C<0> there too.

Verified against R 4.6.1 (C<oneway.test>, C<anova(aov())>, C<anova(lm())>,
C<summary(lm())$fstatistic>, C<summary(glm())$coefficients>) and against SciPy's
C<f.sf> / C<norm.sf> and statsmodels' C<anova_oneway>; see
C<t/model_pvalue_tails.t> and C<t/oneway_test.R.scipy.t>.

=head1 COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself

=head1 Thanks

A lot of this work used Claude AI, which was paid for by the University of Idaho's IMCI

=head1 AUTHOR

David E. Condon <dec986@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026-present by David E. Condon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
