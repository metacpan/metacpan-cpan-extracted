package SQL::Preproc;

use Text::Balanced ':ALL';

use vars qw($VERSION $PRINT $SYNTAX $SUBCLASS $KEEP $DEBUG $ALIAS $PREPROC_ONLY $RELAXED);
our $VERSION = '0.10';

use strict;
#
#	parser for SQL::Preproc
#
our %keyword_map = (
'BEGIN', [ 'BEGIN\s+WORK\b', \&sqlpp_begin_work ],
'CALL',  [ 'CALL\s+\w+(\s*\()?', \&sqlpp_call ],
'CLOSE', [ 'CLOSE\s+', \&sqlpp_close_cursor ],
'COMMIT', [ 'COMMIT(\s+WORK)?', \&sqlpp_commit_work ],
'CONNECT', [ 'CONNECT\s+TO\s+', \&sqlpp_connect ],
'DECLARE', [ 'DECLARE\s+(CURSOR|CONTEXT)\s+', \&sqlpp_declare ],
'DESCRIBE', [ 'DESCRIBE\s+', \&sqlpp_describe ],
'DISCONNECT', [ 'DISCONNECT\b', \&sqlpp_disconnect ],
'EXEC',  [ 'EXEC\s+', \&sqlpp_execute ],
'EXECIMM',  [ undef, \&sqlpp_exec_immediate ],
'EXECSQL',  [ undef, \&sqlpp_exec_sql ],
'EXECUTE', [ 'EXECUTE\s+', \&sqlpp_execute ],
'FETCH',  [ 'FETCH\s+', \&sqlpp_fetch_cursor ],
'OPEN',  [ 'OPEN\s+', \&sqlpp_open_cursor ],
'PREPARE', [ 'PREPARE\s+', \&sqlpp_prepare ],
'ROLLBACK', [ 'ROLLBACK(\s+WORK)?', \&sqlpp_rollback_work ],
'SET',  [ 'SET\s+CONNECTION\s+', \&sqlpp_set_connection ],
'WHENEVER', [ 'WHENEVER\s+(SQLERROR|NOT\s+FOUND)\s+', \&sqlpp_whenever ],
'RAISE', [ 'RAISE\s+(SQLERROR|NOT\s+FOUND)\s+', \&sqlpp_raise ],
'}',		[ undef, \&sqlpp_end_handler ],
'SELECT', [ 'SELECT\b', \&sqlpp_select ],
#'USING', [ { default => \&sqlpp_using }, \&sqlpp_using ],
#
#	keywords for std SQL stmts
#
'ALTER', [ 'ALTER\s+\w+\s+', \&sqlpp_exec_sql ],
'CREATE', [ 'CREATE\s+\w+\s+', \&sqlpp_exec_sql ],
'DELETE', [ 'DELETE\s+', \&sqlpp_exec_sql ],
'DROP',  [ 'DROP\s+\w+\s+', \&sqlpp_exec_sql ],
'GRANT', [ 'GRANT\s+\w+\s+', \&sqlpp_exec_sql ],
'INSERT', [ 'INSERT\s+', \&sqlpp_exec_sql ],
'REPLACE',	[ 'REPLACE\s+\w+\s+', \&sqlpp_exec_sql ],
'REVOKE', [ 'REVOKE\s+\w+\s+', \&sqlpp_exec_sql ],
'UPDATE', [ 'UPDATE\s+', \&sqlpp_exec_sql ],
);

use constant SQLPP_START => 0;
use constant SQLPP_LEN => 1;
use constant SQLPP_LINE => 2;
use constant SQLPP_KEY => 3;
use constant SQLPP_HANDLER => 4;
use constant SQLPP_TRUEPOS => 5;
use constant SQLPP_TRUELEN => 6;
use constant SQLPP_ATTRS => 7;

use DBI qw(:sql_types);

our %type_map = (
'BINARY', SQL_BINARY,
'BIT', SQL_BIT,
'BLOB', SQL_BLOB,
'BLOB LOCATOR', SQL_BLOB_LOCATOR,
'BOOLEAN', SQL_BOOLEAN,
'CHAR', SQL_CHAR,
'CLOB', SQL_CLOB,
'CLOB LOCATOR', SQL_CLOB_LOCATOR,
'DATE', SQL_DATE,
'DATETIME', SQL_DATETIME,
'DECIMAL', SQL_DECIMAL,
'DOUBLE', SQL_DOUBLE,
'DOUBLE PRECISION', SQL_DOUBLE,
'FLOAT', SQL_FLOAT,
'GUID', SQL_GUID,
'INTEGER', SQL_INTEGER,
'INT', SQL_INTEGER,
'INTERVAL', SQL_INTERVAL,
'INTERVAL DAY', SQL_INTERVAL_DAY,
'INTERVAL DAY TO HOUR', SQL_INTERVAL_DAY_TO_HOUR,
'INTERVAL DAY TO MINUTE', SQL_INTERVAL_DAY_TO_MINUTE,
'INTERVAL DAY TO SECOND', SQL_INTERVAL_DAY_TO_SECOND,
'INTERVAL HOUR', SQL_INTERVAL_HOUR,
'INTERVAL HOUR TO MINUTE', SQL_INTERVAL_HOUR_TO_MINUTE,
'INTERVAL HOUR TO SECOND', SQL_INTERVAL_HOUR_TO_SECOND,
'INTERVAL MINUTE', SQL_INTERVAL_MINUTE,
'INTERVAL MINUTE TO SECOND', SQL_INTERVAL_MINUTE_TO_SECOND,
'INTERVAL MONTH', SQL_INTERVAL_MONTH,
'INTERVAL SECOND', SQL_INTERVAL_SECOND,
'INTERVAL YEAR', SQL_INTERVAL_YEAR,
'INTERVAL YEAR TO MONTH', SQL_INTERVAL_YEAR_TO_MONTH,
'LONGVARBINARY', SQL_LONGVARBINARY,
'LONGVARCHAR', SQL_LONGVARCHAR,
'MULTISET', SQL_MULTISET,
'MULTISET LOCATOR', SQL_MULTISET_LOCATOR,
'NUMERIC', SQL_NUMERIC,
'REAL', SQL_REAL,
'REF', SQL_REF,
'ROW', SQL_ROW,
'SMALLINT', SQL_SMALLINT,
'TIME', SQL_TIME,
'TIMESTAMP', SQL_TIMESTAMP,
'TINYINT', SQL_TINYINT,
'TIMESTAMP WITH TIMEZONE', SQL_TYPE_TIMESTAMP_WITH_TIMEZONE,
'TIME WITH TIMEZONE', SQL_TYPE_TIME_WITH_TIMEZONE,
'UDT', SQL_UDT,
'UDT LOCATOR', SQL_UDT_LOCATOR,
'UNKNOWN TYPE', SQL_UNKNOWN_TYPE,
'VARBINARY', SQL_VARBINARY,
'VARCHAR', SQL_VARCHAR,
'WCHAR', SQL_WCHAR,
'WLONGVARCHAR', SQL_WLONGVARCHAR,
'WVARCHAR', SQL_WVARCHAR,
);

#
#	check config flags
#
sub import {
    my ($package, %cfg) = @_;
    if (exists $cfg{emit}) {
   		if (!defined($cfg{emit}) || ($cfg{emit}=~/^\d+$/)) {
    		$PRINT = defined($cfg{emit}) ? \*STDOUT : undef;
    	}
    	elsif ($cfg{emit}=~/^STDOUT$/) {
    		$PRINT = \*STDOUT;
    	}
    	elsif ($cfg{emit}=~/^STDERR$/) {
    		$PRINT = \*STDERR;
    	}
    	else {
    		$PRINT = undef,
    		warn "[SQL::Preproc] Unable to emit to $cfg{emit}: $!\n"
    			unless open($PRINT, ">$cfg{emit}");
    	}
   	}
    $KEEP = $cfg{keepsql};
    $SYNTAX = $cfg{syntax};
    $SUBCLASS = $cfg{subclass};
    $DEBUG = $cfg{debug};	# should make this a DBI trace level?
    $PREPROC_ONLY = $cfg{pponly};
    $RELAXED = $cfg{relax};
    $ALIAS = exists($cfg{alias}) ? $cfg{alias} : 1;
#
#	if syntax defined, then load/init its package
#
	foreach (@$SYNTAX) {
		eval "use SQL::Preproc::$_; 
			init SQL::Preproc::$_(\&sqlpp_install_syntax);";
		warn "Cannot load SQL::Preproc::$_: $@"
			if $@;
	}
	
	1;
}

