package Review::Helper::VCS::Git;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use Cwd qw/abs_path/;
use Encode qw/decode/;
use File::Basename qw/dirname/;
use File::Spec();
use File::Temp();
use POSIX();

use Object::HashBase qw{
    <root
    <git_dir
    <common_dir
};

use Role::Tiny::With;
with 'Review::Helper::VCS';

my @DIFF_OPTIONS = qw{
    --no-ext-diff --no-color --no-textconv --indent-heuristic
    --diff-algorithm=histogram --find-renames -U3
    --src-prefix=a/ --dst-prefix=b/
};

my %STATUS_MAP = (A => 'A', D => 'D', M => 'M', R => 'R', T => 'M', C => 'A');

sub init($self) {
    croak "'root' is a required attribute" unless $self->{+ROOT};
}

sub find($class, $path) {
    croak "No path given" unless defined $path && length $path;
    my $dir = -d $path ? $path : dirname($path);
    croak "No such directory: $dir" unless -d $dir;
    $dir = abs_path($dir);

    my ($git_dir, $common_dir, $in_git_dir) = split /\n/ => $class->_git_in($dir, qw/rev-parse --path-format=absolute --git-dir --git-common-dir --is-inside-git-dir/);

    my $root;
    if ($in_git_dir eq 'true') {
        $root = $class->_root_from_git_dir($git_dir, $common_dir);
    }
    else {
        ($root) = split /\n/ => $class->_git_in($dir, qw/rev-parse --show-toplevel/);
    }

    return $class->new(root => $root, git_dir => $git_dir, common_dir => $common_dir);
}

sub state_dir($self)        { $self->_git_path('review-helper') }
sub shared_state_dir($self) { $self->{+COMMON_DIR} . '/review-helper' }

sub is_internal_path($self, $path) {
    return !!grep { index($path, "$_/") == 0 } $self->{+GIT_DIR}, $self->{+COMMON_DIR};
}

sub resolve($self, $rev) {
    my ($out, $exit, $err) = $self->_run($self->{+ROOT}, undef, qw/rev-parse --verify --quiet --end-of-options/, "$rev^{commit}");
    croak "Unknown revision '$rev'"  if $exit == 1;
    die "git rev-parse failed: $err" if $exit;
    chomp($out);
    return $out;
}

sub empty_revision($self) {
    return $self->{_empty_tree} //= do {
        my $out = $self->_git(qw/hash-object -t tree/, '/dev/null');
        chomp($out);
        $out;
    };
}

sub has_revision($self, $sha) {
    return $self->_predicate(qw/rev-parse --verify --quiet --end-of-options/, "$sha^{commit}");
}

# Oldest first, each after its parents, with them.
sub revisions($self, $base, $head) {
    my $out = $self->_git(qw/rev-list --reverse --topo-order --parents --end-of-options/, "$base..$head");
    return [map { my ($sha, @parents) = split / /; +{revision => $sha, parents => \@parents} } split /\n/ => $out];
}

# The branch or tag name $rev stands for: not a detached HEAD, nor an
# option git would read.
sub revision_name($self, $rev) {
    return undef if $rev =~ m/^-/;
    my ($name) = split /\n/ => $self->_git(qw/rev-parse --abbrev-ref/, $rev);
    return undef if !defined($name) || $name eq 'HEAD';
    return $name;
}

sub revision_info($self, $sha) {
    my $out = $self->_git(qw/log -1 --no-show-signature --format=%H%x00%P%x00%an%x20<%ae>%x00%at%x00%s%x00%B --end-of-options/, $sha);
    my ($full, $parents, $author, $authored, $subject, $message) = split /\0/ => decode('UTF-8', $out), 6;
    my ($parent) = split / / => $parents;
    $message =~ s/\n+\z/\n/;

    return {
        revision => $full,
        parent   => $parent,
        subject  => $subject,
        message  => $message,
        author   => $author,
        authored => $authored + 0,
    };
}

sub change_id($self, $sha) {
    my $diff = $self->_git('diff', @DIFF_OPTIONS, $self->_parent_or_empty($sha), $sha);
    return undef unless length $diff;

    my ($out, $exit, $err) = $self->_run($self->{+ROOT}, $diff, qw/patch-id --stable/);
    die "git patch-id failed: $err" if $exit;
    my ($id) = split / / => $out;
    return $id;
}

