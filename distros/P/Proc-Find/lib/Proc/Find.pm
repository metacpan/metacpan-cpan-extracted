package Proc::Find;

our $DATE = '2015-01-03'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use List::Util qw(first);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       find_proc
                       find_any_proc
                       find_all_proc
                       proc_exists
               );

our $CACHE = 0;

my $_table_res;
sub _table {
    state $pt = do {
        require Proc::ProcessTable;
        Proc::ProcessTable->new;
    };
    if (!$CACHE || !$_table_res) {
        $_table_res = $pt->table;
    }
    $_table_res;
}

sub find_proc {
    my %args = @_;

    my @unknown_args = grep {!/\A(
                                   pid|name|cmndline|exec|
                                   user|uid|euser|euid|
                                   table|detail|
                                   result_max
                               )\z/x} keys %args;
    die "Unknown arguments to find_proc(): ".join(", ", @unknown_args)
        if @unknown_args;

    my $table = $args{table} // _table();

    my ($arg_uid, $arg_euid);

    my @res;
    for my $p (@$table) {
        # create extra fields
        $p->{name} = $p->{cmndline};
        $p->{name} =~ s/\s.*//;
        $p->{name} =~ s!.+/!!;

        my $cond = 0;
      COND:
        {
            if (defined $args{pid}) {
                last COND unless $p->{pid} == $args{pid};
            }
            if (defined $args{name}) {
                if (ref($args{name}) eq 'Regexp') {
                    last COND unless $p->{name} =~ $args{name};
                } else {
                    last COND unless $p->{name} eq $args{name};
                }
            }
            if (defined $args{cmndline}) {
                if (ref($args{cmndline}) eq 'Regexp') {
                    last COND unless $p->{cmndline} =~ $args{cmndline};
                } else {
                    last COND unless $p->{cmndline} eq $args{cmndline};
                }
            }
            if (defined $args{exec}) {
                my $exec = $p->{exec} // '';
                unless ($args{exec} =~ m!/!) {
                    $exec =~ s!.+/!!;
                }
                last COND unless $exec eq $args{exec};
            }
            if (defined($args{user}) || defined($args{uid})) {
                my $val = $args{user} // $args{uid};
                my $uid;
                if ($val =~ /\A\d+\z/) {
                    $uid = $val;
                } else {
                    if (!defined($arg_uid)) {
                        my @pw = getpwnam($val);
                        $arg_uid = @pw ? $pw[2] : -1;
                    }
                    $uid = $arg_uid;
                }
                last COND unless $p->{uid} == $uid;
            }
            if (defined($args{euser}) || defined($args{euid})) {
                my $val = $args{euser} // $args{euid};
                my $euid;
                if ($val =~ /\A\d+\z/) {
                    $euid = $val;
                } else {
                    if (!defined($arg_euid)) {
                        my @pw = getpwnam($val);
                        $arg_euid = @pw ? $pw[2] : -1;
                    }
                    $euid = $arg_euid;
                }
                last COND unless $p->{euid} == $euid;
            }

            $cond = 1;
        }

        $cond = !$cond if $args{inverse};
        next unless $cond;

        if ($args{detail}) {
            push @res, { %$p }; # unbless
        } else {
            push @res, $p->{pid};
        }

        if (defined $args{result_max}) {
            last if @res >= $args{result_max};
        }
    }

    \@res;
}

sub proc_exists {
    @{ find_proc(@_, result_max=>1) } > 0 ? 1:0;
}

sub find_any_proc {
    return [] unless @_;

    my $detail = $_[0]->{detail};
    my $table = $_[0]->{table} // _table();

    my @allres;
    for my $crit (@_) {
        my $res = find_proc(%$crit, table=>$table, detail=>$detail);
      ITEM:
        for my $item (@$res) {
            # skip duplicate process
            if ($detail) {
                next ITEM if first {$_->{pid} == $res->{pid}} @allres;
            } else {
                next ITEM if first {$_ == $res} @allres;
            }
            push @allres, @$res;
        }
    }

    \@allres;
}

sub find_all_proc {
    return [] unless @_;

    my $detail = $_[0]->{detail};
    my $table = $_[0]->{table} // _table();

    my @allres;
  CRIT:
    for my $crit (@_) {
        my $res = find_proc(%$crit, table=>$table);
        if (!@allres) {
            push @allres, @$res;
            next CRIT;
        }
        @allres = grep {
            my $p = $_;
            $detail ?
                ((first {$p->{pid} == $_->{pid}} @$res) ? 1:0) :
                ((first {$p == $_} @$res) ? 1:0)
        } @allres;
    }

    \@allres;
}

