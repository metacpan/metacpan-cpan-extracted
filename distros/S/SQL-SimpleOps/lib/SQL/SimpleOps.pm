## ABSTRACT SQL Simple Operations Commands
#
## LICENSE AND COPYRIGHT
# 
## Copyright (C) Carlos Celso
# 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
# 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
#
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see L<http://www.gnu.org/licenses/>.
#
	package SQL::SimpleOps;

	use 5.006001;
	use strict;
	use warnings;
	use Exporter;

	use DBI;
	use File::Spec;

	## dynamic modules

	## option configfile=
	##	JSON

	## option driver=[drivername]
	##	SQL::SimpleOps::[interface]::[driver]

	## option message_log=1 (used as "required")
	##	Sys::Syslog

	## option sql_save=1 (used as "required")
	##	Calc::Date
	##	File::Path
	##	IO::File

################################################################################
## global initialization

	our @ISA = qw ( Exporter );

	our @EXPORT = qw(
		new
		Open Select SelectCursor Delete Insert
		Update Commit Close Call Wait SelectSubQuery
		getDBH getMessage getRC getRows
		getLastCursor getLastSQL getLastSave getWhere
		getAliasTable getAliasCols
		setDumper

		SQL_SIMPLE_ALIAS_INSERT
		SQL_SIMPLE_ALIAS_UPDATE
		SQL_SIMPLE_ALIAS_DELETE
		SQL_SIMPLE_ALIAS_SELECT
		SQL_SIMPLE_ALIAS_WHERE
		SQL_SIMPLE_ALIAS_GROUPBY
		SQL_SIMPLE_ALIAS_ORDERBY

		SQL_SIMPLE_CURSOR_BACK
		SQL_SIMPLE_CURSOR_NEXT
		SQL_SIMPLE_CURSOR_TOP
		SQL_SIMPLE_CURSOR_LAST
		SQL_SIMPLE_CURSOR_RELOAD

		SQL_SIMPLE_ORDER_OFF
		SQL_SIMPLE_ORDER_ASC
		SQL_SIMPLE_ORDER_DESC

		SQL_SIMPLE_CMD_OFF
		SQL_SIMPLE_CMD_ON
		SQL_SIMPLE_CMD_ALL

		SQL_SIMPLE_LOG_OFF
		SQL_SIMPLE_LOG_STD
		SQL_SIMPLE_LOG_SYS
		SQL_SIMPLE_LOG_ALL

		SQL_SIMPLE_RC_SYNTAX
		SQL_SIMPLE_RC_OK
		SQL_SIMPLE_RC_ERROR
		SQL_SIMPLE_RC_EMPTY

		$VERSION
		$errstr
		$err
	);

	our $VERSION = "2023.362.1";

	our @EXPORT_OK = @EXPORT;

	our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

################################################################################
## literals initialization

	use constant SQL_SIMPLE_ALIAS_INSERT => 1;
	use constant SQL_SIMPLE_ALIAS_UPDATE => 2;
	use constant SQL_SIMPLE_ALIAS_DELETE => 4;
	use constant SQL_SIMPLE_ALIAS_SELECT => 8;
	use constant SQL_SIMPLE_ALIAS_WHERE => 16;
	use constant SQL_SIMPLE_ALIAS_GROUPBY => 32;
	use constant SQL_SIMPLE_ALIAS_ORDERBY => 64;
	use constant SQL_SIMPLE_ALIAS_FQDN => 32768;

	use constant SQL_SIMPLE_CURSOR_TOP => 1;	# page first
	use constant SQL_SIMPLE_CURSOR_BACK => 2;	# page backward
	use constant SQL_SIMPLE_CURSOR_NEXT => 3;	# page next
	use constant SQL_SIMPLE_CURSOR_LAST => 4;	# page last
	use constant SQL_SIMPLE_CURSOR_RELOAD => 5;	# page current

	use constant SQL_SIMPLE_ORDER_OFF => undef;	# order disabled
	use constant SQL_SIMPLE_ORDER_ASC => "ASC";	# order asceding
	use constant SQL_SIMPLE_ORDER_DESC => "DESC";	# order descending

	use constant SQL_SIMPLE_CMD_OFF => 0;		# sql_save disabled
	use constant SQL_SIMPLE_CMD_ON => 1;		# sql_save update
	use constant SQL_SIMPLE_CMD_ALL => 2;		# sql_save read/update

	use constant SQL_SIMPLE_LOG_OFF => 0;		# log disabled
	use constant SQL_SIMPLE_LOG_SYS => 1;		# log syslog
	use constant SQL_SIMPLE_LOG_STD => 2;		# log stderr
	use constant SQL_SIMPLE_LOG_ALL => 3;		# log stderr/syslog

	use constant SQL_SIMPLE_RC_SYNTAX => -1;	# syntax error
	use constant SQL_SIMPLE_RC_OK => 0;		# sql successul
	use constant SQL_SIMPLE_RC_ERROR => 1;		# sql error
	use constant SQL_SIMPLE_RC_EMPTY => 2;		# sql successul, empty

	our $SQL_SIMPLE_CURSOR_ORDER =
	{
		1 => SQL_SIMPLE_ORDER_ASC,	# top
		2 => SQL_SIMPLE_ORDER_DESC,	# last
		3 => SQL_SIMPLE_ORDER_ASC,	# next
		4 => SQL_SIMPLE_ORDER_DESC,	# last
		5 => SQL_SIMPLE_ORDER_ASC,	# reload
	};

################################################################################
## local environments
	
	our $SQL_SIMPLE_CLASS = "SQL::SimpleOps";

	our %SQL_SIMPLE_TABLE_OF_MSGS =
	(
		"001" => { T=>"E", M=>"[%s] Database is missing" },
		"002" => { T=>"E", M=>"[%s] Server is missing" },
		"003" => { T=>"E", M=>"[%s] Interface invalid" },
		"004" => { T=>"S", M=>"[%s] The Database driver is omitted or empty" },
		"005" => { T=>"E", M=>"[%s] Table is missing or invalid" },
		"006" => { T=>"E", M=>"[%s] Table invalid, must be single-value or array" },
		"007" => { T=>"E", M=>"[%s] Fields invalid, must be array" },
		"008" => { T=>"E", M=>"[%s] Group_by invalid, must be single-value or array" },
		"009" => { T=>"E", M=>"[%s] Order_by invalid, must be single-value or array-pairs" },
		"010" => { T=>"E", M=>"[%s] Field '%s' not mapped in table list" },
		"011" => { T=>"E", M=>"[%s} Stat File error, %s" },
		"012" => { T=>"I", M=>"[%s] Key not found" },
		"013" => { T=>"E", M=>"[%s] Cursor is missing or invalid" },
		"014" => { T=>"E", M=>"[%s] Cursor Key is missing or invalid" },
		"015" => { T=>"E", M=>"[%s] Cursor Command invalid" },
		"016" => { T=>"W", M=>"[%s] Key is missing, option 'force' is required" },
		"017" => { T=>"E", M=>"[%s] Fields is missing" },
		"018" => { T=>"E", M=>"[%s] Fields Format error, must be hash-pairs or arrayref" },
		"019" => { T=>"E", M=>"[%s] Interface '%s::%s' missing" },
		"020" => { T=>"E", M=>"[%s] Where Clause invalid" },
		"021" => { T=>"E", M=>"[%s] Where invalid, must be single-value or array" },
		"022" => { T=>"E", M=>"[%s] Database is not open" },
		"023" => { T=>"E", M=>"[%s] SQL Command is missing" },
		"024" => { T=>"E", M=>"[%s] Buffer Type invalid, must be hashref, arrayref, scalaref or callback_ref" },
		"025" => { T=>"S", M=>"[%s] Make Folder error, %s" },
		"026" => { T=>"S", M=>"[%s] Open File error, %s" },
		"027" => { T=>"S", M=>"[%s] Values is missing" },
		"028" => { T=>"E", M=>"[%s] Table/Field Value invalid, must be single-value or array" },
		"029" => { T=>"E", M=>"[%s] TCP Port invalid, must be numeric and between 1-65536" },
		"030" => { T=>"E", M=>"[%s] Aliass Table is not a hashref" },
		"031" => { T=>"E", M=>"[%s] Aliases '%s' invalid, table_cols must be hashref" },
		"032" => { T=>"E", M=>"[%s] Aliases '%s' invalid, table_cols invalid format" },
		"033" => { T=>"E", M=>"[%s] Table '%s' already, there can be only one" },
		"034" => { T=>"E", M=>"[%s] Aliases '%s' invalid, table_name is missing" },
		"035" => { T=>"S", M=>"[%s] Interface '%s::%s' error, %s" },
		"036" => { T=>"S", M=>"[%s] Interface '%s::%s' load error" },
		"037" => { T=>"S", M=>"[%s] Interface '%s::%s' aborted, %s" },
		"038" => { T=>"E", M=>"[%s] Syslog Facility invalid, must be 'local0' to 'local7'" },
		"039" => { T=>"E", M=>"[%s] Syslog Service invalid, must contains 'alphanumeric' characters" },
		"040" => { T=>"E", M=>"[%s] Log File invalid, must contains 'alphanumeric' characters" },
		"041" => { T=>"E", M=>"[%s] Values Format error, must be arrayref" },
		"042" => { T=>"E", M=>"[%s] Conflict/Duplicate Format error, must be hashref" },
		"043" => { T=>"E", M=>"[%s] Limit is missing" },
		"044" => { T=>"E", M=>"[%s] Buffer hashkey invalid, buffer is not hashref" },
		"045" => { T=>"E", M=>"[%s] Buffer hashkey not mapped" },
		"046" => { T=>"E", M=>"[%s] Buffer hashkey must be scalaref or arrayref" },
		"047" => { T=>"E", M=>"[%s] Buffer arrayref Off not allowed for multiple field list" },
		"048" => { T=>"E", M=>"[%s] Buffer hashindex must be arrayref" },
		"049" => { T=>"E", M=>"[%s] Cursor_order invalid" },
		"099" => { T=>"S", M=>"[%s] %s" },
	);

	our $errstr = "";	# last message
	our $err = 0;		# last return code

	1;

################################################################################
## action: create object
## return:
##	null	falure to loaded, system error
##	bless	is successful loaded

