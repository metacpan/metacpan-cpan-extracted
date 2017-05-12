package Net::Scan::SSH::Server::SupportedAuth;

use strict;
use warnings;
use Carp;

our $VERSION = '0.02';

use Net::SSH::Perl::Kex;
use Net::SSH::Perl::Auth;
our %AUTH_IF;
while (my ($a, $b) = each %Net::SSH::Perl::Auth::AUTH) {
    $AUTH_IF{ lc($a) } = 1<<$b;
}
$AUTH_IF{publickey} = $AUTH_IF{rsa}; # alias
our @EXPORT_OK   = qw(%AUTH_IF);
our %EXPORT_TAGS = ( flag => [qw(%AUTH_IF)] );

BEGIN {
    my $debug_flag = $ENV{SMART_COMMENTS} || $ENV{SMART_COMMENT} || $ENV{SMART_DEBUG} || $ENV{SC};
    if ($debug_flag) {
        my @p = map { '#'x$_ } ($debug_flag =~ /([345])\s*/g);
        use UNIVERSAL::require;
        Smart::Comments->use(@p);
    }
}

sub new {
    my($class, %opt) = @_;

    my $self =  bless {
        server   => {
            host => '127.0.0.1',
            port => '22',
        },
        _version => 0, # 2.0 or 1.99 or 1.5
        _result  => {
            1 => 0,
            2 => 0,
        },
        _scanned => 0,
    }, $class;

    $self->{server}{$_} = $opt{$_} for grep { $opt{$_} } keys %{$self->{server}};
    ### host, port: $self->{server}{host}, $self->{server}{port}

    return $self;
}

sub scan {
    my $self = shift;

    $self->{_scanned} = 1;

    $self->_sshconnect2();
    $self->_sshconnect1() if $self->{_version} < 2;

    ### scan: $self->{_result}
    return $self->{_result};
}

sub scan_as_hash {
    my $self = shift;
    $self->scan unless $self->{_scanned};
    ### dump: $self->{_result}

    my $result;
    for my $v (2,1) {
        $result->{$v}{password}  = ($self->{_result}{$v} & $AUTH_IF{password}) ? 1 : 0;
        $result->{$v}{publickey} = ($self->{_result}{$v} & $AUTH_IF{rsa})      ? 1 : 0;
    }
    ### scan: $result
    return $result;
}

sub _sshconnect2 {
    my $self = shift;

    ### ssh2 connect
    my $ssh;
    eval {
        $ssh = Net::SSH::Perl->new(
            $self->{server}{host},
            port        => $self->{server}{port},
            protocol    => 2,
            compression => 0,
            debug       => 0,
           ) or return;
    };
    if ($@) {
        ### ssh2 connect error: $@
        return;
    }

    my $v = $self->_protocol_version( $ssh->server_version_string );
    ### _version: $v
    $self->{_version} = $v if $v;

    return if $self->{_version} < 1.5; # server supports 1 only

    my @authlist;
    {
        # override to get auth list.
        package Net::SSH::Perl::AuthMgr;
        no warnings 'redefine', 'once';

        local *auth_failure = sub {
            my $amgr = shift;
            my($packet) = @_;
            my $authlist = $packet->get_str;
            $packet->{data}->{offset} -= length($authlist)+4;

            $amgr->{__authlist} = [ split /,/, $authlist ];

            $amgr->{_done} = 1;
        };
        local *auth_list = sub {
            my $amgr = shift;
            $amgr->authenticate;
            return @{ $amgr->{__authlist} };
        };

        my $kex      = Net::SSH::Perl::Kex->new($ssh);
        $kex->exchange;
        my $amgr     = Net::SSH::Perl::AuthMgr->new($ssh);
        @authlist = $amgr->auth_list;
    }

    for my $a (@authlist) {
        ### authlist: $a
        if ($a eq 'publickey') {
            $self->{_result}{2} |= $AUTH_IF{rsa};
        } elsif ($a eq 'password') {
            $self->{_result}{2} |= $AUTH_IF{password};
        }
    }
    ### ssh2 result: $self->{_result}
}

