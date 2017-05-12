package Random::Quantum;
BEGIN {
  $Random::Quantum::VERSION = '0.04';
}
use Moose;
use IO::Socket::INET;

has 'user' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'password' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'host' => (
    is => 'rw',
    isa => 'Str',
    default => 'random.irb.hr'
);

has 'port' => (
    is => 'rw',
    isa => 'Int',
    default => 1227
);

has 'use_cache' => (
    is => 'rw',
    isa => 'Int',
    default => 1
);

has 'server_responses' => (
    is => 'ro',
    isa => 'Any',
    default => sub{[
        "OK: None",
        "Service was shutting down: Try again later",
        "Server was/is experiencing internal errors: Try again later",
        "Service said we have requested some unsupported operation: Upgrade your client software",
        "Service said we sent an ill-formed request packet: Upgrade your client software",
        "Service said we were sending our request too slow: Check your network connection",
        "Authentication failed: Check your login credentials",
        "User quota exceeded: Try again later, or contact Service admin to increase your quota(s)"
    ]}
);

has 'status' => (
    is => 'rw',
    isa => 'Str',
);

has 'available' => (
    is => 'rw',
    isa => 'Int',
    default => 0
);

has 'bytes' => (
    is => 'rw',
    isa => 'Any'
);

has 'cache_size' => (
    is => 'rw',
    isa => 'Int',
    default => 4096
);

sub int1 {
    ord(shift->chunk(1));
}

sub signed_int1 {
    (unpack("c", shift->chunk(1)))[0];
}

sub int2 {
    (unpack("S", shift->chunk(2)))[0];
}

sub signed_int2 {
    (unpack("s", shift->chunk(2)))[0]
}

sub int4 {
    (unpack("L", shift->chunk(4)))[0];
}

sub signed_int4 {
    (unpack("l", shift->chunk(4)))[0];
}

sub float {
    (unpack("f", pack("i!", 0x3F800000 | (shift->signed_int2 & 0x00FFFFFF))))[0] - 1;
}

sub chunk {
    my ($self, $size) = @_;
    my $data;
    unless ($self->use_cache) {
        $data = substr($self->request(4096), 0, $size);
    } else {
        if ($self->available < $size) {
            $self->request($self->cache_size);
        }
        $data = substr($self->bytes, 0, $size);
        $self->available($self->available - $size);
        $self->bytes(substr($self->bytes, $size));
    }
    return $data;
}


sub request {
    my ($self, $size) = @_;
    $self->status('');
    my $client = IO::Socket::INET->new(
        PeerAddr  => $self->host,
        PeerPort => $self->port,
    ) || die $!;
    my $s = chr(0).pack("n",length($self->user)+length($self->password)+6).
			chr(length($self->user)).
			$self->user.
			chr(length($self->password)).
			$self->password.
			pack("N",$size);
    print $client $s;
    my $data;
    $client->recv($data, 6);
    my @fields = unpack("BBN", $data);
    if ($fields[0] != 0) {
        close $client;
        $self->error($fields[0], $fields[1]);
	warn $self->error;
    }
    $data = '';
    $client->recv($data, $fields[2]);

    $self->bytes($data);
    $self->available(length($self->bytes));
    $self->status('Recieved:'.$self->available);
    close $client;
    return $data;
}

sub error {
    my $self = shift;
    if (defined(my $error = shift)) {
        $self->status($error);
        return undef;
    }
    return $self->status;
}

__PACKAGE__->meta->make_immutable;

# ABSTRACT: Get fundamentally random numbers using QRBGS(Quantum Random Bit Generator Service)

=head1 NAME

Random::Quantum - Get fundamentally random numbers using QRBGS ( Quantum Random Bit Generator Service http://random.irb.hr/ )

=head1 SYNOPSIS

    use Random::Quantum();
    my $cl = new Random::Quantum(user => 'YOUR_LOGIN', 'password' => 'YOUR_PASSWORD');
    print $cl->int1; # prints unsigned int(1)

=head1 METHODS

=head2 int1

Returns unsigned tiny (1 byte) integer

=head2 int1_signed

Returns signed tiny (1 byte) integer

=head2 int2

Returns unsigned short integer

=head2 int2_signed

Returns signed short integer

=head2 int4

Returns unsigned long integer

=head2 int4_signed

Returns signed long integer

=head1 INTERNAL METHODS

=head2 status

Status of last request

=head2 error

Last error

=head2 chunk($size)

Returns bits

=head1 Links

=head1 CONFIG

=head2 use_cache => 0|1

Cache service answer. Default: 1

=head2 cache_size => 1..unknown

Size of cache. Default: 4096.

L<Quantum Random Bit Generator Service|<a href="http://random.irb.hr/">random.irb.hr</a>>

=head1 AUTHOR

Egor Korablev, C<< <egor.korablev at gmail.com> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
