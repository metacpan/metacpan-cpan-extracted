package Proc::Find;

our $DATE = '2019-11-23'; # DATE
our $VERSION = '0.051'; # VERSION

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

sub _match {
    my ($target, $cond, $is_numeric) = @_;
    if (ref $cond eq 'Regexp') {
        return 0 unless $target =~ $cond;
    } elsif (ref $cond eq 'ARRAY') {
        return 0 unless grep { $is_numeric ? $target == $_ : $target eq $_ } @$cond;
    } else {
        return 0 unless $is_numeric ? $target == $cond : $target eq $cond;
    }
    1;
}

sub find_proc {
    my %args = @_;

    my @unknown_args = grep {!/\A(
                                   filter|
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
            if (defined $args{filter}) {
                local $_ = $p;
                last COND unless $args{filter}->($p);
            }
            if (defined $args{pid})      { last COND unless _match($p->{pid}     , $args{pid}     , 1) }
            if (defined $args{name})     { last COND unless _match($p->{name}    , $args{name}    ) }
            if (defined $args{cmndline}) { last COND unless _match($p->{cmndline}, $args{cmndline}) }
            if (defined $args{exec}) {
                my $exec = $p->{exec} // '';
                unless ($args{exec} =~ m!/!) {
                    $exec =~ s!.+/!!;
                }
                last COND unless _match($exec, $args{exec});
            }
            if (defined($args{user}) || defined($args{uid})) {
                my $cond = $args{user} // $args{uid};
                if ($cond eq 'Regexp') {
                    last COND unless _match($p->{uid}, $cond, 1); # XXX allow matching against username?
                } else {
                    my @uids;
                    for my $val (ref $cond eq 'ARRAY' ? @$cond : $cond) {
                        if ($val =~ /\A\d+\z/) {
                            push @uids, $val;
                        } else {
                            my @pw = getpwnam($val);
                            push @uids, @pw ? $pw[2] : -1;
                        }
                    }
                    last COND unless _match($p->{uid}, \@uids, 1);
                }
            }
            if (defined($args{euser}) || defined($args{euid})) {
                my $cond = $args{euser} // $args{euid};
                if ($cond eq 'Regexp') {
                    last COND unless _match($p->{euid}, $cond, 1); # XXX allow matching against username?
                } else {
                    my @uids;
                    for my $val (ref $cond eq 'ARRAY' ? @$cond : $cond) {
                        if ($val =~ /\A\d+\z/) {
                            push @uids, $val;
                        } else {
                            my @pw = getpwnam($val);
                            push @uids, @pw ? $pw[2] : -1;
                        }
                    }
                    last COND unless _match($p->{euid}, \@uids, 1);
                }
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

This document describes version 0.051 of Proc::Find (from Perl distribution Proc-Find), released on 2019-11-23.

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

=item * filter => code

Filter by a coderef. The coderef will receive the process record (hashref).

=item * pid => int|array[int]|regex

Find by PID. Note that if you only want to check whether a PID exists, there are
cheaper methods (see L</"SEE ALSO">).

=item * name => str|array[str]|regex

Match against process' "name". Name is taken from the first word of the
cmndline, with path stripped.

If value is regex, will do a regex match instead of exact string comparison.

Example:

 find_proc(name => "bash")
 find_proc(name => qr/^(Thunar|dolphin|konqueror)$/)

=item * cmndline => str|array[str]|regex

Match against full cmndline.

If value is regex, will do a regex match instead of exact string comparison.

=item * exec => str|array[str]|regex

Match against program (executable/binary)'s path. If value does not contain a
path separator character, will be matched against program's name.

Example:

 find_proc(exec => "perl")          # find any perl
 find_proc(exec => "/usr/bin/perl") # find only a specific perl

=item * user => int|str|array[int|str]|regex

List processes owned by specified user/UID.

If given a username which does not exist, will simply not match.

=item * uid => int|str|array[int|str]|regex

Same as C<user>.

=item * euser => int|str|array[int|str]|regex

List processes running as certain effective user/UID (will look against
C<euid>).

If given a username which does not exist, will simply not match.

=item * euid => int|str|array[int|str]|regex

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Proc-Find>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Proc-Find>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Proc-Find>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Proc::Exists> can be used to check if one or more PIDs exist. If you are only
concerned with POSIX systems, you can just do C<kill 0, $pid> to accomplish the
same.

B<pgrep> Unix command.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