1;
# ABSTRACT: Find processes by name, PID, or some other attributes

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::Find - Find processes by name, PID, or some other attributes

=head1 VERSION

This document describes version 0.04 of Proc::Find (from Perl distribution Proc-Find), released on 2015-01-03.

=head1 SYNOPSIS

 use Proc::Find qw(find_proc proc_exists);

 # list all of a user's processes
 my $procs = find_proc(user=>'ujang', detail=>1);

 # check if a program is running
 die "Sorry, xscreensaver is not running"
     unless proc_exists(name=>'xscreensaver').

=head1 DESCRIPTION

This module provides a simple routine, C<proc_exists()>, to check a process'
existence by name, something that is commonly done in shell scripts using:

 ps ax | grep name
 pgrep name

and also some routines, C<find_*()>, to list processes matching some criteria.

=head1 VARIABLES

=head2 $Proc::Find::CACHE => bool (default: 0)

If set to true, will cache the call to C<Proc::ProcessTable>'s C<table()> so
subsequent invocation to C<find_proc()> or C<proc_exists> doesn't have to call
the method again. But this also means that the process check/listing will be
done on a past/stale process table.

=head1 FUNCTIONS

=head2 find_proc(%args) => \@pids (or \@procs)

Find process by name, PID, or some other attributes. Return an arrayref of
PID's, or an empty arrayref if none match the criteria.

Currently use L<Proc::ProcessTable> to list the processes.

Arguments:

=over

=item * pid => int

Find by PID. Note that if you only want to check whether a PID exists, there are
cheaper methods (see L</"SEE ALSO">).

=item * name => str|regex

Match against process' "name". Name is taken from the first word of the
cmndline, with path stripped.

If value is regex, will do a regex match instead of exact string comparison.

Example:

 find_proc(name => "bash")
 find_proc(name => qr/^(Thunar|dolphin|konqueror)$/)

=item * cmndline => str|regex

Match against full cmndline.

If value is regex, will do a regex match instead of exact string comparison.

=item * exec => str

Match against program (executable/binary)'s path. If value does not contain a
path separator character, will be matched against program's name.

Example:

 find_proc(exec => "perl")          # find any perl
 find_proc(exec => "/usr/bin/perl") # find only a specific perl

=item * user => int|str

List processes owned by specified user/UID.

If given a username which does not exist, will simply not match.

=item * uid => int|str

Same as C<user>.

=item * euser => int|str

List processes running as certain effective user/UID (will look against
C<euid>).

If given a username which does not exist, will simply not match.

=item * euid => int|str

Same as C<euser>.

=item * inverse => bool

If set to true, then will return all processes I<not> matching the criteria.

=item * table => obj

Supply result from C<Proc::ProcessTable> object's C<table()>. This can be used
to reuse the C<table()> cached result instead of repeatedly call C<table()> on
every invocation.

See also C<$Proc::Find::CACHE>.

=item * detail => bool (default: 0)

Instead of returning just the PID for each result, return a hash (record) of
process information instead. Currently this is just the entry from
C<Proc::ProcTable> object's C<table()> result.

=back

=head2 proc_exists(%args) => bool

Shortcut for:

 @{ find_proc(%args) } > 0

=head2 find_all_proc(\%args, \%args2, ...) => \@pids (or \@procs)

Given multiple criteria, perform an AND search. Will only call
C<Proc::ProcessTable>'s C<table()> method once.

 # find all processes matching mutiple criteria (although the same thing can
 # also be accomplished by find_proc() and combining the criteria)
 find_all_proc([{name=>'mplayer'}, {cmndline=>qr/mp3/}]);

=head2 find_any_proc(\%args, \%args2, ...) => \@pids (or \@procs)

Given multiple criteria, perform an OR search. Will only call
C<Proc::ProcessTable>'s C<table()> method once.

 # find all processes belonging to either user
 find_any_proc([{user=>'ujang'}, {user=>'titin'}]);

=head1 SEE ALSO

L<Proc::Exists> can be used to check if one or more PIDs exist. If you are only
concerned with POSIX systems, you can just do C<kill 0, $pid> to accomplish the
same.

B<pgrep> Unix command.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Proc-Find>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Proc-Find>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Proc-Find>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
