package PAGI::Headers;
$PAGI::Headers::VERSION = '0.002002';
use strict;
use warnings;
use Carp qw(croak);

# Iterating @{$headers} yields the [name,value] pairs (the PAGI wire form), so
# `@{$res->headers}` callers keep working. READ-ONLY: it returns a COPY, so
# pushing onto it does not mutate the container -- use add(). Emission must use
# to_pairs, never this overload.
use overload '@{}' => sub { $_[0]->to_pairs }, fallback => 1;

=head1 NAME

PAGI::Headers - ordered, case-insensitive, multi-value HTTP header container

=head1 DESCRIPTION

Holds HTTP headers as an ordered list of C<[name, value]> byte pairs -- the PAGI
wire form. Lookup is case-insensitive (ASCII fold; field names are ASCII tokens);
original casing is preserved on output. Insertion order is preserved (never
sorted). Multiple values per name are first-class (e.g. C<Set-Cookie>).

Lookups scan the ordered list -- header sets are small, so this is deliberately
indexless.

This container is B<not> a hash and does not overload hash dereference; iterate
names with C<names> and read values with C<get>/C<get_all>, or take an explicit
plain-hash snapshot with C<to_hash>.

=head1 METHODS

=head2 to_hash

    my $flat  = $headers->to_hash;     # { Name => last-value }
    my $multi = $headers->to_hash(1);  # { Name => [ all values ] }

Returns a plain hashref snapshot keyed by distinct header name (grouped
case-insensitively, using the casing and order C<names> reports). The flat form
mirrors C<get> -- one value per name, last wins. Passing a true argument returns
the multi-value form, mirroring C<get_all> -- an arrayref of every value for each
name. Values are B<not> comma-joined (unlike L<HTTP::Headers>/L<Mojo::Headers>).

Header values are opaque bytes and pass through untouched -- including C<CR>,
C<LF>, and C<NUL>. This container does B<not> validate or sanitize them; rejecting
injection bytes on the wire is the server's job, which it B<MUST> do when emitting
a response (see L<PAGI::Spec::Www/"Response Start - send event">). A value must,
however, be B<defined>: C<add>, C<set>, and C<set_default> C<croak> on an C<undef>
value rather than storing it, since an undefined header value is a caller bug, not
data.

=cut

# ASCII-only lowercase for name keying. Field names are ASCII tokens (RFC 7230);
# Perl's lc() is Unicode-aware and could mis-fold stray bytes.
sub _fold { my $k = $_[0]; $k =~ tr/A-Z/a-z/; return $k }

# Hop-by-hop headers (RFC 7230 §6.1) -- not safe to forward through a proxy.
my %HOP = map { $_ => 1 } qw(
    connection keep-alive proxy-authenticate proxy-authorization
    te trailer transfer-encoding upgrade
);

sub new {
    my ($class, $pairs) = @_;
    my @p;
    if (defined $pairs) {
        croak("PAGI::Headers->new expects an arrayref of [name, value] pairs")
            unless ref($pairs) eq 'ARRAY';
        @p = map { [ $_->[0], $_->[1] ] } @$pairs;
    }
    return bless { pairs => \@p }, $class;
}

sub clone { return PAGI::Headers->new($_[0]->{pairs}) }

# --- reads (case-insensitive) ---

sub get {
    my ($self, $name) = @_;
    croak("header name required") unless defined $name;
    my $key = _fold($name);
    my $val;
    for my $p (@{$self->{pairs}}) { $val = $p->[1] if _fold($p->[0]) eq $key }
    return $val;
}

sub get_all {
    my ($self, $name) = @_;
    croak("header name required") unless defined $name;
    my $key = _fold($name);
    return map { $_->[1] } grep { _fold($_->[0]) eq $key } @{$self->{pairs}};
}

sub has {
    my ($self, $name) = @_;
    return 0 unless defined $name && length $name;
    my $key = _fold($name);
    for my $p (@{$self->{pairs}}) { return 1 if _fold($p->[0]) eq $key }
    return 0;
}

sub names {
    my ($self) = @_;
    my (%seen, @names);
    for my $p (@{$self->{pairs}}) {
        push @names, $p->[0] unless $seen{ _fold($p->[0]) }++;
    }
    return @names;
}

sub count    { scalar @{ $_[0]->{pairs} } }
sub is_empty { @{ $_[0]->{pairs} } ? 0 : 1 }

# --- writes (return $self) ---

sub set {
    my ($self, $name, @values) = @_;
    croak("header name required") unless defined $name;
    croak("header value must be defined") if grep { !defined } @values;
    my $key = _fold($name);
    @{$self->{pairs}} = grep { _fold($_->[0]) ne $key } @{$self->{pairs}};
    push @{$self->{pairs}}, [ $name, $_ ] for @values;
    return $self;
}

sub add {
    my ($self, $name, @values) = @_;
    croak("header name required") unless defined $name;
    croak("header value must be defined") if grep { !defined } @values;
    push @{$self->{pairs}}, [ $name, $_ ] for @values;
    return $self;
}

sub set_default {
    my ($self, $name, $value) = @_;
    return $self if $self->has($name);
    return $self->add($name, $value);
}

sub remove {
    my ($self, $name) = @_;
    croak("header name required") unless defined $name;
    my $key = _fold($name);
    my @removed = map { $_->[1] } grep { _fold($_->[0]) eq $key } @{$self->{pairs}};
    @{$self->{pairs}} = grep { _fold($_->[0]) ne $key } @{$self->{pairs}};
    return @removed;
}

sub clear { @{ $_[0]->{pairs} } = (); return $_[0] }

sub remove_content_headers {
    my ($self) = @_;
    my @removed = grep {  _fold($_->[0]) =~ /^content-/ } @{$self->{pairs}};
    @{$self->{pairs}} = grep { _fold($_->[0]) !~ /^content-/ } @{$self->{pairs}};
    return PAGI::Headers->new(\@removed);
}

# Strip hop-by-hop headers: the fixed RFC 7230 set PLUS any field NAMED by the
# Connection header (e.g. "Connection: X-Secret" makes X-Secret hop-by-hop).
sub dehop {
    my ($self) = @_;
    my %drop = %HOP;
    for my $conn ($self->get_all('connection')) {
        for my $tok (split /,/, $conn) {
            $tok =~ s/\A\s+//; $tok =~ s/\s+\z//;
            $drop{ _fold($tok) } = 1 if length $tok;
        }
    }
    @{$self->{pairs}} = grep { !$drop{ _fold($_->[0]) } } @{$self->{pairs}};
    return $self;
}

# --- output ---

sub to_pairs { return [ map { [ $_->[0], $_->[1] ] } @{ $_[0]->{pairs} } ] }
sub flatten  { return map { @$_ } @{ $_[0]->{pairs} } }

# Plain-hash snapshot, keyed by distinct name (case-insensitively grouped, in
# names() order/casing). Flat form mirrors get() -- one value per name, last
# wins; multi form (truthy arg) mirrors get_all() -- an arrayref of every value.
# This is the explicit "I want a hash" path; the container itself is NOT a hash.
sub to_hash {
    my ($self, $multi) = @_;
    return { map { $_ => [ $self->get_all($_) ] } $self->names } if $multi;
    return { map { $_ => $self->get($_) } $self->names };
}

# Debug/inspection only -- NOT a wire-emission helper. It does not validate or
# strip CR/LF, so it is unsafe for untrusted header values; wire safety is the
# server's job (it validates http.response.start). The real output is to_pairs.
sub to_string { return join('', map { "$_->[0]: $_->[1]\r\n" } @{ $_[0]->{pairs} }) }

1;
