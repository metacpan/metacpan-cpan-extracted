package Radamsa;

use 5.010;
use strict;
use warnings;

use Carp qw(croak);
use Exporter qw(import);

our $VERSION   = '0.02';
our @EXPORT_OK = qw(mutate);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        seed      => delete($args{seed}) // _random_seed(),
        max_len   => delete($args{max_len}),
        max_scale => delete($args{max_scale}) // 4,
    }, $class;

    croak 'unknown constructor arguments: ' . join(', ', sort keys %args)
        if %args;

    return $self;
}

sub mutate {
    my ($thing, @rest) = @_;
    my $self = ref($thing) ? $thing : undef;
    my $input = $self ? shift(@rest) : $thing;
    my %args = @rest;

    croak 'input must be defined' unless defined $input;

    my $seed = delete($args{seed});
    if (defined $self) {
        $seed //= $self->{seed}++;
    }
    else {
        $seed //= _random_seed();
    }

    my $max_len = delete $args{max_len};
    if (!defined $max_len && defined $self) {
        $max_len = $self->{max_len};
    }
    $max_len //= _default_max_len($input, $self ? $self->{max_scale} : 4);

    croak 'max_len must be a positive integer' if $max_len < 1;
    croak 'unknown mutate arguments: ' . join(', ', sort keys %args)
        if %args;

    return _mutate_raw($input, int($max_len), int($seed));
}

sub _random_seed {
    return int(rand(4_294_967_296));
}

sub _default_max_len {
    my ($input, $scale) = @_;
    $scale = 4 unless defined $scale;
    my $len = length $input;
    my $min = 1024;

    return $min if $len == 0;

    $scale = 1 if $scale < 1;
    my $max_len = int($len * $scale);
    $max_len = $len if $max_len < $len;
    $max_len = $min if $max_len < $min;

    return $max_len;
}

1;

=head1 NAME

Radamsa - Perl 5 bindings for the Radamsa mutational fuzzer

=head1 SYNOPSIS

  use Radamsa qw(mutate);

  my $output = mutate("hello\n", seed => 1234, max_len => 4096);

  my $rad = Radamsa->new(seed => 1, max_len => 4096);
  my $case1 = $rad->mutate("sample one");
  my $case2 = $rad->mutate("sample two");

=head1 DESCRIPTION

This module wraps Radamsa's C library interface and exposes a simple Perl API
for generating fuzzed variants of byte strings. The CPAN distribution ships a
vendored generated C source for Radamsa, so installation does not need network
access or the original Owl Lisp toolchain.

=head1 FUNCTIONS

=head2 mutate

  my $output = mutate($input, %options);

Mutates one byte string and returns the mutated output.

Options:

=over 4

=item * seed

Unsigned 32-bit seed passed to the Radamsa library entry point.

=item * max_len

Maximum output size in bytes. Defaults to a heuristic based on the input size.

=back

=head1 METHODS

=head2 new

  my $rad = Radamsa->new(%options);

Creates a stateful mutator object.

=head1 NOTES

Radamsa's library mode keeps internal mutation state between calls. A fixed
seed influences generation, but repeated calls with the same seed should not be
assumed to be byte-for-byte deterministic for the lifetime of the same process.

=head1 LICENSE

This distribution includes vendored Radamsa source code by Aki Helin under the
MIT license. See the top-level F<LICENSE> file.

=cut
