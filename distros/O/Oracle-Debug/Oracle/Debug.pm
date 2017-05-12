
# $Id: Debug.pm,v 1.46 2003/07/30 15:25:11 oradb Exp $

=head1 NAME

Oracle::Debug - A Perl (perldb-like) interface to the Oracle DBMS_DEBUG package for debugging PL/SQL programs.

=cut

package Oracle::Debug;

use 5.008;
use strict;
use warnings;
use Carp qw(carp croak);
use Data::Dumper;
use DBI;
use Term::ReadKey;

use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 1.46 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $DEBUG = $ENV{Oracle_Debug} || 0;

=head1 SYNOPSIS

	./oradb

=head1 ABSTRACT

A perl-debugger-like interface to the Oracle DBMS_DEBUG package for
debugging PL/SQL programs.

The initial impetus for creating this was to get a command-line interface,
similar in instruction set and feel to the perl debugger.  For this
reason, it may be beneficial for a user of this module, or at least the
intended B<oradb> interface, to be familiar with the perl debugger first.

=head1 DESCRIPTION

There are really 2 parts to this exersize:

=over 4

=item DB

The current Oracle chunk is a package which can be used directly to debug
PL/SQL without involving perl at all, but which has similar, but very limited, 
commands to the perl debugger.

Please see the I<packages/header.sql> file for credits for the original B<db> PL/SQL.

Developed against B<Probe version 2.4>

=item oradb

The Perl chunk implements a perl-debugger-like interface to the Oracle
debugger itself, partially via the B<DB> library referenced above.

=back

In both cases much more conveniently from the command line, than the
vanilla Oracle packages themselves.  In fairness DBMS_DEBUG is probably
designed to be used from a GUI of some sort, but this module focuses on 
it from a command line usage.

=head1 NOTES

Ignore any methods which are prefixed with an underscore (_)

We use a special B<oradb_table> for our own purposes.

Set B<Oracle_Debug>=1 for debugging information.

=head1 METHODS

=over 4

=item new

Create a new Oracle::Debug object

	my $o_debug = Oracle::Debug->new(\%dbconnectdata);

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) ? ref($proto) : $proto;
	my $self  = bless({
		'_config'		=> do 'scripts/config', # $h_conf,
		'_connect'	=> {
			'debugpid'	=> '',
			'primed'    => 0,
			'sessionid'	=> '',
			'targetid'	=> '',
			'connected' => 0,
			'synched'   => 0,
			'syncs'   	=> 7,
		},
		'_dbh'			=> {},
		'_unit'			=> {
			'owner'			=> '',
			'type'			=> '',
			'name'			=> '',
			'namespace'	=> '',
		},
	}, $class);
	$self->_prime;
	# $self->log($self.' '.Dumper($self)) if $DEBUG;
	return $self; 
}

=item _prime

Prime the object and connect to the db

Also ensure we are able to talk to Probe

	$o_debug->_prime;

=cut

sub _prime {
	my $self  = shift;
	my $h_ref = $self->{_config};
	unless (ref($h_ref) eq 'HASH') {
		$self->fatal("invalid db priming data hash ref: ".Dumper($h_ref));
	} else {
		# $self->{_dbh} = $self->dbh;
		$self->{_dbh}->{$$} = $self->_connect($h_ref);
		$self->{_connect}{primed}++ if $self->{_dbh}->{$$};
		$self->dbh->func(20000, 'dbms_output_enable');
		$self->self_check();
	}
	return ref($self->{_dbh}->{$$}) ? $self : undef;
}

# =============================================================================
# dbh and sql methods
# =============================================================================

=item dbh

Return the database handle

	my $dbh = $o_debug->dbh;

=cut

sub dbh {
	my $self = shift;
	# my $type = $self->{_config}->{type}; # debug-target
	return ref($self->{_dbh}->{$$}) ? $self->{_dbh}->{$$} : $self->_connect($self->{_config});
}

=item _connect

Connect to the database

=cut

sub _connect {
	my $self   = shift;
	my $h_conf = $self->{_config};

	my $dbh = DBI->connect(
		$h_conf->{datasrc},	$h_conf->{user}, $h_conf->{pass}, $h_conf->{params} 
	) || $self->fatal("Can't connect to database: $DBI::errstr");

	$self->{_connect}{connected}++;
	$self->log("connected: $dbh") if $DEBUG;

	return $dbh; #$id eq 'Debug' ? $dbh : 1;
}

=item getarow

Get a row

	my ($res) = $o_debug->getarow($sql);

=cut

sub getarow {
	my $self  = shift;
	my $sql   = shift;
	my @res;

	eval { @res = $self->dbh->selectrow_array($sql) };
#	my @res = $self->dbh->selectrow_array($sql) || $self->error("failed <$sql>");
	
	if ($DEBUG) {
		$self->log("failed to getarow: $sql $DBI::errstr") unless @res >= 1;
	}

	return @res;
}

=item getahash

Get a list of hashes

	my ($res) = $o_debug->getahash($sql);

=cut

sub getahash {
	my $self  = shift;
	my $sql   = shift;
	my @res;

	eval { @res = $self->dbh->selectrow_hash($sql) };
#	my @res = $self->dbh->selectrow_array($sql) || $self->error("failed <$sql>");
	
	if ($DEBUG) {
		$self->log("failed to getahash: $sql $DBI::errstr") unless @res >= 1;
	}

	return @res;
}


# =============================================================================
# parse and control
# =============================================================================

