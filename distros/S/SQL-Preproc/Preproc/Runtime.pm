package SQL::Preproc::Runtime;
#
#	SQL::Preproc::Runtime - runtime module for SQL::Preproc
#
#	Currently only a placeholder for a future version which
#	will use a packaged runtime, rather than emitting all the
#	DBI code directly into the translated source.
#
use DBI;
use DBI qw(:sql_types);

use strict;

our $VERSION = '0.20';

sub new {
	my $class = shift;
	
	my $obj = { 
		current_dbh => undef,
		current_sth => undef,
		dbhs => { },
		sths => { },
		cursors => { }
	};
	
	bless $obj, $class;
	
	return $obj;
}
#
#	install a syntax handler
#
sub sqlpp_install_syntax {
	my ($obj, $syntax) = @_;

}
#
#	runtime subroutines for
#	processing statements
#
sub sqlpp_connect {
	my ($obj, $dsn, $user, $password, $name, $attributes, $syntax) = @_;

"	${sqlpp_ctxt}->{current_dbh} = ${sqlpp_ctxt}->{dbhs}->{$args[9]} = 
		$driver->connect(\"$args[0]\", $args[5], $args[7],
		{ PrintError => 0, RaiseError => 0, AutoCommit => 1, $args[11] });

	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, \$DBI::err, \$DBI::state, \$DBI::errstr) :
		die \$DBI::errstr
		unless defined(${sqlpp_ctxt}->{current_dbh});
";
}

sub sqlpp_disconnect {
	my ($obj, $name) = @_;

	$remnant = 'default'
		unless defined($remnant);

	return undef
		unless ($remnant=~/^(\$*\w+)$/);
#
#	we need to clean out any assoc. stmts/cursors
#
	return ($1 ne 'ALL') ?
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Unknown connection $1\") :
		die \"Unknown connection $1\"
		unless defined(${sqlpp_ctxt}->{dbhs}->{$1});

	${sqlpp_ctxt}->{dbhs}->{$1}->disconnect;
	${sqlpp_ctxt}->{current_dbh} = undef
		if (${sqlpp_ctxt}->{current_dbh} eq ${sqlpp_ctxt}->{dbhs}->{$1});
	delete ${sqlpp_ctxt}->{dbhs}->{$1};
" :
"	foreach (keys \%{${sqlpp_ctxt}->{dbhs}}) {
		${sqlpp_ctxt}->{dbhs}->{\$_}->disconnect;
		${sqlpp_ctxt}->{current_dbh} = undef
			if (${sqlpp_ctxt}->{current_dbh} eq ${sqlpp_ctxt}->{dbhs}->{\$_});
		delete ${sqlpp_ctxt}->{dbhs}->{\$_};
	}
";}

