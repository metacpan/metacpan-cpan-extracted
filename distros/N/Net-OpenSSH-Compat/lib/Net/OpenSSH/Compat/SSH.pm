package Net::OpenSSH::Compat::SSH;

our $VERSION = '0.06';

use strict;
use warnings;
use Carp ();
use IPC::Open2;
use IPC::Open3;
use Net::OpenSSH;
use Net::OpenSSH::Constants qw(OSSH_MASTER_FAILED OSSH_SLAVE_CMD_FAILED);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ssh ssh_cmd sshopen2 sshopen3);

my $supplant;

our %DEFAULTS = ( connection => [] );

sub import {
    my $class = shift;
    if (!$supplant and
        $class eq __PACKAGE__ and
        grep($_ eq ':supplant', @_)) {
        $supplant = 1;
        for my $end ('') {
            my $this = __PACKAGE__;
            my $pkg = "Net::SSH";
            my $file = "Net/SSH";
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

sub version { "0.09 (".__PACKAGE__."-$VERSION)" }

sub ssh {
    my $host = shift;
    my $ssh = Net::OpenSSH->new($host);
    if ($ssh->error) {
        $? = (255<<8);
        return -1;
    }
    my @cmd = $ssh->make_remote_command({quote_args => 0}, @_);
    system (@cmd);
}

sub ssh_cmd {
    my ($host, $user, $command, @args, $stdin);
    if (ref $_[0] eq 'HASH') {
        my %opts = $_[0];
        $host = delete $opts{host};
        $user = delete $opts{user};
        $command = delete $opts{command};
        $stdin = delete $opts{stdin_string};
        my $args = delete $opts{args};
        @args = @$args if defined $args;
    }
    else {
        ($host, $command, @args) = @_;
    }
    $stdin = '' unless defined $stdin;
    my $ssh = Net::OpenSSH->new($host, user => $user);
    if ($ssh->error) {
        $? = (255<<8);
        die $ssh->error;
    }
    my ($out, $err) = $ssh->capture2({quote_args => 0, stdin_data => $stdin},
                                     $command, @args);
    die $err if length $err;
    $out;
}

sub sshopen2 {
    my($host, $reader, $writer, $cmd, @args) = @_;
    my $ssh = Net::OpenSSH->new($host);
    $ssh->die_on_error;
    my @cmd = $ssh->make_remote_command({quote_args => 0}, $cmd, @args);
    open2($reader, $writer, @cmd);
}

sub sshopen3 {
    my($host, $writer, $reader, $error, $cmd, @args) = @_;
    my $ssh = Net::OpenSSH->new($host);
    $ssh->die_on_error;
    my @cmd = $ssh->make_remote_command({quote_args => 0}, $cmd, @args);
    open3($writer, $reader, $error, @cmd);
}

1;

__END__

=head1 NAME

Net::OpenSSH::Compat::SSH - Net::OpenSSH adapter for Net::SSH API compatibility

=head1 SYNOPSIS

  use Net::OpenSSH::ConnectionCache; # for speed bost
  use Net::OpenSSH::Compat qw(Net::SSH);

  use Net::SSH qw(ssh ssh_cmd sshopen3);

  my $out = ssh_cmd('username@host', $command);

  sshopen2('user@hostname', $reader, $writer, $command);

  sshopen3('user@hostname', $writer, $reader, $error, $command);

=head1 DESCRIPTION

This module implements L<Net::SSH> API on top of L<Net::OpenSSH>.

After the module is loaded as follows:

  use Net::OpenSSH::Compat 'Net::SSH';

or from the command line:

  $ perl -MNet::OpenSSH::Compat=Net::SSH script.pl

it will supplant Net::SSH module as if it was installed on the
machine and use L<Net::OpenSSH> under the hood to handle SSH
operations.

Most programs using L<Net::SSH> should continue to work without any
change.

It can be used together with L<Net::OpenSSH::ConnectionCache> usually
for a big speed boost.

=cut