my %HISTORY = ();
my %TYPES   = (
	'CU' => 'CURSOR',
	'FU' => 'FUNCTION',
	'PA' => 'PACKAGE',
	'PR' => 'PROCEDURE',
	'TR' => 'TRIGGER',
	'TY' => 'TYPE',
);
my %NAMESPACES = (
	'BO' => 'Namespace_pkg_body', 
	'CU' => 'Namespace_cursor',
	'FU' => 'Namespace_pkgspec_or_toplevel', 
	'PA' => 'Namespace_pkgspec_or_toplevel', 
	'PK' => 'Namespace_pkgspec_or_toplevel', 
	'PR' => 'Namespace_pkgspec_or_toplevel', 
	'SP' => 'Namespace_pkgspec_or_toplevel', 
	'TR' => 'Namespace_trigger',
);
my %GROUPS  = (
	+0	=> [qw()],
	+1	=> [qw(b c n r s)],
	+3	=> [qw(l L v T)],
	+5	=> [qw(h H ! q)],
	+6	=> [qw(context err perl rc sync sql shell info)],
	+8	=> [qw(abort ping check test is_running)],
);
my $COMMANDS= join('|', @{$GROUPS{1}}, @{$GROUPS{3}}, @{$GROUPS{5}}, @{$GROUPS{6}}, @{$GROUPS{8}});
my %COMMAND = (
	'abort'		=> {
		'long'		=> 'abortexecution',
		'handle'	=> 'abort',
		'syntax'	=> 'abort[execution]',
		'simple'	=> 'abort target', 
		'detail'	=> 'abort currently running program in target session',
	},
	'b'		=> {
		'long'		=> 'setbreakpoint',
		'handle'	=> 'break',
		'syntax'	=> 'b [lineno] || setbreakpoint [lineno]',
		'simple'	=> 'set breakpoint', 
		'detail'	=> 'set breakpoint on given line of code identified by unit name',
	},
	'c'	  => {
		'long'		=> 'continue',
		'handle'	=> 'continue',
		'syntax'	=> 'c',
		'simple'	=> 'continue',
		'detail'	=> 'continue to breakpoint or other reason to stop',
	},
	'check'=> {
		'long'		=> 'selfcheck',
		'handle'	=> 'self_check',
		'syntax'	=> 'check || selfcheck',
		'simple'	=> 'run a self_check',
		'detail'	=> 'run a self_check against dbms_debug and probe communications',
	},
	'context'	  => {
		'long'		=> 'context',
		'handle'	=> 'runtime', # context
		'syntax'	=> 'context key[=val] [key[=val]]+',
		'simple'	=> 'get/set context',
		'detail'	=> 'get/set context for this instance: unit name, type, namespace etc.',
	},
	'err'	  => {
		'long'		=> 'errorstring',
		'handle'	=> 'plsql_errstr',
		'syntax'	=> 'err',
		'simple'	=> 'print plsql_errstr',
		'detail'	=> 'display the DBI->plsql_errstr (if set)',
	},
	'info'	  => {
		'long'		=> 'information',
		'handle'	=> 'info',
		'syntax'	=> 'info',
		'simple'	=> 'info on current environment',
		'detail'	=> 'display information on current programs and db(NYI)',
	},
	'help'	  => {
		'long'		=> 'help',
		'handle'	=> 'help',
		'syntax'	=> 'h [cmd|h|syntax]',
		'simple'	=> 'help listing - h h for more',
		'detail'	=> 'you can also give a command as an argument (eg: h b)',
	},
	'H'	  => {
		'long'		=> 'historylist',
		'handle'	=> 'history',
		'syntax'	=> 'H',
		'simple'	=> 'command history',
		'detail'	=> 'history listing not including single character commands',
	},
	'l'	  => {
		'long'		=> 'listsourcecode',
		'handle'	=> 'list_source',
		'syntax'	=> 'l unitname [PROC|PACK|TRIG|...]',
		'simple'	=> 'list source code',
		'detail'	=> 'list source code given with library type',
	},
	'L'	  => {
		'long'		=> 'listbreakpoints',
		'handle'	=> 'list_breakpoints',
		'syntax'	=> 'L',
		'simple'	=> 'list breakpoints',
		'detail'	=> 'on which line breakpoints exist',
	},
	'n'	  => {
		'long'		=> 'next',
		'handle'	=> 'next',
		'syntax'	=> 'n',
		'simple'	=> 'next line',
		'detail'	=> 'continue until the next line',
	},
	'perl'=> {
		'long'		=> 'perlcommand',
		'handle'	=> 'perl',
		'syntax'	=> 'perl <valid perl command>',
		'simple'	=> 'perl command',
		'detail'	=> 'execute a perl command',
	},
	'q'   => {
		'long'		=> 'quit',
		'handle'	=> 'quit',
		'syntax'	=> 'q(uit)',
		'simple'	=> 'exit',
		'detail'	=> 'quit the oradb',
	},
	'r'	  => {
		'long'		=> 'return',
		'handle'	=> 'return',
		'syntax'	=> 'r',
		'simple'	=> 'return',
		'detail'	=> 'return from the current block',
	},
	'rc'  => {
		'long'		=> 'recompilecode',
		'handle'	=> 'recompile',
		'syntax'	=> 'rc unitname',
		'simple'	=> 'recompile',
		'detail'	=> 'recompile the program/s given ',
	},
	's'	  => {
		'long'		=> 'stepintosubroutine',
		'handle'	=> 'step',
		'syntax'	=> 's',
		'simple'	=> 'step into',
		'detail'	=> 'step into the next function or method call',
	},
	'shell'	=> {
		'long'		=> 'shellcommand',
		'handle'	=> 'shell',
		'syntax'	=> 'shell <valid shell command>',
		'simple'	=> 'shell command',
		'detail'	=> 'execute a shell command',
	},
	'sql' => {
		'long'		=> 'sqlcommand',
		'handle'	=> 'sql',
		'syntax'	=> 'sql <valid SQL>',
		'simple'	=> 'SQL select',
		'detail'	=> 'execute a SQL SELECT statement',
	},
	'sync'	  => {
		'long'		=> 'synchronize',
		'handle'	=> 'sync',
		'syntax'	=> 'sync',
		'simple'	=> 'sync',
		'detail'	=> 'syncronize the sessions - '.
                 '(note that this session _should_ hang until the procedure is executed in the target session)'
	},
	'test'=> {
		'long'		=> 'testconnection',
		'handle'	=> 'test',
		'syntax'	=> 'test',
		'simple'	=> 'ping and check and if target is running',
		'detail'	=> 'ping, run a self_check and test whether target session is currently running and responding',
	},
	'is_running'=> {
		'long'		=> 'isrunning',
		'handle'	=> 'is_running',
		'syntax'	=> 'is_running',
		'simple'	=> 'check target is_running',
		'detail'	=> 'check whether target session is currently running and responding',
	},
	'ping'=> {
		'long'		=> 'pingthedatabase',
		'handle'	=> 'ping',
		'syntax'	=> 'ping',
		'simple'	=> 'ping target',
		'detail'	=> 'ping target session',
	},
	'T'=> {
		'long'		=> 'backtrace',
		'handle'	=> 'backtrace',
		'syntax'	=> 'T',
		'simple'	=> 'display backtrace',
		'detail'	=> 'backtrace listings',
	},
	'v'	  => {
		'long'		=> 'variablevalue',
		'handle'	=> 'value',
		'syntax'	=> 'v varname[=value]',
		'simple'	=> 'get/set variable',
		'detail'	=> 'get or set the value of a variable, (use double quotes to contain spaces)',
	},
	'!'   => {
		'long'		=> 'runhistorycommand',
		'handle'	=> 'rerun',
		'syntax'	=> '! (!|historyno)',
		'simple'	=> 'run history command',
		'detail'	=> 'run a command from the history list',
	},
	'x'   => {
		'long'		=> 'execute',
		'handle'	=> 'execute',
		'syntax'	=> 'x sql',
		'simple'	=> 'execute sql command',
		'detail'	=> 'execute a sql command in the target session',
	},
);

