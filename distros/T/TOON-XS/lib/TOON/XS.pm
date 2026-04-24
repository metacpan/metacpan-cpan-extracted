# ABSTRACT: Token-Oriented Object Notation for Perl in XS
package TOON::XS;
$TOON::XS::VERSION = '0.001';
use 5.010;
use strict;
use warnings;

use Carp qw(croak);
use Exporter 'import';
use XSLoader;

our @EXPORT_OK = qw(
    encode_toon decode_toon
    encode_line_toon decode_line_toon validate_line_toon
    encode_brace_toon decode_brace_toon validate_brace_toon
);

XSLoader::load(__PACKAGE__, $TOON::XS::{VERSION} ? ${ $TOON::XS::{VERSION} } : ());

sub encode_line_toon {
    my ($data, %opts) = @_;
    return _xs_encode_line($data, \%opts);
}

sub decode_line_toon {
    my ($text, %opts) = @_;
    return _xs_decode_line($text, \%opts);
}

sub validate_line_toon {
    my ($text, %opts) = @_;
    return _xs_validate_line($text, \%opts);
}

sub encode_brace_toon {
    my ($data, %opts) = @_;
    return _xs_encode_brace($data, \%opts);
}

sub decode_brace_toon {
    my ($text, %opts) = @_;
    return _xs_decode_brace($text);
}

sub validate_brace_toon {
    my ($text, %opts) = @_;
    my $ok = eval { _xs_decode_brace($text); 1 };
    return $ok ? 1 : 0;
}

sub encode_toon {
    my ($data, %opts) = @_;
    my $syntax = delete $opts{'syntax'} // q{};
    $syntax eq 'line'    ? return encode_line_toon($data, %opts)
    : $syntax eq 'brace' ? return encode_brace_toon($data, %opts)
    : croak q{encode_toon() requires 'syntax' => 'line'|'brace'};
}

sub decode_toon {
    my ($text, %opts) = @_;
    my $syntax = delete $opts{syntax} // q{};
    $syntax eq 'line'    ? return decode_line_toon($text, %opts)
    : $syntax eq 'brace' ?  return decode_brace_toon($text, %opts)
    : croak q{decode_toon() requires 'syntax' => 'line'|'brace'};
}

sub new {
    my ($class, %opts) = @_;
    defined $opts{'syntax'}
        or croak q{'syntax' => 'line'|'brace' is required};

    return bless {
        syntax    => $opts{syntax},
        pretty    => exists $opts{pretty}    ? $opts{pretty}    : 0,
        canonical => exists $opts{canonical} ? $opts{canonical} : 0,
        indent    => exists $opts{indent}    ? $opts{indent}    : 2,
    }, $class;
}

sub encode {
    my ($self, $data, %opts) = @_;
    my %all_opts = ( %{$self}, %opts );
    my $syntax = delete $all_opts{'syntax'};
    $syntax eq 'brace'  ? return encode_brace_toon($data, %all_opts)
    : $syntax eq 'line' ? return encode_line_toon($data, %all_opts)
    : croak "Unknown syntax '$syntax' for object encode()";
}

sub decode {
    my ($self, $text, %opts) = @_;
    my %all_opts = (%{$self}, %opts);
    my $syntax = delete $all_opts{syntax};
    $syntax eq 'brace'  ? return decode_brace_toon($text, %all_opts)
    : $syntax eq 'line' ? return decode_line_toon($text, %all_opts)
    : croak "Unknown syntax '$syntax' for object decode()";
}

sub validate {
    my ($self, $text, %opts) = @_;
    my %all_opts = (%{$self}, %opts);
    my $syntax = delete $all_opts{syntax};
    $syntax eq 'brace'  ? return validate_brace_toon($text, %all_opts)
    : $syntax eq 'line' ? return validate_line_toon($text, %all_opts)
    : croak "Unknown syntax '$syntax' for object validate()";
}

sub pretty {
    my ($self, $value) = @_;
    $self->{pretty} = @_ > 1 ? $value : 1;
    return $self;
}

sub canonical {
    my ($self, $value) = @_;
    $self->{canonical} = @_ > 1 ? $value : 1;
    return $self;
}

sub indent {
    my ($self, $value) = @_;
    defined $value and $self->{indent} = $value;
    return $self;
}

