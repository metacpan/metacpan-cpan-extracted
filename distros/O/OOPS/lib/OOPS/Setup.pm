
BEGIN {
	Filter::Util::Call::filter_add(\&OOPS::SelfFilter::filter)
		unless $OOPS::SelfFilter::defeat;
}

package OOPS::Setup; # dummy

package OOPS;

use strict;
use warnings;

# Regular expression to match error returned when the database
# has not been initialized:
#
#	mysql		Table 'PREFIXobject' doesn't exist
# 	sqlite		no such table: PREFIXobject(1) at dbdimp.c
#	postgresql	ERROR:  relation "PREFIXobject" does not exist
#
our $gcgenstart = 10_000;
our $last_reserved_oid = 100;

sub initial_setup_real
{
	my ($pkg, %args) = @_;

	my $dbo;
	if (ref $pkg) {
		$dbo = $pkg->dbo;
	} else {
		$dbo = OOPS::DBO->dboconnect(%args);
	}

	# create tables, initial objects, etc.
	my ($oldout, $olderr, $obuf, $ebuf);
	$dbo->db_domany(
		$dbo->tabledefs()
		 . db_initial_values()
		 . $dbo->db_initial_values(),
		args	=> \%args, 
		silent	=> $ENV{HARNESS_ACTIVE});
	my $dbms = $dbo->{dbms};
	$dbo->commit();
	$dbo->disconnect unless ref $pkg;
	return $dbms;
}

sub db_initial_values
{
	return <<END;
	INSERT INTO TP_object values (1, 1, 'HASH', 'H', 'V', '0', '0', $OOPS::SCHEMA_VERSION, 1, 1, $gcgenstart);
	INSERT INTO TP_attribute values (2, 'user objects', '1', 'R');

	INSERT INTO TP_object values (2, 2, 'HASH', 'H', 'V', '0', '0', 0, 1, 1, $gcgenstart);
	INSERT INTO TP_attribute values (2, 'internal objects', '2', 'R');
	INSERT INTO TP_attribute values (2, 'VERSION', '$OOPS::VERSION', '0');
	INSERT INTO TP_attribute values (2, 'SCHEMA_VERSION', '$OOPS::SCHEMA_VERSION', '0');
	INSERT INTO TP_attribute values (2, 'GC GENERATION', '$gcgenstart', '0');

	INSERT INTO TP_object values (3, 3, 'HASH', 'H', 'V', '0', '0', 0, 1, 1, $gcgenstart);
	INSERT INTO TP_attribute values (2, 'counters', '3', 'R');

	INSERT INTO TP_object values ($OOPS::gc_overflow_id, $OOPS::gc_overflow_id, 'HASH', 'H', 'V', '0', '0', 0, 1, 1, $gcgenstart);
	INSERT INTO TP_attribute values (2, 'gc extra todo', '$OOPS::gc_overflow_id', 'R');
END
}

#
# On a failure to load the named_objects hash, auto-initialize the
# database.
#
sub load_failure
{
	my ($oops, $err) = @_;

	my $nodatarx = $oops->{dbo}->nodata_rx;
	print "load_failure($err) -- compare to $nodatarx\n" if $OOPS::debug_setup;
	return 0 unless $err =~ /$nodatarx/;

	die "DBMS not initialized - use auto_initialize or initial_setup()\n" 
		unless $oops->{args}{auto_initialize} || $ENV{OOPS_INIT};

	print STDERR "Initializing database...\n";
	
	$oops->{dbo}->rollback || confess $oops->{dbo}->errstr;
	
	print "rollback complete\n" if $OOPS::debug_setup;

	$oops->initial_setup_real(%{$oops->{args}});

	print "Initial setup done\n" if $OOPS::debug_setup;

	return 1;
}

package OOPS::DBO;

use strict;
use warnings;

#
# method invocation as either a $dbo or $oops method 
# or pass dbiconnect args as $opts{args}
#
# also:
#  $opts{silent} - don't print on errors
#  $opts{nonfatal} - don't die on errors
#  $opts{autocommit} - autocommit each command
#
sub db_domany
{
	my ($something, $command, %opts) = @_;
	my $dbo;
	if (ref $something) {
		$dbo = $something;
	} elsif ($opts{args}) {
		$dbo = OOPS::DBO->dboconnect(%{$opts{args}});
	} else {
		confess;
	}
	my @ret;
	die unless $command;
	$command .= ";\n" unless $command =~ /;/;  # if there's just one query...

	while ($command =~ /\G\s*(\S.*?);\n/sgc) {
		my $query = $1;
		print STDERR "do $query\n" if $OOPS::debug_initialize;
		my $nonfatal = $query =~ s/^-// || $opts{nonfatal};
		my $q = $dbo->adhoc_query($query);
		if ($nonfatal) {
			my $r;
			if (eval { $r = $q->execute() }) {
				push(@ret, $r);
			} else {
				warn "do '$query':".$dbo->errstr
					unless $opts{silent};
				$dbo->rollback || confess $dbo->errstr;
			}
		} else {
			my $r = $q->execute()
				or confess("<<$query>>" . $dbo->errstr); 
			push(@ret, $r);
		}
		$dbo->commit if $opts{autocommit};
	}
	$dbo->commit if $opts{commit} || 
		! (ref($something) || $opts{autocommit});
	die "x='$command'" unless $command =~ /\G\s*\Z/sg;
	unless (ref $something) {
		$dbo->disconnect();
	}
	return(@ret);
}


1;
