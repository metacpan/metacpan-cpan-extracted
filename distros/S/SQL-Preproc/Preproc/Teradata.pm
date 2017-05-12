package Sql::Preproc::Teradata;
#
#	SQL::Preproc::Teradata - Teradata specific syntax extension module
#	
#	Provides support for Teradata SQL extensions, including PM/API
#	requests
#
use strict;

my %tdat_keywords = (
'ABORT', \&tdat_abort,
'BEGIN',  \&tdat_begin_work,
'DATABASE', undef,
'END',  \&tdat_end_work,
'EXECSQL', \&tdat_exec_mstmt,
'IDENTIFY', \&tdat_identify,
'LOCK',  \&tdat_exec_immediate,
'LOCKING',  \&tdat_exec_immediate,
'MERGE',  undef,
'MONITOR',	\&tdat_monitor,
'POSITION',  \&tdat_position_cursor,
'REWIND',  \&tdat_rewind_cursor,
'SET', \&tdat_set,
'SHOW',  undef,
'USING',  \&tdat_exec_immediate
);

my $mstmt;	# to hold running SQL of multistmts
my $in_mstmt;	# 1 => we're in an mstmt section

sub init {
	my ($keywords) = @_;

	$keywords->{$_}->{ Teradata } = $tdat_keywords{$_}
		foreach (keys %tdat_keywords);
	
	$mstmt = undef;
	$in_mstmt = undef;
	return $keywords;
}

sub tdat_begin_work {
	my ($cmd, $remnant, $sqlpp) = @_;
#
#	Teradata syntax to commit
#
	return ($remnant=~/^(TRANSACTION|TRANS|WORK)$/) ? 
"	${sqlpp}->{current_dbh}->{AutoCommit} = undef;
" :	undef;
}

sub tdat_begin_mstmt {
	my ($cmd, $remnant, $sqlpp) = @_;
#
#	accumulate a SQL stmt in mstmt context
#
	$mstmt .= "$cmd $remnant;";
}

sub tdat_end_mstmt {
	my ($cmd, $remnant, $sqlpp) = @_;
#
#	now we can emit the multistmt processing code
#
	$in_mstmt = undef;
	return 
"	${sqlpp}->{current_sth} = ${sqlpp}->{current_dbh}->prepare('$mstmt');
	
	defined(${sqlpp}->{SQLERROR}) ?
		${sqlpp}->{SQLERROR}->[-1]->catch($sqlpp_ctxt,
			${sqlpp}->{current_dbh}->err,
			${sqlpp}->{current_dbh}->state,
			${sqlpp}->{current_dbh}->errstr) :
		die ${sqlpp}->{current_dbh}->errstr
		unless defined(${sqlpp}->{current_sth});
	
	${sqlpp}->{rows} = ${sqlpp}->{current_sth}->execute();
	
	defined(${sqlpp}->{SQLERROR}) ?
		${sqlpp}->{SQLERROR}->[-1]->catch($sqlpp_ctxt,
			${sqlpp}->{current_sth}->err,
			${sqlpp}->{current_sth}->state,
			${sqlpp}->{current_sth}->errstr) :
		die ${sqlpp}->{current_sth}->errstr
		unless defined(${sqlpp}->{rows});
	}

	${sqlpp}->{NOTFOUND}->[-1]->catch($sqlpp_ctxt)
		if (defined(${sqlpp}->{NOTFOUND}) && (${sqlpp}->{rows} == 0));
#
#	iterate over the result sets
#
";
}

sub tdat_end_work {
	my ($cmd, $remnant, $sqlpp) = @_;
#
#	Teradata syntax to commit
#
	return ($remnant=~/^(TRANSACTION|TRANS|WORK)$/) ?
"	${sqlpp}->{current_dbh}->commit();
" : undef;
}

sub tdat_exec_immediate {
	my ($cmd, $remnant, $sqlpp) = @_;
	
	if ($cmd eq 'USING') {
#
#	need a way to interpret these variables
#
	}
	if (($cmd eq 'LOCK') || ($cmd eq 'LOCKING')) {
#
#	just bypass this clause, then look for placeholders
#	in the rest of hte query
#
	}
#
#	generate code to execute the query
#
	return 
"	${sqlpp}->{rows} = ${sqlpp}->{current_dbh}->do('$cmd $remnant');
	
	defined(${sqlpp}->{SQLERROR}) ?
		${sqlpp}->{SQLERROR}->[-1]->catch($sqlpp_ctxt,
			${sqlpp}->{current_dbh}->err,
			${sqlpp}->{current_dbh}->state,
			${sqlpp}->{current_dbh}->errstr) :
		die ${sqlpp}->{current_dbh}->errstr
		unless defined(${sqlpp}->{rows});

	${sqlpp}->{NOTFOUND}->[-1]->catch($sqlpp_ctxt)
		if (defined(${sqlpp}->{NOTFOUND}) && (${sqlpp}->{rows} == 0));
";
}

