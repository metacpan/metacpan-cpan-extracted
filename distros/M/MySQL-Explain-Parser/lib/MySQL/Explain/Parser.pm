package MySQL::Explain::Parser;
use 5.008005;
use strict;
use warnings;
use utf8;
use parent "Exporter";
use Text::VisualWidth::PP qw/vtrim/;

our $VERSION = "0.02";
our @EXPORT_OK = qw/parse parse_vertical/;

sub parse {
    my ($explain) = @_;

    my @rows = grep {$_} split /\r?\n/, $explain;

    shift @rows; # Skip the top of outline

    # Skip bottom unnecessary line(s)
    if (pop(@rows) =~ /\A\d+\s+rows/) {
        pop @rows;
    }

    my $index_row = shift @rows;
    my @indexes = grep {$_} split /\|/, $index_row;
    my @indexes_length = map {length $_} @indexes;
    map {s/\s//g} @indexes; ## no critic

    shift @rows; # Skip the separator between header and body

    my @parsed;
    my $num_of_indexes = scalar @indexes;
    for my $row (@rows) {
        my %parsed;
        my $begin_pos = 0;
        for (my $i = 0; $i < $num_of_indexes; $i++) {
            my $length = $indexes_length[$i];
            my $item = vtrim($row, $length + 1);
            $row =~ s/\A\Q$item\E//;
            ($item) = $item =~ /\A\|\s*(.*?)\s*\Z/;

            $parsed{$indexes[$i]} = $item eq 'NULL' ? undef : $item;
        }
        push @parsed, \%parsed;
    }

    return \@parsed;
}

sub parse_vertical {
    my ($explain) = @_;

    my @parsed;
    my @explains;
    my @rows = grep {$_} split /\r?\n/, $explain;
    for my $row (@rows) {
        if ($row =~ /\A\*+\s\d/) {
            if (@explains) {
                push @parsed, _parse_yaml_like(\@explains);
            }
            @explains = ();
            next;
        }

        $row =~ s/\A\s*//;
        push @explains, $row;
    }

    if (@explains) {
        push @parsed, _parse_yaml_like(\@explains);
    }

    return \@parsed;
}

sub _parse_yaml_like {
    my ($explains) = @_;

    if ($explains->[-1] =~ /\A\d+\s+rows/) {
        pop @$explains;
    }

    my %parsed;
    for my $explain (@$explains) {
        (my $v = $explain) =~ s/\s*?([^:]*):\s*//;
        my $k = $1;
        if ($v eq 'NULL') {
            $v = undef;
        }
        $parsed{$k} = $v;
    }
    return \%parsed;
}

1;
__END__

=encoding utf-8

=head1 NAME

MySQL::Explain::Parser - Parser for result of EXPLAIN of MySQL

=head1 SYNOPSIS

    use utf8;
    use MySQL::Explain::Parser qw/parse/;

    my $explain = <<'...';
    +----+-------------+-------+-------+---------------+---------+---------+------+------+----------+-------------+
    | id | select_type | table | type  | possible_keys | key     | key_len | ref  | rows | filtered | Extra       |
    +----+-------------+-------+-------+---------------+---------+---------+------+------+----------+-------------+
    |  1 | PRIMARY     | t1    | index | NULL          | PRIMARY | 4       | NULL | 4    | 100.00   |             |
    |  2 | SUBQUERY    | t2    | index | a             | a       | 5       | NULL | 3    | 100.00   | Using index |
    +----+-------------+-------+-------+---------------+---------+---------+------+------+----------+-------------+
    ...

    my $parsed = parse($explain);
    # =>
    #    [
    #        {
    #            'id'            => '1',
    #            'select_type'   => 'PRIMARY',
    #            'table'         => 't1',
    #            'type'          => 'index',
    #            'possible_keys' => undef,
    #            'key'           => 'PRIMARY',
    #            'key_len'       => '4',
    #            'ref'           => undef
    #            'rows'          => '4',
    #            'filtered'      => '100.00',
    #            'Extra'         => '',
    #        },
    #        {
    #            'id'            => '2',
    #            'select_type'   => 'SUBQUERY',
    #            'table'         => 't2',
    #            'type'          => 'index',
    #            'possible_keys' => 'a',
    #            'key'           => 'a',
    #            'key_len'       => '5',
    #            'ref'           => undef
    #            'rows'          => '3',
    #            'filtered'      => '100.00',
    #            'Extra'         => 'Using index',
    #        }
    #    ]

=head1 DESCRIPTION

MySQL::Explain::Parser is the parser for result of EXPLAIN of MySQL.

This module provides C<parse()> and C<parse_vertical()> function.
These function receive the result of EXPLAIN or EXPLAIN EXTENDED, and return the parsed result as array reference that contains hash reference.

This module treat SQL's C<NULL> as Perl's C<undef>.

Please refer to the following pages to get information about format of EXPLAIN;

=over 4

=item L<http://dev.mysql.com/doc/en/explain-output.html>

=item L<http://dev.mysql.com/doc/en/explain-extended.html>

=back

=head1 FUNCTIONS

=over 4

=item * C<parse($explain : Str)>

Returns the parsed result of EXPLAIN as ArrayRef[HashRef]. This function can be exported.

=item * C<parse_vertical($explain : Str)>

Returns the parsed result of EXPLAIN which is formatted vertical as ArrayRef[HashRef]. This function can be exported.

e.g.

    use utf8;
    use MySQL::Explain::Parser qw/parse_vertical/;

    my $explain = <<'...';
    *************************** 1. row ***************************
               id: 1
      select_type: PRIMARY
            table: t1
             type: index
    possible_keys: NULL
              key: PRIMARY
          key_len: 4
              ref: NULL
             rows: 4
         filtered: 100.00
            Extra:
    *************************** 2. row ***************************
               id: 2
      select_type: SUBQUERY
            table: t2
             type: index
    possible_keys: a
              key: a
          key_len: 5
              ref: NULL
             rows: 3
         filtered: 100.00
            Extra: Using index
    ...

    my $parsed = parse_vertical($explain);

=back

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

