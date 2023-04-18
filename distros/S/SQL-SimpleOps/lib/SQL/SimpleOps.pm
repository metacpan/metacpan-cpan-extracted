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
		Update Commit Close Call Wait
		getDBH getMessage getRC getRows
		getLastCursor getLastSQL getLastSave getWhere
		getAliasTable getAliasCols

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

	our $VERSION = "2023.106.1";

	our @EXPORT_OK = @EXPORT;

	our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

################################################################################
## literals initialization

	use constant SQL_SIMPLE_DB_PG => 1;		# engine postgres
	use constant SQL_SIMPLE_DB_MARIADB => 2;	# engine mariadb/mysql
	use constant SQL_SIMPLE_DB_SQLLITE3 => 3;	# engine sqlite3

	use constant SQL_SIMPLE_CURSOR_TOP => 1;	# page first
	use constant SQL_SIMPLE_CURSOR_BACK => 2;	# page backward
	use constant SQL_SIMPLE_CURSOR_NEXT => 3;	# page next
	use constant SQL_SIMPLE_CURSOR_LAST => 4;	# page last
	use constant SQL_SIMPLE_CURSOR_RELOAD => 5;	# page current

	use constant SQL_SIMPLE_ORDER_OFF => undef;	# order disabled
	use constant SQL_SIMPLE_ORDER_ASC => 1;		# order asceding
	use constant SQL_SIMPLE_ORDER_DESC => 2;	# order descending

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

################################################################################
## local environments
	
	our $SQL_SIMPLE_CLASS = "SQL::SimpleOps";

	our %SQL_SIMPLE_TABLE_OF_MSGS =
	(
		"001" => { T=>"E", M=>"[%s] Database is missing" },
		"002" => { T=>"E", M=>"[%s] Server is missing" },
		"003" => { T=>"E", M=>"[%s] Interface invalid" },
		"004" => { T=>"S", M=>"[%s] The Database driver is omitted or empty" },
		"005" => { T=>"E", M=>"[%s] Table is missing" },
		"006" => { T=>"E", M=>"[%s] Table invalid, must be single-value or array" },
		"007" => { T=>"E", M=>"[%s] Fields invalid, must be array" },
		"008" => { T=>"E", M=>"[%s] Group_by invalid, must be single-value or array" },
		"009" => { T=>"E", M=>"[%s] Order_by invalid, must be single-value or array-pairs" },
		"010" => { T=>"E", M=>"[%s] Table/Field Index invalid" },
		"011" => { T=>"E", M=>"[%s} Stat File error, %s" },
		"012" => { T=>"I", M=>"[%s] Key not found" },
		"013" => { T=>"E", M=>"[%s] Cursor is missing or invalid" },
		"014" => { T=>"E", M=>"[%s] Cursor-key is missing or invalid" },
		"015" => { T=>"E", M=>"[%s] Cursor Command invalid" },
		"016" => { T=>"W", M=>"[%s] Key is missing, option 'force' is required" },
		"017" => { T=>"E", M=>"[%s] Fields is missing" },
		"018" => { T=>"E", M=>"[%s] Fields Format error, must be hash-pairs or arrayref" },
		"019" => { T=>"E", M=>"[%s] Interface '%s::%s' missing" },
		"020" => { T=>"E", M=>"[%s] Where Clause invalid" },
		"021" => { T=>"E", M=>"[%s] Field invalid, must be single-value or array" },
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
		"038" => { T=>"E", M=>"[%s] Syslog Service invalid, must contains 'alphanumeric' characters" },
		"040" => { T=>"E", M=>"[%s] Log File invalid, must contains 'alphanumeric' characters" },
		"041" => { T=>"E", M=>"[%s] Values Format error, must be arrayref" },
		"042" => { T=>"E", M=>"[%s] Conflict/Duplicate Format error, must be hashref" },
		"043" => { T=>"E", M=>"[%s] Limit is missing" },
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
			&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"011",$self->{argv}{configfile});
			return undef;
		}
		my $fh = new IO::File($self->{argv}{configfile});
		if (!defined($fh))
		{
			&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"026",$!);
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

	## mandatory itens
    if (!grep(/^$self->{argv}{interface}$/i,"dbi"))
	{
		&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"003");
	       	return undef;
       	}
	## check interface/driver(plugin)
	if (!defined($self->{argv}{driver}))
	{
		&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"004");
		return undef;
	}
	elsif (grep(/^$self->{argv}{driver}$/i,"pg","postgres","postsql","pgsql"))
	{
		return undef if (!&_newTestServer($self));

		$self->{init}{driver_id} = SQL_SIMPLE_DB_PG;
		$self->{init}{plugin_id} = "PG";
		$self->{init}{schema} = 1;
	}
	elsif (grep(/^$self->{argv}{driver}$/i,"mysql","mariadb"))
	{
		return undef if (!&_newTestServer($self));

		$self->{init}{driver_id} = SQL_SIMPLE_DB_MARIADB;
		$self->{init}{plugin_id} = "MySQL";
		$self->{init}{schema} = 0;
	}
	elsif (grep(/^$self->{argv}{driver}$/i,"sqlite","sqlite3"))
	{
		if ($self->{argv}{db} eq "" && $self->{argv}{dbfile} eq "")
		{
			&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"001");
			return undef;
		}
		$self->{init}{driver_id} = SQL_SIMPLE_DB_SQLLITE3;
		$self->{init}{plugin_id} = "SQLite";
		$self->{init}{schema} = 0;
	}
	else
	{
		&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"004");
		return undef;
	}
	## check aliases table
	if (defined($self->{argv}{tables}))
	{
		if (ref($self->{argv}{tables}) ne "HASH")
		{
			&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"030");
			return undef;
		}
		foreach my $table(keys(%{$self->{argv}{tables}}))
		{
			if (!defined($self->{argv}{tables}{$table}{name}) || $self->{argv}{tables}{$table}{name} eq "")
			{
				&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"034",$table);
				return undef;
			}
			if (defined($self->{argv}{tables}{$table}{cols}))
			{
				if (ref($self->{argv}{tables}{$table}{cols}) ne "HASH")
				{
					&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"031",$table);
					return undef;
				}
				foreach my $field(keys(%{$self->{argv}{tables}{$table}{cols}}))
				{
					if ($self->{argv}{tables}{$table}{cols}{$field} eq "")
					{
						&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"032",$field);
						return undef;
					}
				}
			}
		}
	}
	## check syslog options
	if (defined($self->{argv}{message_syslog_facility}) && !($self->{argv}{message_syslog_facility} =~ /^local[0-7]$/i))
	{
		&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"038",$self->{argv}{message_syslog_facility});
		return undef;
	}
	if (defined($self->{argv}{message_syslog_service}) && ($self->{argv}{message_syslog_service} =~ s/[a-zA-Z0-9\-\_]//g))
	{
		&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"039",$self->{argv}{message_syslog_service});
		return undef;
	}
	if (defined($self->{argv}{sql_save_name}) && ($self->{argv}{sql_save_name} =~ s/[a-zA-Z0-9\-\_]//g))
	{
		&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"040",$self->{argv}{sql_save_name});
		return undef;
	}
	## load interface type
       	if ($self->{argv}{interface} =~ /^dbi$/i)
	{
		$self->{argv}{interface} = "DBI";
		$self->{argv}{interface_options}{RaiseError} = 0 if (!defined($self->{argv}{interface_options}{RaiseError}));
		$self->{argv}{interface_options}{PrintError} = 0 if (!defined($self->{argv}{interface_options}{PrintError}));
	}
	else { return undef; }

	## load pluging
	## making: dsname option and more
	if (defined($self->{init}{plugin_id}) && $self->{init}{plugin_id} ne "")
	{
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
			&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"019",$self->{argv}{interface},$self->{init}{plugin_id});
			return undef;
		}
		eval { require $fn; };
		if ($@)
		{
			&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"035",$self->{argv}{interface},$self->{init}{plugin_id},$@);
			return undef;
		}
		$self->{init}{plugin_fh} = $plugin->new(sql_simple => $self);
		if (!defined($self->{init}{plugin_fh}))
		{
			&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"035",$self->{argv}{interface},$self->{init}{plugin_id},$@);
			return undef;
		}
	}
	## new object
	my $bless = bless($self,$class);
	return undef if (!defined($bless));

	## my first connect
	return undef if ($self->{argv}{connect} && $self->Open());

	## successful
	$bless;
}