sub syntax {
    my ($self, $value) = @_;
    defined $value and $self->{syntax} = $value;
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TOON::XS - Token-Oriented Object Notation for Perl in XS

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use TOON::XS qw(
      encode_toon
      decode_toon

      encode_line_toon
      decode_line_toon

      encode_brace_toon
      decode_brace_toon

      validate_line_toon
      validate_brace_toon
  );

  my $line = encode_line_toon({ id => 1 });
  my $obj1 = decode_line_toon($line);

  my $brace = encode_brace_toon({ answer => 42 }, canonical => 1);
  my $obj2  = decode_brace_toon($brace);

  my $explicit = encode_toon({ answer => 42 }, syntax => 'brace');

  my $toon = TOON::XS->new(syntax => 'brace')->pretty->canonical;
  my $text = $toon->encode({ answer => 42 });

=head1 DESCRIPTION

L<TOON::XS> provides a super fast implementation of TOON that can handle both
line-style and brace-style TOON syntax, meaning it could replace both L<TOON>
and L<Data::TOON>. However, it's in XS (i.e., C). But it's only requiring 5.10.

It supports both functional interface and object-oriented interface. For funsies.

The generic C<encode_toon> / C<decode_toon> functions require an explicit
C<syntax> parameter and do not assume defaults.

=head1 PERFORMANCE

=head2 L<TOON> vs. L<TOON::XS>:

=over 4

=item * C<TOON> brace encode: 4.178e-01 +/- 1.1e-03 (0.3%)

=item * C<TOON> brace decode: 1.7438e+00 +/- 3.1e-03 (0.2%)

=item * C<TOON::XS> brace encode: 9.873e-02 +/- 1.3e-04 (0.1%)

=item * C<TOON::XS> brace decode: 4.3244e-02 +/- 2.2e-05 (0.1%)

=back

=head2 L<Data::TOON> vs. L<TOON::XS>:

=over 4

=item * C<Data::TOON> line encode: 5.0582e-01 +/- 5.1e-04 (0.1%)

=item * C<Data::TOON> line decode: 8.479e-01 +/- 1.5e-03 (0.2%)

=item * C<TOON::XS> line encode: 1.2367e-01 +/- 2.9e-04 (0.2%)

=item * C<TOON::XS> line decode: 8.957e-02 +/- 1.7e-04 (0.2%)

=back

=head2 Totals

So basically, encoding is >4x faster (whether brace-basedd or line-based).

=over 4

=item * If you're using line-based, decoding is almost 10x faster.

=item * If you're using brace-based, decoding is about 40x faster.

=back

I hope that's fast enough.

=head1 FUNCTIONS

=head2 encode_line_toon

    my $text = encode_line_toon({'foo' => 'bar', 'baz' => [0..3]});

    # baz[4]:
    #   - 0
    #   - 1
    #   - 2
    #   - 3
    # foo: bar

Encodes a Perl data structure into line-style TOON.

Supports encoder options such as C<delimiter>, C<column_priority>, and
C<max_depth>.

Returns TOON text.

=head2 decode_line_toon

    my $data = decode_line_toon($text);

Decodes line-style TOON text into Perl data.

May throw on invalid input.

=head2 validate_line_toon

    my $ok = validate_line_toon($text);

Validates line-style TOON text.

Returns C<1> for valid input and C<0> for invalid input.

=head2 encode_brace_toon

    my $text = encode_brace_toon({'foo' => 'bar', 'baz' => [0..3]});

    # {foo: "bar", baz: [0, 1, 2, 3]}

Encodes a Perl data structure into brace-style TOON.

Supports encoder options such as C<pretty>, C<canonical>, and C<indent>.

Returns TOON text.

=head2 decode_brace_toon

    my $data = decode_brace_toon($text);

Decodes brace-style TOON text into Perl data.

May throw on invalid input.

=head2 validate_brace_toon

    my $ok = validate_brace_toon($text);

Validates brace-style TOON text by attempting to decode it.

Returns C<1> for valid input and C<0> for invalid input.

=head2 encode_toon

    my $data = encode_toon(
        { 'foo' => 'bar', 'baz' => [0..3] },
        'syntax' => 'line', # or 'brace',
    );

Requires C<syntax =E<gt> 'line' | 'brace'>.

Dispatches to C<encode_line_toon> or C<encode_brace_toon>.

=head2 decode_toon

    my $value = decode_toon($text, syntax => 'line');

Requires C<syntax =E<gt> 'line' | 'brace'>.

Dispatches to C<decode_line_toon> or C<decode_brace_toon>.

=head1 METHODS

=head2 new

    my $toon = TOON::XS->new(
        syntax    => 'line', # required: 'line' or 'brace'
        pretty    => 0,
        canonical => 0,
        indent    => 2,
    );

Constructs an encoder/decoder object with persistent defaults.

Unlike the function API, C<syntax> is required here.

=head2 encode

    my $text = $toon->encode($data, %overrides);

Object method only. Uses the object's C<syntax> option.

Per-call C<%overrides> are merged over object defaults.

=head2 decode

    my $data = $toon->decode($text, %overrides);

Object method only. Uses the object's C<syntax> option.

Per-call C<%overrides> are merged over object defaults.

=head2 validate

    my $ok = $toon->validate($text, %overrides);

Object method only. Uses the object's C<syntax> option.

Per-call C<%overrides> are merged over object defaults.

=head2 pretty

    $toon->pretty;    # enable
    $toon->pretty(0); # disable

Setter for the brace encoder C<pretty> flag.

Returns C<$self>.

=head2 canonical

    $toon->canonical;    # enable
    $toon->canonical(0); # disable

Setter for the brace encoder C<canonical> flag.

Returns C<$self>.

=head2 indent

    $toon->indent(4);

Setter for the brace encoder indentation width.

Returns C<$self>.

=head2 syntax

    $toon->syntax('line'); # or 'brace'

Setter for object syntax mode used by C<encode>, C<decode>, and C<validate>.

Returns C<$self>.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
