package TOML::Tiny;
# ABSTRACT: a minimal, pure perl TOML parser and serializer
$TOML::Tiny::VERSION = '0.15';
use strict;
use warnings;
no warnings qw(experimental);
use v5.18;

use TOML::Tiny::Parser;
use TOML::Tiny::Writer;

use parent 'Exporter';

our @EXPORT = qw(
  from_toml
  to_toml
);

#-------------------------------------------------------------------------------
# TOML module compatibility
#-------------------------------------------------------------------------------
sub from_toml {
  my ($source, %param) = @_;

  # strict was previously strict_arrays; accept both for backward
  # compatibility.
  if (exists $param{strict_arrays}) {
    $param{strict} = $param{strict_arrays};
    delete $param{strict_arrays};
  }

  my $parser = TOML::Tiny::Parser->new(%param);
  my $toml   = eval{ $parser->parse($source) };

  if (wantarray) {
    return ($toml, $@);
  } else {
    die $@ if $@;
    return $toml;
  }
}

sub to_toml {
  my ($data, %param) = @_;

  # strict was previously strict_arrays; accept both for backward
  # compatibility.
  if (exists $param{strict_arrays}) {
    $param{strict} = $param{strict_arrays};
    delete $param{strict_arrays};
  }

  TOML::Tiny::Writer::to_toml($data, %param);
}

#-------------------------------------------------------------------------------
# Object API
#-------------------------------------------------------------------------------
sub new {
  my ($class, %param) = @_;
  bless{ %param, parser => TOML::Tiny::Parser->new(%param) }, $class;
}

sub decode {
  my ($self, $source) = @_;
  $self->{parser}->parse($source);
}

sub encode {
  my ($self, $data) = @_;
  TOML::Tiny::Writer::to_toml($data, strict => $self->{strict});
}

