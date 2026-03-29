# ABSTRACT: Rex SSH connection via Net::LibSSH (no SFTP required)

package Rex::Interface::Connection::LibSSH;
our $VERSION = '0.002';
use strict;
use warnings;

use Net::LibSSH;
use Rex::Logger;
use Rex::Config;
use Rex::Helper::IP;
use Rex::Interface::Connection::Base;
use base qw(Rex::Interface::Connection::Base);

sub new {
    my ( $that, %args ) = @_;
    my $self = $that->SUPER::new(%args);
    return $self;
}

sub connect {
    my ( $self, %opt ) = @_;

    my $server   = $opt{server};
    my $port     = $opt{port}     || Rex::Config->get_port( server => $server )    || 22;
    my $timeout  = $opt{timeout}  || Rex::Config->get_timeout( server => $server ) || 10;
    my $user     = $opt{user};
    my $password = $opt{password};
    my $privkey  = $opt{private_key};
    my $auth     = $opt{auth_type} // 'key';

    $self->{server}        = $server;
    $self->{is_sudo}       = $opt{sudo};
    $self->{__auth_info__} = \%opt;

    ( $server, $port ) = Rex::Helper::IP::get_server_and_port( $server, $port );

    Rex::Logger::debug("LibSSH: connecting to $server:$port as $user");

    my $ssh = Net::LibSSH->new;
    $ssh->option( host    => "$server" );
    $ssh->option( port    => $port     );
    $ssh->option( user    => $user     ) if defined $user;
    $ssh->option( timeout => $timeout  );
    $ssh->option( strict_hostkeycheck => 0 );

    unless ( $ssh->connect ) {
        Rex::Logger::info( "LibSSH: can't connect to $server: " . ( $ssh->error // '' ), 'warn' );
        $self->{connected} = 0;
        return;
    }

    # Reset timeout to 0 (infinite) after connect — the connect timeout must
    # be short so unreachable hosts fail fast, but channel reads (e.g. apt-get
    # with DKMS build) must not time out. libssh's timeout option affects both.
    $ssh->option( timeout => 0 );

    $self->{connected} = 1;

    # Try authentication in order
    my $authed = 0;

    if ( $auth eq 'pass' && defined $password ) {
        $authed = $ssh->auth_password($password);
    }
    elsif ( $auth eq 'key' && defined $privkey ) {
        $authed = $ssh->auth_publickey($privkey);
        $authed ||= $ssh->auth_agent if !$authed;
    }
    else {
        # auto: agent first, then key file, then password
        $authed = $ssh->auth_agent;
        $authed ||= $ssh->auth_publickey($privkey) if !$authed && $privkey;
        $authed ||= $ssh->auth_password($password) if !$authed && $password;
    }

    unless ($authed) {
        Rex::Logger::info( "LibSSH: authentication failed for $user\@$server: "
              . ( $ssh->error // '' ), 'warn' );
        $self->{auth_ret} = 0;
        return;
    }

    Rex::Logger::debug("LibSSH: authenticated $user\@$server");
    $self->{ssh}      = $ssh;
    $self->{auth_ret} = 1;
}

sub reconnect {
    my ($self) = @_;
    Rex::Logger::debug("LibSSH: reconnecting");
    $self->connect( %{ $self->{__auth_info__} } );
}

sub disconnect {
    my ($self) = @_;
    if ( $self->{ssh} ) {
        $self->{ssh}->disconnect;
        undef $self->{ssh};
    }
    return 1;
}

sub error {
    my ($self) = @_;
    return $self->{ssh} ? $self->{ssh}->error : undef;
}

sub get_connection_object {
    my ($self) = @_;
    return $self->{ssh};
}

sub get_fs_connection_object {
    my ($self) = @_;
    return $self;    # exec-based Fs needs no separate SFTP object
}

sub is_connected {
    my ($self) = @_;
    return $self->{connected} // 0;
}

sub is_authenticated {
    my ($self) = @_;
    return $self->{auth_ret} // 0;
}

sub get_connection_type {
    my ($self) = @_;
    return Rex::is_sudo() ? 'Sudo' : 'LibSSH';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Interface::Connection::LibSSH - Rex SSH connection via Net::LibSSH (no SFTP required)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # In your Rexfile
  use Rex -feature => ['1.4'];
  set connection => 'LibSSH';

=head1 DESCRIPTION

L<Rex::Interface::Connection::LibSSH> provides a Rex SSH connection backed
by L<Net::LibSSH> (libssh). Unlike the C<OpenSSH> connection type, it does
not require an SFTP subsystem on the remote server — all file operations are
performed via exec channels.

Use this connection type on servers where the SSH daemon has no SFTP
subsystem configured (e.g. minimal containers, embedded systems).

=head1 SEE ALSO

L<Rex::Interface::Fs::LibSSH>, L<Net::LibSSH>

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