use Filter::Simple;

#
#	get rid of pod and data
#
my $EOP = qr/\n\n|\Z/;
my $CUT = qr/\n=cut.*$EOP/;
my $pod_or_DATA = qr/
              ^=(?:head[1-4]|item) .*? $CUT
            | ^=pod .*? $CUT
            | ^=for .*? $EOP
            | ^=begin \s* (\S+) .*? \n=end \s* \1 .*? $EOP
            | ^__(DATA|END)__\r?\n.*
            /smx;
my @exlist = ();	# extract list
my $sqlpp_ctxt = '$sqlpp_ctxt';
my $exceptvar = 1;
my @markers = ();		# SQL statement position stack
my @nls = (0);
my $line = 0;
#
#	scan for
#	- comment
#	- variables
#	- bracketed sections
#	- heredocs
#	- quotelikes
#	- naked names
#	- candidate preceding terminators
#	- pod/DATA sections
#
#	if a comment, advance
#	if pod/DATA, advance
#	if a candidate terminator, set terminator flag and advance
#	if naked name
#		if a SQL keyword and terminator flag set
#			clear terminator flag
#			if parses as SQL
#				push start position on position stack
#				push SQL statement on SQL stack
#			else
#				advance past initial keyword
#			endif
#		else
#			advance past naked name
#		endif
#	endif
#	if variable, heredoc, quotelike, or bracketed,
#		clear terminator flag
#		extract item in list context
#		if (no match or (prefix ne ''))
#			advance to initial character + 1
#		endif
#	endif
#
#	create a newline map so we can try to map SQL stmts
#	to their line numbers
#
FILTER {
#
#	bug in old version of Filter::Simple causes filter
#	to be invoked a 2nd time with empty source string
#
return $_ unless ($_ && ($_ ne ''));

$DB::single = 1;	# so we can debug
@nls = (0);
$line = 0;
s/\r\n/\n/g;
@markers = ();		# SQL statement position stack
push @nls, $-[0]
	while /\n/gcs;
push @nls, length($_);
pos($_) = 0;
my ($terminated, $prefix, $start, $len);
my $lastpos = -1;
my $in_handler;
while (/\G\s*(.*?)((#.*?\n)|([\{\}:;])|([\$\%\@\(\['"\`])|(<<)|(\b([ysm]|q[rqxw]?|tr)\b)|([A-Z]+)|($pod_or_DATA))/gcs) {
	if (pos($_) eq $lastpos) {
		print "We didn't move!!! at $lastpos\n"
			if $DEBUG;
		last;
	}
	$lastpos = pos($_);
#
#	if anything nonwhitespace appears, clear terminator
#
	$prefix = $1;
	$terminated = undef
		if $prefix;

	if ($3) {
		print "Matched comment\n"
			if $DEBUG;
		next;
	}
#
#	treat pod and data like comments
#
	if ($10) {
		print "Matched pod/data\n"
			if $DEBUG;
		next;
	}
	
	if ($4) {
#
#	if in a handler, terminate it if end of code block
#
		if (defined($in_handler)) {
			$in_handler += ($4 eq '}') ? -1 : ($4 eq '{') ? 1 : 0;
#
#	push arrayref of (startposition, length, line number, keyword, handler)
#	on SQL detect stack
#
			unless ($in_handler) {
#
#	find its line
#
				$line++
					while (($line <= $#nls) && ($-[4] > $nls[$line]));
				push @markers, [ $-[4], 1, $line, '}', $keyword_map{'}'}[1], $-[4], 1, ];
				$in_handler = undef;
			}
		}
		$terminated = 1;
		print "Matched terminator\n"
			if $DEBUG;
		next;
	}

	my $initpos = $-[2];
#
#	clear terminator flag and backup for non-naked names
#
	pos($_) = $initpos,
	$terminated = undef
		unless $9;

	if ($7) {
		print "Matched quotelike\n"
			if $DEBUG;
		@exlist = extract_quotelike($_);
		pos($_) = $initpos+1,
		print "quotelike failed\n"
			unless (($exlist[0] ne '') && ($exlist[2] eq ''));
		next;
	}

	if ($6) {
		print "Matched heredoc\n"
			if $DEBUG;
#
#	Text::balanced 1.65 has a bug extracting heredocs
#	in list context, so we'll have to work around it
#	with scalar context by putting it back into $_
#	and advancing past it
#
#		@exlist = extract_quotelike($_);
#
#	NOTE: see Text::Balanced RE: potential mangling
#	of the input string for funny heredocs
#
		my $term = sqlpp_skip_heredoc(\$_);
		pos($_) = $initpos + 1
			unless $term;
		$terminated = 1 if ($term == 1);
#			unless (($exlist[0] ne '') && ($exlist[2] eq ''));
		next;
	}

	if ($5) {
		if (($5 eq '(') || ($5 eq '[')) {
			print "Matched paren\n"
				if $DEBUG;
			@exlist = extract_codeblock($_, '()[]');
			pos($_) = $initpos + 1,
			print "paren failed\n"
				unless (($exlist[0] ne '') && ($exlist[2] eq ''));
		}
		elsif (($5 eq '$') || ($5 eq '%') || ($5 eq '@')) {
			print "Matched variable\n"
				if $DEBUG;
			
			@exlist  = extract_variable($_);
			pos($_) = $initpos + 1,
			print "variable failed\n"
				unless (($exlist[0] ne '') && ($exlist[2] eq ''));
		}
		elsif (($5 eq '\'') || ($5 eq '"') || ($5 eq '`')) {
			print "Matched 2nd quotelike\n"
				if $DEBUG;

			@exlist = extract_quotelike($_);
			pos($_) = $initpos + 1,
			print "quotelike failed\n"
				unless (($exlist[0] ne '') && ($exlist[2] eq ''));
		}
		next;
	}
#
#	check for keyword
#
	if ($9) {
		$terminated = undef,
		next 
			unless ($terminated and $keyword_map{$9} and $keyword_map{$9}[0]);

		my $cmd = $9;
		my $after = $+[9];
		my $pattern = $keyword_map{$cmd}[0];
		next unless $pattern;	# for special keywords

print "Looks like a keyword: $cmd\n"
			if $DEBUG;
#
#	sidestep potential labels
#	note we keep the terminator flag set here,
#	since we end on a terminator
#
		next 
			if /\G\s*:\s+/gcs;
#
#	make sure it passes muster
#
		pos($_) = $initpos;
		unless (/\G$pattern/gcs) {;
			pos($_) = $after;
			next;
		}
		
		pos($_) = $initpos;
#
#	find its line
#
		$line++
			while (($line <= $#nls) && ($initpos > $nls[$line]));
#
#	push arrayref of (startposition, length, line number, 
#		keyword, handler, truestartpos, attrs)
#	on SQL detect stack
#
		my $attrs;
		my $truepos = $initpos;
		if (/\GEXEC\s+SQL\s+/gcs) {
#
#	scan for and extract braceblock
#
			$cmd = 'EXECSQL';
			if (/\G(\{)/gcs) {
				pos($_) = $-[1];
				@exlist = extract_codeblock($_,'{}');
				$terminated = undef,
				pos($_) = $after,
				print "[SQL::Preproc] EXEC SQL attrs extract failed\n" and
				next
					unless (($exlist[0] ne '') && ($exlist[2] eq ''));
				$attrs = $exlist[0];
				/\G\s*/gcs;	# skip intervening whitespace
			}
#
#	see if we have a matching keyword for it,
#	if so perform prelim pattern validation
#	NOTE: we still process it even if pattern doesn't
#	match
#
			$truepos = pos($_);
			if ((/\G\s*([A-Z]+)/gcsi) && ($keyword_map{uc $1})) {
				$cmd = uc $1;
				$pattern = $keyword_map{$cmd}[0];
				pos($_) = $truepos;
				$cmd = 'EXECSQL'
					unless /\G$pattern/gcsi;
			}
			pos($_) = $truepos;
#
#	fall thru for rest of scan
#
		}

		if (($cmd eq 'WHENEVER') && 
			/\GWHENEVER\s+(?:(SQLERROR|NOT\s+FOUND))\s+/gcs) {
#
#	fail if already in handler or no braceblock
#
			$terminated = undef,
			pos($_) = $after,
			print "[SQL::Preproc] WHENEVER extract failed\n" and
			next
				if (defined($in_handler) || (!/\G(\{)/gcs));
#
#	since the codeblock can have SQL in it, we can't just extract;
#	instead we need to set a handler flag, and loop thru until the end
#	of the code block
#
			$in_handler = 1;
			push @markers, [ $initpos, pos($_) - $initpos, $line, $cmd, 
				$keyword_map{$cmd}[1], $truepos, pos($_) - $truepos ];
			next;
		}
		elsif (/\GEXEC(UTE)?\s+IMMEDIATE\s+/gcs) {
#
#	scan for quotelikes, blocks, variables, up to semicolon
#	(we allow arbitrary expressions here, but no comments, pod, or DATA)
#
			$truepos = pos($_);
			while (/\G.*?(([;\$\%\@\(\[\{'"\`])|(<<)|(\b([ysm]|q[rqxw]?|tr)\b))/gcs) {
				pos($_) = $-[1];
				if ($2) { # special character
					if ($2 eq ';') {
					#terminator
						pos($_) = $+[1];
						push @markers, [ $initpos, pos($_) - $initpos, $line, 'EXECIMM', 
							$keyword_map{EXECIMM}[1], $truepos, pos($_) - $truepos, $attrs ];
						last;
					}
					elsif (($2 eq '$') || ($2 eq '@') || ($2 eq '%')){
					#skip over variable
						@exlist  = extract_variable($_);
						pos($_) = $after,
						print "variable failed\n" and
						last
							unless (($exlist[0] ne '') && ($exlist[2] eq ''));
					}
					elsif (($2 eq '(') || ($2 eq '[') || ($2 eq '{')){
					#skip bracketed block
						@exlist = extract_codeblock($_, '()[]{}');
						pos($_) = $after,
						print "bracketed block failed\n" and
						last
							unless (($exlist[0] ne '') && ($exlist[2] eq ''));
					}
					elsif (($2 eq '"') || ($2 eq '`') || ($2 eq "'")){
					#skip quotelikes
						@exlist = extract_quotelike($_);
						pos($_) = $after,
						print "quotelike failed\n" and
						last
							unless (($exlist[0] ne '') && ($exlist[2] eq ''));
					}
				}
				elsif ($3) {
#
#	Text::balanced 1.65 has a bug extracting heredocs
#	in list context, so we'll have to work around it
#	with scalar context by putting it back into $_
#	and advancing past it
#
#					@exlist = extract_quotelike($_);
#
#	NOTE: see Text::Balanced RE: potential mangling
#	of the input string for funny heredocs
#
					my $term = sqlpp_skip_heredoc(\$_);
					pos($_) = $after,
					print "heredoc failed\n" and
					last
						unless $term;
#
#	if stmt is terminated, handle like ';'
#
					if ($term == 1) {
						push @markers, [ $initpos, pos($_) - $initpos, $line, 'EXECIMM', 
							$keyword_map{EXECIMM}[1], $truepos, pos($_) - $truepos, $attrs ];
						last;
					}
#						unless (($exlist[0] ne '') && ($exlist[2] eq ''));
				}
				elsif ($4) {
					#skip quotelikes
					@exlist = extract_quotelike($_);
					pos($_) = $after,
					print "quotelike failed\n" and
					last
						unless (($exlist[0] ne '') && ($exlist[2] eq ''));
				}
			}
			next;
		}
		else {
#
#	scan for statement terminator, skipping over strings, variables,
#	and embedded braceblocks, up to semicolon
#
			$truepos = pos($_);
			while (/\G.*?([\(\[\{'"\$\@%;])/gcs) {
				if (($1 eq '(') || ($1 eq '[') || ($1 eq '{')) {
					pos($_) = $-[1];
					@exlist = 
						($1 eq '(') ? extract_bracketed($_, '("\')') :
						($1 eq '[') ? extract_bracketed($_, '["\']') :
							extract_bracketed($_, '{"\'}');
					pos($_) = $after,
					last
						unless (($exlist[0] ne '') && ($exlist[2] eq ''));
				}
				elsif (($1 eq '"') || ($1 eq "'")) {
					pos($_) = $-[1];
					@exlist = extract_quotelike($_);
					pos($_) = $after,
					last
						unless (($exlist[0] ne '') && ($exlist[2] eq ''));
				}
				elsif ($1 eq ';') {	# terminator
					push @markers, [ $initpos, pos($_) - $initpos, $line, $cmd, 
						$keyword_map{$cmd}[1], $truepos, pos($_) - $truepos, $attrs ];
					last;
				}
				else {	# variable cuz hash values may have strings in them
					pos($_) = $-[1];
					@exlist = extract_variable($_);
					pos($_) = $after,
					last
						unless (($exlist[0] ne '') && ($exlist[2] eq ''));
				}
			}	# end while scanning for stmt terminator
		}	# end if some SQL keyword
	}	# end if possible SQL
	else {
#
#	shouldn't get here!?!?!
#
print "A MATCH FAILED!!!\n"
	if $DEBUG;
		last;
	}
}	# end while scanning

#
#	now we can extract and replace SQL statements,
#	starting from the end and working backwards
#	so the in situ replacements don't goof up our
#	positions
#
my $src = $_;
my $offset = 0;
while (@markers) {
	my $stmt = shift @markers;

	print "\n!!!!! Got a long one\n"
		if ($$stmt[SQLPP_LEN] > 1500);

	print "
****
Got $$stmt[SQLPP_KEY] statement at line $$stmt[SQLPP_LINE]
($$stmt[SQLPP_START] len $$stmt[SQLPP_LEN])\n",
		substr($src, $$stmt[SQLPP_START], $$stmt[SQLPP_LEN]), "\n"
		if $DEBUG;
#
#	apply the SQL statement
#
	my $sql = substr($src, $offset + $$stmt[SQLPP_START], $$stmt[SQLPP_LEN]);
	my $str = '';
#
#	include the original SQL as comment
#
	$sql=~s/\n/\n#\t/gs,
	$str .= "\n#\n#\t$sql\n#\n"
		if $KEEP;
#
#	alias line number
#
	$str .= "\n#line $$stmt[SQLPP_LINE]\n"
		if $ALIAS;
#
#	now get just the interesting part
#
	$sql = substr($src, $offset + $$stmt[SQLPP_TRUEPOS], $$stmt[SQLPP_TRUELEN]);
	$sql=~s/\s*;$//;
#
#	extract strings and variables so we can freely parse
#	(except for EXECUTE IMMEDIATE, which could be an arbitrary expression)
#
	my @phs = ();
	my $ph = 0;
	my ($t, $pos, $m, $extract);
	unless ($$stmt[SQLPP_KEY] eq 'EXECIMM') {
		pos($sql) = 0;
		while ($sql=~/\G.*?(['"\$\@%])/gcs) {
			pos($sql) = $pos = $-[1];

			$extract =	(($1 eq '"') || ($1 eq '\'')) ?
				extract_quotelike($sql) : extract_variable($sql);
			$m = (($1 eq '"') || ($1 eq '\'')) ? "\0" : "\01";

			if ($extract ne '') {
				push(@phs, $extract);
				$t = "$m$ph$m";
				$ph++;
				substr($sql, $pos, 0) = $t;
				pos($sql) = $pos + length($t);
			}
			else {
				pos($sql) = $pos + 1;
			}
		}
	}
#
#	replace in source if it xlates
#
	my $attrs = $$stmt[SQLPP_ATTRS] ||= '';
	my $xlated = $$stmt[SQLPP_HANDLER]->($sql, $attrs, \@phs);
#
#	on parse failure, leave the original intact in the source stream
#
	next unless $xlated;
#
#	restore any placeholders
#
	$xlated=~s/[\0\01](\d+)[\0\01]/$phs[$1]/g
		if scalar @phs;	# EXEC IMM implicitly avoided here!

	substr($src, $offset + $$stmt[SQLPP_START], $$stmt[SQLPP_LEN]) = $str . $xlated;
	$offset += (length($str) + length($xlated) - $$stmt[SQLPP_LEN]);
}
	print $PRINT $src and
	close $PRINT
		if $src && ($src ne '') && $PRINT && ref $PRINT;
	$_ = $PREPROC_ONLY ? "# preproc only, no source returned\n" : $src;
	$_;
};

sub sqlpp_begin_work {
#
#	start a transaction
#
	return $RELAXED ?
"	${sqlpp_ctxt}->{current_dbh}{AutoCommit} = 0;
" :
"	unless (defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection\");
	}
	else {
		${sqlpp_ctxt}->{current_dbh}{AutoCommit} = 0;
	}
";
}

sub sqlpp_call {
	my ($src, $attrs, $phs) = @_;
#
#	need to properly marshall params for SPs
#	note we must extract placeholders of form ":\$+\w+"
#	and replace with '?' (may need to support others
#	in future
#
	return undef 
		unless ($src=~/^CALL\s+(\w+)(\s*\(.*\))?$/is);
	my $sp = $1;
	my $params = $2;
	my @inphs = ();
	my @outphs = ();
	if ($params) {
		@inphs = ($params=~/:\01(\d+)\01/gs);
		@outphs = ($params=~/:(\w+)/gs);
		$params=~s/:\01\d+\01/\?/g;
		$params=~s/:(\w+)/$1/g;
	}
	$src = $sp;
	$src .= $params if $params;
#
#	our default binding uses separate argument counters
#	for IN/INOUT and OUTs
#
	my $bindings = 
"	${sqlpp_ctxt}->{rc} = 1;
";
	my $close = '';
	if (scalar @inphs) {
#
#	xlate the phs back to their names
#
		$inphs[$_] = $$phs[$inphs[$_]]
			foreach (0..$#inphs);

		$bindings .= 
"		${sqlpp_ctxt}->{rc} =
			${sqlpp_ctxt}->{current_sth}->bind_param_inout($_, \\$inphs[$_-1])
				if ${sqlpp_ctxt}->{rc};
"
			foreach (1..scalar @inphs);
	}

	if (scalar @outphs) {
		$outphs[$_] = '\$' . $outphs[$_]
			foreach (0..$#outphs);
		$bindings .= 
"		${sqlpp_ctxt}->{rc} =
			${sqlpp_ctxt}->{current_sth}->bind_col($_, $outphs[$_-1])
				if ${sqlpp_ctxt}->{rc};
"
		foreach (1..scalar @outphs);
	}
	
	return $RELAXED ?
"	${sqlpp_ctxt}->{current_sth} = 
		${sqlpp_ctxt}->{current_dbh}->prepare(\"CALL $src\", $attrs);

	unless (defined(${sqlpp_ctxt}->{current_sth})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
	}
	else {
$bindings
	unless (${sqlpp_ctxt}->{rc}) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, ${sqlpp_ctxt}->{current_sth});
	}
	else {
		${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{current_sth}->execute();
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, ${sqlpp_ctxt}->{current_sth})
			unless defined(${sqlpp_ctxt}->{rows});
	}
	}
" :
"	unless (defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection\");
	}
	else {
		${sqlpp_ctxt}->{current_sth} = 
			${sqlpp_ctxt}->{current_dbh}->prepare(\"CALL $src\", $attrs);

		unless (defined(${sqlpp_ctxt}->{current_sth})) {
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
		}
		else {
$bindings
		unless (${sqlpp_ctxt}->{rc}) {
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_sth});
		}
		else {
			${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{current_sth}->execute();
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_sth})
				unless defined(${sqlpp_ctxt}->{rows});
		}
	}
	}
";
}

sub sqlpp_connect {
	my ($src, $attrs, $phs) = @_;

	my @args = ($src=~/^CONNECT\s+TO\s+(\w+|[\0\01]\d+[\0\01])(\s+USER\s+(\w+|[\0\01]\d+[\0\01])(\s+IDENTIFIED\s+BY\s+(\w+|[\0\01]\d+[\0\01]))?)?(\s+AS\s+(\w+|\01\d+\01))?(\s+WITH\s+\{(.*)\})?$/is);
	return undef
		unless defined($args[0]);
#
#	if its a string, we have to do runtime interpolation
#	we must assume its a complete string, not an expression
#
	$args[0] = '"' . $args[0] . '"'
		unless ($args[0]=~/^[\0\01]/);	

	$args[2] = defined($args[2]) ? ($args[2]=~/^[\0\01]/) ? $args[2] : "\"$args[2]\"" : "undef";
	$args[4] = defined($args[4]) ? ($args[4]=~/^[\0\01]/) ? $args[4] : "\"$args[4]\"" : "undef";
	$args[6] = defined($args[6]) ? ($args[6]=~/^[\0\01]/) ? $args[6] : "\"$args[6]\"" : "'default'";
	$args[8] = '' unless defined($args[8]);

	my $driver = $SUBCLASS ? "DBIx::$SUBCLASS" : 'DBI';
	return 
"	\$_ = $args[0];
	\$_ = 'dbi:' . \$_
		unless /^dbi:/;

	${sqlpp_ctxt}->{current_dbh} = ${sqlpp_ctxt}->{dbhs}{$args[6]} = 
		$driver->connect(\$_, $args[2], $args[4],
		{ PrintError => 0, RaiseError => 0, AutoCommit => 1, $args[8] });

	if (defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{curr_dbh_name} = $args[6];
	}
	else {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, \$DBI::err, \$DBI::state, \$DBI::errstr);
	}
";
}

sub sqlpp_close_cursor {
	my ($src, $attrs, $phs) = @_;
	my ($name) = ($src=~/^CLOSE\s+(\w+|\01]\d+\01)$/i);
	return undef unless $name;
#
#	close a cursor
#
	return 
"	if (! defined(${sqlpp_ctxt}->{cursors}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Unknown cursor $name\");
	}
	elsif (! defined(${sqlpp_ctxt}->{cursor_open}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Cursor $name not open.\");
	}
	else {
		${sqlpp_ctxt}->{cursors}{$name}->finish();
		delete ${sqlpp_ctxt}->{cursor_map}{$name};
		delete ${sqlpp_ctxt}->{cursor_open}{$name};
	}
";
}

sub sqlpp_commit_work {
#
#	commit any open xaction
#	NOTE: what is the disposition of any open cursors ???
#	we may need to force a behavior
#
	return $RELAXED ?
"	${sqlpp_ctxt}->{current_dbh}->commit();
	${sqlpp_ctxt}->{current_dbh}{AutoCommit} = 1;
" :
"	unless (defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\");
	}
	else {
		${sqlpp_ctxt}->{current_dbh}->commit();
		${sqlpp_ctxt}->{current_dbh}{AutoCommit} = 1;
	}
";
}

sub sqlpp_declare {
	my ($src, $attrs, $phs) = @_;
#
#	declare a cursor
#	note we must extract placeholders of form ":\$+\w+"
#	and replace with '?' (may need to support others
#	in future
#
#	print $src, "\n";

	return undef
		unless ($src=~/^DECLARE\s+(CURSOR\s+(\w+|\01\d+\01)\s+AS\s+(SELECT\b.+))|(CONTEXT\s+(\01(\d+)\01))$/is);

	if (defined($1)) {
#
#	cursor declaration:
#		extract PHs
#		prepare result
#		flag if FOR UPDATE
#		bind the PHs
#	NOTE: we don't support array binding for cursors, since cursor behavior
#	isn't well defined in that case
#
		my $name = $2;
		my $sql = $3;
		my @vars = ();
		push @vars, $$phs[$1]
			while ($sql=~/:\01(\d+)\01/gs);
		$sql=~s/\:\01\d+\01/\?/g;

		$sql = sqlpp_quote_it($sql, $phs);
		my $replaced = $RELAXED ?
"	${sqlpp_ctxt}->{cursors}{$name} = 
		${sqlpp_ctxt}->{current_dbh}->prepare($sql, $attrs);

	unless (defined(${sqlpp_ctxt}->{cursors}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
	}
	else {
		${sqlpp_ctxt}->{stmt_map}{$name} = ${sqlpp_ctxt}->{curr_dbh_name};
" :
"	unless (defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\");
	}
	else {
		${sqlpp_ctxt}->{cursors}{$name} = 
			${sqlpp_ctxt}->{current_dbh}->prepare($sql, $attrs);

		unless (defined(${sqlpp_ctxt}->{cursors}{$name})) {
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
		}
		else {
			${sqlpp_ctxt}->{stmt_map}{$name} = ${sqlpp_ctxt}->{curr_dbh_name};
";
#
#	create refs to the bind variables; then we'll deref when we bind
#	for execution
#
		if (scalar @vars) {
			$replaced .= 
"			${sqlpp_ctxt}->{cursor_phs}{$name} = [ \\" .
				join(', \\', @vars) . "];
";
		}
		$replaced .= $RELAXED ?
'	}
' :
'		}
	}
';
		return $replaced;
	}
#
#	create context variable
#	and install the default handlers
#
	$sqlpp_ctxt = $$phs[$6];
	return undef 
		unless (substr($sqlpp_ctxt, 0, 1) eq '$');
	return
"	$sqlpp_ctxt = { 
		sths => { },
		dbhs => { },
		current_dbh => undef,
		current_sth => undef,
		handler_idx => -1,
		SQLERROR => [ ],
		NOTFOUND => [ ],
	},
	SQL::Preproc::ExceptContainer->default_SQLERROR($sqlpp_ctxt),
	SQL::Preproc::ExceptContainer->default_NOTFOUND($sqlpp_ctxt)
		unless (defined($sqlpp_ctxt) && 
			(ref $sqlpp_ctxt) &&
			(ref $sqlpp_ctxt eq 'HASH'));
";
}

sub sqlpp_describe {
	my ($src, $attrs, $phs) = @_;
#
#	requires a prepared or a cursor statement
#	convert the arrayrefs of metadata into arrayref/array/hash of hashref
#	of { NAME, TYPE, PRECISION, SCALE }
#	if an INTO is provided, place in the scalar, else put in @_
#
	my ($name, $dmy, $var) = ($src=~/^DESCRIBE\s*(\w+|\01\d+\01)(\s+INTO\s+:\01(\d+)\01)?$/is);

	$var = $$phs[$var] if defined($var);

	return undef
		unless defined($name);

	my $xlated = 
"	unless (defined(${sqlpp_ctxt}->{cursors}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Undefined statement/cursor $name\");
	}
	else {
";

	unless ($var) {
#
#	missing our INTO, use @_
#
		$xlated .=
"		\@_ = ();
		push \@_, { 
			Name => ${sqlpp_ctxt}->{cursors}{$name}{NAME}[\$_],
			Type => ${sqlpp_ctxt}->{cursors}{$name}{TYPE}[\$_],
			Precision => ${sqlpp_ctxt}->{cursors}{$name}{PRECISION}[\$_],
			Scale => ${sqlpp_ctxt}->{cursors}{$name}{SCALE}[\$_]
			}
			foreach (0..\$#{${sqlpp_ctxt}->{cursors}{$name}{NAME}});
	}
";
		return $xlated;
	}

	$var = "\@$var" if (substr($var, 0, 1) eq '$');
	$xlated .= "\t$var = ();\n";
	$var=~s/^%/\$/;
	$xlated .= (substr($var, 0, 1) eq '$') ? 
"		$var\{${sqlpp_ctxt}->{cursors}{$name}{NAME}[\$_]\} = { 
			Type => ${sqlpp_ctxt}->{cursors}{$name}{TYPE}[\$_],
			Precision => ${sqlpp_ctxt}->{cursors}{$name}{PRECISION}[\$_],
			Scale => ${sqlpp_ctxt}->{cursors}{$name}{SCALE}[\$_]
		}
			foreach (0..\$#{${sqlpp_ctxt}->{cursors}{$name}{NAME}});
	}
" : 
"		push $var, { 
			Name => ${sqlpp_ctxt}->{cursors}{$name}{NAME}[\$_],
			Type => ${sqlpp_ctxt}->{cursors}{$name}{TYPE}[\$_],
			Precision => ${sqlpp_ctxt}->{cursors}{$name}{PRECISION}[\$_],
			Scale => ${sqlpp_ctxt}->{cursors}{$name}{SCALE}[\$_]
		}
			foreach (0..\$#{${sqlpp_ctxt}->{cursors}{$name}{NAME}});
	}
";
	return $xlated;
}

sub sqlpp_disconnect {
	my ($src, $attrs, $phs) = @_;
#
#	disconnect (optionally named) connection
#
	return undef
		unless ($src=~/^DISCONNECT(\s+(\w+|\01\d+\01))?$/is);
	my $name = $2;
	my $qname = '';
	$qname = (substr($name, 0, 1) eq "\01") ? $name : '"' . $name . '"'
		if $name;
#
#	we need to clean out any assoc. stmts/cursors
#
	return
"	if (${sqlpp_ctxt}->{current_dbh}) {
		${sqlpp_ctxt}->{current_dbh}->disconnect;
		foreach (keys \%{${sqlpp_ctxt}->{stmt_map}}) {
#
#	remove assoc. stmts/cursors
#
			delete ${sqlpp_ctxt}->{sths}{\$_},
			delete ${sqlpp_ctxt}->{stmt_map}{\$_},
			delete ${sqlpp_ctxt}->{stmt_phs}{\$_},
			delete ${sqlpp_ctxt}->{cursors}{\$_},
			delete ${sqlpp_ctxt}->{cursor_phs}{\$_}
				if (${sqlpp_ctxt}->{stmt_map}{\$_} eq ${sqlpp_ctxt}->{curr_dbh_name});
		}
		delete ${sqlpp_ctxt}->{dbhs}{${sqlpp_ctxt}->{curr_dbh_name}};
		delete ${sqlpp_ctxt}->{curr_dbh_name};
		delete ${sqlpp_ctxt}->{current_dbh};
	}
"
		unless $name;

	return $RELAXED ?
"	${sqlpp_ctxt}->{dbhs}{$name}->disconnect;
	${sqlpp_ctxt}->{current_dbh} = undef
		if (${sqlpp_ctxt}->{curr_dbh_name} eq $qname);
	delete ${sqlpp_ctxt}->{dbhs}{$name};
	foreach (keys %{${sqlpp_ctxt}->{stmt_map}}) {
#
#	remove assoc. stmts/cursors
#
		delete ${sqlpp_ctxt}->{sths}{\$_},
		delete ${sqlpp_ctxt}->{stmt_map}{\$_},
		delete ${sqlpp_ctxt}->{stmt_phs}{\$_},
		delete ${sqlpp_ctxt}->{cursors}{\$_},
		delete ${sqlpp_ctxt}->{cursor_phs}{\$_}
			if (${sqlpp_ctxt}->{stmt_map}{\$_} eq $qname);
	}
" :
"	unless (defined(${sqlpp_ctxt}->{dbhs}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Unknown connection $name\")
	}
	else {
		${sqlpp_ctxt}->{dbhs}{$name}->disconnect;
		${sqlpp_ctxt}->{current_dbh} = undef
			if (${sqlpp_ctxt}->{curr_dbh_name} eq $qname);
		delete ${sqlpp_ctxt}->{dbhs}{$name};
		foreach (keys \%{${sqlpp_ctxt}->{stmt_map}}) {
#
#	remove assoc. stmts/cursors
#
			delete ${sqlpp_ctxt}->{sths}{\$_},
			delete ${sqlpp_ctxt}->{stmt_map}{\$_},
			delete ${sqlpp_ctxt}->{stmt_phs}{\$_},
			delete ${sqlpp_ctxt}->{cursors}{\$_},
			delete ${sqlpp_ctxt}->{cursor_phs}{\$_}
				if (${sqlpp_ctxt}->{stmt_map}{\$_} eq $qname);
		}
	}
"
		unless (uc $name eq 'ALL');

	return
"	${sqlpp_ctxt}->{dbhs}{\$_}->disconnect,
	delete ${sqlpp_ctxt}->{dbhs}{\$_}
		foreach (keys \%{${sqlpp_ctxt}->{dbhs}});
	delete ${sqlpp_ctxt}->{current_dbh};
	${sqlpp_ctxt}->{sths} = {};
	${sqlpp_ctxt}->{stmt_map} = {};
	${sqlpp_ctxt}->{stmt_phs} = {};
	${sqlpp_ctxt}->{cursors} = {};
	${sqlpp_ctxt}->{cursor_phs} = {};
";
}
#
#	arbitrary sql:
#		scan for and replace placeholders
#		prepare
#		execute
#
sub sqlpp_exec_sql {
	my ($src, $attrs, $phs) = @_;
	
	my ($cursor) = ($src=~/\bWHERE\s+CURRENT\s+OF\s+(\w+|[\0\01]\d+[\0\01])$/is);
	my @vars = ();
	push @vars, $$phs[$1]
		while ($src=~/:\01(\d+)\01/gcs);
	$src=~s/:\01(\d+)\01/\?/g;
#
#	remove mapped cursor name; we'll append true name at runtime
#
	$src=~s/\b(WHERE\s+CURRENT\s+OF\s+).+$/$1/i;
#
#	type of binding and execution determined by type of variables used
#
	my ($execsub, $bindsub, $useref) = ('execute()', 'bind_param', '');
	($execsub, $bindsub, $useref) = ("execute_array({ ArrayTupleStatus => ${sqlpp_ctxt}->{tuple_status} })", 
		'bind_param_array', '\\')
		if (scalar @vars && (substr($vars[0], 0, 1) eq '@'));

	my $bindings =
"		${sqlpp_ctxt}->{rc} = 1;
";
	if (scalar @vars) {
		$bindings .=
"		${sqlpp_ctxt}->{rc} =
			${sqlpp_ctxt}->{current_sth}->$bindsub($_, ${useref}$vars[$_-1])
				if ${sqlpp_ctxt}->{rc};
"
		foreach (1..scalar @vars);

	}

	my $replaced = $RELAXED ? '' :
"	if (! defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\");
	}
";

	if (defined($cursor) && ($cursor ne '')) {
		$replaced .= ($RELAXED ? '	if' : '	elsif') .
" (! defined(${sqlpp_ctxt}->{cursors}{$cursor})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Unknown cursor $cursor.\");
	}
	elsif (! ${sqlpp_ctxt}->{cursor_open}{$cursor}) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Cursor $cursor not open.\");
	}
	elsif (${sqlpp_ctxt}->{stmt_map}{$cursor} ne ${sqlpp_ctxt}->{curr_dbh_name}) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Cursor $cursor not defined on current connection.\");
	}
	elsif (! ${sqlpp_ctxt}->{cursor_map}{$cursor}) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Cursor $cursor is readonly.\");
	}
";
	}
	else {
		$cursor = '';
	}

	$src = sqlpp_quote_it($src, $phs);
	$replaced .= 
"	else {
"
		unless ($RELAXED && ($cursor eq ''));
	$replaced .= ($cursor eq '') ?
"	${sqlpp_ctxt}->{tuple_status} = [];
	${sqlpp_ctxt}->{current_sth} = ${sqlpp_ctxt}->{current_dbh}->prepare($src, $attrs);
	if (${sqlpp_ctxt}->{current_sth}) {
$bindings
		unless (${sqlpp_ctxt}->{rc}) {
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
		}
		else {
			${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{current_sth}->$execsub;
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_sth})
				unless defined(${sqlpp_ctxt}->{rows});
		}
	}
	else {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
	}
" :
"		${sqlpp_ctxt}->{tuple_status} = [];
		${sqlpp_ctxt}->{current_sth} = ${sqlpp_ctxt}->{current_dbh}->prepare(
			$src . ${sqlpp_ctxt}->{cursor_map}{$cursor}, $attrs);
		if (${sqlpp_ctxt}->{current_sth}) {
$bindings
			unless (${sqlpp_ctxt}->{rc}) {
				${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
					$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
			}
			else {
				${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{current_sth}->$execsub;
				${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
					$sqlpp_ctxt, ${sqlpp_ctxt}->{current_sth})
					unless defined(${sqlpp_ctxt}->{rows});
			}
		}
		else {
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
		}
";
	$replaced .= 
"	}
"
		unless ($RELAXED && ($cursor eq ''));
	return $replaced;
}
#
#	execute immediate
#
sub sqlpp_exec_immediate {
	my ($src, $attrs, $phs) = @_;
#
# 	execute immediate: its an expression; just do() it
#	NOTE: no placeholders are supported,
#	and no data returning stmts either
#	note that we assign the expr to a variable in order
#	to support arbitrary expressions
#
	$exceptvar++;
	return $RELAXED ?
"	my \$__expr_$exceptvar = $src;
	${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
		$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh})
		unless defined(${sqlpp_ctxt}->{current_dbh}->do(\$__expr_$exceptvar, $attrs));
" :
"	unless (defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\");
	}
	else {
		my \$__expr_$exceptvar = $src;
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh})
			unless defined(${sqlpp_ctxt}->{current_dbh}->do(\$__expr_$exceptvar, $attrs));
	}
"
}
#
#	execute prepared
#
sub sqlpp_execute {
	my ($src, $attrs, $phs) = @_;
#
#	collect any PH values to be applied
#	NOTE: should NOTFOUND be tested ???
#	NOTE2: need to support SELECT here ?
#	No, use cursors instead!!!
#
	return undef
		unless ($src=~/^EXEC(UTE)?\s+(\w+|[01]\d+[\01])$/is);

	my $name = $2;
	$name = $$phs[$1] if ($name=~/\01(\d+)/);
	my $replaced = $RELAXED ? '' :
"	if (! defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\");
	}
	else {
";
	$replaced .=
"	unless (defined(${sqlpp_ctxt}->{sths}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Unknown statement $name.\");
	}
	else {
		${sqlpp_ctxt}->{rc} = 1;
		if (${sqlpp_ctxt}->{stmt_phs}{$name}[0] &&
			(ref ${sqlpp_ctxt}->{stmt_phs}{$name}[0] eq 'ARRAY')) {
#
#	use array binding
#
			foreach (1..scalar \@{${sqlpp_ctxt}->{stmt_phs}{$name}}) {
				${sqlpp_ctxt}->{rc} =
					${sqlpp_ctxt}->{sths}{$name}->bind_param_array(\$_,
						${sqlpp_ctxt}->{stmt_phs}{$name}[\$_-1]);
				last unless ${sqlpp_ctxt}->{rc};
			}

			${sqlpp_ctxt}->{tuple_status} = [];
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{sths}{$name})
				unless (${sqlpp_ctxt}->{rc} &&
					defined(${sqlpp_ctxt}->{sths}{$name}->execute_array(
						{ArrayTupleStatus => ${sqlpp_ctxt}->{tuple_status}})));
		}
		else {
			foreach (1..scalar \@{${sqlpp_ctxt}->{stmt_phs}{$name}}) {
				${sqlpp_ctxt}->{rc} =
					${sqlpp_ctxt}->{sths}{$name}->bind_param(\$_,
						\${${sqlpp_ctxt}->{stmt_phs}{$name}[\$_-1]});
				last unless ${sqlpp_ctxt}->{rc};
			}

			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{sths}{$name})
				unless (${sqlpp_ctxt}->{rc} &&
					defined(${sqlpp_ctxt}->{sths}{$name}->execute()));
		}
	}
";
	return $RELAXED ? $replaced : "$replaced
	}
";
}

