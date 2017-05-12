package Net::SSH::Any::Backend::Plink_Cmd;

use strict;
use warnings;
use Carp;
use Net::SSH::Any::Util qw(_first_defined _array_or_scalar_to_list $debug _debug);
use Net::SSH::Any::Constants qw(SSHA_CONNECTION_ERROR);

use parent 'Net::SSH::Any::Backend::_Cmd';

sub _validate_backend_opts {
    my ($any, %be_opts) = @_;
    $any->SUPER::_validate_backend_opts(%be_opts) or return;

    $be_opts{local_plink_cmd} //= $any->_find_cmd(plink => undef, 'PuTTY') // return;

    my $out = $any->_local_capture($be_opts{local_plink_cmd}, '-V');
    if ($out =~ /plink:\s*(?:Unidentified\s+build\s*,|Pre-release|Release)\s*(.*?)\s*$/mi) {
        $any->{be_plink_version} = $1;
    }
    else {
        $out =~ s/\s+/ /gs; $out =~ s/\s$//;
        $any->_set_error(SSHA_CONNECTION_ERROR, "plink not found or bad version, output: $out");
        return;
    }

    my ($auth_type, $interactive_login);

    if (defined $be_opts{password}) {
        $auth_type = 'password';
        if (my @too_much = grep defined($be_opts{$_}), qw(key_path passphrase)) {
            croak "option(s) '".join("', '", @too_much)."' can not be used together with 'password'"
        }
    }
    else {
        if (defined (my $key = $be_opts{key_path})) {
            my $ppk = "$key.ppk";
            $be_opts{ppk_key_path} = $ppk;
            unless (-e $ppk) {
                local $?;
                my $puttygen = $be_opts{local_puttygen_cmd} //=
                    $any->_find_cmd(puttygen => $be_opts{local_pink_cmd}, 'PuTTY') // return;

                my @cmd = ($puttygen, -O => 'private', -o => $ppk, $key);
                $debug and $debug & 1024 and _debug "generating ppk file with command '".join("', '", @cmd)."'";
                my $out = $any->_local_capture(@cmd);
                if ($?) {
                    $out =~ s/\s+/ /gs; $out =~ s/\s$//;
                    $any->_set_error(SSHA_CONNECTION_ERROR, 'puttygen failed, rc: '.($? >> 8).", output: $out");
                    return
                }
            }
            # fallback
        }
        if (defined (my $ppk = $be_opts{ppk_key_path})) {
            unless (-e $ppk) {
                $any->_set_error(SSHA_CONNECTION_ERROR, 'puttygen failed to convert key to PPK format');
                return
            }
            $auth_type = 'publickey';
        }
        else {
            $auth_type = 'default';
        }
    }

    $any->{be_opts} = \%be_opts;
    $any->{be_auth_type} = $auth_type;
    $any->{be_interactive_login} = 0;
    1;
}

sub _make_cmd {
    my ($any, $cmd_opts, $cmd) = @_;
    my $be_opts = $any->{be_opts};

    my @args = ( $be_opts->{local_plink_cmd},
                 '-ssh',
                 '-batch' );

    push @args, '-C' if $be_opts->{compress};
    push @args, -l => $be_opts->{user} if defined $be_opts->{user};
    push @args, -P => $be_opts->{port} if defined $be_opts->{port};
    push @args, -i => $be_opts->{ppk_key_path} if defined $be_opts->{ppk_key_path};

    if ($any->{be_auth_type} eq 'password') {
        # Add some guard here, user should allow this thing explicitly!
        push @args, -pw => $be_opts->{password};
    }

    push @args, _array_or_scalar_to_list($be_opts->{plink_opts})
        if defined $be_opts->{plink_opts};

    push @args, '-s' if delete $cmd_opts->{subsystem};
    push @args, $be_opts->{host};

    return (@args, $cmd);
}

1;

__END__

=head1 NAME

Net::SSH::Any::Backend::Plink_Cmd - Backend for PuTTY's plink

=head1 SYNOPSIS

  use Net::SSH::Any;
  my $ssh = Net::SSH::Any->new($host, user => $user, password => $password,
                               backend => 'Plink_Cmd',
                               local_plink_cmd => 'C:\\PuTTY\\plink.exe');
  my $output = $ssh->capture("echo hello world");

=head1 DESCRIPTION

This module implements a Net::SSH::Any backend using PuTTY's plink
utility.

It is probably the easiest way to get a working, password
authenticated SSH connection on Windows. Unfortunately, it is not
completely secure as the password is passed to plink on the command
line and anybody with access to the local computer may eavesdrop it.

Also, a new connection is established for every command run, so this
backend is not particularly efficient when running several commands
in the target host.

=head2 Public key authentication

When public key authentication is requested, the module looks first for
the key in a file with the extension C<ppk>.

In case that file does not exist, it looks for the private key in
OpenSSH format and if found, it tries to convert it to PuTTY format
using the companion utility C<puttygen>.

For instance:

  $ssh = Net::SSH::Any->new($host, key_path => 'C:\\OpenSSH\\keys\\my_key',
                            backends => ['Plimk_Cmd']);
                            local_plink_cmd => 'C:\\PuTTY\\plink.exe',
                            local_puttygen_cmd => 'C:\\PuTTY\\puttygen.exe');

  # Looks for "C:\OpenSSH\keys\my_key.ppk". In case that file doesn't
  # exist, it looks for "C:\OpenSSH\keys\my_key" and tries to convert
  # it using the program "C:\PuTTY\puttygen.exe".

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2014 by Salvador FandiE<ntilde>o,
E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