sub _sshconnect1 {
    my $self = shift;

    ### ssh1 connect
    my $ssh;
    eval {
        $ssh = Net::SSH::Perl->new(
            $self->{server}{host},
            port        => $self->{server}{port},
            protocol    => 1,
            compression => 0,
            debug       => 0,
           ) or return;
    };
    if ($@) {
        ### ssh1 connect error: $@
        return;
    }

    my $v = $self->_protocol_version( $ssh->server_version_string );
    ### _version: $v
    $self->{_version} = $v if $v;

    my($protocol_flags, $supported_ciphers, $supported_auth);
    {
        # copy from Net::SSH::Perl::SSH1#_login
        use Net::SSH::Perl::Constants qw( :protocol :msg :hosts );
        my $packet = Net::SSH::Perl::Packet->read_expect($ssh, SSH_SMSG_PUBLIC_KEY);
        my $check_bytes = $packet->bytes(0, 8, "");

        my %keys;
        for my $which (qw( public host )) {
            $keys{$which}            = Net::SSH::Perl::Key::RSA1->new;
            $keys{$which}{rsa}{bits} = $packet->get_int32;
            $keys{$which}{rsa}{e}    = $packet->get_mp_int;
            $keys{$which}{rsa}{n}    = $packet->get_mp_int;
        }

        $protocol_flags    = $packet->get_int32;
        $supported_ciphers = $packet->get_int32;
        $supported_auth    = $packet->get_int32;
    }

    $self->{_result}{1} = $supported_auth;
}

sub _protocol_version {
    my $self = shift;
    ### _protocol_version: $_[0]
    return $_[0] =~ /^SSH-([\d.]+)/ ? $1 : 0;
}

sub dump {
    my $self = shift;
    $self->scan unless $self->{_scanned};
    ### dump: $self->{_result}

    return sprintf(
        '{"1":{"password":%d,"publickey":%d},"2":{"password":%d,"publickey":%d}}',
        $self->{_result}{1} & $AUTH_IF{password} ? 1 : 0,
        $self->{_result}{1} & $AUTH_IF{rsa}      ? 1 : 0,
        $self->{_result}{2} & $AUTH_IF{password} ? 1 : 0,
        $self->{_result}{2} & $AUTH_IF{rsa}      ? 1 : 0,
       );
}

1;

__END__

=head1 NAME

Net::Scan::SSH::Server::SupportedAuth - detect supported authentication method of SSH server

=head1 SYNOPSIS

  use Net::Scan::SSH::Server::SupportedAuth qw(:flag);

  my $scanner = Net::Scan::SSH::Server::SupportedAuth->new(host => 'localhost');

  ### get result as hash
  my $sa_hash = $scanner->scan_as_hash;
  #  $sa_hash = {'1' => {'password' => 0,'publickey' => 0},
  #              '2' => {'password' => 0,'publickey' => 1}};

  ### get result as bit flag
  my $sa = $scanner->scan;

  sub checker {
      my($label, $boolean) = @_;
      printf "%-26s: %s\n", $label, $boolean ? 't' : 'f';
  }
  checker("2-publickey only",
          ($sa->{2} == $AUTH_IF{publickey} && $sa->{1} == 0) );
  checker("any-publickey",
          (($sa->{1} | $sa->{2}) & $AUTH_IF{publickey}) );
  checker("2-publickey or 2-password",
          ($sa->{2} & ( $AUTH_IF{publickey} | $AUTH_IF{password} )) );

=head1 DESCRIPTION

Net::Scan::SSH::Server::SupportedAuth connect SSH server and probe protocol version and supported authentication method (publickey or password).

=head1 METHODS

=head2 new

  $scanner = Net::Scan::SSH::Server::SupportedAuth->new( %option )

This method constructs a new "Net::Scan::SSH::Server::SupportedAuth" instance and returns it. %option is to specify SSH server.

  key   value
  ========================================================
  host  "hostname" or "IP address" (default: '127.0.0.1')
  port  "port number" (default: '22')

=head2 scan

  $sa = $scanner->scan;

Do scan and return hash reference which contains information of supported authentication method.

  $sa = { VERSION => AUTH_FLAGS, VERSION => AUTH_FLAGS, ... }

  VERSION    : SSH protocol version. 1 or 2.
  AUTH_FLAGS : 32bit bit flags. to compare with %Net::Scan::SSH::Server::SupportedAuth::AUTH_IF.

=head2 scan_as_hash

  $sa_hash = $scanner->scan_as_hash;

Do scan and return human readable hash reference which contains information of supported authentication method.

  $sa_hash = { VERSION => { password => 0 or 1, publickey => 0 or 1, },
               VERSION => { password => 0 or 1, publickey => 0 or 1, },
               ... }

  VERSION    : SSH protocol version. 1 or 2.

=head2 dump

  $string = $scanner->dump;

Do scan and return as string.

=head1 SEE ALSO

L<Net::SSH::Perl>
L<http://www.openssh.com/>

=head1 AUTHOR

HIROSE Masaaki, C<< <hirose31@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-scan-ssh-server-supportedauth@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 HIROSE Masaaki, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
