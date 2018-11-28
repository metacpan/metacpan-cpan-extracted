package Tail::Tool::File;

# Created on: 2010-10-25 11:11:38
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use Scalar::Util qw/openhandle/;
use English qw/ -no_match_vars /;
use AnyEvent;

our $VERSION = version->new('0.4.8');

has name => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'The name of a file to be watched',
);
has remote => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    init_arg      => undef,
    documentation => 'Flags that the file is located on a remote server',
);
has cmd => (
    is            => 'rw',
    isa           => 'Str',
    documentation => '',
);
has pid => (
    is            => 'rw',
    isa           => 'Str',
    documentation => '',
);
has handle => (
    is            => 'rw',
    isa           => 'FileHandle',
    clearer       => 'clear_handle',
    documentation => 'The opened filehandle of name',
);
has size => (
    is            => 'rw',
    isa           => 'Int',
    init_arg      => undef,
    default       => 0,
    documentation => 'The size of file when last read',
);
has pause => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => 'Flags not to display any lines from the file',
);
has auto_unpause => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    init_arg      => undef,
    documentation => 'If a file was missing moved or deleted this flags that tailing should be restarted when the file reappears',
);
has no_inotify => (
    is            => 'ro',
    isa           => 'Bool',
    documentation => 'Flags not to use the INotify the file (can be useful when a file is on a network file system like sshfs)',
);
has watcher => (
    is            => 'rw',
    init_arg      => undef,
    clearer       => 'clear_watcher',
    documentation => 'This is the event watcher ojbect handle',
);
has runner => (
    is            => 'rw',
    isa           => 'CodeRef',
    documentation => 'This is the subroutine reference that should be run with each file change',
);
has started => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    init_arg      => undef,
    documentation => 'Flags that tailing has started and not to limit the number of lines any more',
);
has stat_time => (
    is            => 'rw',
    isa           => 'Int',
    default       => time,
    init_arg      => undef,
    documentation => 'The last time a file was stat()ed',
);
has stat_period => (
    is            => 'rw',
    isa           => 'Int',
    default       => 1,
    documentation => 'The time period between checks if a file has been moved or deleted',
);
has tailer => (
    is            => 'rw',
    isa           => 'Tail::Tool',
    documentation => 'The object that this file belongs to',
);
has restart => (
    is      => 'ro',
    default => 0,
);

my $inotify;
my $watcher;
sub watch {
    my ($self, $lines) = @_;

    return 0 if $self->pause;
    return $self->watcher if $self->watcher;

    $self->_get_file_handle();

    if ( !defined $inotify ) {
        eval { require Linux::Inotify2 };
        if ($EVAL_ERROR) {
            $inotify = 0;
        }
        else {
            $inotify = Linux::Inotify2->new;
        }
    }

    my $w;
    if ( $self->name ne '-' && !$self->remote  && $inotify && !$self->no_inotify ) {
        # IN_MODIFY | IN_ALL_EVENTS & ~IN_ACCESS
        $w = $inotify->watch( $self->name, Linux::Inotify2::IN_ALL_EVENTS(), sub { $self->run } );
        if ( !$watcher ) {
            $watcher = AE::io $inotify->fileno, 0, sub { $inotify->poll };
        }
    }
    elsif ( $self->name eq '-' ) {
        $self->started(1);
        $w = AE::io \*STDIN, 0, sub {
            if ( !defined fileno \*STDIN ) {
                close STDIN;
            }
            $self->run
        };
        # TODO work out how to end if STDIN closed
    }
    else {
        $w = AE::timer 0, 1, sub { $self->run };
    }

    $self->watcher($w);

    return $self->watcher;
}

sub run {
    my ($self, $first) = @_;
    $self->runner->($self, $first);
}

