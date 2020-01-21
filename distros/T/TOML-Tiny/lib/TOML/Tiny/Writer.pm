package TOML::Tiny::Writer;
$TOML::Tiny::Writer::VERSION = '0.05';
use strict;
use warnings;
no warnings qw(experimental);
use v5.18;

use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use TOML::Tiny::Grammar;
use TOML::Tiny::Util qw(is_strict_array);

my @KEYS;

sub to_toml {
  my $data = shift;
  my %param = @_;
  my @buff;

  for (ref $data) {
    when ('HASH') {
      # Generate simple key/value pairs for scalar data
      for my $k (grep{ ref($data->{$_}) !~ /HASH|ARRAY/ } sort keys %$data) {
        my $key = to_toml_key($k);
        my $val = to_toml($data->{$k}, %param);
        push @buff, "$key=$val";
      }

      # For values which are arrays, generate inline arrays for non-table
      # values, array-of-tables for table values.
      ARRAY: for my $k (grep{ ref $data->{$_} eq 'ARRAY' } sort keys %$data) {
        # Empty table
        if (!@{$data->{$k}}) {
          my $key = to_toml_key($k);
          push @buff, "$key=[]";
          next ARRAY;
        }

        my @inline;
        my @table_array;

        # Sort table and non-table values into separate containers
        for my $v (@{$data->{$k}}) {
          if (ref $v eq 'HASH') {
            push @table_array, $v;
          } else {
            push @inline, $v;
          }
        }

        # Non-table values become an inline table
        if (@inline) {
          my $key = to_toml_key($k);
          my $val = to_toml(\@inline, %param);
          push @buff, "$key=$val";
        }

        # Table values become an array-of-tables
        if (@table_array) {
          push @KEYS, $k;

          for (@table_array) {
            push @buff, '', '[[' . join('.', map{ to_toml_key($_) } @KEYS) . ']]';
            push @buff, to_toml($_);
          }

          pop @KEYS;
        }
      }

      # Sub-tables
      for my $k (grep{ ref $data->{$_} eq 'HASH' } sort keys %$data) {
        if (!keys(%{$data->{$k}})) {
          # Empty table
          my $key = to_toml_key($k);
          push @buff, "$key={}";
        } else {
          # Generate [table]
          push @KEYS, $k;
          push @buff, '', '[' . join('.', map{ to_toml_key($_) } @KEYS) . ']';
          push @buff, to_toml($data->{$k}, %param);
          pop @KEYS;
        }
      }
    }

    when ('ARRAY') {
      if (@$data && $param{strict_arrays}) {
        my ($ok, $err) = is_strict_array($data);
        die "toml: found heterogenous array, but strict_arrays is set ($err)\n" unless $ok;
      }

      push @buff, '[' . join(', ', map{ to_toml($_, %param) } @$data) . ']';
    }

    when ('SCALAR') {
      if ($$_ eq '1') {
        return 'true';
      } elsif ($$_ eq '0') {
        return 'false';
      } else {
        push @buff, to_toml($$_, %param);
      }
    }

    when (/JSON::PP::Boolean/) {
      return $$data ? 'true' : 'false';
    }

    when (/DateTime/) {
      return $data->stringify;
    }

    when ('Math::BigInt') {
      return $data->bstr;
    }

    when ('Math::BigFloat') {
      return $data->bnstr;
    }

    when ('') {
      for ($data) {
        when (looks_like_number($_)) {
          return $data;
        }

        when (/$DateTime/) {
          return $data;
        }

        default{
          return to_toml_string($data);
        }
      }
    }

    default{
      die 'unhandled: '.Dumper($_);
    }
  }

  join "\n", @buff;
}

sub to_toml_key {
  my $str = shift;

  if ($str =~ /^[-_A-Za-z0-9]+$/) {
    return $str;
  }

  if ($str =~ /^"/) {
    return qq{'$str'};
  } else {
    return qq{"$str"};
  }
}

sub to_toml_string {
  state $escape = {
    "\n" => '\n',
    "\r" => '\r',
    "\t" => '\t',
    "\f" => '\f',
    "\b" => '\b',
    "\"" => '\"',
    "\\" => '\\\\',
    "\'" => '\\\'',
  };

  my ($arg) = @_;
  $arg =~ s/([\x22\x5c\n\r\t\f\b])/$escape->{$1}/g;
  $arg =~ s/([\x00-\x08\x0b\x0e-\x1f])/'\\u00' . unpack('H2', $1)/eg;

  return '"' . $arg . '"';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TOML::Tiny::Writer

=head1 VERSION

version 0.05

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