=cut

=item help

Print the help listings where I<levl> is one of: 

	h    (simple)

	h h  (detail)
	
	h b  (help for break command etc.)

	$o_oradb->help($levl);

=cut

sub help {
	my $self = shift;
	my $levl = shift || '';

	my $help = '';
	if (grep(/^$levl$/, keys %COMMAND)) {
			$help .= "\tsyntax: $COMMAND{$levl}{syntax}\n\t$COMMAND{$levl}{detail}\n";
	} else {
		$levl = 'simple' unless $levl =~ /^(simple|detail|syntax|handle)$/io;
		my (@help, @left, @right) = ();
		foreach my $grp (sort { $a <=> $b } keys %GROUPS) {
			foreach my $char (@{$GROUPS{$grp}}) {
				# $help .= "\t".($levl ne 'syntax' ? "$char\t" : '')."$COMMAND{$char}{$levl}\n";
				my $myhelp = '    '.($levl ne 'syntax' ? sprintf('%-10s', $char) : '').($COMMAND{$char}{$levl}||'');
				if ($grp =~ /^[13579]$/) {
					push(@left, $myhelp);
				} else {
					push(@right, $myhelp);
				}
			}
		}
		$#left = $#right if $#left < $#right;
		$help = "oradb help:\n\n";
		while (@left) {
			no warnings; # empty right values
			local $^W=0;
			$help .= sprintf('%-45s', shift(@left) || '').shift(@right)."\n";
		}
		$help .= "\n";
	}

	return $help;
}

=item preparse

Return the command via the shortest match possible

	my $command = $o_oradb->preparse($cmd); # (help|he)->h

=cut

sub preparse {
	my $self = shift;
	my $cmd  = shift;
	my $comm = '';

	my @comms = sort keys %COMMAND;
	print "preparsing cmd($cmd) against comms(@comms)\n";

	my $i_cnt = my ($found) = grep(/^$cmd/, @comms);
	if ($i_cnt == 1) {
		$comm = $found;
		print "found($found) comm($comm)\n";
	} else {
		my @longs = sort map { $COMMAND{$_}{long} } keys %COMMAND;
		print "preparsing cmd($cmd) against longs(@longs)\n";
		my $i_cnt = my ($found) = grep(/^$cmd/, @longs);
		if ($i_cnt == 1) {
			$comm = $found;
			print "long($found) comm($comm)\n";
		}
	}
	print "returning comm($comm)\n";
	@comms = ();
	
	return $comm;
}

=item parse

Parse the input command to the appropriate method

	$o_oradb->parse($cmd, $input);

=cut 

sub parse {
	my $self = shift;
	my $cmd  = shift;
	my $input= shift;

	$DB::single=2;
	my $xcmd = $self->preparse($cmd);
	unless (defined($COMMAND{$cmd}{handle})) {
	unless ($self->can($COMMAND{$cmd}{handle})) {
		$self->error("command '$cmd' not understood");
		print $self->help;
	} else {
		my $handler = $COMMAND{$cmd}{handle} || 'help';
		$self->log("cmd($cmd) input($input) handler($handler)") if $DEBUG;
		$DB::single=2;
		my @res = $self->$handler($input);
		$self->log("handler($handler) returned(@res)") if $DEBUG;
		print @res;
	}
	}
}

# =============================================================================
# run and exec methods
# =============================================================================

=item do

Wrapper for oradb->dbh->do() - internally we still use prepare and execute.

	$o_oradb->do($sql);

=cut

sub do {
	my $self = shift;
	my $exec = shift;
	my $i_res;

	$self->log("*** incoming pl/sql: self($self) $exec args(@_)") if $DEBUG;
	my $csr  = $self->dbh->prepare($exec);
	unless ($csr) {
		$self->error("Failed to prepare $exec - $DBI::errstr\n") unless $csr;
	} else {
		eval {
			($i_res) = $csr->execute; # returning 0E0 is true/ok/good
		};

		if ($@) {
			$self->error("Failure: $@ while evaling $exec - $DBI::errstr\n");
		}

		unless ($i_res) {
			$self->error("Failed to execute $exec - $DBI::errstr\n");
		}
	}

	$self->log("do($exec)->res($i_res)") if $DEBUG;
	
	return $self;
}

=item recompile

Recompile these procedure|function|package's for debugging

	$oradb->recompile('xsource');

=cut

sub recompile {
	my $self = shift;
	my $args = shift;
	my @res  = ();

	my @names = split(/\s+/, $args);
	foreach my $name (@names) {
		my %data = $self->unitdata('name'=>$name);
		if ($data{name} && $data{type}) {
				$data{type} =~ s/BODY//;
				my $exec = qq|ALTER $data{type} $data{name} COMPILE Debug|; $exec .= ' BODY' if $data{type} =~ /^PACKAGE|TYPE$/o;
				my @msg = $self->do($exec)->get_msg;
				print (@msg >= 1 ? "$data{name} recompiled\n" : "$data{name} failed recompilation!\n");
				push(@res, @msg);
		}
	}

	return @res;
}

=item synchronize