sub sqlpp_fetch_cursor {
	my ($src, $attrs, $phs) = @_;
#
#	fetch the results into specified variables, which may be any of
#	(hash, array, list of scalars)
#	OR default to @_
#
	my ($name, $dmy);
	($name, $dmy, $src) = ($src=~/^FETCH\s+(\w+|\01\d+\01)(\s+INTO\s+(.+))?$/is);

	return undef
		unless defined($name);

	$name = $$phs[$1] if ($name=~/\01(\d+)/);
	my @vars = $src ? split(/\s*,\s*/, $src) : ();
	foreach (0..$#vars) {
		$vars[$_] = $$phs[$1]
			if ($vars[$_]=~/\:\01(\d+)/);
	}

	my $replaced = $RELAXED ?
"	if (! defined(${sqlpp_ctxt}->{cursors}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Undefined cursor $name\");
	}
	elsif (! ${sqlpp_ctxt}->{cursor_open}{$name}) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Cursor $name not open.\");
	}
	else {
" :
"	if (! defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\");
	}
	elsif (! defined(${sqlpp_ctxt}->{cursors}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Undefined cursor $name\");
	}
	elsif (! ${sqlpp_ctxt}->{cursor_open}{$name}) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Cursor $name not open.\");
	}
	else {
";

	unless (scalar @vars) {
#
#	missing our INTO, use @_
#
		$replaced .= 
"		\@_ = ${sqlpp_ctxt}->{cursors}{$name}->fetchrow_array();
		unless (scalar \@_) {
";
	}
	elsif (substr($vars[0], 0, 1) eq '%') {
		$replaced .= 
"		\$_ = ${sqlpp_ctxt}->{cursors}{$name}->fetchrow_hashref();
		if (\$_) {
			$vars[0] = \%\$_;
		}
		else {
";
	}
	elsif (substr($vars[0], 0, 1) eq '@') {
		$replaced .= 
"		$vars[0] = ${sqlpp_ctxt}->{cursors}{$name}->fetchrow_array();
		unless (scalar $vars[0]) {
";
	}
	else {
#
#	get list and move the data into it; if it has
#	bad entries in the list, then perl runtime will choke
#
		$replaced .= 
"		\@_ = ${sqlpp_ctxt}->{cursors}{$name}->fetchrow_array();
		if (scalar \@_) {
			(" . join(', ', @vars) . ") = \@_;
		}
		else {
";
	}
	$replaced .=
"			if (${sqlpp_ctxt}->{cursors}{$name}->err) {
				${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
					$sqlpp_ctxt, ${sqlpp_ctxt}->{cursors}{$name});
			}
			else {
				${sqlpp_ctxt}->{NOTFOUND}[${sqlpp_ctxt}->{handler_idx}]->catch(
					$sqlpp_ctxt);
			}
		}
	}
";		
	return $replaced;
}

sub sqlpp_open_cursor {
	my ($src, $attrs, $phs) = @_;
#
#	open the named cursor
#
	return undef 
		unless ($src=~/^OPEN\s+(\w+|\01\d+\01)$/);

	my $name = $1;
	return
"	unless (defined(${sqlpp_ctxt}->{cursors}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Undefined cursor $name\");
	}
	else {

		${sqlpp_ctxt}->{current_sth} = ${sqlpp_ctxt}->{cursors}{$name};
		${sqlpp_ctxt}->{rc} = 1;
		if (${sqlpp_ctxt}->{cursor_phs}{$name}) {
			foreach (1..scalar \@{${sqlpp_ctxt}->{cursor_phs}{$name}}) {
				${sqlpp_ctxt}->{rc} = 
					${sqlpp_ctxt}->{current_sth}->bind_param(\$_, 
						\${${sqlpp_ctxt}->{cursor_phs}{$name}[\$_-1]});
				last unless ${sqlpp_ctxt}->{rc};
			}
		}
		${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{rc} ?
			${sqlpp_ctxt}->{current_sth}->execute() : undef;
	
		if (! defined(${sqlpp_ctxt}->{rows})) {
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_sth});
		}
		elsif (! ${sqlpp_ctxt}->{rows}) {
			${sqlpp_ctxt}->{NOTFOUND}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt); 
		}
		else {
#
#	save synthesized cursor name (if any)
#
			${sqlpp_ctxt}->{cursor_map}{$name} = 
				${sqlpp_ctxt}->{current_sth}->{CursorName};
			${sqlpp_ctxt}->{cursor_open}{$name} = 1;
		}
	}
