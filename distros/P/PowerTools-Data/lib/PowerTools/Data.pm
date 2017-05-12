package PowerTools::Data;

use 5.000002;
use strict;
use warnings;
use DBI;
use DBD::mysql;
use Time::Piece;
use Time::Piece::MySQL;
use Time::HiRes qw(time);
use Config::IniHash;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PowerTools::Data ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	connect disconnect status execute count 
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	connect disconnect status execute count
);

our $VERSION = '0.04';


# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PowerTools::Data - Additional Perl tool for Apache::ASP - MySQL database connection

=head1 SYNOPSIS

	use PowerTools::Data;
	
	# Create new object using params

	my $db = PowerTools::Data->new(
		# Username
		username => 'mysql',			# default 'root'
		# Password
		password => 'grendel1981',		# default ''
		# Database name
		database => 'test',			# default 'test'
		# Hostname
		hostname => 'localhost,			# default 'localhost';
		# Port
		port => 3306,				# default 3306;
		# Protocol compression (0/1)
		compression => 1,			# default 1;
		# DBI's RaiseError (0/1)
		errors => 1,				# default 1;
		# DBI's AutoCommit (0/1)
		commit => 1				# default 1;

	);

	# Create new object using .INI file

	my $db = PowerTools::Data->new(
		# Path to .INI file
		ini => 'test.ini'			# default ''
	);

	# Note: You can change .ini extension to other
	# Remember to secure choosen extensions name in Your Apache config

	# Connects to database
	my $conn = $db->connect;

	# Connection status (0 - FAIL/1 - OK)
	my $s = $db->status;
	print "STATUS $s\n";

	# MySQL Server info
	my $s = $db->{_SERVER_INFO};
	print "SERVER $s\n";

	# MySQL Server host info
	my $s = $db->{_HOST_INFO};
	print "HOST $s\n";

	# Executes SQL statement
	my $ex = $db->execute("INSERT INTO test (test_val1,test_val2) VALUES ('a','b')");

	# Items count
	my $cn = $db->count;
	print "COUNT INSERT $cn\n";

	# Last inserted item
	my $lt = $db->last;
	print "LAST ITEM $lt\n";

	# Query execute time
	my $tk = $db->took;
	print "TOOK $tk\n";

	# Parse query result

	while(!$db->eof) {
		my $str = "-> ".$db->field('test_id').", ".$db->field('test_val1').", ".$db->field('test_val2').", ".$db->field('test_val3');
		print "$str\n";
		$db->movenext;
	}

	# Additional tools

	# Get (in MySQL format) current: date ('GET_MYSQL_DATE'), datetime ('GET_MYSQL_DATETIME'), time ('GET_MYSQL_TIME'), timestamp ('GET_MYSQL_TIMESTAMP')
	my $cur = $db->tools('GET_MYSQL_TIMESTAMP');
	print "$cur\n";

	# Returns time object from MySQL's: date ('RETURN_TIME_DATE'), datetime ('RETURN_TIME_DATETIME'), timestamp ('RETURN_TIME_TIMESTAMP')
	my $cur = $db->tools('RETURN_TIME_TIMESTAMP',$cur);
	print "$cur\n";


=head1 AUTHOR

Piotr Ginalski, E<lt>office@gbshouse.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

our ($_CONN,$_CONN_STATUS,$_CONN_ERROR,$_QUERY,$_QUERY_RESULT,$_QUERY_STATUS,$_RECORD_COUNT,$_SERVER_INFO,$_HOST_INFO,$_LAST_ID,$_COMMIT,$_TIME_TOOK);

sub new {
	my $class = shift;
	my (%options) = @_;
	return bless \%options, $class;
}

sub connect {
	my $self = shift;

	my $db_user = $self->{username} || 'root';
	my $db_pass = $self->{password} || '';
	my $db_base = $self->{database} || 'test';
	my $db_host = $self->{hostname} || 'localhost';

	my $db_port = $self->{port} || 3306;
	my $db_comp = $self->{compression} || 1;
	
	my $db_re = $self->{errors} || 1;
	my $db_ac = $self->{commit} || 1;
	$self->{_COMMIT} = $db_ac;

	my $db_log = $self->{log} || 0;

	my $ini = $self->{ini};

	if( ($ini) && (-e $ini) ) {
		my $conf = ReadINI $ini;

		$db_user = $conf->{mysql}->{username} || 'root';
		$db_pass = $conf->{mysql}->{password} || '';
		$db_base = $conf->{mysql}->{database} || 'test';
		$db_host = $conf->{mysql}->{hostname} || 'localhost';

		$db_port = $conf->{mysql}->{port} || 3306;
		$db_comp = $conf->{mysql}->{compression} || 1;
	
		$db_re = $conf->{mysql}->{errors} || 1;
		$db_ac = $conf->{mysql}->{commit} || 1;
		$self->{_COMMIT} = $db_ac;

		$db_log = $conf->{mysql}->{log} || 0;
	} else {
		_error("Can't open INI file");
	}
	
	eval {
		my $db_dsn = "DBI:mysql:database=".$db_base.";host=".$db_host.";port=".$db_port.";mysql_compression=".$db_comp;
		$self->{_CONN} = DBI->connect($db_dsn,$db_user,$db_pass,{'RaiseError' => $db_re, 'AutoCommit' => $db_ac, 'PrintError' => 1}) or die $DBI::lasth->errstr;
	};

	if ($@) {
		$self->{_CONN_STATUS} = 0;
		$self->{_CONN_ERROR} = $DBI::lasth->errstr;
		_error($DBI::lasth->errstr);
	} else {
		$self->{_CONN_STATUS} = 1;
		$self->{_SERVER_INFO} = $self->{_CONN}->{'mysql_serverinfo'};
		$self->{_HOST_INFO} = $self->{_CONN}->{'mysql_hostinfo'};
	}

	return $self->{_CONN};	

}