sub new()
{
	my $class = shift; $class = ref($class) || $class || $SQL_SIMPLE_CLASS;
	my $self = {};

	$self->{argv} = {@_};

	## checking for configfile
	if (defined($self->{argv}{configfile}))
	{
		if (!stat($self->{argv}{configfile}))
		{
			&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"011",$self->{argv}{configfile});
			return undef;
		}
		my $fh = new IO::File($self->{argv}{configfile});
		if (!defined($fh))
		{
			&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"026",$!);
			return undef;
		}
		require JSON;
		my $st; while (!$fh->eof) { $st .= <$fh>; }; undef($fh);
		my $pt = new JSON(); $self->{argv} = $pt->decode($st); undef($pt);
	}

	## defaults
	$self->{argv}{interface} = "dbi" if (!defined($self->{argv}{interface}));
	$self->{argv}{quote} = "'" if (!defined($self->{argv}{quote}));
	$self->{argv}{connect} = 1 if (!defined($self->{argv}{connect}));
	$self->{argv}{message_log} = SQL_SIMPLE_LOG_STD if (!defined($self->{argv}{message_log}));
	$self->{argv}{port} = "" if (!defined($self->{argv}{port}));

	## check interfaces
	if (!grep(/^$self->{argv}{interface}$/i,"dbi"))
	{
		&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"003");
		return undef;
	}

	## check driver
	if (!defined($self->{argv}{driver}) || $self->{argv}{driver} eq "")
	{
		&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"004");
		return undef;
	}

	## check database
	if (!defined($self->{argv}{db}) || $self->{argv}{db} eq "")
	{
		&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"001");
		return undef;
	}

	## check aliases table
	if (defined($self->{argv}{tables}))
	{
		if (ref($self->{argv}{tables}) ne "HASH")
		{
			&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"030");
			return undef;
		}
		foreach my $table(keys(%{$self->{argv}{tables}}))
		{
			if (!defined($self->{argv}{tables}{$table}{name}) || $self->{argv}{tables}{$table}{name} eq "")
			{
				&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"034",$table);
				return undef;
			}
			if (defined($self->{init}{table_realname}{$self->{argv}{tables}{$table}{name}}))
			{
				&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"034",$table);
				return undef;
			}
			if (defined($self->{argv}{tables}{$self->{argv}{tables}{$table}{name}}))
			{
				&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"034",$table);
				return undef;
			}
			$self->{init}{table_realname}{$self->{argv}{tables}{$table}{name}} = $table;
			if (defined($self->{argv}{tables}{$table}{cols}))
			{
				if (ref($self->{argv}{tables}{$table}{cols}) ne "HASH")
				{
					&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"031",$table);
					return undef;
				}
				my $myTable = $self->{argv}{tables}{$table}{name};
				foreach my $field(keys(%{$self->{argv}{tables}{$table}{cols}}))
				{
					if ($self->{argv}{tables}{$table}{cols}{$field} eq "")
					{
						&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"032",$field);
						return undef;
					}
					push(@{$self->{init}{fields_xref}{$field}},[$table,$self->{argv}{tables}{$table}{cols}{$field}]);
				}
			}
		}
	}

	## check syslog options
	if (defined($self->{argv}{message_syslog_facility}) && !($self->{argv}{message_syslog_facility} =~ /^local[0-7]$/i))
	{
		&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"038",$self->{argv}{message_syslog_facility});
		return undef;
	}
	if (defined($self->{argv}{message_syslog_service}) && ($self->{argv}{message_syslog_service} =~ s/[a-zA-Z0-9\-\_]//g))
	{
		&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"039",$self->{argv}{message_syslog_service});
		return undef;
	}
	if (defined($self->{argv}{sql_save_name}) && ($self->{argv}{sql_save_name} =~ s/[a-zA-Z0-9\-\_]//g))
	{
		&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"040",$self->{argv}{sql_save_name});
		return undef;
	}

	## interface defaults values
	$self->{argv}{interface} = uc($self->{argv}{interface});
	$self->{argv}{interface_options}{RaiseError} = 0 if (!defined($self->{argv}{interface_options}{RaiseError}));
	$self->{argv}{interface_options}{PrintError} = 0 if (!defined($self->{argv}{interface_options}{PrintError}));

	## standards plugins
	if	(grep(/^$self->{argv}{driver}$/i,"mysql","mariadb"))			{$self->{init}{plugin_id} = "MySQL";}
	elsif	(grep(/^$self->{argv}{driver}$/i,"pg","postgres","postsql","pgsql"))	{$self->{init}{plugin_id} = "PG";}
	elsif	(grep(/^$self->{argv}{driver}$/i,"sqlite","sqlite3"))			{$self->{init}{plugin_id} = "SQLite";}
	else										{$self->{init}{plugin_id} = $self->{argv}{driver};}

	## load pluging
	my $fn;
	my $plugin = $SQL_SIMPLE_CLASS."::".$self->{argv}{interface}."::".$self->{init}{plugin_id};
	foreach my $dir(@INC)
	{
		$fn = File::Spec->catdir($dir,split(/::/,$plugin)).".pm";
		last if (stat($fn));
		$fn = "";
	}
	if ($fn eq "")
	{
		&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"019",$self->{argv}{interface},$self->{init}{plugin_id});
		return undef;
	}
	eval { require $fn; };
	if ($@)
	{
		&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"035",$self->{argv}{interface},$self->{init}{plugin_id},$@);
		return undef;
	}
	$self->{init}{plugin_fh} = $plugin->new(sql_simple => $self);
	if (!defined($self->{init}{plugin_fh}))
	{
		&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"035",$self->{argv}{interface},$self->{init}{plugin_id},$@);
		return undef;
	}

	## test server, the 'test_server' env must be defined on plugin
	if ($self->{init}{test_server})
	{
		if ($self->{argv}{server} eq "")
		{
			&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"002");
			return undef;
		}
		if ($self->{argv}{port} ne "" && (($self->{argv}{port} =~ /^\D+$/) || ($self->{argv}{port} < 1 || $self->{argv}{port} > 65535)))
		{
			&_setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"029");
			return undef;
		}
	}

	## new object
	my $bless = bless($self,$class);
	return undef if (!defined($bless));

	## my first connect
	return undef if ($self->{argv}{connect} && $self->Open());

	## successful
	return $bless;
}

################################################################################
## action: open database
## return:
##	rc<0	syntax error
##	rc=0	successful
##	rc>0	sql return code

