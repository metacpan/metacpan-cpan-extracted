##############################################################################
# Purpose : SQL Shell API
# Author  : John Alden
# Created : Jul 2006 (refactored from sqlsh.pl)
# CVS     : $Header: /home/cvs/software/cvsroot/db_utils/lib/SQL/Shell.pm,v 1.14 2006/12/05 14:31:33 andreww Exp $
###############################################################################

package SQL::Shell;

use strict;

use Carp;
use DBI;
use File::Path;
use IO::File;
use URI::Escape;

use vars qw($VERSION);
$VERSION = ('$Revision: 1.16 $' =~ /([\d\._]+)/)[0];

use constant HISTORY_SIZE => $ENV{HISTSIZE} || $ENV{HISTFILESIZE} || 50;
use vars qw(%Renderers %Commands %Settings);

#Available rendering routines
%Renderers = (
	'delimited' => \&_render_delimited,
	'box' => \&_render_box,
	'spaced' => \&_render_spaced,
	'record' => \&_render_record,
	'sql' => \&_render_sql,
	'xml' => \&_render_xml,
);

#Commands available by default
%Commands = (
	qr/^(list|show) +drivers$/i => \&show_drivers,
	qr/^(?:list|show) datasources (\w+)$/i => \&show_datasources,
	qr/^(show )?history$/i => \&show_history,
	qr/^clear history$/i => \&clear_history,
	qr/^load history from ([\w\-\.\/~]+)$/i => \&load_history,
	qr/^save history to ([\w\-\.\/~]+)$/i => \&save_history,
	qr/^connect (\S+) ?(\S+)? ?(\S+)?/i => \&connect,
	qr/^disconnect$/i => \&disconnect,
	qr/^show +\$dbh +(.*)/i => \&show_dbh,
	qr/^(list|show) +schema$/i => \&show_schema,
	qr/^(list|show) +tablecounts$/i => \&show_tablecounts,	
	qr/^(list|show) +(tables|catalogs|schemas|tabletypes)(?: like)?( .*)?$/i => \&show_objects,
	qr/^(list|show) +charsets$/i => \&show_charsets,	
	qr/^(list|show) +settings$/i => \&show_settings,
	qr/^(?:desc|describe) +(.*)/i => \&describe,
	qr/^((?:select|explain|recv)\s+.*)/is => \&run_query,
	qr/^((?:create|alter|drop|insert|replace|update|delete|grant|revoke|send) .*)/is => \&do_sql,
	qr/^begin work/i => \&begin_work,
	qr/^rollback/i => \&rollback,
	qr/^commit/i => \&commit,
	qr/^wipe(?: all)? tables$/i => \&wipe_tables,
	qr/^load ([^\s]+) into ([\w\-\.\/]+)(?: delimited by (\S+))?(?: (uri-decode))?(?: from (\S+))?(?: to (\S+))?/i => \&load_data,
	qr/^dump (.+) into ([\w\-\.\/~]+)(?: delimited by (\S+))?/i => \&dump_data,
	qr/^set +(.*?)\s+(.*)/i => \&set_param,
	qr/^(?:execute|source) +(.*)/i => \&run_script,
	qr/^no log$/i => \&disable_logging,
	qr/^log +(.*?) +(?:(?:to|into) +)?(.*)/i => \&enable_logging,
);

%Settings = map {$_ => 1} qw(GetHistory SetHistory AddHistory MaxHistory Interactive Verbose NULL Renderer Logger Delimiter Width LogLevel EscapeStrategy AutoCommit LongTruncOk LongReadLen MultiLine);

my %viewable_settings = (
   'auto-commit'            => 'AutoCommit',
    delimiter               => 'Delimiter',
   'enter-whitespace'       => 'EnterWhitespace',
   'escape'                 => 'EscapeStrategy',
    longreadlen             => 'LongReadLen',
    longtruncok             => 'LongTruncOk',
    multiline               => 'MultiLine',
    verbose                 => 'Verbose',
    width                   => 'Width',
);

my %boolean_settings = map {$_ => 1} qw (AutoCommit LongTruncOk MultiLine Verbose);

#######################################################################
#
# Public methods - these should croak on error
#
#######################################################################

sub new 
{
	my ($class, $overrides) = @_;

	#Default storage for history information (used by closures)
	my @history;

	#Default settings	
	my $settings = {
		Interactive => $overrides->{Interactive} || 0,		
		Verbose => $overrides->{Verbose} || 0,		
		Renderer => _renderer($overrides->{Renderer}) || \&_render_box,
		Logger => _renderer($overrides->{Logger}) || \&_render_delimited,
		Delimiter => $overrides->{Delimiter} || "\t",
		Width => $overrides->{Width} || 80,
		MaxHistory => $overrides->{MaxHistory} || HISTORY_SIZE,
		LogLevel => $overrides->{LogLevel},
		AutoCommit => $overrides->{AutoCommit} || 0,
		LongTruncOk => exists $overrides->{LongTruncOk}? $overrides->{LongTruncOk} : 1,
		LongReadLen => $overrides->{LongReadLen} || 512,
		MultiLine => $overrides->{MultiLine} || 0,
		GetHistory => $overrides->{GetHistory} || sub {return \@history},
		SetHistory => $overrides->{SetHistory} || sub {my $n = shift; @history = @$n},
		AddHistory => $overrides->{AddHistory} || sub {push @history, shift()},
		NULL => exists $overrides->{NULL}? $overrides->{NULL} : 'NULL',
	};

	my %commands = %Commands;
	my %renderers = %Renderers;

	my $self = {
		'settings' => $settings,
		'commands' => \%commands,	
		'renderers' => \%renderers,	
		'current_statement' => ''
	};
	return bless($self, $class);
}

sub DESTROY 
{
	my $self = shift;
	if(_is_connected($self->{dbh})) {
		$self->{dbh}->disconnect();
	}
}

sub set
{
	my ($self, $key, $value) = @_;
	croak("Unknown setting: $key") unless $Settings{$key};
	$self->{settings}{$key} = $value;
}

sub get
{
	my ($self, $key) = @_;
	croak("Unknown setting: $key") unless $Settings{$key};
	return $self->{settings}{$key};	
}

sub install_renderers
{
	my ($self, $renderers) = @_;
	croak "install_renderers method should be passed a hashref" unless(ref $renderers eq 'HASH');
	foreach my $k (keys %$renderers) {
		$self->{renderers}{$k} = $renderers->{$k};	
	}
}

sub uninstall_renderers
{
	my ($self, $renderers) = @_;
	$renderers = $self->{renderers} unless defined ($renderers);
	croak "uninstall_renderers method should be passed an arrayref" unless(ref $renderers eq 'ARRAY');
	for(@$renderers) {
		delete $self->{renderers}{$_} or carp("$_ not found in list of renderers");	
	}
}

sub install_cmds
{
	my ($self, $cmds) = @_;
	croak "install_commands method should be passed a hashref" unless(ref $cmds eq 'HASH');
	foreach my $rx(keys %$cmds) {
		$self->{commands}{$rx} = $cmds->{$rx};	
	}
}