";
}

sub sqlpp_prepare {
	my ($src, $attrs, $phs) = @_;
#
#	prepare a statement as a named entity
#	note we must extract placeholders of form ":\$+\w+"
#	and replace with '?'
#	NOTE: we currently don't support or check for
#	SELECT, CALL, or positioned updates here, tho
#	some future release may support those
#
	return undef 
		unless ($src=~/^PREPARE\s+(\01\d+\01|\w+)\s+AS\s+(.+)$/is);

	my $name = $1;
	$src = $2;
	my @vars = ($src=~/\:(\01\d+\01)/gs);
	$src=~s/:(\01\d+\01)/\?/g;

	my $phlist = '';
	if (scalar @vars) {
		$src=~s/:([@\$]\$*\w+)/\?/g;
		my $first = substr($vars[0],0,1);
		$phlist = "\\$vars[0]";
		foreach (1..$#vars) {
			warn '[SQL::Preproc] Invalid statement: cannot mix scalar and array placeholders.',
			return undef
				unless ($first eq substr($vars[$_],0,1));
			$phlist .= ", \\$vars[$_]";
		}
	}

	$src = sqlpp_quote_it($src, $phs);
	return $RELAXED ?
"	${sqlpp_ctxt}->{sths}{$name} = ${sqlpp_ctxt}->{current_dbh}->prepare($src, $attrs);
	unless (defined(${sqlpp_ctxt}->{sths}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
	}
	else {
#
#	save the list of PH refs
#
		${sqlpp_ctxt}->{stmt_phs}{$name} = [ $phlist ];
		${sqlpp_ctxt}->{stmt_map}{$name} = ${sqlpp_ctxt}->{curr_dbh_name};
	}
" :
"	unless (defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\");
	}
	else {
		${sqlpp_ctxt}->{sths}{$name} = ${sqlpp_ctxt}->{current_dbh}->prepare($src, $attrs);
		unless (defined(${sqlpp_ctxt}->{sths}{$name})) {
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
		}
		else {
#
#	save the list of PH refs
#
			${sqlpp_ctxt}->{stmt_phs}{$name} = [ $phlist ];
			${sqlpp_ctxt}->{stmt_map}{$name} = ${sqlpp_ctxt}->{curr_dbh_name};
		}
	}
";
}

