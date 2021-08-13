package TOML::Tiny::Writer;
$TOML::Tiny::Writer::VERSION = '0.15';
use strict;
use warnings;
no warnings qw(experimental);
use v5.18;

use B qw(svref_2object SVf_IOK SVf_NOK);
use Data::Dumper;
use TOML::Tiny::Grammar;
use TOML::Tiny::Util qw(is_strict_array);

my @KEYS;

sub to_toml {
  my $data  = shift;
  my $param = ref($_[1]) eq 'HASH' ? $_[1] : undef;

  for (ref $data) {
    when ('HASH') {
      return to_toml_table($data, $param);
    }

    when ('ARRAY') {
      return to_toml_array($data, $param);
    }

    when ('SCALAR') {
      if ($$data eq '1') {
        return 'true';
      } elsif ($$data eq '0') {
        return 'false';
      } else {
        return to_toml($$_, $param);
      }
    }

    when ('JSON::PP::Boolean') {
      return $$data ? 'true' : 'false';
    }

    when ('Types::Serializer::Boolean') {
      return $data ? 'true' : 'false';
    }

    when ('DateTime') {
      return strftime_rfc3339($data);
    }

    when ('Math::BigInt') {
      return $data->bstr;
    }

    when ('Math::BigFloat') {
      if ($data->is_inf || $data->is_nan) {
        return lc $data->bstr;
      } else {
        return $data->bstr;
      }
    }

    when ('') {
      # Thanks to ikegami on Stack Overflow for the trick!
      # https://stackoverflow.com/questions/12686335/how-to-tell-apart-numeric-scalars-and-string-scalars-in-perl/12693984#12693984
      # note: this must come before any regex can flip this flag off
      if (svref_2object(\$data)->FLAGS & (SVf_IOK | SVf_NOK)) {
        return 'inf'  if Math::BigFloat->new($data)->is_inf;
        return '-inf' if Math::BigFloat->new($data)->is_inf('-');
        return 'nan'  if Math::BigFloat->new($data)->is_nan;
        return $data;
      }
      #return $data if svref_2object(\$data)->FLAGS & (SVf_IOK | SVf_NOK);
      return $data if $data =~ /$DateTime/;
      return lc($data) if $data =~ /^$SpecialFloat$/;

      return to_toml_string($data);
    }

    default{
      die 'unhandled: '.Dumper($_);
    }
  }
}

sub to_toml_inline_table {
  my ($data, $param) = @_;
  my @buff;

  for my $key (keys %$data) {
    my $value = $data->{$key};

    if (ref $value eq 'HASH') {
      push @buff, $key . '=' . to_toml_inline_table($value);
    } else {
      push @buff, $key . '=' . to_toml($value);
    }
  }

  return '{' . join(', ', @buff) . '}';
}

sub to_toml_table {
  my ($data, $param) = @_;
  my @buff_assign;
  my @buff_tables;

  # Generate simple key/value pairs for scalar data
  for my $k (grep{ ref($data->{$_}) !~ /HASH|ARRAY/ } sort keys %$data) {
    my $key = to_toml_key($k);
    my $val = to_toml($data->{$k}, $param);
    push @buff_assign, "$key=$val";
  }

  # For arrays, generate an array of tables if all elements of the array are
  # hashes. For mixed arrays, generate an inline array.
  ARRAY: for my $k (grep{ ref $data->{$_} eq 'ARRAY' } sort keys %$data) {
    # Empty table
    if (!@{$data->{$k}}) {
      my $key = to_toml_key($k);
      push @buff_assign, "$key=[]";
      next ARRAY;
    }

    # Mixed array
    if (grep{ ref $_ ne 'HASH' } @{$data->{$k}}) {
      my $key = to_toml_key($k);
      my $val = to_toml($data->{$k}, $param);
      push @buff_assign, "$key=$val";
    }
    # Array of tables
    else {
      push @KEYS, $k;

      for (@{ $data->{$k} }) {
        push @buff_tables, '', '[[' . join('.', map{ to_toml_key($_) } @KEYS) . ']]';
        push @buff_tables, to_toml($_);
      }

      pop @KEYS;
    }
  }

  # Sub-tables
  for my $k (grep{ ref $data->{$_} eq 'HASH' } sort keys %$data) {
    if (!keys(%{$data->{$k}})) {
      # Empty table
      my $key = to_toml_key($k);
      push @buff_assign, "$key={}";
    } else {
      # Generate [table]
      push @KEYS, $k;
      push @buff_tables, '', '[' . join('.', map{ to_toml_key($_) } @KEYS) . ']';
      push @buff_tables, to_toml($data->{$k}, $param);
      pop @KEYS;
    }
  }

  join "\n", @buff_assign, @buff_tables;
}

sub to_toml_array {
  my ($data, $param) = @_;

  if (@$data && $param->{strict}) {
    my ($ok, $err) = is_strict_array($data);
    die "toml: found heterogenous array, but strict is set ($err)\n" unless $ok;
  }

  my @items;

  for my $item (@$data) {
    if (ref $item eq 'HASH') {
      push @items, to_toml_inline_table($item, $param);
    } else {
      push @items, to_toml($item, $param);
    }
  }

  return "[\n" . join("\n", map{ "  $_," } @items) . "\n]";
}

sub to_toml_key {
  my $str = shift;

  if ($str =~ /^$BareKey$/) {
    return $str;
  }

  # Escape control characters
  $str =~ s/([\p{General_Category=Control}])/'\\u00' . unpack('H2', $1)/eg;

  # Escape unicode characters
  #$str =~ s/($NonASCII)/'\\u00' . unpack('H2', $1)/eg;

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
  $arg =~ s/(["\\\b\f\n\r\t])/$escape->{$1}/g;
  $arg =~ s/([\p{General_Category=Control}])/'\\u00' . unpack('H2', $1)/eg;

  return '"' . $arg . '"';
}

#-------------------------------------------------------------------------------
# Adapted from DateTime::Format::RFC3339.
#-------------------------------------------------------------------------------
sub strftime_rfc3339 {
  my ($dt) = @_;
  my $tz;

  #-----------------------------------------------------------------------------
  # Calculate the time zone offset for non-UTC time zones.
  #
  # TOML uses RFC3339 for datetimes, but supports a "local datetime" which
  # excludes the timezone offset. A DateTime with a floating time zone
  # indicates a TOML local datetime.
  #
  # DateTime::Format::RFC3339 requires a time zone, however, and defaults to
  # +00:00 for floating time zones. To support local datetimes in output,
  # format the datetime as RFC3339 and strip the timezone when encountering a
  # floating time zone.
  #-----------------------------------------------------------------------------
  if ($dt->time_zone_short_name eq 'floating') {
    $tz = '';
  } elsif ($dt->time_zone->is_utc) {
    $tz = 'Z';
  } else {
    my $sign = $dt->offset < 0 ? '-' : '+';
    my $secs = abs $dt->offset;

    my $mins = int($secs / 60);
    $secs %= 60;

    my $hours = int($mins / 60);
    $mins %= 60;

    if ($secs) {
      $dt = $dt->clone;
      $dt->set_time_zone('UTC');
      $tz = 'Z';
    } else {
      $tz = sprintf '%s%02d:%02d', $sign, $hours, $mins;
    }
  }

  my $format = $dt->nanosecond ? '%Y-%m-%dT%H:%M:%S.%9N' : '%Y-%m-%dT%H:%M:%S';
  return $dt->strftime($format) . $tz;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TOML::Tiny::Writer

=head1 VERSION

version 0.15

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
