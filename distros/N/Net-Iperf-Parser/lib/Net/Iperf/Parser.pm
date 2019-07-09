package Net::Iperf::Parser;
$Net::Iperf::Parser::VERSION = '0.01';
use Moose;
use namespace::autoclean;

# ABSTRACT: Parse a single iperf line result


has start           => ( is => 'ro', isa => 'Int', default => 0  );
has end             => ( is => 'ro', isa => 'Int', default => 0  );
has is_valid        => ( is => 'ro', isa => 'Bool', default => 1 );
has is_process_avg  => ( is => 'ro', isa => 'Bool', default => 1 );
has speed           => ( is => 'ro', isa => 'Num', default => 0  );


sub duration {
    my $s   = shift;
    return $s->end - $s->start;
}

sub is_global_avg {
    my $s   = shift;
    return ($s->is_process_avg && $s->start == 0 && $s->end > 5) || 0;
}

sub speedk {
    return shift->speed / 1024;
}

sub speedm {
    return shift->speed / (1024 * 1024);
}

sub dump {
    my $s = shift;

    my @fld = qw/is_valid start end duration speed speedk speedm
        is_process_avg is_global_avg/;

    my $ret = "{\n";

    foreach(@fld) {
        $ret .= "\t$_ => " . $s->$_ . ",\n";
    }

    $ret .= '}';

    return $ret;

}


sub parsecsv {
    my $s       = shift;
    my $row     = shift || '';
    if ($row =~ /\,/) {
        $s->{is_valid} = 1;
        my @itms = split(/,/,$row);

        my $t_range = $itms[6];
        ($s->{start},$s->{end}) = map $_+0, split(/-/, $t_range);

        $s->{is_process_avg} = ($itms[5] == -1 || 0);
        #$s->{speed} = ($itms[-1] / $s->duration);
        $s->{speed} = $itms[-1] + 0;
    } else {
        $s->{is_valid} = 0;
    }
}

sub parse {
    my $s       = shift;
    my $row     = shift || '';
    if ($row =~ /^\[((\s*\d+)|SUM)\]\s+\d/) {
        $s->{is_valid} = 1;
        my @itms;
        $row =~ /([\d\.]+-\s*[\d\.]+)\s+sec/;
        my $t_range = $1;
        ($s->{start},$s->{end}) = map $_+0, split(/-/, $t_range);

        $s->{is_process_avg} = ($row =~ /^\[SUM\]/ || 0);
        $row =~/\s+([\d\.]+)\s+(\w+)\/sec/;
        if ($2 eq 'Mbits') {
            $s->{speed} = ($1+0) * 1024 * 1024;
        } else {
            $s->{speed} = ($1+0) * 1024;
        }
    } else {
        $s->{is_valid} = 0;
    }
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Iperf::Parser - Parse a single iperf line result

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Net::Iperf::Parser;

  my $p = new Net::Iperf::Parser;

  $p->parse($row);
  print $p->dump;

=head1 DESCRIPTION

Parse a single iperf line result in default or CSV mode

=head1 METHODS

=head2 start

Return the start range

=head2 end

Return the end range

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

=head2 parsed

=head2 parsecsv

=head1 SEE ALSO

L<Net::OpenSSH>

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