sub range_changes($self, $from, $to, $paths = undef) {
    my @range   = ($from, $to, '--', @{$paths // []});
    my $changes = $self->_parse_raw($self->_git(qw/diff-tree -r -z -M --raw/, @range));
    my $numstat = $self->_git(qw/diff-tree -r -z -M --numstat/, @range);

    my $counts = $self->_parse_numstat($numstat);
    for my $change (@$changes) {
        my $count = $counts->{$change->{path}} // die "No line counts for '$change->{path}'";
        %$change = (%$change, %$count);
    }

    return $changes;
}

sub range_diff($self, $from, $to, $path, $old_path = undef) {
    return $self->_git('diff', @DIFF_OPTIONS, $from, $to, '--', $self->_file_pathspecs($path, $old_path));
}

sub resolution_changes($self, $sha, $paths = undef) {
    return [] unless $self->_has_remerge_diff && @{$self->parents($sha)} > 1;
    return $self->_parse_raw($self->_git(qw/diff-tree --remerge-diff --no-commit-id -r -z -M --raw --end-of-options/, $sha, '--', @{$paths // []}));
}

sub resolution_diff($self, $sha, $path, $old_path = undef) {
    return $self->_git(qw/diff-tree --remerge-diff --no-commit-id -r -p/, @DIFF_OPTIONS, '--end-of-options', $sha, '--', $self->_file_pathspecs($path, $old_path));
}

sub parents($self, $sha) {
    my (undef, @parents) = split ' ' => $self->_git(qw/rev-list --parents -n 1 --end-of-options/, $sha);
    return \@parents;
}

# One run when the file is there; on a failure, a second finds out whether
# it is absent or git failed.
sub file($self, $sha, $path) {
    my ($out, $exit, $err) = $self->_run($self->{+ROOT}, undef, qw/cat-file blob/, "$sha:$path");
    return $out  unless $exit;
    return undef unless defined $self->_blob($sha, $path);
    die "git cat-file failed: $err";
}

sub file_id($self, $sha, $path) {
    my ($out, $exit, $err) = $self->_run($self->{+ROOT}, undef, qw/rev-parse --verify --quiet --end-of-options/, "$sha:$path");
    return undef                     if $exit == 1;
    die "git rev-parse failed: $err" if $exit;
    chomp($out);
    return $out;
}

sub pin_name($self, $review_id, $number) { "refs/review-helper/$review_id/$number" }

sub pin($self, $ref, $sha) { $self->_git('update-ref', $ref, $sha); return }
sub unpin($self, $ref) { $self->_git(qw/update-ref -d/, $ref); return }

# for-each-ref matches a prefix by path components, so check it whole.
sub pins($self, $review_id) {
    my $prefix = "refs/review-helper/$review_id/";
    return [grep { index($_, $prefix) == 0 } split /\n/ => $self->_git(qw/for-each-ref --format=%(refname)/, $prefix)];
}

# Unlike every other git run here, this one reads the user's configuration:
# that is where their name and email live.
sub user($self) {
    my %id;
    for my $key (qw/name email/) {
        open(my $fh, '-|', 'git', '-C', $self->{+ROOT}, 'config', '--get', "user.$key") or next;
        my $value = decode('UTF-8', join('' => <$fh>));
        close($fh);
        $value =~ s/\A\s+|\s+\z//g;
        $id{$key} = $value if !$? && length $value;
    }
    my @parts = (($id{name} // ()), (defined($id{email}) ? "<$id{email}>" : ()));
    return @parts ? join(' ' => @parts) : undef;
}

sub _git($self, @args) {
    my ($out, $exit, $err) = $self->_run($self->{+ROOT}, undef, @args);
    die "git @args failed: $err" if $exit;
    return $out;
}

sub _git_path($self, $name) {
    my $out = $self->_git(qw/rev-parse --path-format=absolute --git-path/, $name);
    chomp($out);
    return $out;
}

# One file's paths, taken literally: `app/[id]/page.js` must not match
# `app/i/page.js`.
sub _file_pathspecs($self, $path, $old_path = undef) {
    return map { ":(literal)$_" } defined($old_path) ? ($old_path, $path) : ($path);
}

# git 2.36 added --remerge-diff.
sub _has_remerge_diff($self) {
    return $self->{_has_remerge_diff} //= do {
        my ($major, $minor) = $self->_git('version') =~ m/(\d+)\.(\d+)/;
        ($major // 0) > 2 || (($major // 0) == 2 && $minor >= 36) ? 1 : 0;
    };
}

# The blob id of a file at $path in commit $sha; undef when it is absent or
# not a file. A directory is a tree. A submodule entry names a commit of
# another repository, usually absent from this one, so cat-file fails for it.
sub _blob($self, $sha, $path) {
    my $id = $self->file_id($sha, $path) // return undef;
    my ($type, $exit) = $self->_run($self->{+ROOT}, undef, qw/cat-file -t/, $id);
    return $exit || $type ne "blob\n" ? undef : $id;
}

sub _git_in($class, $dir, @args) {
    my ($out, $exit, $err) = $class->_run($dir, undef, @args);
    croak "Not inside a git worktree: $dir\n$err" if $exit;
    return $out;
}

sub _root_from_git_dir($class, $git_dir, $common_dir) {
    # A git directory that names its worktree (core.worktree, as a submodule's
    # does) answers this; a repository's own .git and a linked worktree's
    # git directory do not.
    my ($root, $top_exit) = $class->_run($git_dir, undef, qw/rev-parse --show-toplevel/);
    chomp($root);
    if ($top_exit || !length($root)) {
        if ($git_dir eq $common_dir) {
            $root = dirname($git_dir);
        }
        else {
            open(my $fh, '<', "$git_dir/gitdir") or croak "Cannot find the worktree of $git_dir: $!";
            my $dot_git = <$fh>;
            chomp($dot_git);

            # Relative when the worktree was added with --relative-paths.
            $root = dirname(File::Spec->rel2abs($dot_git, $git_dir));
            $root = abs_path($root) // $root if -d $root;
        }
    }

    my ($check, $exit) = -d $root ? $class->_run($root, undef, qw/rev-parse --path-format=absolute --git-dir/) : (q{}, 1);
    chomp($check);
    croak "Cannot find the worktree of $git_dir" if $exit || $check ne $git_dir;

    return $root;
}

sub _parent_or_empty($self, $sha) { $self->parents($sha)->[0] // $self->empty_revision }

# Paths come back as characters.
sub _parse_raw($self, $raw) {
    my @changes;
    my @tokens = map { decode('UTF-8', $_) } split /\0/ => $raw;
    while (@tokens) {
        my ($old_mode, $new_mode, undef, undef, $code) = split / / => substr(shift(@tokens), 1);
        $code = substr($code, 0, 1);
        my %change = (status => $STATUS_MAP{$code} // die "Unexpected diff status '$code'");
        $change{submodule} = grep({ $_ eq '160000' } $old_mode, $new_mode) ? 1 : 0;
        $change{old_path}  = shift @tokens if $code eq 'R' || $code eq 'C';
        $change{path}      = shift @tokens;
        $change{old_path}  = undef unless $change{status} eq 'R';
        push @changes => \%change;
    }

    return \@changes;
}

sub _parse_numstat($self, $numstat) {
    my %counts;
    my @tokens = split /\0/ => $numstat;
    while (@tokens) {
        my ($added, $removed, $path) = split /\t/ => shift(@tokens), 3;
        unless (length $path) {
            shift @tokens;    # old path of a rename
            $path = shift @tokens;
        }

        my $binary = $added eq '-' ? 1 : 0;
        $counts{decode('UTF-8', $path)} = {
            added   => $binary ? 0 : $added + 0,
            removed => $binary ? 0 : $removed + 0,
            binary  => $binary,
        };
    }

    return \%counts;
}

sub _predicate($self, @args) {
    my (undef, $exit, $err) = $self->_run($self->{+ROOT}, undef, @args);
    return 1 if $exit == 0;
    return 0 if $exit == 1;
    die "git @args failed: $err";
}

# Fork and exec by hand, not Capture::Tiny: git needs its input and error
# file on descriptors 0 and 2 and its output as bytes (RULINGS.md).
sub _run($class, $dir, $input, @args) {
    my @argv = ('git', '-C', $dir, @args);
    # Character strings become UTF-8; byte strings (paths from the file system) pass as they are.
    utf8::is_utf8($_) && utf8::encode($_) for @argv;

    my $err = File::Temp->new;
    my $in;
    if (defined $input) {
        $in = File::Temp->new;
        print $in $input;
        close($in) or die "close input file: $!";
    }

    my $pid = open(my $fh, '-|') // die "Could not fork: $!";
    unless ($pid) {
        $ENV{GIT_CONFIG_NOSYSTEM} = 1;
        $ENV{GIT_CONFIG_GLOBAL}   = '/dev/null';
        # Pathspec modes would change what :(literal) and --path globs mean.
        delete @ENV{qw/GIT_LITERAL_PATHSPECS GIT_GLOB_PATHSPECS GIT_NOGLOB_PATHSPECS GIT_ICASE_PATHSPECS/};
        # By descriptor: Perl's STDIN and STDERR may not be descriptors 0
        # and 2 (in-memory handles), and git inherits descriptors. The error
        # file goes to 2 first, since it is on 0 when the parent has 0 closed.
        my ($msg, $stdin);
        if    (!defined POSIX::dup2(fileno($err), 2))                 { $msg = "cannot set up git's error output: $!" }
        elsif (!open($stdin, '<', $in ? $in->filename : '/dev/null')) { $msg = "cannot open git's input: $!" }
        elsif (!defined POSIX::dup2(fileno($stdin), 0))               { $msg = "cannot set up git's input: $!" }
        else {
            no warnings 'exec';    # reported below
            exec(@argv);
            $msg = "exec git failed: $!";
        }
        POSIX::write(2, $msg, length $msg);    # not Perl's STDERR, which may not be descriptor 2
        POSIX::_exit(127);
    }

    binmode($fh);
    my $out = join('' => <$fh>);
    close($fh);
    my $exit = $? >> 8;
    $exit ||= 255 if $?;

    seek($err, 0, 0);
    my $err_text = join('' => <$err>);

    return ($out, $exit, $err_text);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::VCS::Git - Git as the version control system of a review.

=head1 DESCRIPTION

The git implementation of L<Review::Helper::VCS>, holding everything about
git the rest of Review::Helper does not know: commands, options, ref names,
the git directory and pathspec magic.

Git always runs as a list-form process, never through a shell, with
C<GIT_CONFIG_NOSYSTEM=1> and C<GIT_CONFIG_GLOBAL=/dev/null>, and with the
C<GIT_*_PATHSPECS> variables unset, so user configuration cannot change its
output. A single file is named as C<< :(literal)<path> >>. Diffs use one
fixed set of options so line anchors stay stable.

Arguments are character strings and are passed to git as UTF-8. Paths and
commit text coming back from the higher-level methods are decoded from UTF-8;
the diffs and C<file> return raw bytes.

The format specification gives the git meaning of each of the role's terms.
C<user> (C<user.name> and C<user.email>) is the one git run that reads the
user's own configuration; a git older than 2.36 shows no merge resolutions.

=head1 SYNOPSIS

    use Review::Helper::VCS::Git;

    my $git = Review::Helper::VCS::Git->find($path);

    my $head    = $git->resolve('HEAD');
    my $revs    = $git->revisions($base, $head);
    my $changes = $git->range_changes($base, $head);

=head1 ATTRIBUTES

=over 4

=item $dir = $git->root()

Absolute path of the worktree's top directory.

=item $dir = $git->git_dir()

Absolute path of the worktree's git directory.

=item $dir = $git->common_dir()

Absolute path of the git directory shared by all worktrees.

=back

=head1 PUBLIC METHODS

Every method the role requires, as L<Review::Helper::VCS> describes them.
C<find> here:

=over 4

=item $git = Review::Helper::VCS::Git->find($path)

Find the worktree holding C<$path>, a file or directory. A file need not
exist, but its directory must. Paths inside a git directory (where review
files live by default) resolve to that git directory's worktree. Croaks when
there is no worktree, including for bare repositories.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
