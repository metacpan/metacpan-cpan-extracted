package Quote::LineProtocol;

use v5.26;
use warnings;
use Time::Moment;
use Syntax::Keyword::Match;

use Exporter 'import';
our @EXPORT_OK = qw(measurement tags fields timestamp);

our $VERSION = "0.1.0";

my $qr = qr{([,=\s])};    # Match tag and field keys, and tag values
my $qs = qr{(["\\,=\s])}; # Match field string values

sub measurement {
  my $str = shift;
  return $str =~ s{([,\s])}{\Q$1\E}gr;
}

sub tags {
  my (%tags) = @_;
  my @r;

  for my $key (keys %tags) {
    my $val = $tags{$key};
    push @r, sprintf(qq(%s=%s), $key =~ s{$qr}{\Q$1\E}gr, $val =~ s{$qr}{\Q$1\E}gr);
  }

  return join ',', @r;
}

sub fields {
  my (%fields) = @_;
  my @r;

  for my $key (sort keys %fields) {
    my $val = $fields{$key};
    my $type;

    if(ref $val) {
      die "Type missing or invalid for field '$key'" unless exists $val->{type} && $val->{type} =~  /^[fisbu]\z/;
      $type = $val->{type};
      $val = $val->{value};
      die "Type is UInt but value is negative, '$key' = '$val'" if $type eq 'u' && $val < 0;
    }
    else {
      match($val : =~) {
        case(/^-?[0-9]+\.[0-9]+$/) {
          $type = 'f';
        }
        case(/^-?[0-9]+$/) {
          $type = 'i';
        }
        case(/\w+/) {
          $type = 's';
        }
      }
    }

    match($type : eq) {
      case('f') {
        push @r, sprintf(qq(%s=%s),   $key =~ s{$qr}{\Q$1\E}gr, $val);
      }
      case('i') {
        push @r, sprintf(qq(%s=%di),  $key =~ s{$qr}{\Q$1\E}gr, $val);
      }
      case('u') {
        push @r, sprintf(qq(%s=%du),  $key =~ s{$qr}{\Q$1\E}gr, $val);
      }
      case('s') {
        push @r, sprintf(qq)%s="%s"), $key =~ s{$qr}{\Q$1\E}gr, $val =~ s{$qs}{\Q$1\E}gr);
      }
      case('b') {
        push @r, sprintf(qq(%s=%s),   $key =~ s{$qr}{\Q$1\E}gr, $val);
      }
      default {
        push @r, sprintf(qq(%s="%s"), $key =~ s{$qr}{\Q$1\E}gr, $val =~ s{$qs}{\Q$1\E}gr);
      }
    }
  }

  return join ',', @r;
}

sub timestamp {
  my ($unit, $utc) = @_;
  my $now = $utc ? Time::Moment->now_utc : Time::Moment->now;
  return sprintf("%d", sprintf("%d%d", $now->epoch, $unit eq 'ns' ? $now->nanosecond
                                                  : $unit eq 'us' ? $now->microsecond
                                                  : $unit eq 'ms' ? $now->millisecond
                                                  : $now->nanosecond));
}

1;
__END__

=encoding utf-8

=head1 NAME

Quote::LineProtocol - Helper module for Lineprotocol quoting

=head1 SYNOPSIS

    use Quote::LineProtocol qw(measurement tags fields timestamp);
    my $measurement = 'Windows servers';
    my $tags = {Host => 'Server1', Address => 'server1.example.com', Description => 'Service backend'};
    my $fields = {MemoryMax => '4092000000', MemoryUsed => '367848234234', MemoryPrct => {type => 'f', value => 89.89}};

    say sprintf("%s,%s %s %s", measurement($measurement), tags(%$tags), fields(%$fields), timestamp('ns', 1));

    > Windows\ servers,Host=Server1,Address=server1.example.com,Description=Service\ backend MemoryMax=4092000000i,MemoryUsed=367848234234i,MemoryPrct=89.89 1768171443493651000

=head1 DESCRIPTION

    This module provides helper functions to quote key/value pairs of datapoints
    meant to be sent over the InfluxDB lineprotocol following the rules specified
    on L<https://docs.influxdata.com/influxdb/v2/reference/syntax/line-protocol/>

=head1 METHODS

=head2 measurement($str)

Returns a quoted string

=head2 tags(key => value, key2 => value, ...)

Returns the input values quoted and joined with C<,>

=head2 fields(key => value, key2 => value, ...)

Returns the input values quoted and joined with C<,>. The type of C<value> is guessed based on regexps.
The C<value> type can be specified with a hashref and must in that case consist of a C<type> key and C<value> key
where type can be one of:

=over

=item *

C<f> for float

=item *

C<i> for integer

=item *

C<u> for unsigned integer

=item *

C<b> for boolean. In that case the value must be one of

=over

=item -

t, T, true, True, TRUE

=item -

f, F, false, False, FALSE

=back

=item *

C<s> for string

=back

=head2 timestamp([$str, [$utc]])

$str specifies the precision of the timestamp, C<ns>, C<us>, or C<ms>.
If no precision is specified C<ns> is assumed.
$utc tells the function to use UTC time. Local timezone is assumed if not specified

=head1 LICENSE

Copyright (C) Jari Matilainen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

vague E<lt>vague@cpan.orgE<gt>

=cut