sub uninstall_cmds
{
	my ($self, $cmds) = @_;
	$cmds = $self->{commands} unless defined ($cmds);
	croak "uninstall_commands method should be passed an arrayref" unless(ref $cmds eq 'ARRAY');
	for(@$cmds) {
		delete $self->{commands}{$_} or carp("$_ not found in list of commands");	
	}
}

sub execute_cmd
{
	my $self = shift;
	return $self->_execute(@_);
}

sub is_connected
{
	my $self = shift;
	return _is_connected($self->{dbh});
}

sub dsn
{
	my $self = shift;
	return undef unless _is_connected($self->{dbh});
	return sprintf "DBI:%s:%s", $self->{dbh}{Driver}{Name}, $self->{dbh}{Name};
}

sub render_rowset {
	my $self = shift;
	$self->{settings}{Renderer}->($self, \*STDOUT, @_);
}

sub log_rowset {
	my $self = shift;
	$self->{settings}{Logger}->($self, $self->{LogFH}, @_);
}

###############################################
#
# Commands - these should die with /n on error
#
###############################################

sub run_script
{
	my ($self, $script) = @_;
	print "Executing $script\n" if ($self->{settings}{Verbose});
	$script = _expand_filename($script);
	my $file = new IO::File "$script" or die("Unable to open file $script - $!");
	my @cmds = map {chomp; $_} <$file>;
	foreach(@cmds)
	{
		$self->execute_cmd($_) or die("Command '$_' failed - aborting $script");
	}
	return 1;
}

sub load_history 
{
	my $self = shift;
	my $filename = shift || die("You must specify a file to load the history from");

	TRACE("Loading history from $filename");
	my $history = _load_history($filename);		
	$self->{settings}{SetHistory}->($history) if(defined $history);
	return $history;
}

sub clear_history 
{
	my $self = shift;
	TRACE("Clearing history");
	$self->{settings}{SetHistory}->([]);
	return 1;
}

sub save_history 
{
	my $self = shift;
	my $filename = shift || die("You must specify a file to save the history to");
	my $max_size = shift || $self->{settings}{MaxHistory};

	my $history = $self->{settings}{GetHistory}->();
	TRACE("Saving history to $filename (contains ".(scalar @$history)." items)");
	_save_history($history, $filename, $max_size);
	return 1;
}

sub show_history 
{
	my $self = shift;
	my $history = $self->{settings}{GetHistory}->();
	print "\n",(map {"  ".$_."\n"} @$history),"\n";
	return 1;	
}

sub enable_logging
{
	my ($self, $level, $file) = @_;
	die("Unrecognised logging level: $level\n") unless($level =~ /^(commands|queries|all)$/);
	my $settings = $self->{settings};
	$file = _expand_filename($file);
	$self->{LogFH} = new IO::File ">> $file" or die("Unable to open $file for logging - $!\n");
	$settings->{LogLevel} = $level;
	print "Logging $level to $file\n" if($settings->{Verbose});
	return 1;
}

sub disable_logging
{
	my ($self) = @_;
	my $settings = $self->{settings};
	print "Stopped logging $settings->{LogLevel}\n"  if($settings->{Verbose} && defined $self->{LogFH});
	$self->{LogFH} = undef;
	$settings->{LogLevel} = undef;
	return 1;
}

sub connect
{
	my($self, $dsn, $username, $password) = @_;
	my $settings = $self->{settings};

	my $dbh = DBI->connect($dsn, $username, $password,
		{PrintError => 0, RaiseError => 1, LongTruncOk => $settings->{LongTruncOk},
		LongReadLen => $settings->{LongReadLen}});

	eval { $dbh->{AutoCommit} = $settings->{AutoCommit} };
	if ($@ && !$settings->{AutoCommit}) {
		warn "WARNING: $dsn doesn't appear to support transactions\n";
	}

	$self->{dbh} = $dbh;
	return $dbh;
}

sub disconnect
{
	my $self = shift;
	$self->{dbh}->disconnect if _is_connected($self->{dbh});
	$self->{dbh} = undef;
	return 1;
}

sub show_charsets
{
	my ($self) = @_;
	eval {require Locale::Recode};
	die "Locale::Recode is not available.  Please install it if you want character set support.\n" if($@);
	my $charsets = Locale::Recode->getSupported();
	print "\n",(map {"  ".$_."\n"} sort @$charsets),"\n";
	return 1;	
}

sub show_drivers
{
	print "\n",(map {"  ".$_."\n"} DBI->available_drivers()),"\n";
	return 1;
}

sub show_datasources
{
	my ($self, $driver) = @_;	
	print "\n",(map {"  ".$_."\n"} DBI->data_sources($driver)),"\n";
	return 1;
}

sub show_dbh
{
	my ($self, $property) = @_;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";
	$self->render_rowset([$property], [[$dbh->{$property}]]);
	return 1;
}

sub show_schema
{
	my $self = shift;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";

	#Banner
	my($driver, $db, $user) = ($dbh->{Driver}{Name}, $dbh->{Name}, $dbh->{Username});
	my $header = ["Schema dump"];
	my @data = (
		["$driver database $db"],
		["connected as $user"],
		["on ".localtime()],
	);	
	$self->_render_box(\*STDOUT, $header, \@data);
	
	#Each table
	foreach(_list_tables($dbh))
	{
		print "\n";
		$self->_desc_table($_);
	}

	return 1;
}

# Show the viewable settings:
sub show_settings {
    my $self = shift;

    my @header = qw{ PARAMETER VALUE };
    my @data;
    for my $setting (sort keys %viewable_settings) {
        my $value = $self->{settings}->{ $viewable_settings{$setting} };
        $value = '' unless defined $value;
        if ( exists($boolean_settings{ $viewable_settings{$setting} }) ) {
            $value = 'on' if $value eq '1';
            $value = 'off' if $value eq '0';
        }
        if ( $setting eq 'escape' ) {
            my $mapping = {
                'ShowWhitespace' => 'show-whitespace',
                'UriEscape' => 'uri-escape',
                'EscapeWhitespace' => 'escape-whitespace',
                '' => 'off'
            };
            $value = $mapping->{$value};
        }
        push @data, _escape_whitespace([ $setting, $value ]);
    }

    $self->render_rowset(\@header, \@data);
}


# Show tables, schemas, catalogs, or table-types:
sub show_objects {
    my $self = shift;
    my $command = shift;
    my $object = shift;
    my $pattern = shift;

    $pattern = '%' unless defined $pattern;

    my $dbh = $self->_dbh() or die "Not connected to database.\n";
    my $sth = undef;

    if ( $object eq 'catalogs' ){
        $sth = $dbh->table_info($pattern,'','','');
        $self->_list_object_attrib($sth, 'TABLE_CAT');
    }
    elsif ( $object eq 'schemas' ) {
        $sth = $dbh->table_info('',$pattern,'','');
        $self->_list_object_attrib($sth, 'TABLE_SCHEM');
    }
    elsif ( $object eq 'tables' ) {
        if ( $pattern eq '%' ) {
            $sth = $dbh->table_info();
        }
        else {
            $sth = $dbh->table_info('','',$pattern,'');
        }
        $self->_list_object_attrib($sth, 'TABLE_NAME');
    }
    elsif ( $object eq 'tabletypes' ) {
        $sth = $dbh->table_info('','','',$pattern);
        $self->_list_object_attrib($sth, 'TABLE_TYPE');
    }

    return 1;
}