sub sqlpp_rollback_work {
#
#	rollback a xaction
#
	return $RELAXED ?
"	${sqlpp_ctxt}->{current_dbh}->rollback();
	${sqlpp_ctxt}->{current_dbh}{AutoCommit} = 1;
" :
"	unless (defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\");
	}
	else {
		${sqlpp_ctxt}->{current_dbh}->rollback();
		${sqlpp_ctxt}->{current_dbh}{AutoCommit} = 1;
	}
";
}
#
#	handle SELECT
#
sub sqlpp_select {
	my ($src, $attrs, $phs) = @_;
#
#	fetch the results into specified variables, which may be any of
#	(hash, array, list of scalars)
#	OR default to @_
#	NOTE: may need better parsing of returned column list in future
#	NOTE2: we assume that prepare/execute provide all status needed
#	for throwing exceptions, and so don't check for errors/NOTFOUND
#	during the fetch
#
	my @vars;
	@vars = split(/\s*,\s*/, $1)
		if ($src=~/\bINTO\s+(:\01\d+\01(\s*,\s*:\01\d+\01)*)/is);
#
#	trim leading colon and get actual variable name
#
	foreach (0..$#vars) {
		$vars[$_] = $$phs[$1] 
			if ($vars[$_]=~/\:\01(\d+)/);
	}
#
#	verify variable types
#
	if (scalar @vars) {
		my $first = substr($vars[0], 0,1);
		warn "[SQL::Preproc] Invalid INTO list: only 1 hash or array variable permitted.",
		return undef
			if ((($first eq '%') || ($first eq '@')) && (scalar @vars > 1));

		foreach (0..$#vars) {
			warn "[SQL::Preproc] Invalid INTO list: cannot mix scalars, arrays, and hashes.",
			return undef
				if (substr($vars[$_], 0,1) ne $first);
		}
#
#	suss out the INTO clause
#
		$src=~s/\bINTO\s+:\01\d+\01(\s*,\s*:\01\d+\01)*//i;
	}
#
#	locate all other vars and remap to '?'
#		NOTE: we only support scalars for PH variables in SELECT
#	then prepare/execute statement
#		NOTE: in future we may need a way to bind type info
#
	my @invars = ();
	push @invars, $$phs[$1]
		while ($src=~/\:\01(\d+)\01/gs);
	$src=~s/\:\01\d+\01/\?/g;

	$src = sqlpp_quote_it($src, $phs);
	my $execsql = (scalar @invars) ? 
		'execute(' . join(', ', @invars) . ')' : 'execute()';
#
#	sorry, no DBI shortcuts here, since we need error/not found
#	events
#
	my $replaced = $RELAXED ?
"	${sqlpp_ctxt}->{current_sth} = 
		${sqlpp_ctxt}->{current_dbh}->prepare($src, $attrs);
	unless (defined(${sqlpp_ctxt}->{current_sth})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
	}
	else {
		${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{current_sth}->$execsql;

		if (! defined(${sqlpp_ctxt}->{rows})) {
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_sth});
		}
		elsif (! ${sqlpp_ctxt}->{rows}) {
			${sqlpp_ctxt}->{NOTFOUND}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt);
		}
		else {
" :

"	unless (defined(${sqlpp_ctxt}->{current_dbh})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\");
	}
	else {
		${sqlpp_ctxt}->{current_sth} = 
			${sqlpp_ctxt}->{current_dbh}->prepare($src, $attrs);
		unless (defined(${sqlpp_ctxt}->{current_sth})) {
			${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
				$sqlpp_ctxt, ${sqlpp_ctxt}->{current_dbh});
		}
		else {
			${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{current_sth}->$execsql;

			if (! defined(${sqlpp_ctxt}->{rows})) {
				${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
					$sqlpp_ctxt, ${sqlpp_ctxt}->{current_sth});
			}
			elsif (! ${sqlpp_ctxt}->{rows}) {
				${sqlpp_ctxt}->{NOTFOUND}[${sqlpp_ctxt}->{handler_idx}]->catch(
					$sqlpp_ctxt);
			}
			else {
";

	if (! scalar @vars) {
#
#	missing our INTO, use @_
#
		$replaced .= 
"				\@_ = ${sqlpp_ctxt}->{current_sth}->fetchrow_array();
";
	}
	elsif (substr($vars[0], 0, 1) eq '%') {
#
#	get all rows keyed by column names; note that
#	this copy isn't as bad as might be thought, as its
#	not a deep copy
#
		substr($vars[0], 0, 1) = '$';
		$replaced .= 
"				my \$i;
				my \@cols = (([]) x ${sqlpp_ctxt}->{current_sth}{NUM_OF_FIELDS});
				my \$rows = ${sqlpp_ctxt}->{current_sth}->fetchall_arrayref();
				foreach (\@\$rows) {
					foreach \$i (0..\$#\$_) {
						push \@{\$cols[\$i]}, \$\$_[\$i];
					}
				}
				$vars[0]\{${sqlpp_ctxt}->{current_sth}{NAME}[\$_]\} = \$cols[\$_]
					foreach (0..\$#cols);
";
	}
	elsif (substr($vars[0], 0, 1) eq '@') {
#
#	get all rows as column arrayrefs stored in the PH array
#	this copy isn't as bad as might be thought, as its
#	not a deep copy
#
		$replaced .= 
"				$vars[0] = \@{${sqlpp_ctxt}->{current_sth}->fetchall_arrayref()};
";
	}
	else {
#
#	get list and move the data into it; if it has
#	bad entries in the list, then perl runtime will choke
#	should we throw exception if # of vars <> NUM_OF_FIELDS ?
#
				$replaced .= 
"				(" . join(', ', @vars) . ") = 
					${sqlpp_ctxt}->{current_sth}->fetchrow_array();
";
	}
#
#	always clean up after ourselves
#
	$replaced .= $RELAXED ?
"			${sqlpp_ctxt}->{current_sth}->finish();
			delete ${sqlpp_ctxt}->{current_sth};
		}
	}
" :
"				${sqlpp_ctxt}->{current_sth}->finish();
				delete ${sqlpp_ctxt}->{current_sth};
			}
		}
	}
