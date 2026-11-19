package Path::Secure 0.001;

# ABSTRACT: Say whether an account other than you could change a path, or make sure it cannot

use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aa';

use Cwd    qw{realpath};
use Errno  qw{ENOENT};
use parent qw{Exporter};
use Fcntl  qw{S_ISDIR S_ISLNK S_ISVTX S_IWGRP S_IWOTH};
use File::Spec;

our @EXPORT_OK = qw{exposed secure};


# The bits of a mode that chmod sets: the permissions, and setuid, setgid and sticky.
my $MODE_BITS = oct 7777;

# Systems whose stat does not report POSIX owners and modes.
my %NOT_POSIX = map { $_ => 1 } qw{MSWin32 VMS dos os2 MacOS NetWare riscos symbian};

# The longest chain of symbolic links that walk follows, as Linux does.
my $MOST_LINKS = 40;

# The paths in @changed, as a message names them.
my $listed = sub {
    my (@changed) = @_;
    return @changed ? join q{, }, @changed : 'nothing';
};

# The options of $function, checked: $path, then @{$pairs}, of which @known
# are allowed.  A hash of the options, with the gids of trust_group as the keys
# of trusted.
my $options = sub {
    my ( $function, $path, $pairs, @known ) = @_;
    die "Path::Secure cannot tell who can change a path on $^O, whose files do not have POSIX owners and modes\n" if $NOT_POSIX{$^O};
    die "$function needs a path\n"                                                                                if !defined $path || $path eq q{};
    die "$function takes a path and then pairs of options and their values\n"                                     if @{$pairs} % 2;
    my %given   = @{$pairs};
    my %allowed = map       { $_ => 1 } @known;
    my @unknown = sort grep { !$allowed{$_} } keys %given;
    die "$function does not know the option @unknown\n" if @unknown;
    my $groups = exists $given{trust_group} ? $given{trust_group} : [];
    my @gids   = ref $groups eq 'ARRAY'     ? @{$groups}          : ($groups);

    for my $gid (@gids) {
        my $shown = !defined $gid ? 'undef' : ref $gid ? ref $gid : $gid;
        die "trust_group takes a gid or a reference to an array of gids, not $shown\n" if !defined $gid || ref $gid || $gid !~ m{\A\d+\z}sx;
    }
    my %option = ( %given, trusted => { map { $_ => 1 } @gids } );
    return \%option;
};

# The names in $path that walk looks up, without the empty ones and dots.
my $parts = sub {
    my ($path) = @_;
    return grep { $_ ne q{} && $_ ne q{.} } split m{/+}sx, $path;
};

# Whether the owner $uid is one that the policy trusts.
my $trusted_owner = sub {
    my ($uid) = @_;
    return $uid == $> || $uid == 0;
};

# Why the entry $path, which lstat describes as @{$status}, is exposed, or
# undef.  $role is 'above' for a directory above the target, else 'target'.
my $judge = sub {
    my ( $path, $status, $option, $mode, $role ) = @_;
    my ( $bits, $uid, $gid ) = @{$status}[ 2, 4, 5 ];
    my $trusted = $option->{trusted};
    $bits = $bits & ~$MODE_BITS | $mode->{$path} if exists $mode->{$path};
    return "another account owns $path" if !$trusted_owner->($uid);
    my $pass = $role eq 'above' || $option->{sticky_target};
    return                                   if $pass && S_ISDIR($bits) && $bits & S_ISVTX;
    return "every account can write $path"   if $bits & S_IWOTH;
    return "the group of $path can write it" if $bits & S_IWGRP && !$trusted->{$gid};
    return;
};

# What exposed returns for $path, with the options in %{$option}, and with the
# modes of the real paths in %{$mode} in place of what lstat says.
my $walk = sub {
    my ( $path, $option, $mode ) = @_;
    my @todo  = $parts->( File::Spec->rel2abs($path) );
    my $at    = q{/};
    my @where = stat_entry($at);
    my $links = 0;
    while (@todo) {
        my $name = shift @todo;
        if ( $name eq q{..} ) {
            $at =~ s{/[^/]+\z}{}sx;
            $at    = q{/} if $at eq q{};
            @where = stat_entry($at);
            next;
        }
        my $why = $judge->( $at, \@where, $option, $mode, 'above' );
        return $why if defined $why;
        my $next  = $at eq q{/} ? "/$name" : "$at/$name";
        my @found = stat_entry($next);
        return $! == ENOENT ? "$next is not there" : "cannot look at $next: $!" if !@found;
        if ( !S_ISLNK( $found[2] ) ) {
            ( $at, @where ) = ( $next, @found );
            next;
        }
        return "another account owns the symbolic link $next"     if !$trusted_owner->( $found[4] );
        return "$path names more than $MOST_LINKS symbolic links" if ++$links > $MOST_LINKS;
        my $to = readlink $next;
        return "cannot read the symbolic link $next: $!" if !defined $to;
        unshift @todo, $parts->($to);
        if ( File::Spec->file_name_is_absolute($to) ) {
            $at    = q{/};
            @where = stat_entry($at);
        }
    }
    return $judge->( $at, \@where, $option, $mode, 'target' );
};

