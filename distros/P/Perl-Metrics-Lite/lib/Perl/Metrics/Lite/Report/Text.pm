package Perl::Metrics::Lite::Report::Text;
use strict;
use warnings;
use Text::ASCIITable;

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
    my $show_only_error = $args{show_only_error}
        = exists $args{show_only_error}
        ? $args{show_only_error}
        : 0;

    $self->{max_sub_lines}             = $max_sub_lines;
    $self->{max_sub_mccabe_complexity} = $max_sub_mccabe_complexity;
    $self->{show_only_error}           = $show_only_error;

    return $self;
}

sub report {
    my ( $self, $analysis ) = @_;

    my $file_stats = $analysis->file_stats;
    $self->report_file_stats($file_stats);

    my $sub_stats = $analysis->sub_stats;
    $self->report_sub_stats($sub_stats);
}

sub report_file_stats {
    my ( $self, $file_stats ) = @_;
    _print_file_stats_report_header();

    my @rows = ();
    foreach my $file_stat ( @{$file_stats} ) {
        push @rows,
            {
            path     => $file_stat->{path},
            packages => $file_stat->{main_stats}->{packages},
            loc      => $file_stat->{main_stats}->{lines},
            subs     => $file_stat->{main_stats}->{number_of_methods}
            };
    }
    if (@rows) {
        my $keys = [ "path", "loc", "subs", "packages" ];
        my $table = $self->_create_table( $keys, \@rows );
        print $table;
    }
}

sub _print_file_stats_report_header {
    print "#======================================#\n";
    print "#           File Metrics               #\n";
    print "#======================================#\n";
}

sub report_sub_stats {
    my ( $self, $sub_stats ) = @_;
    $self->_print_sub_stats_report_header;
    foreach my $file_path ( keys %{$sub_stats} ) {
        my $sub_metrics = $sub_stats->{$file_path};
        $self->_report_sub_metrics( $file_path, $sub_metrics );
    }
}

sub _print_sub_stats_report_header {
    print "#======================================#\n";
    print "#         Subroutine Metrics           #\n";
    print "#======================================#\n";
}

sub _report_sub_metrics {
    my ( $self, $path, $sub_metrics ) = @_;
    my $table = $self->_create_ascii_table_for_submetrics($sub_metrics);
    if ($table) {
        $self->_print_table( $path, $table );
    }
}

sub _print_table {
    my ( $self, $path, $table ) = @_;

    print "\nPath: ${path}\n";
    print $table;
}

sub _create_ascii_table_for_submetrics {
    my ( $self, $sub_metrics ) = @_;
    my @rows = ();
    foreach my $sub_metric ( @{$sub_metrics} ) {
        next
            if $self->{show_only_error}
                && $self->is_sub_metric_ok($sub_metric);
        push @rows, $self->_create_row($sub_metric);
    }

    my $table;
    if (@rows) {
        my $keys = [ "method", "loc", "mccabe_complexity" ];
        $table = $self->_create_table( $keys, \@rows );
    }
    return $table;
}

sub is_sub_metric_ok {
    my ( $self, $sub_metric ) = @_;
    return 1 if $sub_metric->{lines} < $self->{max_sub_lines};
    return 1
        if $sub_metric->{mccabe_complexity}
            < $self->{max_sub_mccabe_complexity};
    return 0;
}

sub _create_row {
    my ( $self, $sub_metric ) = @_;
    return {
        method            => $sub_metric->{name},
        loc               => $sub_metric->{lines},
        mccabe_complexity => $sub_metric->{mccabe_complexity}
    };
}

sub _create_table {
    my ( $self, $keys, $rows ) = @_;
    my $t = Text::ASCIITable->new();
    $t->setCols(@$keys);
    $t->addRow( @$_{@$keys} ) for @$rows;
    $t;
}

1;

__END__