################################################################################
## action: test server/tcpport for remote databases
##	rc=0	syntax error
##	rc=1	successful
#
sub _newTestServer()
{
	my $self = shift;
	if ($self->{argv}{server} eq "")
	{
		&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"002");
		return undef;
	}
	if ($self->{argv}{port} ne "" && (($self->{argv}{port} =~ /^\D+$/) || ($self->{argv}{port} < 1 || $self->{argv}{port} > 65535)))
	{
		&setMessage($self,"new",SQL_SIMPLE_RC_SYNTAX,"029");
		return undef;
	}
	return 1;
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

	if ($self->{init}{plugin_fh}->can('Open') && $self->{init}{plugin_fh}->Open())
	{
		$self->setMessage("open",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if ($self->{argv}{interface} =~ /^dbi$/i)
	{
		$self->{init}{dbh} = DBI->connect(
			$self->{argv}{dsname},  $self->{argv}{login}, $self->{argv}{password}, \%{$self->{argv}{interface_options}});
		$self->setMessage("open");
		return $self->getRC();
	}
	return SQL_SIMPLE_RC_SYNTAX;
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

	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{init}{command} = "select";

	if ($self->{init}{plugin_fh}->can('SelectCursor') && $self->{init}{plugin_fh}->SelectCursor($argv))
	{
		$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_message_log = $self->setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_SelectCursor(%{$argv});

	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->setQuote($saved_quote) if (defined($argv->{quote}));
	$self->setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _SelectCursor()
{
	my $self = shift;
	my $argv = {@_};

	## check mandatory options
	if ($argv->{cursor_command} != SQL_SIMPLE_CURSOR_TOP && $argv->{cursor_command} != SQL_SIMPLE_CURSOR_LAST)
	{
		if (!defined($argv->{cursor}) || $argv->{cursor} eq "")
		{
			if (!defined($argv->{cursor_info}))
			{
				$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"013");
				return SQL_SIMPLE_RC_SYNTAX;
			}
			my ($first,$last);
			if	(ref($argv->{cursor_info}) eq "HASH") { ($first,$last) = ($argv->{cursor_info}{first},$argv->{cursor_info}{last}); }
			elsif	(ref($argv->{cursor_info}) eq "ARRAY") { ($first,$last) = ($argv->{cursor_info}[2],$argv->{cursor_info}[3]); }
			elsif	(ref($argv->{cursor_info}) eq "SCALAR") { my @a=split(" ",$argv->{cursor_info}); ($first,$last) = ($a[2],$a[3]); }
			else
			{
				$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"013");
				return SQL_SIMPLE_RC_SYNTAX;
			}
			if	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_NEXT) { $argv->{cursor} = $last; $argv->{cursor_command} = SQL_SIMPLE_CURSOR_TOP if (!defined($last));}
			elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_BACK) { $argv->{cursor} = $first; $argv->{cursor_command} = SQL_SIMPLE_CURSOR_LAST if (!defined($first));}
			elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_RELOAD) { $argv->{cursor} = $first; }
		}
	}
	if (!defined($argv->{cursor_key}) || ref($argv->{cursor_key}) ne "")
	{
		$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"014");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (defined($argv->{where}) && ref($argv->{where}) ne "ARRAY")
	{
		$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"021");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	## have order by?
	my @order;
	if	(!defined($argv->{order_by})) {}
	elsif	(ref($argv->{order_by}) eq "") { @order = ($argv->{order_by}); }
	elsif	(ref($argv->{order_by}) eq "ARRAY") { @order = @{$argv->{order_by}}; }
	else
	{
		$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"009");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## test the type of cursor
	if	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_TOP)
	{
		unshift(@order,$argv->{cursor_key} => SQL_SIMPLE_ORDER_ASC);
	}
	elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_BACK)
	{
		unshift(@order,$argv->{cursor_key} => SQL_SIMPLE_ORDER_DESC);

		unshift(@{$argv->{where}}, $argv->{cursor_key} => [ "<", $argv->{cursor} ]);
	}
	elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_NEXT || $argv->{cursor_command} == SQL_SIMPLE_CURSOR_RELOAD)
	{
		unshift(@order,$argv->{cursor_key} => SQL_SIMPLE_ORDER_ASC);

		unshift(@{$argv->{where}}, $argv->{cursor_key} => [ ">", $argv->{cursor} ]);
	}
	elsif	($argv->{cursor_command} == SQL_SIMPLE_CURSOR_LAST)
	{
		unshift(@order,$argv->{cursor_key} => SQL_SIMPLE_ORDER_DESC);
	}
	else
	{
		$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"015");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (!defined($argv->{limit}) || $argv->{limit} eq "")
	{
		$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"043");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## format o order options
	unshift(@{$argv->{order_by}},@order) if (@order);

	## define notfound if not exists
	$argv->{notfound} = 1 if (!defined($argv->{notfound}));

	## execute and save cursor info
	return $self->{init}{cursor}{rc} if ($self->{init}{cursor}{rc} = $self->_Select(%{$argv}));

	$self->{init}{cursor}{lines} = $self->getRows();

	($self->{init}{cursor}{first},$self->{init}{cursor}{last}) =
       		($self->{init}{cursor}{lines}) ?
		( $argv->{buffer}[0]{$argv->{cursor_key}}, $argv->{buffer}[$self->{init}{cursor}{lines}-1]{$argv->{cursor_key}} ):
		( 0, 0 );

	## return cursor info
	if	(!defined($argv->{cursor_info})) {}
	elsif	(ref($argv->{cursor_info}) eq "HASH")
	{
		$argv->{cursor_info}->{rc} = $self->{init}{cursor}{rc};
		$argv->{cursor_info}->{lines} = $self->{init}{cursor}{lines};
		($argv->{cursor_info}->{first},$argv->{cursor_info}->{last}) = ($argv->{cursor_command} == SQL_SIMPLE_CURSOR_BACK) ?
			($self->{init}{cursor}{last},$self->{init}{cursor}{first}) :
			($self->{init}{cursor}{first},$self->{init}{cursor}{last});
	}
	elsif (ref($argv->{cursor_info}) eq "ARRAY")
	{
		$argv->{cursor_info}->[0] = $self->{init}{cursor}{rc};
		$argv->{cursor_info}->[1] = $self->{init}{cursor}{lines};
		($argv->{cursor_info}->[2],$argv->{cursor_info}->[3]) = ($argv->{cursor_command} == SQL_SIMPLE_CURSOR_BACK) ?
			($self->{init}{cursor}{last},$self->{init}{cursor}{first}) :
			($self->{init}{cursor}{first},$self->{init}{cursor}{last});
	}
	elsif (ref($argv->{cursor_info}) eq "SCALAR")
	{
		my @a = split(" ",${$argv->{cursor_info}});
		$argv->{cursor_info} = $self->{init}{cursor}{rc}." ".$self->{init}{cursor}{lines}." ".$a[2]." ".$a[3];
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

	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{init}{command} = "select";

	if ($self->{init}{plugin_fh}->can('Select') && $self->{init}{plugin_fh}->Select($argv))
	{
		$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_message_log = $self->setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Select(%{$argv});

	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->setQuote($saved_quote) if (defined($argv->{quote}));
	$self->setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _Select()
{
	my $self = shift;
	my $argv = {@_};

	## check mandatory options
	if (!defined($argv->{table}))
	{
		$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"005");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	my @tables_work;
	if	(ref($argv->{table}) eq "") { @tables_work = ($argv->{table}); }
	elsif	(ref($argv->{table}) eq "ARRAY")
	{
		my %tables_tmp;
		foreach my $table(@{$argv->{table}})
		{
			if ($tables_tmp{$table})
			{
				$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"033",$table);
				return SQL_SIMPLE_RC_SYNTAX;
			}
			$tables_tmp{$table}=1;
		}
	    @tables_work = @{$argv->{table}};
    }
	else
	{
		$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"006");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	my @fields_work;
	my %fields_distinct;
	if (defined($argv->{fields}))
        {
		if (ref($argv->{fields}) ne "ARRAY")
		{
			$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"007");
			return SQL_SIMPLE_RC_SYNTAX;
		}
		for (my $ix=0; $ix < @{$argv->{fields}}; $ix++)
		{
			my $field = $argv->{fields}[$ix];
			my $distinct;
			if ($field =~ /^distinct$/i)
			{
				$field = $argv->{fields}[++$ix];
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
					my $table = $1;
					if (!grep(/^$table$/i,@tables_work))
					{
						$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"010");
						return SQL_SIMPLE_RC_SYNTAX;
					}
				}
			}
			push(@fields_work,$field);
			$fields_distinct{$field} = 1 if ($distinct);
		}
	}
	else
	{
		if (@tables_work > 1)
		{
			foreach my $table(@tables_work)
			{
				if (!defined($self->{argv}{tables}{$table}) || !defined($self->{argv}{tables}{$table}{cols}))
				{
					$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"010");
					return SQL_SIMPLE_RC_SYNTAX;
				}
				foreach my $field(sort(keys(%{$self->{argv}{tables}{$table}{cols}})))
				{
					push(@fields_work,$table.".".$field);
				}
			}
		}
		else
		{
			if (defined($self->{argv}{tables}{$tables_work[0]}) && defined($self->{argv}{tables}{$tables_work[0]}{cols}))
			{
				push(@fields_work,sort(keys(%{$self->{argv}{tables}{$tables_work[0]}{cols}})));
			}
		}
	}
	my @group_work;
	if (defined($argv->{group_by}))
	{
		if	(ref($argv->{group_by}) eq "") { @group_work = ($argv->{group_by}); }
		elsif	(ref($argv->{group_by}) eq "ARRAY") { push(@group_work,@{$argv->{group_by}}); }
		else
		{
			$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"008");
			return SQL_SIMPLE_RC_SYNTAX;
		}
	}
	my @order_work;
	if (defined($argv->{order_by}))
	{
		if	(ref($argv->{order_by}) eq "") { @order_work = ($argv->{order_by}); }
		elsif	(ref($argv->{order_by}) eq "ARRAY")
		{
			if (@{$argv->{order_by}} == 1) { @order_work = @{$argv->{order_by}}; }
			if (@{$argv->{order_by}} % 2 != 0)
			{
				$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"009");
				return SQL_SIMPLE_RC_SYNTAX;
			}
		       	push(@order_work,@{$argv->{order_by}});
		}
		else
		{
			$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"009");
			return SQL_SIMPLE_RC_SYNTAX;
		}
	}
	## making fields
	my $middle = ($self->{init}{driver_id} == SQL_SIMPLE_DB_PG) ? " AS " : " ";
	my @fields;
	my $table = $tables_work[0];
	if (@fields_work)
	{
		foreach my $field(@fields_work)
		{
			my $distinct = ($fields_distinct{$field}) ? "DISTINCT " : "";
			## escape?
			if ($field =~ /^\\(.*)/)
			{
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
				my $table = $1;
				my $field = $2;
				my $realn = $self->getAliasCols($table,$field);
				($field ne $realn) ?
					push(@fields,$distinct.$field_a.$table.".".$realn.$field_b." ".$table."_".$field) :
					push(@fields,$distinct.$field_a.$table.".".$realn.$field_b);
			}
			else
			{
				if (@tables_work == 1)
				{
					my $realn = $self->getAliasCols($table,$field);
					($field ne $realn) ?
						push(@fields,$distinct.$field_a.$realn.$field_b." ".$field) :
						push(@fields,$distinct.$field_a.$field.$field_b);
				}
				else { push(@fields,$distinct.$field); }
			}
		}
	}
	else
	{
		push(@fields,"*");
	}
	## make where
	my $where;
	return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhere("select",\@tables_work,$argv->{where},\$where));

	## make order
	my @order;
	while (@order_work)
	{
		my $field = shift(@order_work);
		if ($field =~ /^(.*?)\.(.*?)$/)
		{
			my $table = $1;
			my $field = $2;
			$field = $table.".".$self->getAliasCols($table,$field);
		}
		else
		{
			$field = $self->getAliasCols($table,$field);
		}
		if (@order_work)
		{
			my $ordem = shift(@order_work);
			$field .= " ".(($ordem == SQL_SIMPLE_ORDER_DESC) ? 'DESC' : ($ordem == SQL_SIMPLE_ORDER_ASC) ? 'ASC' : $ordem);
		}
		push(@order,$field);
	}
	## make tables
	my @tables;
	foreach my $table(@tables_work)
	{
		push(@tables,$self->getAliasTable($table,1));
	}

	## build sql command
	my $sql = "SELECT ".join(", ",@fields)." FROM ".join(", ",@tables);
	$sql .= " WHERE ".$where if ($where);
	$sql .= " GROUP BY ".join(", ",@group_work) if (@group_work);
	$sql .= " ORDER BY ".join(", ",@order) if (@order);
	$sql .= " LIMIT ".$argv->{limit} if (defined($argv->{limit}) && $argv->{limit} > 0);

	## execute
	return SQL_SIMPLE_RC_ERROR if ($self->_Call(
		command => $sql,
		command_type => 0,			# (ZERO is read)
		buffer => $argv->{buffer},
		buffer_options => $argv->{buffer_options},
		make_only => $argv->{make_only},
		flush => $argv->{flush},
		sql_save => $argv->{sql_save},
	));
	return SQL_SIMPLE_RC_OK if ($self->getRows());
	return SQL_SIMPLE_RC_OK if ($argv->{notfound});

	$self->setMessage("select",SQL_SIMPLE_RC_SYNTAX,"012");
	return SQL_SIMPLE_RC_EMPTY;
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

	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{init}{command} = "delete";

	if ($self->{init}{plugin_fh}->can('Delete') && $self->{init}{plugin_fh}->Delete($argv))
	{
		$self->setMessage("delete",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_commit = $self->setCommit($argv->{commit}) if (defined($argv->{commit}));
	my $saved_message_log = $self->setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Delete(%{$argv});

	$self->setCommit($saved_commit) if (defined($argv->{commit}));
	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->setQuote($saved_quote) if (defined($argv->{quote}));
	$self->setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _Delete()
{
	my $self = shift;
	my $argv = {@_};

	## check mandatory options
	if (!defined($argv->{table}) && ref($argv->{table}) ne "")
	{
		$self->setMessage("delete",SQL_SIMPLE_RC_SYNTAX,"005");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## make where
	my $where;
	return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhere("delete",[$argv->{table}],$argv->{where},\$where));
	if ((!defined($where) || $where eq "") && !$argv->{force})
	{
		$self->setMessage("delete",SQL_SIMPLE_RC_SYNTAX,"016");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## build sql command
	my $sql = "DELETE FROM ".$self->getAliasTable($argv->{table},0);
	$sql .= " WHERE ".$where if ($where);

	return SQL_SIMPLE_RC_ERROR if ($self->_Call(
		command => $sql,
		command_type => 1,			# (NOT_ZERO is update)
		buffer => $argv->{buffer},
		buffer_options => $argv->{buffer_options},
		make_only => $argv->{make_only},
		flush => $argv->{flush},
		sql_save => $argv->{sql_save},
	));
	return SQL_SIMPLE_RC_OK if ($argv->{notfound});
	if ($self->getRows() == 0)
	{
		$self->setMessage("delete",SQL_SIMPLE_RC_SYNTAX,"012");
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

	## define the command in load
	$self->{init}{command} = "insert";

	$self->Open() if (!defined($self->{init}{dbh}));

	if ($self->{init}{plugin_fh}->can('Insert') && $self->{init}{plugin_fh}->Insert($argv))
	{
		$self->setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_commit = $self->setCommit($argv->{commit}) if (defined($argv->{commit}));
	my $saved_message_log = $self->setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Insert(%{$argv});

	$self->setCommit($saved_commit) if (defined($argv->{commit}));
	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->setQuote($saved_quote) if (defined($argv->{quote}));
	$self->setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _Insert()
{
	my $self = shift;
	my $argv = {@_};

	## check mandatory options
	if (!defined($argv->{table}) && ref($argv->{table}) ne "")
	{
		$self->setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"005");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (!defined($argv->{fields}))
	{
		$self->setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"017");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if	(ref($argv->{fields}) eq "HASH") {}
	elsif	(ref($argv->{fields}) eq "ARRAY")
	{
		if (!defined($argv->{values}))
		{
			$self->setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"027");
			return SQL_SIMPLE_RC_SYNTAX;
		}
		if (ref($argv->{values}) ne "ARRAY")
		{
			$self->setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"041");
			return SQL_SIMPLE_RC_SYNTAX;
		}
	}
	else
	{
		$self->setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"018");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (defined($argv->{conflict}) && ref($argv->{conflict}) ne "HASH")
	{
		$self->setMessage("insert",SQL_SIMPLE_RC_SYNTAX,"042");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## making fields
	my @fields;
	my @values;
	if (ref($argv->{fields}) eq "HASH")
	{
		my @line;
		foreach my $field(sort(keys(%{$argv->{fields}})))
		{
			push(@fields,$self->getAliasCols($argv->{table},$field));
			push(@line,$argv->{fields}{$field});
		}
		push(@values,"(".$self->{argv}{quote}.join($self->{argv}{quote}.",".$self->{argv}{quote},@line).$self->{argv}{quote}.")");
	}
	else
	{
		my $no_fld = @{$argv->{fields}};
		foreach my $field(@{$argv->{fields}})
		{
			push(@fields,$self->getAliasCols($argv->{table},$field));
		}
		foreach my $values(@{$argv->{values}})
		{
			if ($no_fld == 1)
			{
				if (ref($values) eq "ARRAY")
				{
					push(@values,"(".$self->{argv}{quote}.join($self->{argv}{quote}."),(".$self->{argv}{quote},@{$values}).$self->{argv}{quote}.")");
				}
				else
				{
					push(@values,"(".$self->{argv}{quote}.$values.$self->{argv}{quote}.")");
				}
			}
			else
			{
				if (ref($values) eq "ARRAY")
				{
					push(@values,"(".$self->{argv}{quote}.join($self->{argv}{quote}.",".$self->{argv}{quote},@{$values}).$self->{argv}{quote}.")");
				}
				else
				{
					push(@values,"(".$self->{argv}{quote}.join($self->{argv}{quote}.",".$self->{argv}{quote},@{$argv->{values}}).$self->{argv}{quote}.")");
					goto EXIT_VALUES;
				}
			}
		}
		EXIT_VALUES:
	}
	## build sql
	my $sql = "INSERT INTO ".$self->getAliasTable($argv->{table},0)." (".join(",",@fields).") VALUES ".join(",",@values);
	if (defined($argv->{conflict}))
	{
		my @conflict;
		foreach my $field(sort(keys(%{$argv->{conflict}})))
		{
			($argv->{conflict}{$field} =~ /^\\(.*)/) ?
				push(@conflict,$self->getAliasCols($argv->{table},$field)." = ".$1): 
				push(@conflict,$self->getAliasCols($argv->{table},$field)." = ".$self->{argv}{quote}.$argv->{conflict}{$field}.$self->{argv}{quote});
		}
		$sql .= ($self->{init}{plugin_id} =~ /^mysql/i || $self->{init}{plugin_id} =~ /^mariadb/i) ?
			" ON DUPLICATE KEY UPDATE ".join(", ",@conflict) :
		       	" ON CONFLICT ".(($argv->{conflict_key})?"(".$self->getAliasCols($argv->{table},$argv->{conflict_key}).") ":"")."DO UPDATE SET ".join(", ",@conflict);
	}
	## execute
	return SQL_SIMPLE_RC_ERROR if ($self->_Call(
		command => $sql,
		command_type => 1,			# (NOT_ZERO is update)
		buffer => $argv->{buffer},
		buffer_options => $argv->{buffer_options},
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

	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{init}{command} = "update";

	if ($self->{init}{plugin_fh}->can('Update') && $self->{init}{plugin_fh}->Update($argv))
	{
		$self->setMessage("update",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_commit = $self->setCommit($argv->{commit}) if (defined($argv->{commit}));
	my $saved_message_log = $self->setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Update(%{$argv});

	$self->setCommit($saved_commit) if (defined($argv->{commit}));
	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->setQuote($saved_quote) if (defined($argv->{quote}));
	$self->setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _Update()
{
	my $self = shift;
	my $argv = {@_};

	## check mandatory options
	if (!defined($argv->{table}) && ref($argv->{table}) ne "")
	{
		$self->setMessage("update",SQL_SIMPLE_RC_SYNTAX,"005");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (!defined($argv->{fields}))
	{
		$self->setMessage("update",SQL_SIMPLE_RC_SYNTAX,"017");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (ref($argv->{fields}) ne "HASH")
	{
		$self->setMessage("update",SQL_SIMPLE_RC_SYNTAX,"018");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## make fields
	my @fields;
	foreach my $field(keys(%{$argv->{fields}}))
	{
		($argv->{fields}{$field} =~ /^\\(.*)/) ?
			push(@fields,$self->getAliasCols($argv->{table},$field)." = ".$1): 
			push(@fields,$self->getAliasCols($argv->{table},$field)." = ".$self->{argv}{quote}.$argv->{fields}{$field}.$self->{argv}{quote});
	}
	## make where
	my $where;
	return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhere("update",[$argv->{table}],$argv->{where},\$where));

	if ((!defined($where) || $where eq "") && !$argv->{force})
	{
		$self->setMessage("update",SQL_SIMPLE_RC_SYNTAX,"016");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## formata o sql
	my $sql = "UPDATE ".$self->getAliasTable($argv->{table},0)." SET ".join(", ",@fields);
	$sql .= " WHERE ".$where if ($where);

	## execute
	return SQL_SIMPLE_RC_ERROR if ($self->_Call(
		command => $sql,
		command_type => 1,			# (NOT_ZERO is update)
		buffer => $argv->{buffer},
		buffer_options => $argv->{buffer_options},
		make_only => $argv->{make_only},
		flush => $argv->{flush},
		sql_save => $argv->{sql_save},
	));
	return SQL_SIMPLE_RC_OK if ($argv->{notfound});
	if ($self->getRows() == 0)
	{
		$self->setMessage("update",SQL_SIMPLE_RC_SYNTAX,"012");
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

	$self->Open() if (!defined($self->{init}{dbh}));

	## define the command in load
	$self->{init}{command} = "call";

	if ($self->{init}{plugin_fh}->can('Call') && $self->{init}{plugin_fh}->Call($argv))
	{
		$self->setMessage("call",SQL_SIMPLE_RC_SYNTAX,"037",$self->{argv}{interface},$self->{argv}{driver},$self->getMessage());
		return SQL_SIMPLE_RC_SYNTAX;
	}

	if ($argv->{command} eq "")
	{
		$self->setMessage("call",SQL_SIMPLE_RC_SYNTAX,"023");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	my $saved_commit = $self->setCommit($argv->{commit}) if (defined($argv->{commit}));
	my $saved_message_log = $self->setLogMessage($argv->{message_log}) if (defined($argv->{message_log}));
	my $saved_quote = $self->setQuote($argv->{quote}) if (defined($argv->{quote}));
	my $saved_sql_save = $self->setSqlSave($argv->{sql_save}) if (defined($argv->{sql_save}));

	my $rc = $self->_Call(%{$argv});

	$self->setCommit($saved_commit) if (defined($argv->{commit}));
	$self->setMessgeLog($saved_message_log) if (defined($argv->{message_log}));
	$self->setQuote($saved_quote) if (defined($argv->{quote}));
	$self->setSqlSave($saved_sql_save) if (defined($argv->{sql_save}));

	return $rc;
}

sub _Call()
{
	my $self = shift;
	my $argv = {@_};

	$self->{init}{sql_command} = $argv->{command};

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
		$self->setMessage("call",SQL_SIMPLE_RC_SYNTAX,"022");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	my $flush_buffer = (!defined($argv->{flush}) || $argv->{flush}) ? 1 : 0;
	my $type;
	if	(!defined($argv->{buffer}))		{}
	elsif	(ref($argv->{buffer}) eq "HASH")	{ $type=1; undef(%{$argv->{buffer}}) if ($flush_buffer); }
	elsif	(ref($argv->{buffer}) eq "ARRAY")	{ $type=2; undef(@{$argv->{buffer}}) if ($flush_buffer); }
	elsif	(ref($argv->{buffer}) eq "CODE")	{ $type=3; }
	elsif	(ref($argv->{buffer}) eq "SCALAR")	{ $type=4; }
	else
	{
		$self->setMessage("call",SQL_SIMPLE_RC_SYNTAX,"024");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## prepare command
	$argv->{command} =~ s/^\s+|\s+$//;
	my $sth = $self->{init}{dbh}->prepare($argv->{command}.( ($argv->{command} =~ /\;$/) ? "":";") );

	## execute command
	if (defined($sth))
	{
		$sth->execute();			# send command to run
		$self->setMessage("call");		# save the current status

		## scan the fields
		if (defined($argv->{buffer}))
		{
			if ($sth->{NUM_OF_FIELDS})
			{
				while (my $ref = $sth->fetchrow_hashref())
				{
					if	($type == 1) { %{$argv->{buffer}} = %{$ref}; }
					elsif	($type == 2) { push(@{$argv->{buffer}},$ref); }
					elsif	($type == 3) { last if (&{$argv->{buffer}}($ref,$argv->{buffer_options})); }
					elsif	($type == 4) { foreach my $id(keys(%{$ref})) { ${$argv->{buffer}} = $ref->{$id}; }}
				}
			}
		}
		$self->{init}{rows} = $sth->rows();	# get number of extracted lines

		## close and commit (if need)
		$sth->finish();
	}
	else
	{
		$self->setMessage("call");
	}
	undef($sth);

	## force commit if required
	$self->Commit(%{$argv}) if ($self->{argv}->{commit} && $argv->{command_type});
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

	return SQL_SIMPLE_RC_OK if (!defined($self->{init}{dbh}));

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

	$self->setMessage("close");

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
	my $path = ($self->{init}{sql_save_bydate}) ?
		File::Spec->catdir($self->{init}{sql_save_dir},substr($today,0,4),substr($today,0,6),$today) :
		$self->{init}{sql_save_dir};

	if (!stat($path) && !&File::Path::mkpath($path))
	{
		$self->setMessage("save",SQL_SIMPLE_RC_ERROR,"025",$!);
		return ($self->{argv}{sql_save_ignore}) ? SQL_SIMPLE_RC_OK : SQL_SIMPLE_RC_ERROR;
	}

	$self->{init}{sql_save_logfile} = File::Spec->catpath("", $path,$self->{init}{sql_save_name}.".".($self->{argv}{db}||"public").".".$today.".".$$.".".(++$self->{init}{sql_save_ix}));
	my $fh = IO::File->new(">".$self->{init}{sql_save_logfile});
	if (!defined($fh))
	{
		$self->setMessage("save",SQL_SIMPLE_RC_ERROR,"026",$!);
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

	## criar as regras de validacao da table, where, buffer.
	## criar as regras de validacao da table, where, buffer.
	## criar as regras de validacao da table, where, buffer.

	my @tables;
	if	(ref($argv->{table}) eq "ARRAY"){ push(@tables,@{$argv->{table}}); }
	elsif	(ref($argv->{table}) eq "")	{ push(@tables,$argv->{table}); }
	else
	{
		$self->setMessage("getWhere",SQL_SIMPLE_RC_SYNTAX,"006");
		return SQL_SIMPLE_RC_SYNTAX;
	}

	return $self->_getWhere("where",\@tables,$argv->{where},$argv->{buffer});
}

sub _getWhere()
{
	my $self = shift;
	my $command = shift;
	my $tables = shift;
	my $where = shift;
	my $buffer = shift;

	## return dummy where
	return SQL_SIMPLE_RC_OK if (!$where);

	## format where
	my @where_local;
	return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhereRecursive($command,0,$tables,$where,\@where_local));

	## return the where clause
	${$buffer} = join(" ",@where_local);
	return SQL_SIMPLE_RC_OK;
}

sub _getWhereRecursive()
{
	my $self = shift;
	my $command = shift;
	my $level = shift;
	my $tables = shift;
	my $where = shift;
	my $buffer = shift;

	## return error if argvs is empty, format error
	if ($where eq "")
	{
		$self->setMessage($command,SQL_SIMPLE_RC_SYNTAX,"020");
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
		$self->setMessage($command,SQL_SIMPLE_RC_SYNTAX,"021");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	## format where
	my @where_tmp;
	my $oper_pend = 0;
	for (my $ix=0; $ix < @{$where};)
	{
		my $value1 = $where->[$ix++];

		if (ref($value1) ne "")
		{
			my @where_aux;
			return SQL_SIMPLE_RC_SYNTAX if ($self->_getWhereRecursive($command,$level+1,$tables,$value1,\@where_aux));

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
			push(@where_tmp,uc($value1));
			$oper_pend = 0;
			next;
		}
		## valida se requer AND/OR
		if ($oper_pend && @where_tmp)
		{
			push(@where_tmp,"AND");
			$oper_pend = 0;
		}
		## convert value1 to realname if possible
		if	($value1 =~ /^\\/) {}
		elsif	(@{$tables} == 1)
		{
			$value1 = $self->getAliasCols($tables->[0],$value1,0);
		}
		elsif	($value1 =~ /^(.*?)\.(.*?)$/ && grep(/^$1$/,@{$tables}))
		{
			$value1 = $self->getAliasCols($1,$2,1);
		}
		else
		{
			$value1 = $self->getAliasCols($tables->[0],$value1,0);
		}
		if ($ix >= @{$where})
		{
			push(@where_tmp,$value1);
			last;
		}
		my $value2 = $where->[$ix++];
		my $quote = $self->{argv}{quote};;

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
					my $not = ($operator eq "!=") ? " NOT" : "";
					(@_value2 == 3 && $_value2[1] eq "..") ?
						push(@where_tmp,$value1.$not." BETWEEN (".$quote.$_value2[0].$quote.",".$quote.$_value2[2].$quote.")") :
						push(@where_tmp,$value1.$not." IN (".$quote.join("$quote,$quote",@_value2).$quote.")");
					next;
				}
			}
			## multiple conditions
			my @where_aux;
			foreach my $value(@_value2)
			{
				if	(defined($value) && $value ne "")
				{
					if ($value =~ /^\\(.*)/)
					{
						push(@where_tmp,$value1." ".$operator." ".$1);
					}
					elsif (@{$tables} == 1)
					{
						push(@where_aux,$value1." ".$operator." ".$quote.$value2_a.$value.$value2_b.$quote);
					}
					elsif ($value =~ /^(.*?)\.(.*?)$/ && grep(/^$1$/,@{$tables}))
					{
						my $_value = $self->getAliasCols($1,$2,1);
						push(@where_aux,$value1." ".$operator." ".$_value);
					}
					else
					{
						push(@where_aux,$value1." ".$operator." ".$quote.$value2_a.$value.$value2_b.$quote);
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
			if ($value2 ne "")
			{
				if ($value2 =~ /^\\(.*)/)
				{
					push(@where_tmp,$value1." = ".$1);
				}
				elsif (@{$tables} == 1)
				{
					push(@where_tmp,$value1." = ".$quote.$value2.$quote);
				}
				elsif ($value2 =~ /^(.*?)\.(.*?)$/ && grep(/^$1$/,@{$tables}))
				{
					my $_value2 = $self->getAliasCols($1,$2,1);
					push(@where_tmp,$value1." = ".$_value2);
				}
				else { push(@where_tmp,$value1." = ".$quote.$value2.$quote); }
			}
			else { push(@where_tmp,$value1." IS NULL"); }
			next;
		}

		## return error if value2 is not array or value type
		$self->setMessage($command,SQL_SIMPLE_RC_SYNTAX,"028");
		return SQL_SIMPLE_RC_SYNTAX;
	}
	if (@where_tmp)
	{
		push(@{$buffer},join(" ",@where_tmp));
		$buffer->[0] = "(".$buffer->[0] if ($level);
		my $n = @{$buffer};
		$buffer->[$n-1] .= ")" if ($level);
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
	my $table = shift;
	my $ident = shift;

	my $schema = ($self->{init}{schema} && defined($self->{argv}{schema}) && $self->{argv}{schema} ne "") ? $self->{argv}{schema}."." : "";

	return (!defined($self->{argv}{tables}) ||
		!defined($self->{argv}{tables}{$table}) ||
		!defined($self->{argv}{tables}{$table}{name}) ||
		$self->{argv}{tables}{$table}{name} eq $table) ?
		$schema.$table :
		($ident) ?
		$schema.$self->{argv}{tables}{$table}{name}." ".$table :
		$schema.$self->{argv}{tables}{$table}{name};
}

##############################################################################
## action: get the table's realname
## return: name of the table

sub getAliasCols()
{
	my $self = shift;
	my $table = shift;
	my $field = shift;
	my $notab = shift;

	return (!defined($self->{argv}{tables}) ||
		!defined($self->{argv}{tables}{$table}) ||
		!defined($self->{argv}{tables}{$table}{cols}) ||
		!defined($self->{argv}{tables}{$table}{cols}{$field})) ?
			(($notab) ? $table.".".$field : $field) :
			(($notab) ? $table.".".$self->{argv}{tables}{$table}{cols}{$field} : $self->{argv}{tables}{$table}{cols}{$field});
}

################################################################################
## action: set commit
## return: old commit

sub setCommit()
{
	my $self = shift;
	my $save = $self->{argv}{commit};
	$self->{argv}{commit} = shift || 0;
	return $save;
}

################################################################################
## action: set message_log
## return: old message_log

sub setLogMessage()
{
	my $self = shift;
	my $save = $self->{argv}{message_log};
	$self->{argv}{message_log} = shift || 0 ;
	return $save;
}

################################################################################
## action: set sql_save
## return: old sql_save

sub setSqlSave()
{
	my $self = shift;
	my $save = $self->{argv}{sql_save};
	$self->{argv}{sql_save} = shift || 0;
	return $save;
}

################################################################################
## action: set quote character
## return: old quote chacracter

sub setQuote()
{
	my $self = shift;
	my $quote = shift;
	my $save = $self->{argv}{quote};
	$self->{argv}{quote} = $quote || "'" if ($quote eq "" || $quote eq '"' || $quote eq "'");
	return $save;
}

################################################################################
## action: set message state
## return: return code

sub setMessage()
{
	my $self = shift;
	my $command = shift;
	my $rc = shift;
	my $code = shift;
	my @argv = @_;

	if (!defined($rc))
	{
		return $self->setMessage($command,$self->{init}{dbh}->err+0,"099",$self->{init}{dbh}->errstr()) if (defined($self->{init}{dbh}) && $self->{init}{dbh}->err);
		return $self->setMessage($command,$DBI::err+0,"099",$DBI::errstr) if ($DBI::err);

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

__END__