Synchronize the debug and target sessions

	$o_oradb->synchronize;

=cut

sub xsynchronize {
	my $self = shift;
	my $args = shift;
	my @res  = ();

	print "Synching - once this hangs, execute the code in the target session\n"; 
	print "\t(if this does not hang, (it SHOULD), check the connection (with 'test'), and retry)\n";
	@res = $self->sync;
	$self->{_connect}{synched}++;
	# print "Synched (if we hung - above - setting some breakpoints might be an idea...\n";

	return @res;
}

=item unitdata

Retrieve data for given unit - expects to recieve B<single> record from db!

	%data = $o_oradb->unitdata('name'=>$name, 'type'=>$type, ...);

=cut

sub unitdata {
	my $self = shift;
	my %args = (
		'name'	=> '',
		'type'	=> '',
		'owner'	=> '',
	@_);
	map { $args{$_} = '' unless $args{$_} } keys %args;
	my %res  = ();

	unless ($args{name} =~ /^\w+$/o) { # rjsf
		$self->error("unit name($args{name}) is required");
	} else {
		my $sql = qq#SELECT DISTINCT(name || ':' || type || ':' || owner) FROM all_source 
									WHERE UPPER(name) = UPPER('$args{name}')#;
		$sql .= qq# AND UPPER(type) LIKE UPPER('$args{type}%')# if $args{type};
		my ($data) = my @data = $self->getarow($sql);
		my $input = join(', ', map { $_.'='.$args{$_} } sort keys %args);
		unless (scalar(@data) == 1) {
			$self->error("invalid or unambiguated data found via input($input)");
		} else {
			my ($name, $type, $owner) = split(':', $data);
			unless ($name =~ /^\w+$/o) {
				$self->error("invalid data($data) found via input($input)");
			} else {
				%res = (
					'name'	=> $name, 
					'type'	=> $type,
					'owner'	=> $owner,
				);
				map { $self->{_unit}{lc($_)} = $res{$_} } keys %res;
			} 
		} 
	}

	return %res;
}

=item perl 

Run a chunk of perl 

	$o_oradb->perl($perl);

=cut

sub perl {
		my $self = shift;
		my $perl = shift;
		
		eval $perl;
		if ($@) {
			$self->error("failed perl expression($perl) - $@");
		}
		return "\n";
}

=item shell 

Run a shell command 

	$o_oradb->shell($shellcommand);

=cut

sub shell {
		my $self  = shift;
		my $shell = shift;
		
		system($shell);
		if ($@) {
			$self->error("failed shell command($shell) - $@");
		}
		return "\n";
}

=item sql 

Run a chunk of SQL (select only)

	$o_oradb->sql($sql);

=cut

sub sql {
		my $self = shift;
		my $xsql = shift;
		my @res  = ();

		unless ($xsql =~ /^\s*\w+\s+/io) {
			$self->error("SQL statements only please: <$xsql>");
		} else {
			$xsql =~ s/\s*;\s*$//;
			@res = ($self->getarow($xsql), "\n");
		}

		return @res;
}

=item _run

Run a chunk

	$o_oradb->_run($sql);

=cut

sub _run { # INTERNAL
      my $self = shift;
      my $xsql = shift;

      my $exec = qq#
              BEGIN
                      $xsql;
              END;
      #;

      return $self->do($exec)->get_msg;
}


# =============================================================================
# start debug and target methods
# =============================================================================

=item target

Run the target session

	$o_oradb->target;

=cut

sub target {
	my $self = shift;

	my $dbid = $self->start_target('rfi_oradb_sessionid');
	if ($dbid) {
		ReadMode 0;
		print "orasql> enter a PL/SQL command to debug (debugger session must be running...)\n";
		while (1) {
			print "orasql>";
			chomp(my $input = ReadLine(0));
			$self->log("processing input($input)") if $DEBUG;
			if ($input =~ /^\s*(q\s*|quit\s*)$/io) {
				$self->quit;
			} elsif ($input =~ /^\s*(h\s*|help\s*)$/io) {
				print qq|No help menus for target session - simply enter code to debug (which will un-hang the debug session...)\n|;
				$self->help;
			} else {
				$self->_run($input); 
			}
		}
	}

	return $self;
}

=item start_target 

Get the target session id(given) and stick it in our table (by process_id)

	my $dbid = $oradb->start_target($dbid);

=cut

sub start_target {
	my $self = shift;
	my $dbid = shift;

	if ($self->{_connect}{debugid}) {
		$self->fatal("debug process may not run as a target instance");
	}

	$self->{_connect}{targetpid} = $dbid;
	my $x_res = $self->do('DELETE FROM '.$self->{_config}{table}); # currently we only allow a single session at a time

	my $init = qq#
		DECLARE 
			xret VARCHAR2(32); 
		BEGIN 
			xret := dbms_debug.initialize('$dbid'); 
			-- dbms_debug.debug_on(TRUE, FALSE); -- wait
			dbms_debug.debug_on(TRUE, TRUE); -- immediate
		END;
	#;
	$x_res = $self->do($init);
=pod
	my $ddid = qq#
		BEGIN 
			-- dbms_debug.debug_on(TRUE, FALSE); -- target releases debugger sync-hang by execute 
			-- not certain the second TRUE is fully functional here...
			dbms_debug.debug_on(TRUE, TRUE); -- debugger releases target hang with executes
		END;
		#; # should hang (if 2nd true) unless debugger running
	$x_res = $self->do($ddid);

	# should be autonomous transaction
	my $insert = qq#INSERT INTO $self->{_config}{table} 
           (created, debugpid, targetpid, sessionid, data) 
		VALUES (sysdate, $$, $$, '$dbid', 'xxx'
	)#;
	$x_res = $self->do($insert);

	$x_res = $self->do('COMMIT');
=cut

	$self->log("target started: $dbid") if $DEBUG;

	return $dbid;
}

=item debugger

Run the debugger

	$o_debug->debugger;

=cut

