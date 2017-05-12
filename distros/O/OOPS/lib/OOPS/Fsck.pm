
package OOPS::Fsck;

use OOPS;
use OOPS::Setup;
require Exporter;
use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT = qw(fsck);

our $check_batchsize = 200;
our $silent = 0;
our $debug = 0;

sub fsck
{
	my (%args) = @_;

	my $dbms;
	my $prefix;
	my $hasbig = 1;
	{
		my $dbh;
		($dbh, $dbms, $prefix) = OOPS->dbiconnect(%args, readonly => 1);
	}
	require "OOPS/$dbms.pm";

	#
	# We'll need to transform the queries...
	#
	my $TPsub = sub {
		my ($query) = @_;
		$query =~ s/TP_/$prefix/g;
		return $query;
	};

	my $corrections;
	my $rows;
	my $lastid = $OOPS::last_reserved_oid;
	for (;;) {
		my $some = 0;
		transaction(sub {
			my $dbh = OOPS->dbiconnect(%args);
			my $refsQ = $dbh->prepare_cached(&$TPsub(<<END)) || die;
				SELECT	COUNT(*)
				FROM	TP_attribute
				WHERE	pval = ?
				  AND	ptype = 'R'
END
			my $getobjQ = $dbh->prepare(&$TPsub(<<END)) || die;
				SELECT	id, class, otype, refs
				FROM	TP_object
				WHERE	id > ?
				LIMIT	$check_batchsize
END
			$getobjQ->execute($lastid) || die $dbh->errstr;
			my $commit = 0;
			my $last;
			while (my ($id, $class, $otype, $refs) = $getobjQ->fetchrow_array()) {
				$some++;
				$last = $id;
				$refsQ->execute($id) || die;
				my ($found) = $refsQ->fetchrow_array();
				if ($found == $refs) {
					print "# Fsck: Ref correct for *$id $otype/$class\n" if $debug;
				} else {
					print STDERR "Correcting refcount for *$id $otype/$class: was $refs, now $found\n"
						if ! $silent;
					my $update = $dbh->prepare_cached(&$TPsub(<<END)) || die;
						UPDATE	TP_object
						SET	refs = ?
						WHERE	id = ?
END
					$update->execute($found, $id) || die;
					$commit++;
				}
			}
			$getobjQ->finish();
			$dbh->commit if $commit;
			$corrections += $commit;
			$rows += $some;
			$lastid = $last;
		});
		last unless $some;
	}
	my $missingobjs = 0;
	$lastid = $OOPS::last_reserved_oid;
	my $lastpkey = undef;
	for (;;) {
		my $done = 0;
		transaction(sub {
			my $dbh = OOPS->dbiconnect(%args);
			my $found;
			my $stop_at_id;
			if (defined $lastpkey) {
				print "# Fsck: continuing with $lastid/$lastpkey\n" if $debug;
				my $getrefQ = $dbh->prepare(&$TPsub(<<END)) || die;
					SELECT	pkey, pval
					FROM	TP_attribute
					WHERE	id = ?
					  AND	pkey >= ?
					  AND	ptype = 'R'
					ORDER BY pkey
					LIMIT $check_batchsize
END
				$getrefQ->execute($lastid, $lastpkey) || die $dbh->errstr;
				$found = $getrefQ->fetchall_arrayref();
				if (@$found < $check_batchsize) {
					print "# Fsck: done with $lastid\n" if $debug;
					undef $lastpkey;
				} else {
					$lastpkey = $found->[$#$found][0];
				}
			} else {
				print "# Fsck: Searching from $lastid\n" if $debug;
				my $getrefQ = $dbh->prepare(&$TPsub(<<END)) || die;
					SELECT	pkey, pval, id
					FROM	TP_attribute
					WHERE	id > ?
					  AND	ptype = 'R'
					ORDER	BY id, pkey
					LIMIT	$check_batchsize
END
				$getrefQ->execute($lastid) || die $dbh->errstr;
				$found = $getrefQ->fetchall_arrayref();
				$stop_at_id = $found->[$#$found][2];
				die unless $stop_at_id;
				if (@$found < $check_batchsize) {
					print "# Fsck: all done\n" if $debug;
					$done = 1;
				} elsif ($found->[0][2] == $stop_at_id) {
					print "# Fsck: all one batch\n" if $debug;
					$lastpkey = $found->[$#$found][0];
					$stop_at_id = undef;
				}
			}
			my $checkobjQ = $dbh->prepare(&$TPsub(<<END)) || die;
				SELECT	id
				FROM	TP_object
				WHERE	id = ?
END
			my $commit = 0;
			for my $row (@$found) {
				my $fromid = $row->[2] || $lastid;
				if ($stop_at_id and $fromid == $stop_at_id) {
					last;
				}
				$lastid = $fromid;
				my $toid = $row->[1];
				$checkobjQ->execute($toid) || die;
				my ($fetchedid) = $checkobjQ->fetchrow_array();
				if (! $fetchedid) {
					print STDERR "Reference to missing object *$toid from *$fromid/$row->[0]\n";
					my $cleanupQ = $dbh->prepare_cached(&$TPsub(<<END)) || die;
						UPDATE	TP_attribute
						SET	ptype = '', pval = null
						WHERE	id = ?
						  AND	pkey = ?
END
					$cleanupQ->execute($fromid, $row->[0]) || die;
					$commit++;
				}
			}

			$checkobjQ->finish();
			$dbh->commit if $commit;
			$missingobjs += $commit;
		});
		last if $done;
	}
	print STDERR "Rows: $rows, Corrections: $corrections, Missing Objects: $missingobjs\n" if ($corrections || $missingobjs || $debug) && ! $silent;
	return ($rows, $corrections, $missingobjs) if wantarray;
	return $corrections + $missingobjs;
}

1;


__END__

=head1 NAME

 OOPS::Fsck - Reference checker for OOPS

=head1 SYNOPSIS

 use OOPS::Fsck;

 fsck(%args);

=head1 DESCRIPTION

OOPS::Fsck provides a sanity checker for your persistent
data.  You only need this if you've got some indication there
might be a problem (OOPS dying due to reference counts of -1).

It will correct reference counts on objects.  It will remove 
pointers to objects that don't exist. 

If you have these sorts of problems, you should probably also
run garbage collection (L<OOPS::GC>).

=head1 INVOCATION

The arguments you pass to C<fsck()> are exactly the same as the
arguments you pass to C<OOPS::dbiconnect()>.

=head1 LICENSE

See the license for L<OOPS>.