";

	return $replaced;
}

sub sqlpp_set_connection {
	my ($src, $attrs, $phs) = @_;
#
#	only permits setting current connection for now
#
	my ($name) = ($src=~/^SET\s+CONNECTION\s+(.+)$/is);
	return undef unless $name;

	return $RELAXED ?
"	${sqlpp_ctxt}->{current_dbh} = ${sqlpp_ctxt}->{dbhs}{$name};
" :
"	unless (defined(${sqlpp_ctxt}->{dbhs}{$name})) {
		${sqlpp_ctxt}->{SQLERROR}[${sqlpp_ctxt}->{handler_idx}]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Undefined connection $name\");
	}
	else {
		${sqlpp_ctxt}->{current_dbh} = ${sqlpp_ctxt}->{dbhs}{$name};
	}
";
}
#
#	parse any placeholder descriptors
#	actually, this needs to be handled during the
#	lex scan
#
sub sqlpp_using {
	my ($src, $attrs, $phs) = @_;
}
#
#	raise an exception
#
sub sqlpp_raise {
	my ($src, $attrs, $phs) = @_;

	return undef
		unless ($src=~/^RAISE\s+(SQLERROR|NOT\s+FOUND)(\s+(.+))?/is);
	
	my $type = (uc $1 eq 'SQLERROR') ? 'SQLERROR' : 'NOTFOUND';
	my $params = defined($3) ? ", $3" : '';
	return 
"	${sqlpp_ctxt}->{$type}[${sqlpp_ctxt}->{handler_idx}]->raise(
		$sqlpp_ctxt$params);
