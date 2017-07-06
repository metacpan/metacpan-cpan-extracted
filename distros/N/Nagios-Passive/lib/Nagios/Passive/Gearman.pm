package Nagios::Passive::Gearman;
use Moo;
use MooX::late;
use Gearman::Client;
use Crypt::Rijndael;
use MIME::Base64;
use Carp qw/croak/;

extends 'Nagios::Passive::Base';

has 'key' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    predicate => 'has_key',
);

has queue => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => sub { "check_results" },
);

has gearman => (
    is => 'rw',
    isa => 'Gearman::Client',
    required => 1,
);

sub to_string {
    my $self = shift;
    my $template = << 'EOT';
type=%s
host_name=%s%s
start_time=%i.%i
finish_time=%i.%i
latency=%i.%i
return_code=%i
output=%s %s - %s
EOT
    my $result = sprintf $template,
        'passive',
        $self->host_name,
        (defined $self->service_description
            ? sprintf "\nservice_description=%s", $self->service_description
            : '' ),
        time,0,
        time,0,
        0,0,
        $self->return_code,
        $self->check_name,
        $self->_status_code,
        $self->_quoted_output;
    return $result;
}

sub encrypted_string {
    my $self = shift;
    my $payload = $self->to_string;
    my $key = $self->key;
    $key = substr($key,0,32) . chr(0) x ( 32 - length( $key ) );
    my $crypt = Crypt::Rijndael->new(
        $key,
        Crypt::Rijndael::MODE_ECB() # :-(
    );
    $payload = _null_padding($payload,32,'e');
    $crypt->encrypt($payload);
}

sub submit {
    my $self = shift;
    my $payload = $self->has_key
        ? $self->encrypted_string
        : $self->to_string;
    $self->gearman->dispatch_background($self->queue, encode_base64($payload))
        or croak("submitting job failed");
}

# Thanks to Crypt::CBC
sub _null_padding {
    my ($b,$bs,$decrypt) = @_;
    return unless length $b;
    $b = length $b ? $b : '';
    if ($decrypt eq 'd') {
        $b=~ s/\0*$//s;
        return $b;
    }
    return $b . pack("C*", (0) x ($bs - length($b) % $bs));
}

1;

__END__
=head1 NAME

Nagios::Passive::Gearman - drop check results into mod_gearman's check_result queue

=head1 SYNOPSIS

  my $gearman = Gearman::Client->new;
  $gearman->job_servers([@job_servers]);

  my $nw = Nagios::Passive->create(
    gearman => $gearman,
    key => "...", # if using encryption
    service_description => $service_description,
    check_name => $check_name,
    host_name  => $hostname,
    return_code => 0, # 1 2 3
    output => 'looks (good|bad|horrible) | performancedata'
  );

  $nw->submit;

=head1 DESCRIPTION

This module gives you the ability to drop checkresults into
mod_gearman's check_result queue.

The usage is described in L<Nagios::Passive>

=cut
