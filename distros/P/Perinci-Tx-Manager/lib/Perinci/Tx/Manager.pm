package Perinci::Tx::Manager;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use DBI;
use File::Flock::Retry;
use File::Remove qw(remove);
use JSON::MaybeXS;
use Perinci::Sub::Util qw(err);
use Scalar::Util qw(blessed);
use Package::MoreUtil qw(package_exists);
use Time::HiRes qw(time);
use UUID::Random;

# patch, add special action to just retrieve code and meta
require Perinci::Access::Schemeless;
package
    Perinci::Access::Schemeless;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-17'; # DATE
our $DIST = 'Perinci-Tx-Manager'; # DIST
our $VERSION = '0.580'; # VERSION

sub actionmeta_get_code_and_meta { +{
    applies_to => ['function'],
    summary    => "Get code and metadata",
} }

sub action_get_code_and_meta {
    my ($self, $req) = @_;

    my $res;

    $res = $self->get_code($req);
    return $res if $res;

    $res = $self->get_meta($req);
    return $res if $res;

    [200, "OK", [$req->{-code}, $req->{-meta}]];
}

package Perinci::Tx::Manager;

my $proto_v = 2;

our $ep = ""; # error prefix
our $lp = "[tm]"; # log prefix

my $json = JSON::MaybeXS->new->allow_nonref;

# this is used for testing purposes only (e.g. to simulate crash)
our %_hooks;
our %_settings = (
    default_rollback_on_action_failure => 1,
);

# note: to avoid confusion, whenever we mention 'transaction' (or tx for short)
# in the code, we must always specify whether it is a sqlite tx (sqltx) or a
# Rinci tx (Rtx).

# note: no method should die(), we should return error response instead. this is
# historical (we are called by Perinci::Access::Schemeless and in turn it is
# called by Perinci::Access::HTTP::Server, they used to have no wrapper eval(),
# but that turns out to be rather unsafe). an exception to this is in _init(),
# when we don't want to deal with old data and just die.

# note: we have not dealt with sqlite's rowid wraparound. since it's a 64-bit
# integer, we're pretty safe. we also usually rely on ctime first for sorting.

# new() should return object on success, or an error string if failed (fatal
# error). the other methods (internal or external) returns enveloped result.
sub new {
    my ($class, %opts) = @_;
    return "Please supply pa object" unless blessed $opts{pa};
    return "pa object must be an instance of Perinci::Access::Schemeless"
        unless $opts{pa}->isa("Perinci::Access::Schemeless");

    my $obj = bless \%opts, $class;
    if ($opts{data_dir}) {
        unless (-d $opts{data_dir}) {
            mkdir $opts{data_dir} or return "Can't mkdir $opts{data_dir}: $!";
        }
    } else {
        for ("$ENV{HOME}/.perinci", "$ENV{HOME}/.perinci/.tx") {
            unless (-d $_) {
                mkdir $_ or return "Can't mkdir $_: $!";
            }
        }
        $opts{data_dir} = "$ENV{HOME}/.perinci/.tx";
    }
    my $res = $obj->_init;
    return $res->[1] unless $res->[0] == 200;
    $obj;
}

sub _lock_db {
    my ($self, $shared) = @_;

    eval {
        unless ($self->{_lock}) {
            $self->{_lock} = File::Flock::Retry->lock(
                "$self->{_db_file}.lck", {retries=>5, shared=>1});
        }
    };
    return [532, "Tx database is still locked by other process ".
                "(probably recovery) after 5 seconds, giving up: $@"]
        if $@;
    [200];
}

sub _unlock_db {
    my ($self) = @_;

    undef $self->{_lock};
    [200];
}

sub _init {
    my ($self) = @_;
    my $data_dir = $self->{data_dir};
    log_trace("$lp Initializing data dir %s ...", $data_dir);

    unless (-d "$self->{data_dir}/.trash") {
        mkdir "$self->{data_dir}/.trash"
            or return [532, "Can't create .trash dir: $!"];
    }
    unless (-d "$self->{data_dir}/.tmp") {
        mkdir "$self->{data_dir}/.tmp"
            or return [532, "Can't create .tmp dir: $!"];
    }

    $self->{_db_file} = "$data_dir/tx.db";

    (-d $data_dir)
        or return [532, "Transaction data dir ($data_dir) doesn't exist ".
                       "or not a dir"];
    my $dbh = DBI->connect("dbi:SQLite:dbname=$self->{_db_file}", undef, undef,
                           {
                               RaiseError => 0,
                               #sqlite_use_immediate_transaction => 1
                           })
        or return [532, "Can't connect to transaction DB: $DBI::errstr"];

    # init database

    local $ep = "Can't init tx db:"; # error prefix

    $dbh->do(<<_) or return [532, "$ep create tx: ". $dbh->errstr];
CREATE TABLE IF NOT EXISTS tx (
    ser_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    str_id VARCHAR(200) NOT NULL,
    owner_id VARCHAR(64) NOT NULL,
    summary TEXT,
    status CHAR(1) NOT NULL, -- i, a, C, U, R, u, v, d, e, X [uppercase=final]
    ctime REAL NOT NULL,
    commit_time REAL,
    last_action_id INTEGER,
    UNIQUE (str_id)
)
_

    # for tx with status=i, last_action_id is the in-progress action ID, set
    # when in the middle of processing actions, then unset again after action
    # has finished. during recovery, if tx with status=i still has this field
    # set, it means it has crashed in the middle of action.
    #
    # for tx with other transient status (a, u/v, d/e) this field is used to
    # mark which action has been processed. rollback/roll forward will start
    # from this action instead of having to start from the first action of
    # transaction.

    $dbh->do(<<_) or return [532, "$ep create do_action: ". $dbh->errstr];
CREATE TABLE IF NOT EXISTS do_action (
    tx_ser_id INTEGER NOT NULL, -- refers tx(ser_id)
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    sp TEXT, -- for named savepoint
    ctime REAL NOT NULL,
    f TEXT NOT NULL,
    args TEXT NOT NULL,
    UNIQUE(sp)
)
_

    $dbh->do(<<_) or return [532, "$ep create undo_action: ". $dbh->errstr];
CREATE TABLE IF NOT EXISTS undo_action (
    tx_ser_id INTEGER NOT NULL, -- refers tx(ser_id)
    action_id INTEGER NOT NULL, -- refers do_action(id)
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    ctime REAL NOT NULL,
    f TEXT NOT NULL,
    args TEXT NOT NULL
)
_

    $dbh->do(<<_) or return [532, "$ep create _meta: ".$dbh->errstr];
CREATE TABLE IF NOT EXISTS _meta (
    name TEXT PRIMARY KEY NOT NULL,
    value TEXT
)
_
    $dbh->do(<<_) or return [532, "$ep insert v: ".$dbh->errstr];
-- v is incremented everytime schema changes
INSERT OR IGNORE INTO _meta VALUES ('v', '5')
_

    # deal with table structure changes
  UPDATE_SCHEMA:
    while (1) {
        my ($v) = $dbh->selectrow_array(
            "SELECT value FROM _meta WHERE name='v'");
        if ($v <= 3) {

            # changes incompatible (no longer undo_step and redo_step tables),
            # can lose data. we bail and let user decide for herself.

            die join(
                "",
                "Your transaction database ($self->{_db_file}) is still at v=3",
                ", there is incompatible changes with newer version. ",
                "Either delete the transaction database (and lose undo data) ",
                "or use an older version of ".__PACKAGE__." (0.28 or older).\n",
            );

        } elsif ($v == 4) {

            eval {
                local $dbh->{RaiseError} = 1;
                $dbh->begin_work;

                # rename field: last_call_id -> last_action_id
                $dbh->do("ALTER TABLE tx RENAME TO tmp_tx");
                $dbh->do(<<'_');
CREATE TABLE IF NOT EXISTS tx (
    ser_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    str_id VARCHAR(200) NOT NULL,
    owner_id VARCHAR(64) NOT NULL,
    summary TEXT,
    status CHAR(1) NOT NULL, -- i, a, C, U, R, u, v, d, e, X [uppercase=final]
    ctime REAL NOT NULL,
    commit_time REAL,
    last_action_id INTEGER,
    UNIQUE (str_id)
)
_
                $dbh->do(<<'_');
INSERT INTO tx (ser_id,str_id,owner_id,summary,status,ctime,commit_time,last_action_id)
SELECT ser_id,str_id,owner_id,summary,status,ctime,commit_time,last_call_id FROM tmp_tx
_

                $dbh->do("DROP TABLE tmp_tx");
                $dbh->do("DROP TABLE call");
                $dbh->do("DROP TABLE undo_call");
                $dbh->do("UPDATE _meta SET value='5' WHERE name='v'");
                # delete column sp, not yet
                $dbh->commit;
            };
            my $e = $@;
            do { $dbh->rollback; die $e } if $e;

        } else {
            # already the latest schema version
            last UPDATE_SCHEMA;
        }
    }

    $self->{_dbh} = $dbh;
    log_trace("$lp Data dir initialization finished");
    $self->_recover;
}