";
}
#
#	start/install exception handler
#
sub sqlpp_whenever {
	my $src = shift;

	my ($cond) = ($src=~/^WHENEVER\s+(SQLERROR|NOT\s+FOUND)/is);
	$cond = (uc $cond eq 'SQLERROR') ? 'SQLERROR' : 'NOTFOUND';
	$exceptvar++;
	return
"	my \$__except_$exceptvar =
		SQL::Preproc::ExceptContainer->new_$cond(${sqlpp_ctxt}, 
			sub {
";
}
#
#	end the current handler subref
#
sub sqlpp_end_handler {
	return "});";
}
#
#	extract placeholder variables, and replace with
#	'?'; returns ( modified sql, arrayref of variables )
#
sub sqlpp_replace_PHs {
	my $sql = shift;
	my @vars = ($sql=~/:(\01\d+\01)/gs);
	$sql=~s/:(\01\d+\01)/\?/g;
	return ($sql, \@vars);
}
#
#	install an extension for a given keyword
#
sub sqlpp_install_syntax {
	my ($keyword, $pattern, $obj) = @_;

	my $class = ref $obj;
	$class=~s/^SQL::Preproc:://;
	$keyword_map{$keyword}->{$class} = [ $pattern, $obj ];
	1;	
}
#
#	temp fix until Text::Balanced is fixed
#
sub sqlpp_skip_heredoc {
	my $str = shift;
	
	return undef 
		unless ($$str=~/\G<<\s*(('[^']+')|("[^"]+"))\s*(;)?/gcs);

	my $delim = substr($1, 1, length($1) - 2);
	return $4 ? (($$str=~/\G.*?\n$delim[ \t\r\f]*\n/gcs) ? 1 : undef) :
		(($$str=~/\G.*?\n$delim[ \t\r\f]*(;)?[ \t\r\f]*\n/gcs) ? ($1) ? 1 : -1 : undef);
}
#
#	convert a query string into something we can safely
#	stick between single quotes
#
sub sqlpp_quote_it {
	my ($str, $phs) = @_;
	$str=~s/[\0\01](\d+)[\0\01]/$$phs[$1]/g
		if scalar @$phs;	# EXEC IMM implicitly avoided here!
	$str=~s/\\/\\\\/g;
	$str=~s/'/\\'/g;
	return "'" . $str . "'";
}
1;
