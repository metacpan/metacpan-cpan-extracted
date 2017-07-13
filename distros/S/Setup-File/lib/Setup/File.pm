package Setup::File;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.23'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Trash::Undoable;
use File::MoreUtil qw(dir_empty);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(setup_file);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Setup file (existence, mode, permission, content)',
};

$SPEC{rmdir} = {
    v           => 1.1,
    summary     => 'Delete directory',
    description => <<'_',

Fixed state: `path` doesn't exist.

Fixable state: `path` exists and is a directory (or, a symlink to a directory,
if `allow_symlink` option is enabled).

Unfixable state: `path` exists but is not a directory.

_
    args        => {
        path => {
            schema => 'str*',
            req    => 1,
            pos    => 0,
        },
        allow_symlink => {
            schema => [bool => {default => 0}],
            summary => 'Whether to regard symlink to a directory as directory',
        },
        delete_nonempty_dir => {
            schema => [bool => {}],
            summary => 'Whether to delete non-empty directory',
            description => <<'_',

If set to true, will delete non-empty directory.

If set to false, will never delete non-empty directory.

If unset (default), will ask for confirmation first by returning status 331.
Caller can confirm by passing special argument `-confirm`.

_
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub rmdir {
    my %args = @_;

    # TMP, schema
    my $tx_action = $args{-tx_action} // '';
    my $taid      = $args{-tx_action_id}
        or return [412, "Please specify -tx_action_id"];
    my $dry_run   = $args{-dry_run};
    my $path      = $args{path};
    defined($path) or return [400, "Please specify path"];
    my $allow_sym = $args{allow_symlink} // 0;

    my $is_sym    = (-l $path);
    my $exists    = $is_sym || (-e _);
    my $is_dir    = (-d _);
    my $is_sym_to_dir = $is_sym && (-d $path);
    my $empty     = $exists && dir_empty($path);

    my @undo;

    #$log->tracef("path=%s, exists=%s, is_dir=%s, allow_sym=%s, is_sym_to_dir=%s", $path, $exists, $is_dir, $allow_sym, $is_sym_to_dir);
    if ($tx_action eq 'check_state') {
        return [412, "Not a dir"] if $exists &&
            !($is_dir || $allow_sym && $is_sym_to_dir);
        if ($exists) {
            if (!$empty) {
                my $d = $args{delete_nonempty_dir};
                if (defined($d) && !$d) {
                    return [412, "Dir $path is not empty, but instructed ".
                                "never to remove non-empty dir"];
                } elsif (!defined($d)) {
                    if (!$args{-confirm}) {
                        return [331, "Dir $path not empty, confirm delete?"];
                    }
                }
            }
            log_info("(DRY) Removing dir $path ...") if $dry_run;
            unshift @undo, (
                ['File::Trash::Undoable::untrash' =>
                     {path=>$path, suffix=>substr($taid,0,8)}],
            );
        }
        if (@undo) {
            return [200, "Dir $path needs to be removed", undef,
                    {undo_actions=>\@undo}];
        } else {
            return [304, "Dir $path already does not exist"];
        }
    } elsif ($tx_action eq 'fix_state') {
        return File::Trash::Undoable::trash(
            -tx_action=>'fix_state', suffix=>substr($taid,0,8), path=>$path);
    }
    [400, "Invalid -tx_action"];
}

$SPEC{mkdir} = {
    v           => 1.1,
    summary     => 'Create directory',
    description => <<'_',

Fixed state: `path` exists and is a directory.

Fixable state: `path` doesn't exist.

Unfixable state: `path` exists and is not a directory.

_
    args        => {
        path => {
            summary => 'Path to directory',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        allow_symlink => {
            summary => 'Whether to regard symlink to a directory as directory',
            schema => 'str*',
        },
        mode => {
            summary => 'Set mode for the newly created directory',
            schema => 'str*',
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub mkdir {
    my %args = @_;

    # TMP, schema
    my $tx_action = $args{-tx_action} // '';
    my $dry_run   = $args{-dry_run};
    my $path      = $args{path};
    defined($path) or return [400, "Please specify path"];
    my $allow_sym = $args{allow_symlink} // 0;
    my $mode      = $args{mode} // 0755; # XXX use umask
    return [412, "Invalid mode '$mode', please use numeric only"]
        if $mode =~ /\D/;

    my $is_sym    = (-l $path);
    my $exists    = $is_sym || (-e _);
    my $is_dir    = (-d _);
    my $is_sym_to_dir = $is_sym && (-d $path);

    if ($tx_action eq 'check_state') {
        my @undo;
        return [412, "$path is not a dir"] if $exists &&
            !($is_dir || $allow_sym && $is_sym_to_dir);
        if (!$exists) {
            unshift @undo, [rmdir => {path => $path}];
        }
        if (@undo) {
            log_info("(DRY) Creating dir $path ...") if $dry_run;
            return [200, "Dir $path needs to be created", undef,
                    {undo_actions=>\@undo}];
        } else {
            return [304, "Dir $path already exists"];
        }
    } elsif ($tx_action eq 'fix_state') {
        log_info("Creating dir $path ...");
        if (CORE::mkdir($path, $mode)) {
            return [200, "Fixed"];
        } else {
            return [500, "Can't mkdir $path: $!"];
        }
    }
    [400, "Invalid -tx_action"];
}

$SPEC{chmod} = {
    v           => 1.1,
    summary     => "Set file's permission mode",
    description => <<'_',

Fixed state: `path` exists and mode is already correct.

Fixable state: `path` exists but mode is not correct.

Unfixable state: `path` doesn't exist.

_
    args        => {
        path => {
            summary => 'Path to file/directory',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        mode => {
            summary => 'Permission mode, either numeric or symbolic (e.g. a+w)',
            schema  => 'str*',
            req     => 1,
            pos     => 1,
        },
        follow_symlink => {
            summary => 'Whether to follow symlink',
            schema => [bool => {default=>0}],
        },
        orig_mode => {
            summary=>'If set, confirm if current mode is not the same as this',
            schema => 'int',
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub chmod {
    require File::chmod;

    my %args = @_;

    local $File::chmod::UMASK = 0;

    # TMP, schema
    my $tx_action  = $args{-tx_action} // '';
    my $dry_run    = $args{-dry_run};
    my $path       = $args{path};
    defined($path) or return [400, "Please specify path"];
    my $follow_sym = $args{follow_symlink} // 0;
    my $orig_mode  = $args{orig_mode};
    my $want_mode  = $args{mode};
    defined($want_mode) or return [400, "Please specify mode"];

    my $is_sym    = (-l $path);
    return [412, "$path is a symlink"] if !$follow_sym && $is_sym;
    my $exists    = $is_sym || (-e _);
    my @st        = stat($path);
    my $cur_mode  = $st[2] & 07777 if $exists;
    if (!$args{-tx_recovery} && defined($orig_mode) && defined($cur_mode) &&
            $cur_mode != $orig_mode && !$args{-confirm}) {
        return [331, "File $path has changed permission mode, confirm chmod?"];
    }
    if ($want_mode =~ /\D/) {
        return [412, "Symbolic mode ($want_mode) requires path $path to exist"]
            unless $exists;
        $want_mode = File::chmod::getchmod($want_mode, $path);
    }

    #$log->tracef("path=%s, cur_mode=%04o, want_mode=%04o", $path, $cur_mode, $want_mode);
    if ($tx_action eq 'check_state') {
        my @undo;
        return [412, "Path $path doesn't exist"] if !$exists;
        if ($cur_mode != $want_mode) {
            log_info("(DRY) chmod %s to %04o ...", $path, $want_mode)
                if $dry_run;
            unshift @undo, [chmod => {
                path => $path, mode=>$cur_mode, orig_mode=>$want_mode,
                follow_symlink => $follow_sym,
            }];
        }
        if (@undo) {
            log_info("(DRY) Chmod %s to %04o ...", $path, $want_mode)
                if $dry_run;
            return [200, "Path $path needs to be chmod'ed to ".
                        sprintf("%04o", $want_mode), undef,
                    {undo_actions=>\@undo}];
        } else {
            return [304, "Fixed, mode already ".sprintf("%04o", $cur_mode)];
        }
    } elsif ($tx_action eq 'fix_state') {
        log_info("Chmod %s to %04o ...", $path, $want_mode);
        if (CORE::chmod($want_mode, $path)) {
            return [200, "Fixed"];
        } else {
            return [500, "Can't chmod $path, $want_mode: $!"];
        }
    }
    [400, "Invalid -tx_action"];
}

$SPEC{chown} = {
    v           => 1.1,
    summary     => "Set file's ownership",
    description => <<'_',

Fixed state: `path` exists and ownership is already correct.

Fixable state: `path` exists but ownership is not correct.

Unfixable state: `path` doesn't exist.

_
    args        => {
        path => {
            summary => 'Path to file/directory',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        owner => {
            summary => 'Numeric UID or username',
            schema  => 'str*',
        },
        group => {
            summary => 'Numeric GID or group',
            schema  => 'str*',
        },
        follow_symlink => {
            summary => 'Whether to follow symlink',
            schema => [bool => {default=>0}],
        },
        orig_owner => {
            summary=>'If set, confirm if current owner is not the same as this',
            schema => 'str',
        },
        orig_group => {
            summary=>'If set, confirm if current group is not the same as this',
            schema => 'str',
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub chown {
    require Lchown;
    return [412, "lchown() is not available on this system"] unless
        Lchown::LCHOWN_AVAILABLE();

    my %args = @_;

    # TMP, schema
    my $tx_action  = $args{-tx_action} // '';
    my $dry_run    = $args{-dry_run};
    my $path       = $args{path};
    defined($path) or return [400, "Please specify path"];
    my $follow_sym = $args{follow_symlink} // 0;
    my $orig_owner = $args{orig_owner};
    my $orig_group = $args{orig_group};
    my $want_owner = $args{owner};
    my $want_group = $args{group};
    defined($want_owner) || defined($want_group)
        or return [400, "Please specify at least either owner/group"];

    my ($orig_uid, $orig_uname);
    if (defined $orig_owner) {
        if ($orig_owner =~ /\A\d+\z/) {
            $orig_uid = $orig_owner;
            my @ent = getpwuid($orig_uid);
            $orig_uname = $ent[0] if @ent;
        } else {
            $orig_uname = $orig_owner;
            my @ent = getpwnam($orig_uname);
            return [412, "User doesn't exist: $orig_uname"] unless @ent;
            $orig_uid = $ent[2];
        }
    }

    my ($want_uid, $want_uname);
    if (defined $want_owner) {
        if ($want_owner =~ /\A\d+\z/) {
            $want_uid = $want_owner;
            my @ent = getpwuid($want_uid);
            $want_uname = $ent[0] if @ent;
        } else {
            $want_uname = $want_owner;
            my @ent = getpwnam($want_uname);
            return [412, "User doesn't exist: $want_uname"] unless @ent;
            $want_uid = $ent[2];
        }
    }

    my ($orig_gid, $orig_gname);
    if (defined $orig_group) {
        if ($orig_group =~ /\A\d+\z/) {
            $orig_gid = $orig_group;
            my @grent = getgrgid($orig_gid);
            $orig_gname = $grent[0] if @grent;
        } else {
            $orig_gname = $orig_group;
            my @grent = getgrnam($orig_gname);
            return [412, "Group doesn't exist: $orig_gname"] unless @grent;
            $orig_gid = $grent[2];
        }
    }

    my ($want_gid, $want_gname);
    if (defined $want_group) {
        if ($want_group =~ /\A\d+\z/) {
            $want_gid = $want_group;
            my @grent = getgrgid($want_gid);
            $want_gname = $grent[0] if @grent;
        } else {
            $want_gname = $want_group;
            my @grent = getgrnam($want_gname);
            return [412, "Group doesn't exist: $want_gname"] unless @grent;
            $want_gid = $grent[2];
        }
    }

    my @st        = lstat($path);
    my $is_sym    = (-l _);
    my $exists    = $is_sym || (-e _);
    if ($follow_sym && $exists) {
        @st = stat($path);
        return [500, "Can't stat $path (2): $!"] unless @st;
    }
    my $cur_uid   = $st[4];
    my $cur_gid   = $st[5];
    if (!$args{-tx_recovery} && !$args{-confirm}) {
        my $changed = defined($orig_uid) && $orig_uid != $cur_uid ||
            defined($orig_gid) && $orig_gid != $cur_gid;
        return [331, "File $path has changed ownership, confirm chown?"]
            if $changed;
    }

    #$log->tracef("path=%s, cur_uid=%s, cur_gid=%s, want_uid=%s, want_uname=%s, want_gid=%s, want_gname=%s", $cur_uid, $cur_gid, $want_uid, $want_uname, $want_gid, $want_gname);
    if ($tx_action eq 'check_state') {
        my @undo;
        return [412, "$path doesn't exist"] if !$exists;
        if (defined($want_uid) && $cur_uid != $want_uid ||
                defined($want_gid) && $cur_gid != $want_gid) {
            log_info("(DRY) Chown %s to (%s, %s)",
                        $path, $want_owner, $want_group) if $dry_run;
            unshift @undo, [chown => {
                path  => $path,
                owner => (defined($want_uid) &&
                              $cur_uid != $want_uid ? $cur_uid : undef),
                group => (defined($want_gid) &&
                              $cur_gid != $want_gid ? $cur_gid : undef),
                orig_owner => $want_owner, orig_group => $want_group,
                follow_symlink => $follow_sym,
            }];
        }
        if (@undo) {
            return [200, "Path $path needs to be chown'ed to ".
                        "(".($want_owner // "-").", ".($want_group // "-").")",
                    undef, {undo_actions=>\@undo}];
        } else {
            return [304, "Path $path already has correct owner and group"];
        }
    } elsif ($tx_action eq 'fix_state') {
        my $res;
        log_info("%schown %path to (%s, %s) ...", $follow_sym ? "" : "l",
                    $path, $want_uid // -1, $want_gid // -1);
        if ($follow_sym) {
            $res = CORE::chown   ($want_uid // -1, $want_gid // -1, $path);
        } else {
            $res = Lchown::lchown($want_uid // -1, $want_gid // -1, $path);
        }
        if ($res) {
            return [200, "Fixed"];
        } else {
            return [500, "Can't chown $path, ".($want_uid // -1).", ".
                        ($want_gid // -1).": $!"];
        }
    }
    [400, "Invalid -tx_action"];
}

$SPEC{rmfile} = {
    v           => 1.1,
    summary     => 'Delete file',
    description => <<'_',

Fixed state: `path` doesn't exist.

Fixable state: `path` exists and is a file (or, a symlink to a file, if
`allow_symlink` option is enabled).

Unfixable state: `path` exists but is not a file.

_
    args        => {
        path => {
            schema => 'str*',
            req    => 1,
            pos    => 0,
        },
        allow_symlink => {
            schema => [bool => {default => 0}],
            summary => 'Whether to regard symlink to a file as file',
        },
        orig_content => {
            summary =>
                'If set, confirm if current content is not the same as this',
            description => <<'_',

Alternatively, you can use `orig_content_hash`.

_
            schema => 'str',
        },
        orig_content_md5 => {
            summary =>
                'If set, confirm if current content MD5 hash '.
                    'is not the same as this',
            description => <<'_',

MD5 hash should be expressed in hex (e.g. bed6626e019e5870ef01736b3553e570).

Alternatively, you can use `orig_content` (for shorter content).

_
            schema => 'str',
        },
        suffix => {
            summary => 'Use this suffix when trashing',
            schema => 'str',
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub rmfile {
    my %args = @_;

    # TMP, schema
    my $tx_action = $args{-tx_action} // '';
    my $taid      = $args{-tx_action_id}
        or return [400, "Please specify -tx_action_id"];
    my $dry_run   = $args{-dry_run};
    my $path      = $args{path};
    defined($path) or return [400, "Please specify path"];
    my $allow_sym = $args{allow_symlink} // 0;
    my $suffix    = $args{suffix} // substr($taid,0,8);

    my $is_sym    = (-l $path);
    my $exists    = $is_sym || (-e _);
    my $is_file   = (-f _);
    my $is_sym_to_file = $is_sym && (-f $path);

    my @undo;

    #$log->tracef("path=%s, exists=%s, is_file=%s, allow_sym=%s, is_sym_to_file=%s", $path, $exists, $is_file, $allow_sym, $is_sym_to_file);
    if ($tx_action eq 'check_state') {
        return [412, "Path $path is not a file"] if $exists &&
            !($is_file || $allow_sym && $is_sym_to_file);
        if ($exists) {
            if (!$args{-confirm} && (defined($args{orig_content}) ||
                                         defined($args{orig_content_md5}))) {
                if (defined $args{orig_content}) {
                    require File::Slurper;
                    my $ct = eval { File::Slurper::read_text($path) };
                    return [500, "Can't read file $path: $!"]
                        unless defined($ct);
                    return [331, "File $path has changed content, confirm ".
                                "delete?"] if $ct ne $args{orig_content};
                }
                if (defined $args{orig_content_md5}) {
                    require Digest::MD5;
                    return [500, "Can't open file $path: $!"]
                        unless open my($fh), "<", $path;
                    my $ctx = Digest::MD5->new;
                    $ctx->addfile($fh);
                    return [331, "File $path has changed content, confirm ".
                                "delete?"]
                        if $ctx->hexdigest ne $args{orig_content_md5};
                }
            }
            log_info("(DRY) Removing file $path ...") if $dry_run;
            unshift @undo, (
                ['File::Trash::Undoable::untrash' =>
                     {path=>$path, suffix=>$suffix}],
            );
        }
        if (@undo) {
            return [200, "File $path needs to be removed",
                    undef, {undo_actions=>\@undo}];
        } else {
            return [304, "File $path already does not exist"];
        }
    } elsif ($tx_action eq 'fix_state') {
        return File::Trash::Undoable::trash(
            -tx_action=>'fix_state', suffix=>$suffix, path=>$path);
    }
    [400, "Invalid -tx_action"];
}

$SPEC{mkfile} = {
    v           => 1.1,
    summary     => 'Create file (and/or set content)',
    description => <<'_',

Fixed state: `path` exists, is a file, and content is correct.

Fixable state: `path` doesn't exist. Or `path` exists, is a file, and content is
incorrect. Or `orig_path` specified and exists.

Unfixable state: `path` exists and is not a file.

_
    args        => {
        path => {
            summary => 'Path to file',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        allow_symlink => {
            summary => 'Whether to regard symlink to a file as file',
            schema => 'str*',
        },
        content => {
            schema  => 'str',
            summary => 'Desired file content',
            description => <<'_',

Alternatively you can also use `content_md5`, or `gen_content_func` and
`check_content_func`.

_
        },
        content_md5 => {
            schema  => 'str',
            summary => 'Check content against MD5 hash',
            description => <<'_',

MD5 hash should be expressed in hex (e.g. bed6626e019e5870ef01736b3553e570).

Used when checking content of existing file.

Alternatively you can also use `content`, or `check_content_func`.

_
        },
        check_content_func => {
            schema  => 'str',
            summary => 'Name of function to check content',
            description => <<'_',

If unset, file will not be checked for its content. If set, function will be
called whenever file content needs to be checked. Function will be passed the
reference to file content and should return a boolean value indicating whether
content is acceptable. If it returns a false value, content is deemed
unacceptable and needs to be fixed.

Alternatively you can use the simpler `content` or `content_md5` argument.

_
        },
        gen_content_func => {
            schema  => 'str',
            summary => 'Name of function to generate content',
            description => <<'_',

If set, whenever a new file content is needed (e.g. when file is created or file
content reset), this function will be called to provide it. If unset, empty
string will be used instead.

Function will be passed the reference to the current content (or undef) and
should return the new content.

Alternatively you can use the simpler `content` argument.

_
        },
        suffix => {
            schema => 'str',
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub mkfile {
    require Digest::MD5;
    require File::Slurper;

    my %args = @_;

    # TMP, schema
    my $tx_action = $args{-tx_action} // '';
    my $taid      = $args{-tx_action_id}
        or return [400, "Please specify -tx_action_id"];
    my $dry_run   = $args{-dry_run};
    my $path      = $args{path};
    defined($path) or return [400, "Please specify path"];
    my $allow_sym = $args{allow_symlink} // 0;
    my $suffix    = $args{suffix} // substr($taid, 0, 8);

    my @st        = lstat($path);
    my $is_sym    = (-l _);
    my $exists    = $is_sym || (-e _);
    my $is_file   = (-f _);
    my $is_sym_to_file = $is_sym && (-f $path);
    return [412, "Path $path is not a file"] if $exists &&
        !($is_file || $allow_sym && $is_sym_to_file);
    my $msg;

    my $fix_content;
    if ($exists) {
        my $ct = eval { File::Slurper::read_text($path) };
        return [500, "Can't read content of file $path: $!"]
            unless defined($ct);
        my $res;
        if (defined $args{check_content_func}) {
            no strict 'refs';
            $fix_content = !(*{$args{check_content_func}}{CODE}->(\$ct));
        } elsif (defined $args{content_md5}) {
            $fix_content = Digest::MD5::md5_hex($ct) ne $args{content_md5};
        } elsif (defined $args{content}) {
            $fix_content = $ct ne $args{content};
        }
    }

    if ($tx_action eq 'check_state') {

        my @undo;
        if ($exists) {
            if ($fix_content) {
                log_info("(DRY) Replacing file $path ...") if $dry_run;
                $msg = "File $path needs to be replaced";
                unshift @undo, (
                    ["File::Trash::Undoable::untrash",
                     {path=>$path, suffix=>$suffix}],
                    ["File::Trash::Undoable::trash",
                     {path=>$path, suffix=>$suffix."n"}],
                );
            }
        } else {
            log_info("(DRY) File $path should be created");
            my $ct = "";
            if (defined $args{gen_content_func}) {
                no strict 'refs';
                $ct = *{$args{gen_content_func}}{CODE}->(\$ct);
            } elsif (defined $args{content}) {
                $ct = $args{content};
            }
            my $md5 = Digest::MD5::md5_hex($ct);
            log_info("(DRY) Creating file $path ...") if $dry_run;
            $msg = "File $path needs to be created";
            unshift @undo, [rmfile =>
                                {path => $path, suffix=>$suffix."n",
                                 orig_content_md5=>$md5}];
        }
        if (@undo) {
            return [200, $msg, undef, {undo_actions=>\@undo}];
        } else {
            return [304, "File $path already exists"];
        }

    } elsif ($tx_action eq 'fix_state') {

        if ($fix_content) {
            my $res = File::Trash::Undoable::trash(
                -tx_action=>'fix_state', path=>$path,
                    suffix=>$suffix);
            return $res unless $res->[0] == 200;
        }

        if ($fix_content || !$exists) {
            my $ct = "";
            if (defined $args{gen_content_func}) {
                no strict 'refs';
                $ct = *{$args{gen_content_func}}{CODE}->(\$ct);
            } elsif (defined $args{content}) {
                $ct = $args{content};
            }
            log_info("Creating file $path ...");
            if (eval { File::Slurper::write_text($path, $ct); 1 }) {
                CORE::chmod(0644, $path);
                return [200, "OK"];
            } else {
                return [500, "Can't write_file($path): $!"];
            }
        } else {
            # shouldn't reach here
            return [304, "Nothing done"];
        }
    }
    [400, "Invalid -tx_action"];
}

sub _setup_file_or_dir {
    my %args = @_;

    my $which = $args{-which}; # file or dir
    my $Which = ucfirst $which;

    # TMP, SCHEMA
    my $taid         = $args{-tx_action_id}
        or return [400, "Please specify -tx_action_id"];
    my $dry_run      = $args{-dry_run};
    my $path         = $args{path};
    defined($path) or return [400, "Please specify path"];
    my $should_exist = $args{should_exist};
    my $allow_sym    = $args{allow_symlink}   // 1;
    my $replace_file = $args{replace_file}    // 1;
    my $replace_dir  = $args{replace_dir}     // 1;
    my $replace_sym  = $args{replace_symlink} // 1;

    my $ct       = $args{content};
    my $ct_md5   = $args{content_md5};
    my $check_ct = $args{check_content_func};
    my $gen_ct   = $args{gen_content_func};
    return [400, "If check_content_func is specified, ".
                "gen_content_func must also be specified"]
        if defined($check_ct) xor defined($gen_ct);
    return [400, "If content is specified, then check_content_func/".
                "gen_content_func must not be specified (and vice versa)"]
        if defined($ct) && (defined($check_ct) || defined($gen_ct));

    my $is_sym     = (-l $path);
    my $sym_exists = (-e _);
    my $sym_target = readlink($path) if $is_sym;
    my @st         = stat($path); # stricture complains about _
    my $exists     = (-e _);
    my $is_file    = (-f _);
    my $is_dir     = (-d _);

    #$log->tracef("exists=%s, sym_exists=%s, is_sym=%s, sym_target=%s, is_file=%s, is_dir=%s", $exists, $sym_exists, $is_sym, $sym_target, $is_file, $is_dir);

    my (@do, @undo);

    my $act_trash = ["File::Trash::Undoable::trash" => {
        path   => $path,
        suffix => substr($taid,0,8),
    }];
    my $act_untrash = ["File::Trash::Undoable::untrash" => {
        path   => $path,
        suffix => substr($taid,0,8),
    }];
    my $act_trash_n = ["File::Trash::Undoable::trash" => {
        path   => $path,
        suffix => substr($taid,0,8)."n",
    }];
    my $act_untrash_n = ["File::Trash::Undoable::untrash" => {
        path   => $path,
        suffix => substr($taid,0,8)."n",
    }];
    my $act_mkfile = [mkfile => {
        path               => $path,
        content            => $ct,
        content_md5        => $ct_md5,
        check_content_func => $check_ct,
        gen_content_func   => $gen_ct,
        suffix             => substr($taid,0,8)."o",
    }];
    my $act_mkdir = [mkdir => {
        path               => $path,
    }];

    {
        if (defined($should_exist) && !$should_exist) {
            if ($exists) {
                log_info("(DRY) Removing $which $path ...") if $dry_run;
                push    @do  , $act_trash;
                unshift @undo, $act_untrash;
            }
            last;
        }

        last if !defined($should_exist) && !$exists;

        if (!$allow_sym && $is_sym) {
            if (!$replace_sym) {
                return [412,
                        "must replace symlink $path but instructed not to"];
            }
            log_info("(DRY) Replacing symlink $path with $which ...")
                if $dry_run;
            push    @do  , $act_trash;
            unshift @undo, $act_untrash;
        } elsif ($is_dir && $which eq 'file') {
            if (!$replace_dir) {
                return [412, "must replace dir $path but instructed not to"];
            }
            log_info("(DRY) Replacing file $path with $which ...")
                if $dry_run;
            push    @do  , $act_trash;
            unshift @undo, $act_untrash;
        } elsif (!$is_dir && $which eq 'dir') {
            if (!$replace_file) {
                return [412, "must replace file $path but instructed not to"];
            }
            log_info("(DRY) Replacing dir $path with $which ...")
                if $dry_run;
            push    @do  , $act_trash;
            unshift @undo, $act_untrash;
        }

        my $act_mk = $which eq 'file' ? $act_mkfile : $act_mkdir;
        if (!$exists) {
            push    @do  , $act_mk;
            unshift @undo, $act_trash_n;
        } else {
            # get the undo actions from the mk action
            no strict 'refs';
            my $res =
            *{$act_mk->[0]}{CODE}->(
                %{$act_mk->[1]},
                -tx_action=>'check_state', -tx_action_id=>$taid,
            );
            if ($res->[0] == 200) {
                push    @do  , $res->[3]{do_actions} ?
                    @{ $res->[3]{do_actions} } : $act_mk;
                unshift @undo, @{ $res->[3]{undo_actions} };
            } elsif ($res->[0] == 304) {
                # do nothing
            } else {
                return $res;
            }
        }

        if (defined $args{mode}) {
            my $cur_mode = @st ? $st[2] & 07777 : undef;
            push @do, ["chmod" => {
                path=>$path, mode=>$args{mode}}];
            unshift @undo, ["chmod" => {
                path=>$path, mode=>$cur_mode}] if defined($cur_mode);
        }

        if (defined $args{owner}) {
            my $cur_uid = @st ? $st[4] : undef;
            push @do, ["chown" => {
                path=>$path, follow_symlink=>$allow_sym,
                owner=>$args{owner}}];
            unshift @undo, ["chown" => {
                path=>$path, follow_symlink=>$allow_sym,
                mode=>$cur_uid}] if defined($cur_uid);
        }

        if (defined $args{group}) {
            my $cur_gid =@st ?  $st[5] : undef;
            push @do, ["chown" => {
                path=>$path, follow_symlink=>$allow_sym,
                group=>$args{group}}];
            unshift @undo, ["chown" => {
                path=>$path, follow_symlink=>$allow_sym,
                group=>$cur_gid}] if defined($cur_gid);
        }
    } # block

    if (@do) {
        [200, "", undef, {do_actions=>\@do, undo_actions=>\@undo}];
    } else {
        [304, "Already fixed"];
    }
}

$SPEC{setup_file} = {
    v        => 1.1,
    name     => 'setup_file',
    summary  => "Setup file (existence, mode, permission, content)",
    description => <<'_',

On do, will create file (if it doesn't already exist) and correct
mode/permission as well as content.

On undo, will restore old mode/permission/content, or delete the file again if
it was created by this function *and* its content hasn't changed since (if
content/ownership/mode has changed, function will request confirmation).

_
    args     => {
        path => {
            schema  => ['str*'],
            summary => 'Path to file',
            req => 1,
            pos => 0,
        },
        should_exist => {
            schema  => 'bool',
            summary => 'Whether file should exist',
            description => <<'_',

If undef, file need not exist. If set to 0, file must not exist and will be
deleted if it does. If set to 1, file must exist and will be created if it
doesn't.

_
        },
        mode => {
            schema => 'str',
            summary => 'Expected permission mode',
            description => <<'_',

Mode is as supported by File::chmod. Either an octal string (e.g. '0755') or a
symbolic mode (e.g. 'u+rw').

_
        },
        owner => {
            schema  => 'str',
            summary => 'Expected owner (either numeric or username)',
        },
        group => {
            schema  => 'str',
            summary => 'Expected group (either numeric or group name)',
        },
        content => {
            schema  => 'str',
            summary => 'Desired file content',
            description => <<'_',

Alternatively you can also use `content_md5`, or `check_content_func` and
`gen_content_func`.

_
        },
        check_content_func => {
            schema  => 'str',
            summary => 'Name of function to check content',
            description => <<'_',

If unset, file will not be checked for its content. If set, function will be
called whenever file content needs to be checked. Function will be passed the
reference to file content and should return a boolean value indicating whether
content is acceptable. If it returns a false value, content is deemed
unacceptable and needs to be fixed.

Alternatively you can use the simpler `content` argument.

_
        },
        gen_content_func => {
            schema  => 'str',
            summary => 'Name of function to generate content',
            description => <<'_',

If set, whenever a new file content is needed (e.g. when file is created or file
content reset), this function will be called to provide it. If unset, empty
string will be used instead.

Function will be passed the reference to the current content (or undef) and
should return the new content.

Alternatively you can use the simpler `content` argument.

_
        },
        allow_symlink => {
            schema  => [bool => {default=>1}],
            summary => 'Whether symlink is allowed',
            description => <<'_',

If existing file is a symlink to a file then if allow_symlink is false then it
is an unacceptable condition (the symlink will be replaced if replace_symlink is
true).

Note: if you want to setup symlink instead, use Setup::Symlink.

_
        },
        replace_symlink => {
            schema  => [bool => {default=>1}],
            summary => "Replace existing symlink if it needs to be replaced",
        },
        replace_file => {
            schema  => [bool => {default=>1}],
            summary => "Replace existing file if it needs to be replaced",
        },
        replace_dir => {
            schema  => [bool => {default=>1}],
            summary => "Replace existing dir if it needs to be replaced",
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub setup_file {
    _setup_file_or_dir(@_, -which => 'file');
}

$SPEC{setup_dir} = {
    v           => 1.1,
    summary     => "Setup directory (existence, mode, permission)",
    description => <<'_',

On do, will create directory (if it doesn't already exist) and fix its
mode/permission.

On undo, will restore old mode/permission (and delete directory if it is empty
and was created by this function). If directory was created by this function but
is not empty, will return status 331 to ask for confirmation (`-confirm`). If
confirmation is set to true, will delete non-empty directory.

Will *not* create intermediate directories like "mkdir -p". Create intermediate
directories using several setup_dir() invocation.

_
    args     => {
        path => {
            schema  => ['str*'],
            summary => 'Path to file',
            req => 1,
            pos => 0,
        },
        should_exist => {
            schema      => ['bool' => {}],
            summary     => 'Whether dir should exist',
            description => <<'_',

If undef, dir need not exist. If set to 0, dir must not exist and will be
deleted if it does. If set to 1, dir must exist and will be created if it
doesn't.

_
        },
        mode => {
            schema  => ['str' => {}],
            summary => 'Expected permission mode',
        },
        owner => {
            schema  => ['str' => {}],
            summary => 'Expected owner',
        },
        group => {
            schema   => ['str' => {}],
            summary => 'Expected group',
        },
        allow_symlink => {
            schema      => ['bool*' => {default=>1}],
            summary     => 'Whether symlink is allowed',
            description => <<'_',

If existing dir is a symlink then if allow_symlink is false then it is an
unacceptable condition (the symlink will be replaced if replace_symlink is
true).

Note: if you want to setup symlink instead, use Setup::Symlink.

_
        },
        replace_symlink => {
            schema  => ['bool*' => {default=>1}],
            summary => "Replace existing symlink if it needs to be replaced",
        },
        replace_file => {
            schema  => ['bool*' => {default=>1}],
            summary => "Replace existing file if it needs to be replaced",
        },
        replace_dir => {
            schema  => ['bool*' => {default=>1}],
            summary => "Replace existing dir if it needs to be replaced",
        },
    },
    features => {
        tx         => {v=>2},
        idempotent => 1,
    },
};
sub setup_dir  {
    Setup::File::_setup_file_or_dir(@_, -which => 'dir');
}

1;
# ABSTRACT: Setup file (existence, mode, permission, content)

__END__

=pod

=encoding UTF-8

=head1 NAME

Setup::File - Setup file (existence, mode, permission, content)

=head1 VERSION

This document describes version 0.23 of Setup::File (from Perl distribution Setup-File), released on 2017-07-10.

=head1 FUNCTIONS


=head2 chmod

Usage:

 chmod(%args) -> [status, msg, result, meta]

Set file's permission mode.

Fixed state: C<path> exists and mode is already correct.

Fixable state: C<path> exists but mode is not correct.

Unfixable state: C<path> doesn't exist.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<follow_symlink> => I<bool> (default: 0)

Whether to follow symlink.

=item * B<mode>* => I<str>

Permission mode, either numeric or symbolic (e.g. a+w).

=item * B<orig_mode> => I<int>

If set, confirm if current mode is not the same as this.

=item * B<path>* => I<str>

Path to file/directory.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 chown

Usage:

 chown(%args) -> [status, msg, result, meta]

Set file's ownership.

Fixed state: C<path> exists and ownership is already correct.

Fixable state: C<path> exists but ownership is not correct.

Unfixable state: C<path> doesn't exist.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<follow_symlink> => I<bool> (default: 0)

Whether to follow symlink.

=item * B<group> => I<str>

Numeric GID or group.

=item * B<orig_group> => I<str>

If set, confirm if current group is not the same as this.

=item * B<orig_owner> => I<str>

If set, confirm if current owner is not the same as this.

=item * B<owner> => I<str>

Numeric UID or username.

=item * B<path>* => I<str>

Path to file/directory.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 mkdir

Usage:

 mkdir(%args) -> [status, msg, result, meta]

Create directory.

Fixed state: C<path> exists and is a directory.

Fixable state: C<path> doesn't exist.

Unfixable state: C<path> exists and is not a directory.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_symlink> => I<str>

Whether to regard symlink to a directory as directory.

=item * B<mode> => I<str>

Set mode for the newly created directory.

=item * B<path>* => I<str>

Path to directory.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 mkfile

Usage:

 mkfile(%args) -> [status, msg, result, meta]

Create file (and/or set content).

Fixed state: C<path> exists, is a file, and content is correct.

Fixable state: C<path> doesn't exist. Or C<path> exists, is a file, and content is
incorrect. Or C<orig_path> specified and exists.

Unfixable state: C<path> exists and is not a file.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_symlink> => I<str>

Whether to regard symlink to a file as file.

=item * B<check_content_func> => I<str>

Name of function to check content.

If unset, file will not be checked for its content. If set, function will be
called whenever file content needs to be checked. Function will be passed the
reference to file content and should return a boolean value indicating whether
content is acceptable. If it returns a false value, content is deemed
unacceptable and needs to be fixed.

Alternatively you can use the simpler C<content> or C<content_md5> argument.

=item * B<content> => I<str>

Desired file content.

Alternatively you can also use C<content_md5>, or C<gen_content_func> and
C<check_content_func>.

=item * B<content_md5> => I<str>

Check content against MD5 hash.

MD5 hash should be expressed in hex (e.g. bed6626e019e5870ef01736b3553e570).

Used when checking content of existing file.

Alternatively you can also use C<content>, or C<check_content_func>.

=item * B<gen_content_func> => I<str>

Name of function to generate content.

If set, whenever a new file content is needed (e.g. when file is created or file
content reset), this function will be called to provide it. If unset, empty
string will be used instead.

Function will be passed the reference to the current content (or undef) and
should return the new content.

Alternatively you can use the simpler C<content> argument.

=item * B<path>* => I<str>

Path to file.

=item * B<suffix> => I<str>

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 rmdir

Usage:

 rmdir(%args) -> [status, msg, result, meta]

Delete directory.

Fixed state: C<path> doesn't exist.

Fixable state: C<path> exists and is a directory (or, a symlink to a directory,
if C<allow_symlink> option is enabled).

Unfixable state: C<path> exists but is not a directory.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_symlink> => I<bool> (default: 0)

Whether to regard symlink to a directory as directory.

=item * B<delete_nonempty_dir> => I<bool>

Whether to delete non-empty directory.

If set to true, will delete non-empty directory.

If set to false, will never delete non-empty directory.

If unset (default), will ask for confirmation first by returning status 331.
Caller can confirm by passing special argument C<-confirm>.

=item * B<path>* => I<str>

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 rmfile

Usage:

 rmfile(%args) -> [status, msg, result, meta]

Delete file.

Fixed state: C<path> doesn't exist.

Fixable state: C<path> exists and is a file (or, a symlink to a file, if
C<allow_symlink> option is enabled).

Unfixable state: C<path> exists but is not a file.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_symlink> => I<bool> (default: 0)

Whether to regard symlink to a file as file.

=item * B<orig_content> => I<str>

If set, confirm if current content is not the same as this.

Alternatively, you can use C<orig_content_hash>.

=item * B<orig_content_md5> => I<str>

If set, confirm if current content MD5 hash is not the same as this.

MD5 hash should be expressed in hex (e.g. bed6626e019e5870ef01736b3553e570).

Alternatively, you can use C<orig_content> (for shorter content).

=item * B<path>* => I<str>

=item * B<suffix> => I<str>

Use this suffix when trashing.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 setup_dir

Usage:

 setup_dir(%args) -> [status, msg, result, meta]

Setup directory (existence, mode, permission).

On do, will create directory (if it doesn't already exist) and fix its
mode/permission.

On undo, will restore old mode/permission (and delete directory if it is empty
and was created by this function). If directory was created by this function but
is not empty, will return status 331 to ask for confirmation (C<-confirm>). If
confirmation is set to true, will delete non-empty directory.

Will I<not> create intermediate directories like "mkdir -p". Create intermediate
directories using several setup_dir() invocation.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_symlink> => I<bool> (default: 1)

Whether symlink is allowed.

If existing dir is a symlink then if allow_symlink is false then it is an
unacceptable condition (the symlink will be replaced if replace_symlink is
true).

Note: if you want to setup symlink instead, use Setup::Symlink.

=item * B<group> => I<str>

Expected group.

=item * B<mode> => I<str>

Expected permission mode.

=item * B<owner> => I<str>

Expected owner.

=item * B<path>* => I<str>

Path to file.

=item * B<replace_dir> => I<bool> (default: 1)

Replace existing dir if it needs to be replaced.

=item * B<replace_file> => I<bool> (default: 1)

Replace existing file if it needs to be replaced.

=item * B<replace_symlink> => I<bool> (default: 1)

Replace existing symlink if it needs to be replaced.

=item * B<should_exist> => I<bool>

Whether dir should exist.

If undef, dir need not exist. If set to 0, dir must not exist and will be
deleted if it does. If set to 1, dir must exist and will be created if it
doesn't.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 setup_file

Usage:

 setup_file(%args) -> [status, msg, result, meta]

Setup file (existence, mode, permission, content).

On do, will create file (if it doesn't already exist) and correct
mode/permission as well as content.

On undo, will restore old mode/permission/content, or delete the file again if
it was created by this function I<and> its content hasn't changed since (if
content/ownership/mode has changed, function will request confirmation).

This function is not exported by default, but exportable.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_symlink> => I<bool> (default: 1)

Whether symlink is allowed.

If existing file is a symlink to a file then if allow_symlink is false then it
is an unacceptable condition (the symlink will be replaced if replace_symlink is
true).

Note: if you want to setup symlink instead, use Setup::Symlink.

=item * B<check_content_func> => I<str>

Name of function to check content.

If unset, file will not be checked for its content. If set, function will be
called whenever file content needs to be checked. Function will be passed the
reference to file content and should return a boolean value indicating whether
content is acceptable. If it returns a false value, content is deemed
unacceptable and needs to be fixed.

Alternatively you can use the simpler C<content> argument.

=item * B<content> => I<str>

Desired file content.

Alternatively you can also use C<content_md5>, or C<check_content_func> and
C<gen_content_func>.

=item * B<gen_content_func> => I<str>

Name of function to generate content.

If set, whenever a new file content is needed (e.g. when file is created or file
content reset), this function will be called to provide it. If unset, empty
string will be used instead.

Function will be passed the reference to the current content (or undef) and
should return the new content.

Alternatively you can use the simpler C<content> argument.

=item * B<group> => I<str>

Expected group (either numeric or group name).

=item * B<mode> => I<str>

Expected permission mode.

Mode is as supported by File::chmod. Either an octal string (e.g. '0755') or a
symbolic mode (e.g. 'u+rw').

=item * B<owner> => I<str>

Expected owner (either numeric or username).

=item * B<path>* => I<str>

Path to file.

=item * B<replace_dir> => I<bool> (default: 1)

Replace existing dir if it needs to be replaced.

=item * B<replace_file> => I<bool> (default: 1)

Replace existing file if it needs to be replaced.

=item * B<replace_symlink> => I<bool> (default: 1)

Replace existing symlink if it needs to be replaced.

=item * B<should_exist> => I<bool>

Whether file should exist.

If undef, file need not exist. If set to 0, file must not exist and will be
deleted if it does. If set to 1, file must exist and will be created if it
doesn't.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 FAQ

=head2 Why not allowing coderef in 'check_content_func' and 'gen_content_func' argument?

Because transactional function needs to store its argument in database
(currently in JSON), coderefs are not representable in JSON.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Setup-File>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Setup-File>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Setup-File>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Setup>

L<Setup::File::Dir>

L<Setup::File::Symlink>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