sub tdat_position {
	my ($cmd, $remnant, $sqlpp) = @_;
#
#	not supported for now
#
	return ($remnant=~/^(FIRST|LAST|PREVIOUS|NEXT|([-+]?\d+))$/) ? undef : undef;
}

sub tdat_rewind {
	my ($cmd, $remnant, $sqlpp) = @_;

	return ($remnant=~/^(\w+)$/) ? 
"	${sqlpp}->{sths}->{$1}->tdat_Rewind();
" : undef ;
}

sub tdat_set {
	my ($cmd, $remnant, $sqlpp) = @_;
#
#	maybe for pmapi set session/resource rate
#	or set connection
#
	my @args = ($remnant=~/^(SESSION|RESOURCE)\s+RATE\s+TO\s+(((:\$+)?\w+)|\d+)\s+WHERE\s+VERSION\s*=\s*(\$*\w+)(\s+AND\s+(LOG_CHANGE|VIRTUAL_CHANGE)\s*=\s*(.+))*$/i);
	if (@args) {
	}
#
#	need to be able to support single quoted literals here
#
	@args = ($remnant=~/^SESSION\s+ACCOUNT\s+TO\s+(((:\$+)?\w+))(\s+FOR\s+ALL)\s+WHERE\s+VERSION\s*=\s*(\$*\w+)(\s+AND\s+(HOSTID|SESSIONNO|)\s*=\s*(.+))*$/i);
	if (@args) {
	}
#
#	its a set connection, let default handle it
#
	return undef;
}

sub tdat_monitor {
	my ($cmd, $remnant, $sqlpp) = @_;
#
#	make sure its a PMAPI session,
#	and that the stmt is valid
#
	my @args = ($remnant=~/^(PHYSICAL|VIRTUAL)\s+(CONFIG|RESOURCE|SUMMARY)\s+WHERE\s+VERSION\s*\=\s*(((:\$*)?\w+)|\d+)?$/i);
	if (@args) {
	}

	@args = ($remnant=~/^SESSION\s+WHERE\s+VERSION\s*\=\s*(((:\$*)?\w+)|\d+))?(\s+AND\s+(HOSTID|SESSIONNO|USER)\s*=\s*((:\$*)?\w+))*$/i);
	if (@args) {
	}

	@args = ($remnant=~/^SQL\s+WHERE\s+VERSION\s*\=\s*(((:\$*)?\w+)|\d+))?(\s+AND\s+(HOSTID|SESSIONNO)\s*=\s*((:\$*)?\w+))*$/i);
	if (@args) {
	}

	@args = ($remnant=~/^VERSION\s+WHERE\s+VERSION\s*\=\s*(((:\$*)?\w+)|\d+))$/i);
	if (@args) {
	}
}

sub tdat_identify {
	my ($cmd, $remnant, $sqlpp) = @_;
#
#	PM API IDENTIFY
#
	my @args = ($remnant=~/^(SESSION|DATABASE|TABLE|USER)\s+WHERE\s+((VERSION|HOSTID|SESSIONNO|USER)\s*\=\s*((:\$*)?\w+)(\s+AND\s+)?)+$/i);
	return undef unless @args;
}

sub tdat_abort {
	my ($cmd, $remnant, $sqlpp) = @_;
#
#	may be either xaction abort, or pmapi abort session
#
	my @args = ($remnant=~/^SESSION\s+WHERE\s+((VERSION|HOSTID|SESSIONNO|USER)\s*\=\s*((:\$*)?\w+)(\s+AND\s+)?)+$/i);
	if (@args) {
#
#	its a PM API call
#
	"	${sqlpp}->{sths}->{$1}->tdat_Rewind();
	" : undef ;
	}
	else {
		@args = ($remnant=~/^(WHERE\s+(.+))?$/i);
		return undef unless @args;
#
#	its a xaction abort
#
	}
}

1;