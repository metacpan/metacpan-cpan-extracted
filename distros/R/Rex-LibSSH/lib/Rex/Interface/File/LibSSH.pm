# ABSTRACT: Rex remote file handle via Net::LibSSH exec channels

package Rex::Interface::File::LibSSH;
our $VERSION = '0.002';
use strict;
use warnings;

use Rex;
use Rex::Logger;
use Rex::Config;
use Rex::Interface::File::Base;
use base qw(Rex::Interface::File::Base);

sub new {
    my ( $that, %args ) = @_;
    my $proto = ref($that) || $that;
    return bless {%args}, $proto;
}

sub open {
    my ( $self, $mode, $path ) = @_;

    Rex::Logger::debug("LibSSH File::open $mode $path");

    $self->{path} = $path;
    $self->{mode} = $mode;

    my $ssh = Rex::is_ssh()
        or die "LibSSH File: no active SSH connection";

    my $qpath = _q($path);

    if ( $mode eq '>' || $mode eq '>>' ) {
        my $cmd = $mode eq '>' ? "cat > $qpath" : "cat >> $qpath";
        my $ch  = $ssh->channel or die "LibSSH File: failed to open channel";
        $ch->exec($cmd);
        $self->{ch}  = $ch;
        $self->{buf} = '';
    }
    elsif ( $mode eq '<' ) {
        my $ch = $ssh->channel or die "LibSSH File: failed to open channel";
        $ch->exec("cat $qpath");
        $self->{buf} = $ch->read;
        $self->{pos} = 0;
        $ch->close;
    }
    else {
        die "LibSSH File: unsupported mode '$mode'";
    }

    return 1;
}

sub read {
    my ( $self, $len ) = @_;
    return undef unless defined $self->{buf};

    my $chunk = substr( $self->{buf}, $self->{pos}, $len );
    $self->{pos} += length($chunk);
    return $chunk;
}

sub write {
    my ( $self, $buf ) = @_;

    utf8::encode($buf)
        if Rex::Config->get_write_utf8_files && utf8::is_utf8($buf);

    $self->{ch}->write($buf);
}

sub seek {
    my ( $self, $pos ) = @_;
    $self->{pos} = $pos if defined $self->{pos};
}

sub close {
    my ($self) = @_;
    if ( $self->{ch} ) {
        $self->{ch}->send_eof;
        $self->{ch}->read;    # drain
        $self->{ch}->close;
        undef $self->{ch};
    }
}

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

Rex::Interface::File::LibSSH - Rex remote file handle via Net::LibSSH exec channels

=head1 VERSION

version 0.002

=head1 DESCRIPTION

L<Rex::Interface::File::LibSSH> implements Rex's remote file handle
interface using L<Net::LibSSH> exec channels.

Write modes (C<E<gt>> and C<E<gt>E<gt>>) open a channel running C<cat
E<gt>> or C<cat E<gt>E<gt>> on the remote. Writes are streamed directly
over the SSH connection and committed when C<close()> is called.

Read mode (C<E<lt>>) slurps the entire file via C<cat> and buffers it
locally; C<read()> and C<seek()> operate on the local buffer.

=head1 SEE ALSO

L<Rex::Interface::Connection::LibSSH>, L<Rex::Interface::Fs::LibSSH>

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