#-------------------------------------------------------------------------------
# For compatibility with TOML::from_toml's use of $TOML::Parser
#-------------------------------------------------------------------------------
sub parse {
  goto \&decode;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TOML::Tiny - a minimal, pure perl TOML parser and serializer

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use TOML::Tiny qw(from_toml to_toml);

  binmode STDIN,  ':encoding(UTF-8)';
  binmode STDOUT, ':encoding(UTF-8)';

  # Decoding TOML
  my $toml = do{ local $/; <STDIN> };
  my ($parsed, $error) = from_toml $toml;

  # Encoding TOML
  say to_toml({
    stuff => {
      about => ['other', 'stuff'],
    },
  });

  # Object API
  my $parser = TOML::Tiny->new;
  my $data = $parser->decode($toml);
  say $parser->encode($data);

=head1 DESCRIPTION

=for html <p>
  <a href="https://github.com/sysread/TOML-Tiny/actions?query=workflow%3Arun-tests">
    <img src="https://github.com/sysread/TOML-Tiny/workflows/run-tests/badge.svg" alt="Build status" />
  </a>
</p>

C<TOML::Tiny> implements a pure-perl parser and generator for the
L<TOML|https://github.com/toml-lang/toml> data format. It conforms to TOML v1.0
(with a few caveats; see L</strict>).

C<TOML::Tiny> strives to maintain an interface compatible to the L<TOML> and
L<TOML::Parser> modules, and could even be used to override C<$TOML::Parser>:

  use TOML;
  use TOML::Tiny;

  local $TOML::Parser = TOML::Tiny->new(...);
  say to_toml(...);

=head1 EXPORTS

C<TOML::Tiny> exports the following to functions for compatibility with the
L<TOML> module. See L<TOML/FUNCTIONS>.

=head2 from_toml

Parses a string of C<TOML>-formatted source and returns the resulting data
structure. Any arguments after the first are passed to L<TOML::Tiny::Parser>'s
constructor.

If there is a syntax error in the C<TOML> source, C<from_toml> will die with
an explanation which includes the line number of the error.

  my $result = eval{ from_toml($toml_string) };

Alternately, this routine may be called in list context, in which case syntax
errors will result in returning two values, C<undef> and an error message.

  my ($result, $error) = from_toml($toml_string);

Additional arguments may be passed after the toml source string; see L</new>.

=head3 GOTCHAS

=over

=item Big integers and floats

C<TOML> supports integers and floats larger than what many perls support. When
C<TOML::Tiny> encounters a value it may not be able to represent as a number,
it will instead return a L<Math::BigInt> or L<Math::BigFloat>. This behavior
can be overridden by providing inflation routines:

  my $toml = TOML::Tiny->new(
    inflate_float => sub{
      return do_something_else_with_floats( $_[0] );
    };
  );

=back

=head2 to_toml

Encodes a hash ref as a C<TOML>-formatted string.

  my $toml = to_toml({foo => {'bar' => 'bat'}});

  # [foo]
  # bar="bat"

=head3 mapping perl to TOML types

=head4 table

=over

=item C<HASH> ref

=back

=head4 array

=over

=item C<ARRAY> ref

=back

=head4 boolean

=over

=item C<\0> or C<\1>

=item L<JSON::PP::Boolean>

=item L<Types::Serializer::Boolean>

=back

=head4 numeric types

These are tricky in perl. When encountering a C<Math::Big[Int|Float]>,
that representation is used.

If the value is a defined (non-ref) scalar with the C<SVf_IOK> or C<SVf_NOK>
flags set, the value will be emitted unchanged. This is in line with most
other packages, so the normal hinting hacks for typed output apply:

  number => 0 + $number,
  string => "" . $string,

=over

=item L<Math::BigInt>

=item L<Math::BigFloat>

=item numerical scalars

=back

=head4 datetime

=over

=item RFC3339-formatted string

e.g., C<"1985-04-12T23:20:50.52Z">

=item L<DateTime>

L<DateTime>s are formatted as C<RFC3339>, as expected by C<TOML>. However,
C<TOML> supports the concept of a "local" time zone, which strays from
C<RFC3339> by allowing a datetime without a time zone offset. This is
represented in perl by a C<DateTime> with a B<floating time zone>.

=back

=head4 string

All other non-ref scalars are treated as strings.

=head1 OBJECT API

=head2 new

=over

=item inflate_datetime

By default, C<TOML::Tiny> treats TOML datetimes as strings in the generated
data structure. The C<inflate_datetime> parameter allows the caller to provide
a routine to intercept those as they are generated:

  use DateTime::Format::RFC3339;

  my $parser = TOML::Tiny->new(
    inflate_datetime => sub{
      my ($dt_string) = @_;
      # DateTime::Format::RFC3339 will set the resulting DateTime's formatter
      # to itself. Fallback is the DateTime default, ISO8601, with a possibly
      # floating time zone.
      return eval{ DateTime::Format::RFC3339->parse_datetime($dt_string) }
          || DateTime::Format::ISO8601->parse_datetime($dt_string);
    },
  );

=item inflate_boolean

By default, boolean values in a C<TOML> document result in a C<1> or C<0>.
If L<Types::Serialiser> is installed, they will instead be C<Types::Serialiser::true>
or C<Types::Serialiser::false>.

If you wish to override this, you can provide your own routine to generate values:

  my $parser = TOML::Tiny->new(
    inflate_boolean => sub{
      my $bool = shift;
      if ($bool eq 'true') {
        return 'The Truth';
      } else {
        return 'A Lie';
      }
    },
  );

=item inflate_integer

TOML integers are 64 bit and may not match the size of the compiled perl's
internal integer type. By default, C<TOML::Tiny> coerces numbers that fit
within a perl number by adding C<0>. For bignums, a L<Math::BigInt> is
returned. This may be overridden by providing an inflation routine:

  my $parser = TOML::Tiny->new(
    inflate_integer => sub{
      my $parsed = shift;
      return sprintf 'the number "%d"', $parsed;
    };
  );

=item inflate_float

TOML floats are 64 bit and may not match the size of the compiled perl's
internal float type. As with integers, floats are coerced to numbers and large
floats are upgraded to L<Math::BigFloat>s. The special strings C<NaN> and
C<inf> may also be returned. You can override this by specifying an inflation
routine.

  my $parser = TOML::Tiny->new(
    inflate_float => sub{
      my $parsed = shift;
      return sprintf '"%0.8f" is a float', $parsed;
    };
  );

=item strict

C<strict> imposes some miscellaneous strictures on C<TOML> input, such as
disallowing trailing commas in inline tables and failing on invalid UTF8 input.

B<Note:> C<strict> was previously called C<strict_arrays>. Both are accepted
for backward compatibility, although enforcement of homogenous arrays is no
longer supported as it has been dropped from the spec.

=back

=head2 decode

Decodes C<TOML> and returns a hash ref. Dies on parse error.

=head2 encode

Encodes a perl hash ref as a C<TOML>-formatted string.

=head2 parse

Alias for C<decode> to provide compatibility with C<TOML::Parser> when
overriding the parser by setting C<$TOML::Parser>.

=head1 DIFFERENCES FROM L<TOML> AND L<TOML::Parser>

C<TOML::Tiny> differs in a few significant ways from the L<TOML> module,
particularly in adding support for newer C<TOML> features and strictness.

L<TOML> defaults to lax parsing and provides C<strict_mode> to (slightly)
tighten things up. C<TOML::Tiny> defaults to (somehwat) stricter parsing,
enabling some extra strictures with L</strict>.

C<TOML::Tiny> supports a number of options which do not exist in L<TOML>:
L</inflate_integer>, L</inflate_float>, and L</strict>.

C<TOML::Tiny> ignores invalid surrogate pairs within basic and multiline
strings (L<TOML> may attempt to decode an invalid pair). Additionally, only
those character escapes officially supported by TOML are interpreted as such by
C<TOML::Tiny>.

C<TOML::Tiny> supports stripping initial whitespace and handles lines
terminating with a backslash correctly in multilne strings:

  # TOML input
  x="""
  foo"""

  y="""\
     how now \
       brown \
  bureaucrat.\
  """

  # Perl output
  {x => 'foo', y => 'how now brown bureaucrat.'}

C<TOML::Tiny> includes support for integers specified in binary, octal or hex
as well as the special float values C<inf> and C<nan>.

=head1 SEE ALSO

=over

=item L<TOML::Tiny::Grammar>

Regexp scraps used by C<TOML::Tiny> to parse TOML source.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com> for encouraging their
employees to contribute back to the open source ecosystem. Without their
dedication to quality software development this distribution would not exist.

A big thank you to those who have contributed code or bug reports:

=over

=item L<ijackson|https://github.com/ijackson>

=item L<noctux|https://github.com/noctux>

=item L<oschwald|https://github.com/oschwald>

=item L<jjatria|https://metacpan.org/author/JJATRIA>

=back

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
