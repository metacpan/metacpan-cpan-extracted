package Net::APNs::Extended;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.12';

use parent qw(Exporter Net::APNs::Extended::Base);
use Carp qw(croak);

use constant {
    NO_ERRORS            => 0,
    PROCESSING_ERROR     => 1,
    MISSING_DEVICE_TOKEN => 2,
    MISSING_TOPIC        => 3,
    MISSING_PAYLOAD      => 4,
    INVALID_TOKEN_SIZE   => 5,
    INVALID_TOPIC_SIZE   => 6,
    INVALID_PAYLOAD_SIZE => 7,
    INVALID_TOKEN        => 8,
    SHUTDOWN             => 10,
    UNKNOWN_ERROR        => 255,
};

our @EXPORT_OK = qw{
    NO_ERRORS
    PROCESSING_ERROR
    MISSING_DEVICE_TOKEN
    MISSING_TOPIC
    MISSING_PAYLOAD
    INVALID_TOKEN_SIZE
    INVALID_TOPIC_SIZE
    INVALID_PAYLOAD_SIZE
    INVALID_TOKEN
    SHUTDOWN
    UNKNOWN_ERROR
};
our %EXPORT_TAGS = (constants => \@EXPORT_OK);

__PACKAGE__->mk_accessors(qw[
    max_payload_size
    command
]);

my %default = (
    host_production  => 'gateway.push.apple.com',
    host_sandbox     => 'gateway.sandbox.push.apple.com',
    is_sandbox       => 0,
    port             => 2195,
    max_payload_size => 256,
    command          => 1,
);

sub new {
    my ($class, %args) = @_;
    $class->SUPER::new(%default, %args);
}

sub send {
    my ($self, $device_token, $payload, $extra) = @_;
    croak 'Usage: $apns->send($device_token, \%payload [, \%extra ])'
        unless defined $device_token && ref $payload eq 'HASH';

    $extra ||= {};
    $extra->{identifier} ||= 0;
    $extra->{expiry}     ||= 0;
    my $data = $self->_create_send_data($device_token, $payload, $extra) || return 0;
    return $self->_send($data) ? 1 : 0;
}

sub send_multi {
    my ($self, $datum) = @_;
    croak 'Usage: $apns->send_multi(\@datum)' unless ref $datum eq 'ARRAY';

    my $data;
    my $i = 0;
    for my $stuff (@$datum) {
        croak 'Net::APNs::Extended: send data must be ARRAYREF' unless ref $stuff eq 'ARRAY';
        my ($device_token, $payload, $extra) = @$stuff;
        croak 'Net::APNs::Extended: send data require $device_token and \%payload'
            unless defined $device_token && ref $payload eq 'HASH';
        $extra ||= {};
        $extra->{identifier} ||= $i++;
        $extra->{expiry}     ||= 0;
        $data .= $self->_create_send_data($device_token, $payload, $extra);
    }
    return $self->_send($data) ? 1 : 0;
}

sub retrieve_error {
    my $self = shift;
    my $data = $self->_read;
    return unless defined $data;

    if ($data eq '') { # connection closed
        $self->disconnect;
        return $data;
    }

    my ($command, $status, $identifier) = unpack 'C C L', $data;
    my $error = {
        command    => $command,
        status     => $status,
        identifier => $identifier,
    };

    $self->disconnect;
    return $error;
}
*retrive_error = *retrieve_error;

sub _create_send_data {
    my ($self, $device_token, $payload, $extra) = @_;
    my $chunk;

    croak 'aps parameter must be HASHREF' unless ref $payload->{aps} eq 'HASH';

    # numify
    $payload->{aps}{badge} += 0 if exists $payload->{aps}{badge};

    # trim alert body
    my $json = $self->json->encode($payload);
    while (bytes::length($json) > $self->{max_payload_size}) {
        if (ref $payload->{aps}{alert} eq 'HASH' && exists $payload->{aps}{alert}{body}) {
            $payload->{aps}{alert}{body} = $self->_trim_alert_body($payload->{aps}{alert}{body}, $payload);
        }
        elsif (exists $payload->{aps}{alert}) {
            $payload->{aps}{alert} = $self->_trim_alert_body($payload->{aps}{alert}, $payload);
        }
        else {
            $self->_trim_alert_body(undef, $payload);
        }
        $json = $self->json->encode($payload);
    }

    my $command = $self->command;
    if ($command == 0) {
        $chunk = CORE::pack('C n/a* n/a*', $command, $device_token, $json);
    }
    elsif ($command == 1) {
        $chunk = CORE::pack('C L N n/a* n/a*',
            $command, $extra->{identifier}, $extra->{expiry}, $device_token, $json,
        );
    }
    else {
        croak "command($command) not support. shuled be 0 or 1";
    }

    return $chunk;
}

sub _trim_alert_body {
    my ($self, $body, $payload) = @_;
    if (!defined $body || length $body == 0) {
        my $json = $self->json->encode($payload);
        croak sprintf "over the payload size (current:%d > max:%d) : %s",
            bytes::length($json), $self->{max_payload_size}, $json;
    }
    substr($body, -1, 1) = '';
    return $body;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Net::APNs::Extended - Client library for APNs that support the extended format.

=head1 SYNOPSIS

  use Net::APNs::Extended;

  my $apns = Net::APNs::Extended->new(
      is_sandbox => 1,
      cert_file  => 'apns.pem',
  );

  # send notification to APNs
  $apns->send($device_token, {
      aps => {
          alert => "Hello, APNs!",
          badge => 1,
          sound => "default",
      },
      foo => [qw/bar baz/],
  });

  # if you want to handle the error
  if (my $error = $apns->retrieve_error) {
      die Dumper $error;
  }

=head1 DESCRIPTION

Net::APNs::Extended is client library for APNs. The client is support the extended format.

=head1 METHODS

=head2 new(%args)

Create a new instance of C<< Net::APNs::Extended >>.

Supported arguments are:

=over

=item is_sandbox : Bool

Default: 1

=item cert_file : Str

=item cert : Str

Required.

Sets certificate. You can not specify both C<< cert >> and C<< cert_file >>.

=item key_file : Str

=item key : Str

Sets private key. You can not specify both C<< key >> and C<< key_file >>.

=item password : Str

Sets private key password.

=item read_timeout : Num

Sets read timeout.

=item write_timeout : Num

Sets write timeout.

=back

=head2 $apns->send($device_token, $payload [, $extra ])

Send notification for APNs.

  $apns->send($device_token, {
      aps => {
          alert => "Hello, APNs!",
          badge => 1,
          sound => "default",
      },
      foo => [qw/bar baz/],
  });

=head2 $apns->send_multi([ [ $device_token, $payload [, $extra ] ], [ ... ] ... ])

Send notification for each data. The data chunk is same as C<< send() >> arguments.

=head2 $apns->retrieve_error()

Gets error data from APNs. If there is no error will not return anything.

  if (my $error = $apns->retrieve_error) {
      die Dumper $error;
  }

=head1 AUTHOR

xaicron E<lt>xaicron {@} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
