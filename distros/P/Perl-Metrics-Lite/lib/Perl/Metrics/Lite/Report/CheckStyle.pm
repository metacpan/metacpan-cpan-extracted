package Perl::Metrics::Lite::Report::CheckStyle;
use strict;
use warnings;

my $DEFAULT_MAX_SUB_LINES         = 60;
my $DEFAULT_MAX_MCCABE_COMPLEXITY = 10;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless( {}, $class );

    my $max_sub_lines
        = exists $args{max_sub_lines}
        ? $args{max_sub_lines}
        : $DEFAULT_MAX_SUB_LINES;
    my $max_sub_mccabe_complexity = $args{max_sub_mccabe_complexity}
        = exists $args{max_sub_mccabe_complexity}
        ? $args{max_sub_mccabe_complexity}
        : $DEFAULT_MAX_MCCABE_COMPLEXITY;
    $self->{max_sub_lines}             = $max_sub_lines;
    $self->{max_sub_mccabe_complexity} = $max_sub_mccabe_complexity;
    return $self;
}

sub report {
    my ( $self, $analysis ) = @_;

    my $sub_stats      = $analysis->sub_stats;
    my $checkstyle_xml = $self->create_checkstyle_xml($sub_stats);

    print $checkstyle_xml;
}

sub create_checkstyle_xml {
    my ( $self, $sub_stats ) = @_;

    my $xml = "";
    $xml .= "<checkstyle version=\"5.1\">\n";
    foreach my $file_path ( keys %{$sub_stats} ) {
        my $sub_metrics = $sub_stats->{$file_path};
        $xml .= $self->file_xml_fragment( $file_path, $sub_metrics );
    }
    $xml .= "</checkstyle>";
    return $xml;
}

sub file_xml_fragment {
    my ( $self, $file_path, $sub_metrics ) = @_;

    my $xml = "";
    $xml .= "  <file name=\"${file_path}\"\>\n";
    foreach my $sub_metric ( @{$sub_metrics} ) {

        if ( $sub_metric->{lines} >= $self->{max_sub_lines} ) {
            $xml .= $self->sub_lines_xml_fragment($sub_metric);
        }

        if ( $sub_metric->{mccabe_complexity}
            >= $self->{max_sub_mccabe_complexity} )
        {
            $xml .= $self->sub_mccabe_complexity_xml_fragment($sub_metric);
        }
    }

    $xml .= "  </file>";
    $xml .= "\n";
    return $xml;
}

sub sub_lines_xml_fragment {
    my ( $self, $sub_metric ) = @_;
    my $xml = "";
    $xml .= '    <error line="';
    $xml .= $sub_metric->{line_number};
    $xml .= '"';
    $xml .= ' column="1"';
    $xml .= ' severity="error"';
    $xml .= ' message="\'';
    $xml .= $sub_metric->{name};
    $xml .= '\' method length is ';
    $xml .= $sub_metric->{lines};
    $xml .= ' lines."';
    $xml
        .= ' source="com.puppycrawl.tools.checkstyle.checks.sizes.MethodLengthCheck"/>';
    $xml .= "\n";
    return $xml;
}

sub sub_mccabe_complexity_xml_fragment {
    my ( $self, $sub_metric ) = @_;

    my $xml = "";
    $xml .= '    <error line="';
    $xml .= $sub_metric->{line_number};
    $xml .= '"';
    $xml .= ' column="1"';
    $xml .= ' severity="error"';
    $xml .= ' message="\'';
    $xml .= $sub_metric->{name};
    $xml .= '\' method cyclomatic complexity is ';
    $xml .= $sub_metric->{mccabe_complexity};
    $xml .= '"';
    $xml
        .= ' source="com.puppycrawl.tools.checkstyle.checks.metrics.CyclomaticComplexityCheck"/>';
    $xml .= "\n";
    return $xml;
}

1;

__END__