# The entry at the real path of $path, as secure plans for it: its path, dev,
# ino, uid and gid, whether it is a directory, and the mode bits that chmod
# takes, as was.
my $real_entry = sub {
    my ($path) = @_;
    my $real   = realpath($path);
    my @status = defined $real ? stat_entry($real) : ();
    die "$path is not there\n" if !@status;
    return { path => $real, dev => $status[0], ino => $status[1], uid => $status[4], gid => $status[5], dir => S_ISDIR( $status[2] ), was => $status[2] & $MODE_BITS };
};


sub exposed {
    my ( $path, @pairs ) = @_;
    my $option = $options->( 'exposed', $path, \@pairs, qw{trust_group sticky_target} );
    my $why    = $walk->( $path, $option, {} );
    return $why;
}


sub secure {
    my ( $path, @pairs ) = @_;
    my $option = $options->( 'secure', $path, \@pairs, qw{upto trust_group private} );
    die "secure needs upto, the highest directory that it may change\n" if !defined $option->{upto};
    my $top    = $real_entry->( $option->{upto} );
    my $target = $real_entry->($path);
    die "$option->{upto} is not a directory\n" if !$top->{dir};

    # Every entry from $top down to the target, each with the mode to give it.
    my @plan = ($target);
    my $at   = $target->{path};
    while ( $at ne $top->{path} ) {
        die "$path is not in $option->{upto}\n" if $at eq q{/};
        $at =~ s{/[^/]+\z}{}sx;
        $at = q{/} if $at eq q{};
        unshift @plan, $real_entry->($at);
    }
    my $trusted = $option->{trusted};
    for my $entry (@plan) {
        my $open = $entry->{was} & ( $trusted->{ $entry->{gid} } ? S_IWOTH : S_IWOTH | S_IWGRP );
        $entry->{mode} = $entry->{was};
        if ( $entry == $target || $option->{private} ) {
            $entry->{mode} &= ~$open;
        }
        elsif ($open) {
            $entry->{mode} |= S_ISVTX;
        }
    }

    my %mode = map { $_->{path} => $_->{mode} } @plan;
    my $why  = $walk->( $path, $option, \%mode );
    die "secure cannot make $path safe: $why\n" if defined $why;
    my @changes = grep { $_->{mode} != $_->{was} } @plan;
    for my $change (@changes) {
        next if $change->{uid} == $> || $> == 0;
        die "secure cannot make $path safe: $change->{path} needs its mode changed, and only root can do that\n";
    }

    my @changed;
    for my $change (@changes) {
        my ( $dev, $ino, $now ) = stat_entry( $change->{path} );
        if ( !defined $now || "$dev $ino" ne "@{$change}{qw{dev ino}}" || S_ISLNK($now) ) {
            die "secure stopped: $change->{path} changed while it worked; it had changed @{[ $listed->(@changed) ]}\n";
        }
        change_mode( @{$change}{qw{mode path}} ) or die "secure stopped: chmod $change->{path}: $!; it had changed @{[ $listed->(@changed) ]}\n";
        push @changed, $change->{path};
    }
    $why = exposed( $path, trust_group => [ sort keys %{$trusted} ] );
    die "secure changed @{[ $listed->(@changed) ]}, but $why\n" if defined $why;
    return @changed;
}


sub stat_entry {
    my ($path) = @_;
    return lstat $path;
}


sub change_mode {
    my ( $mode, $path ) = @_;
    return chmod $mode, $path;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Secure - Say whether an account other than you could change a path, or make sure it cannot

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Path::Secure qw{exposed secure};

    my $why = exposed( '/srv/app/config', trust_group => $) + 0 );
    die "refused: $why\n" if defined $why;

    my @changed = secure( '/srv/app/config', upto => '/srv/app' );
    print "made $_ safe\n" for @changed;

