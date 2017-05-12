package Net::OpenSSH::Compat::Perl;

our $VERSION = '0.08';

use strict;
use warnings;
use Carp ();

use Net::OpenSSH;
use Net::OpenSSH::Constants qw(OSSH_MASTER_FAILED OSSH_SLAVE_CMD_FAILED);

require Exporter;
our @ISA = qw(Exporter);
our @CARP_NOT = qw(Net::OpenSSH);

my $supplant;
my $session_id = 1;

our %DEFAULTS = ( session    => [protocol => 2,
                                 strict_host_key_checking => 'no'],
                  connection => [] );

sub import {
    my $class = shift;
    if (!$supplant and
        $class eq __PACKAGE__ and
        grep($_ eq ':supplant', @_)) {
        $supplant = 1;
        for my $end ('') { #, qw(Channel SFTP Dir File)) {
            my $this = __PACKAGE__;
            my $pkg = "Net::SSH::Perl";
            my $file = "Net/SSH/Perl";
            if ($end) {
                $this .= "::$end";
                $pkg .= "::$end";
                $file .= "/$end";
            }
            $INC{$file . '.pm'} = __FILE__;
            no strict 'refs';
            @{"${pkg}::ISA"} = ($this);
            ${"${pkg}::VERSION"} = __PACKAGE__->version;
        }
    }
    __PACKAGE__->export_to_level(1, $class,
                                 grep $_ ne ':supplant', @_);
}

sub version { "1.34 (".__PACKAGE__."-$VERSION)" }

sub new {
    my $class = shift;
    my $host = shift;
    my $cfg = Net::OpenSSH::Compat::Perl::Config->new(@_);
    my $cpt = { host => $host,
                state => 'new',
                cfg => $cfg,
                session_id => $session_id++ };

    bless $cpt, $class;
}

sub _entry_method {
    my $n = 1;
    my $last = 'unknown';
    while (1) {
        my $sub = (caller $n++)[3];
        $sub =~ /^Net::OpenSSH::Compat::(?:\w+::)?(\w+)$/ or last;
        $last = $1;
    }
    $last;
}