sub show_tablecounts
{
	my $self = shift;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";
	$self->render_rowset([qw(table rows)], _summarise_tables($dbh));
	return 1;
}

sub describe
{
	my ($self, $table) = @_;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";

	$self->_desc_table($table);
	return 1;
}

sub run_query
{
	my ($self, $query) = @_;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";

    # Remove the "recv" command, as it is not really a SQL keyword:
    # (it is there so we can pull data from non-select commands)
    $query =~ s/^recv\s+//gis if $query =~ m/^recv\s+/gis;
	
	my $settings = $self->{settings};
	my($headers, $data) = $self->_execute_query($query);
	$self->render_rowset($headers, $data);
	if (defined $settings->{LogLevel} && ($settings->{LogLevel} eq 'queries' || $settings->{LogLevel} eq 'all')) {
		$self->log_rowset($headers, $data);
	}
	return 1;
}

sub do_sql
{
	my ($self, $statement) = @_;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";

    # Remove the "send" command, as it is not really a SQL keyword:
    # (it is there so we can submit commands that would be interpereted by the shell)
    $statement =~ s/^send\s+//gis if $statement =~ m/^send\s+/gis;

	my $rows = $dbh->do($statement);
	$rows = 0 if $rows eq '0E0';

	my $cmd = (split /\s+/, $statement)[0];
	my $obj =
		  scalar $cmd =~ /(create|alter|drop)/? ($statement =~ /$1\s+(\S+\s+\S+?)\b/i)[0]
		: $cmd eq 'insert' ? ($statement =~ /into\s+(\S+?)\b/)[0]
		: $cmd eq 'select' ? ($statement =~ /into\s+(\S+?)\b/)[0]
		: $cmd eq 'update' ? ($statement =~/\s+(\S+?)\b/)[0]
		: $cmd eq 'delete' ? ($statement =~/from\s+(\S+?)\b/)[0]
		: ''
	;

	print "\U$cmd\E $obj: $rows rows affected\n\n" unless($rows == -1 && !$self->{settings}{Verbose});
	return 1;
}

sub begin_work
{
	my $self = shift;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";
	$dbh->begin_work;
	return 1;
}

sub commit
{
	my $self = shift;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";
	$dbh->commit;
	return 1;
}

sub rollback
{
	my $self = shift;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";
	$dbh->rollback;
	return 1;
}

sub wipe_tables
{
	my $self = shift;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";
	my @tables = _list_tables($dbh);

	if($self->{settings}{Interactive}) {
		print "Wipe all data from:\n\n",(map {"  ".$_."\n"} @tables),"\nAre you sure you want to do this? (type 'yes' if you are) ";
		my $response = <STDIN>;
		chomp $response;
		return 0 unless ($response eq 'yes');
	}

	foreach(@tables)
	{
		$dbh->do("delete from $_");
	}
	print "\nWiped all data in database\n\n" if($self->{settings}{Verbose});
	return 1;
}

sub load_data
{
	my ($self,$filename, $table, $delimiter, $uri_decode, $cf, $ct) = @_;
	$uri_decode &&= 1; #Force to boolean (concession to command regex)
	$delimiter = $self->{settings}{Delimiter} unless(defined $delimiter);
	die "You must supply a character set to recode into!\n" if ($cf && !$ct);
	die "You must supply a source character set for recoding\n" if (!$cf && $ct);
	if($cf && $ct) {
		require Locale::Recode;
		die "Unrecognised character set '$cf'\n" if(not Locale::Recode->resolveAlias($cf));
		die "Unrecognised character set '$ct'\n" if(not Locale::Recode->resolveAlias($ct));
	}
	my $dbh = $self->_dbh() or die "Not connected to database.\n";
	
	print "Using URI::Decode\n" if ($uri_decode && $self->{settings}{Verbose});
	my $recoder;
	if ($cf) {
		print "Recoding characters from $cf to $ct\n" if ($self->{settings}{Verbose});
		require Locale::Recode;
		$recoder = new Locale::Recode('from' => $cf, 'to' => $ct);
	}

	#Open file
	my $file = new IO::File $filename;

	#Read headers
	my $headers = <$file>; chomp $headers;
	my @headers = split($delimiter, $headers);

	#Build SQL from headers
	my $sql = "INSERT into $table (".join(",", @headers).") VALUES (".join(",", map{"?"} @headers).")";
	my $sth = $dbh->prepare_cached($sql);

	#Load data from file
	my $counter = 0;
	while(<$file>)
	{
		chomp;
		my @row = split($delimiter, $_);
		die "Error: more values in row ".join(",",@row)." than there are headers (".join(",",@headers).").  Aborting load\n" if(scalar @row > scalar @headers);

		#Fill in short rows with nulls
		while(scalar @row < scalar @headers) {
			push @row, undef;
		}

		#Perform encoding conversions
		@row = _recode($recoder, @row) if ($recoder);
		@row = map {uri_unescape($_)} @row if ($uri_decode);

		#Insert data		
		eval {
			$sth->execute(@row);
		};
		die("Error executing $sql with params (" . join(",", @row) . ") at line $. in $filename - $@") if($@);

		$counter++;
	}

	print "Loaded $counter rows into $table from $filename\n"  if($self->{settings}{Verbose});
	return 1;
}

sub dump_data
{
	my ($self, $source, $filename, $delimiter) = @_;
	my $dbh = $self->_dbh() or die "Not connected to database.\n";
	$source =~ s/^\s+//g; $source =~ s/\s+$//g; #Trim any whitespace
	print "Dumping $source into $filename\n" if($self->{settings}{Verbose});
	if(lc($source) eq 'all tables')
	{
		my $files = $self->_dump_tables($filename, $delimiter);
		print "Dumped ".scalar(@$files)." tables into $filename:\n" if($self->{settings}{Verbose});
		print map {" - $_\n"} @$files;
	}
	else
	{
		my $count = $self->_dump_data($source, $filename, $delimiter);
		print "Dumped $count rows into $filename\n" if($self->{settings}{Verbose});
	}
	return 1;
}

