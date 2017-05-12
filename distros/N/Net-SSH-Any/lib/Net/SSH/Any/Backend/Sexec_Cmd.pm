package Net::SSH::Any::Backend::Sexec_Cmd;

use strict;
use warnings;
use Carp;
use Net::SSH::Any::Util qw(_first_defined _array_or_scalar_to_list $debug _debug);
use Net::SSH::Any::Constants qw(SSHA_CONNECTION_ERROR SSHA_CHANNEL_ERROR SSHA_REMOTE_CMD_ERROR);

use parent 'Net::SSH::Any::Backend::_Cmd';

sub _validate_backend_opts {
    my ($any, %opts) = @_;
    $any->SUPER::_validate_backend_opts(%opts) or return;

    grep defined $opts{$_}, qw(profile_path host)
        or croak "host argument missing";

    my @auth_type;
    if (defined $opts{password}) {
        push @auth_type, 'password';
        #if (my @too_much = grep defined($opts{$_}), qw(key_path passphrase)) {
        #    croak "option(s) '".join("', '", @too_much)."' can not be used together with 'password'"
        #}
    }
    elsif (defined (my $key = $opts{key_path})) {
        push @auth_type, 'publickey';
        croak "pubkey authentication not support yet by Sexec_Cmd backend";
        # my $ppk = "$key.ppk";
        # $opts{ppk_path} = $ppk;
        # unless (-e $ppk) {
        #     local $?;
        #     my $cmd = _first_defined $opts{local_puttygen_cmd},
        #         $any->{local_cmd}{puttygen}, 'puttygen';
        #     my @cmd = ($cmd, -O => 'private', -o => $ppk, $key);
        #     $debug and $debug & 1024 and _debug "generating ppk file with command '".join("', '", @cmd)."'";
        #     if (system @cmd) {
        #         $any->_set_error(SSHA_CONNECTION_ERROR, 'puttygen failed, rc: ' . ($? >> 8));
        #         return
        #     }
        #     unless (-e $ppk) {
        #         $any->_set_error(SSHA_CONNECTION_ERROR, 'puttygen failed to convert key to PPK format');
        #         return
        #     }
        #}
    }
    else {
        # $auth_type = 'default';
    }

    $opts{local_sexec_cmd} = _first_defined $opts{local_sexec_cmd}, $any->{local_cmd}{sexec}, 'sexec';
    $any->{be_opts} = \%opts;
    $any->{be_auth_type} = join(',', @auth_type);
    $any->{be_interactive_login} = 0;
    1;
}

sub _make_cmd {
    my ($any, $cmd_opts, $cmd) = @_;
    my $be_opts = $any->{be_opts};

    my ($sexec, $host, $profile_path, $user, $password, $port) =
        @{$be_opts}{qw(local_sexec_cmd host profile_path user password port)};

    my @args = ($sexec, "-unat=y");
    if (defined $profile_path) {
        push @args, "-profile=$profile_path";
        push @args, "-host=$host" if defined $host;
    }
    else {
        push @args, $host;
    }
    push @args, "-user=$user" if defined $user;
    push @args, "-port=$port" if defined $port;
    push @args, "-pw=$password" if defined $password;

    push @args, _array_or_scalar_to_list($be_opts->{sexec_opts})
        if defined $be_opts->{sexec_opts};

    delete $cmd_opts->{subsystem} and croak "running subsystems is not supported by backend";

    return (@args, "-cmd=$cmd");
}

my %sexec_error_str = (   0 => 'Success',
                          2 => 'Usage error',
                        100 => 'SSH session failure',
                        101 => 'Failure connecting to server',
                        102 => 'SSH host authentication failure',
                        103 => 'SSH user authentication failure',
                        200 => 'Session channel open request was rejected'.
                        201 => 'Execution request was rejected',
                        900 => 'The remote process was terminated by a signal',
                        901 => 'The remote process was terminated by a signal with core dumped' );

sub _remap_child_error {
    my ($any, $proc) = @_;
    if (my $native_rc = $proc->{native_rc}) {
        # if ($native_rc == 0) { do_nothing() }
        # already handled by previous condition

        my $errstr = $sexec_error_str{$native_rc} // 'Unknown failure';
        if ($native_rc < 900) {
            $any->_os_set_error(SSHA_CHANNEL_ERROR, $errstr);
            $proc->{rc} = 255;
        }
        elsif ($native_rc < 1000) {
            $any->_os_set_error(SSHA_REMOTE_CMD_ERROR, $errstr);
            $proc->{rc} = (1 << 8) | ($native_rc == 900 ? 0x7f : 0xff);
        }
        else {
            $proc->{rc} = ($native_rc - 1000) << 8;
        }
        $debug and $debug & 1024 and _debug "native rc $native_rc mapped to $proc->{rc}";
    }
    1;
}

1;

__END__

=head1 NAME

Net::SSH::Any::Backend::Sexec_Cmd - Backend for Bitwise's Tunnelier sexec tool

=head1 SYNOPSIS

  use Net::SSH::Any;

  my $profile_path = "C:\\Documents and Settings\\JSmith\\My Documents\\$host.bscp";

  my $ssh = Net::SSH::Any->new($host, backends => 'Sexec_Cmd',
                               backend_opts => {
                                   Sexec_Cmd => { profile_path => $profile_path }
                               });
  my $output = $ssh->capture("echo hello world");

=head1 DESCRIPTION

This module implements a Net::SSH::Any backend using the obscure
Bitwise's Tunnelier utility C<sexec>.

Together with the Plink_Cmd backend this is probably one of the
easiest ways to get a working, password authenticated SSH connection
on Windows.

The biggest downside is that Tunnelier is a commercial application and
you should pay for it if you use it for business.

One very nice feature of this backend is that you can use the host
profiles created with the Tunnelier application to define connection
parameters, specially authentication items as passwords or kerberos
configurations.

=head2 BACKEND OPTIONS

The backend accepts the following custom options:

=over 4

=item profile_path => $path

Uses the profile defined in the given file to set the connection
options.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Salvador FandiE<ntilde>o,
E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
