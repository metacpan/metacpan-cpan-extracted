package Net::Blossom::URI;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();
use Net::Blossom::_URL ();

use Carp qw(croak);
use Class::Tiny qw(sha256 extension xs as sz);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(sha256 extension xs as sz);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "sha256 is required" unless defined $args{sha256};
    croak "sha256 must be 64-char lowercase hex" unless $args{sha256} =~ $HEX64;

    $args{extension} = 'bin' unless defined $args{extension} && length $args{extension};
    $args{extension} =~ s/\A\.//;
    croak "extension must contain only letters and digits"
        unless length($args{extension}) && $args{extension} =~ /\A[A-Za-z0-9]+\z/;

    $args{xs} = [] unless defined $args{xs};
    croak "xs must be an array reference" unless ref($args{xs}) eq 'ARRAY';
    my @xs = @{$args{xs}};
    for my $server (@xs) {
        croak "server hint must be a domain or http(s) root URL"
            unless defined $server && !ref($server) && _valid_server_hint($server);
    }

    $args{as} = [] unless defined $args{as};
    croak "as must be an array reference" unless ref($args{as}) eq 'ARRAY';
    my @as = @{$args{as}};
    for my $author (@as) {
        croak "author hint must be 64-char lowercase hex"
            unless defined $author && !ref($author) && $author =~ $HEX64;
    }

    if (defined $args{sz}) {
        croak "size must be a positive integer"
            unless !ref($args{sz}) && $args{sz} =~ /\A[1-9][0-9]*\z/;
    }

    $args{xs} = \@xs;
    $args{as} = \@as;
    return bless \%args, $class;
}

sub parse {
    my ($class, $value) = @_;
    croak "URI is required" unless defined $value && length $value;
    croak "URI must use blossom scheme" unless $value =~ s/\Ablossom://;
    croak "fragments are not allowed" if $value =~ /#/;

    my ($path, $query) = split /\?/, $value, 2;
    my ($sha256, $extension) = _parse_path($path);
    my %args = (
        sha256    => $sha256,
        extension => $extension,
    );

    if (defined $query && length $query) {
        for my $pair (split /&/, $query) {
            croak "query parameter must include value" unless $pair =~ /=/;
            my ($key, $raw_value) = split /=/, $pair, 2;
            $key = _pct_decode($key);
            my $decoded = _pct_decode($raw_value);

            if ($key eq 'xs') {
                push @{$args{xs}}, $decoded;
            }
            elsif ($key eq 'as') {
                push @{$args{as}}, $decoded;
            }
            elsif ($key eq 'sz') {
                croak "duplicate size parameter" if defined $args{sz};
                $args{sz} = $decoded;
            }
            else {
                croak "unknown query parameter: $key";
            }
        }
    }

    return $class->new(%args);
}

sub to_string {
    my ($self) = @_;
    my $value = 'blossom:' . $self->sha256 . '.' . $self->extension;

    my @query;
    push @query, map { ['xs', $_] } @{$self->xs};
    push @query, map { ['as', $_] } @{$self->as};
    push @query, ['sz', $self->sz] if defined $self->sz;

    return $value unless @query;
    return $value . '?' . join('&', map { _pct_encode($_->[0]) . '=' . _pct_encode($_->[1]) } @query);
}

sub _parse_path {
    my ($path) = @_;
    croak "sha256 must be 64-char lowercase hex" unless defined $path && length $path;

    my ($sha256, $extension) = split /\./, $path, 2;
    croak "extension is required" unless defined $extension && length $extension;
    croak "sha256 must be 64-char lowercase hex" unless defined $sha256 && $sha256 =~ $HEX64;
    return ($sha256, $extension);
}

sub _valid_server_hint {
    my ($server) = @_;
    return Net::Blossom::_URL::http_root_url($server) if $server =~ m{\Ahttps?://}i;
    return $server =~ m{\A[A-Za-z0-9][A-Za-z0-9.-]*(?::[1-9][0-9]*)?\z};
}

sub _pct_decode {
    my ($value) = @_;
    croak "invalid percent encoding" if $value =~ /%(?![0-9A-Fa-f]{2})/;
    $value =~ tr/+/ /;
    $value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $value;
}

sub _pct_encode {
    my ($value) = @_;
    $value = "$value";
    $value =~ s/([^A-Za-z0-9._~:\/-])/sprintf("%%%02X", ord($1))/ge;
    return $value;
}

1;

=pod

=head1 NAME

Net::Blossom::URI - BUD-10 Blossom URI value object

=head1 SYNOPSIS

    use Net::Blossom::URI;

    my $uri = Net::Blossom::URI->new(
        sha256    => $sha256,
        extension => 'png',
        xs        => ['cdn.example.com'],
        as        => [$pubkey],
        sz        => 1234,
    );

    my $string = $uri->to_string;
    my $parsed = Net::Blossom::URI->parse($string);

=head1 DESCRIPTION

C<Net::Blossom::URI> builds and parses BUD-10 C<blossom:> URIs.

=head1 CONSTRUCTORS

=head2 new

    my $uri = Net::Blossom::URI->new(%args);

Required C<sha256> must be lowercase 64-character hex.

Optional C<extension> defaults to C<bin> and must contain only letters and
digits. A leading dot is removed.

Optional C<xs> is an array reference of server hints. Each hint must be a domain
or HTTP/HTTPS root URL without a path. Optional C<as> is an array reference of
lowercase 64-character author public keys. Optional C<sz> is a positive integer
byte size.

Unknown arguments or invalid values croak.

=head2 parse

    my $uri = Net::Blossom::URI->parse($value);

Parses a C<blossom:> URI and returns a C<Net::Blossom::URI> object. Fragments
are rejected. Unknown query parameters, duplicate C<sz>, missing values, and
invalid percent encoding croak.

=head1 ACCESSORS

=head2 sha256

Returns the lowercase SHA-256 hash.

=head2 extension

Returns the extension without a leading dot.

=head2 xs

Returns the server hint array reference.

=head2 as

Returns the author hint array reference.

=head2 sz

Returns the optional byte size.

=head1 METHODS

=head2 to_string

    my $value = $uri->to_string;

Returns the C<blossom:> URI string. Query parameters are emitted in C<xs>,
C<as>, then C<sz> order.

=cut
