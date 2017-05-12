#ABSTRACT: make simple html, without install Template
package Simple::Html;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  make_html_table
  make_html
);
our $VERSION = '0.01';
our @TR_COLORS    = ( '#d2eaf1', '#ffffff', );
our $TR_COLOR_NUM = scalar(@TR_COLORS);
our $BORDER_COLOR = '#4bacc6';

sub make_html_table {


    my ( $head, $data ) = @_;

    my $th = make_th($head);

    my $tbody;
    my $tr_color_sub = get_tr_color_sub();
    my $max_colnum   = $#$head;
    for my $tr_data (@$data) {
        my $color = $tr_color_sub->();
        my $tr    = make_tr(
            $tr_data,
            color      => $color,
            max_colnum => $max_colnum,
        );
        $tbody .= $tr . "\n";
    }

    return <<__TABLE__;
<table class='tbmain'>
$th
$tbody
</table>
__TABLE__

}

sub make_th {
    my ($head) = @_;

    my @temp = map { "<td>$_</td>" } @$head;
    my $th = join( "\n", @temp );
    return "<tr class='tbhead'> $th </tr>";
}

sub get_tr_color_sub {
    my $i            = 0;
    my $tr_color_sub = sub {
        my $c = $TR_COLORS[ $i % $TR_COLOR_NUM ];
        $i++;
        return $c;
    };
    return $tr_color_sub;
}

sub make_tr {
    my ( $d, %opt ) = @_;
    $opt{max_colnum} ||= $#$d;

    my $tr = '';
    for ( @{$d}[ 0 .. $opt{max_colnum} ] ) {
        $_ = '' unless ( defined $_ );

        ( my $trim = $_ ) =~ s/<[^>]+>//gs;
        my $td_h =
          $trim !~ /^(\d+|N\/A)$/
          ? "<td>"
          : "<td style='text-align:center'>";

        $tr .= "$td_h $_ </td>\n";
    }

    return "<tr style='background-color:$opt{color}'>$tr</tr>\n";
}

sub make_html {
    my ( $html, %opt ) = @_;

    my $h = ref($html) ? $html : \$html;
    my $css = $opt{css} || default_css();

    return <<__HTML__;
<html>
<head>
<style type='text/css'>
$css
</style>
</head>
<body>
$$h
</body>
</html>
__HTML__
}

sub default_css {
    my $css = <<__REPORT_CSS__;
    body {
        font-family: Calibri,Arial, sans-serif;
        font-size: 90%;
        line-height: 110%;
    }
    p {
        text-indent:2em;
        margin:6px;
    }
    .tbmain {
        margin-left:36.0pt;
        border-color:$BORDER_COLOR;
        border-style:solid;
        border-width:1px;
        text-align:left;
        border-collapse:collapse;
		word-break:break-all;
    }

    .tbhead {
        font-weight:bold;
    }
    td {
        padding:0.15cm;
        border-width:1px;
        border-color:$BORDER_COLOR;
        border-style:solid;
    }
    .alarm {
        font-size : 110%;
        font-weight:bold;
		color : red;
	}
    .strike {
        font-size : 110%;
        font-weight:bold;
		color : #0070c0;
	}
    .section {
        font-size : 110%;
        font-weight:bold;
		line-height:150%;
	}	
__REPORT_CSS__
    return $css;
}

1;