sub debugger {
	my $self = shift;

	my $dbid = $self->start_debug('rfi_oradb_sessionid');
	
	ReadMode 0;
	print "Welcome to the oradb (type h for help)\n";
	my $i_cnt = 0;
	while (1) {
		print "oradb> ";
		chomp(my $input = ReadLine(0)); 
		$self->log("processing command($input)") if $DEBUG;
		$input .= ' ';
		#if ($input =~ /^\s*($COMMANDS)\s+(.*)\s*$/o) {
		if ($input =~ /^\s*(\w+)\s+(.*)\s*$/o) {
			my ($cmd, $args) = ($1, $2); 
			$cmd =~ s/\s+$//; $args =~ s/^\s+//; $args =~ s/\s+$//;
			$self->log("input($input) -> cmd($cmd) args($args)") if $DEBUG;
			my $res = $cmd.' '.$args;
			$HISTORY{++$i_cnt} = $res unless $input =~ /^\s*(.|!.*)\s*$/o || grep(/^$res$/, map { $HISTORY{$_} } keys %HISTORY);
			$self->parse($cmd, $args); # + process
		} else {
			$self->error("oradb> command ($input) not understood");	
		}
	}

	return $self; 
}

=item start_debug

Start the debugger session

	my $i_res = $oradb->start_debug($db_session_id, $pid);

=cut