sub execute {
	my $self = shift;
	my $query = $_[0];

	if( ($query) && ($self->{_CONN_STATUS} == 1) ) {

		my $t0 = time();
		my $Q = substr $query, 0, 6;

		if($Q eq 'SELECT') {

			$self->{'current_record'} = 0;
			$self->{_QUERY} = $self->{_CONN}->prepare($query) or die $DBI::lasth->errstr;
			$self->{_QUERY}->execute() or die $DBI::lasth->errstr;
			$self->{_QUERY_RESULT} = $self->{_QUERY}->fetchall_arrayref({});
			$self->{_RECORD_COUNT} = $self->{_QUERY}->rows;
			$self->{_QUERY}->finish();
			$self->{_QUERY_STATUS} = 1;

		} elsif($Q eq 'INSERT') {

			$self->{_QUERY} = $self->{_CONN}->do($query) or die $DBI::lasth->errstr;
			$self->{_RECORD_COUNT} = $self->{_QUERY};
			$self->{_LAST_ID} = $self->{_CONN}->{'mysql_insertid'};
			$self->{_QUERY_STATUS} = 1;

		} elsif($Q eq 'UPDATE') {

			$self->{_QUERY} = $self->{_CONN}->do($query) or die $DBI::lasth->errstr;
			$self->{_RECORD_COUNT} = $self->{_QUERY};
			$self->{_LAST_ID} = $self->{_CONN}->{'mysql_insertid'};
			$self->{_QUERY_STATUS} = 1;

		} elsif($Q eq 'DELETE') {

			$self->{_QUERY} = $self->{_CONN}->do($query) or die $DBI::lasth->errstr;
			$self->{_RECORD_COUNT} = $self->{_QUERY};
			$self->{_LAST_ID} = $self->{_CONN}->{'mysql_insertid'};
			$self->{_QUERY_STATUS} = 1;

		} else {

		}

		my $t1 = time();
		$self->{_TIME_TOOK} = ($t1 - $t0);

	} else {
		$self->{_QUERY_STATUS} = 0;
	}

	return $self;

}

sub took {
	my $self = shift;
	if($self->{_CONN_STATUS} == 1) {
		return sprintf('%.6f',$self->{_TIME_TOOK});
	} else {
		return undef;
	}
}

sub eof {
	my $self = shift;
	if($self->{_CONN_STATUS} == 1) {
		if($self->{'current_record'} < $self->{_QUERY}->rows) {
			return 0;
		} else {
			return 1;
		}
	} else {
		return 1;
	}
}

sub movenext {
	my $self = shift;
	if($self->{_CONN_STATUS} == 1) {
		if($self->{'current_record'} < $self->{_QUERY}->rows) {
			$self->{'current_record'}++;
		}
	}
	return $self;
}

sub field {
	my $self = shift;
	if($self->{_CONN_STATUS} == 1) {
		my $p = $_[0];
		return $self->{_QUERY_RESULT}->[$self->{'current_record'}]->{$p};
	}
}

sub last {
	my $self = shift;
	return $self->{_LAST_ID};
}

sub count {
	my $self = shift;
	if($self->{_RECORD_COUNT} eq '0E0') { $self->{_RECORD_COUNT} = 0; }
	if($self->{_RECORD_COUNT} < 0) { $self->{_RECORD_COUNT} = 0; }
	return $self->{_RECORD_COUNT};
}

sub disconnect {
	my $self = shift;
	if($self->{_CONN_STATUS} == 1) {
		$self->{_CONN}->disconnect;
	}
	return $self;
}

sub status {
	my $self = shift;
	return $self->{_CONN_STATUS};
}

sub tools {
	my $self = shift;
	my $O = $_[0];
	my $V = $_[1];

	if($O eq 'GET_MYSQL_DATE') {
		my $t = localtime;
		return $t->mysql_date;
	} elsif($O eq 'GET_MYSQL_DATETIME') {
		my $t = localtime;
		return $t->mysql_datetime;
	} elsif($O eq 'GET_MYSQL_TIME') {
		my $t = localtime;
		return $t->mysql_time;
	} elsif($O eq 'GET_MYSQL_TIMESTAMP') {
		my $t = localtime;
		return $t->mysql_timestamp;
	} elsif($O eq 'RETURN_TIME_DATE') {
		return Time::Piece->from_mysql_date($V);
	} elsif($O eq 'RETURN_TIME_DATETIME') {
		return Time::Piece->from_mysql_datetime($V);
	} elsif($O eq 'RETURN_TIME_TIMESTAMP') {
		return Time::Piece->from_mysql_timestamp($V);
	}

}

sub _error {
	my $self = shift;
	my $t = $_[0];
	return $t;
}

sub _log {
	my $self = shift;
	my $txt = $_[0];
	open(LOG,">>c:\\powertools_data.log");
	print LOG $txt,"\n";
	close(LOG);
}

1;
__END__