sub get_trash_dir {
    my ($self) = @_;
    my $tx = $self->{_cur_tx};
    return [412, "No current transaction, won't create trash dir"] unless $tx;
    my $d = "$self->{data_dir}/.trash/$tx->{ser_id}";
    unless (-d $d) {
        mkdir $d or return [532, "Can't mkdir $d: $!"];
    }
    [200, "OK", $d];
}

sub get_tmp_dir {
    my ($self) = @_;
    my $tx = $self->{_cur_tx};
    return [412, "No current transaction, won't create tmp dir"] unless $tx;
    my $d = "$self->{data_dir}/.tmp/$tx->{ser_id}";
    unless (-d $d) {
        mkdir $d or return [532, "Can't mkdir $d: $!"];
    }
    [200, "OK", $d];
}

sub get_func_and_meta {
    my ($self, $func) = @_;

    my ($module, $leaf) = $func =~ /(.+)::(.+)/
        or return [400, "Not a valid fully qualified function name: $func"];
    my $module_p = $module; $module_p =~ s!::!/!g; $module_p .= ".pm";
    eval { require $module_p };
    my $req_err = $@;
    if ($req_err) {
        if (!package_exists($module)) {
            return [532, "Can't load module $module (probably ".
                        "mistyped or missing module): $req_err"];
        } elsif ($req_err !~ m!Can't locate!) {
            return [532, "Can't load module $module (probably ".
                        "compile error): $req_err"];
        }
        # require error of "Can't locate ..." can be ignored. it
        # might mean package is already defined by other code. we'll
        # try and access it anyway.
    } elsif (!package_exists($module)) {
        # shouldn't happen
        return [532, "Module loaded OK, but no $module package ".
                    "found, something's wrong"];
    }
    # get metadata as well as wrapped
    my $res = $self->{pa}->request(get_code_and_meta => "/$module/$leaf");
    $res;
}

# about _in_sqltx: DBI/DBD::SQLite currently does not support checking whether
# we are in an active sqltx, except $dbh->{BegunWork} which is undocumented. we
# use our own flag here.

# just a wrapper to avoid error when rollback with no active tx
sub _rollback_dbh {
    my $self = shift;
    $self->{_dbh}->rollback if $self->{_in_sqltx};
    $self->{_in_sqltx} = 0;
    [200];
}

# just a wrapper to avoid error when committing with no active tx
sub _commit_dbh {
    my $self = shift;
    return [200] unless $self->{_in_sqltx};
    my $res = $self->{_dbh}->commit;
    $self->{_in_sqltx} = 0;
    $res ? [200] : [532, "db: Can't commit: ".$self->{_dbh}->errstr];
}

# just a wrapper to avoid error when beginning twice
sub _begin_dbh {
    my $self = shift;
    return [200] if $self->{_in_sqltx};
    my $res = $self->{_dbh}->begin_work;
    $self->{_in_sqltx} = 1;
    $res ? [200] : [532, "db: Can't begin: ".$self->{_dbh}->errstr];
}

