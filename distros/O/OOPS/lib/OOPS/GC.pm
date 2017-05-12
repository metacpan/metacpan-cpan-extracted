
package OOPS::GC;

use OOPS;
require OOPS::Setup;
use OOPS::TxHash;
require Exporter;
use strict;
use warnings;
use Carp qw(confess);

our @ISA = qw(Exporter);
our @EXPORT = qw(gc);

# scale adjusts the limits
our $min_scale_factor	= 0.5;
our $max_scale_factor	= 20;
our $scale_up		= 1.2;
our $scale_down		= 0.8;

# limits
our $too_many_todo	= 5000;
our $work_length	= 200;
our $clear_batchsize	= 50;
our $virtual_hash_slice	= 20;
our $maximum_spill_size	= 500;

# debugging
our $debug		= 0;
our $debug_scale  	= 0;
our $debug_cleaned	= 0;

# counters
our $overflow_count	= 0;
our $readsaved_count	= 0;
our $error;

#
# Mark objects at the last minute, just before processing
# them?  Advantage: simpler, less chance of collision with
# other users of the database.  Disadvantage: more database
# query results because objects on the todo list will be
# returned.
#
our $mark_last_minute = 1;    

sub gc
{
	my (%args) = @_;

	$error = undef;
	my $dbms;
	my $prefix;
	my $hasbig = 1;
	transaction(sub {
		my $dbh;
		($dbh, $dbms, $prefix) = OOPS->dbiconnect(%args, readonly => 1);
		$dbh->disconnect();
	});
	require "OOPS/$dbms.pm";

	#
	# We'll need to transform the queries...
	#
	my $TPsub = sub {
		my ($query) = @_;
		$query =~ s/TP_/$prefix/g;
		return $query;
	};

	my $gcgen;
	transaction(sub {
		my ($dbh, $dbms, $prefix, $dbo) = OOPS->dbiconnect(%args);
		transaction_lock($dbo);
		undef $dbo;
		($gcgen) = $dbh->selectrow_array(&$TPsub(<<END));
			SELECT pval
			FROM TP_attribute
			WHERE id = 2 AND pkey = 'GC GENERATION'
END
		unless ($gcgen) {
			print "### ERROR: ".$dbh->errstr()."\n";
			confess $dbh->errstr() 
		}
		my $old = $gcgen++;
		print "# GC: New generation number: $gcgen\n";
		$dbh->do(&$TPsub(<<END), undef, $gcgen, $old) or confess $dbh->errstr;
			UPDATE	TP_attribute
			SET	pval = ?
			WHERE	id = 2 AND pkey = 'GC GENERATION' AND pval = ?
END
		$dbh->do(&$TPsub(<<END), undef, $gcgen, $OOPS::last_reserved_oid) or confess $dbh->errstr;
			UPDATE	TP_object
			SET	gcgeneration = ?
			WHERE	id <= ?
END
		$dbh->do(&$TPsub(<<END)) or confess $dbh->errstr;
			DELETE	FROM TP_attribute
			WHERE	id = $OOPS::gc_overflow_id
END
		$dbh->commit;
	});

	exit if $debug == 99;

	my $foo;
	my %todo_real = (
		1	=> \$foo,		# virtual hash
		2	=> undef,		# hash
		3	=> undef,		# hash
	);

	#
	# Stating at the root nodes, follow all references changing the 
	# GC generation as we go.
	#

	my $bailout = 0;
	my $scale_factor = 1;
	my $last_overflow_rows = 0;

	while (%todo_real && ! $bailout) {
		printf "# GC: Top of loop, todo = %d, scale = %.1f\n", scalar(keys %todo_real), $scale_factor if $debug || $debug_scale;
		my $accomplished = 0;
		my $overflow_rows = 0;
		my $restarts = 0;
		transaction(sub {
			my $th = tie my %todo, 'OOPS::TxHash', \%todo_real or confess;

			my ($dbh, $dbms, $prefix, $dbo) = OOPS->dbiconnect(%args);
			transaction_lock($dbo) if ++$restarts > 3;

			my ($curgcgen) = $dbh->selectrow_array(&$TPsub(<<END));
				SELECT pval
				FROM TP_attribute
				WHERE id = 2 AND pkey = 'GC GENERATION'
END
			if ($curgcgen != $gcgen) {
				$bailout = "Another GC is running, only one allowed at a time";
				print "# GC: curgen($curgcgen) != gcgen($gcgen)\n" if $debug;
				%todo_real = ();
				return;
			}

			my $overflow_rowsQ = $dbo->adhoc_query(<<END);
				SELECT	count(*)
				FROM	TP_attribute
				WHERE	id = $OOPS::gc_overflow_id
END
			$overflow_rowsQ->execute() || confess;
			($overflow_rows) = $overflow_rowsQ->fetchrow_array();
			$overflow_rowsQ->finish;

			my $work = 0;
			my $objects_done = 0;
			my $nlimit = int($virtual_hash_slice * $scale_factor);

			printf "# GC: Inner loop, work = %d, todo = %d\n", $work, scalar(%todo) if $debug;
			while ($work < $work_length * $scale_factor && %todo && %todo <= $too_many_todo * $scale_factor) {
				my ($id, $key);
				1 while not (($id, $key) = each(%todo)); # OOPS::TxHash better be right about SCALAR...

				printf "# GC: working on %d/%s\n", $id, defined($key) ? $key : "<undef>" if $debug;

				my $q;
				my $oldkey = 0;
				my $limit = defined($key) ? "LIMIT $nlimit" : "";
				if (defined $key && ! ref($key)) {
					print "# GC: continuing through a virtual hash\n" if $debug;
					$q = $dbo->adhoc_query(<<END, execute => [ $id, $key, $gcgen]) or confess $dbh->errstr;
						SELECT	o.id, o.otype, o.virtual, a.pkey
						FROM	TP_object AS o,
							TP_attribute AS a
						WHERE	a.id = ? 
						  AND	a.pkey > ?
						  AND	a.ptype = 'R'
						  AND	o.id = DBO:CAST:PGBYTEA2INT(a.pval)
						  AND	o.gcgeneration < ?
						ORDER	BY a.pkey
						LIMIT	$nlimit
END
					$oldkey = 1;
				} else {
					print "# GC: starting on a fresh object\n" if $debug;
					$objects_done++;
					if ($mark_last_minute) {
						print "# GC: marking $id as gen $gcgen\n" if $debug > 5;
						$q = $dbo->adhoc_query(<<END, execute => [$gcgen, $id, $gcgen]) or confess $dbh->errstr;
							UPDATE	TP_object 
							SET	gcgeneration = ?
							WHERE	id = ?
							  AND	gcgeneration < ?
END
						$q->finish;
					}
					$q = $dbo->adhoc_query(<<END, execute => [ $id, $gcgen ]) or confess $dbh->errstr;
						SELECT	o.id, o.otype, o.virtual, a.pkey
						FROM	TP_object AS o,
							TP_attribute AS a
						WHERE	a.id = ? 
						  AND	a.ptype = 'R'
						  AND	o.id = DBO:CAST:PGBYTEA2INT(a.pval)
						  AND	o.gcgeneration < ?
						ORDER	BY a.pkey
						$limit
END
				}


				my ($count, $newkey) = get_todo($q, \%todo);
				$work += $count || 1;

				print "# GC: found $count new things to worry about\n" if $debug;

				#
				# mark objects as done as they are added to the todo list
				#
				if ($mark_last_minute) {
					if ($limit and $count == $nlimit) {
						$todo{$id} = $newkey;
					} else {
						delete $todo{$id};
					}
				} elsif ($limit and $count == $nlimit) {
					if ($oldkey) {
						print "# GC: partial set from a virtual hash that was partway through '$key' to '$newkey'\n" if $debug;
						$q = $dbo->adhoc_query(<<END, execute => [$gcgen, $id, $key, $newkey, $gcgen]) or confess $dbh->errstr;
							UPDATE	TP_object AS o,
								TP_attribute AS a
							SET	o.gcgeneration = ?
							WHERE	a.id = ?
							  AND	a.pkey > ?
							  AND	a.pkey <= ?
							  AND	a.ptype = 'R'
							  AND	o.id = DBO:CAST:PGBYTEA2INT(a.pval)
							  AND	o.gcgeneration < ?
END
					} else {
						# partial set from a virtual hash that just started
						print "# GC: partial set from a new virtual hash ... upto '$newkey'\n" if $debug;
						$q = $dbo->adhoc_query(<<END, execute => [$gcgen, $id, $newkey, $gcgen]) or confess $dbh->errstr;
							UPDATE	TP_object AS o,
								TP_attribute AS a
							SET	o.gcgeneration = ?
							WHERE	a.id = ?
							  AND	a.pkey <= ?
							  AND	a.ptype = 'R'
							  AND	o.id = a.pval
							  AND	o.gcgeneration < ?
END
					}
					$todo{$id} = $newkey;
				} elsif ($limit && $oldkey) {
					print "# GC: finish a partially done virtual hash ...  from '$key'\n" if $debug;
					$q = $dbo->adhoc_query(<<END, execute => [$gcgen, $id, $key, $gcgen]) or confess $dbh->errstr;
						UPDATE	TP_object AS o,
							TP_attribute AS a
						SET	o.gcgeneration = ?
						WHERE	a.id = ?
						  AND	a.pkey > ?
						  AND	a.ptype = 'R'
						  AND	o.id = DBO:CAST:PGBYTEA2INT(a.pval)
						  AND	o.gcgeneration < ?
END
					delete $todo{$id};
				} else {
					print "# GC: finished an object\n" if $debug;
					$q = $dbo->adhoc_query(<<END, execute => [$gcgen, $id, $gcgen]) or confess $dbh->errstr;
						UPDATE	TP_object AS o,
							TP_attribute AS a
						SET	o.gcgeneration = ?
						WHERE	a.id = ?
						  AND	a.ptype = 'R'
						  AND	o.id = a.pval 
						  AND	o.gcgeneration < ?
END
					delete $todo{$id};
				}

			}

			#
			# At this point, we've either done enough work to finish the
			# transaction or we've run out of things to do.  First, if we've
			# run out, see if other processes have left us some new stuff
			# for our todo list.
			#

			while (! %todo) {
				print "# GC: TODO is empty, look for more\n" if $debug;
				my $q = $dbo->adhoc_query(<<END, execute => [$gcgen]) or confess $dbh->errstr;
					SELECT	o.id, o.otype, o.virtual, a.pkey
					FROM	TP_object AS o,
						TP_attribute AS a
					WHERE	a.id = $OOPS::gc_overflow_id
					  AND	o.id = DBO:CAST:PGBYTEA2INT(a.pkey)
					  AND	o.gcgeneration < ?
					ORDER BY a.pkey
					LIMIT 	$nlimit
END
				my ($count, $pkey) = get_todo($q, \%todo);
				$q->finish;
				my @args;
				if ($count == $nlimit) {
					$q = $dbo->adhoc_query(<<END) or confess $dbh->errstr;
						DELETE FROM TP_attribute
						WHERE	id = $OOPS::gc_overflow_id
						  AND	pkey <= ?
END
					@args = ($pkey);
				} else {
					$q = $dbo->adhoc_query(<<END) or confess $dbh->errstr;
						DELETE FROM TP_attribute
						WHERE	id = $OOPS::gc_overflow_id
END
					@args = ();
				}
				my $r = $q->execute(@args);
				confess unless $r;
				$objects_done += $r - $count;
				$q->finish;
				$readsaved_count += $count;
				print "# GC: TODO was empty, found $count more\n" if $debug;
				last unless $count;
			}

			#
			# Alternatively, if we're gotten here because we've done enough
			# let's check to make sure our todo list isn't getting too big.  If it
			# is, let's save some of it to the database.
			#

			if (%todo > $too_many_todo * $scale_factor) {
				print "# GC: TODO is overflowing, save some for later\n" if $debug;
				my $q1 = $dbo->adhoc_query(<<END) or confess $dbh->errstr;
					SELECT	COUNT(*)
					FROM	TP_attribute
					WHERE	id = $OOPS::gc_overflow_id
					  AND	pkey = ?
END
				my $q2 = $dbo->adhoc_query(<<END) or confess $dbh->errstr;
					INSERT INTO TP_attribute
					VALUES ($OOPS::gc_overflow_id, ?, '', '0')
END
				my $spilled = 0;
				for my $id (keys %todo) {
					next if defined $todo{$id};
					$q1->execute($id) or confess $dbh->errstr;
					my ($rc) = $q1->fetchrow_array();
					next if $rc > 0;
					$q2->execute($id) or confess $dbh->errstr;
					delete $todo{$id};
					$overflow_count++;
					last if %todo < $too_many_todo * $scale_factor / 2;
					last if ++$spilled > $maximum_spill_size * $scale_factor;
				}
				$q1->finish();
				$q2->finish();
			}
			#
			# Okay, time to record what we've done and go 'round again.
			#

			print "# GC commit\n" if $debug;
			$dbh->commit or confess $dbh->errstr;
			$th->commit;
			$accomplished = $objects_done;
		});
		printf "# GC: accomplished: %d change in overflow rows: %d old scale: %.2f restarts: %d\n", $accomplished, $overflow_rows - $last_overflow_rows, $scale_factor, $restarts if $debug_scale;
		if ($accomplished < $overflow_rows - $last_overflow_rows) {
			# we didn't get as much done as new work came in.
			if ($restarts < 5) {
				# try to do more work in each transaction
				$scale_factor *= $scale_up;
			} else {
				# maybe we're trying to do too much at once?
				$scale_factor *= $scale_down;
			}
		} else {
			# let's do less at once so we have a smaller impact
			# on other transactions
			$scale_factor *= ((1+$scale_down)/2);
		}
	}

	if ($bailout) {
		print STDERR "# GC: $bailout\n";
		$error = $bailout;
		return undef;
	}

	my $total = 0;

	#
	# Now, we want to run a scan across all objects but we don't
	# want to lock the whole database as we do it.  
	#

	print "# GC: Scanning for objects we didn't mark\n" if $debug || $debug_cleaned;

	for(;;) {
		my $idlast = -1;
		my $last;
		my $restarts = 0;
		transaction(sub {
			my ($dbh, $dbms, $prefix, $dbo) = OOPS->dbiconnect(%args);
			transaction_lock($dbo) if ++$restarts > 3;
			my $q = $dbh->prepare(&$TPsub(<<END)) or confess $dbh->errstr;
				SELECT	id
				FROM	TP_object
				WHERE	id > ?
				  AND	gcgeneration < ?
				LIMIT	$clear_batchsize
END
			$q->execute($idlast, $gcgen) or confess $dbh->errstr;
			my @idset;
			while (my ($id) = $q->fetchrow_array()) {
				push(@idset, $id);
			}
			$q->finish();
			return unless @idset;

			print "# GC: found @idset, will delete 'em\n" if $debug || $debug_cleaned;

			my $decrement = $dbo->adhoc_query(<<END) or confess $dbh->errstr;
				# DBO:name GC::decrement
				:sqlite2:
					UPDATE	TP_object 
					SET	refs = refs - 1
					WHERE	id IN (
						SELECT	pval
						FROM	TP_attribute
						WHERE	id = ?
						  AND	ptype = 'R'
						)
				:sqlite:
					UPDATE	TP_object 
					SET	refs = refs - 1
					WHERE	id IN (
						SELECT	pval
						FROM	TP_attribute
						WHERE	id = ?
						  AND	ptype = 'R'
						)
				:mysql:
					UPDATE	TP_object AS o, TP_attribute AS a
					SET	o.refs = o.refs - 1
					WHERE	a.id = ?
					  AND	a.ptype = 'R'
					  AND	o.id = a.pval
				:pg:
					UPDATE	TP_object 
					SET	refs = refs - 1
					FROM	TP_attribute
					WHERE	TP_attribute.id = ?
					  AND	TP_attribute.ptype = 'R'
					  AND	TP_object.id = DBO:CAST:PGBYTEA2INT(TP_attribute.pval)
END
			my $ro = $dbh->prepare(&$TPsub(<<END)) or confess $dbh->errstr;
				DELETE FROM TP_object
				WHERE id = ?
END
			my $ra = $dbh->prepare(&$TPsub(<<END)) or confess $dbh->errstr;
				DELETE FROM TP_attribute
				WHERE id = ?
END
			my $ref = $dbh->prepare(&$TPsub(<<END)) or confess $dbh->errstr;
				UPDATE	TP_attribute
				SET	pval = NULL, ptype = '0'
				WHERE	pval = ?
END
			for my $id (@idset) {
				$decrement->execute($id) or confess $dbh->errstr;
				$ro->execute($id) or confess $dbh->errstr;
				$ra->execute($id) or confess $dbh->errstr;
				$ref->execute($id) or confess $dbh->errstr;
			}

			if ($hasbig) {
				my $rb = $dbh->prepare(&$TPsub(<<END)) or confess $dbh->errstr;
					DELETE FROM TP_big
					WHERE id = ?
END
				for my $id (@idset) {
					$rb->execute($id) or confess $dbh->errstr;
				}
			}
			$dbh->commit or confess $dbh->errstr;
			$total += @idset;
			$last = $idset[$clear_batchsize-1];
		});
		last unless $last;
		$idlast = $last;
	};

	print "# GC $total objects removed\n" if $debug;
	return $total;
}