sub Open()
{
	my $self = shift;

	$self->_resetSession();
	if ($self->{init}{plugin_fh}->can('Open') && $self->{init}{plugin_fh}->Open())
	{
		$self->_setMessage("open",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if ($self->{argv}{interface} =~ /^dbi$/i)
	{
		$self->{init}{dbh} = DBI->connect($self->{argv}{dsname},  $self->{argv}{login}, $self->{argv}{password}, \%{$self->{argv}{interface_options}});
		$self->_setMessage("open");
		return $self->getRC();
	}
	return SQL_SIMPLE_RC_SYNTAX;
}

################################################################################
## action: create select command to inject as subquery
## return:
##	rc<0 syntax error
##	rc=0 returns SQL STRING COMMAND
##	rc=1 sql error
##	rc=2 successful, no lines selected (no match or empty)

sub SelectSubQuery()
{
	my $self = shift;
	my $argv = {@_};

	$argv->{subquery} = 1;

	return $self->Select(%{$argv});
}

################################################################################
## action: select as fetch command, buffers of lines based cursor
## return:
##	rc<0 syntax error
##	rc=0 successful
##	rc=1 sql error
##	rc=2 successful, no lines selected (no match or empty)

sub SelectCursor()
{
	my $self = shift;
	my $argv = {@_};

	$self->_resetSession();
	$self->_Dumper("selectcursor",$argv);
	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{work}{command} = SQL_SIMPLE_ALIAS_SELECT;

	if ($self->{init}{plugin_fh}->can('SelectCursor') && $self->{init}{plugin_fh}->SelectCursor($argv))
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_message_log = $self->_setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->_setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->_setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_SelectCursor(%{$argv});

	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->_setQuote($saved_quote) if (defined($argv->{quote}));
	$self->_setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _SelectCursor()
{
	my $self = shift;
	my $argv = {@_};

	## validate cursor-key
	if	(!defined($argv->{cursor_key}))		{ @{$self->{work}{cursor_key}} = []; }
	elsif	(ref($argv->{cursor_key}) eq "")	{ @{$self->{work}{cursor_key}} = ($argv->{cursor_key}); }
	elsif	(ref($argv->{cursor_key}) eq "ARRAY")	{ @{$self->{work}{cursor_key}} = @{$argv->{cursor_key}}; }
	else
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"014");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## validate cursor, must be similar type of cursor-key
	if	(!defined($argv->{cursor})) {}
	elsif	(ref($argv->{cursor}) eq "" && @{$self->{work}{cursor_key}} == 1) {}
	elsif	(ref($argv->{cursor}) eq "ARRAY" && $self->{work}{cursor_key} == @{$argv->{cursor}}+0) {}
	else
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"013");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## enforce cursor as top if missed
	$argv->{cursor_command} = SQL_SIMPLE_CURSOR_TOP if (!defined($argv->{cursor_command}) || $argv->{cursor_command} eq "");

	if ($argv->{cursor_command} != SQL_SIMPLE_CURSOR_TOP && $argv->{cursor_command} != SQL_SIMPLE_CURSOR_LAST)
	{
		## if im not using cursor the cursor_info is required
		if (!defined($argv->{cursor}) || $argv->{cursor} eq "")
		{
			if (!defined($argv->{cursor_info}))
			{
				$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"013");
				return SQL_SIMPLE_RC_SYNTAX;
			}

			## getting the last and first cursors
			my ($first,$last);
			if	(ref($argv->{cursor_info}) eq "HASH")
			{
				($first,$last) = ($argv->{cursor_info}{first},$argv->{cursor_info}{last});
			}
			elsif	(ref($argv->{cursor_info}) eq "ARRAY")
			{
				($first,$last) = ($argv->{cursor_info}[2],$argv->{cursor_info}[3]);
			}
			elsif	(ref($argv->{cursor_info}) eq "SCALAR")
			{
				## scalar cursor_info mismatch with multiple keys
				if (@{$self->{work}{cursor_key}} > 1)
				{
					$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"013");
					return SQL_SIMPLE_RC_SYNTAX;
				}
				my @a=split(" ",$argv->{cursor_info}); ($first,$last) = ($a[2],$a[3]);
			}
			else
			{
				$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"013");
				return SQL_SIMPLE_RC_SYNTAX;
			}

			## adjusting cursor if cursor_key is array
			if (ref($argv->{cursor_key}) eq "ARRAY")
			{
				$first = [] if (ref($first) ne "ARRAY");
				$last = [] if (ref($last) ne "ARRAY");
			}

			## adjusting cursor
			if	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_NEXT)
			{
				$argv->{cursor} = $last;
				$argv->{cursor_command} = SQL_SIMPLE_CURSOR_TOP if (!defined($last));
			}
			elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_BACK)
			{
				$argv->{cursor} = $first;
				$argv->{cursor_command} = SQL_SIMPLE_CURSOR_LAST if (!defined($first));
			}
			elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_RELOAD)
			{
				$argv->{cursor} = $first;
			}
		}
		
		## enforce rerun last command if exists and request is reload
		if ($argv->{cursor_command} == SQL_SIMPLE_CURSOR_RELOAD)
		{
			$self->{work}{cursor_command_reload} = 1;
			if	(ref($argv->{cursor_info}) eq "HASH")
			{
				$argv->{cursor_command} = $argv->{cursor_info}{previouscmd} if (defined($argv->{cursor_info}{previouscmd}));
			}
			elsif	(ref($argv->{cursor_info}) eq "ARRAY")
			{
				$argv->{cursor_command} = $argv->{cursor_info}[ @{$argv->{cursor_info}}-1 ] if (@{$argv->{cursor_info}} >= 5);
			}
			else
			{
				my @a = split(" ",$argv->{cursor_info});
				my $b = (@{$self->{work}{cursor_key}} < 2) ? 2 : @{$self->{work}{cursor_key}} * 2;
				$argv->{cursor_command} = $a[@a-1] if (@a > (2 + $b));
			}
		}
	}

	## validade where
	if (defined($argv->{where}) && ref($argv->{where}) ne "ARRAY")
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"021");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## have order by?
	my @order;
	if	(!defined($argv->{order_by})) {}
	elsif	(ref($argv->{order_by}) eq "ARRAY") { @order = @{$argv->{order_by}}; }
	elsif	(ref($argv->{order_by}) eq "HASH") { @order = ($argv->{order_by}); }
	elsif	(ref($argv->{order_by}) eq "") { @order = ($argv->{order_by}); }
	else
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"009");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## test the type of cursor and adjust where clause
	if	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_TOP)
	{
		my @o;
		foreach my $key( (ref($argv->{cursor_key}) eq "ARRAY") ? @{$argv->{cursor_key}} : $argv->{cursor_key} )
		{
			push(@o,{$key => SQL_SIMPLE_ORDER_ASC});
		}
		unshift(@order,@o);
	}
	elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_BACK)
	{
		my $oper = ($self->{work}{cursor_command_reload}) ? "<=" : "<";
		if (ref($argv->{cursor_key}) ne "ARRAY")
		{
			unshift(@order,{$argv->{cursor_key} => SQL_SIMPLE_ORDER_DESC});
			unshift(@{$argv->{where}}, $argv->{cursor_key} => [ $oper, $argv->{cursor} ]);
		}
		else
		{
			my @w;
			my @o;
			for (my $i=0; $i < @{$argv->{cursor_key}}; $i++)
			{
				push(@o,{$argv->{cursor_key}[$i] => SQL_SIMPLE_ORDER_DESC});
				my @s;
				for (my $j=0; $j < $i; $j++)
				{
					push(@s,$argv->{cursor_key}[$j] => $argv->{cursor}[$j]);
				}
				push(@s,$argv->{cursor_key}[$i] => [ $oper, $argv->{cursor}[$i]]);
				push(@w,"or") if (@w);
				push(@w,\@s);
			}
			push(@{$argv->{where}},(@{$argv->{where}}) ? [\@w] : \@w);
			unshift(@order,@o);
		}
	}
	elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_NEXT || $argv->{cursor_command} == SQL_SIMPLE_CURSOR_RELOAD)
	{
		my $oper = ($argv->{cursor_command} == SQL_SIMPLE_CURSOR_RELOAD || $self->{work}{cursor_command_reload}) ? ">=" : ">";
		if (ref($argv->{cursor_key}) ne "ARRAY")
		{
			unshift(@order,{$argv->{cursor_key} => SQL_SIMPLE_ORDER_ASC});
			unshift(@{$argv->{where}}, $argv->{cursor_key} => [ $oper, $argv->{cursor} ]);
		}
		else
		{
			my @w;
			my @o;
			for (my $i=0; $i < @{$argv->{cursor_key}}; $i++)
			{
				push(@o,{$argv->{cursor_key}[$i] => SQL_SIMPLE_ORDER_ASC});
				my @s;
				for (my $j=0; $j < $i; $j++)
				{
					push(@s,$argv->{cursor_key}[$j] => $argv->{cursor}[$j]);
				}
				push(@s,$argv->{cursor_key}[$i] => [ $oper, $argv->{cursor}[$i]]);
				push(@w,"or") if (@w);
				push(@w,\@s);
			}
			push(@{$argv->{where}},(@{$argv->{where}}) ? [\@w] : \@w);
			unshift(@order,@o);
		}
	}
	elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_LAST)
	{
		my @o;
		foreach my $key( (ref($argv->{cursor_key}) eq "ARRAY") ? @{$argv->{cursor_key}} : $argv->{cursor_key} )
		{
			push(@o,{$key => SQL_SIMPLE_ORDER_DESC});
		}
		unshift(@order,@o);
	}
	else
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"015");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	$argv->{order_by} = \@order;

	## validate cursor_order option
	if	(!defined($argv->{cursor_order})) { }
	elsif	($argv->{cursor_order} eq SQL_SIMPLE_ORDER_ASC || $argv->{cursor_order} eq SQL_SIMPLE_ORDER_DESC)
	{
		$self->{work}{cursor_order} = ($argv->{cursor_order} eq $SQL_SIMPLE_CURSOR_ORDER->{$argv->{cursor_command}})+0;
	}
	else
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"049");
		return SQL_SIMPLE_RC_SYNTAX;
	}	

	## validate limits
	if (!defined($argv->{limit}) || $argv->{limit} eq "")
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"043");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## define notfound if not exists
	$argv->{notfound} = 1 if (!defined($argv->{notfound}));

	## execute and save cursor info
	return $self->{init}{cursor}{rc} if ($self->{init}{cursor}{rc} = $self->_Select(%{$argv}));

	$self->{init}{cursor}{lines} = $self->getRows();
	if (!$self->{init}{cursor}{lines})
	{
		$self->{init}{cursor}{first} = [];
		$self->{init}{cursor}{last} = [];
	}

	## return cursor info
	if	(!defined($argv->{cursor_info})) {}
	elsif	(ref($argv->{cursor_info}) eq "HASH")
	{
		$argv->{cursor_info}->{rc} = $self->{init}{cursor}{rc};
		$argv->{cursor_info}->{lines} = $self->{init}{cursor}{lines};

		if ($argv->{cursor_command} == SQL_SIMPLE_CURSOR_BACK || $argv->{cursor_command} == SQL_SIMPLE_CURSOR_LAST)
		{
			$argv->{cursor_info}{first} = (ref($argv->{cursor_key}) eq "ARRAY") ? $self->{init}{cursor}{last} : $self->{init}{cursor}{last}[0];
			$argv->{cursor_info}{last}  = (ref($argv->{cursor_key}) eq "ARRAY") ? $self->{init}{cursor}{first} : $self->{init}{cursor}{first}[0];
		}
		else
		{
			$argv->{cursor_info}{first} = (ref($argv->{cursor_key}) eq "ARRAY") ? $self->{init}{cursor}{first} :$self->{init}{cursor}{first}[0];
			$argv->{cursor_info}{last}  = (ref($argv->{cursor_key}) eq "ARRAY") ? $self->{init}{cursor}{last} : $self->{init}{cursor}{last}[0];
		}
		$argv->{cursor_info}{previouscmd} = $argv->{cursor_command};
	}
	elsif (ref($argv->{cursor_info}) eq "ARRAY")
	{
		$argv->{cursor_info} = [];
		push(@{$argv->{cursor_info}},$self->{init}{cursor}{rc},$self->{init}{cursor}{lines});
		if ($argv->{cursor_command} == SQL_SIMPLE_CURSOR_BACK || $argv->{cursor_command} == SQL_SIMPLE_CURSOR_LAST)
		{
			push(@{$argv->{cursor_info}},(ref($argv->{cursor_key}) eq "ARRAY") ? $self->{init}{cursor}{last} : $self->{init}{cursor}{last}[0]);
			push(@{$argv->{cursor_info}},(ref($argv->{cursor_key}) eq "ARRAY") ? $self->{init}{cursor}{first} : $self->{init}{cursor}{first}[0]);
		}
		else
		{
			push(@{$argv->{cursor_info}},(ref($argv->{cursor_key}) eq "ARRAY") ? $self->{init}{cursor}{first} :$self->{init}{cursor}{first}[0]);
			push(@{$argv->{cursor_info}},(ref($argv->{cursor_key}) eq "ARRAY") ? $self->{init}{cursor}{last} : $self->{init}{cursor}{last}[0]);
		}
		push(@{$argv->{cursor_info}},$argv->{cursor_command});
	}
	elsif (ref($argv->{cursor_info}) eq "SCALAR")
	{
		my @a;
		if ($argv->{cursor_command} == SQL_SIMPLE_CURSOR_BACK || $argv->{cursor_command} == SQL_SIMPLE_CURSOR_LAST)
		{
			push(@a,
				(ref($argv->{cursor_key}) eq "ARRAY") ? join(" ",@{$self->{init}{cursor}{last}}) : $self->{init}{cursor}{last}[0],
				(ref($argv->{cursor_key}) eq "ARRAY") ? join(" ",@{$self->{init}{cursor}{first}}) : $self->{init}{cursor}{first}[0],
			);
		}
		else
		{
			push(@a,
				(ref($argv->{cursor_key}) eq "ARRAY") ? join(" ",@{$self->{init}{cursor}{first}}) : $self->{init}{cursor}{first}[0],
				(ref($argv->{cursor_key}) eq "ARRAY") ? join(" ",@{$self->{init}{cursor}{last}}) : $self->{init}{cursor}{last}[0],
			);
		}
		${$argv->{cursor_info}} = join(" ",$self->{init}{cursor}{rc},$self->{init}{cursor}{lines},@a,$argv->{cursor_command});
	}
	return SQL_SIMPLE_RC_OK;
}

################################################################################
## action: select command
## return:
##	rc<0 syntax error
##	rc=0 successful
##	rc=1 sql error
##	rc=2 no selected found (no match where found)

sub Select()
{
	my $self = shift;
	my $argv = {@_};

	$argv->{make_only} = 1 if ($argv->{subquery});

	$self->_resetSession();
	$self->_Dumper("select",$argv);
	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{work}{command} = SQL_SIMPLE_ALIAS_SELECT;

	if ($self->{init}{plugin_fh}->can('Select') && $self->{init}{plugin_fh}->Select($argv))
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_message_log = $self->_setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->_setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->_setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Select(%{$argv});

	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->_setQuote($saved_quote) if (defined($argv->{quote}));
	$self->_setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return "\\(". ( ($self->getRC()==0) ? $self->getLastSQL() : "**".$self->getMessage()."**" ) .")" if ($argv->{subquery});
	return $rc;
}