sub start_debug {
	my $self = shift;
	my $dbid = shift;
	my $pid  = shift;

	# my $x_res = $self->do('UPDATE '.$self->{_config}{table}." SET debugpid = $pid");
	if ($self->{_connect}{targetid}) {
		$self->fatal("target process may not run as a debug instance");
	}
	$self->{_connect}{debugpid} = $dbid;

	# SET serveroutput ON;                  -- done via dbi
	my $x_res = $self->do(qq#ALTER session SET plsql_debug=TRUE#)->get_msg;
	# ALTER session SET plsql_debug = TRUE; -- done per proc.

	my $exec = qq#
		BEGIN 
			dbms_debug.attach_session('$dbid'); 
			dbms_output.put_line('attached');
		END;
	#;

	return $self->do($exec)->get_msg;
}

=item sync

Blocks debug session until we exec in target session

	my $i_res = $oradb->sync;

=cut

sub sync {
	my $self = shift;
	my @res  = ();

=pod rjsf
	my ($tid) = $self->getarow('SELECT targetpid FROM '.$self->{_config}{table}." WHERE debugpid = '".$self->{_debugpid}."'");
	$self->{_targetpid} = $tid;
=cut
	print "Synching - once this hangs, execute the code in the target session\n"; 
	print "\t(if this does not hang, (it SHOULD), check the connection (with 'test'), and retry)\n";
	
	my $exec = qq#
		DECLARE	
			xec     binary_integer;
			runtime dbms_debug.runtime_info;
		BEGIN	
			xec := dbms_debug.synchronize(runtime);
			IF xec = dbms_debug.success THEN
				NULL;
				dbms_output.put_line('...synched ' || runtime.program.name);
			ELSE
				dbms_output.put_line('Error: ' || oradb.errorcode(xec));
			END IF;
		END;
	#;

	my $test  = '';
	my $i_cnt = 0;
	while (1) {
		$i_cnt++;
		@res = $self->do($exec)->get_msg;
		chomp($test = $self->is_running);
		print ".";
		last if ($i_cnt >= $self->{_connect}{syncs} || $test eq 'target is currently running');
		sleep 1;
	}
	$self->{_connect}{synched}++;
	print "\n$test\n";

	return @res;
}

# ============================================================================= 
# b c n s r exec
# =============================================================================

=item execute 

Runs the given statement against the target session

	my $i_res = $oradb->execute($xsql);

=cut

sub execute {
	my $self = shift;
	my $xsql = shift;

	$xsql =~ s/[\s\;]*$//;

	my $exec = qq#
		DECLARE 
			col1 sys.dbms_debug_vc2coll;
			errm VARCHAR2(100);
		BEGIN 
			dbms_debug.execute('BEGIN $xsql; END;', 
				-1, 0, col1, errm); 
			IF (errm IS NOT NULL) THEN
				DBMS_OUTPUT.put_line('Error($xsql): ' || errm);
			END IF;
		END;
	#;

	return $self->do($exec)->get_msg;
}

=item break

Set a breakpoint

	my $i_res = $oradb->break("$i_line $procedurename");

=cut

sub break {
	my $self = shift;
	my $args = shift;
	my @res  = ();

	my ($line, $name) = split(/\s+/, $args);
	# unless ($line =~ /^(\d+|\*)$/o) { <- fuzzy
	unless ($line =~ /^(\d+)$/o) {
		$self->error("must supply a valid line number($line) to set a breakpoint via($args)");
	} else {
	  my $name = $name || $self->{_unit}{name} || '';
		unless ($name =~ /^(\w+)$/o) { 
			$self->error("library unit($name) must be given");
		} else {
			my $exec = qq|
				BEGIN 
					oradb.b('$name', $line); 
				END;
			|;
			@res = $self->do($exec)->get_msg;
		}
	}

	return @res;
}

=item continue 

Continue execution until given breakpoints

	my $i_res = $oradb->continue;

=cut

sub continue {
	my $self = shift;

	my $exec = qq#
		BEGIN 
    	oradb.continue_(dbms_debug.break_any_call);
		END;
	#;

	return $self->do($exec)->get_msg;
}

=item next 

Step over the next line

	my $i_res = $oradb->next;

=cut

sub next {
	my $self = shift;

	my $exec = qq#
		BEGIN 
    	oradb.continue_(dbms_debug.break_next_line);
		END;
	#;

	return $self->do($exec)->get_msg;
}

=item step

Step into the next statement

	my $i_res = $oradb->step;

=cut

sub step {
	my $self = shift;

	my $exec = qq#
		BEGIN 
    	oradb.continue_(dbms_debug.break_any_call);
		END;
	#;

	return $self->do($exec)->get_msg;
}

=item return

Return from the current scope

	my $i_res = $oradb->return;

=cut

sub return {
	my $self = shift;

	my $exec = qq#
		BEGIN 
    	oradb.continue_(dbms_debug.break_return);
		END;
	#;

	return $self->do($exec)->get_msg;
}

# =============================================================================
# runtime_info and source listing methods
# =============================================================================

=item runtime

Print runtime_info via dbms_output

	$oradb->runtime;

=cut

sub runtime {
	my $self = shift;
	my $sep = '-' x 80;
	my @msg = ();

	unless ($self->{_connect}{synched}) {
		$self->error('not running yet');
	} else {
=pod
   info_getStackDepth    CONSTANT PLS_INTEGER := 2;  -- get stack depth
   info_getBreakpoint    CONSTANT PLS_INTEGER := 4;  -- get breakpoint number
   info_getLineinfo      CONSTANT PLS_INTEGER := 8;  -- get program info
   info_getOerInfo       CONSTANT PLS_INTEGER := 32; -- (Probe v2.4)
=cut

	my $exec = qq/
		DECLARE 
			runinfo dbms_debug.runtime_info; 
			xinf BINARY_INTEGER DEFAULT dbms_debug.info_getBreakpoint + dbms_debug.info_getLineinfo + dbms_debug.info_getOerInfo;
			xec  BINARY_INTEGER;
		BEGIN 
			xec := dbms_debug.get_runtime_info(xinf, runinfo);
			IF xec = 0 THEN
				dbms_output.put_line('Runtime Info:');
				dbms_output.put_line('  Name:          ' || runinfo.program.name);
				dbms_output.put_line('  Line:          ' || runinfo.line#);
				dbms_output.put_line('  Owner:         ' || runinfo.program.owner);
				dbms_output.put_line('  Unit:          ' || oradb.libunittype(runinfo.program.libunittype));
				dbms_output.put_line('  Namespace:     ' || oradb.namespace(runinfo.program.namespace));
			ELSE
				dbms_output.put_line('   Error: ' || oradb.errorcode(xec));
			END IF;
		END;
	/;

		@msg = $self->do($exec)->get_msg;
	}

	return @msg >= 1 ? "\n".join("\n", $sep, @msg, $sep)."\n" : '...';
}

   
=item backtrace 

Print backtrace from runtime info via dbms_output

	$o_oradb->backtrace();

=cut

sub backtrace {
	my $self = shift;

	my $exec = qq#
		DECLARE 
			tracing VARCHAR2(2000);
		BEGIN 
			dbms_debug.print_backtrace(tracing); 
			dbms_output.put_line(tracing);
		END;
	#;

	my @msg = $self->do($exec)->get_msg;

	return @msg;
}

=item list_source 

Print source 

	$oradb->list_source('xsource', [PROC|...]);

=cut

sub list_source {
	my $self = shift;
	my $args = shift;
	my @res  = ();

	my ($name, $type) = split(/\s+/, $args); 
	my %data = $self->unitdata('name'=>$name, 'type'=>$type);

	if ($data{name} && $data{type}) {
		my $exec = qq#
			DECLARE
				xsrc VARCHAR2(4000);
				CURSOR src IS
					SELECT line, text FROM all_source WHERE name = '$data{name}' 
					   AND type LIKE '$data{type}%' AND type != 'PACKAGE' ORDER BY name, line;
			BEGIN
				FOR rec IN src LOOP
					xsrc := rec.line || ': ' || rec.text;
					dbms_output.put_line(SUBSTR(xsrc, 1, LENGTH(xsrc) -1));
				END LOOP;
			END;
		#;
		@res = $self->do($exec)->get_msg;
		my $res = join('', @res);
		unless ($res =~ /\w+/o) {
			$self->error("no source($res) found with unit($data{name}) type($data{type})");
		}
	} 

	return @res;
}

=item list_breakpoints

Print breakpoint info

	$oradb->list_breakpoints;

=cut

sub list_breakpoints {
	my $self = shift;

	my $exec = qq/
		DECLARE
    	brkpts dbms_debug.breakpoint_table;
    	i      number;
  	BEGIN	
			dbms_debug.show_breakpoints(brkpts); 
			i := brkpts.first();
			dbms_output.put_line('breakpoints: ');
			while i is not null loop
				dbms_output.put_line('  ' || i || ': ' || brkpts(i).name || ' (' || brkpts(i).line# ||')');
				i := brkpts.next(i);
			end loop;
		END;
	/;

	return $self->do($exec)->get_msg;
}

=pod rjsf
		vanilla version
		DECLARE 
			runinfo dbms_debug.runtime_info; 
      i_before number := 1;
      i_after  number := 99;
      i_width  number := 80;
		BEGIN 
      oradb.print_runtime_info_with_source(runinfo, i_before, i_after, i_width);
		END;
=cut

=item history

Display the command history

	print $o_oradb->history;	

=cut

sub history {
	my $self = shift;

	my @hist = map { "$_: $HISTORY{$_}\n" } sort { $a <=> $b } grep(!/\!/, keys %HISTORY);

	return @hist;
}

=item rerun

Rerun a command from the history list

	$o_oradb->rerun($histno);

=cut

sub rerun {
	my $self = shift;
	my $hist = shift || 0;

	if ($hist =~ /!/o) {
		($hist) = reverse sort { $a <=> $b } keys %HISTORY;
	}
	unless ($HISTORY{$hist} =~ /^(\S+)\s(.*)$/o) {
		$self->error("invalid history key($hist) - try using 'H'");
	} else {
		my ($cmd, $args) = ($1, $2);
		$self->parse($cmd, $args); # + process
	}

	return ();
}

# =============================================================================
# check and ping methods
# =============================================================================

=item info 

Info

	print $oradb->info;

=cut

sub info {
	my $self = shift;

	my $src = $self->{_config}{datasrc} || '';
	$src =~ s/^\w+:\w+://;
	my @src = split(';', $src);
	my %src = map { split('=', $_) } @src;
	my ($probe, $version) = split(/:\s+/, $self->probe_version);
	chomp($version);

	my %data = (
		'host'			=> $src{host},
		'instance'	=> uc($src{sid}),
		'oradb'			=> $Oracle::Debug::VERSION,
		'port'			=> $src{port},
		'user'			=> $self->{_config}{user},
		$probe			=> $version,
	);
	my ($i_max) = sort { $b <=> $a } map { length($_) } keys %data;

	my @res = ("\n", (map { $_.(' 'x($i_max-length($_))).' = '.$data{$_}."\n" } sort keys %data), "\n");

	return @res;
}

=item context

Get and set context info

	my $s_res = $o_oradb->context($name);         # get

	my $s_res = $o_oradb->context($name, $value); # set

=cut

sub context {
	my $self = shift;
	my $args = shift || '';
	my @args = my %args = ();
	my @res  = ();

	my ($i_max) = sort { $b <=> $a } map { length($_) } keys %{$self->{_unit}};

	if (%args = ($args =~ /\G\s*(\w+)\s*=\s*(\w+)/go)) { # set
		foreach (sort sort keys %args) {
			my $call = "_$_";
			push(@res, $_.(' 'x($i_max-length($_))).' = '.$self->$call($args{$_})."\n") if $self->can($call);
		}
	} elsif (@args = ($args =~ /\G\s*(\w+)\s*/go)) {     # get
		foreach (sort @args) {
			my $call = "_$_";
			push(@res, $_.(' 'x($i_max-length($_))).' = '.$self->$call()."\n") if $self->can($call);
		}
	} else {                                             # all
		@res = map { $_.(' 'x($i_max-length($_))).' = '.$self->{_unit}{$_}."\n" } sort keys %{$self->{_unit}};
	}

	return @res;
}

=item probe_version 

Log the Probe version

	print $oradb->probe_version;

=cut

sub probe_version {
	my $self = shift;

	my $exec = qq#
		DECLARE 
			i_maj BINARY_INTEGER; 
			i_min BINARY_INTEGER; 
		BEGIN 
			dbms_debug.probe_version(i_maj, i_min); 
			dbms_output.put_line('probe version: ' || i_maj || '.' || i_min); 
		END;
		#;

	return $self->do($exec)->get_msg;
}

=item test 

Call self_check, ping and is_running

	my $i_ok = $oradb->test();

=cut

sub test {
	my $self = shift;
	my @res  = ();

	push(@res, $self->self_check, $self->ping, $self->is_running);
	
	return @res;
}

=item self_check 

Self->check

	my $i_ok = $oradb->self_check; # 9.2

=cut

sub self_check {
	my $self = shift;

	my $exec = qq#
		BEGIN 
			dbms_debug.self_check(10);
			dbms_output.put_line('checked');
		END;
		#;

	return $self->do($exec)->get_msg;
}

=item ping 

Ping the target process (gives an ORA-error if no target)

	my $i_ok = $oradb->ping; # 9.2

=cut

sub ping {
	my $self = shift;

	my $exec = qq#
		BEGIN 
			dbms_debug.ping();
			dbms_output.put_line('pinged');
		END;
		#;

	return $self->do($exec)->get_msg;
}

=item is_running 

Check the target is still running - ???

	my $i_ok = $oradb->is_running; # 9.2

=cut

sub is_running {
	my $self = shift;

	my $exec = qq#
		BEGIN 
			IF dbms_debug.target_program_running THEN
				dbms_output.put_line('target is currently running');
			ELSE 
				dbms_output.put_line('target is not currently running');
			END IF;
		END;
		#;

	return $self->do($exec)->get_msg;
}

# =============================================================================
# get and put msg methods
# =============================================================================

=item plsql_errstr

Get PL/SQL error string

	$o_debug->plsql_errstr;

=cut

sub plsql_errstr {
	my $self  = shift;

	return $self->dbh->func('plsql_errstr');
}

=item put_msg 

Put debug message info

	$o_debug->put_msg($msg);

=cut

sub put_msg {
	my $self  = shift;

	return $self->dbh->func(@_, 'dbms_output_put');
}

=item get_msg 

Get debug message info

	print $o_debug->get_msg;

=cut

sub get_msg {
	my $self  = shift;

	my @msg = (); {
		no warnings;
		@msg = grep(/./, $self->dbh->func('dbms_output_get'));
	}

	return (@msg >= 1 ? join("\n", @msg)."\n" : "\n"); 
}

=item value

Get and set the value of a variable, in a procedure, or in a package

	my $val = $o_oradb->value($name);

	my $val = $o_oradb->value($name, $value);

=cut

sub value {
	my $self = shift;
	my $args = shift || '';
	my @res  = ();

	my ($var, $getset) = ('', '', '');

	if ($args =~ /^\s*(\w[\.\w]*)\s*:{0,1}=\s*(\S.+)?\s*$/o) {	# set
		$var = "$1 := $2;";
		$getset = '_set_val';
	} elsif ($args =~ /^\s*(\w[\.\w]*)\s*$/) {        					# get
		$var = $1;
		$getset = '_get_val';
	} else {																							# err
		$self->error("unable to get or set variable - incorrect syntax: v $args");
	}

	if ($getset) {
		@res = $self->$getset($var);
	}

	return @res;
}

=item _get_val

Get the value of a variable

	my $val = $o_debug->_get_val($varname);

=cut

sub _get_val {
	my $self = shift;
	my $xvar = shift;

	my $exec = qq#
		DECLARE
			program dbms_debug.program_info;
			runinfo dbms_debug.runtime_info; 
			xinf BINARY_INTEGER DEFAULT dbms_debug.info_getBreakpoint + dbms_debug.info_getLineinfo + dbms_debug.info_getOerInfo;
			xec  BINARY_INTEGER;
			buff   VARCHAR2(500);
		BEGIN
			xec := dbms_debug.get_runtime_info(xinf, runinfo);
			IF runinfo.program.namespace = 2 THEN 
				/*
					program := runinfo.program;
	 				program.namespace  := dbms_debug.namespace_pkgspec_or_toplevel; -- as per docs...
					program.Owner      := runinfo.program.owner;
					program.Name       := runinfo.program.name;
					xec := dbms_debug.get_value('$xvar', program, buff, NULL);
				*/
				xec := dbms_debug.get_value('$xvar', 0, buff, NULL);
			ELSE
				xec := dbms_debug.get_value('$xvar', 0, buff, NULL);
			END IF; 
			IF xec = dbms_debug.success THEN
				dbms_output.put_line('$xvar = ' || buff);
			ELSE
				dbms_output.put_line('Error: ' || oradb.errorcode(xec));
			END IF;
		END;
	#;

	my @res = $self->do($exec)->get_msg;

	return @res;
}

=item _set_val

Set the value of a variable

	my $val = $o_debug->_set_val($xset);

=cut

sub _set_val {
	my $self = shift;
	my $xset = shift;

	# $self->error("unimplemented");

	my $exec = qq#
		DECLARE
			xec BINARY_INTEGER;
		BEGIN
			xec := dbms_debug.set_value(0, '$xset');

			IF xec = dbms_debug.success THEN
				dbms_output.put_line('$xset succeeded');
			ELSE
				dbms_output.put_line('Error: ' || oradb.errorcode(xec));
			END IF;
		END;
	#;
	
	my @res = $self->do($exec)->get_msg;

	return @res;
}

=item audit 

Get auditing info

	my ($audsid) = $o_debug->audit;

=cut

sub audit {
	my $self  = shift;

	my $sql   = qq#
		SELECT audsid || '-' || sid || '-' || osuser || '-' || username FROM v\$session WHERE audsid = userenv('SESSIONID')
	#;

	my ($res) = $self->dbh->selectrow_array($sql);

	$self->error("failed to audit: $sql $DBI::errstr") unless $res;

	return $res." $$";
}

# =============================================================================
# get and put context methods
# =============================================================================

=item _check

Return whether or not the given PLSQL target has a value of some sort

	my $i_ok = $o_oradb->_check('unit');

=cut

sub _check {
	my $self = shift;
	my $targ = lc(shift);
	my $i_ok = 0;
	
	unless ($targ =~ /^\w+$/o) {
		$self->error("require a valid plsql target($targ) to check: ".join(', ', sort keys %{$self->{_unit}}));
	} else {
		$i_ok++ if $self->{_unit}{$targ} =~ /./o;
	}

	return $i_ok;
}

=item _unit

Get and set B<unit> name for all consequent actions

	$o_oradb->_unit;        # get

	$o_oradb->_unit($name); # set

=cut

sub _unit {
	my $self = shift;
	my $args = shift || $self->{_unit}{name} || '';

	unless ($args =~ /^\s*(\w+)\s*$/o) {
		$self->error("valid alphanumeric unit($args) is required");
	} else {
		$self->{_unit}{name} = uc($args);
	}
	
	$self->{_unit}{name};
}

=item _type 

Get and set B<type> for all consequent actions

	$o_oradb->_type;        # get

	$o_oradb->_type($type); # set

=cut

sub _type {
	my $self = shift;
	my $args = shift || $self->{_unit}{type} || '';

	my $xx = uc(substr($args, 0, 2));
	unless ($TYPES{$xx} =~ /^(\w+)$/o) {
		$self->error("invalid type($args) - the following are allowed: ".join(', ', sort VALUES %TYPES));
	} else {
		$self->{_unit}{type} = uc($1);
	}
	
	$self->{_unit}{type};
}

=item _namespace

Get and set B<unit> namespace for all consequent actions

	$o_oradb->_namespace;         # get

	$o_oradb->_namespace($space); # set

=cut

sub _namespace {
	my $self = shift;
	my $args = shift || $self->{_unit}{namespace} || '';

	my $xx = uc(substr($args, 0, 2));
	unless ($NAMESPACES{$xx} =~ /^(\w+)$/o) {
		$self->error("invalid namespace($args) - the following are allowed: ".join(', ', sort VALUES %NAMESPACES));
	} else {
		$self->{_unit}{namespace} = uc($1);
	}
	
	return $self->{_unit}{namespace};
}

=item _owner

Get and set B<unit> owner for all consequent actions

	$o_oradb->_owner;        # get

	$o_oradb->_owner($user); # set

=cut

sub _owner {
	my $self = shift;
	my $args = shift || $self->{_unit}{owner} || '';

	unless ($args =~ /^\s*(\w+)\s*$/o) {
		$self->error("valid alphanumeric owner($args) is required");
	} else {
		$self->{_unit}{owner} = uc($1);
	}
	
	return $self->{_unit}{owner};
}

# =============================================================================
# error, log and cleanup methods
# =============================================================================

=item feedback 

Feedback handler (currently just prints to STDOUT)

	$o_debug->feedback("this");

=cut

sub feedback {
	my $self = shift;
	my $msgs = join(' ', @_);
	print STDOUT 'ORADB> '."$msgs\n";
	return $msgs;
}

=item log 

Log handler (currently just prints to STDERR)

	$o_debug->log("this");

=cut

sub log {
	my $self = shift;
	my $msgs = join(' ', @_);
	print STDERR 'oradb: '."$msgs\n";
	return $msgs;
}

=item quit

Quit the debugger

	$o_oradb->quit;

=cut

sub quit {
	my $self = shift;
	$self->abort();
	print "oradb detaching...\n";
	# $self->detach;
	exit;
}

=item error 

Error handler

=cut

sub error {
	my $self = shift;
	$DB::errstr = $DB::errstr;
	my $errs = join(' ', 'Error:', @_).($DB::errstr || '')."\n";
	print $errs;
	# carp($errs);
	return $errs;
}

=item fatal

Fatal error handler

=cut

sub fatal {
	my $self = shift;
	croak(ref($self).' FATAL ERROR: ', @_);
}

=item abort 

Tell the target session to abort the currently running program

	$o_debug->abort;

=cut

sub abort {
	my $self = shift;

	my $exec = qq#
		DECLARE 
			runinfo dbms_debug.runtime_info; 
			ret BINARY_INTEGER;
		BEGIN 
    	-- oradb.continue_(dbms_debug.abort_execution);
    	ret := dbms_debug.continue(runinfo, dbms_debug.abort_execution, 0);
		END;
	#;

	$self->do($exec)->get_msg;
}


=item detach

Tell the target session to detach itself

	$o_debug->detach;

=cut

sub detach {
	my $self = shift;

	my $exec = qq#
		BEGIN 
			dbms_debug.detach_session; 
		END;
	#;
	$self->do($exec)->get_msg;

	# autonomous transaction
	# $self->do('DELETE FROM '.$self->{_config}{table});
	# $self->do('COMMIT');
}

sub DESTROY {
	my $self = shift;
	my $dbh  = $self->{_dbh}->{$$};
	if (ref($dbh)) {
		$dbh->disconnect;
	}
}

1;

=back

=head1 SEE ALSO

DBD::Oracle

perldebug

=head1 AUTHOR

Richard Foley, E<lt>Oracle_Debug@rfi.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Richard Foley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