sub get_todo
{
	my ($q, $todoref) = @_;

	my ($oid, $otype, $ovirtual, $pkey);
	my $count = 0;
	while (($oid, $otype, $ovirtual, $pkey) = $q->fetchrow_array()) {
		print "# GC:	more todo $oid $otype $ovirtual $pkey\n" if $debug;
		$count++;
		next if exists $todoref->{$oid};
		if ($ovirtual) {
			$todoref->{$oid} = \'VIRTUAL';
		} else {
			$todoref->{$oid} = undef;
		}
	}
	$q->finish;
	return $count unless wantarray();
	return ($count, $pkey);
}

#
# Hopefully this will avoid persistent deadlock problems
# with mysql.
#
sub transaction_lock
{
	my ($dbo) = @_;
	$dbo->adhoc_query(<<END, execute => [1]);
		SELECT	counter
		FROM	TP_object
		WHERE	id = ?
END
}

1;

__END__

We're trying to do a recursive traversal of all data structures w/o locking much
of the database at a time.

We do this by keeping a todo list of things that we haven't yet processed.
Things on the todo list have have been marked but their children have not.

Since this is done live, what happens when we have 


	$root => {
		A	=> {
			foo	=> (bless { }, bar),
		},
		B	=> {
		},
	}

and then after we've processed B, but before we've gotten to A, foo moves from A to B?


