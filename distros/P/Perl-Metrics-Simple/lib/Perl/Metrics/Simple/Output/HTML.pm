package Perl::Metrics::Simple::Output::HTML;

our $VERSION = 'v1.0.1';

use strict;
use warnings;

use parent qw(Perl::Metrics::Simple::Output);
use Readonly 1.03;

Readonly my $EMPTY_STRING => q{};
Readonly my $ONE_SPACE    => q{ };

Readonly my $COMPLEXITY_LEVEL_THRESHOLD => {
    BTW => 10,
    WTF => 20,
    OMG => 30,
};

Readonly my $THRESHOLD_TO_CSS_CLASS => {
    0                                  => 'fyi',
    $COMPLEXITY_LEVEL_THRESHOLD->{BTW} => 'btw',
    $COMPLEXITY_LEVEL_THRESHOLD->{WTF} => 'wtf',
    $COMPLEXITY_LEVEL_THRESHOLD->{OMG} => 'omg',
};

Readonly my $CSS => {
    body  => ['font-family:sans-serif;'],
    table => [
        'border-collapse:collapse;', 'border-spacing:0px;',
        'margin:10px 0px;'
    ],
    tr       => [ 'text-align:left;',          'vertical-align:top;' ],
    'td, th' => [ 'border:solid 1px #000000;', 'padding:2px;' ],
    th       => ['background-color:#cccccc;'],
    '.fyi'   => ['background-color:#99ff99;'],
    '.btw'   => ['background-color:#ffff99;'],
    '.wtf'   => ['background-color:#ffcc99;'],
    '.omg'   => ['background-color:#ff9999;'],
    '.w300'  => ['width:300px;'],
    '.w200'  => ['width:200px;'],
    '.w100'  => ['width:100px;'],
    '.right' => ['text-align:right;']
};

sub make_report {
    my ($self) = @_;

    my $html = '<!DOCTYPE html><html lang="en">';

    $html .= $self->make_head();

    $html .= $self->make_body();

    $html .= '</html>';
    return $html;
}

sub make_head {
    my ($self) = @_;

    my $head = '<head><title>countperl</title><meta charset="utf-8">';

    $head .= make_css();

    $head .= '</head>';
    return $head;
}

sub make_css {
    my ($self) = @_;

    my $css = '<style type="text/css">';

    foreach my $selector ( keys %{$CSS} ) {
        $css .= $selector . '{';

        foreach ( @{ $CSS->{$selector} } ) {
            $css .= $_;
        }

        $css .= '}';
    }

    $css .= '</style>';

    return $css;
}

sub make_body {
    my ($self) = @_;

    my $body = '<body><h3>';
    $body .= 'Perl files found ' . $self->analysis()->file_count();
    $body .= '</h3>';

    $body .= $self->make_counts();
    $body .= $self->make_subroutine_size();
    $body .= $self->make_code_complexity();
    $body .= $self->make_list_of_subs();
    $body .= $self->make_complexity_levels();

    $body .= '</body>';
    return $body;
}

sub make_counts {
    my ($self) = @_;

    my $analysis = $self->analysis();

    my $counts = '<table><tr><th colspan="2">Counts</th></tr>';

    $counts .= make_tr( 'total code lines', $analysis->lines() );
    $counts
        .= make_tr( 'lines of non-sub code', $analysis->main_stats()->{lines} );
    $counts .= make_tr( 'packages found', $analysis->package_count() );
    $counts .= make_tr( 'subs/methods',   $analysis->sub_count() );

    $counts .= '</table>';
    return $counts;
}

sub make_tr {
    my ( $key, $value, $css ) = @_;
    $css = $css ? $ONE_SPACE . $css : $EMPTY_STRING;

    my $tr = '<tr><td class="w200">';
    $tr .= $key;
    $tr .= '</td><td class="w100 right' . $css . '">';
    $tr .= $value;
    $tr .= '</td></tr>';

    return $tr;
}

sub make_subroutine_size {
    my ($self) = @_;

    my $analysis = $self->analysis();

    my $subroutine_size = '<table><tr><th colspan="2">Subroutine/Method Size</th></tr>';

    my $min                = $analysis->summary_stats()->{sub_length}->{min}                || 0;
    my $max                = $analysis->summary_stats()->{sub_length}->{max}                || 0;
    my $mean               = $analysis->summary_stats()->{sub_length}->{mean}               || '0.00';
    my $standard_deviation = $analysis->summary_stats()->{sub_length}->{standard_deviation} || '0.00';
    my $median             = $analysis->summary_stats()->{sub_length}->{median}             || '0.00';

    $subroutine_size .= make_tr( 'min',            $min );
    $subroutine_size .= make_tr( 'max',            $max );
    $subroutine_size .= make_tr( 'mean',           $mean );
    $subroutine_size .= make_tr( 'std. deviation', $standard_deviation );
    $subroutine_size .= make_tr( 'median',         $median );

    $subroutine_size .= '</table>';

    return $subroutine_size;
}

