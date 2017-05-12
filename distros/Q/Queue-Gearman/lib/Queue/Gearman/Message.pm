package Queue::Gearman::Message;
use strict;
use warnings;
use utf8;

use Carp qw/croak/;

our $VERSION = "0.01";

use parent qw/Exporter/;

our (%EXPORT_TAGS, @EXPORT_OK);
BEGIN {
    $EXPORT_TAGS{functions} = [qw/build_header build_message parse_header parse_args/];
    $EXPORT_TAGS{constants} = [qw/ARGS_DELIMITER HEADER_BYTES/];
    $EXPORT_TAGS{headers}   = [];
    $EXPORT_TAGS{msgtypes}  = [];
    $EXPORT_TAGS{all}       = \@EXPORT_OK;
    push @EXPORT_OK => map { @{$EXPORT_TAGS{$_}} } keys %EXPORT_TAGS;
}

use constant +{
    ARGS_DELIMITER => "\0",
    HEADER_BYTES   => 12,
};

my (%MAGIC_CODE, %MAGIC_CODE_REV, %MSGTYPE, %MSGTYPE_REV);
BEGIN {
    %MAGIC_CODE = (
        REQ => "\0REQ",
        RES => "\0RES",
    );
    %MAGIC_CODE_REV = reverse %MAGIC_CODE;
    %MSGTYPE = (
        REQ => +{
            CAN_DO             => 1,
            CANT_DO            => 2,
            RESET_ABILITIES    => 3,
            PRE_SLEEP          => 4,
            SUBMIT_JOB         => 7,
            GRAB_JOB           => 9,
            WORK_STATUS        => 12,
            WORK_COMPLETE      => 13,
            WORK_FAIL          => 14,
            GET_STATUS         => 15,
            ECHO_REQ           => 16,
            SUBMIT_JOB_BG      => 18,
            SUBMIT_JOB_HIGH    => 21,
            SET_CLIENT_ID      => 22,
            CAN_DO_TIMEOUT     => 23,
            ALL_YOURS          => 24,
            WORK_EXCEPTION     => 25,
            OPTION_REQ         => 26,
            WORK_DATA          => 28,
            WORK_WARNING       => 29,
            GRAB_JOB_UNIQ      => 30,
            SUBMIT_JOB_HIGH_BG => 32,
            SUBMIT_JOB_LOW     => 33,
            SUBMIT_JOB_LOW_BG  => 34,
            SUBMIT_JOB_SCHED   => 35,
            SUBMIT_JOB_EPOCH   => 36,
        },
        RES => +{
            NOOP            => 6,
            JOB_CREATED     => 8,
            NO_JOB          => 10,
            JOB_ASSIGN      => 11,
            WORK_STATUS     => 12,
            WORK_COMPLETE   => 13,
            WORK_FAIL       => 14,
            ECHO_RES        => 17,
            ERROR           => 19,
            STATUS_RES      => 20,
            WORK_EXCEPTION  => 25,
            OPTION_RES      => 27,
            WORK_DATA       => 28,
            WORK_WARNING    => 29,
            JOB_ASSIGN_UNIQ => 31,
        },
    );
    %MSGTYPE_REV = map {
        $_ => +{
            reverse %{$MSGTYPE{$_}},
        }
    } keys %MSGTYPE;
}

my %BUILD_HEADER_CACHE;
sub build_header {
    my ($context, $msgtype) = @_;
    return $BUILD_HEADER_CACHE{$context}{$msgtype} ||= do {
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        _build_header($context, $msgtype);
    };
}

sub _build_header {
    my ($context, $msgtype) = @_;
    my $magic_code   = $MAGIC_CODE{$context}        or croak "invalid context: $context";
    my $msgtype_code = $MSGTYPE{$context}{$msgtype} or croak "invalid msgtype: $msgtype";
    return $magic_code . pack 'N', $msgtype_code;
}

sub build_message {
    my $header = shift;
    my $args   = join ARGS_DELIMITER, @_;
    my $bytes  = pack 'N', length $args;
    return $header.$bytes.$args;
}

sub parse_header {
    my $header = shift;
    my ($magic_code, $msgtype_code, $bytes) = unpack 'a4NN', $header;
    my $context = $MAGIC_CODE_REV{$magic_code};
    my $msgtype = $MSGTYPE_REV{$context}{$msgtype_code};
    return ($context, $msgtype, $bytes);
}

sub parse_args {
    my $args = shift;
    return split ARGS_DELIMITER, $args;
}

# Creates HEADER_*/MSGTYPE_* constants, and creates `build_header` cache.
BEGIN {
    require constant;
    for my $context (keys %MSGTYPE) {
        for my $msgtype (keys %{ $MSGTYPE{$context} }) {
            my $name  = "HEADER_${context}_${msgtype}";
            my $value = build_header($context, $msgtype);
            constant->import($name => $value);

            # export
            push @EXPORT_OK                 => $name;
            push @{ $EXPORT_TAGS{headers} } => $name;
        }
    }

    for my $context (keys %MSGTYPE) {
        for my $msgtype (keys %{ $MSGTYPE{$context} }) {
            my $name = "MSGTYPE_${context}_${msgtype}";
            constant->import($name => $msgtype);

            # export
            push @EXPORT_OK                  => $name;
            push @{ $EXPORT_TAGS{msgtypes} } => $name;
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Queue::Gearman::Message - Gearman protocol message builder and parser.

=head1 SYNOPSIS

    use Socket qw/IPPROTO_TCP TCP_NODELAY/;
    use IO::Socket::INET;
    use Queue::Gearman::Message qw/:functions :headers HEADER_BYTES/;

    my $sock = IO::Socket::INET->new(PeerHost => '127.0.0.1', PeerPort => 7003, Proto => 'tcp') or die $!;
    $sock->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1) or die $!;
    $sock->autoflush(1);

    my $msg = build_message(HEADER_REQ_SUBMIT_JOB, 'Echo', '', '{"args":{"foo":"bar"}}');
    my $ret = $sock->syswrite($msg, length $msg);

    my ($context, $msgtype, $bytes) = do {
        $sock->sysread(my $header, HEADER_BYTES);
        parse_header($header);
    };
    my @args = do {
        $sock->sysread(my $args, $bytes);
        parse_args($args);
    };

    $sock->close();

=head1 DESCRIPTION

Queue::Gearman::Message is ...

=head1 SEE ALSO

L<Gearman::Util>
L<http://gearman.org/protocol/>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

