package PCL::Simple;

=head1 NAME

PCL::Simple - Create PCL for printing plain text files

=head1 SYNOPSIS

  use PCL::Simple qw( PCL_pre PCL_post );

  open PLAIN,  '<plain_file.txt'         or die;
  open SNAZZY, '>ready_for_printing.txt' or die;

  print SNAZZY PCL_pre( -w => 132, -lpp => 66 );
  print SNAZZY while (<PLAIN>);
  print SNAZZY PCL_post;

  close PLAIN;
  close SNAZZY;

=head1 DESCRIPTION

PCL::Simple will provide PCL strings that cause your printer to print a plain text file with *exactly* the right font -- i.e. the exact font needed to fill the page with as many fixed width characters across and down as you specify.

In addition to providing for your desired width and height layout, the provided PCL strings will also cause the printer to honor your other desires regarding paper size, paper orientation, sides printed, and number of copies.

=head1 USAGE

Two functions are exportable: PCL_pre and  PCL_post.

PCL_post takes no parameters, it simply returns a string containing the "Printer Reset Command" and "Universal Exit Language Command" as specified by PCL documentation.  This string is meant for appending to the end of your plain text document.

PCL_pre takes a list or an href of key value pairs and returns a PCL string for insertion at the beginning of your plain text document.  PCL_pre Paramaters are:

=over 2

=item C<-w>

Width (Required)

=item C<-lpp>

Lines Per Page (Required)

=item C<-ms>

Media Size defaults to letter.  Valid values are: executive, letter, legal, ledger, a4, a3, monarch, com-10, d1, c5, b5

=item C<-msrc>

Media Source is not set by default.  Valid values are: numbers from 0 to 69.  Generally refers to paper trays or feeders.  See your printer documentation for details.

=item C<-o>

Orientation defaults to portrait.  Valid values are: landscape, portrait.

=item C<-s>

Sides defaults to 0.  Valid values are: 0 (Single), 1 (Double Long), 2 (Double Short)

=item C<-c>

Copies defaults to 1.

=back 2

=cut

use base Exporter;

use vars qw/ @EXPORT_OK $VERSION /;
@EXPORT_OK = qw/ PCL_pre PCL_post /;
$VERSION = 1.01;

# for converting millemeters to inches
use constant MM_PER_IN => 25.4;

# used in logical page setup to convert dot values to inches
use constant DPI_LP_CALC => 300;