sub make_code_complexity {
    my ($self) = @_;

    my $code_complexity = '<table><tr><th colspan="3">McCabe Complexity</th></tr>';

    $code_complexity .= $self->make_complexity_section(
        'Code not in any subroutine',
        'main_complexity'
    );
    $code_complexity .= $self->make_complexity_section(
        'Subroutines/Methods',
        'sub_complexity'
    );

    $code_complexity .= '</table>';

    return $code_complexity;
}

sub make_complexity_section {
    my ( $self, $section, $key ) = @_;

    my $analysis = $self->analysis();

    my $complexity_section = '<tr><td rowspan="5" class="w200">' . $section . '</td>';

    my $min                = $analysis->summary_stats()->{$key}->{min}                || 0;
    my $max                = $analysis->summary_stats()->{$key}->{max}                || 0;
    my $mean               = $analysis->summary_stats()->{$key}->{mean}               || '0.00';
    my $standard_deviation = $analysis->summary_stats()->{$key}->{standard_deviation} || '0.00';
    my $median             = $analysis->summary_stats()->{$key}->{median}             || '0.00';

    $complexity_section .= '<td class="w200">min</td><td class="w100 right ' . get_class_by_count($min) . '">';
    $complexity_section .= $min;
    $complexity_section .= '</td></tr>';

    $complexity_section .= make_tr( 'max',            $max,                get_class_by_count($max) );
    $complexity_section .= make_tr( 'mean',           $mean,               get_class_by_count($mean) );
    $complexity_section .= make_tr( 'std. deviation', $standard_deviation, get_class_by_count($standard_deviation) );
    $complexity_section .= make_tr( 'median',         $median,             get_class_by_count($median) );

    return $complexity_section;
}

sub make_list_of_subs_tr {
    my ($sub) = @_;

    my $list_of_subs_tr = '<tr><td class="' . get_class_by_count( $sub->{mccabe_complexity} ) . ' right">' . $sub->{mccabe_complexity} . '</td><td>' . $sub->{name} . '</td><td>' . $sub->{path} . '</td><td class="right">' . $sub->{lines} . '</td></tr>';

    return $list_of_subs_tr;
}

sub make_list_of_subs {
    my ($self) = @_;

    my $sorted_subs = $self->SUPER::make_list_of_subs()->[1];

    my $list_of_subs = '<table><tr><th colspan="4">List of subroutines, with most complex at top</th></tr>' . '<tr><td class="w100">complexity</td><td>sub</td><td>path</td><td class="w100">size</td><tr>';

    foreach my $sub (@$sorted_subs) {
        $list_of_subs .= make_list_of_subs_tr($sub);
    }

    $list_of_subs .= '</table>';

    return $list_of_subs;
}

sub make_complexity_levels {
    my ($self) = @_;

    my $complexity_levels = '<table><tr><th colspan="2">Complexity Levels</th></tr>';

    foreach my $level ( sort keys %{$THRESHOLD_TO_CSS_CLASS} ) {
        $complexity_levels .= '<tr><td class="' . $THRESHOLD_TO_CSS_CLASS->{$level} . '">' . $THRESHOLD_TO_CSS_CLASS->{$level} . '</td><td class="' . $THRESHOLD_TO_CSS_CLASS->{$level} . '">' . '&gt;= ' . $level . '</td></tr>';
    }

    $complexity_levels .= '</table>';

    return $complexity_levels;
}

sub get_class_by_count {
    my ($count) = @_;

    my @level = reverse sort keys %{$THRESHOLD_TO_CSS_CLASS};

    foreach (@level) {
        return $THRESHOLD_TO_CSS_CLASS->{$_} if ( $count >= $_ );
    }
    return;
}

1;    # Keep Perl happy, snuggy, and warm.

__END__

=pod

=head1 NAME

Perl::Metrics::Simple::Output::HTML - Produce HTML report.

=head1 SYNOPSIS

    $analysis =  Perl::Metrics::Simple->new()->analyze_files(@files);
    $html     = Perl::Metrics::Simple::Putput::HTML->new($analysis);
    print $html->make_report;

=cut