sub get_line {
    my ($self) = @_;
    my $fh = $self->_get_file_handle;

    return if $self->pause;

    if ( !$self->remote ) {
        my $size = -s $self->name || 0;
        if ( $size < $self->size ) {
            warn $self->name . " was truncated!\n";
            close $fh;
            $self->clear_handle;
            $fh = $self->_get_file_handle;
        }
        elsif ($self->restart) {
            # reset file handle
            seek $fh, 0, 1;
        }
        else {
            $self->clear_watcher;
        }
        $self->size($size || 0);
    }

    my @lines = <$fh>;

    # re-check the stat time of the file to make sure that the file has not been rotated
    if ( !$self->remote && !@lines && time > $self->stat_time + $self->stat_period * 60 ) {
        $self->stat_time(time);
        # TODO why is this being run if the file has finished? Should not be run for STDIN reading
        my @stat_file   = stat $self->name;
        my @stat_handle = stat $fh;
        # check if the file handle's modified time is not the same as files'
        if ( !defined $stat_handle[1] || !defined $stat_file[1] || $stat_handle[1] != $stat_file[1] ) {
            # close and reopen file incase the file has been rotated
            close $fh;
            $self->_get_file_handle();
        }
    }
    return @lines;
}

sub _get_file_handle {
    my ($self) = @_;

    my $fh = $self->handle;
    if ( $self->name eq '-' ) {
        if ( !$fh ) {
            $self->handle(\*STDIN);
        }
        elsif ( !openhandle($fh) ) {
            $self->clear_watcher;
        }
        return $self->handle;
    }

    if ( $self->remote || $self->name =~ m{^s(sh|cp)://}xms ) {
        $self->remote(1);
        return if $self->pause;

        my $host_re = qr/( [\w.-]+ )/xms;
        my $user_re = qr/([^@]+) [@]/xms;
        my $port_re = qr/[:] (\d*)/xms;
        my $file_re = qr/(.*)/xms;
        my $ssh_re = qr{^ssh://(?: $user_re )? $host_re (?: $port_re )? / $file_re$}xms;
        my $scp_re = qr{^scp://(?: $user_re )? $host_re $port_re $file_re$}xms;
        my $re = $self->name =~ /^ssh/ ? $ssh_re : $scp_re;

        my ($user, $host, $port, $file) = $self->name =~ m{$re}xms;

        if ( !$fh ) {
            my $cmd = sprintf "ssh %s$host %s 'tail -f -n %d %s'",
               ( $user         ? "$user\@"            : '' ),
               ( $port         ? "-P $port"           : '' ),
               ( $self->tailer ? $self->tailer->lines : 10 ),
               _shell_quote($file);

            if ( my $pid = open $fh, '-|', $cmd ) {
                $fh->blocking(0);
                $self->pid($pid);
                $self->handle($fh);
            }
            else {
                $self->pause(1);
                warn "Could not tail remote file (" . $self->name . "): $!";
            }
        }
    }
    elsif ( !$fh || tell $fh == -1 ) {
        if ( open $fh, '<', $self->name ) {
            $self->handle($fh);
            $self->size(-s $self->name);
        }
        else {
            warn "Could not open '".$self->name."': $!\n" if !$self->auto_unpause;
            $self->pause(1);
            $self->auto_unpause(1);
        }
    }

    return $fh;
}

sub _shell_quote {
    my ($file) = @_;
    $file =~ s{ ( [^\w\-./?*] ) }{\\$1}gxms;

    return $file;
}

1;

__END__

=head1 NAME

Tail::Tool::File - Looks after individual files

=head1 VERSION

This documentation refers to Tail::Tool::File version 0.4.8.

=head1 SYNOPSIS

    use Tail::Tool::File;

    # Create a new Tail::Tool::File object
    my $file = Tail::Tool::File->new( '/my/file' );

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<watch ()>

Return: AnyEvent watcher or Linux::Inotify2 watcher

Description: Creates the watcher for the file if the file exists and is not
paused.

=head2 C<run ($first)>

Param: C<$first> - bool - Specifies that this is the first time run has been
called.

Description: Runs the the file event.

=head2 C<get_line ()>

Description: Gets any unread lines from the file.

=head1 DIAGNOSTICS

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gamil.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gamil.com)
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia, 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