sub sqlpp_select {
	my ($obj, $stmt) = @_;
#
#	fetch the results into specified variables, which may be any of
#	(hash, array, list of scalars)
#	OR default to @_
#	NOTE: may need better parsing of returned column list in future
#
	my @outphs = ($remnant=~/\bINTO\s+:([%@\$]\$*\w+)(\s*,\s*:[@\$]\$*\w+)*/i);
	pop @outphs
		while ((scalar @outphs) && (! defined($outphs[-1])));
	if (scalar @outphs) {
#
#	trim leading colon
#
		$outphs[$_]=~s/^(\s*,\s)?://
			foreach (1..$#outphs);
#
#	verify variable types
#
		my $first = substr($outphs[0], 0,1);
		warn "[SQL::Preproc] Invalid INTO list: only 1 hash variable permitted.",
		return undef
			if (($first eq '%') && (scalar @outphs > 1));

		foreach (1..$#outphs) {
			warn "[SQL::Preproc] Invalid INTO list: cannot mix scalars, arrays, and hashes.",
			return undef
				if (substr($outphs[$_], 0,1) ne $first);
		}
#
#	suss out the INTO clause
#
		$remnant=~s/\bINTO\s+:[%@\$]\$*\w+(\s*,\s*:[@\$]\$*\w+)*//i;
	}
#
#	locate all other PHs and remap to '?'
#		NOTE: we only support scalars for PH variables in SELECT
#	then prepare/execute statement
#		NOTE: in future we may need a way to bind type info
#
	my @inphs = ($remnant=~/:(\$+\w+)/g);
	$remnant=~s/:\$+\w+/\?/g;

	my $execsql = (scalar @inphs) ? 
		'execute(' . join(', ', @inphs) . ')' : 'execute()';

	my $replaced =
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\") :
		die \"No current connection.\"
		unless defined(${sqlpp_ctxt}->{current_dbh});

	${sqlpp_ctxt}->{current_sth} = ${sqlpp_ctxt}->{current_dbh}->prepare(\"SELECT $remnant\");

	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt,
			${sqlpp_ctxt}->{current_dbh}->err,
			${sqlpp_ctxt}->{current_dbh}->state,
			${sqlpp_ctxt}->{current_dbh}->errstr
			) :
		die ${sqlpp_ctxt}->{current_dbh}->errstr
		unless defined(${sqlpp_ctxt}->{current_sth});

	${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{current_sth}->$execsql;

	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt,
			${sqlpp_ctxt}->{current_sth}->err,
			${sqlpp_ctxt}->{current_sth}->state,
			${sqlpp_ctxt}->{current_sth}->errstr
			) :
		die ${sqlpp_ctxt}->{current_sth}->errstr
		unless defined(${sqlpp_ctxt}->{rows});

	${sqlpp_ctxt}->{NOTFOUND}->[-1]->catch($sqlpp_ctxt)
		if (${sqlpp_ctxt}->{NOTFOUND} && (! ${sqlpp_ctxt}->{rows}));
";

	unless (scalar @outphs) {
#
#	missing our INTO, use @_
#
		$replaced .= 
"	\@_ = ${sqlpp_ctxt}->{current_sth}->fetchrow_array();
";		
	}
	elsif (substr($outphs[0], 0, 1) eq '%') {
		$replaced .= 
"	$outphs[0] = ${sqlpp_ctxt}->{current_sth}->fetchrow_hash();
";
	}
	elsif (substr($outphs[0], 0, 1) eq '@') {
#
#	maybe we should use bind_cols here ?
#	also, should we throw exception if # of PHs <> NUM_OF_FIELDS ?
#
		$replaced .= 
"	${sqlpp_ctxt}->{results} = ${sqlpp_ctxt}->{current_sth}->->fetchall_arrayref();
";
		$replaced .= 
"	$outphs[$_] = \@{${sqlpp_ctxt}->{results}->[$_]};
"
			foreach (0..$#outphs);
		$replaced .= 
"	delete ${sqlpp_ctxt}->{results};
";
	}
	else {
#
#	get list and move the data into it; if it has
#	bad entries in the list, then perl runtime will choke
#	should we throw exception if # of PHs <> NUM_OF_FIELDS ?
#
		$replaced .= "	(" . join(', ', @outphs) . ") = 
		${sqlpp_ctxt}->{current_sth}->fetchrow_array();
";
	}
#
#	always clean up after ourselves
#
	$replaced .= 
"	${sqlpp_ctxt}->{current_sth}->finish();
	delete ${sqlpp_ctxt}->{current_sth};
";

	return $replaced;
}

sub sqlpp_begin_work {
	my ($obj, $stmt) = @_;

	return (defined($remnant) && ($remnant=~/^WORK$/i)) ? 
"	${sqlpp_ctxt}->{SQLERROR} ? 
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection\") :
		die \"No current connection\"
		unless defined(${sqlpp_ctxt}->{dbhs}->{$1});

	${sqlpp_ctxt}->{current_dbh}->{AutoCommit} = 0;
" : undef;
}

sub sqlpp_call {
	my ($obj, $stmt) = @_;

"	${sqlpp_ctxt}->{SQLERROR} ? 
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection\") :
		die \"No current connection\"
		unless defined(${sqlpp_ctxt}->{dbhs}->{$1});

	${sqlpp_ctxt}->{current_sth} = 
		${sqlpp_ctxt}->{current_dbh}->prepare(\"CALL $remnant\");

	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch($sqlpp_ctxt,
			${sqlpp_ctxt}->{current_dbh}->err,
			${sqlpp_ctxt}->{current_dbh}->state,
			${sqlpp_ctxt}->{current_dbh}->errstr
			) :
		die ${sqlpp_ctxt}->{current_dbh}->errstr
		unless defined(${sqlpp_ctxt}->{current_sth});

	${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{current_sth}->execute();
	
	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch($sqlpp_ctxt,
			${sqlpp_ctxt}->{current_sth}->err,
			${sqlpp_ctxt}->{current_sth}->state,
			${sqlpp_ctxt}->{current_sth}->errstr
			) :
		die ${sqlpp_ctxt}->{current_sth}->errstr
		unless defined(${sqlpp_ctxt}->{rows});
" : undef;
}

sub sqlpp_declare_cursor {
	my ($obj, $stmt) = @_;

	return undef
		unless ($stmt=~/^CURSOR\s+(\$?\w+)\s+AS\s+(.+)$/);

	if (defined($1)) {
#
#	cursor declaration:
#		extract PHs
#		prepare result
#
		return 
"	${sqlpp_ctxt}->{stmts}->{$2} = \"$3\";
" 
	}
}

sub sqlpp_open_cursor {
	my ($obj, $cursor) = @_;
#
#	open the named cursor
#
	return undef 
		unless ($remnant=~/^(\$*\w+)$/);

	return
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Undefined cursor $1\") :
		die \"Undefined cursor $1\"
		unless defined(${sqlpp_ctxt}->{cursors}->{$1});

	${sqlpp_ctxt}->{current_sth} = ${sqlpp_ctxt}->{cursors}->{$1};
	${sqlpp_ctxt}->{rows} = ${sqlpp_ctxt}->{current_sth}->execute();
	
	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch($sqlpp_ctxt, 
			${sqlpp_ctxt}->{current_sth}->err,
			${sqlpp_ctxt}->{current_sth}->state,
			${sqlpp_ctxt}->{current_sth}->errstr) :
		die ${sqlpp_ctxt}->{current_sth}->errstr
		unless defined(${sqlpp_ctxt}->{rows});
";
}

sub sqlpp_fetch_cursor {
	my ($obj, $cursor) = @_;
#
#	fetch the results into specified variables, which may be any of
#	(hash, array, list of scalars)
#	OR default to @_
#
	my @phs = ($remnant=~/^\s*(\$*\w+)(\s+INTO\s+(:[%@\$]\$*\w+)(\s*,\s*(:[%@\$]\$*\w+))*)?$/i);
	pop @phs
		while ((scalar @phs) && (! defined($phs[-1])));
	return undef
		unless defined($phs[0]);

	my $replaced =
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Undefined cursor $phs[0]\") :
		die \"Undefined cursor $phs[0]\"
		unless defined(${sqlpp_ctxt}->{cursors}->{$phs[0]});
";

#print "FETCH got ", scalar @phs, "PHs\n";
	if (1 == scalar @phs) {
#
#	missing our INTO, use @_
#
		$replaced .= 
"	\@_ = ${sqlpp_ctxt}->{cursors}->{$phs[0]}->fetchrow_array();
";		
	}
	elsif ($phs[2]=~/^%/) {
		$replaced .= 
"	$phs[2] = ${sqlpp_ctxt}->{cursors}->{$phs[0]}->fetchrow_hash();
";
	}
	elsif ($phs[2]=~/^@/) {
		$replaced .= 
"	$phs[2] = ${sqlpp_ctxt}->{cursors}->{$phs[0]}->fetchrow_array();
";
	}
	else {
#
#	get list and move the data into it; if it has
#	bad entries in the list, then perl runtime will choke
#
		my @targets = ();
		my $i = 2;
		push (@targets, $phs[$i]),
		$i += 2
			while ($i < scalar @phs);

		$replaced .= "	(" . join(', ', @targets) . 
			") = ${sqlpp_ctxt}->{cursors}->{$phs[0]}->fetchrow_array();
";
	}
	return $replaced;
}

sub sqlpp_close_cursor {
	my ($obj, $cursor) = @_;

	return 
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Unknown cursor $1\") :
		die \"Unknown cursor $1\"
		unless defined(${sqlpp_ctxt}->{cursors}->{$1});

	${sqlpp_ctxt}->{cursors}->{$1}->finish();
";
}

sub sqlpp_prepare {
	my ($obj, $stmt, $name) = @_;
#
#	prepare a statement as a named entity
#	note we must extract placeholders of form ":\$+\w+"
#	and replace with '?'
#	also need to handle SELECT...INTO
#
	return undef 
		unless ($remnant=~/^(\$*\w+)\s+AS\s+(.+)$/);

	my $name = $1;
	$remnant = $2;
	my @phs = ($remnant=~/:([@\$]\$*\w+)/g);
	
	my $phlist = '';
	if (scalar @phs) {
		$remnant=~s/:([@\$]\$*\w+)/\?/g;
		my $first = substr($phs[0],0,1);
		$phlist = "'$phs[0]'";
		foreach (1..$#phs) {
			warn '[SQL::Preproc] Invalid statement: cannot mix scalar and array placeholders.',
			return undef
				unless ($first eq substr($phs[$_],0,1));
			$phlist .= ", '$phs[$_]'";
		}
	}

	return
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\") :
		die \"No current connection.\"
		unless defined(${sqlpp_ctxt}->{current_dbh});

	${sqlpp_ctxt}->{sths}->{$name} = ${sqlpp_ctxt}->{current_dbh}->prepare($remnant);
	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch($sqlpp_ctxt, 
			${sqlpp_ctxt}->{current_dbh}->err,
			${sqlpp_ctxt}->{current_dbh}->state,
			${sqlpp_ctxt}->{current_dbh}->errstr) :
		die ${sqlpp_ctxt}->{current_dbh}->errstr
		unless defined(${sqlpp_ctxt}->{sths}->{$name});

	${sqlpp_ctxt}->{phs}->{$name} = [ $phlist ];
";
}

sub sqlpp_describe {
	my ($obj, $stmt) = @_;

	my @phs = ($remnant=~/^\s*(\$*\w+)(\s+INTO\s+:([%@]?\$*\w+))?/i);

	return undef
		unless defined($phs[0]);

	my $xlated = 
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Undefined statement/cursor $phs[0]\") :
		die \"Undefined statement/cursor $phs[0]\"
		unless defined(${sqlpp_ctxt}->{cursors}->{$phs[0]})
";

	unless (1 < scalar @phs) {
#
#	missing our INTO, use @_
#
		$xlated .=
"	\@_ = ();
	push \@_, { 
		Name => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{NAME}->[\$_],
		Type => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{TYPE}->[\$_],
		Precision => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{PRECISION}->[\$_],
		Scale => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{SCALE}->[\$_]
		}
		foreach (0..\$#{${sqlpp_ctxt}->{cursors}->{$phs[0]}->{NAME}});
";
		return $xlated;
	}

	$phs[2] = "\@$phs[2]" if ($phs[2]=~/^\$/);
	$xlated .= "\t$phs[2] = ();\n";
	$phs[2]=~s/^%/\$/;
	$xlated .= ($phs[2]=~/^\$/) ? 
"	$phs[2]{${sqlpp_ctxt}->{cursors}->{$phs[0]}->{NAME}->[\$_]} = { 
		Type => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{TYPE}->[\$_],
		Precision => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{PRECISION}->[\$_],
		Scale => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{SCALE}->[\$_]
		}
		foreach (0..\$#{${sqlpp_ctxt}->{cursors}->{$phs[0]}->{NAME}});
" : 
"	push $phs[2], { 
		Name => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{NAME}->[\$_],
		Type => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{TYPE}->[\$_],
		Precision => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{PRECISION}->[\$_],
		Scale => ${sqlpp_ctxt}->{cursors}->{$phs[0]}->{SCALE}->[\$_]
		}
		foreach (0..\$#{${sqlpp_ctxt}->{cursors}->{$phs[0]}->{NAME}});
";
	return $xlated;
}

sub sqlpp_commit {
	my ($obj, $stmt) = @_;

	return undef
		if (defined($remnant) && ($remnant!~/^(WORK)?$/));
	return 
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\") :
		die \"No current connection.\"
		unless defined(${sqlpp_ctxt}->{current_dbh});

	${sqlpp_ctxt}->{current_dbh}->commit();
	${sqlpp_ctxt}->{current_dbh}->{AutoCommit} = 1;
";
}

sub sqlpp_rollback {
	my $obj = shift;
#
#	rollback a xaction
#
	return (defined($remnant) && ($remnant!~/^WORK$/i)) ? undef :
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\") :
		die \"No current connection.\"
		unless defined(${sqlpp_ctxt}->{current_dbh});

	${sqlpp_ctxt}->{current_dbh}->rollback();
";
}

sub sqlpp_set_connection {
	my ($obj, $name) = @_;
#
#	only permits setting current connection for now
#
	return ($remnant=~/^CONNECTION\s+(\$?\w+)$/) ?
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Undefined connection $1\") :
		die \"Undefined connection $1\"
		unless defined(${sqlpp_ctxt}->{dbhs}->{$1});

	${sqlpp_ctxt}->{current_dbh} = ${sqlpp_ctxt}->{dbhs}->{$1};
" : undef;
}

sub sqlpp_exec_immediate {
	my ($obj, $stmt) = @_;
#
# 	execute immediate: its an expression; just do() it
#	NOTE: no placeholders are supported,
#	and no data returning stmts either
#
	$remnant=~s/^IMMEDIATE\s+//i,
	return
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"No current connection.\") :
		die \"No current connection.\"
		unless defined(${sqlpp_ctxt}->{current_dbh});

	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch($sqlpp_ctxt, 
			${sqlpp_ctxt}->{current_dbh}->err,
			${sqlpp_ctxt}->{current_dbh}->state,
			${sqlpp_ctxt}->{current_dbh}->errstr) :
		die ${sqlpp_ctxt}->{current_dbh}->errstr
		unless defined(${sqlpp_ctxt}->{current_dbh}->do($remnant));
"
}

sub sqlpp_exec_prepared {
	my ($obj, $stmt) = @_;
#
#	otherwise its a prepared stmt
#	collect any PH values to be applied
#	NOTE: should NOTFOUND be tested ???
#
	my $execsql = defined(${sqlpp_ctxt}->{phs}->{$1}) ?
		'execute(' . join(', ', @{${sqlpp_ctxt}->{phs}->{$1}}) . ')' : 
		'execute()';
	return
"	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch(
			$sqlpp_ctxt, -1, 'S1000', \"Unknown statement $1.\") :
		die \"Unknown statement $1.\"
		unless defined(${sqlpp_ctxt}->{sths}->{$1});

	${sqlpp_ctxt}->{SQLERROR} ?
		${sqlpp_ctxt}->{SQLERROR}->[-1]->catch($sqlpp_ctxt, 
			${sqlpp_ctxt}->{current_dbh}->err,
			${sqlpp_ctxt}->{current_dbh}->state,
			${sqlpp_ctxt}->{current_dbh}->errstr) :
		die ${sqlpp_ctxt}->{current_dbh}->errstr
		unless defined(${sqlpp_ctxt}->{sths}->{$1}->$execsql);
";
}

sub sqlpp_exec_sql {
	my ($obj, $stmt) = @_;
}

sub sqlpp_whenever {
	my ($obj, $cond) = @_;
#
#	declare an exception handler;
#	note that we need to handle multistmts if we're scoped
#
	return undef 
		unless ($remnant=~/^(SQLERROR|(NOT\s+FOUND))\s+(.+)$/);
	my $cond = ($1 eq 'SQLERROR') ? 'SQLERROR' : 'NOTFOUND';
	return
"	push \@{${sqlpp_ctxt}->{$cond}}, 
		SQL::Preproc::Exception->new_$cond(${sqlpp_ctxt}, 
			sub { $3 });
";
}

sub DESTROY {
	my $obj = shift;
	
	delete $obj->{_ctxt};
	1;
}

1;