=head1 DESCRIPTION

Before a program reads a file that tells it what to do, or runs one, it has to
know that nobody else wrote it.  Checking the file is not enough.  An account
that can write a directory above the file can rename the file away and put its
own in its place, and an account that can write the directory holding a
symbolic link can point the link somewhere else.  L</exposed> answers the
whole question: could an account other than you change this path, or a
directory above it, or a link on the way to it?  L</secure> changes the modes
that it can, so that the answer is no.

The same check exists in L<File::Temp>, as the private C<_is_safe> and
C<_is_verysafe>, and in L<Net::OpenSSH>, for its control directory.  This
distribution makes it public, with an option to trust a group, and returns the
reason rather than a bare false.

=head2 The policy

These are the rules that both functions apply.  A I<path> here is the path
that the caller passes.  Its I<entries> are every directory that resolving the
path looks in, from F</> down, every symbolic link that it follows, and the
entry that it finally names, which is the I<target>.

=over

=item *

An entry is safe from an account when that account cannot write it, and
cannot replace it.  Root can do anything, so an entry that root owns or can
write is not a risk that a check can remove.  So root is trusted, as is the
effective uid of the process, C<< $> >>.  Nobody else is.

=item *

An entry is exposed when another account owns it, other than root.  The owner
of a file can change its mode at any time, so no mode makes it safe.

=item *

An entry is exposed when every account can write it (C<S_IWOTH>), or when its
group can write it (C<S_IWGRP>) and that group is not one that the caller
trusts with C<trust_group>.  No group is trusted by default, not even the
primary group of the process: a group usually has members that the process
does not know about.

=item *

A directory above the target that has the sticky bit (C<S_ISVTX>) is safe even
when other accounts can write it, because then they can rename or remove only
the entries that they own, and the next entry down has to pass the owner rule.
That is how F</tmp> works.  It still has to pass the owner rule itself.

=item *

The target gets no pass for the sticky bit.  An account that can make a new
entry in a directory can make one whose name the program will read, even if it
cannot replace the entries that are there.  C<< sticky_target => 1 >> gives the
pass to a target that is a directory, for a caller that only makes new entries
in it with C<O_EXCL> and reads nothing that it did not make.

=item *

A symbolic link is followed one step at a time, as the kernel does.  The link
itself has to pass the owner rule: in a sticky directory, the owner of a link
can replace it.  Its own mode means nothing.  The directory that holds it is
an entry above the target, so whoever can write that directory could point
the link somewhere else.  What the link names is resolved in turn, and so is each link after
it.  A chain of more than 40 links, which is the limit of Linux, is a reason.

=item *

A C<..> leaves a directory without making it an entry above the target,
because the kernel resolves C<..> from the directory's own parent, which a
write to the directory cannot change.

=item *

A relative path is taken from the current directory, as the kernel would take
it.  Its real path, from L<Cwd>, is where the walk starts, so every directory
above the current one is checked too.

=back

=head2 What it does not cover

The check reads owners and mode bits, and nothing else that can grant a
write.  It does not read access control lists (POSIX ACLs, NFSv4 ACLs), Linux
capabilities such as C<CAP_DAC_OVERRIDE> or C<CAP_FOWNER> held by another
process, file attributes such as C<chattr +i>, the options that a filesystem
is mounted with, or the policies of SELinux or AppArmor.  A filesystem that
does not keep POSIX owners, such as FAT or many network mounts, reports what
its driver makes up.  A file system mounted by another account, such as a
FUSE mount, is safe only as far as its driver tells the truth.

It does not look for another name of the same file: a hard link in a directory
that other accounts can write lets them unlink that name, not change the file,
so it does not matter here.

=head2 Chown giveaway

On some systems an account can give a file that it owns to another account
with C<chown>.  POSIX calls the opposite C<_POSIX_CHOWN_RESTRICTED>, and asks
for it with C<pathconf(_PC_CHOWN_RESTRICTED)>.  Linux and the BSDs restrict
C<chown> to root.  Where it is not restricted, an entry that the process owns
may have been made by another account, which can still hold a descriptor that
it opened for writing before it gave the file away.  No mode or owner shows
that, so this module cannot see it, on any system.  It does not change the
result.  L<File::Temp> asks C<_PC_CHOWN_RESTRICTED> only to decide whether to
check the directories above a path.  This module always checks them.

=head2 The race that it cannot close