sub set_param
{
	my ($self,$param, $mode) = @_;
	TRACE("set $param=$mode");
	my $settings = $self->{settings};
	my $dbh = $self->_dbh;
	
	my $valid = 1;
	if($param eq 'display-mode')
	{
		die sprintf "'$mode' is an invalid value for display-mode. Valid values are %s\n", join(", ", sort keys %{$self->{renderers}}) unless (exists $self->{renderers}{$mode});
		$settings->{Renderer} = $self->{renderers}{$mode};
	}
	elsif($param eq 'log-mode')
	{
		die sprintf "'$mode' is an invalid value for log-mode. Valid values are %s\n", join(", ", sort keys %{$self->{renderers}}) unless(exists $self->{renderers}{$mode});
		$settings->{Logger} = $self->{renderers}{$mode};
	}
	elsif($param eq 'escape')
	{
		die("'$mode' is an invalid value for escape should be (off, uri-escape, show-whitespace or escape-whitespace)") unless $mode =~ /(uri-escape|show-whitespace|escape-whitespace|off)/;
		my $mapping = {
			'show-whitespace' => 'ShowWhitespace',
			'uri-escape' => 'UriEscape',
			'escape-whitespace' => 'EscapeWhitespace',
			'off' => undef
		};
		$settings->{EscapeStrategy} = $mapping->{$mode};
		print "Escape set to $mode\n" if($settings->{Verbose});
	}
	elsif($param eq 'enter-whitespace')
	{
		my $_onoff = ($mode =~ /^on$/i) ? 1 : ($mode =~ /^off$/i) ? 0 : undef;
		die "'$mode' is an invalid value for enter-whitespace (should be 'on' or 'off')\n" unless(defined $_onoff);
		$settings->{EnterWhitespace} = $_onoff;
		print "Whitespace ".($settings->{EnterWhitespace}?"may":"may not")." be entered as \\n, \\r and \\t\n" if($settings->{Verbose});
	}
	elsif($param eq 'delimiter')
	{
		$settings->{Delimiter} = $mode;
		print "Delimiter is now '$settings->{Delimiter}'\n" if($settings->{Verbose});
	}
	elsif($param eq 'width')
	{
		die "'$mode' is an invalid value for width (should be an integer)\n" unless($mode =~ /^\d+$/);
		$settings->{Width} = $mode;
		print "Width is now '$settings->{Width}'\n" if($settings->{Verbose});
	}
	elsif($param eq 'auto-commit')
	{
		my $_onoff = ($mode =~ /^on$/i) ? 1 : ($mode =~ /^off$/i) ? 0 : undef;
		die "'$mode' is an invalid value for auto-commit (should be 'on' or 'off')\n" unless (defined $_onoff);
		eval {$dbh->{AutoCommit} = $_onoff if _is_connected($dbh) };
		die "Couldn't set AutoCommit to '$mode' - $@\n" if($@);
		print "AutoCommit is now '\U$mode\E'\n" if($settings->{Verbose});
		$settings->{AutoCommit} = $_onoff;
	}
	elsif($param eq 'longreadlen')
	{
		die "'$mode' is an invalid value for longreadlen (should be an integer)\n" unless($mode =~ /^\d+$/);
		eval { $dbh->{LongReadLen} = $mode if _is_connected($dbh) };
		die "Couldn't set LongReadLen to '$mode' - $@\n" if($@);
		print "LongReadLen set to '$mode'\n" if($settings->{Verbose});
		$settings->{LongReadLen} = $mode;
	}
	elsif($param eq 'longtruncok')
	{
		my $_onoff = ($mode =~ /^on$/i) ? 1 : ($mode =~ /^off$/i) ? 0 : undef;
		die "'$mode' is an invalid value for longtruncok (should be 'on' or 'off')\n" unless (defined $_onoff);
		eval { $dbh->{LongTruncOk} = $_onoff if _is_connected($dbh) };
		die "Couldn't set LongTruncOk to '\U$mode\E'\n - $@" if($@);
		print "LongTruncOk set to '\U$mode\E'\n" if($settings->{Verbose});
		$settings->{LongTruncOk} = $_onoff;
	}
	elsif($param eq 'multiline')
	{
		my $_onoff = ($mode =~ /^on$/i) ? 1 : ($mode =~ /^off$/i) ? 0 : undef;
		die "'$mode' is an invalid value for multiline (should be 'on' or 'off')\n" unless (defined $_onoff);
		$settings->{MultiLine} = $_onoff;
	}
	elsif($param eq 'tracing')
	{
		if ($mode =~ /^on$/i) {
			import Log::Trace("print");
			print "Log::Trace enabled\n" if($settings->{Verbose});
		}
		elsif ($mode =~ /^off$/i) {
			import Log::Trace();
			print "Log::Trace disabled\n" if($settings->{Verbose});
		}
		elsif ($mode =~ /^deep$/i) {
			import Log::Trace("print" => {Deep => 1});
			print "Log::Trace enabled with deep import into modules\n" if($settings->{Verbose});
		}
		else { 
			die "'$mode' is an invalid value for tracing (should be 'on', 'deep' or 'off')\n";
		}
	}
	else
	{
		die "Unknown parameter '$param' for set command\n";
	}
	
	return $valid;	
}


#######################################################################
#
# Private methods
#
#######################################################################

#
# Main worker
#
sub _execute
{
	my($self, $cmd) = @_;
	my $valid = 1;
	
	#Convenience vars
	my $dbh = $self->_dbh;
	my $settings = $self->{settings};
	
	if (defined $settings->{LogLevel} && ($settings->{LogLevel} eq 'all' || $settings->{LogLevel} eq 'commands'))
	{
		my $log = $self->{LogFH};
		my $dont_log = 0; #May want to extend to allow a list of command regexes to be specified "unsuitable for logging"
		print $log "$cmd\n" unless($dont_log);
	}

	if ($settings->{MultiLine})
	{
		$self->{current_statement} .= $cmd."\n";
		return 1 unless $self->{current_statement} =~ /;\s*$/s;
		$cmd = $self->{current_statement};
		$cmd =~ s/\n/ /sg;
	}
	$self->{current_statement} = '';

	$cmd =~ s/(?:^\s*|\s*;?\s*$)//g;
	if($settings->{EnterWhitespace})
	{
		$cmd =~ s/\\n/\n/g;
		$cmd =~ s/\\r/\r/g;
		$cmd =~ s/\\t/\t/g;
	}

	#Command recognition
	if($cmd)
	{
		#Look for command in command table		
		my $found = 0;
		foreach my $regex (keys %{$self->{commands}}) {
			my @args = ($cmd =~ $regex);
			if(@args) {
				eval
				{
					#Execute command and convert any true return value to 1
					$valid = $self->{commands}{$regex}->($self, @args) && 1;
				};
				if($@) {
					print $@;
					$valid = 0;	
				}
				$found = 1;
				last;
			}
		}
		
		if(not $found) {
			my $s = length($cmd)>20? substr($cmd,0,20)."..." : $cmd;
			warn "Unrecognised command '$s'\n";
			$valid = 0;
		}
	}
	
	$settings->{AddHistory}->($cmd) if($cmd =~ /\S/ && $valid); #Add command to history
	return $valid;
}



#######################################################################
#
# Renderers
#
#######################################################################

sub _render_delimited
{
	my ($self, $fh, $headers, $data) = @_;
	my $delim = $self->{settings}{Delimiter};
	print $fh join($delim, @$headers)."\n";
	foreach(@$data)
	{	
		print $fh join($delim, @$_)."\n";
	}
	print $fh "\n";
}

sub _render_sql
{
	my ($self, $fh, $headers, $data, $table) = @_;	
	$table ||= '$table';
	my $sql = "INSERT into $table (".join("," , @$headers).") VALUES (%s);\n";
	my $settings = $self->{settings};
	my $dbh = $self->_dbh;
	local $settings->{NULL} = 'NULL' unless -t $fh;
	foreach(@$data)
	{
		my @fields = map{
			defined() ? 
				DBI::looks_like_number($_) ? $_ : $dbh->quote($_) 
			: $settings->{NULL}
		} @$_;
		printf $fh $sql, join(",", @fields);
	}
	print $fh "\n";
}

