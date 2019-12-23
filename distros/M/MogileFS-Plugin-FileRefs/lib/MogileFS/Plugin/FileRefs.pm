package MogileFS::Plugin::FileRefs;

use strict;
use warnings;

use MogileFS::Store;
use MogileFS::Worker::Query;

use constant LOCK_TIMEOUT => 5;

our $VERSION = '0.10';
MogileFS::Store->add_extra_tables("file_ref");

sub load {
    MogileFS::register_worker_command('add_file_ref', \&add_file_ref) or die;

    MogileFS::register_worker_command('del_file_ref', \&del_file_ref) or die;

    MogileFS::register_worker_command('rename_if_no_refs', \&rename_if_no_refs) or die;

    MogileFS::register_worker_command('list_refs_for_dkey', \&list_refs_for_dkey) or die;
}

# By virtue of DBI, this returns true if the connection worked.
sub _claim_lock {
    my ($rv) = Mgd::validate_dbh->selectrow_array("SELECT GET_LOCK(?,?)", {}, "mogile-filerefs-".$_[1]->{domain}."-".$_[1]->{arg1}, LOCK_TIMEOUT());
    return $rv==1;
}

sub _free_lock {
    eval { Mgd::validate_dbh->do("SELECT RELEASE_LOCK(?)", {}, "mogile-filerefs-".$_[1]->{domain}."-".$_[1]->{arg1}) or warn "could not free lock: $DBI::errstr"; };
    return;
}

sub add_file_ref {
    my ($query, $args) = @_;
    my $dmid = $query->check_domain($args) or return;
    my $dbh = Mgd::validate_dbh();
    _claim_lock($query, $args) or return $query->err_line("get_key_lock_fail");
    local $@;
    my $updated = eval { $dbh->do("INSERT INTO file_ref (dmid, dkey, ref) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE ref=ref", {}, $dmid, $args->{arg1}, $args->{arg2}); };
    if ($@ || $dbh->err || $updated < 1) {
        _free_lock($query, $args);
        return $query->err_line("add_file_ref_fail");
    }
    _free_lock($query, $args);
    return $query->ok_line({made_new_ref => $updated>1 ? 0:1});
}

sub del_file_ref {
    my ($query, $args) = @_;
    my $dbh = Mgd::validate_dbh();
    my $dmid = $query->check_domain($args) or return;
    local $@;
    my $deleted = eval { $dbh->do("DELETE FROM file_ref WHERE dmid = ? AND dkey = ? AND ref = ?", {}, $dmid, $args->{arg1}, $args->{arg2}) };
    if ($@ || $dbh->err) {
        return $query->err_line("del_file_ref_fail");
    }
    return $query->ok_line({deleted_ref => $deleted>0 ? 1:0 });
}

# TODO - use a stored procedure.

sub rename_if_no_refs {
    my ($query, $args) = @_;
    my $dbh = Mgd::validate_dbh();

    my $dmid = $query->check_domain($args) or return;

    _claim_lock($query, $args) or return $query->err_line("get_key_lock_fail");

    my ($count) = eval { $dbh->selectrow_array("SELECT COUNT(*) FROM file_ref WHERE dmid = ? AND dkey = ?", {}, $dmid, $args->{arg1}) };
    if ($@ || $dbh->err) {
        _free_lock($query, $args);
        return $query->err_line("rename_if_no_refs_failed");
    }

    if ($count != 0) {
        _free_lock($query, $args);
        return $query->ok_line({files_outstanding => $count});
    }

    my $updated = eval { $dbh->do("UPDATE file SET dkey = ? WHERE dmid = ? AND dkey = ?", {}, $args->{arg2}, $dmid, $args->{arg1}); };
    if ($@ || $dbh->err) {
        _free_lock($query, $args);
        return $query->err_line("rename_if_no_refs_failed");
    }
    _free_lock($query, $args);

    return $query->ok_line({files_outstanding => 0, updated => $updated+0});
}

sub list_refs_for_dkey {
    my ($query, $args) = @_;
    my $dmid = $query->check_domain($args) or return;
    my $dbh = Mgd::validate_dbh();
    my $result = eval {
        $dbh->selectcol_arrayref("SELECT ref FROM file_ref WHERE dmid = ? AND dkey = ?", {}, $dmid, $args->{arg1});
    };
    if ($@ || $dbh->err) {
        return $query->err_line("list_refs_for_dkey_failed");
    }
    my $i;
    return $query->ok_line({
        total => scalar(@$result),
        map { "ref_".$i++ => $_ } @{ $result }
    });

}

sub update_schema {
    my $store = Mgd::get_store();
    my $dbh = $store->dbh();
    $dbh->do($store->filter_create_sql(TABLE_fileref()))
        or die "Failed to create table file_ref: ". $dbh->errstr;

    return;
}

BEGIN {
    *MogileFS::Store::TABLE_file_ref = sub {
        q{CREATE TABLE `file_ref` (
      `dmid` SMALLINT UNSIGNED NOT NULL,
      `dkey` varchar(255) DEFAULT NULL,
      `ref`  varchar(255) DEFAULT NULL,
      UNIQUE KEY `i_unique` (`dmid`,`dkey`,`ref`)
    );
    };
    };
}

1;
__END__

=head1 NAME

MogileFS::Plugin::FileRefs - MogileFS extension

=head1 DESCRIPTION

This module provides MogileFS with additional functionality to keep track of
multiple uses of an individual dkey.  This may be useful for implementing
de-duplication in your application.


=head2 Mogile commands

=over

=item add_file_ref

Takes domain id, dkey, and your reference as arguments.

Creates an association from a key to your reference.

=item del_file_ref

Takes domain id, dkey, and your reference as arguments.

Deletes an association from a key to your reference.

=item rename_if_no_refs

Takes domain id, old dkey and new dkey.

Atomically renames a dkey provided there are no references to it.

=item list_refs_for_dkey

Takes domain id, dkey.

Lists all the references against a dkey.

=back

=head2 Locking behaviour

Care has been taken to ensure that it is possible to remove a file, without
the danger of a reference being added to it during the deletion process.
L<add_file_ref> take a lock, keyed to the domain and key of the reference
added.  C<rename_if_no_refs> also takes a lock which it holds between checking
the reference count and actually doing the renaming, ensuring a reference
cannot sneak in.

If a lock cannot be obtained within the timeout period, a C<get_key_lock_fail>
error is returned.

=head1 SEE ALSO

L<MogileFS::Server>

=head1 AUTHOR

Dave Lambley, E<lt>dlambley@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 Oscar Music and Media

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