sub _Select()
{
	my $self = shift;
	my $argv = {@_};

	return SQL_SIMPLE_RC_SYNTAX if ($self->_checkTablesEntries("select",$argv) != SQL_SIMPLE_RC_OK);

	## testing buffer-hashindex
	if	(!defined($argv->{buffer})){}
	elsif	(ref($argv->{buffer}) ne "HASH"){}
	elsif	(!defined($argv->{buffer_hashkey})){}
	elsif	(!defined($argv->{buffer_hashindex})){}
	elsif	(ref($argv->{buffer_hashindex}) ne "ARRAY")
	{
		$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"048");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## testing fields
	my @fields_work;
	my %fields_distinct;
	my %fields_aliases;
	if (defined($argv->{fields}))
	{
		my $fields_argv;
		if	(ref($argv->{fields}) eq "ARRAY") { $fields_argv = $argv->{fields}; }
		elsif	(ref($argv->{fields}) eq "") { $fields_argv = [ $argv->{fields} ]; }
		else
		{
			$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"007");
			return SQL_SIMPLE_RC_SYNTAX;
		}
		if (@{$fields_argv} != 1 || $fields_argv->[0] ne "*")
		{
			for (my $ix=0; $ix < @{$fields_argv}; $ix++)
			{
				my $field = $fields_argv->[$ix];
				my $distinct;
				my $alias;
				if (ref($field) eq "HASH")
				{
					$alias = $field;
					($fields_aliases{$alias}{f},$fields_aliases{$alias}{a}) = %{$field};
					$field = $fields_aliases{$alias}{f};
					$self->{work}{field_alias}{$fields_aliases{$alias}{a}} = $fields_aliases{$alias}{f};
					$self->{work}{field_realname}{$fields_aliases{$alias}{f}} = $fields_aliases{$alias}{a};
					$self->{work}{field_cols}{$1}{$fields_aliases{$alias}{a}} = $2 if ($fields_aliases{$alias}{f} =~ /^(.*?)\.(.*?)$/);
				}
				if ($field =~ /^distinct$/i)
				{
					$field = $fields_argv->[++$ix];
					$distinct = 1;
				}
				elsif ($field =~ /^distinct\s+(.*)/i)
				{
					$field = $1;
					$distinct = 1;
				}
				if (!($field =~ /^\\/))
				{
					my $value = ($field =~ /^(.*?)\((.*?)\,(.*)\)/) ? $2 : ($field =~ /^(.*?)\((.*)\)/) ? $2 : $field;
					if ($value =~ /^(.*)\.(.*)$/)
					{
						if (!grep(/^$1$/,@{$self->{work}{tables_valids}}))
						{
							$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"010",$field);
							return SQL_SIMPLE_RC_SYNTAX;
						}
					}
				}
				push(@fields_work,$alias || $field);
				$fields_distinct{$field} = 1 if ($distinct);
			}
		}
	}
	elsif (defined($self->{argv}{tables}))
	{
		if (@{$self->{work}{tables_inuse}} > 1)
		{
			my $any=0;
			foreach my $table(@{$self->{work}{tables_inuse}})
			{
				my $temp;
				if (!defined($self->{argv}{tables}{$table}) || !defined($self->{argv}{tables}{$table}{cols}))
				{
					if (!defined($self->{init}{table_realname}{$table}))
					{
						$any=1;
						next;
					}
					$temp = $self->{init}{table_realname}{$table};
				}
				else
				{
					$temp = $table;
				}
				foreach my $field(sort(keys(%{$self->{argv}{tables}{$temp}{cols}})))
				{
					push(@fields_work,$table.".".$field);
				}
			}
			if ($any && @fields_work)
			{
				$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"010","*");
				return SQL_SIMPLE_RC_SYNTAX;
			}
		}
		else
		{
			my $temp = (!defined($self->{init}{table_realname}{$self->{work}{tables_inuse}[0]})) ? $self->{work}{tables_inuse}[0] : $self->{init}{table_realname}{$self->{work}{tables_inuse}[0]};
			if (defined($self->{argv}{tables}{$temp}) && defined($self->{argv}{tables}{$temp}{cols}))
			{
				push(@fields_work,sort(keys(%{$self->{argv}{tables}{$temp}{cols}})));
			}
		}
	}

	## testing groupby
	my @group_work;
	if (defined($argv->{group_by}))
	{
		if	(ref($argv->{group_by}) eq "") { @group_work = ($argv->{group_by}); }
		elsif	(ref($argv->{group_by}) eq "ARRAY") { push(@group_work,@{$argv->{group_by}}); }
		else
		{
			$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"008");
			return SQL_SIMPLE_RC_SYNTAX;
		}
	}
	
	## testing orderby
	my @order_work;
	if (defined($argv->{order_by}))
	{
		if	(ref($argv->{order_by}) eq "") { @order_work = ($argv->{order_by}); }
		elsif	(ref($argv->{order_by}) eq "HASH") { @order_work = ($argv->{order_by}); }
		elsif	(ref($argv->{order_by}) eq "ARRAY")
		{
		       	push(@order_work,@{$argv->{order_by}});
		}
		else
		{
			$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"009");
			return SQL_SIMPLE_RC_SYNTAX;
		}
	}
	
	## making fields
	my $middle = ($self->{init}{alias_with_as}) ? " AS " : " ";
	my @fields;
	my $table = $self->{work}{tables_inuse}[0];
	if (@fields_work)
	{
		foreach my $field(@fields_work)
		{
			my $alias;
			my $distinct = ($fields_distinct{$field}) ? "DISTINCT " : "";
			## field is hash?
			if (defined($fields_aliases{$field}))
			{
				$alias = $fields_aliases{$field}{a};
				$field = $fields_aliases{$field}{f};
			}
			## is escape?
			if ($field =~ /^\\(.*)/)
			{
				($alias) ?
					push(@fields,$distinct.$1.$middle.$alias) :
					push(@fields,$distinct.$1);
				next;
			}
			## have function?
			my $field_a;
			my $field_b;
			if ($field =~ /^(.*?)\((.*?)\,(.*)\)/)
			{
				$field_a = $1."(";
				$field = $2;
				$field_b = ",".$3.")";
			}
			elsif ($field =~ /^(.*?)\((.*)\)/)
			{
				$field_a = $1."(";
				$field = $2;
				$field_b = ")";
			}
			else
			{
				$field_a = "";
				$field_b = "";
			}
			## translate field
			if ($field =~ /^(.*)\.(.*)$/)
			{
				my $realn = $self->_getAliasCols(1,$field,SQL_SIMPLE_ALIAS_SELECT);
				my $table = (!defined($self->{init}{table_realname}{$1})) ? $1 : $self->{init}{table_realname}{$1};
				my $field = $2;
				if ($realn =~  /^.*\..*$/)
				{
					($alias) ?
						push(@fields,$distinct.$field_a.$realn.$field_b.$middle.$alias) :
					($table.".".$field ne $realn) ?
						push(@fields,$distinct.$field_a.$realn.$field_b.$middle.$field) :
						push(@fields,$distinct.$field_a.$realn.$field_b);
				}
				else
				{
					($alias) ?
						push(@fields,$distinct.$field_a.$table.".".$realn.$field_b.$middle.$alias) :
					($field ne $realn) ?
						push(@fields,$distinct.$field_a.$table.".".$realn.$field_b.$middle.$field) :
						push(@fields,$distinct.$field_a.$table.".".$realn.$field_b);
				}
			}
			else
			{
				if (@{$self->{work}{tables_inuse}} == 1)
				{
					my $realn = $self->_getAliasCols(2,$field,SQL_SIMPLE_ALIAS_SELECT);
					($alias) ?
						push(@fields,$distinct.$field_a.$realn.$field_b.$middle.$alias) :
					($field ne $realn) ?
						push(@fields,$distinct.$field_a.$realn.$field_b.$middle.$field) :
						push(@fields,$distinct.$field_a.$field.$field_b);
				}
				else
				{
					if ($alias)
					{
						push(@fields,$distinct.$field.$middle.$alias);
					}
					else
					{
						foreach my $table(@{$self->{work}{tables_inuse}})
						{
							my $realn = $self->_getAliasCols(3,$field,SQL_SIMPLE_ALIAS_SELECT);
							if ($realn ne $field)
							{
								$alias = $field;
								$field = $realn;
								last;
							}
						}
						($alias) ?
							push(@fields,$distinct.$field.$middle.$alias):
							push(@fields,$distinct.$field);
					}
				}
			}
		}
	}
	else
	{
		push(@fields,"*");
	}

	## make where
	my $where;
	return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhere("select",$argv->{where},\$where));

	## make group_by
	for (my $i=0; $i < @group_work; $i++)
	{
		$group_work[$i] = ($group_work[$i] =~ /^(.*)\.(.*)$/) ?
			$self->_getAliasCols(4,$group_work[$i],SQL_SIMPLE_ALIAS_GROUPBY+SQL_SIMPLE_ALIAS_FQDN) :
			$self->_getAliasCols(5,$group_work[$i],SQL_SIMPLE_ALIAS_GROUPBY);
	}

	## make order
	my @order;
	while (@order_work)
	{
		my $field = shift(@order_work);
		if (ref($field) eq "HASH")
		{
			foreach my $_id(sort(keys(%{$field})))
			{
				$self->_SelectOrderBy(\@order,$table,$_id,$field->{$_id});
			}
		}
		else { $self->_SelectOrderBy(\@order,$table,$field); }
	}

	## make tables
	my @tables;
	foreach my $table(@{$self->{work}{tables_inuse}})
	{
		push(@tables,$self->_getAliasTable($table,$argv));
	}

	## build sql command
	my $sql = "SELECT ".join(", ",@fields)." FROM ".join(", ",@tables);
	$sql .= " WHERE ".$where if ($where);
	$sql .= " GROUP BY ".join(", ",@group_work) if (@group_work);
	$sql .= " ORDER BY ".join(", ",@order) if (@order);
	$sql .= " LIMIT ".$argv->{limit} if (defined($argv->{limit}) && $argv->{limit} > 0);

	## cross check cursor_key v buffer_hashkey
	$self->{work}{cursor_key_vs_hashkey} = 0;
	if (defined($argv->{buffer_hashkey}))
	{
		$self->{work}{buffer_hashkey} = [];
		foreach my $key( (ref($argv->{buffer_hashkey}) eq "ARRAY") ? @{$argv->{buffer_hashkey}} : ($argv->{buffer_hashkey}) )
		{
			push(@{$self->{work}{buffer_hashkey}},$key);
			$self->{work}{cursor_key_vs_hashkey}++ if (defined($self->{work}{cursor_key}) && grep(/^$key$/,@{$self->{work}{cursor_key}}));
		}
	}

	## execute
	return SQL_SIMPLE_RC_ERROR if ($self->_Call(
		command => $sql,
		command_type => 0,			# (ZERO is read)
		buffer => $argv->{buffer},
		buffer_options => $argv->{buffer_options},
		buffer_hashkey => $argv->{buffer_hashkey},
		buffer_arrayref => $argv->{buffer_arrayref},
		buffer_hashindex => $argv->{buffer_hashindex},
		buffer_hashindex => $argv->{buffer_hashindex},
		buffer_fields => @fields+0,
		cursor => $argv->{cursor},
		cursor_command => $argv->{cursor_command},
		cursor_key => $argv->{cursor_key},
		cursor_order => $argv->{cursor_order},
		make_only => $argv->{make_only},
		flush => $argv->{flush},
		sql_save => $argv->{sql_save},
	));
	return SQL_SIMPLE_RC_OK if ($self->getRows());
	return SQL_SIMPLE_RC_OK if ($argv->{notfound});

	$self->_setMessage("select",SQL_SIMPLE_RC_SYNTAX,"012");
	return SQL_SIMPLE_RC_EMPTY;
}

sub _SelectOrderBy()
{
	my $self = shift;
	my $array = shift;
	my $table = shift;
	my $field = shift;
	my $order = shift;

	if ($field =~ /^(.*?)\.(.*?)$/)
	{
		$field = $self->_getAliasCols(6,$field,SQL_SIMPLE_ALIAS_ORDERBY+SQL_SIMPLE_ALIAS_FQDN);
	}
	else
	{
		$field = $self->_getAliasCols(7,$field,SQL_SIMPLE_ALIAS_ORDERBY);
	}
	if ($order)
	{
		$order = uc($order);
		$field .= " ".(($order eq SQL_SIMPLE_ORDER_ASC) ? 'ASC' : ($order eq SQL_SIMPLE_ORDER_DESC) ? 'DESC' : 'USING '.$order);
	}
	push(@{$array},$field);
}

################################################################################
## action: delete
## return:
##	rc<0 syntax error
##	rc=0 successful
##	rc=1 sql error
##	rc=2 no selected found (no match where found)