sub _render_xml
{
	my ($self, $fh, $headers, $data) = @_;
	require CGI; #For its markup escaping routine
	print $fh "<rowset>\n";
	foreach my $record (@$data)
	{
		print $fh "\t<record>\n";
		print $fh map {
			my $val = shift @$record;
			$val = CGI::escapeHTML($val);
			"\t\t<$_>$val</$_>\n"
		} @$headers;
		print $fh "\t</record>\n";
	}
	print $fh "</rowset>\n";
	print $fh "\n";
}

sub _render_box
{
	my ($self, $fh, $headers, $data, $table) = @_;
	my $settings = $self->{settings};
	my $widths = _compute_widths($headers,$data);
	use constant LD_H => '-';
	use constant LD_V => '|';
	use constant LD_X => '+';
	my $line = join(LD_X, map{LD_H x ($_+2)} @$widths);
	local $settings->{NULL} = 'NULL' unless -t $fh;

	#Table
	if($table) {
		print $fh LD_X . LD_H x (length $line) . LD_X . "\n";
		my $str = " " x int(0.5 * (length($line) - length($table)));
		$str .= $table;
		$str .= " " x (length($line) - length($str));
		print LD_V . $str . LD_V . "\n";
	}

	#Headers
	print $fh LD_X . $line . LD_X . "\n";
	my $str = LD_V;
	for(my $l = 0; $l<=$#$headers; $l++)
	{
		$str .=  " " . $headers->[$l] . " " x ($widths->[$l] - length($headers->[$l])) . " " . LD_V;
	}
	print $fh $str."\n";
	
	print $fh LD_X . $line . LD_X . "\n";

	#Data
	foreach my $row (@$data)
	{
		my $str = LD_V;
		for(my $l = 0; $l<=$#$headers; $l++)
		{
			my $value = $row->[$l];
			my $len_val;
			unless (defined $value) {
				$value   = $settings->{NULL};
				$len_val = 4;
			} else {
				$len_val = length $value;
			}
			$str .=  " " . $value . " " x ($widths->[$l] - $len_val) . " " . LD_V;
		}
		print $fh $str."\n";
	}

	print $fh LD_X . $line . LD_X . "\n";
}

sub _render_spaced
{
	my ($self, $fh, $headers, $data) = @_;
	my $widths = _compute_widths($headers,$data);
	my $format = join($self->{settings}{Delimiter}, map{"%".$_."s"} @$widths)."\n";
	TRACE($format);
	printf $fh ($format, @$headers);
	foreach(@$data)
	{
		printf $fh ($format, map {defined() ? $_ : 'NULL'} @$_);
	}
	print $fh "\n";
}

sub _render_record
{
	my ($self, $fh, $headers, $data) = @_;
	my $settings = $self->{settings};
	my $header_width = _max_width($headers);
	my $line = (LD_H x $settings->{Width})."\n";
	local $settings->{NULL} = 'NULL' unless -t $fh;
	foreach my $record (@$data)
	{
		print $fh $line;
		for(my $l = 0; $l<=$#$headers; $l++)
		{
			my $heading = $headers->[$l] . " " x ($header_width - length($headers->[$l])) . " " . LD_V . " ";
			my $str;
			if($settings->{Width} > length($heading))
			{
				my $room = $settings->{Width} - length($heading);
				my $text = defined $record->[$l] ? $record->[$l] : $settings->{NULL};
				my $segments = length($text)/$room;
				for(my $i=0; $i<$segments; $i++)
				{
					$str .= $heading . substr($text,$i*$room,$room) . "\n"
				}
			}
			else
			{
				$str="Terminal too narrow\n";
			}
			print $fh $str;
		}
		print $fh $line."\n";
	}
}

#######################################################################
#
# Misc private methods
#
#######################################################################

#Dump data to a logfile
sub _dump_data
{
	my($self, $sql, $filename, $delimiter) = @_;
	my $table;
	unless($sql=~/ /) #If it's just one word treat it as a table name
	{
		$table = $sql;
		$sql = "select * from $table"; #Allow just table name to be passed
	}
	my ($headers, $data) = $self->_execute_query($sql);
	$filename = _expand_filename($filename);
	my $fh = new IO::File ">$filename" or die ("Unable to write to $filename - $!");
	my $settings = $self->{settings};
	my $old_delim = $self->{settings}{Delimiter};
	eval {
		$self->{settings}{Delimiter} = $delimiter if($delimiter);
		$settings->{Logger}->($self, $fh, $headers, $data, $table);
	};
	$self->{settings}{Delimiter} = $old_delim; #restore before raising exception
	die($@) if($@); #Rethrow exception
	return scalar(@$data);
}

#Dump all tables to a directory
sub _dump_tables
{
	my($self, $dir, $delimiter) = @_;
	$dir = _expand_filename($dir);
	mkpath($dir) if(! -e $dir);
	my @files;
	foreach(_list_tables($self->_dbh))
	{
		my $filename = $dir."/".$_.".dat";
		push @files, $filename;
		$self->_dump_data($_, $filename, $delimiter);
	}
	return \@files;
}

sub _execute_query
{	
	my ($self, $sql) = @_;

	#Place to hang future logic for memory-saving database cursors
	my $class = "Tie::Rowset::InMemory";
	TRACE("Executing $sql using $class");

	#Get a handle onto the data that looks like an array of arrays
	my @data;
	my $dbh = $self->_dbh;
	tie @data, $class, $dbh, $sql, {Type => 'Array'};
	my $object = tied @data;
	my $headers = $object->column_names();

	#Attach filter for escaping data as it's accessed
	my $settings = $self->{settings};
	if($settings->{EscapeStrategy} eq "EscapeWhitespace")
	{
		_escape_whitespace($headers);
		$object->filter(\&_escape_whitespace); #install a filter on the tied rowset
	}
	if($settings->{EscapeStrategy} eq "ShowWhitespace")
	{
		_show_whitespace($headers);
		$object->filter(\&_show_whitespace); #install a filter on the tied rowset
	}
	elsif($settings->{EscapeStrategy} eq "UriEscape")
	{
		_uri_escape($headers);
		$object->filter(\&_uri_escape); #install a filter on the tied rowset
	}

	return($headers, \@data);
}

sub _desc_table
{
	my ($self, $table) = @_;
	my $dbh = $self->_dbh;
	my $driver = $dbh->{Driver}->{Name};
	my ($headers, $data);
	if($driver eq 'mysql')
	{
		($headers, $data) = $self->_execute_query("desc $table");
	}
	else
	{
		$data = _deduce_columns($dbh,$table);
		$headers=['Field','Type','Null'];
	}
	my $settings = $self->{settings};
	$self->render_rowset($headers, $data, $table);
	$self->log_rowset($headers, $data, $table) if($settings->{LogLevel} eq 'queries' || $settings->{LogLevel} eq 'all');
}

sub _dbh
{
	my $self = shift;
	if(_is_connected($self->{dbh})) {
		return $self->{dbh};	
	} else {
		$self->disconnect();
		return undef;
	}
}

#######################################################################
#
# Private routines
#
#######################################################################

sub _renderer {
	my $renderer = shift;
	if(defined $renderer && ref $renderer ne 'CODE') {
		$renderer = $Renderers{$renderer} || die("Unrecognised renderer: $renderer\n");
	}
	return $renderer;	
}

sub _is_connected
{
	if(defined $_[0] && ref $_[0] && UNIVERSAL::isa($_[0], 'DBI::db') && $_[0]->ping) {
		return 1;	
	} else {
		return 0;
	}
}

#
# Table manipulation
#

#List tables and their size
sub _summarise_tables
{
	my($dbh) = @_;
	my @results;
	foreach my $table(_list_tables($dbh))
	{
		my $sth = $dbh->prepare("select count(*) from $table");
		$sth->execute();
		my ($rows) = $sth->fetchrow_array();
		push @results,[$table, $rows];
	}
	return \@results;
}

sub _list_tables
{
	my($dbh) = @_;
	my $driver = $dbh->{Driver}->{Name};
	if($driver eq 'Oracle')
	{
		my $sth = $dbh->prepare("select table_name from cat where table_type=?");
		$sth->execute('TABLE');
		my $tables = $sth->fetchall_arrayref();
		return map {$_->[0]} @$tables;
	}
	else
	{
		#Generic DBI function
		return $dbh->tables();
	}
}


sub _deduce_columns
{
	my ($dbh,$table) = @_;
	my $sth = $dbh->prepare("select * from $table where 0=1");
	$sth->execute();
	my @names = @{$sth->{NAME}};
	my (@types, @nullable);
	eval
	{
		my @null = ("NO","YES","");
		my @type_codes = @{$sth->{TYPE}};
		my @precision = @{$sth->{PRECISION}};
		@nullable = map{$null[$_]} @{$sth->{NULLABLE}};
		$sth->finish;

		foreach(@type_codes)
		{
			my $info = $dbh->type_info($_);
			my $type = $info->{TYPE_NAME};
			my $precision = shift @precision;
			$type.="($precision)" if(defined $precision);
			push @types, $type;
		}
	};
	my @data = map {[$_, shift @types, shift @nullable]} @names;
	return \@data;
}

# Pull and render attributes from an active statement handle.
# A helper routine for show_objects()
sub _list_object_attrib {
    my $self   = shift;
    my $sth    = shift;
    my $attrib = shift;

    my @header;
    my @data;

    if ( $attrib eq 'TABLE_NAME' ) {
        @header = qw{ TABLE_CAT TABLE_SCHEM TABLE_NAME TABLE_TYPE REMARKS };
        while (my $row = $sth->fetchrow_hashref('NAME_uc')) {
            my @data_row = map { $row->{$_} } @header;
            push @data, \@data_row;
        }
    }
    else {
        @header = ( $attrib );
        my $hash_ref = $sth->fetchall_hashref($attrib);
        @data = map { [ $_ ] } sort keys %{ $hash_ref };
    }

    $self->render_rowset(\@header, \@data);
        
}

#
# History
#
sub _load_history {
	my $filename = shift;
	local *FH;
	my @hist;
	open (FH, _expand_filename($filename)) or die("Unable to load history from $filename - $!");
	while (<FH>) {
		chomp; push @hist, $_;
	}
	close FH;
	TRACE("Loaded ".scalar @hist." items from $filename");
	return \@hist;
}

sub _save_history {
	my $history = shift;
	my $filename = shift || die("You must specify a file to save the history to");
	my $max_size = shift || HISTORY_SIZE;
	my $max_hist = scalar @$history >= $max_size ? $max_size : scalar @$history;
	TRACE("Saving $max_hist items to $filename");
	my @hist = @$history[-$max_hist..-1];
	local *FH;
	open (FH, "> " . _expand_filename($filename)) or die("Unable to save history to $filename - $!");
		print FH $_, $/ for @hist;
	close FH;
}

sub _recode
{
	my ($recoder, @rows) = @_;
	foreach (@rows)
	{
		my $init = $_;
		die $recoder->getError if $recoder->getError;
		$recoder->recode($_) or die $recoder->getError;
		TRACE("recoded FROM [$init] to [$_]");
	}
	return @rows;
}

sub _escape_whitespace
{
	my $row = shift;
	foreach(@$row)
	{
		s/\r/\\r/g;
		s/\n/\\n/g;
		s/\t/\\t/g;
	}
	return $row;
}

sub _show_whitespace
{
	my $row = shift;
	$row = _escape_whitespace($row);
	foreach(@$row)
	{
		s/ /./g; #Also convert spaces to dots
	}
	return $row;
}

sub _uri_escape
{
	my $row = shift;
	my @new = map {uri_escape($_)} @$row;
	return \@new;
}

sub _compute_widths
{
	my ($headers,$data) = @_;
	my @widths = map {length $_} @$headers;
	foreach my $row(@$data)
	{
		for(0..$#widths)
		{
			my $len = defined $row->[$_] ? length($row->[$_]) : length 'NULL';
			$widths[$_] = $len if($len > $widths[$_]);
		}
	}
	return \@widths;
}

sub _max_width
{
	my ($list) = @_;
	my $width = 0;
	foreach (@$list)
	{
		my $len = length($_);
		$width = $len if($len > $width);
	}
	return $width;
}


sub _expand_filename {
	my $file = shift;
	if ($file =~ s/^~([^\/]*)//)
	{
		my $home = $1 ? ((getpwnam ($1)) [7]) : $ENV{HOME};
		$file = $home . $file;
	}
	return $file;
}

# stubs for Log::Trace
sub TRACE{}
sub DUMP{}

############################################################################################
#
# Inlined package for the time being whilst Tie::Rowset is being worked on
#
############################################################################################

package Tie::Rowset::InMemory;

use strict;
use Carp;

##############################################
# TIE interface
##############################################

sub TIEARRAY 
{
	my ($class, $dbh, $sql, $options) = @_;
	$options = {} unless defined $options;
	my $params = $options->{params};
	my $self = {
		'dbh' => $dbh,
		'sql' => $sql,
		'params' => defined $params? $params : [],
		'type' => $options->{Type} || 'Hash',
		'filter' => $options->{Filter},
		'count' => undef,
	};
	bless $self, $class;
	TRACE(__PACKAGE__." constructor");
	return $self;
}  

sub DESTROY
{
	my $self = shift;
	$self->{sth}->finish() if defined($self->{sth});
}

sub FETCH 
{
	my ($self, $index) = @_;
	TRACE("FETCH $index");
	$self->_execute_query() unless $self->{data};
	croak("index $index is out of bounds - rowset only has " . scalar @{$self->{data}}." elements") if($index+1 > scalar @{$self->{data}});
	my $rv = $self->{data}->[$index];
	$rv = $self->{filter}->($rv) if defined $self->{filter}; #optionally filter
	DUMP("Fetch $index", $rv);
	return $rv;
}     

sub FETCHSIZE 
{
	my $self = shift;
	$self->_execute_query() unless $self->{data};	
	TRACE("Fetch size - " . scalar @{$self->{data}});
	return scalar @{$self->{data}};
}

##############################################
# Non-tied OO interface (access via tied)
##############################################

sub column_names
{
	my $self = shift;
	$self->_execute_query() unless $self->{headers};
	return $self->{headers};	
}

sub filter
{
	my ($self, $filter) = @_;
	$self->{filter} = $filter if defined($filter);
	return $self->{filter};
}

##############################################
# private methods
##############################################

sub _execute_query
{
	my $self = shift;
	eval
	{
		my $sth = $self->{dbh}->prepare($self->{sql});
		$sth->execute(@{$self->{params}});
		$self->{headers} = $sth->{NAME};
		if($self->{type} eq 'Array') {
			$self->{data} = $sth->fetchall_arrayref();
		} else {
			my @loh;
			while(my $hashref = $sth->fetchrow_hashref)
			{
				push @loh, { %$hashref };
			}
			$self->{data} = \@loh;
		}
	};
	if($@)
	{
		$@ =~ s/\n$//;
		die("$@  sql=$self->{sql}"); #Decorate error messages with SQL
	}
}

# stubs for Log::Trace
sub TRACE{}
sub DUMP{}


=head1 NAME

SQL::Shell - command interpreter for DBI shells

=head1 SYNOPSIS

	use SQL::Shell;
	
	#Initialise and configure
	my $sqlsh = new SQL::Shell(\%settings);
	$sqlsh->set($setting, $new_value);
	$value = $sqlsh->get($setting);
	
	#Interpret commands
	$sqlsh->execute_command($command);
	$sqlsh->run_script($filename);

=head1 DESCRIPTION

SQL::Shell is a command-interpreter API for building shells and batch scripts.
A command-line interface with readline support - sqlsh.pl - is included as part of the CPAN distribution.  See <SQL::Shell::Manual> for a user guide.

SQL::Shell offers features similar to the mysql or sql*plus client programs but is database independent.
The default command syntax is arguably more user-friendly than dbish not requiring any go, do or slashes to fire SQL statements at the database.

Features include:

=over 4

=item * issuing common SQL statements by simply typing them

=item * command history

=item * listing drivers, datasources, tables

=item * describing a table or the entire schema

=item * dumping and loading data to/from delimited text files

=item * character set conversion when loading data

=item * logging of queries, results or all commands to file

=item * a number of formats for display/logging data (sql, xml, delimited, boxed)

=item * executing a series of commands from a file

=back

You can also install custom commands, rendering formats and command history mechanisms.
All the commands run by the interpreter are available via the API so if you don't like the default command syntax you can replace the command regexes with your own.
 
It's been developed and used in anger with Oracle and mysql but should work with any database with a DBD:: driver.

=head1 METHODS

=over 4

=item $sqlsh = new SQL::Shell(\%settings);

Constructs a new object and initialises it with a set of settings.
See L</SETTINGS> for a complete list.

=item $sqlsh->set($setting, $new_value)

Changes a setting once the object has been constructed.
See L</SETTINGS> for a complete list.

=item $value = $sqlsh->get($setting)

Fetches a setting.
See L</SETTINGS> for a complete list.

=back

=head2 Commands

=over 4

=item $sqlsh->execute_cmd($command)

Executes a command ($command is a string).  

Returns 1 if the command was successful.
Returns 0 if the command was unsuccessful.

=item $sqlsh->run_script($filename)

Executes a sequence of commands in a file.
Dies if there is a problem.

=item $sqlsh->install_cmds(\%additional_commands)

%additional_commands should contain a mapping of regex to coderef.  
See L</INSTALLING CUSTOM COMMANDS> for more information.

=item $sqlsh->uninstall_cmds(\@commands)

@additional_commands should contain a list of regexes to remove.
If uninstall_cmds is called with no arguments, all commands will be uninstalled.

=item $sqlsh->set_param($param, $value)

Equivalent to the "set <param> <value>" command.
In many cases this will affect the internal settings accessible through the C<set> and C<get> methods.

=back

=head2 Renderers 

=over 4

=item $sqlsh->install_renderers(\%additional_renderers)

%additional_renderers should contain a mapping of renderer name to coderef.  
See L</INSTALLING CUSTOM RENDERERS> for more information.

=item $sqlsh->uninstall_renderers(\@renderers)

@renderers should contain a list of renderer names to remove.
If uninstall_renderers is called with no arguments, all renderers will be uninstalled.

=item $sqlsh->render_rowset(\@headers, \@data, $table)

Calls the current renderer (writes to STDOUT)

=item $sqlsh->log_rowset(\@headers, \@data, $table)

Calls the current logger

=back

=head2 Database connection 

=over 4

=item $dsn = $sqlsh->connect($dsn, $user, $pass)

Connects to a DBI datasource.
Equivalent to issuing the "connect $dsn $user $pass" command.

=item $sqlsh->disconnect()

Disconnects if connected.
Equivalent to issuing the "disconnect" command.

=item $bool = $sqlsh->is_connected()

Check if we're connected to the database.

=item $string = $sqlsh->dsn()

The datasource we're currently connected as - undef if not connected.

=back

=head2 History manipulation 

=over 4

=item $arrayref = $sqlsh->load_history($filename)

Loads a sequence of commands from a file into the command history.
Equivalent to "load history from $filename".

=item $sqlsh->clear_history()

Clears the command history.
Equivalent to "clear history".

=item $sqlsh->save_history($filename, $size)

Saves the command history to a file in a format suitable for C<load_history> and C<run_script>.
Equivalent to "save history to $filename", except the maximum number of items can be specified.
$size is optional - if not specified defaults to the MaxHistory setting.

=item $sqlsh->show_history()

Displays the command history.
Equivalent to "show history".

=back

=head2 Logging

=over 4

=item $sqlsh->enable_logging($level, $file)

Enables logging to a file.
$level should be all, queries or commands.
Equivalent to "log $level $file".  

=item $sqlsh->disable_logging()

Disables logging to a file.
Equivalent to "no log".

=back

=head2 Querying

=over 4

=item $sqlsh->show_drivers()

Outputs a list of database drivers. Equivalent to "show drivers".

=item $sqlsh->show_datasources($driver)

Outputs a list of datasources for a driver. Equivalent to "show datasources $driver".

=item $sqlsh->show_dbh($property)

Outputs a property of a database handle.  Equivalent to "show \$dbh $property".

=item $sqlsh->show_schema()

Equivalent to "show schema".

=item $sqlsh->show_objects()

Displays a list of tables, schemas, catalogs or table-types depending on the 
object argument passed.

=item $sqlsh->show_tablecounts()

Displays a list of tables with row counts.  Equivalent to "show tablecounts".

=item $sqlsh->show_settings()

Displays a list of internal C<sqlsh> settings.  Equivalent to "show 
settings".  Not all internal settings are included here yet.

=item $sqlsh->describe($table)

Displays the columns in the table.  Equivalent to "describe $table".

=item $sqlsh->run_query($sql)

Displays the rowset returned by the query.  Equivalent to execute_cmd with a select or explain statement.

=back

=head2 Modifying data

=over 4

=item $sqlsh->do_sql($sql)

Executes a SQL statement that modifies the database.  Equivalent to execute_cmd with a DML or DDL statement.

=item $sqlsh->begin_work()

Starts a transaction.  Equivalent to "begin work".

=item $sqlsh->commit()

Commits a transaction.  Equivalent to "commit".

=item $sqlsh->rollback()

Rolls back a transaction.  Equivalent to "rollback".

=item $sqlsh->wipe_tables()

Blanks all the tables in the database.
Will prompt for confirmation if the Interactive setting is enabled.
Equivalent to "wipe tables".

=back

=head2 Loading and dumping data

=over 4

=item $sqlsh->dump_data($source, $filename, $delimiter)

Dumps data from a table or query into a delimited file.
$source should either be a table name or a select query.
This is equivalent to the "dump data" command.

=item $sqlsh->load_data($filename, $table, $delimiter, $uri_decode, $charset_from, $charset_to)

Loads data from a delimited file into a database table.
$uri_decode is a boolean value - if true the data will be URI-decoded before being inserted.
$charset_from and $charset_to are character set names understood by Locale::Recode.
This is equivalent to the "load data" command.

=item $sqlsh->show_charsets()

Lists the character sets supported by the recoding feature of "load data".  Equivalent to "show charsets".

=back

=head1 CUSTOMISING

=head2 INSTALLING CUSTOM COMMANDS

The coderef will be passed the $sqlsh object followed by each argument captured by the regex.

	my %additional_commands = (
	qr/^hello from (\.*)/ => sub {
		my ($self, $name) = @_;
		print "hi there $name\n";
	});

To install this:

	$sqlsh->install_cmds(\%additional_commands)

Then in sqlsh:

	> hello from John
	hi there John

=head2 INSTALLING CUSTOM RENDERERS

Renderers are coderefs which are passed the following arguments:

	$sqlsh - the SQL::Shell object
	$fh - the filehandle to render to
	$headers - an arrayref of column headings
	$data - an arrayref of arrays containing the data (row major)
	$table - the name of the table being rendered (not defined in all contexts)

Here's an example to render data in CSV format:

	sub my_renderer {
		my ($sqlsh, $fh, $headers, $data, $table) = @_;
		my $delim = ",";
		print $fh "#Dump of $table" if($table); #Assuming our CSV format support #-style comments
		print $fh join($delim, @$headers)."\n";
		foreach my $row (@$data)
		{	
			print $fh join($delim, @$row)."\n";
		}		
	}

To install this:

	$sqlsh->install_renderers({'csv' => \&my_renderer});

Then in sqlsh:

	> set display-mode csv

=head2 INSTALLING A CUSTOM HISTORY MECHANISM

You can install a custom history recording mechanism by overriding the GetHistory, SetHistory and AddHistory callbacks which should take the following arguments and return values:

=over 4

=item $arrayref = $GetHistorySub->()

=item $SetHistorySub->($arrayref)

=item $AddHistorySub->($string)

=back

An example:

	my $term = new Term::ReadLine "My Shell";
	my $autohistory = $term->Features()->{autohistory};
	my $sqlsh = new SQL::Shell({
		'GetHistory' => sub {[$term->GetHistory()]}); 
		'SetHistory' => sub {my $history = shift; $term->SetHistory(@$history)});
		'AddHistory' => sub {my $cmd = shift; $term->addhistory($cmd) if !$autohistory});
	});

=head1 SETTINGS

The following settings can only be set through the constructor or the C<set> method:

	NAME           DESCRIPTION                        DEFAULT
	GetHistory     Callback to fetch history          sub {return \@history}
	SetHistory     Callback to set history            sub {my $n = shift; @history = @$n}
	AddHistory     Callback to add cmd to history     sub {push @history, shift()}
	MaxHistory     Maximum length of history to save  $ENV{HISTSIZE} || $ENV{HISTFILESIZE} || 50
	Interactive    Should SQL::Shell ask questions?   0
	Verbose        Should SQL::Shell print messages?  0
	NULL           How to display null values         NULL

The following are also affected by the C<set_param> method or the "set" command:

	NAME           DESCRIPTION                               DEFAULT
	Renderer       Current renderer for screen               \&_render_box
	Logger         Current renderer for logfile              \&_render_delimited
	Delimiter      Delimiter for delimited format            \t
	Width          Width used for record display             80
	LogLevel       Log what? all|commands|queries            undef
	EscapeStrategy UriEscape|EscapeWhitespace|ShowWhitespace undef
	AutoCommit     Commit each statement                     0
	LongTruncOk    OK to truncate LONG datatypes?            1
	LongReadLen    Amount read from LONG datatypes           512
	MultiLine      Allows multiline sql statements           0

=head1 COMMANDS
 
 show drivers
 show datasources <driver>
 connect <dsn> [<user> <pass>] - connect to DBI DSN
 disconnect - disconnect from the DB
 
 show tables - display a list of tables
 show catalogs - display a list of catalogs
 show schemas - display a list of schemas
 show tabletypes - display a list of tabletypes
 show schema - display the entire schema
 show settings - display some internal settings
 desc <table> - display schema of table
 
 show $dbh <attribute> - show a database handle object.
 	some examples:
 		show $dbh Name
 		show $dbh LongReadLen
 		show $dbh mysql_serverinfo (mysql only)
 
 set display-mode delimited|spaced|box|record|sql|xml - query display mode
 set log-mode delimited|spaced|box|record|sql|xml - set the query log mode
 set delimiter <delim> - set the column delimiter (default is tab)
 set escape show-whitespace|escape-whitespace|uri-escape|off
 	- show-whitespace is just for looking at
 	- escape-whitespace is compatible with enter-whitespace
 	- uri-escape is compatible with uri-decode (load command)
 set enter-whitespace on|off - allow \r \n and \t in SQL statements
 set uri-encode on|off - allow all non ascii characters to be escaped
 set auto-commit on|off - commit after every statement (default is OFF)
 set longtruncok on|off - See DBI/LongTruncOk  (default is on)
 set longreadlen <int>  - See DBI/LongReadLen  (default is 512)
 set multiline on|off - multiline statements ending in ; (default is off)
 set tracing on|off|deep - debug sqlsh using Log::Trace (default is off)
 
 log (queries|commands|all) <filename> - start logging to <filename>
 no log - stop logging
 
 select ...
 insert ...
 update ...
 create ...
 alter ...
 drop ...
 grant ...
 revoke ...
 begin_work
 commit
 rollback
 send ...
 recv ...
 
 load <file> into <table> (delimited by foo) (uri-decode) (from bar to baz) 
  - load delimited data from a file
  - use uri-decode if file includes uri-encoded data
  - from, to can take character set to recode data e.g. from CP1252 to UTF-8
 show charsets - display available character sets
 dump <table> into <file> (delimited by foo) - dump delimited data
 dump <sql> into <file> (delimited by foo) - dump delimited data
 dump all tables into <directory> (delimited by foo) - dump delimited data
 wipe tables - remove all data from DB (leaving tables empty)
 
 show history - display command history
 clear history - erases the command history
 save history to <file> - saves the command history
 load history from <file> - loads the command history
 execute <file> - run a set of SQL or sqlsh commands from a file

=head1 VERSION

Version 1.16

=head1 AUTHOR

John Alden with contributions by Simon Flack and Simon Stevenson <cpan _at_ bbc _dot_ co _dot_ uk>

Miguel Gualdron maintainer.

=head1 COPYRIGHT

    SQL-Shell:  Interactive shell for DBI Databases
    Copyright (C) 2006  BBC
    Copyright (C) 2019  Miguel Gualdron

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

See the file COPYING in this distribution, or https://www.gnu.org/licenses/gpl-2.0.html
      
=cut