sub _check_state {
    my ($cpt, $expected) = @_;
    my $state = $cpt->{state};
    return 1 if $expected eq $state;
    my $method = $cpt->_entry_method;
    my $class = ref $cpt;
    Carp::croak qq($class object can't do "$method" on state $state);
    return
}

sub _check_error {
    my $cpt = shift;
    my $ssh = $cpt->{ssh};
    return if (!$ssh->error or $ssh->error == OSSH_SLAVE_CMD_FAILED);
    my $method = $cpt->_entry_method;
    $cpt->{state} = 'failed' if $ssh->error == OSSH_MASTER_FAILED;
    Carp::croak "$method failed: " . $ssh->error;
}

sub login {
    my ($cpt, $user, $password, $suppress_shell) = @_;
    $cpt->_check_state('new');

    $cpt->{user} = $user;
    $cpt->{password} = '*****' if defined $password;
    $cpt->{suppress_shell} = $suppress_shell;

    my @args = (host => $cpt->{host}, @{$DEFAULTS{connection}});
    push @args, user => $user if defined $user;
    push @args, password => $password if defined $password;

    my $cfg = $cpt->{cfg};
    push @args, port => $cfg->{port} if defined $cfg->{port};
    push @args, batch_mode => 1 unless $cfg->{interactive};

    my @more;
    push @more, 'UsePrivilegedPort=yes' if $cfg->{privileged};
    push @more, "Ciphers=$cfg->{ciphers}" if defined $cfg->{ciphers};
    push @more, "Compression=$cfg->{compression}" if defined $cfg->{compression};
    push @more, "CompressionLevel=$cfg->{compression_level}" if defined $cfg->{compression_level};
    push @more, "StrictHostKeyChecking=$cfg->{strict_host_key_checking}" if defined $cfg->{strict_host_key_checking};
    if ($cfg->{identity_files}) {
        push @more, "IdentityFile=$_" for @{$cfg->{identity_files}};
    }
    if ($cfg->{options}) {
        push @more, @{$cfg->{options}};
    }
    push @args, master_opts => [map { -o => $_ } @more];
    # warn "args: @args";

    my $ssh = $cpt->{ssh} = Net::OpenSSH->new(@args);
    if ($ssh->error) {
        $ssh->{state} = 'failed';
        $ssh->die_on_error;
    }
    $cpt->{state} = 'connected';
}

sub cmd {
    my ($cpt, $cmd, $stdin) = @_;
    $cpt->_check_state('connected');
    my $ssh = $cpt->{ssh};
    $stdin = '' unless defined $stdin;
    local $?;
    my ($out, $err) = $ssh->capture2({stdin_data => $stdin}, $cmd);
    $cpt->_check_error;
    return ($out, $err, ($? >> 8));
}

sub shell {
    my $cpt = shift;
    $cpt->_check_state('connected');
    my $ssh = $cpt->{ssh};
    my $tty = $cpt->{cfg}{use_pty};
    $tty = 1 unless defined $tty;
    $ssh->system({tty => $tty});
}

sub config { shift->{cfg} }

sub debug { Carp::carp("@_") if shift->{cfg}{debug} }

sub session_id { shift->{session_id} }

my $make_missing_methods = sub {
    my $pkg = caller;
    my $faked = $pkg;
    $faked =~ s/^Net::OpenSSH::Compat::/Net::SSH::/;
    for (@_) {
        my $name = $_;
        no strict 'refs';
        *{$pkg.'::'.$name} = sub {
            Carp::croak("method ${faked}::$name is not implemented by $pkg, report a bug if you want it supported!");
        }
    }
};

$make_missing_methods->(qw(register_handler
                           sock
                           incomming_data
                           packet_start));

package Net::OpenSSH::Compat::Perl::Config;

my %option_perl2openssh = qw(protocol proto);

sub new {
    my $class = shift;
    my %opts = (@{$DEFAULTS{session}}, @_);
    my %cfg = map { my $v = delete $opts{$_};
                    my $name = $option_perl2openssh{$_} || $_;
                    defined $v ? ($name, $v) : () } qw(port protocol debug interactive
                                                       privileged identity_files cipher
                                                       ciphers compression
                                                       compression_level use_pty
                                                       options strict_host_key_checking);

    %opts and Carp::croak "unsupported configuration option(s) given: ".join(", ", keys %opts);
    $cfg{proto} =~ /\b2\b/ or Carp::croak "Unsupported protocol version requested $cfg{proto}";

    bless \%cfg, $class;
}

sub get { $_[0]->{$_[1]} }

sub set {
    my ($cfg, $k, $v) = @_;
    $cfg->{$k} = $v if @_ == 3;
    $cfg->{$k};
}

sub DESTROY {};

$make_missing_methods->(qw(read_config merge_directive AUTOLOAD));

1;

__END__

=head1 NAME

Net::OpenSSH::Compat::Perl - Net::OpenSSH adapter for Net::SSH::Perl API compatibility

=head1 SYNOPSIS

  use Net::OpenSSH::Compat::Perl qw(:supplant);

  use Net::SSH::Perl;

  my $ssh = Net::SSH::Perl->new('host');
  $ssh->login($user, $passwd);

  my ($out, $err, $rc) = $ssh->cmd($cmd);

=head1 DESCRIPTION

This module implements a subset of L<Net::SSH::Perl> API on top of
L<Net::OpenSSH>.

After the module is loaded as...

  use Net::OpenSSH::Compat::Perl qw(:supplant);

... it supplants the Net::SSH::Perl module as if it were installed on
the machine using L<Net::OpenSSH> under the hood to handle SSH
operations.

=head2 Setting defaults

The hash C<%Net::OpenSSH::Compat::Perl::DEFAULTS> can be used to set
default values for L<Net::OpenSSH> and other modules called under the
hood and otherwise not accessible through the Net::SSH::Perl API.

The entries currently supported are:

=over

=item connection => [ %opts ]

Extra options passed to C<Net::OpenSSH::new> constructor.

Example:

  $Net::OpenSSH::Compat::SSH::Perl::DEFAULTS{connection} =
    [ ssh_path => "/opt/SSH/bin/ssh" ];

=back

=head1 BUGS AND SUPPORT

B<This is a work in progress.>

C<register_handler> method is not supported.

Net::SSH::Perl submodules (i.e. L<Net::SSH::Perl::Channel>) are not emulated.

Anyway, if your Net::SSH::Perl script fails, fill a bug report at the CPAN
RT bugtracker
(L<https://rt.cpan.org/Ticket/Create.html?Queue=Net-OpenSSH-Compat>)
or just send me an e-mail with the details.

Include at least:

=over 4

=item 1 - The full source of the script

=item 2 - A description of what happens in your machine

=item 3 - What you thing it should be happening

=item 4 - What happens when you use the real Net::SSH::Perl

=item 5 - The version and name of your operating system

=item 6 - The version of the OpenSSH ssh client installed on your machine (C<ssh -V>)

=item 7 - The Perl version (C<perl -V>)

=item 8 - The versions of the Perl packages Net::OpenSSH, IO::Pty and this Net::OpenSSH::Compat.

=back

=head2 Git repository

The source code repository is at
L<https://github.com/salva/p5-Net-OpenSSH-Compat>.

=head2 My wishlist

If you like this module and you're feeling generous, take a look at my
Amazon Wish List: L<http://amzn.com/w/1WU1P6IR5QZ42>

Also consider contributing to the OpenSSH project this module builds
upon: L<http://www.openssh.org/donations.html>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2014-2016 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