sub PCL_pre {

    my $args;
    if ($#_) {
        $args = { @_ };
    } elsif (ref $_[0] eq 'HASH') {
        $args = $_[0];
    } else {
        die "parameters to PCL_pre must be in list or href format!"
    }

    # acceptable key => value combinations
    my $ok = {
        -w      =>  qr/^\d+$/,
        -lpp    =>  qr/^\d+$/,
        -ms     =>  [qw/ executive letter legal ledger a4 a3 monarch com-10 d1 c5 b5 /],
        -msrc   =>  [ 0..69 ],
        -o      =>  qr/^(landscape|portrait)$/i,
        -s      =>  [ 0, 1, 2 ],
        -c      =>  qr/^\d+$/,
    };

    # make sure all parms are ok
    for my $key (keys %{$args}) {
        die "An invalid parameter key ($key) was passed to PCL_pre!" unless ( grep /^$key$/ => keys(%{$ok}) );
        if (ref $ok->{$key} eq 'Regexp') {
            die "An invalid paramater value ($args->{$key}) was passed to PCL_pre!" unless ( $args->{$key} =~ /$ok->{$key}/ );
        } else {
            die "An invalid paramater value ($args->{$key}) was passed to PCL_pre!" unless ( grep /^$args->{$key}$/ => @{$ok->{$key}} );
        }
    }

    die "No width was specified!" unless $args->{-w};
    die "No lines per page was specified!" unless $args->{-lpp};

    $args->{-ms} = 'letter'   unless (defined $args->{-ms});
    $args->{-o}  = 'portrait' unless (defined $args->{-o});
    $args->{-s}  = 0          unless (defined $args->{-s});
    $args->{-c}  = 1          unless (defined $args->{-c});

    my %page =
    (
        executive =>
        {
                        type                    => 'paper',
                        note                    => 'Executive',
                        page_size_code          => 1,
                        physical_page_width     => 7.25,            # inches
                        physical_page_length    => 10.5,            # inches
                        logical_page_width      =>
                        {
                            portrait  => 2025 / DPI_LP_CALC,        # inches
                            landscape => 3030 / DPI_LP_CALC,        # inches
                        },
        },
        letter =>
        {
                        type                    => 'paper',
                        note                    => 'Letter',
                        page_size_code          => 2,
                        physical_page_width     => 8.5,
                        physical_page_length    => 11,
                        logical_page_width      =>
                        {
                            portrait  => 2400 / DPI_LP_CALC,
                            landscape => 3180 / DPI_LP_CALC,
                        },
        },
        legal =>
        {
                        type                    => 'paper',
                        note                    => 'Legal',
                        page_size_code          => 3,
                        physical_page_width     => 8.5,
                        physical_page_length    => 14,
                        logical_page_width      =>
                        {
                            portrait  => 2400 / DPI_LP_CALC,
                            landscape => 4080 / DPI_LP_CALC,
                        },
        },
        ledger =>
        {
                        type                    => 'paper',
                        note                    => 'Ledger',
                        page_size_code          => 6,
                        physical_page_width     => 11,
                        physical_page_length    => 17,
                        logical_page_width      =>
                        {
                            portrait  => 3150 / DPI_LP_CALC,
                            landscape => 4980 / DPI_LP_CALC,
                        },
        },
        a4 =>
        {
                        type                    => 'paper',
                        note                    => 'A4',
                        page_size_code          => 26,
                        physical_page_width     => 210 / MM_PER_IN,
                        physical_page_length    => 297 / MM_PER_IN,
                        logical_page_width      =>
                        {
                            portrait  => 2338 / DPI_LP_CALC,
                            landscape => 3389 / DPI_LP_CALC,
                        },
        },
        a3 =>
        {
                        type                    => 'paper',
                        note                    => 'A3',
                        page_size_code          => 27,
                        physical_page_width     => 297 / MM_PER_IN,
                        physical_page_length    => 420 / MM_PER_IN,
                        logical_page_width      =>
                        {
                            portrait  => 3365 / DPI_LP_CALC,,
                            landscape => 4842 / DPI_LP_CALC,,
                        },
        },
        monarch =>
        {
                        type                    => 'envelope',
                        note                    => 'Monarch',
                        page_size_code          => 80,
                        physical_page_width     => 3.875,
                        physical_page_length    => 7.5,
                        logical_page_width      =>
                        {
                            portrait  => 1012 / DPI_LP_CALC,
                            landscape => 2130 / DPI_LP_CALC,
                        },
        },
        'com-10' =>
        {
                        type                    => 'envelope',
                        note                    => 'Com-10',
                        page_size_code          => 81,
                        physical_page_width     => 4.125,
                        physical_page_length    => 9.5,
                        logical_page_width      =>
                        {
                            portrait  => 1087 / DPI_LP_CALC,
                            landscape => 2730 / DPI_LP_CALC,
                        },
        },
        dl =>
        {
                        type                    => 'envelope',
                        note                    => 'International DL',
                        page_size_code          => 90,
                        physical_page_width     => 110 / MM_PER_IN,
                        physical_page_length    => 220 / MM_PER_IN,
                        logical_page_width      =>
                        {
                            portrait  => 1157 / DPI_LP_CALC,
                            landscape => 2480 / DPI_LP_CALC,
                        },
        },
        c5 =>
        {
                        type                    => 'envelope',
                        note                    => 'International C5',
                        page_size_code          => 91,
                        physical_page_width     => 162 / MM_PER_IN,
                        physical_page_length    => 229 / MM_PER_IN,
                        logical_page_width      =>
                        {
                            portrait  => 1771 / DPI_LP_CALC,
                            landscape => 2586 / DPI_LP_CALC,
                        },
        },
        b5 =>
        {
                        type                    => 'envelope',
                        note                    => 'International B5',
                        page_size_code          => 100,
                        physical_page_width     => 176 / MM_PER_IN,
                        physical_page_length    => 250 / MM_PER_IN,
                        logical_page_width      =>
                        {
                            portrait  => 1936 / DPI_LP_CALC,
                            landscape => 2834 / DPI_LP_CALC,
                        },
        },
    );

    my $orientation_code;
    if ($args->{-o} eq 'landscape') {
        $orientation_code = 1;
    } elsif ($args->{-o} eq 'portrait') {
        $orientation_code = 0;
    } else {
        die;
    }

    (defined $page{$args->{-ms}}{page_size_code})
        ? my $page_size_code = $page{$args->{-ms}}{page_size_code}
        : die;

    my $num_left_margin_chars = ($orientation_code == 0)
                                       # My trial and error constant...
                              ? ( int(.51 * $args->{-w} / $page{$args->{-ms}}{logical_page_width}{portrait})  + 1 )
                              : ( int(.25 * $args->{-w} / $page{$args->{-ms}}{logical_page_width}{landscape}) + 1 );

    my $pitch = sprintf(
                            "%3.2f",
                            (
                                ($args->{-w} + ($num_left_margin_chars * 2))
                                /
                                $page{$args->{-ms}}{logical_page_width}{$args->{-o}}
                            )
                       );

    my $num_right_margin_position = ($orientation_code == 0)
                                  ? (($num_left_margin_chars - 1) + $args->{-w})
                                  : ( $num_left_margin_chars      + $args->{-w});

    # Assume .5 inch default top and bottom margins
    my $l = ($orientation_code == 0)
          ? $page{$args->{-ms}}{physical_page_length}
          : $page{$args->{-ms}}{physical_page_width};

    my $num_top_margin_lines = ($orientation_code == 1)
                             ? ( int(.7 * $args->{-lpp} / $l) + 1)
                             : 0;

    my $vmi = sprintf(
                        "%2.4f",
                        ( ($l - 1)/($args->{-lpp} + int($num_top_margin_lines / 2)) * 48 )
                     );

    my $num_bottom_margin_position = ($orientation_code == 1)
                                   ? $args->{-lpp}
                                   : 0;

    return
            # Universal Exit Language Command
              "\e%-12345X" .

            # Printer Reset Command
              "\eE" .

            # Number of Copies Command
              "\e&l" . $args->{-c} . "X" .

            # Simplex/Duplex Print Command
              "\e&l" . $args->{-s} . "S" .

            # Page Size Command
              "\e&l" . $page_size_code . "A" .

            # Page Source Command
              (
                  (defined $args->{-msrc})
                    ? "\e&l" . $args->{-msrc} . "H"
                    : ''
              ) .

            # Logical Page Orientation Command
              "\e&l" . $orientation_code . "O" .

            # Roman-8 symbol set
              "\e(8U" .

            # Fixed Spacing for primary font
              "\e(s0P" .

            # Pitch (horizontal spacing) for primary font
              "\e(s" . $pitch . "H" .

            # Vertical Motion Index (VMI) Command
              "\e&l" . $vmi . "C" .

            # Stroke Weight
              "\e(s3B" .

            # Left Margin Command
              (
                  ($num_left_margin_chars)
                    ? "\e&a" . $num_left_margin_chars . "L"
                    : ''
              ) .

            # Right Margin Command
              (
                  ($num_right_margin_position)
                    ? "\e&a" . $num_right_margin_position . "M"
                    : ''
              ) .

            # Top Margin Command
              (
                  ($num_top_margin_lines)
                    ? "\e&l" . $num_top_margin_lines . "E"
                    : ''
              ) .

            # Text Length Command (bottom margin)
              (
                  ($num_bottom_margin_position)
                    ? "\e&l" . $num_bottom_margin_position . "F"
                    : ''
              );
}

sub PCL_post {
    return
            # Printer Reset Command
              "\eE" .

            # Universal Exit Language Command
              "\e%-12345X";
}

1;

=head1 AUTHOR

PCL::Simple by Phil R Lawrence.

=head1 COPYRIGHT

The PCL::Simple module is Copyright (c) 2002 Phil R Lawrence.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 NOTE

This module was developed while I was in the employ of Lehigh University.  They kindly allowed me to have ownership of the work with the understanding that I would release it to open source.  :-)

=cut
