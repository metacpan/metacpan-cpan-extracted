# ABSTRACT: Rex filesystem operations via exec channels (no SFTP)

package Rex::Interface::Fs::LibSSH;
our $VERSION = '0.002';
use strict;
use warnings;

use Rex;
use Rex::Logger;
use Rex::Interface::Exec;
use Rex::Interface::Fs::Base;
use base qw(Rex::Interface::Fs::Base);

sub new {
    my ( $that, %args ) = @_;
    my $proto = ref($that) || $that;
    return bless {%args}, $proto;
}

sub _run {
    my ( $self, $cmd ) = @_;
    my $exec = Rex::Interface::Exec->create('LibSSH');
    return $exec->exec($cmd);
}

sub is_file {
    my ( $self, $path ) = @_;
    $path = _q($path);
    $self->_run("test -f $path || test -c $path || test -b $path || test -p $path || test -S $path");
    return $? == 0 ? 1 : undef;
}

sub is_dir {
    my ( $self, $path ) = @_;
    $path = _q($path);
    $self->_run("test -d $path");
    return $? == 0 ? 1 : undef;
}

sub is_readable {
    my ( $self, $path ) = @_;
    $path = _q($path);
    $self->_run("test -r $path");
    return $? == 0 ? 1 : undef;
}

sub is_writable {
    my ( $self, $path ) = @_;
    $path = _q($path);
    $self->_run("test -w $path");
    return $? == 0 ? 1 : undef;
}

sub readlink {
    my ( $self, $path ) = @_;
    $path = _q($path);
    my $out = $self->_run("readlink $path");
    chomp $out;
    return $out;
}

sub stat {
    my ( $self, $path ) = @_;
    $path = _q($path);

    # %a = octal perms, %s = size, %u = uid, %g = gid, %X = atime, %Y = mtime
    my $out = $self->_run("stat -c '%a %s %u %g %X %Y' $path 2>/dev/null");
    return undef unless $out && $out =~ /\S/;
    chomp $out;
    my ( $mode, $size, $uid, $gid, $atime, $mtime ) = split /\s+/, $out;
    return (
        mode  => sprintf( '%04o', oct($mode) ),
        size  => $size  + 0,
        uid   => $uid   + 0,
        gid   => $gid   + 0,
        atime => $atime + 0,
        mtime => $mtime + 0,
    );
}

sub ls {
    my ( $self, $path ) = @_;
    $path = _q($path);
    my $out = $self->_run("ls -1a $path 2>/dev/null");
    return () unless defined $out && length $out;
    return grep { $_ ne '.' && $_ ne '..' } split /\n/, $out;
}

sub glob {
    my ( $self, $pattern ) = @_;
    my $out = $self->_run("echo $pattern");
    chomp $out;
    return split /\s+/, $out;
}

sub mkdir {
    my ( $self, $path ) = @_;
    $path = _q($path);
    $self->_run("mkdir -p $path");
    return $? == 0 ? 1 : 0;
}

sub rename {
    my ( $self, $from, $to ) = @_;
    $self->_run( 'mv ' . _q($from) . ' ' . _q($to) );
    return $? == 0 ? 1 : 0;
}

sub unlink {
    my ( $self, @files ) = @_;
    for my $f (@files) {
        $self->_run( 'rm -f ' . _q($f) );
    }
}

sub upload {
    my ( $self, $local, $remote ) = @_;
    $remote = _q($remote);

    my $content = do {
        local $/;
        open( my $fh, '<:raw', $local ) or die "upload: cannot read $local: $!";
        <$fh>;
    };

    my $ssh = Rex::is_ssh()
        or die "LibSSH upload: no active SSH connection";

    my $ch = $ssh->channel or die "LibSSH upload: failed to open channel";
    $ch->exec("cat > $remote");
    $ch->write($content);
    $ch->send_eof;
    $ch->read;    # drain any output
    my $exit = $ch->exit_status;
    $ch->close;

    die "upload: writing to $remote failed (exit $exit)" if $exit != 0;
}

sub download {
    my ( $self, $remote, $local ) = @_;
    $remote = _q($remote);

    my $ssh = Rex::is_ssh()
        or die "LibSSH download: no active SSH connection";

    my $ch = $ssh->channel or die "LibSSH download: failed to open channel";
    $ch->exec("cat $remote");
    my $content = $ch->read;
    my $exit    = $ch->exit_status;
    $ch->close;

    die "download: reading $remote failed (exit $exit)" if $exit != 0;

    open( my $fh, '>:raw', $local ) or die "download: cannot write $local: $!";
    print $fh $content;
    close $fh;
}

# Shell-quote a single path component
sub _q {
    my ($path) = @_;
    $path =~ s/'/'"'"'/g;
    return "'$path'";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Interface::Fs::LibSSH - Rex filesystem operations via exec channels (no SFTP)

=head1 VERSION

version 0.002

=head1 DESCRIPTION

L<Rex::Interface::Fs::LibSSH> implements Rex's filesystem interface using
SSH exec channels instead of SFTP. Every operation runs a small shell
command on the remote host via L<Net::LibSSH>.

This makes it suitable for servers that have no SFTP subsystem — minimal
containers, embedded systems, or any host where C<set connection =E<gt>
'OpenSSH'> would crash with C<Can't call method "stat" on an undefined
value>.

=head1 SEE ALSO

L<Rex::Interface::Connection::LibSSH>, L<Rex::Interface::File::LibSSH>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-libssh/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
