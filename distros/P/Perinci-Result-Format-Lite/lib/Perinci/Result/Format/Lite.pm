package Perinci::Result::Format::Lite;

our $DATE = '2021-03-08'; # DATE
our $VERSION = '0.279'; # VERSION

use 5.010001;
#IFUNBUILT
# use strict;
# use warnings;
#END IFUNBUILT

use List::Util qw(first max);

use Exporter qw(import);
our @EXPORT_OK = qw(format);

# copy-pasted from List::MoreUtils::PP
sub firstidx (&@) {
    my $f = shift;
    foreach my $i ( 0 .. $#_ )
        {
            local *_ = \$_[$i];
            return $i if $f->();
        }
    return -1;
}

sub _json {
    state $json = do {
        if    (eval { require Cpanel::JSON::XS; 1 })   { Cpanel::JSON::XS->new->canonical(1)->convert_blessed->allow_nonref }
        elsif (eval { require JSON::Tiny::Subclassable; 1 }) { JSON::Tiny::Subclassable->new }
        elsif (eval { require JSON::PP; 1 })   { JSON::PP->new->canonical(1)->convert_blessed->allow_nonref }
        else { die "Can't find any JSON module" }
    };
    $json;
};

sub __cleanse {
    state $cleanser = do {
        eval { require Data::Clean::JSON; 1 };
        if ($@) {
            undef;
        } else {
            Data::Clean::JSON->get_cleanser;
        }
    };
    if ($cleanser) {
        $cleanser->clean_in_place($_[0]);
    } else {
        $_[0];
    }
}

sub __gen_table {
    my ($data, $header_row, $resmeta, $format) = @_;

    $resmeta //= {};

    # column names
    my @columns;
    if ($header_row) {
        @columns = @{$data->[0]};
    } else {
        @columns = map {"col$_"} 0..@{$data->[0]}-1;
    }

    my $column_orders; # e.g. [col2, col1, col3, ...]
  SET_COLUMN_ORDERS: {

        # find column orders from 'table_column_orders' in result metadata (or
        # from env)
        my $tcos;
        if ($ENV{FORMAT_PRETTY_TABLE_COLUMN_ORDERS}) {
            $tcos = _json->encode($ENV{FORMAT_PRETTY_TABLE_COLUMN_ORDERS});
        } elsif (my $rfos = ($resmeta->{'cmdline.format_options'} //
                                 $resmeta->{format_options})) {
            my $rfo = $rfos->{'text-pretty'} // $rfos->{text} // $rfos->{any};
            if ($rfo) {
                $tcos = $rfo->{table_column_orders};
            }
        }
        if ($tcos) {
            # find an entry in tcos that @columns contains all the columns of
          COLS:
            for my $cols (@$tcos) {
                for my $col (@$cols) {
                    next COLS unless first {$_ eq $col} @columns;
                }
                $column_orders = $cols;
                last SET_COLUMN_ORDERS;
            }
        }

        if ($resmeta->{'table.field_orders'}) {
            $column_orders = $resmeta->{'table.field_orders'};
            last SET_COLUMN_ORDERS;
        }

        # find column orders from table spec
        $column_orders = $resmeta->{'table.fields'};
    }

    # reorder each row according to requested column order
    if ($column_orders) {
        require Sort::BySpec;
        my $cmp = Sort::BySpec::cmp_by_spec(spec => $column_orders);
        # 0->2, 1->0, ... (map column position from unordered to ordered)
        my @map0 = sort { $cmp->($a->[1], $b->[1]) }
            map {[$_, $columns[$_]]} 0..$#columns;
        #use DD; dd \@map0;
        my @map;
        for (0..$#map0) {
            $map[$_] = $map0[$_][0];
        }
        #use DD; dd \@map;
        my $newdata = [];
        for my $row (@$data) {
            my @newrow;
            for (0..$#map) { $newrow[$_] = $row->[$map[$_]] }
            push @$newdata, \@newrow;
        }
        $data = $newdata;
        my @newcolumns;
        for (@map) { push @newcolumns, $columns[$_] }
        @columns = @newcolumns;
    }

    my @field_idxs; # map column to index in table.fields
    {
        my $tff = $resmeta->{'table.fields'} or last;
        for my $i (0..$#columns) {
            $field_idxs[$i] = firstidx { $_ eq $columns[$i] } @$tff;
        }
    }

    # determine field labels
    {
        last unless $header_row && @$data;
        my $tff = $resmeta->{'table.fields'} or last;
        my $tfl = $resmeta->{'table.field_labels'};
        my $tfu = $resmeta->{'table.field_units'};
        for my $i (0..$#columns) {
            my $field_idx = $field_idxs[$i];
            next unless $field_idx >= 0;
            if ($tfl && defined $tfl->[$field_idx]) {
                $data->[0][$i] = $tfl->[$field_idx];
            } elsif ($tfu && defined $tfu->[$field_idx]) {
                # add field units as label suffix to header (" (UNIT)")
                $data->[0][$i] .= " ($tfu->[$field_idx])";
            }
        }
    }

  FORMAT_CELLS:
    {
        my $tffmt         = $resmeta->{'table.field_formats'};
        my $tffmt_code    = $resmeta->{'table.field_format_code'};
        my $tffmt_default = $resmeta->{'table.default_field_format'};
        last unless $tffmt || $tffmt_code || $tffmt_default;

        my (@fmt_names, @fmt_opts); # key: column index
        for my $i (0..$#columns) {
            my $field_idx = $field_idxs[$i];
            my $fmt = $tffmt_code ? $tffmt_code->($columns[$i]) : undef;
            $fmt //= $tffmt->[$field_idx] if $field_idx >= 0;
            $fmt //= $tffmt_default;
            if (ref $fmt eq 'ARRAY') {
                $fmt_names[$i] = $fmt->[0];
                $fmt_opts [$i] = $fmt->[1] // {};
            } else {
                $fmt_names[$i] = $fmt;
                $fmt_opts [$i] = {};
            }
        }

        my $nf;

        for my $i (0..$#{$data}) {
            next if $i==0 && $header_row;
            my $row = $data->[$i];
            for my $j (0..$#columns) {
                next unless defined $row->[$j];
                my $fmt_name = $fmt_names[$j];
                #say "D:j=$j fmt_name=$fmt_name";
                next unless $fmt_name;
                my $fmt_opts = $fmt_opts [$j];
                if ($fmt_name eq 'iso8601_datetime' || $fmt_name eq 'iso8601_date') {
                    if ($row->[$j] =~ /\A[0-9]+(\.[0-9]*)?\z/) {
                        my $frac = $1 ? "0$1"+0 : 0;
                        my @t = gmtime($row->[$j]);
                        if ($fmt_name eq 'iso8601_datetime') {
                            $row->[$j] = sprintf(
                                "%04d-%02d-%02dT%02d:%02d:".($frac ? "%06.3f" : "%02d")."Z",
                                $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]+$frac);
                        } else {
                            $row->[$j] = sprintf(
                                "%04d-%02d-%02d",
                                $t[5]+1900, $t[4]+1, $t[3]);
                        }
                    }
                } elsif ($fmt_name eq 'boolstr') {
                    $row->[$j] = $row->[$j] ? "yes" : "no";
                } elsif ($fmt_name eq 'filesize') {
                    require Format::Human::Bytes;
                    $row->[$j] = Format::Human::Bytes::base2($row->[$j], 0);
                } elsif ($fmt_name eq 'sci2dec') {
                    if ($row->[$j] =~ /\A(?:[+-]?)(?:\d+\.|\d*\.(\d+))[eE]([+-]?\d+)\z/) {
                        my $n = length($1 || "") - $2; $n = 0 if $n < 0;
                        $row->[$j] = sprintf("%.${n}f", $row->[$j]);
                    }
                } elsif ($fmt_name eq 'percent') {
                    my $fmt = $fmt_opts->{sprintf} // '%.2f%%';
                    $row->[$j] = sprintf($fmt, $row->[$j] * 100);
                } elsif ($fmt_name eq 'number') {
                    require Number::Format::BigFloat;
                    $row->[$j] = Number::Format::BigFloat::format_number(
                        $row->[$j], {
                            thousands_sep  => $fmt_opts->{thousands_sep} // ',',
                            decimal_point  => $fmt_opts->{decimal_point} // '.',
                            decimal_digits => $fmt_opts->{precision} // 0,
                            # XXX decimal_fill
                        });
                }
            }
        }
    }

    if ($format eq 'text-pretty') {
      ALIGN_COLUMNS:
        {
            # XXX we just want to turn off 'uninitialized' and 'negative repeat
            # count does nothing' from the operator x
            no warnings;

            my $tfa         = $resmeta->{'table.field_aligns'};
            my $tfa_code    = $resmeta->{'table.field_align_code'};
            my $tfa_default = $resmeta->{'table.default_field_align'};
            last unless $tfa || $tfa_code || $tfa_default;
            last unless @$data;

            for my $colidx (0..$#columns) {
                my $field_idx = $field_idxs[$colidx];
                my $align = $tfa_code ? $tfa_code->($columns[$colidx]) : undef;
                $align //= $tfa->[$field_idx] if $field_idx >= 0;
                $align //= $tfa_default;
                next unless $align;

                # determine max widths
                my $maxw;
                my ($maxw_bd, $maxw_d, $maxw_ad); # before digit, digit, after d
                if ($align eq 'number') {
                    my (@w_bd, @w_d, @w_ad);
                    for my $i (0..$#{$data}) {
                        my $row = $data->[$i];
                        if (@$row > $colidx) {
                            my $cell = $row->[$colidx];
                            if ($header_row && $i == 0) {
                                my $w = length($cell);
                                push @w_bd, 0;
                                push @w_bd, 0;
                                push @w_ad, 0;
                            } elsif ($cell =~ /\A([+-]?\d+)(\.?)(\d*)\z/) {
                                # decimal notation number
                                push @w_bd, length($1);
                                push @w_d , length($2);
                                push @w_ad, length($3);
                            } elsif ($cell =~ /\A([+-]?\d+\.?\d*)([eE])([+-]?\d+)\z/) {
                                # scientific notation number
                                push @w_bd, length($1);
                                push @w_d , length($2);
                                push @w_ad, length($3);
                            } else {
                                # not a number
                                push @w_bd, length($cell);
                                push @w_bd, 0;
                                push @w_ad, 0;
                            }
                        } else {
                            push @w_bd, 0;
                            push @w_d , 0;
                            push @w_ad, 0;
                        }
                    }
                    $maxw_bd = max(@w_bd);
                    $maxw_d  = max(@w_d);
                    $maxw_ad = max(@w_ad);
                    if ($header_row) {
                        my $w = length($data->[0][$colidx]);
                        if ($maxw_d == 0 && $maxw_ad == 0) {
                            $maxw_bd = $w;
                        }
                    }
                }

                $maxw = max(map {
                    @$_ > $colidx ? length($_->[$colidx]) : 0
                } @$data);

                # do the alignment
                for my $i (0..$#{$data}) {
                    my $row = $data->[$i];
                    for my $i (0..$#{$data}) {
                        my $row = $data->[$i];
                        next unless @$row > $colidx;
                        my $cell = $row->[$colidx];
                        next unless defined($cell);
                        if ($align eq 'number') {
                            my ($bd, $d, $ad);
                            if ($header_row && $i == 0) {
                            } elsif (($bd, $d, $ad) = $cell =~ /\A([+-]?\d+)(\.?)(\d*)\z/) {
                                $cell = join(
                                    '',
                                    (' ' x ($maxw_bd - length($bd))), $bd,
                                    $d , (' ' x ($maxw_d  - length($d ))),
                                    $ad, (' ' x ($maxw_ad - length($ad))),
                                );
                            } elsif (($bd, $d, $ad) = $cell =~ /\A([+-]?\d+\.?\d*)([eE])([+-]?\d+)\z/) {
                                $cell = join(
                                    '',
                                    (' ' x ($maxw_bd - length($bd))), $bd,
                                    $d , (' ' x ($maxw_d  - length($d ))),
                                    $ad, (' ' x ($maxw_ad - length($ad))),
                                );
                            }
                            my $w = length($cell);
                            $cell = (' ' x ($maxw - $w)) . $cell
                                if $maxw > $w;
                        } elsif ($align eq 'right') {
                            $cell = (' ' x ($maxw - length($cell))) . $cell;
                        } elsif ($align eq 'middle' || $align eq 'center') {
                            my $w = length($cell);
                            my $n = int(($maxw-$w)/2);
                            $cell = (' ' x $n) . $cell . (' ' x ($maxw-$w-$n));
                        } else {
                            # assumed left
                            $cell .= (' ' x ($maxw - length($cell)));

                        }
                        $row->[$colidx] = $cell;
                    }
                }
            } # for $colidx
        } # END align columns

        my $fres;
        my $backend = $ENV{FORMAT_PRETTY_TABLE_BACKEND};
        $backend //= "Text::Table::Org" if $ENV{INSIDE_EMACS};
        if ($backend) {
            require Text::Table::Any;
            $fres = Text::Table::Any::table(rows=>$data, header_row=>$header_row, backend=>$backend);
        } else {
            require Text::Table::Sprintf;
            $fres = Text::Table::Sprintf::table(rows=>$data, header_row=>$header_row);
        }
        $fres .= "\n" unless $fres =~ /\R\z/ || !length($fres);
        $fres;
    } elsif ($format eq 'csv') {
        no warnings 'uninitialized';
        join(
            "",
            map {
                my $row = $_;
                join(
                    ",",
                    map {
                        my $cell = $_;
                        $cell =~ s/(["\\])/\\$1/g;
                        qq("$cell");
                    } @$row)."\n";
            } @$data
        );
    } elsif ($format eq 'html') {
        no warnings 'uninitialized';
        require HTML::Entities;

        my $tfa = $resmeta->{'table.field_aligns'};

        my @res;
        push @res, "<table".($resmeta->{'table.html_class'} ?
                                 " class=\"".HTML::Entities::encode_entities(
                                     $resmeta->{'table.html_class'})."\"" : "").
                                         ">\n";
        for my $i (0..$#{$data}) {
            my $data_elem = $i == 0 ? "th" : "td";
            push @res, "<thead>\n" if $i == 0;
            push @res, "<tbody>\n" if $i == 1;
            push @res, " <tr>\n";
            my $row = $data->[$i];
            for my $j (0..$#{$row}) {
                my $field_idx = $field_idxs[$j];
                my $align;
                if ($field_idx >= 0 && $tfa->[$field_idx]) {
                    $align = $tfa->[$field_idx];
                    $align = "right" if $align eq 'number';
                    $align = "middle" if $align eq 'center';
                }
                push @res, "  <$data_elem",
                    ($align ? " align=\"$align\"" : ""),
                    ">", HTML::Entities::encode_entities($row->[$j]),
                    "</$data_elem>\n";
            }
            push @res, " </tr>\n";
            push @res, "</thead>\n" if $i == 0;
        }
        push @res, "</tbody>\n";
        push @res, "</table>\n";
        join '', @res;
    } else {
        no warnings 'uninitialized';
        shift @$data if $header_row;
        join("", map {join("\t", @$_)."\n"} @$data);
    }
}

sub format {
    my ($res, $format, $is_naked, $cleanse) = @_;

    if ($format =~ /\A(text|text-simple|text-pretty|csv|html)\z/) {
        $format = $format eq 'text' ?
            ((-t STDOUT) ? 'text-pretty' : 'text-simple') : $format;
        no warnings 'uninitialized';
        if ($res->[0] !~ /^(2|304)/) {
            my $fres = "ERROR $res->[0]: $res->[1]";
            if (my $prev = $res->[3]{prev}) {
                $fres .= " ($prev->[0]: $prev->[1])";
            }
            return "$fres\n";
        } elsif ($res->[3] && $res->[3]{"x.hint.result_binary"}) {
            return $res->[2];
        } else {
            require Data::Check::Structure;
            my $data = $res->[2];
            my $max = 1000;
            if (!ref($data)) {
                $data //= "";
                $data .= "\n" unless !length($data) || $data =~ /\n\z/;
                return $data;
            } elsif (ref($data) eq 'ARRAY' && !@$data) {
                return "";
            } elsif (Data::Check::Structure::is_aos($data, {max=>$max})) {
                return join("", map {"$_\n"} @$data);
            } elsif (Data::Check::Structure::is_aoaos($data, {max=>$max})) {
                my $header_row = 0;
                my $data = $data;
                if ($res->[3]{'table.fields'}) {
                    $data = [$res->[3]{'table.fields'}, @$data];
                    $header_row = 1;
                }
                return __gen_table($data, $header_row, $res->[3], $format);
            } elsif (Data::Check::Structure::is_hos($data, {max=>$max})) {
                $data = [map {[$_, $data->{$_}]} sort keys %$data];
                unshift @$data, ["key", "value"];
                return __gen_table($data, 1, $res->[3], $format);
            } elsif (Data::Check::Structure::is_aohos($data, {max=>$max})) {
                # collect all mentioned fields
                my @fieldnames;
                if ($res->[3] && $res->[3]{'table.fields'} &&
                        $res->[3]{'table.hide_unknown_fields'}) {
                    @fieldnames = @{ $res->[3]{'table.fields'} };
                } else {
                    my %fieldnames;
                    for my $row (@$data) {
                        $fieldnames{$_}++ for keys %$row;
                    }
                    @fieldnames = sort keys %fieldnames;
                }
                my $newdata = [];
                for my $row (@$data) {
                    push @$newdata, [map {$row->{$_}} @fieldnames];
                }
                unshift @$newdata, \@fieldnames;
                return __gen_table($newdata, 1, $res->[3], $format);
            } else {
                $format = 'json-pretty';
            }
        }
    }

    my $tff = $res->[3]{'table.fields'};
    $res = $res->[2] if $is_naked;

    if ($format eq 'perl') {
        my $use_color = $ENV{COLOR} // (-t STDOUT);
        if ($use_color && eval { require Data::Dump::Color; 1 }) {
            return Data::Dump::Color::dump($res);
        } elsif (eval { require Data::Dump; 1 }) {
            return Data::Dump::dump($res);
        } else {
            no warnings 'once';
            require Data::Dumper;
            local $Data::Dumper::Terse = 1;
            local $Data::Dumper::Indent = 1;
            local $Data::Dumper::Useqq = 1;
            local $Data::Dumper::Deparse = 1;
            local $Data::Dumper::Quotekeys = 0;
            local $Data::Dumper::Sortkeys = 1;
            local $Data::Dumper::Trailingcomma = 1;
            return Data::Dumper::Dumper($res);
        }
    }

    unless ($format =~ /\Ajson(-pretty)?\z/) {
        warn "Unknown format '$format', fallback to json-pretty";
        $format = 'json-pretty';
    }
    __cleanse($res) if ($cleanse//1);
    if ($format =~ /json/) {
        if ($tff && _json->can("sort_by") &&
                eval { require Sort::ByExample; 1}) {
            my $cmp = Sort::ByExample->cmp($tff);
            _json->sort_by(sub { $cmp->($JSON::PP::a, $JSON::PP::b) });
        }

        if ($format eq 'json') {
            return _json->encode($res) . "\n";
        } else {
            _json->pretty(1);
            return _json->encode($res);
        }
    }
}

1;
# ABSTRACT: Format enveloped result

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Result::Format::Lite - Format enveloped result

=head1 VERSION

This document describes version 0.279 of Perinci::Result::Format::Lite (from Perl distribution Perinci-Result-Format-Lite), released on 2021-03-08.

=head1 SYNOPSIS

=head1 DESCRIPTION

=for Pod::Coverage ^(firstidx)$

=head1 FUNCTIONS

=head2 format($res, $format[ , $is_naked=0, $cleanse=1 ]) => str

=head1 ENVIRONMENT

=head2 FORMAT_PRETTY_TABLE_BACKEND => str

If this is set, will render text table using L<Text::Table::Any> (with
C<backend> set to the value of this environment variable) instead of the default
L<Text::Table::Sprintf>. This is useful if you want to output text table in a
different format, for example to generate Org tables (make sure
L<Text::Table::Org> backend is already installed):

 % FORMAT_PRETTY_TABLE_BACKEND=Text::Table::Org lcpan rdeps Getopt::Lucid

For convenience, a default is chosen for you under certain condition. When
inside Emacs (environment C<INSIDE_EMACS> is set), C<Text::Table::Org> is used
as default.

=head2 FORMAT_PRETTY_TABLE_COLUMN_ORDERS => array (json)

Set the default of C<table_column_orders> in C<format_options> in result
metadata, similar to what's implemented in L<Perinci::Result::Format> and
L<Data::Format::Pretty::Console>.

=head2 COLOR => bool

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Result-Format-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Result-Format-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Perinci-Result-Format-Lite/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Result::Format>, a more heavyweight version of this module.

L<Perinci::CmdLine::Lite> uses this module to format enveloped result.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