Each answer is true when it is made.  Between the check and the moment the
program opens the path, the modes and the entries can change.  The check is
worth making because of what it rules out: when every entry passes, no account
other than root and the caller can make such a change, so the answer stays
true until one of them changes it.  Open the path after the check, and if the
check matters, compare C<dev> and C<ino> of what you opened with C<stat> of
the path.

=head1 FUNCTIONS

=head2 exposed

C<($path, %option)>.  Why an account other than the effective uid or root
could change C<$path> or an entry on the way to it, as L</The policy> says, or
undef when no such account can, in list context as well.  The reason is one
clause in English that names the entry at fault, such as C<every account can
write /srv/shared>, so a caller can put it after C<refused:> in a message.  It checks the entries from
F</> down and gives the first reason that it finds.

A path that is not there is not safe: the reason is that the first missing
entry C<is not there>.  An entry that it cannot look at, for example in a
directory that it cannot search, gives the error of C<lstat>.

The options:

=over

=item trust_group

A gid, or a reference to an array of gids.  An entry that one of these groups
can write is not exposed for that.  The default trusts no group.

=item sticky_target

True to give the target the pass for the sticky bit that the directories above
it get, when the target is a directory.  The default is false.

=back

Dies when C<$path> is undefined or empty, when an option is not one of these,
when C<trust_group> is not a whole number or an array of them, and on a system
whose files do not have POSIX owners and modes, such as Windows or VMS, rather
than call a path safe there.

=head2 secure

C<($path, upto =E<gt> $top, %option)>.  Changes the modes of C<$path> and of
the directories above it, up to and including C<$top>, so that L</exposed>
finds nothing with the same C<trust_group>.  Returns the paths that it
changed, from the top down, and an empty list when it changed nothing.

It works on the real path of C<$path>, from L<Cwd>, because C<chmod> follows
symbolic links.  For the target, it takes away the write bit of every account,
and the write bit of the group unless C<trust_group> trusts the group.  For
each directory above the target, up to and including C<$top>, that another
account or a group that it does not trust can write, it adds the sticky bit.
That keeps the directory writable for whoever shares it, and stops them
replacing what the caller owns there.  The option C<< private => 1 >> takes
those write bits away from the directories instead.

It changes nothing above C<$top>, and nothing that the effective uid does not
own unless that is root.  So it can fail, and it does all of its checks before
its first change.  It plans every mode first.  Then it runs the check of
L</exposed> on C<$path> as given, with the planned modes in place of the real
ones, so that a directory above C<$top>, a link on the way to the real path,
or an entry that another account owns stops it before anything changes.  Then
it dies if a planned change is to an entry that the effective uid cannot
change.  Only then does it change the modes, from C<$top> down, so that each
parent is safe before its child changes.  Before each change it looks at the
entry again, and dies if it is not the entry that it planned for.  At the end
it runs L</exposed> again, and dies with its reason if the path is still
exposed, so a caller never gets a partial success that looks like a full one.

The options:

=over

=item upto

Required.  A directory that C<$path> is in, or C<$path> itself.  It is the
highest directory that C<secure> may change.

=item trust_group

As for L</exposed>.

=item private

True to take away the write bits of other accounts and of groups that it does
not trust from the directories above the target, rather than to add the sticky
bit.  The default is false.

=back

Dies, having changed nothing, for what L</exposed> dies for, when C<upto> is
missing or is not a directory, when C<$path> is not there or is not in
C<$top>, when the planned modes still leave the path exposed, and when a
planned change is to an entry that the effective uid does not own, unless that
is root.  Dies, after the
changes that it lists, when a C<chmod> fails or an entry changed under it.

The race: between the second look at an entry and the C<chmod>, an account
that can write the parent of that entry could put another entry in its place,
and the C<chmod> would follow it if it is a link.  Going from the top down
closes that for every entry that the caller owns, because its parent is sticky
or closed by then.  It remains for the entries that root owns, and for C<$top>
itself, whose parent C<secure> may not change.

=head2 stat_entry

C<($path)>.  What C<lstat> says about C<$path>.  It is not exported.  The two
functions call it for every entry, so that a test can replace it to give an
entry another owner, which an account that is not root cannot make.

=head2 change_mode

C<($mode, $path)>.  C<chmod> of C<$path> to C<$mode>, and what C<chmod>
returns.  It is not exported.  L</secure> calls it for each change, so that a
test can replace it.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Path-Secure/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-robot

troglodyne-robot <trogbot@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