sub _test_tx_support {
    my ($self, $meta) = @_;
    my $ff = $meta->{features} // {};
    $ff->{tx} or
        return [412, "function does not support transaction"];
    ($ff->{tx}{v} // 1) == $proto_v
        or return [412, "function does not support correct transaction ".
            "protocol version (v=$proto_v needed)"];
    $ff->{idempotent} or
        return [412, "function does not declare idempotent feature"];
    [200];
}

# check actions. actions should be [[f,args,JSON(args),cid?,\&code?,$meta?],
# ...]. this function will check whether function name is valid, whether
# arguments can be deserialized, etc. modify actions in-place (e.g. qualify
# function names if $opts->{qualify} is set, decode/encode JSON for arguments,
# cache function in [4], cache meta in [5]).
sub _check_actions {
    my ($self, $actions, $opts) = @_;
    $opts //= {};
    return [532, "BUG: argument 'actions' not an array"]
        unless ref($actions) eq 'ARRAY';
    my $i = 0;
    for my $a (@$actions) {
        $i++;
        local $ep = "action #$i ($a->[0]): invalid action";
        return [532, "$ep: not an array"] unless ref($a) eq 'ARRAY';
        $a->[0] = "$opts->{qualify}::$a->[0]"
            if $opts->{qualify} && $a->[0] !~ /::/;
        return [532, "$ep: invalid function name"]
            unless $a->[0] =~ /\A\w+(::\w+)+\z/;
        eval {
            if ($a->[2]) {
                $a->[1] = $json->decode($a->[2]);
            } elsif ($a->[1]) {
                $a->[2] = $json->encode($a->[1]);
            }
        };
        return [532, "$ep: can't decode/encode JSON arguments: $@"] if $@;
        my $res = $self->get_func_and_meta($a->[0]);
        return err(532, "$ep: can't get metadata", $res)
            unless $res->[0] == 200;
        my ($func, $meta) = @{$res->[2]};
        $res = $self->_test_tx_support($meta);
        return err(532, "$ep: function does not pass tx support test", $res)
            unless $res->[0] == 200;
        $a->[4] = $func;
        $a->[5] = $meta;
    }
    [200];
}

sub _set_tx_status_before_or_after_actions {
    my ($self, $which0, $whicha) = @_;

    my $dbh = $self->{_dbh};
    my $tx  = $self->{_cur_tx};

    my $os = $tx->{status};
    my $ns; # temporary new status during processing
    my $fs; # desired final status
    if ($whicha eq 'action') {
        # no change is expected
        $ns = $os;
        $fs = $os;
    } elsif ($whicha eq 'rollback') {
        $ns = $os eq 'i' ? 'a' : $os eq 'u' ? 'v' : $os eq 'd' ? 'e' : $os;
        $fs = $os eq 'u'||$ns eq 'v' ? 'C' : $os eq 'd'||$ns eq 'e' ? 'U' : 'R';
    } elsif ($whicha eq 'undo') {
        $ns = 'u';
        $fs = 'U';
    } elsif ($whicha eq 'redo') {
        $ns = 'd';
        $fs = 'C';
    }

    if ($which0 eq 'before') {
        if ($ns ne $os) {
            log_trace("$lp Setting transient transaction status ".
                             "%s -> %s ...", $os, $ns);
            $dbh->do("UPDATE tx SET status='$ns', last_action_id=NULL ".
                         "WHERE ser_id=?", {}, $tx->{ser_id})
                or return [532, "db: Can't update tx status $os -> $ns: ".
                    $dbh->errstr];
            # to make sure, check once again if Rtx status is indeed updated
            my @r = $dbh->selectrow_array(
                "SELECT status FROM tx WHERE ser_id=?", {}, $tx->{ser_id});
            return [532, "Can't update tx status #3 ".
                        "(tx doesn't exist in db)"] unless @r;
            return [532, "Can't update tx status #2 ".
                        "(wants $ns, still $r[0])"]
                unless $r[0] eq $ns;
            # update row cache
            $tx->{status} = $ns; $tx->{last_action_id} = undef;
        }
    }
    $os = $ns;

    if ($which0 eq 'after') {
        if ($whicha eq 'action') {
            # reset last_action_id to mark that we are finished
            $dbh->do("UPDATE tx SET last_action_id=NULL ".
                         "WHERE ser_id=?", {}, $tx->{ser_id})
                or return [532, "db: Can't update last_action_id->NULL: ".
                    $dbh->errstr];
        }

        if ($os ne $fs) {
            log_trace("$lp Setting final transaction status %s -> %s ...",
                         $ns, $fs);
            $dbh->do("UPDATE tx SET status='$fs',last_action_id=NULL ".
                         "WHERE ser_id=?",
                     {}, $tx->{ser_id})
                or return [532, "db: Can't set tx status to $fs: ".
                               $dbh->errstr];
            # update row cache
            $tx->{status} = $fs; $tx->{last_action_id} = undef;
        }
    }

    [200];
}

sub _set_tx_status_before_actions {
    my $self = shift;
    $self->_set_tx_status_before_or_after_actions('before', @_);
}

sub _set_tx_status_after_actions {
    my $self = shift;
    $self->_set_tx_status_before_or_after_actions('after', @_);
}

# return enveloped actions (arrayref)
sub _get_actions_from_db {
    my ($self, $which) = @_;

    # for safety, we shouldn't call this function when which='action' anyway
    return [200, "OK", []] if $which eq 'action';

    my $dbh = $self->{_dbh};
    my $tx  = $self->{_cur_tx};

    my $t = $which eq 'redo' || $which eq 'rollback' && $tx->{status} eq 'v' ?
        'do_action' : 'undo_action';

    my $lai = $tx->{last_action_id};
    my $actions = $dbh->selectall_arrayref(
        "SELECT f, NULL, args, id FROM $t WHERE tx_ser_id=? ".
            ($lai ? "AND (id<>$lai AND ".
                 "ctime <= (SELECT ctime FROM $t WHERE id=$lai)) " : "").
                     "ORDER BY ctime, id", {}, $tx->{ser_id});
    [200, "OK", [reverse @$actions]];
}

# return enveloped undo actions (arrayref), this is currently used for debugging
sub _get_undo_actions_from_db {
    my ($self, $which) = @_;

    # rollback does not record undo actions in db
    return [200, "OK", []] if $which eq 'rollback';

    my $dbh = $self->{_dbh};
    my $tx  = $self->{_cur_tx};
    my $t = $which eq 'redo' || $which eq 'rollback' && $tx->{status} eq 'v' ||
        # we can also invoke actions during undo
        ($which eq 'action' && !$self->{_in_undo})
            ? 'undo_action' : 'do_action';

    my $actions = $dbh->selectall_arrayref(
        "SELECT f, NULL, args, id FROM $t WHERE tx_ser_id=? ".
            "ORDER BY ctime, id", {}, $tx->{ser_id});
    [200, "OK", [reverse @$actions]];
}

sub _collect_stash {
    my ($self, $res) = @_;
    my $s = $res->[3]{stash};
    return [200] unless ref($s) eq 'HASH';
    $self->{_stash}{$_} = $s->{$_} for keys %$s;
    [200];
}

sub _perform_action {
    my ($self, $which, $action, $opts) = @_;
    my $res;

    my $dbh = $self->{_dbh};
    my $tx  = $self->{_cur_tx};

    my %args = %{$action->[1]};
    $args{-tx_v} = $proto_v;
    $args{-tx_rollback} = 1 if $which eq 'rollback';
    $args{-tx_recovery} = 1 if $self->{_in_recovery};
    $args{-confirm} = 1 if $opts->{confirm};
    my $dd = $action->[5]{deps} // {};
    if ($dd->{tmp_dir}) { # XXX actually need to use dep_satisfy_rel
        $res = $self->get_tmp_dir;
        return err(412, "Can't get tmp dir", $res) unless $res->[0] == 200;
        $args{-tmp_dir} = $res->[2];
    }
    if ($dd->{trash_dir}) { # XXX actually need to use dep_satisfy_rel
        $res = $self->get_trash_dir;
        return err($res, "Can't get trash dir", $res) unless $res->[0] == 200;
        $args{-trash_dir} = $res->[2];
    }
    $args{-stash} = $self->{_stash};

    # call the first time, to get undo actions

    $args{-tx_action} = 'check_state';
    $args{-tx_action_id} = UUID::Random::generate();
    $self->{_res} = $res = $action->[4]->(%args);
    log_trace("$lp check_state args: %s, result: %s", \%args, $res);
    return err(532, "$ep: Check state failed", $res)
        unless $res->[0] == 200 || $res->[0] == 304;
    log_debug($res->[1]) if $res->[0] == 200 && $res->[1];
    my $undo_actions = $res->[3]{undo_actions} // [];
    my $do_actions   = $res->[3]{do_actions};
    $self->_collect_stash($res);

    for ('after_check_state') {
        last unless $_hooks{$_};
        log_trace("$lp hook: $_");
        $_hooks{$_}->($self, which=>$which, action=>$action, res=>$res);
    }

    my $pkg = $action->[0]; $pkg =~ s/::\w+\z//;
    $res = $self->_check_actions($undo_actions, {qualify=>$pkg});
    return $res unless $res->[0] == 200;

    if ($do_actions) {
        $res = $self->_check_actions($do_actions, {qualify=>$pkg});
        return $res unless $res->[0] == 200;
    }

    # record action

    if ($which eq 'action' && !$self->{_in_undo} && !$self->{_in_redo}) {
        my $t = 'do_action';
        $dbh->do("INSERT INTO $t (tx_ser_id,ctime,f,args) ".
                     "VALUES (?,?,?,?)", {},
                 $tx->{ser_id}, time(), $action->[0], $action->[2])
            or return [532, "$ep: db: can't insert $t: ".$dbh->errstr];
        my $action_id = $dbh->last_insert_id("","","","");
        $dbh->do("UPDATE tx SET last_action_id=? WHERE ser_id=?", {},
                 $action_id, $tx->{ser_id})
            or return [532, "$ep: db: can't set last_action_id: ".$dbh->errstr];
        $action->[3] = $action_id;
    }

    # record undo actions. rollback doesn't need to do this, failure in rollback
    # will result in us giving up anyway.

    unless ($which eq 'rollback' || $do_actions) {
        # no BEGIN + COMMIT is needed here, because actions have not been
        # performed. all these undo actions should return 304 anyway if
        # performed during rollback
        my $j = 0;
        for my $ua (@$undo_actions) {
            local $ep = "$ep undo_actions[$j] ($ua->[0])";
            if ($self->{_in_undo}) {
                $dbh->do(
                    "INSERT INTO do_action (tx_ser_id,ctime,f,args) ".
                        "VALUES (?,?,?,?)", {},
                    $tx->{ser_id}, time(), $ua->[0], $ua->[2])
                    or return [532, "$ep: db: can't insert undo_action: ".
                                   $dbh->errstr];
            } else {
                $dbh->do(
                    "INSERT INTO undo_action(tx_ser_id,action_id,ctime,f,args)".
                        "VALUES (?,?,?,?,?)", {},
                    $tx->{ser_id}, $action->[3], time(), $ua->[0], $ua->[2])
                    or return [532, "$ep: db: can't insert do_action: ".
                                   $dbh->errstr];
            }
            $j++;
        }
    }

    # call function "for real" this time

    if ($do_actions && @$do_actions) {

        for ('before_inner_action') {
            last unless $_hooks{$_};
            log_trace("$lp hook: $_");
            $_hooks{$_}->($self, which=>$which, actions=>$do_actions);
        }

        $res = $self->_action($do_actions, $opts);
        return $res unless $res->[0] == 200;

        for ('after_inner_action') {
            last unless $_hooks{$_};
            log_trace("$lp hook: $_");
            $_hooks{$_}->($self, which=>$which,actions=>$do_actions,res=>$res);
        }

    } elsif ($self->{_res}[0] == 200) {
        $args{-tx_action} = 'fix_state';
        $self->{_res} = $res = $action->[4]->(%args);
        log_trace("$lp fix_state args: %s, result: %s", \%args, $res);
        return [532, "$ep: action failed", $res]
            unless $res->[0] == 200 || $res->[0] == 304;
        $self->_collect_stash($res);
    }

    for ('after_fix_state') {
        last unless $_hooks{$_};
        log_trace("$lp hook: $_");
        $_hooks{$_}->($self, which=>$which, action=>$action, res=>$res);
    }

    # update last_action_id so we don't have to repeat all steps
    # after recovery. error can be ignored here, i think.

    unless ($which eq 'action') {
        $dbh->do("UPDATE tx SET last_action_id=? WHERE ser_id=?", {},
                 $action->[3], $tx->{ser_id});
    }

    [200];
}

# rollback, undo, redo, action are all action loops. we combine them here into a
# common routine.
sub _action_loop {
    # $actions is only for which='action'. for rollback/undo/redo, $actions is
    # taken from the database table.
    my ($self, $which, $actions, $opts) = @_;
    $opts //= {};
    $opts->{rollback} //= $_settings{default_rollback_on_action_failure};

    my $res;

    local $self->{_action_nest_level} = ($self->{_action_nest_level}//0) + 1
        if $which eq 'action';

    local $lp = "[tm] [".
        "$which".
            ($self->{_action_nest_level} ? "($self->{_action_nest_level})":"").
                "]";

    return [532, "BUG: 'which' must be rollback/undo/redo/action"]
        unless $which =~ /\A(rollback|undo|redo|action)\z/;

    # this prevent endless loop in rollback, since we call functions when doing
    # rollback, and functions might call $tx->rollback too upon failure.
    return if $self->{_in_rollback} && $which eq 'rollback';
    local $self->{_in_rollback} = 1 if $which eq 'rollback';

    local $self->{_in_undo} = 1 if $which eq 'undo';
    local $self->{_in_redo} = 1 if $which eq 'redo';

    my $tx = $self->{_cur_tx};
    return [532, "called w/o Rinci transaction, probably a bug"] unless $tx;

    my $dbh = $self->{_dbh};
    $self->_rollback_dbh;
    # we're now in sqlite autocommit mode, we use this mode for the following
    # reasons: 1) after we set Rtx status to a/e/v/u/d, we need other clients to
    # immediately see this, so e.g. if Rtx was i, they do not try to add steps
    # to it. also, when performing actions, we want to update+commit after each
    # action.

    # first we need to set the appropriate transaction status first, to prevent
    # other clients from interfering/racing.
    $res = $self->_set_tx_status_before_actions($which);
    return $res unless $res->[0] == 200;

    $self->{_stash} = {};

    # for the main processing, we setup a giant eval loop. any error during
    # processing, we return() from the eval and trigger a rollback (unless we
    # are the rollback process itself, in which case we set tx status to X and
    # give up).
    my $eval_res = eval {
        $actions = $self->_get_actions_from_db($which)->[2] unless $actions;
        log_trace("$lp Actions to perform: %s",
                     [map {[$_->[0], $_->[2] // $_->[1]]} @$actions]);

        # check the actions
        $res = $self->_check_actions($actions);
        return $res unless $res->[0] == 200;

        my $i = 0;
        for my $action (@$actions) {
            $i++;
            local $lp = "$lp [action #$i/".scalar(@$actions)." ($action->[0])]";
            local $ep = "action #$i/".scalar(@$actions)." ($action->[0])";
            $res = $self->_perform_action($which, $action, $opts);
            return $res unless $res->[0] == 200;
        }

        $res = $self->_set_tx_status_after_actions($which);
        return $res unless $res->[0] == 200;

        [200];
    }; # eval
    my $eval_err = $@;

    if ($eval_err || $eval_res->[0] != 200) {
        if ($which eq 'rollback') {
            # if failed during rolling back, we don't know what else to do. we
            # set Rtx status to X (inconsistent) and ignore it.
            $dbh->do("UPDATE tx SET status='X' WHERE ser_id=?",
                     {}, $tx->{ser_id});
            return $eval_err ?
                err(532, "died during rollback: $eval_err") :
                    err(532, "error during rollback", $eval_res);
        } elsif (!$opts->{rollback} || ($self->{_action_nest_level}//0) > 1) {
            # do not rollback nested action or if told not to rollback
            return $eval_err ?
                err(532, "died during nested action (no rollback): $eval_err") :
                err(532, "error during nested action (no rollback)", $eval_res);
        } else {
            my $rbres = $self->_rollback;
            if ($rbres->[0] != 200) {
                $rbres->[3]{prev} = $eval_res;
                return $eval_err ?
                    err(532, $eval_err." (rollback failed)", $rbres) :
                    err(532, "$eval_res->[0] - $eval_res->[1] ".
                            "(rollback failed)", $rbres);
            } else {
                return $eval_err ?
                    err(532, $eval_err." (rolled back)", $eval_res) :
                    err(532, "$eval_res->[0] - $eval_res->[1] (rolled back)",
                        $eval_res);
            }
        }
    }

    if (log_is_trace) {
        my $undo_actions = $self->_get_undo_actions_from_db($which)->[2];
        log_trace("$lp Recorded undo actions: %s",
                     [map {[$_->[0], $_->[2]]} @$undo_actions])
            if $undo_actions;
    }

    [200];
}

sub _cleanup {
    my ($self, $which) = @_;
    log_trace("$lp Performing cleanup ...");

    # there should be only one process running
    my $res = $self->_lock_db(undef);
    return $res unless $res->[0] == 200;

    my $data_dir = $self->{data_dir};
    my $dbh = $self->{_dbh};

    for my $subd (".trash", ".tmp") {
        my $dir = "$data_dir/$subd";
        (-d $dir) or next;
        opendir my($dh), $dir;
        my @dirs = grep {/^\d+$/} readdir($dh);
        closedir $dh;
        my @tx_ids = map {$_->[0]}
            @{ $dbh->selectall_arrayref("SELECT ser_id FROM tx") // []};
        for my $tx_id (@dirs) {
            next if grep { $tx_id eq $_ } @tx_ids;
            log_trace("Deleting %s ...", "$dir/$tx_id");
            remove "$dir/$tx_id";
        }
    }

    $self->discard_all(status=>['R','X']);

    # XXX also discard all C/U Rtxs that are too old

    # XXX also rolls back all i Rtxs that have been going around too for
    # long

    log_trace("$lp Finished cleanup");
    $self->_unlock_db;

    [200];
}

sub _recover {
    my ($self, $which) = @_;

    log_trace("$lp Performing recovery ...");
    local $self->{_in_recovery} = 1;

    # there should be only one process running
    my $res = $self->_lock_db(undef);
    return $res unless $res->[0] == 200;

    my $dbh = $self->{_dbh};
    my $sth;

    # rollback all transactions that need to be rolled back (crashed
    # in-progress, failed undo, failed redo)
    $sth = $dbh->prepare(
        "SELECT * FROM tx WHERE status IN ('a', 'v', 'e') ".
            "OR (status='i' AND last_action_id IS NOT NULL)".
                "ORDER BY ctime DESC",
    );
    $sth->execute or return [532, "db: Can't select tx: ".$dbh->errstr];
    while (my $row = $sth->fetchrow_hashref) {
        $self->{_cur_tx} = $row;
        $self->_rollback;
    }

    # continue interrupted undo
    $sth = $dbh->prepare(
        "SELECT * FROM tx WHERE status IN ('u') ".
                "ORDER BY ctime DESC",
    );
    $sth->execute or return [532, "db: Can't select tx: ".$dbh->errstr];
    while (my $row = $sth->fetchrow_hashref) {
        $self->{_cur_tx} = $row;
        $self->_undo;
    }

    # continue interrupted redo
    $sth = $dbh->prepare(
        "SELECT * FROM tx WHERE status IN ('d') ".
                "ORDER BY ctime ASC",
    );
    $sth->execute or return [532, "db: Can't select tx: ".$dbh->errstr];
    while (my $row = $sth->fetchrow_hashref) {
        $self->{_cur_tx} = $row;
        $self->_redo;
    }

  EXIT_RECOVERY:
    $self->_unlock_db;
    log_trace("$lp Finished recovery");
    [200];
}

sub _resp_incorrect_tx_status {
    my ($self, $r) = @_;

    state $statuses = {
        i => 'still in-progress',
        a => 'aborted, further requests ignored until rolled back',
        v => 'aborted undo, further requests ignored until rolled back',
        e => 'aborted redo, further requests ignored until rolled back',
        C => 'already committed',
        R => 'already rolled back',
        U => 'already committed+undone',
        u => 'undoing',
        d => 'redoing',
        X => 'inconsistent',
    };

    my $s   = $r->{status};
    my $ss  = $statuses->{$s} // "unknown (bug)";
    [480, "tx #$r->{ser_id}: Incorrect status, status is '$s' ($ss)"];
}

# all methods that work inside a transaction have some common code, e.g.
# database file locking, starting sqltx, checking Rtx status, etc. hence
# refactored into _wrap(). arguments:
#
# - label (string, just a label for logging)
#
# - args* (hashref, arguments to method)
#
# - cleanup (bool, default 0). whether to run cleanup first before code. this is
#   curently run by begin() only, to make up room by purging old transactions.
#
# - tx_status (str/array, if set then it means method requires Rtx to exist and
#   have a certain status(es)
#
# - code (coderef, main method code, will be passed args as hash)
#
# - rollback (bool, whether we should do rollback if code does not return
#   success
#
# - hook_check_args (coderef, will be passed args as hash)
#
# - hook_after_commit (coderef, will be passed args as hash).
#
# wrap() will also put current Rtx record to $self->{_cur_tx}
#
# return enveloped result
sub _wrap {
    my ($self, %wargs) = @_;
    my $margs = $wargs{args}
        or return [532, "BUG: args not passed to _wrap()"];
    my @caller = caller(1);

    my $res;

    $res = $self->_lock_db("shared");
    return [532, "Can't acquire lock: $res"] unless $res->[0] == 200;

    $self->{_now} = time();

    # initialize & check tx_id argument
    $margs->{tx_id} //= $self->{_tx_id};
    my $tx_id = $margs->{tx_id};
    $self->{_tx_id} = $tx_id;

    return [400, "Please specify tx_id"]
        unless defined($tx_id) && length($tx_id);
    return [400, "Invalid tx_id, please use 1-200 characters only"]
        unless length($tx_id) <= 200;

    my $dbh = $self->{_dbh};

    if ($wargs{cleanup}) {
        $res = $self->_cleanup;
        return err(532, "Can't succesfully cleanup", $res)
            unless $res->[0] == 200;
    }

    # we need to begin sqltx here so that client's actions like rollback() and
    # commit() are indeed atomic and do not interfere with other clients'.

    $self->_begin_dbh or return [532, "db: Can't begin: ".$dbh->errstr];

    my $cur_tx = $dbh->selectrow_hashref(
        "SELECT * FROM tx WHERE str_id=?", {}, $tx_id);
    $self->{_cur_tx} = $cur_tx;

    if ($wargs{hook_check_args}) {
        $res = $wargs{hook_check_args}->(%$margs);
        do { $self->_rollback; return err(532, "hook_check_args failed", $res) }
            unless $res->[0] == 200;
    }

    if ($wargs{tx_status}) {
        if (!$cur_tx) {
            $self->_rollback_dbh;
            return [484, "No such transaction"];
        }
        my $ok = grep { $cur_tx->{status} eq $_ } @{$wargs{tx_status}};
        unless ($ok) {
            $self->_rollback_dbh;
            return $self->_resp_incorrect_tx_status($cur_tx);
        }
    }

    if ($wargs{code}) {
        $res = $wargs{code}->(%$margs, _tx=>$cur_tx);
        # on error, rollback and skip the rest
        if ($res->[0] >= 400) {
            $self->_rollback if $wargs{rollback} // 1
                && ($res->[3]{rollback} // 1);
            return $res;
        }
    }

    my $res2 = $self->_commit_dbh;
    return $res2 unless $res2->[0] == 200;

    if ($wargs{hook_after_commit}) {
        $res2 = $wargs{hook_after_tx}->(%$margs);
        return err(532, "hook_after_tx failed", $res2) unless $res2->[0] == 200;
    }

    $res;
}

# all methods that don't work inside a transaction have some common code, e.g.
# database file locking. arguments:
#
# - args* (hashref, arguments to method)
#
# - lock_db (bool, default false)
#
# - code* (coderef, main method code, will be passed args as hash)
#
# return enveloped result
sub _wrap2 {
    my ($self, %wargs) = @_;
    my $margs = $wargs{args}
        or return [532, "BUG: args not passed to _wrap()"];
    my @caller = caller(1);

    my $res;

    if ($wargs{lock_db}) {
        $res = $self->_lock_db("shared");
        return err(532, "Can't acquire lock", $res) unless $res->[0] == 200;
    }

    $res = $wargs{code}->(%$margs);

    if ($wargs{lock_db}) {
        $self->_unlock_db;
    }

    $res;
}

sub begin {
    my ($self, %args) = @_;
    $self->_wrap(
        args => \%args,
        cleanup => 1,
        code => sub {
            my $dbh = $self->{_dbh};
            my $r = $dbh->selectrow_hashref("SELECT * FROM tx WHERE str_id=?",
                                            {}, $args{tx_id});
            return [409, "Another transaction with that ID exists", undef,
                    {rollback=>0}] if $r;

            # XXX check for limits

            $dbh->do("INSERT INTO tx (str_id, owner_id, summary, status, ".
                         "ctime) VALUES (?,?,?,?,?)", {},
                     $args{tx_id}, $args{client_token}//"", $args{summary}, "i",
                     $self->{_now})
                or return [532, "db: Can't insert tx: ".$dbh->errstr];

            $self->{_tx_id} =  $args{tx_id};
            $self->{_cur_tx} = $dbh->selectrow_hashref(
                "SELECT * FROM tx WHERE str_id=?", {}, $args{tx_id})
                or return [532, "db: Can't select tx: ".$dbh->errstr];
            [200];
        },
    );
}

sub _action {
    my ($self, $actions, $opts) = @_;
    $self->_action_loop('action', $actions, $opts);
}

# old name, for backward compatibility
sub _call { my $self =shift; $self->_action(@_) }
sub call  { my $self =shift; $self->action(@_)  }

sub action {
    my ($self, %args) = @_;

    my ($f, $args, $actions);
    $actions = $args{actions} // [[$args{f}, $args{args}]];
    return [304, "No actions to do"] unless @$actions;

    $self->_wrap(
        args => \%args,
        # we allow calling action() during rollback, since a function can call
        # other function using action(), but we don't actually bother to save
        # the undo actions.
        tx_status => ["i", "d", "u", "a", "v", "e"],
        rollback => 0, # _action_loop already does rollback
        code => sub {
            my $cur_tx = $self->{_cur_tx};
            if ($cur_tx->{status} ne 'i' && !$self->{_in_rollback}) {
                return $self->_resp_incorrect_tx_status($cur_tx);
            }

            delete $self->{_res};
            my $res = $self->_action($actions, {confirm=>$args{confirm}});
            if ($res->[0] != 200 && $res->[0] != 304) {
                if ($self->{_res} && $self->{_res}[0] !~ /200|304/) {
                    return [$self->{_res}[0],
                            $self->{_res}[1],
                            undef,
                            {tx_result=>$res, prev=>$res}];
                } else {
                    return err(532, {prev=>$res});
                }
            } else {
                return [$self->{_res}[0],
                        $self->{_res}[1],
                        $self->{_stash}{result},
                        { %{ $self->{_stash}{result_meta} // {} },
                          %{ $res->[3] // {}} }];
            }
        },
    );
}

sub commit {
    my ($self, %args) = @_;
    $self->_wrap(
        args => \%args,
        tx_status => ["i", "a"],
        code => sub {
            my $dbh = $self->{_dbh};
            my $tx  = $self->{_cur_tx};
            if ($tx->{status} eq 'a') {
                my $res = $self->_rollback;
                return $res unless $res->[0] == 200;
                return [200, "Rolled back"];
            }
            $dbh->do(
                "DELETE FROM do_action WHERE tx_ser_id=?",{},$tx->{ser_id});
            $dbh->do("UPDATE tx SET status=?, commit_time=? WHERE ser_id=?",
                     {}, "C", $self->{_now}, $tx->{ser_id})
                or return [532, "db: Can't update tx status to committed: ".
                               $dbh->errstr];
            [200];
        },
    );
}

sub _rollback {
    my ($self) = @_;
    my $dbh = $self->{_dbh};
    my $tx  = $self->{_cur_tx};

    my $res = $self->_action_loop('rollback');
    return $res unless $res->[0] == 200;
    $dbh->do("DELETE FROM do_action   WHERE tx_ser_id=?", {}, $tx->{ser_id});
    $dbh->do("DELETE FROM undo_action WHERE tx_ser_id=?", {}, $tx->{ser_id});
    [200];
}

sub _undo {
    my ($self, $opts) = @_;
    my $dbh = $self->{_dbh};
    my $tx  = $self->{_cur_tx};

    my $res = $self->_action_loop('undo', undef, $opts);
    return $res unless $res->[0] == 200;
    $dbh->do("DELETE FROM undo_action WHERE tx_ser_id=?", {}, $tx->{ser_id});
    [200];
}

sub _redo {
    my ($self, $opts) = @_;
    my $dbh = $self->{_dbh};
    my $tx  = $self->{_cur_tx};

    my $res = $self->_action_loop('redo', undef, $opts);
    return $res unless $res->[0] == 200;
    $dbh->do("DELETE FROM do_action WHERE tx_ser_id=?", {}, $tx->{ser_id});
    [200];
}

sub rollback {
    my ($self, %args) = @_;
    $self->_wrap(
        args => \%args,
        tx_status => ["i", "a"],
        rollback => 0, # _action_loop already does rollback
        code => sub {
            $self->_rollback;
        },
    );
}

sub prepare {
    [501, "Not implemented"];
}

sub savepoint {
    [501, "Not yet implemented"];
}

sub release_savepoint {
    [501, "Not yet implemented"];
}

sub list {
    my ($self, %args) = @_;
    $self->_wrap2(
        args => \%args,
        code => sub {
            my $dbh = $self->{_dbh};
            my @wheres = ("1");
            my @params;
            if ($args{tx_id}) {
                push @wheres, "str_id=?";
                push @params, $args{tx_id};
            }
            if ($args{tx_status}) {
                push @wheres, "status=?";
                push @params, $args{tx_status};
            }
            my $sth = $dbh->prepare(
                "SELECT * FROM tx WHERE ".join(" AND ", @wheres).
                    " ORDER BY ctime, ser_id");
            $sth->execute(@params);
            my @res;
            while (my $row = $sth->fetchrow_hashref) {
                if ($args{detail}) {
                    push @res, {
                        tx_id         => $row->{str_id},
                        tx_status     => $row->{status},
                        tx_start_time => $row->{ctime},
                        tx_commit_time=> $row->{commit_time},
                        tx_summary    => $row->{summary},
                    };
                } else {
                    push @res, $row->{str_id};
                }
            }
            [200, "OK", \@res];
        },
    );
}

sub undo {
    my ($self, %args) = @_;

    # find latest committed tx
    unless ($args{tx_id}) {
        my $dbh = $self->{_dbh};
        my @row = $dbh->selectrow_array(
            "SELECT str_id FROM tx WHERE status='C' ".
                "ORDER BY commit_time DESC, ser_id DESC LIMIT 1");
        return [412, "There are no committed transactions to undo"] unless @row;
        $args{tx_id} = $row[0];
    }

    $self->_wrap(
        args => \%args,
        tx_status => ["C"],
        rollback => 0, # _action_loop already does rollback
        code => sub {
            delete $self->{_res};
            my $res = $self->_undo({confirm=>$args{confirm}});
            if ($res->[0] != 200 && $res->[0] != 304) {
                if ($self->{_res} && $self->{_res}[0] !~ /200|304/) {
                    return [$self->{_res}[0],
                            $self->{_res}[1],
                            undef,
                            {tx_result=>$res, prev=>$res}];
                } else {
                    return err(532, {prev=>$res});
                }
            } else {
                return [200];
            }
        },
    );
}

sub redo {
    my ($self, %args) = @_;

    # find first undone committed tx
    unless ($args{tx_id}) {
        my $dbh = $self->{_dbh};
        my @row = $dbh->selectrow_array(
            "SELECT str_id FROM tx WHERE status='U' ".
                "ORDER BY commit_time ASC, ser_id ASC LIMIT 1");
        return [412, "There are no undone transactions to redo"] unless @row;
        $args{tx_id} = $row[0];
    }

    $self->_wrap(
        args => \%args,
        tx_status => ["U"],
        rollback => 0, # _action_loop already does rollback
        code => sub {
            delete $self->{_res};
            my $res = $self->_redo({confirm=>$args{confirm}});
            if ($res->[0] != 200 && $res->[0] != 304) {
                if ($self->{_res} && $self->{_res}[0] !~ /200|304/) {
                    return [$self->{_res}[0],
                            $self->{_res}[1],
                            undef,
                            {tx_result=>$res, prev=>$res}];
                } else {
                    return err(532, {prev=>$res});
                }
            } else {
                return [200];
            }
        },
    );
}

sub _discard {
    my ($self, $which, %args) = @_;
    my $wmeth = $which eq 'one' ? '_wrap' : '_wrap2';
    $self->$wmeth(
        label => $which,
        args => \%args,
        tx_status => $which eq 'one' ? ['C','U','R','X'] : undef,
        code => sub {
            my $dbh = $self->{_dbh};
            my $sth;
            if ($which eq 'one') {
                $sth = $dbh->prepare("SELECT ser_id FROM tx WHERE str_id=?");
                $sth->execute($self->{_cur_tx}{str_id});
            } else {
                my $txs = "'C','U','R','X'";
                if ($args{status}) {
                    $txs = join(",",map{"'$_'"}
                                    grep {/\A[CURX]\z/} @{$args{status}});
                }
                $sth = $dbh->prepare(
                    "SELECT ser_id FROM tx WHERE status IN ($txs)");
                $sth->execute;
            }
            my @txs;
            while (my @row = $sth->fetchrow_array) {
                push @txs, $row[0];
            }
            if (@txs) {
                my $txs = join(",", @txs);
                $dbh->do("DELETE FROM tx WHERE ser_id IN ($txs)")
                    or return [532, "db: Can't delete tx: ".$dbh->errstr];
                $dbh->do("DELETE FROM do_action WHERE tx_ser_id IN ($txs)");
                log_info("$lp discard tx: %s", \@txs);
            }
            [200];
        },
    );
}

sub discard {
    my $self = shift;
    $self->_discard('one', @_);
}

sub discard_all {
    my $self = shift;
    $self->_discard('all', @_);
}

1;
# ABSTRACT: A Rinci transaction manager

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Tx::Manager - A Rinci transaction manager

=head1 VERSION

This document describes version 0.580 of Perinci::Tx::Manager (from Perl distribution Perinci-Tx-Manager), released on 2023-11-17.

=head1 SYNOPSIS

 # used by Perinci::Access::Schemeless

=head1 DESCRIPTION

This class implements transaction and undo manager (TM), as specified by
L<Rinci::Transaction> and L<Riap::Transaction>. It is meant to be instantiated
by L<Perinci::Access::Schemeless>, but will also be passed to transactional
functions to save undo/redo data.

It uses SQLite database to store transaction list and undo/redo data as well as
transaction data directory to provide trash_dir/tmp_dir for functions that
require it.

=for Pod::Coverage ^(call|get_func_and_meta)$

=head1 ATTRIBUTES

=head2 _tx_id

This is just a convenience so that methods that require tx_id will get the
default value from here if tx_id not specified in arguments.

=head1 METHODS

=head2 new(%args) => OBJ

Create new object. Arguments:

=over 4

=item * pa => OBJ

Perinci::Access::Schemeless object. This is required by Perinci::Tx::Manager to
load/get functions when it wants to perform undo/redo/recovery.
Perinci::Access::Schemeless conveniently require() the Perl modules and wraps
the functions.

=item * data_dir => STR (default C<~/.perinci/.tx>)

=item * max_txs => INT (default 1000)

Limit maximum number of transactions maintained by the TM, including all rolled
back and committed transactions, since they are still recorded in the database.
The default is 1000.

Not yet implemented.

After this limit is reached, cleanup will be performed to delete rolled back
transactions, and after that committed transactions.

=item * max_open_txs => INT (default 100)

Limit maximum number of open (in progress, aborted, prepared) transactions. This
exclude resolved transactions (rolled back and committed). The default is no
limit.

Not yet implemented.

After this limit is reached, starting a new transaction will fail.

=item * max_committed_txs => INT (default 100)

Limit maximum number of committed transactions that is recorded by the database.
This is equal to the number of undo steps that are remembered.

After this limit is reached, cleanup will automatically be performed so that
the oldest committed transactions are purged.

Not yet implemented.

=item * max_open_age => INT

Limit the maximum age of open transactions (in seconds). If this limit is
reached, in progress transactions will automatically be purged because it times
out.

Not yet implemented.

=item * max_committed_age => INT

Limit the maximum age of committed transactions (in seconds). If this limit is
reached, the old transactions will start to be purged.

Not yet implemented.

=back

=head2 $tx->get_trash_dir => RESP

=head2 $tx->get_tmp_dir => RESP

=head2 $tm->begin(%args) => RESP

Start a new transaction.

Arguments: tx_id (str, required, unless already supplied via _tx_id()), twopc
(bool, optional, currently must be false since distributed transaction is not
yet supported), summary (optional).

TM will create an entry for this transaction in its database.

=head2 $tm->action(%args) => RESP

Perform action for the transaction by calling one or more functions.

Arguments: C<f> (fully-qualified function name), C<args> (arguments to function,
hashref). Or, C<actions> (list of function calls, array, C<[[f1, args1], ...]>,
alternative to specifying C<f> and C<args>), C<confirm> (bool, if set to true
then will pass C<< -confirm => 1 >> special argument to functions; see status
code 331 in L<Rinci::function> for more details on this).

TM will also pass the following special arguments: C<< -tx_v => PROTO_VERSION
>>, C<< -tx_rollback => 1 >> during rollback, and C<< -tx_recovery => 1 >>
during recovery, for informative purposes.

To perform a single action, specify C<f> and C<args>. To perform several
actions, supply C<actions>.

Note: special arguments (those started with dash, C<->) will be stripped from
function arguments by TM.

If response from function is not success, rollback() will be called.

Tip: To call in dry-run mode to function supporting dry-run mode, or to call a
pure function, you do not have to use TM's action() but rather call the function
directly, since this will not have any side effects.

Tip: During C<fix_state>, function can return C<stash> in result metadata which
can be set to hash. This will be collected and passed by TM in C<-stash> special
argument. This is useful in multiple actions where one action might need to
check result from previous action.

=head2 $tx->commit(%args) => RESP

Commit a transaction.

Arguments: C<tx_id>

=head2 $tx->rollback(%args) => RESP

Rollback a transaction.

Arguments: C<tx_id>, C<sp_id> (optional, savepoint name to rollback to a
specific savepoint only).

Currently rolling back to a savepoint is not implemented.

=head2 $tx->prepare(%args) => RESP

Prepare a transaction.

Arguments: C<tx_id>

Currently will return 501 (not implemented). Rinci::Transaction does not yet
support distributed transaction.

=head2 $tx->savepoint(%args) => RESP

Declare a savepoint.

Arguments: C<tx_id>, C<sp_id> (savepoint name).

Currently not implemented.

=head2 $tx->release_savepoint(%args) => RESP

Release (forget) a savepoint.

Arguments: C<tx_id>, C<sp_id> (savepoint name).

Currently not implemented.

=head2 $tx->undo(%args) => RESP

Undo a committed transaction.

Arguments: C<tx_id>, C<confirm> (bool, if set to true then will pass C<<
-confirm => 1 >> special argument to functions; see status code 331
in L<Rinci::function> for more details on this).

=head2 $tx->redo(%args) => RESP

Redo an undone committed transaction.

Arguments: C<tx_id>, C<confirm> (bool, if set to true then will pass C<<
-confirm => 1 >> special argument to functions; see status code 331
in L<Rinci::function> for more details on this).

=head2 $tx->list(%args) => RESP

List transactions.

Arguments: B<detail> (bool, default 0, whether to return transaction records
instead of just a list of transaction ID's).

Return an array of results sorted by creation date (in ascending order).

=head2 $tx->discard(%args) => RESP

Discard (forget) a client's committed transaction.

Arguments: C<tx_id>

Transactions that can be discarded are committed, undone committed, or
inconsistent ones (i.e., those with final statuses C<C>, C<U>, C<X>).

=head2 $tm->discard_all(%args) => RESP

Discard (forget) all committed transactions.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Tx-Manager>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Tx-Manager>.

=head1 SEE ALSO

L<Rinci::Transaction>

L<Perinci::Access::Schemeless>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Tx-Manager>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