sub Delete()
{
	my $self = shift;
	my $argv = {@_};

	$self->_resetSession();
	$self->_Dumper("delete",$argv);
	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{work}{command} = SQL_SIMPLE_ALIAS_DELETE;

	if ($self->{init}{plugin_fh}->can('Delete') && $self->{init}{plugin_fh}->Delete($argv))
	{
		$self->_setMessage("delete",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_commit = $self->_setCommit($argv->{commit}) if (defined($argv->{commit}));
	my $saved_message_log = $self->_setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->_setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->_setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Delete(%{$argv});

	$self->_setCommit($saved_commit) if (defined($argv->{commit}));
	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->_setQuote($saved_quote) if (defined($argv->{quote}));
	$self->_setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _Delete()
{
	my $self = shift;
	my $argv = {@_};

	return SQL_SIMPLE_RC_SYNTAX if ($self->_checkTablesEntries("delete",$argv) != SQL_SIMPLE_RC_OK);

	## make where
	my $where;
	return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhere("delete",$argv->{where},\$where));
	if ((!defined($where) || $where eq "") && !$argv->{force})
	{
		$self->_setMessage("delete",SQL_SIMPLE_RC_SYNTAX,"016");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## build sql command
	my $sql = "DELETE FROM ".join(", ",@{$self->{work}{tables_inuse}});
	$sql .= " WHERE ".$where if ($where);

	return SQL_SIMPLE_RC_ERROR if ($self->_Call(
		command => $sql,
		command_type => 1,			# (NOT_ZERO is update)
		buffer => $argv->{buffer},
		buffer_options => $argv->{buffer_options},
		buffer_hashkey => $argv->{buffer_hashkey},
		buffer_arrayref => $argv->{buffer_arrayref},
		make_only => $argv->{make_only},
		flush => $argv->{flush},
		sql_save => $argv->{sql_save},
	));
	return SQL_SIMPLE_RC_OK if ($argv->{notfound});
	if ($self->getRows() == 0)
	{
		$self->_setMessage("delete",SQL_SIMPLE_RC_SYNTAX,"012");
		return SQL_SIMPLE_RC_EMPTY;
	}
	return SQL_SIMPLE_RC_OK;
}

################################################################################
## action: insert
## return:
##	rc<0 syntax error
##	rc=0 successful
##	rc=1 sql error
##	rc=2 no selected found (no match where found)

sub Insert()
{
	my $self = shift;
	my $argv = {@_};

	$self->_resetSession();
	$self->_Dumper("insert",$argv);
	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{work}{command} = SQL_SIMPLE_ALIAS_INSERT;

	if ($self->{init}{plugin_fh}->can('Insert') && $self->{init}{plugin_fh}->Insert($argv))
	{
		$self->_setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_commit = $self->_setCommit($argv->{commit}) if (defined($argv->{commit}));
	my $saved_message_log = $self->_setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->_setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->_setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Insert(%{$argv});

	$self->_setCommit($saved_commit) if (defined($argv->{commit}));
	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->_setQuote($saved_quote) if (defined($argv->{quote}));
	$self->_setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _Insert()
{
	my $self = shift;
	my $argv = {@_};

	return SQL_SIMPLE_RC_SYNTAX if ($self->_checkTablesEntries("insert",$argv) != SQL_SIMPLE_RC_OK);

	## check mandatory options
	if (!defined($argv->{fields}))
	{
		$self->_setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"017");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## hash: fields=> { fld => value }
	## array: fields=> [ fld1,fld2 }, values=> [ val1,val2 ]
	if	(ref($argv->{fields}) eq "HASH") {}
	elsif	(ref($argv->{fields}) eq "ARRAY")
	{
		if (!defined($argv->{values}))
		{
			$self->_setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"027");
			return SQL_SIMPLE_RC_SYNTAX;
		}
		if (ref($argv->{values}) ne "ARRAY")
		{
			$self->_setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"041");
			return SQL_SIMPLE_RC_SYNTAX;
		}
	}
	else
	{
		$self->_setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"018");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## validat conflict option
	if (defined($argv->{conflict}) && ref($argv->{conflict}) ne "HASH")
	{
		$self->_setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"042");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## making fields
	my @fields;
	my @values;

	## format: fields => { ... }
	if (ref($argv->{fields}) eq "HASH")
	{
		## mapping field and value
		my @value_;
		foreach my $field(sort(keys(%{$argv->{fields}})))
		{
			push(@fields,$self->_getAliasCols(8,$field,SQL_SIMPLE_ALIAS_INSERT));
			push(@value_,(!defined($argv->{fields}{$field})) ? "NULL" : $self->{argv}{quote}.$self->_escapeQuote($argv->{fields}{$field}).$self->{argv}{quote});
		}
		@values = ("(".join(",",@value_).")");
	}
	## format: fields => [ ... ]
	else
	{
		## mapping field
		foreach my $field(@{$argv->{fields}})
		{
			push(@fields,$self->_getAliasCols(9,$field,SQL_SIMPLE_ALIAS_INSERT));
		}
		my @value_;
		foreach my $value(@{$argv->{values}})
		{
			## format: fields => [ col => val ]
			if (ref($value) ne "ARRAY")
			{
				push(@value_,(!defined($value)) ? "NULL" : $self->{argv}{quote}.$self->_escapeQuote($value).$self->{argv}{quote});
			}
			## format: fields => [ col => [ val1, ... ] ], field must be 1
			else
			{
				my @value2;
				foreach my $value2(@{$value})
				{
					push(@value2,(!defined($value2)) ? "NULL" : $self->{argv}{quote}.$self->_escapeQuote($value2).$self->{argv}{quote});
				}
				push(@values,"(".join(",",@value2).")");
			}
		}
		push(@values, (@fields == 1) ? "(".join("),(",@value_).")" : "(".join(",",@value_).")" ) if (@value_);
	}

	## build sql
	my $sql = "INSERT INTO ".join(", ",@{$self->{work}{tables_inuse}})." (".join(",",@fields).") VALUES ".join(",",@values);
	if (defined($argv->{conflict}))
	{
		my @conflict;
		foreach my $field(sort(keys(%{$argv->{conflict}})))
		{
			($argv->{conflict}{$field} =~ /^\\(.*)/) ?
				push(@conflict,$self->_getAliasCols(10,$field,SQL_SIMPLE_ALIAS_INSERT)." = ".$1): 
				push(@conflict,$self->_getAliasCols(11,$field,SQL_SIMPLE_ALIAS_INSERT)." = ".$self->{argv}{quote}.$self->_escapeQuote($argv->{conflict}{$field}).$self->{argv}{quote});
		}
		$sql .= ($self->{init}{plugin_id} =~ /^mysql/i || $self->{init}{plugin_id} =~ /^mariadb/i) ?
			" ON DUPLICATE KEY UPDATE ".join(", ",@conflict) :
		       	" ON CONFLICT ".(($argv->{conflict_key})?"(".$self->_getAliasCols(12,$argv->{conflict_key},SQL_SIMPLE_ALIAS_INSERT).") ":"")."DO UPDATE SET ".join(", ",@conflict);
	}

	## execute
	return SQL_SIMPLE_RC_ERROR if ($self->_Call(
		command => $sql,
		command_type => 1,			# (NOT_ZERO is update)
		buffer => $argv->{buffer},
		buffer_options => $argv->{buffer_options},
		buffer_hashkey => $argv->{buffer_hashkey},
		buffer_arrayref => $argv->{buffer_arrayref},
		make_only => $argv->{make_only},
		flush => $argv->{flush},
		sql_save => $argv->{sql_save},
	));
	return SQL_SIMPLE_RC_OK;
}

################################################################################
## action: update
## return:
##	rc<0 syntax error
##	rc=0 successful
##	rc=1 sql error
##	rc=2 no selected found (no match where found)

sub Update()
{
	my $self = shift;
	my $argv = {@_};

	$self->_resetSession();
	$self->_Dumper("update",$argv);
	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{work}{command} = SQL_SIMPLE_ALIAS_UPDATE;

	if ($self->{init}{plugin_fh}->can('Update') && $self->{init}{plugin_fh}->Update($argv))
	{
		$self->_setMessage("update",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_commit = $self->_setCommit($argv->{commit}) if (defined($argv->{commit}));
	my $saved_message_log = $self->_setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->_setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->_setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Update(%{$argv});

	$self->_setCommit($saved_commit) if (defined($argv->{commit}));
	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->_setQuote($saved_quote) if (defined($argv->{quote}));
	$self->_setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _Update()
{
	my $self = shift;
	my $argv = {@_};

	return SQL_SIMPLE_RC_SYNTAX if ($self->_checkTablesEntries("update",$argv) != SQL_SIMPLE_RC_OK);

	## check mandatory options
	if (!defined($argv->{fields}))
	{
		$self->_setMessage("update",SQL_SIMPLE_RC_SYNTAX,"017");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (ref($argv->{fields}) ne "HASH")
	{
		$self->_setMessage("update",SQL_SIMPLE_RC_SYNTAX,"018");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## make fields
	my $ident = 0;
	my @fields;
	foreach my $field(sort(keys(%{$argv->{fields}})))
	{
		my $realn = $self->_getAliasCols(13,$field,SQL_SIMPLE_ALIAS_UPDATE);
		$ident = 1 if ($realn =~ /^.*\..*$/);

		if	(!defined($argv->{fields}{$field}))
		{
			push(@fields,$realn." = NULL");
		}
		elsif	($argv->{fields}{$field} =~ /^\\(.*)/)
		{
			my $value = $1;
			push(@fields,$realn." = ".$value);
		}
		else
		{
			## validate functions as arguments
			$self->_checkFunctions(\$argv->{fields}{$field},SQL_SIMPLE_ALIAS_UPDATE);
			push(@fields,$realn." = ".$self->{argv}{quote}.$self->_escapeQuote($argv->{fields}{$field}).$self->{argv}{quote});
		}
	}

	## make tables
	my @tables;
	foreach my $table(@{$self->{work}{tables_inuse}})
	{
		my $_table = $self->_getAliasTable($table,$argv);

		## remove alias if not required
		$_table = $1 if (!$ident && $_table =~ /^(.*?)\s+.*?$/);

		push(@tables,$_table);
	}

	## make where
	my $where;
	return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhere("update",$argv->{where},\$where));
	if ((!defined($where) || $where eq "") && !$argv->{force})
	{
		$self->_setMessage("update",SQL_SIMPLE_RC_SYNTAX,"016");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## formata o sql
	my $sql = "UPDATE ".join(", ",@tables)." SET ".join(", ",@fields);
	$sql .= " WHERE ".$where if ($where);

	## execute
	return SQL_SIMPLE_RC_ERROR if ($self->_Call(
		command => $sql,
		command_type => 1,			# (NOT_ZERO is update)
		buffer => $argv->{buffer},
		buffer_options => $argv->{buffer_options},
		buffer_hashkey => $argv->{buffer_hashkey},
		buffer_arrayref => $argv->{buffer_arrayref},
		make_only => $argv->{make_only},
		flush => $argv->{flush},
		sql_save => $argv->{sql_save},
	));
	return SQL_SIMPLE_RC_OK if ($argv->{notfound});
	if ($self->getRows() == 0)
	{
		$self->_setMessage("update",SQL_SIMPLE_RC_SYNTAX,"012");
		return SQL_SIMPLE_RC_EMPTY;
	}
	return SQL_SIMPLE_RC_OK;
}

################################################################################
## action: wait db connect
## return:
##	rc<0	syntax error
##	rc=0	successful
##	rc>0	sql command error

sub Wait()
{
	my $self = shift;
	my $argv= {@_};

	$self->_Dumper("wait",$argv);

	my $count = 1 if (!defined($argv->{count}));
	my $sleep = 5 if (!defined($argv->{interval}));

	return SQL_SIMPLE_RC_SYNTAX if ($count =~ /^\D+$/);
	return SQL_SIMPLE_RC_SYNTAX if ($sleep =~ /^\D+$/);

	while ($count-- > 0)
	{
		last if (!$self->Open());

		sleep($sleep) if ($count && $sleep);
	}
	return $self->getRC();
}

################################################################################
## action: execute sql command
## return: 
##	rc<0	syntax error
##	rc=0	successful
##	rc>0	sql command error
#
## callback example:
##	sub myfunc()
##	{
##		my $ref = shift;	# input field hash info
##		my $options = shift;	# options args
##		return 0;		# if ok to continue than return ZERO
##		return 1;		# if aboort needed than return NOT_ZERO
##	}

sub Call()
{
	my $self = shift;
	my $argv = {@_};

	$self->_resetSession();
	$self->_Dumper("call",$argv);
	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load

	if ($self->{init}{plugin_fh}->can('Call') && $self->{init}{plugin_fh}->Call($argv))
	{
		$self->_setMessage("call",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if ($argv->{command} eq "")
	{
		$self->_setMessage("call",SQL_SIMPLE_RC_SYNTAX,"023");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_commit = $self->_setCommit($argv->{commit}) if (defined($argv->{commit}));
	my $saved_message_log = $self->_setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->_setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->_setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Call(%{$argv});

	$self->_setCommit($saved_commit) if (defined($argv->{commit}));
	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->_setQuote($saved_quote) if (defined($argv->{quote}));
	$self->_setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _Call()
{
	my $self = shift;
	my $argv = {@_};

	$self->_setLastSQL($argv->{command});

	## save command (call-sql_save is prior that new-sql_save
	if ((defined($argv->{sql_save}) && $argv->{sql_save}) || (defined($self->{argv}{sql_save}) && $self->{argv}{sql_save} && $argv->{command_type}))
	{
		return SQL_SIMPLE_RC_ERROR if ($self->Save($argv->{command}));
	}

	## return if makeonly
	return SQL_SIMPLE_RC_ERROR if ($argv->{make_only});

	## mandatory
	if (!defined($self->{init}{dbh}))
	{
		$self->_setMessage("call",SQL_SIMPLE_RC_SYNTAX,"022");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	my $flush_buffer = (!defined($argv->{flush}) || $argv->{flush}) ? 1 : 0;
	my $type;

	## define type of return data
	if	(!defined($argv->{buffer})) {}
	elsif	(ref($argv->{buffer}) eq "HASH")
	{
		if	(!defined($argv->{buffer_hashkey})) { $type=1; }
		elsif	(ref($argv->{buffer_hashkey}) eq "ARRAY") { $type = (@{$argv->{buffer_hashkey}} > 1) ? 6 : 5; }
		elsif	(ref($argv->{buffer_hashkey}) eq "SCALAR") { $type=5; }
		elsif	(ref($argv->{buffer_hashkey}) eq "") { $type=5; }
		else
		{
			$self->_setMessage("call",SQL_SIMPLE_RC_SYNTAX,"046");
			return SQL_SIMPLE_RC_SYNTAX;
		}
		if ($flush_buffer)
		{
			undef(%{$argv->{buffer}});;
			undef(@{$argv->{buffer_hashindex}}) if (defined($argv->{buffer_hashindex}));
		}
	}
	else
	{
		if (ref($argv->{buffer}) eq "ARRAY")
		{
			if (defined($argv->{buffer_arrayref}) && !$argv->{buffer_arrayref})
			{
				if ($argv->{buffer_fields} != 1)
				{
					$self->_setMessage("call",SQL_SIMPLE_RC_SYNTAX,"047");
					return SQL_SIMPLE_RC_SYNTAX;
				}
				$type=7;
			}
			else { $type=2; }
			undef(@{$argv->{buffer}}) if ($flush_buffer);
		}
		elsif (ref($argv->{buffer}) eq "CODE") { $type=3; }
		elsif (ref($argv->{buffer}) eq "SCALAR") { $type=4; }
		else
		{
			$self->_setMessage("call",SQL_SIMPLE_RC_SYNTAX,"024");
			return SQL_SIMPLE_RC_SYNTAX;
		}

		## test buffer_hashkey
		if (defined($argv->{buffer_hashkey}))
		{
			$self->_setMessage("call",SQL_SIMPLE_RC_SYNTAX,"044");
			return SQL_SIMPLE_RC_SYNTAX;
		}
	}

	## run-PreFetch if exists
	if ($self->{init}{plugin_fh}->can('PreFetch') && $self->{init}{plugin_fh}->PreFetch($argv))
	{
		$self->_setMessage("prefetch",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## prepare command
	$argv->{command} =~ s/^\s+|\s+$//;
	my $sth = $self->{init}{dbh}->prepare($argv->{command}.( ($argv->{command} =~ /\;$/) ? "":";") );

	## enforce cursor_order if not defined
	$self->{work}{cursor_order} = 1 if (!defined($self->{work}{cursor_order}));

	## execute command
	if (defined($sth))
	{
		$sth->execute();			# send command to run
		$self->_setMessage("call");		# save the current status

		## scan the fields
		if (defined($argv->{buffer}))
		{
			if ($sth->{NUM_OF_FIELDS})
			{
				$self->{init}{cursor}{first} = [];
				my $ref_saved;
				while (my $ref = $sth->fetchrow_hashref())
				{
					## get first keys elements
					if (defined($self->{work}{cursor_key}) && @{$self->{work}{cursor_key}})
					{
						if (!@{$self->{init}{cursor}{first}})
						{
							foreach my $key(@{$self->{work}{cursor_key}})
							{
								push(@{$self->{init}{cursor}{first}},$ref->{$key});
							}
						}
					}

					## move data
					if	($type == 1) { %{$argv->{buffer}} = %{$ref}; }
					elsif	($type == 2) { ($self->{work}{cursor_order}) ? push(@{$argv->{buffer}},$ref): unshift(@{$argv->{buffer}},$ref); }
					elsif	($type == 3) { last if (&{$argv->{buffer}}($ref,$argv->{buffer_options})); }
					elsif	($type == 4) { foreach my $id(keys(%{$ref})) { ${$argv->{buffer}} = $ref->{$id}; }}
					elsif	($type == 5)
					{
						## save value before remove
						my $val = $ref->{ $self->{work}{buffer_hashkey}[0] };
						$self->{work}{cursor_last_saved}{ $self->{work}{buffer_hashkey}[0] } = $val if ($self->{work}{cursor_key_vs_hashkey});
						
						## create hashindex if required
						(($self->{work}{cursor_order}) ? push(@{$argv->{buffer_hashindex}},$val) : unshift(@{$argv->{buffer_hashindex}},$val)) if (defined($argv->{buffer_hashindex}));

						## remove hashkey from the data buffer
						delete($ref->{ $self->{work}{buffer_hashkey}[0] });

						## move data to buffer (hashkey + 1 field data)
						if ($argv->{buffer_fields} == 2)
					       	{
							my @k = each(%{$ref});
							$argv->{buffer}->{ $val } = $ref->{$k[0]};
						}
						else
						{
							$argv->{buffer}->{ $val } = $ref;
						}
					}
					elsif	($type == 6)
					{
						my $addr = $argv->{buffer};
						my @keys;
						foreach my $key(@{$argv->{buffer_hashkey}})
						{
							if (!defined($ref->{$key}))
							{
								$self->_setMessage("call",SQL_SIMPLE_RC_SYNTAX,"045");
								return SQL_SIMPLE_RC_SYNTAX;
							}
							
							## save value before remove if match with cursor_key
							$self->{work}{cursor_last_saved}{$key} = $ref->{$key} if ($self->{work}{cursor_key_vs_hashkey});
							
							## create temporary hashindex if required
							push(@keys,$ref->{$key}) if (defined($argv->{buffer_hashindex}));

							## switch index over index
							$addr->{$ref->{$key}} = {} if (!defined($addr->{$ref->{$key}}));
							$addr = $addr->{$ref->{$key}};

							## remove hashkey from the data
							delete($ref->{$key});
						}
						## create hashindex if required
						(($self->{work}{cursor_order}) ? push(@{$argv->{buffer_hashindex}},\@keys) : unshift(@{$argv->{buffer_hashindex}},\@keys)) if (defined($argv->{buffer_hashindex}));

						## move data to buffer
						%{$addr} = (keys(%{$ref}) != 1) ? %{$ref} : $ref->{ each(%{$ref}) };
					}
					elsif	($type == 7)
					{
						my @key = keys(%{$ref});
						($self->{work}{cursor_order}) ? push(@{$argv->{buffer}},$ref->{ $key[0] }) : unshift(@{$argv->{buffer}},$ref->{ $key[0] });
					}
					$ref_saved = $ref;
				}

				## get last keys elements
				if ($ref_saved && defined($self->{work}{cursor_key}) && @{$self->{work}{cursor_key}})
				{
					$self->{init}{cursor}{last} = [];
					foreach my $key(@{$self->{work}{cursor_key}})
					{
						push(@{$self->{init}{cursor}{last}},(defined($ref_saved->{$key})) ? $ref_saved->{$key} : $self->{work}{cursor_last_saved}{$key});
					}
				}
			}
		}
		$self->{init}{rows} = $sth->rows();	# get number of extracted lines

		## close and commit (if need)
		$sth->finish();
	}
	else
	{
		$self->_setMessage("call");
	}
	undef($sth);

	## force commit if required
	$self->_Commit(%{$argv}) if ($self->{argv}->{commit} && $argv->{command_type});
	return $self->getRC();
}

################################################################################
## action: commit command
## return:
##	rc=0	successful
##	rc>0	sql command error

sub Commit()
{
	my $self = shift;
	my $argv = {@_};

	$self->_resetSession();
	$self->_Dumper("commit",$argv);

	return SQL_SIMPLE_RC_OK if (!defined($self->{init}{dbh}));
	return $self->_Commit(%{$argv});
}

sub _Commit()
{
	my $self = shift;
	my $argv = {@_};

	return $self->_Call(
		command => "commit",
		command_type => 0,		# (ZERO to eliminate the LOOP)
		make_only => $argv->{make_only},
		flush => $argv->{flush},
		sql_save => $argv->{sql_save},
	);
}

################################################################################
## action: disconnect database
## return:
##	rc=0	successful
##	rc>0	sql command error

sub Close()
{
	my $self = shift;

	return SQL_SIMPLE_RC_OK if (!defined($self->{init}{dbh}));

	my $rc = $self->{init}{dbh}->disconnect();

	$self->_setMessage("close");

	undef($self->{init}{dbh});

	return $self->getRC();
}

##############################################################################
## action: save the current sql command
## return:
##	rc=0, successful
##	rc=1, system error (mkdir/openfile)

sub Save()
{
	my $self = shift;
	my @sqls = @_;

	$self->_Dumper("save",\@sqls);
	$self->{init}{sql_save_ix} = 0 if (!defined($self->{init}{sql_save_ix}));
	$self->{init}{sql_save_name} = "sql" if (!defined($self->{init}{sql_save_name}));
	$self->{init}{sql_save_dir} =
		(defined($self->{argv}{sql_save_dir})) ? $self->{argv}{sql_save_dir} :
		($^O ne 'MSWin32') ?  File::Spec->catdir("","var","spool","sql") :
		File::Spec->catdir("","windows","temp") if (!defined($self->{init}{sql_save_dir}));

	require Date::Calc;
	require File::Path;
	require IO::File;

	my $today = sprintf("%04s%02s%02s",Date::Calc::Today());
	my $path = ($self->{argv}{sql_save_bydate}) ?
		File::Spec->catdir($self->{init}{sql_save_dir},substr($today,0,4),substr($today,0,6),$today) :
		$self->{init}{sql_save_dir};

	if (!stat($path))
       	{
		eval { &File::Path::mkpath($path); };
		if ($@)
		{
			$self->_setMessage("save",SQL_SIMPLE_RC_ERROR,"025",$@);
			return ($self->{argv}{sql_save_ignore}) ? SQL_SIMPLE_RC_OK : SQL_SIMPLE_RC_ERROR;
		}
	}

	$self->{init}{sql_save_logfile} = File::Spec->catpath("", $path,$self->{init}{sql_save_name}.".".($self->{argv}{db}||"public").".".$today.".".$$.".".(++$self->{init}{sql_save_ix}));
	my $fh = IO::File->new(">".$self->{init}{sql_save_logfile});
	if (!defined($fh))
	{
		$self->_setMessage("save",SQL_SIMPLE_RC_ERROR,"026",$!);
		return ($self->{argv}{sql_save_ignore}) ? SQL_SIMPLE_RC_OK : SQL_SIMPLE_RC_ERROR;
	}

	print $fh join("\n",@sqls),"\n";
	close($fh);
	undef($fh);
	return SQL_SIMPLE_RC_OK;
}

################################################################################
## action: where clause formater, used by: select, insert, delete, update
## return:
##	rc<0	syntax error
##	rc=0	successful

sub getWhere()
{

	my $self = shift;
	my $argv = {@_};

	$self->{work}{tables_inuse} = [];
	if	(ref($argv->{table}) eq "ARRAY"){ push(@{$self->{work}{tables_inuse}},@{$argv->{table}}); }
	elsif	(ref($argv->{table}) eq "")	{ push(@{$self->{work}{tables_inuse}},$argv->{table}); }
	else
	{
		$self->_setMessage("getWhere",SQL_SIMPLE_RC_SYNTAX,"006");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	return $self->_getWhere("where",$argv->{where},$argv->{buffer});
}

sub _getWhere()
{
	my $self = shift;
	my $command = shift;
	my $where = shift;
	my $buffer = shift;

	## return dummy where
	return SQL_SIMPLE_RC_OK if (!$where);

	## format where
	my @where_local;
	return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhereRecursive($command,0,$where,\@where_local));

	## return the where clause
	${$buffer} = join(" ",@where_local);
	return SQL_SIMPLE_RC_OK;
}

sub _getWhereRecursive()
{
	my $self = shift;
	my $command = shift;
	my $level = shift;
	my $where = shift;
	my $buffer = shift;

	## return error if argvs is empty, format error
	if ($where eq "")
	{
		$self->_setMessage($command,SQL_SIMPLE_RC_SYNTAX,"020");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (ref($where) eq "")
	{
		push(@{$buffer},$where);
		return 0;
	}
	## return error if value1 is not array or value type
	if (ref($where) ne "ARRAY")
	{
		$self->_setMessage($command,SQL_SIMPLE_RC_SYNTAX,"021");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## format where
	my @where_tmp;
	my $oper_pend = 0;
	for (my $ix=0; $ix < @{$where};)
	{
		undef(@where_tmp) if (@where_tmp && join('',@where_tmp) eq '');

		###############################################################
		## value1

		my $value1 = $where->[$ix++];

		if (ref($value1) ne "")
		{
			my @where_aux;
			return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhereRecursive($command,$level+1,$value1,\@where_aux));

			## valida se requer AND/OR
			push(@where_tmp,"AND") if ($oper_pend && @where_tmp);
			## salva o where recursivo
			push(@where_tmp,join(" ",@where_aux));
			$oper_pend = 1;
			next;
		}

		## check and/or logical connector
		if ($value1 =~ /^(and|\&\&|or|\|\|)$/i)
		{
			push(@where_tmp,uc($value1)) if ($oper_pend && @where_tmp);
			$oper_pend = 0;
			next;
		}

		## valida se requer AND/OR
		if ($oper_pend && @where_tmp)
		{
			push(@where_tmp,"AND");
			$oper_pend = 0;
		}

		## process value if not escape
		if (!($value1 =~ /^\\(.*)/))
		{
			## validate functions as arguments
			if ($self->_checkFunctions(\$value1,SQL_SIMPLE_ALIAS_WHERE))
			{}
			## adjusts for single tables
			elsif (@{$self->{work}{tables_inuse}} == 1)
			{
				$value1 = $self->_getAliasCols(19,$value1,SQL_SIMPLE_ALIAS_WHERE);
			}
			## adjusts for multiple tables
			elsif	($value1 =~ /^(.*?)\.(.*?)$/ && (grep(/^$1$/,@{$self->{work}{tables_inuse}}) || defined($self->{init}{table_realname}{$1})))
			{
				$value1 = $self->_getAliasCols(20,$value1,SQL_SIMPLE_ALIAS_WHERE+SQL_SIMPLE_ALIAS_FQDN);
			}
			elsif	(defined($self->{work}{field_alias}{$value1}))
			{
				$value1 = $self->_getAliasCols(28,$self->{work}{field_alias}{$value1},SQL_SIMPLE_ALIAS_WHERE+SQL_SIMPLE_ALIAS_FQDN);
			}
			## others adjusts
			else
			{
				$value1 = $self->_getAliasCols(21,$value1,SQL_SIMPLE_ALIAS_WHERE);
			}
		}
		else
		{
			$value1 = $1;
		}

		## finis where if no more values
		if ($ix >= @{$where})
		{
			push(@where_tmp,$value1);
			last;
		}

		###############################################################
		## value2

		## test value2, if required
		my $value2 = $where->[$ix++];
		my $quote = $self->{argv}{quote};

		$oper_pend = 1;

		## value2 is array, multiple values
		if (ref($value2) eq "ARRAY")
		{
			my @_value2 = @{$value2};
			my $value2_b = "";
			my $value2_a = "";
			my $operator = $value2->[0];
			my $where_opr = "AND";

			## value0 is escaped (not operator)
			if	(!defined($operator))	{ $operator = "="; }
			elsif	($operator =~ /^\\/)	{ $operator = "="; }
			elsif	($operator eq "=")	{ shift(@_value2); }
			elsif	($operator eq "!")	{ shift(@_value2); $operator = "!="; }
			elsif	($operator eq "!=")	{ shift(@_value2); $operator = "!="; }
			elsif	($operator eq "<>")	{ shift(@_value2); $operator = "!="; }
			elsif	($operator eq "<=")	{ shift(@_value2); }
			elsif	($operator eq "<")	{ shift(@_value2); }
			elsif	($operator eq ">=")	{ shift(@_value2); }
			elsif	($operator eq ">")	{ shift(@_value2); }
			elsif	($operator eq "%%")	{ shift(@_value2); $operator = "LIKE"; $value2_b = "%"; $value2_a = "%"; $where_opr = "OR" if (@_value2 > 1); }
			elsif	($operator eq "^%")	{ shift(@_value2); $operator = "LIKE"; $value2_b = "%"; $where_opr = "OR" if (@_value2 > 1); }
			elsif	($operator eq "%^")	{ shift(@_value2); $operator = "LIKE"; $value2_a = "%"; $where_opr = "OR" if (@_value2 > 1); }
			elsif	($operator eq "^^")	{ shift(@_value2); $operator = "LIKE"; $where_opr = "OR" if (@_value2 > 1); }
			elsif	($operator eq "!%%")	{ shift(@_value2); $operator = "NOT LIKE"; $value2_b = "%"; $value2_a = "%"; }
			elsif	($operator eq "!^%")	{ shift(@_value2); $operator = "NOT LIKE"; $value2_b = "%"; }
			elsif	($operator eq "!%^")	{ shift(@_value2); $operator = "NOT LIKE"; $value2_a = "%"; }
			elsif	($operator eq "!^^")	{ shift(@_value2); $operator = "NOT LIKE"; }
			else				{ $operator = "="; }

			## construct condition
			if ($operator eq "=" || $operator eq "!=")
			{
				if (@_value2 > 1)
				{
					for (my $i=0; $i < @_value2; $i++)
					{
						if (!defined($_value2[$i]))
						{
							$_value2[$i] = 'NULL';
						}
						elsif ($_value2[$i] =~ /^\\(.*)/)
						{
							my $v = $1;
							if ($v =~ /^(\(SELECT\s+.*\))$/)
							{
								$_value2[$i] = $v;
							}
							elsif ($v =~ /^(.*?)\..*?$/ && grep(/^$1$/,@{$self->{work}{tables_valids}}))
							{
								$_value2[$i] = $self->_getAliasCols(22,$v,SQL_SIMPLE_ALIAS_WHERE+SQL_SIMPLE_ALIAS_FQDN);
							}
							elsif (defined($self->{work}{field_alias}{$v}))
							{
								$_value2[$i] = $self->_getAliasCols(27,$self->{work}{field_alias}{$v},SQL_SIMPLE_ALIAS_WHERE+SQL_SIMPLE_ALIAS_FQDN);
							}
							else
							{
								$_value2[$i] = $v;
							}
						}
						else
						{
							$_value2[$i] = $quote.$self->_escapeQuote($_value2[$i]).$quote;
						}
					}
					$quote = "";
					my $not = ($operator eq "!=") ? " NOT" : "";
					
					## no _escapeQuote required, already done in value2 build
					(@_value2 == 3 && $_value2[1] eq "'..'") ?
						push(@where_tmp,$value1.$not." BETWEEN (".$quote.$_value2[0].$quote.",".$quote.$_value2[2].$quote.")"):
						push(@where_tmp,$value1.$not." IN (".$quote.join("$quote,$quote",@_value2).$quote.")");
					next;
				}
			}

			## multiple conditions
			my @where_aux;
			foreach my $value(@_value2)
			{
				if	(defined($value))
				{
					if ($value =~ /^\\(.*)/)
					{
						my $v = $1;
						if ($v =~ /^(\(SELECT\s+.*\))$/)
						{
							if	($operator eq "=") { push(@where_tmp,$value1." IN ".$1); }
							elsif	($operator eq "!=") { push(@where_tmp,$value1." NOT IN ".$1); }
							else	{ push(@where_tmp,$value1." ".$operator." ".$1); }
						}
						elsif ($v =~ /^(.*?)\..*?$/ && grep(/^$1$/,@{$self->{work}{tables_valids}}))
						{
							push(@where_aux,$value1." ".$operator." ".$self->_getAliasCols(23,$v,SQL_SIMPLE_ALIAS_WHERE+SQL_SIMPLE_ALIAS_FQDN));
						}
						elsif (defined($self->{work}{field_alias}{$v}))
						{
							push(@where_aux,$value1." = ".$self->_getAliasCols(26,$self->{work}{field_alias}{$v},SQL_SIMPLE_ALIAS_WHERE+SQL_SIMPLE_ALIAS_FQDN));
						}
						else
						{
							push(@where_aux,$value1." ".$operator." ".$v);
						}
					}
					else
					{
						push(@where_aux,$value1." ".$operator." ".$quote.$self->_escapeQuote($value2_a.$value.$value2_b).$quote);
					}
				}
				elsif	($operator eq "=")
				{
					push(@where_aux,$value1." IS NULL");
				}
				else
				{
					push(@where_aux,$value1." NOT NULL");
				}
			}
			if (@where_aux > 1)
			{
				$where_aux[0] = "(".$where_aux[0];
				$where_aux[@where_aux-1] .= ")";
			}
			push(@where_tmp,join(" ".$where_opr." ",@where_aux)) if (@where_aux);
			next;
		}

		## value2 is single value
		if (!defined($value2))
		{
			push(@where_tmp,$value1." IS NULL");
			next;
		}
		if (ref($value2) eq "")
		{
			if ($value2 =~ /^\\(.*)/)
			{
				my $v = $1;
				if ($v =~ /^(\(SELECT\s+(.*)\))$/)
				{
					push(@where_tmp,$value1." IN ".$1);
				}
				elsif ($v =~ /^(.*?)\..*?$/ && grep(/^$1$/,@{$self->{work}{tables_valids}}))
				{
					push(@where_tmp,$value1." = ".$self->_getAliasCols(24,$v,SQL_SIMPLE_ALIAS_WHERE+SQL_SIMPLE_ALIAS_FQDN));
				}
				elsif (defined($self->{work}{field_alias}{$v}))
				{
					push(@where_tmp,$value1." = ".$self->_getAliasCols(25,$self->{work}{field_alias}{$v},SQL_SIMPLE_ALIAS_WHERE+SQL_SIMPLE_ALIAS_FQDN));
				}
				else
				{
					push(@where_tmp,$value1." = ".$v);
				}
			}
			else
			{
				push(@where_tmp,$value1." = ".$quote.$self->_escapeQuote($value2).$quote);
			}
			next;
		}

		## return error if value2 is not array or value type
		$self->_setMessage($command,SQL_SIMPLE_RC_SYNTAX,"028");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (@where_tmp)
	{
		push(@{$buffer},join(" ",@where_tmp));
		if ($level && @where_tmp > 1)
		{
			$buffer->[0] = "(".$buffer->[0];
			$buffer->[@{$buffer}-1] .= ")";
		}
	}
	return 0;
}

##############################################################################
## action: get dbh entry point module
## return: current dbi drive pointer module

sub getDBH()
{
	return $_[0]->{init}{dbh};
}

##############################################################################
## action: get last condition state
## return: last return code state

sub getRC()
{
	return $err;
}

##############################################################################
## action: get last message state
## return: last system message

sub getMessage()
{
	return $errstr;
}

##############################################################################
## action: get number of extracted lines
## return: number of extracted lines

sub getRows()
{
	return $_[0]->{init}{rows};
}

##############################################################################
## action: get the last sql command
## return: last sql command

sub getLastSQL()
{
	return $_[0]->{init}{sql_command};
}

##############################################################################
## action: get the last cursor pointer
## return: cursor pointer

sub getLastCursor()
{
	my $self = shift;
	return %{$self->{init}{cursor}};
}

##############################################################################
## action: get the last saved fileset
## return: last sql logfile

sub getLastSave()
{
	return $_[0]->{init}{sql_save_logfile};
}

##############################################################################
## action: get the table's realname
## return: name of the table

sub getAliasTable()
{
	my $self = shift;
	return $self->_getAliasTable(@_,{schema=>defined($self->{init}{schema})});
}

sub _getAliasTable()
{
	my $self = shift;
	my $table = shift;
	my $argv = shift;

	return $self->_getSchemaName($argv).$table." ".$self->{work}{tables_alias}{$table} if (defined($self->{work}{tables_alias}{$table}));
	return $self->_getSchemaName($argv).$table;
}

##############################################################################
## action: get the schema name if required
## return: name of the schema

sub _getSchemaName()
{
	my $self = shift;
	my $argv = shift;

	return "" if (!$argv->{schema});
	return "" if (!defined($self->{argv}{schema}));
	return $self->{argv}{schema}.".";
}

##############################################################################
## action: get the table's realname
## return: name of the table

sub getAliasCols()
{
	my $self = shift;
	return $self->_getAliasCols(0,@_);
}

##############################################################################
# 0x01 - return col_real wo/table

sub _getAliasCols()
{
	my $self = shift;
	my $mycall = shift;
	my $field = shift;
	my $result = shift;

	my $_table;
	my $_field;

	## enforce prefered aliases if defined
	$field = $self->{work}{field_alias}{$field} if (defined($self->{work}{field_alias}{$field}));

	## field have ident?
	if ($field =~ /^(.*?)\.(.*?)$/)
	{
		$_table = $1;
		$_field = $2;
		if (defined($self->{work}{field_cols}))
		{
			if (defined($self->{work}{field_cols}{$_table}))
			{
				if (defined($self->{work}{field_cols}{$_table}{$_field}))
				{
					$_field = $self->{work}{field_cols}{$_table}{$_field};
				}
			}
			else
			{
				if (defined($self->{work}{tables_alias}{$_table}))
				{
					my $a = $self->{work}{tables_alias}{$_table};
					if (defined($self->{work}{field_cols}{$a}))
					{
						if (defined($self->{work}{field_cols}{$a}{$_field}))
						{
							$_field = $self->{work}{field_cols}{$a}{$_field};
						}
					}
				}
			}

		}
		if (!grep(/^$_table$/,@{$self->{work}{tables_inuse}}))
		{
			return $field if (!defined($self->{argv}{tables}) || !defined($self->{argv}{tables}{$_table}));
			$_table = $self->{argv}{tables}{$_table}{name};
		}
		$_field = $self->{argv}{tables}{ $self->{work}{tables_alias}{$_table} }{cols}{$_field} if (defined($self->{argv}{tables}) && defined($self->{work}{tables_alias}{$_table}) && defined($self->{argv}{tables}{ $self->{work}{tables_alias}{$_table} }{cols}{$_field}));
		$result |= SQL_SIMPLE_ALIAS_FQDN if (@{$self->{work}{tables_inuse}} != 1);
	}
	else
	{
		$_field = $field;

		## single table in use?
		if (@{$self->{work}{tables_inuse}} == 1)
		{
			$_table = $self->{work}{tables_inuse}[0];
			$_field = $self->{argv}{tables}{ $self->{work}{tables_alias}{$_table} }{cols}{$_field} if (defined($self->{work}{tables_alias}{$_table}) && defined($self->{argv}{tables}{ $self->{work}{tables_alias}{$_table} }{cols}{$_field}));
		}
	
		## scan contents
		else
		{
			foreach my $t(@{$self->{work}{tables_inuse}})
			{
				## ignore table if field not found
				next if ( defined($self->{work}{tables_alias}{$t}) && !defined($self->{argv}{tables}{ $self->{work}{tables_alias}{$t} }{cols}{$_field}) );

				## returns field as is if duplicated
				return $field if ($_table);

				## define the table by alias
				$_table = $t;
			}
		}
	}
	if ($_table && $result & SQL_SIMPLE_ALIAS_FQDN)
	{
		$_table = $self->{work}{tables_alias}{$_table} if (defined($self->{work}{tables_alias}{$_table}));
		return $_table.".".$_field;
	}
	return $_field;
}

################################################################################
## action: validate functions and convert the fields named 

sub _checkFunctions()
{
	my $self = shift;
	my $value1 = shift;
	my $result = shift;

	## test if value is function
	my $fnc;
	my $op1 = ${$value1};
	my $op2 = '';
	my $lvl;
	while (($op1 =~ /^(.*?)\((.*)\)(.*)\)$/) || ($op1 =~ /^(.*?)\((.*)\)$/))
	{
		$lvl++;
		$fnc .= $1."(";
		$op1 = $2.((defined($3)) ? ")" : "");
		$op2 .= (defined($3)) ? ")".$3 : ")";
	}

	## process functions if mapped
	if ($lvl)
	{
		if ($op1 =~ /^(.*?)\,(.*)$/)
		{
			my $o1 = $1;
			my $o2 = $2;
			if ($o1 =~ /^.*?\..*?$/)
			{
				$op1 = $self->_getAliasCols(15,$o1,$result+SQL_SIMPLE_ALIAS_FQDN);
			}
			else
			{
				$op1 = $self->_getAliasCols(16,$o1,$result);
			}
			$op1 .= ",".$o2;
		}
		else
		{
			if ($op1 =~ /^.*?\..*?$/)
			{
				$op1 = $self->_getAliasCols(17,$op1,$result+SQL_SIMPLE_ALIAS_FQDN);
			}
			else
			{
				$op1 = $self->_getAliasCols(18,$op1,$result);
			}
		}
		${$value1} = $fnc.$op1.$op2;
	}
	return $lvl;
}

################################################################################
## action: test the argv->{table} and create the tables_inuse list

sub _checkTablesEntries()
{
	my $self = shift;
	my $cmnd = shift;
	my $argv = shift;

	## tables is missing?
	if (!defined($argv->{table}))
	{
		$self->_setMessage($cmnd,SQL_SIMPLE_RC_SYNTAX,"005");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## validate tables
	my $tables_work;
	if	(ref($argv->{table}) eq "")
	{
		$tables_work = [$argv->{table}];
	}
	elsif	(ref($argv->{table}) eq "ARRAY" && ($self->{work}{command} == SQL_SIMPLE_ALIAS_SELECT || $self->{work}{command} == SQL_SIMPLE_ALIAS_UPDATE))
	{
		$tables_work = $argv->{table};
	}
	else
	{
		$self->_setMessage($cmnd,SQL_SIMPLE_RC_SYNTAX,"006");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## assign table as in use
	$self->{work}{tables_valids} = [];
	foreach my $table(@{$tables_work})
	{
		if (grep(/^$table$/,@{$self->{work}{tables_inuse}}))
		{
			$self->_setMessage($cmnd,SQL_SIMPLE_RC_SYNTAX,"033",$table);
			return SQL_SIMPLE_RC_SYNTAX;
		}
		if (defined($self->{argv}{tables}))
		{
			## defined as alias in content tables?
			if (defined($self->{argv}{tables}{$table}) && defined($self->{argv}{tables}{$table}{name}))
			{
				my $realname = $self->{argv}{tables}{$table}{name};
				if (defined($self->{work}{tables_alias}{$realname}))
				{
					$self->_setMessage($cmnd,SQL_SIMPLE_RC_SYNTAX,"033",$table);
					return SQL_SIMPLE_RC_SYNTAX;
				}
				push(@{$self->{work}{tables_inuse}},$realname);
				$self->{work}{tables_alias}{$realname} = $table;
				push(@{$self->{work}{tables_valids}},$table);
				next;
			}
			elsif (defined($self->{init}{table_realname}{$table}))
			{
				$self->{work}{tables_alias}{$table} = $self->{init}{table_realname}{$table};
				push(@{$self->{work}{tables_valids}},$self->{init}{table_realname}{$table});
			}
		}
		push(@{$self->{work}{tables_inuse}},$table);
	}
	push(@{$self->{work}{tables_valids}},@{$self->{work}{tables_inuse}});
	return SQL_SIMPLE_RC_OK;
}

################################################################################
## action: set last command sql
## return: none

sub _setLastSQL()
{
	$_[0]->{init}{sql_command} = $_[1];
}

################################################################################
## action: set commit
## return: old commit

sub _setCommit()
{
	my $self = shift;
	my $save = $self->{argv}{commit};
	$self->{argv}{commit} = shift || 0;
	return $save;
}

################################################################################
## action: set message_log
## return: old message_log

sub _setLogMessage()
{
	my $self = shift;
	my $save = $self->{argv}{message_log};
	$self->{argv}{message_log} = shift || 0 ;
	return $save;
}

################################################################################
## action: set sql_save
## return: old sql_save

sub _setSqlSave()
{
	my $self = shift;
	my $save = $self->{argv}{sql_save};
	$self->{argv}{sql_save} = shift || 0;
	return $save;
}

################################################################################
## action: set quote character
## return: old quote chacracter

sub _setQuote()
{
	my $self = shift;
	my $quote = shift;
	my $save = $self->{argv}{quote};
	$self->{argv}{quote} = $quote || "'" if ($quote eq "" || $quote eq '"' || $quote eq "'");
	return $save;
}

################################################################################
## action: escape quote in string
## return: string with escape (if exists)

sub _escapeQuote()
{
	my $self = shift;
	my $value = shift;
	
	## return if not quote
	return $value if ($self->{argv}{quote} eq "");
	
	## escape and return
	$value =~ s/$self->{argv}{quote}/\\$self->{argv}{quote}/g;
	return $value;
}

################################################################################
## action: cleanup the last session call
## return: return code

sub _resetSession()
{
	my $self = shift;
	$err = 0;
	$errstr = "";
	$self->_setLastSQL("");
	delete ($self->{work});
	$self->{work} = {};
}

################################################################################
## action: set message state
## return: return code

sub _setMessage()
{
	my $self = shift;
	my $command = shift;
	my $rc = shift;
	my $code = shift;
	my @argv = @_;

	if (!defined($rc))
	{
		return $self->_setMessage($command,$self->{init}{dbh}->err+0,"099",$self->{init}{dbh}->errstr()) if (defined($self->{init}{dbh}) && $self->{init}{dbh}->err);
		return $self->_setMessage($command,$DBI::err+0,"099",$DBI::errstr) if ($DBI::err);

		$err = 0;
		$errstr = "";
		return $err;
	}

	$err = $rc;
	$errstr = (defined($SQL_SIMPLE_TABLE_OF_MSGS{$code})) ?
		$code.$SQL_SIMPLE_TABLE_OF_MSGS{$code}{T}." ".sprintf($SQL_SIMPLE_TABLE_OF_MSGS{$code}{M},$command,@argv) :
		"999S [message] invalid message code '$code'";

	if ($self->{argv}{message_log})
	{
		print STDERR $errstr."\n" if ($self->{argv}{message_log} & SQL_SIMPLE_LOG_STD);

		if ($self->{argv}{message_log} & SQL_SIMPLE_LOG_SYS)
		{
			require Sys::Syslog;
			openlog($self->{argv}{message_syslog_service} || "SQL-SimpleOps", "ndelay,pid", $self->{argv}{message_syslog_facility} || "local0");
			syslog(
				($SQL_SIMPLE_TABLE_OF_MSGS{$code}{T} eq "E") ? "error" :
				($SQL_SIMPLE_TABLE_OF_MSGS{$code}{T} eq "S") ? "error" :
				($SQL_SIMPLE_TABLE_OF_MSGS{$code}{T} eq "W") ? "warning" :
				"info",
				$errstr
			);
			closelog();
		}
	}
	return $err;
}

################################################################################
## action: enable/disable show dumper data at each call
## note: used for debug mode only.

sub setDumper()
{
	my $self = shift;
	return $self->{init}{dumper} = shift;
}

sub _Dumper()
{
	my $self = shift;
	my $call = shift;
	my $argv = shift;

	return if (!$self->{init}{dumper});

	require Data::Dumper;
	$Data::Dumper::Sortkeys = \sub { my ($hash) = @_; return [ (sort keys %$hash) ]; };

	my $dumper = new Data::Dumper([$argv]);

	$dumper->Terse(1);

	print STDERR $call." = ".$dumper->Dump;
}

__END__
