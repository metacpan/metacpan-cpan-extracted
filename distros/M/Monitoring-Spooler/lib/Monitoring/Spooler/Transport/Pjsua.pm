package Monitoring::Spooler::Transport::Pjsua;
$Monitoring::Spooler::Transport::Pjsua::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Transport::Pjsua::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a monitoring spooler voice transport using pjsua

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use IPC::Open2;
use File::Temp qw();

# extends ...
extends 'Monitoring::Spooler::Transport';
# has ...
has 'sipid' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);
has 'registrar' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);
has 'realm' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);
has 'username' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);
has 'password' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);
has 'outbound' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);
has 'stunsrv' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);
has 'sipdest' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);
# with ...
# initializers ...

# your code here ...
sub provides {
    my $self = shift;
    my $type = shift;

    if($type =~ m/^phone/i) {
        return 1;
    }

    return;
}

sub run {
    my $self = shift;
    my $number = shift;
    my $voicefile = shift;

    # use IPC::open2 or open3 (or even just open ...) and hand-crafted eval-timeouts in favor of Expect

    # run pjsua, call number, play voicefile, record DTMF
    # return (nothing) on error or no DTMF data
    # return value of DTMF on success: return wantarray ? (key1, key2, ...) : key1;
    # write temp config file
    my $config_file = $self->_write_config();
    my $pjsua_cmd = '/usr/bin/pjsua --config-file '.$config_file;
    $pjsua_cmd .= ' --play-file '.$voicefile;
    $pjsua_cmd .= ' --log-level 5 --app-log-level 3 --auto-play --duration 90';
    $pjsua_cmd .= ' --max-calls 1  ';
    $pjsua_cmd .= ' --log-file /var/log/mon-spooler/pjsua_logs/log-'.$number.'pjsua_out_'.time();
    $pjsua_cmd .= ' sip:'.$number.'@'.$self->sipdest();
    $pjsua_cmd .= ' 2>/tmp/pj.error';

    my ($child_in, $child_out);
    my $pid = open2($child_out, $child_in, $pjsua_cmd);

    if($pid) {
        if($self->_wait_for($child_out,qr/Got answer/i,90)) {
            my $match_re = qr/Incoming DTMF on call 0: (\d+)/i;
            my $dtmf = $self->_wait_for($child_out,$match_re,90);
            if($dtmf && $dtmf =~ m/$match_re/) {
                my $dmtf_digit = $1;

                print $child_in "h\n"; # send hangup command
                sleep 2;
                print $child_in "q\n"; # quit pjsua
                sleep 2;

                close($child_out);
                close($child_in);
                unlink($config_file);
                return $dmtf_digit;
            }
        }
        unlink($config_file);
        close($child_out);
        close($child_in);
    }

    return;
}

sub _write_config {
    my $self = shift;

    my ($fh, $filename) = File::Temp::tempfile();
    print $fh '--id '.$self->sipid()."\n";
    print $fh '--registrar '.$self->registrar()."\n";
    print $fh '--realm '.$self->realm()."\n";
    print $fh '--username '.$self->username()."\n";
    print $fh '--password '.$self->password()."\n";
    print $fh '--outboudn '.$self->outbound()."\n";
    print $fh '--stun-srv '.$self->stunsrv()."\n";
    print $fh '--null-audio'."\n";
    close($fh);

    return $filename;
}

sub _wait_for {
    my $self = shift;
    my $fh = shift;
    my $re = shift;
    my $timeout = shift;

    my $subject;
    my $prev_timeout;
    my $eval_status = eval {
        local $SIG{ALRM} = sub { die "alarm-monitoring-spooler-transport-pjsua\n"; };
        $prev_timeout = alarm $timeout;
        while(my $line = <$fh>) {
            if($line =~ m/$re/) {
                $subject = $line;
                last;
            }
        }
        1;
    };
    alarm $prev_timeout;
    if($@ && $@ eq "alarm-monitoring-spooler-transport-pjsua\n") {
        # Timeout ...
        return;
    } elsif($@ || !$eval_status || !$subject) {
        # Other eval error
        return;
    } else {
        return $subject;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Transport::Pjsua - a monitoring spooler voice transport using pjsua

=head1 DESCRIPTION

This class implements an experimental phone transport using the pjsua SIP client.

Please note that this class is only provided as a fallback and its usage is
not recommended sind pjsua is not fully-scriptable.

=head1 METHODS

=head2 run

This method tries to dispatch a call to the given destination number using the
supplied voicefile. If the call suceeds it will return a defined value.

If any error occurs it will return undef.

=head1 NAME

Monitoring::Spooler::Transport::Pjsua - Pjsua-based phone transport

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
