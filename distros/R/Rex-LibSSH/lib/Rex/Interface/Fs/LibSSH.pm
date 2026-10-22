# ABSTRACT: Rex filesystem operations via exec channels (no SFTP)

package Rex::Interface::Fs::LibSSH;
our $VERSION = '0.005';
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

    # The pattern is intentionally NOT _q()-wrapped: the remote shell
    # has to expand *, ?, [...] in place. Quoting would suppress globbing.
    # The security-relevant asymmetry: every other path here is _q()-wrapped;
    # glob is the one place we trust the remote shell to parse something
    # beyond a literal token. As a defense against a malicious or malformed
    # pattern reaching this method, reject any character that would let the
    # pattern break out of the command structure beyond what globbing
    # allows. Legitimate glob patterns contain only path bytes and the
    # glob meta-chars *, ?, [...], {a,b}, /, ., -, _, ~.
    die "LibSSH glob: pattern contains NUL byte\n"
        if defined $pattern && index( $pattern, "\0" ) >= 0;
    die "LibSSH glob: pattern contains shell metacharacter outside glob syntax\n"
        if defined $pattern
        && $pattern =~ /[\0';|&<>`$()\n\r\\]/;

    # Like perl's glob (stock Rex::Interface::Fs::SSH): braces expand
    # locally and every alternative is returned; only an alternative with
    # a wildcard (or a ~) goes to the remote shell, where unmatched ones
    # yield nothing. A plain path is returned as given, existing or not.
    my @result;
    for my $alt ( _brace_expand($pattern) ) {
        if ( $alt !~ /[*?\[~]/ ) {
            push @result, $alt;
            next;
        }

        # Blanks stay part of one word (backslash itself was rejected
        # above, so this cannot unescape anything). The shell leaves
        # unmatched wildcards verbatim, hence the -e/-L test; names are
        # NUL-separated so whitespace in file names survives.
        ( my $word = $alt ) =~ s/([ \t])/\\$1/g;
        my $out = $self->_run(
            qq{for f in $word; do if [ -e "\$f" ] || [ -L "\$f" ]; then printf '%s\\0' "\$f"; fi; done}
        );
        push @result, grep { length } split /\0/, $out
            if defined $out && length $out;
    }
    return @result;
}

# Expand the first {a,b,...} group (nested groups recurse); an unbalanced
# or comma-less group is literal, as in perl's glob.
sub _brace_expand {
    my ($str) = @_;
    my $start = index $str, '{';
    return $str if $start < 0;

    my ( $depth, @comma, $end ) = (0);
    for my $i ( $start .. length($str) - 1 ) {
        my $c = substr $str, $i, 1;
        if    ( $c eq '{' ) { $depth++ }
        elsif ( $c eq '}' ) { if ( --$depth == 0 ) { $end = $i; last } }
        elsif ( $c eq ',' && $depth == 1 ) { push @comma, $i }
    }
    return $str if !defined $end || !@comma;

    my ( $pre, $post ) = ( substr( $str, 0, $start ), substr( $str, $end + 1 ) );
    my @alts;
    my $from = $start + 1;
    for my $to ( @comma, $end ) {
        push @alts, substr $str, $from, $to - $from;
        $from = $to + 1;
    }
    return map { _brace_expand( $pre . $_ . $post ) } @alts;
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

# Shell-quote a single path component.
#
# Single-quote wrap with '\''-escaping of embedded single quotes is the
# canonical POSIX-safe form. Inside single quotes the shell performs no
# expansion, so this defends against spaces, $, `, \, newlines and the
# empty string automatically.
#
# NUL (\0) cannot be represented in argv (libc terminates arguments on
# NUL), so reject it loudly rather than letting libssh silently truncate.
sub _q {
    my ($path) = @_;
    die "LibSSH _q: path contains NUL byte\n"
        if defined $path && index( $path, "\0" ) >= 0;
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

version 0.005

=head1 DESCRIPTION

L<Rex::Interface::Fs::LibSSH> implements Rex's filesystem interface using
SSH exec channels instead of SFTP. Every operation runs a small shell
command on the remote host via L<Net::LibSSH>.

This makes it suitable for servers that have no SFTP subsystem — minimal
containers, embedded systems, or any host where C<set connection =E<gt>
'OpenSSH'> would crash with C<Can't call method "stat" on an undefined
value>.

=head1 LIMITATIONS

This class does not route filesystem operations through
L<Rex::Interface::Fs::Sudo>. C<_run> hardcodes
C<Rex::Interface::Exec-E<gt>create('LibSSH')> rather than letting
C<create()> resolve via L<Rex::Interface::Connection::LibSSH/get_connection_type>,
so operations reached from inside this class never get the Sudo wrap
that C<get_connection_type> would normally select under
C<L<Rex::is_sudo>>. This is a known limitation, not a bug: switching
to the resolving form would change behaviour for every existing caller.
Callers that need sudo-wrapped filesystem operations should use
L<Rex::Interface::Fs::Sudo> explicitly.

C<upload> and C<download> slurp the entire file into memory on both
ends before sending or returning. This is fine for config files but
not appropriate for large files. A future implementation could stream
through L<Net::LibSSH::Channel::read> with an explicit length —
C<read(undef)> reads zero bytes, so callers that pass through an
optional C<$len> must default to slurping rather than passing it
through unchanged.

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