To handle this, OOPS needs to be able to signal us whenever it adds a new reference
from an object that has been GC'ed to one that has not.



SELECT	o.id, o.otype, o.virtual, a.pkey
FROM	charm2object AS o,
charm2attribute AS a
WHERE	a.id = 113 
AND	a.ptype = 'R'
AND	o.id = a.pval 
AND	o.gcgeneration < 3
ORDER	BY a.pkey;



=head1 NAME

 OOPS::GC - Garbage Collector for OOPS

=head1 SYNOPSIS

 use OOPS::GC;

 gc(%args);

=head1 DESCRIPTION

OOPS::GC provides a garbage collector for your persistent
data.  You only need this if you've got a persistent memory
leak in your program.  The way to leak memory is to make a
circular reference between objects and then delete all reference
to the objects with the circular reference.

It's easy to do accidently.

If you find your database is growing more than you think it
should, run C<OOPS::CG::gc()> on it.

For the database that support concurrent access (ie: not SQLite),
the garbage collector runs in the background and does not lock 
up the database.  The garbage collector may need to temporarily 
store additional information in the database so don't run it when
your disk is already full!

=head1 INVOCATION

The arguments you pass to C<gc()> are exactly the same as the
arguments you pass to C<OOPS::dbiconnect()>.

=head1 LICENSE

Same as for L<OOPS>.

