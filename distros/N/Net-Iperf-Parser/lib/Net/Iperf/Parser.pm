package Net::Iperf::Parser;
$Net::Iperf::Parser::VERSION = '0.04';
use Mojo::Base::Tiny -base;

has start          => 0;
has end            => 0;
has is_valid       => 1;
has is_process_avg => 1;
has speed          => 0;

sub duration {
    my $s = shift;
    return $s->end - $s->start;
}

sub is_global_avg {
    my $s = shift;
    return ( $s->is_process_avg && $s->start == 0 && $s->end > 5 ) || 0;
}

sub speedk {
    return shift->speed / 1024;
}

sub speedm {
    return shift->speed / ( 1024 * 1024 );
}

sub dump {
    my $s = shift;

    my @fld = qw/is_valid start end duration speed speedk speedm
        is_process_avg is_global_avg/;

    my $ret = "{\n";

    foreach (@fld) {
        $ret .= "\t$_ => " . $s->$_ . ",\n";
    }

    $ret .= '}';

    return $ret;

}

sub parsecsv {
    my $s   = shift;
    my $row = shift || '';
    if ( $row =~ /\,/ ) {
        $s->{is_valid} = 1;
        my @itms = split( /,/, $row );

        my $t_range = $itms[6];
        ( $s->{start}, $s->{end} ) = map $_ + 0, split( /-/, $t_range );

        $s->{is_process_avg} = ( $itms[5] == -1 || 0 );

        #$s->{speed} = ($itms[-1] / $s->duration);
        $s->{speed} = $itms[-1] + 0;
    } else {
        $s->{is_valid} = 0;
    }
}

sub parse {
    my $s   = shift;
    my $row = shift || '';
    if ( $row =~ /^\[((\s*\d+)|SUM)\]\s+\d/ ) {
        $s->{is_valid} = 1;
        my @itms;
        $row =~ /([\d\.]+-\s*[\d\.]+)\s+sec/;
        my $t_range = $1;
        ( $s->{start}, $s->{end} ) = map $_ + 0, split( /-/, $t_range );

        $s->{is_process_avg} = ( $row =~ /^\[SUM\]/ || 0 );
        $row =~ /\s+([\d\.]+)\s+(\w+)\/sec/;
        if ( $2 eq 'Mbits' ) {
            $s->{speed} = ( $1 + 0 ) * 1024 * 1024;
        } else {
            $s->{speed} = ( $1 + 0 ) * 1024;
        }
    } else {
        $s->{is_valid} = 0;
    }
}

1;

=pod

=head1 NAME

Net::Iperf::Parser - Parse a single iperf line result

=for html <p>
    <a href="https://github.com/emilianobruni/net-iperf-parser/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/emilianobruni/net-iperf-parser/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/emilianobruni/net-iperf-parser">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/emilianobruni/net-iperf-parser">
</p>

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Net::Iperf::Parser;

  my $p = new Net::Iperf::Parser;

  my @rows = `iperf -c iperf.volia.net -P 2`;

  foreach (@rows) {
    $p->parse($_);
    print $p->dump if ($p->is_valid && $p->is_global_avg);
  }

and result is something like this

  {
      is_valid          => 1,
      start             => 0,
      end               => 10,
      duration          => 10,
      speed             => 129024,
      speedk            => 126,
      speedm            => 0.123046875,
      is_process_avg    => 1,
      is_global_avg     => 1,
  }

=head1 DESCRIPTION

Parse a single iperf line result in default or CSV mode

=head1 METHODS

=head2 start

Return the start time

=head2 end

Return the end time

=head2 is_valid

Return if the parsed row is a valid iperf row

=head2 is_process_avg

Return if the row is a process average value

=head2 is_global_avg

Return if the row is the last summary value

=head2 speed

Return the speed calculated in bps

=head2 speedk

Return the speed calculated in Kbps

=head2 speedm

Return the speed calculated in Mbps

=head2 dump

Return a to_string version of the object (like a Data::Dumper::dumper)

=head2 parse($row)

Parse a single iperf line result

=head2 parsecsv($row)

Parse a single iperf line result in CSV mode (-y C)

=encoding UTF-8

=head1 SEE ALSO

L<iperf|https://iperf.fr/>

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Parse a single iperf line result

