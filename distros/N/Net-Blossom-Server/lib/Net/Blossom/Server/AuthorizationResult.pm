package Net::Blossom::Server::AuthorizationResult;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();
use Net::Blossom::Server::Error;

use Carp qw(croak);
use Class::Tiny qw(pubkey action _hashes);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(pubkey action hashes);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "pubkey is required" unless defined $args{pubkey};
    croak "pubkey must be a scalar" if ref($args{pubkey});
    croak "pubkey must be 64-char lowercase hex" unless $args{pubkey} =~ $HEX64;

    croak "action is required" unless defined $args{action};
    croak "action must be a scalar" if ref($args{action});
    croak "action is required" unless length $args{action};

    $args{hashes} = [] unless defined $args{hashes};
    croak "hashes must be an array reference" unless ref($args{hashes}) eq 'ARRAY';
    for my $hash (@{$args{hashes}}) {
        croak "hashes must contain 64-char lowercase hex values"
            unless defined $hash && !ref($hash) && $hash =~ $HEX64;
    }
    $args{_hashes} = [@{$args{hashes}}];
    delete $args{hashes};

    return bless \%args, $class;
}

sub hashes {
    my ($self) = @_;
    return [@{$self->_hashes}];
}

sub require_hash {
    my $self = shift;
    my ($sha256, %opts) = @_;
    my %known = map { $_ => 1 } qw(status reason);
    my @unknown = grep { !exists $known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "sha256 must be 64-char lowercase hex"
        unless defined $sha256 && !ref($sha256) && $sha256 =~ $HEX64;

    $opts{status} = 401 unless defined $opts{status};
    croak "status must be an HTTP status code"
        unless !ref($opts{status}) && $opts{status} =~ /\A[1-5][0-9][0-9]\z/;

    $opts{reason} = 'authorization x tag does not match request hash'
        unless defined $opts{reason};
    croak "reason must be a scalar" if ref($opts{reason});

    return 1 if grep { $_ eq $sha256 } @{$self->_hashes};

    my %headers;
    $headers{'WWW-Authenticate'} = 'Nostr' if $opts{status} == 401;
    Net::Blossom::Server::Error->throw(
        status  => $opts{status},
        reason  => $opts{reason},
        headers => \%headers,
    );
}

1;

=pod

=head1 NAME

Net::Blossom::Server::AuthorizationResult - Verified Blossom authorization data

=head1 SYNOPSIS

    my $result = $auth->authorize($request);
    my $pubkey = $result->pubkey;

    $result->require_hash($sha256, status => 409);

=head1 DESCRIPTION

C<Net::Blossom::Server::AuthorizationResult> is returned by
L<Net::Blossom::Server::Authorization> after a BUD-11 token has been parsed,
signature-checked, and matched to the request action.

The object carries the verified event C<pubkey>, the matched action, and any
validated C<x> tag hashes. Mirror handling uses those hashes after the server
downloads and hashes the remote blob.

=head1 CONSTRUCTOR

=head2 new

    my $result = Net::Blossom::Server::AuthorizationResult->new(%args);

Required arguments are C<pubkey> and C<action>. Optional C<hashes> is an array
reference of lowercase 64-character SHA-256 hashes. Unknown arguments or invalid
values croak.

=head1 ACCESSORS

=head2 pubkey

Returns the verified event pubkey.

=head2 action

Returns the verified Blossom action.

=head2 hashes

Returns a copy array reference of authorized C<x> tag hashes.

=head1 METHODS

=head2 require_hash

    $result->require_hash($sha256);
    $result->require_hash($sha256, status => 409, reason => $reason);

Returns true when C<$sha256> is present in the authorized hash list. Otherwise
throws L<Net::Blossom::Server::Error>. The default status is C<401> with a
C<WWW-Authenticate: Nostr> challenge. Supplying another status, such as the
BUD-04 mirror C<409>, suppresses that challenge.

=cut
