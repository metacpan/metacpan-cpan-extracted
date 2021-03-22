package Perl::Metrics::Simple::Output::PlainText;

our $VERSION = '0.19';

use strict;
use warnings;

use parent qw(Perl::Metrics::Simple::Output);

use Readonly;

Readonly my $MAX_PLAINTEXT_LABEL_LENGTH => 25;
Readonly my $EMPTY_STRING               => q{};
Readonly my $ONE_SPACE                  => q{ };

sub make_report {
    my ($self) = @_;

    my $report = 'Perl files found: ' . $self->analysis()->file_count() . "\n\n";
    $report .= $self->make_counts();
    $report .= $self->make_subroutine_size();
    $report .= $self->make_code_complexity();
    $report .= $self->make_list_of_subs();
    return $report;
}

sub make_counts {
    my ($self) = @_;

    my $counts = _make_headline('Counts');
    $counts .= _make_line( 'total code lines', $self->analysis()->lines() );
    $counts .= _make_line(
        'lines of non-sub code',
        $self->analysis()->main_stats()->{lines}
    );
    $counts .= _make_line( 'packages found', $self->analysis()->package_count() );
    $counts .= _make_line( 'subs/methods',   $self->analysis()->sub_count() );
    $counts .= "\n\n";
    return $counts;
}

sub make_subroutine_size {
    my ($self) = @_;

    my $subroutine_size = _make_headline('Subroutine/Method Size');
    $subroutine_size .= _make_line(
        'min',
        $self->analysis()->summary_stats()->{sub_length}->{min}
    );
    $subroutine_size .= _make_line(
        'max',
        $self->analysis()->summary_stats()->{sub_length}->{max}
    );
    $subroutine_size .= _make_line(
        'mean',
        $self->analysis()->summary_stats()->{sub_length}->{mean}
    );
    $subroutine_size .= _make_line(
        'std. deviation',
        $self->analysis()->summary_stats()->{sub_length}->{standard_deviation}
    );
    $subroutine_size .= _make_line(
        'median',
        $self->analysis()->summary_stats()->{sub_length}->{median}
    );

    $subroutine_size .= "\n\n";
    return $subroutine_size;
}

sub make_code_complexity {
    my ($self) = @_;

    my $code_complexity = _make_headline('McCabe Complexity');

    $code_complexity .= $self->make_complexity_section(
        'Code not in any subroutine',
        'main_complexity'
    );
    $code_complexity .= "\n";
    $code_complexity .= $self->make_complexity_section(
        'Subroutines/Methods',
        'sub_complexity'
    );

    $code_complexity .= "\n\n";
    return $code_complexity;
}

sub make_complexity_section {
    my ( $self, $section, $key ) = @_;

    my $complexity_section = $section . "\n";

    $complexity_section
        .= _make_line( 'min', $self->analysis()->summary_stats()->{$key}->{min} );
    $complexity_section
        .= _make_line( 'max', $self->analysis()->summary_stats()->{$key}->{max} );
    $complexity_section .= _make_line(
        'mean',
        $self->analysis()->summary_stats()->{$key}->{mean}
    );
    $complexity_section .= _make_line(
        'std. deviation',
        $self->analysis()->summary_stats()->{$key}->{standard_deviation}
    );
    $complexity_section .= _make_line(
        'median',
        $self->analysis()->summary_stats()->{$key}->{median}
    );
    return $complexity_section;
}

sub make_list_of_subs {
    my ($self) = @_;

    my ( $main_from_each_file, $sorted_all_subs ) = @{ $self->SUPER::make_list_of_subs() };

    my $column_widths = _get_column_widths($main_from_each_file);

    my $list_of_subs = _make_headline('List of subroutines, with most complex at top');

    $list_of_subs .= _make_column( 'complexity', $column_widths->{mccabe_complexity} );
    $list_of_subs .= _make_column( 'sub',        $column_widths->{name} );
    $list_of_subs .= _make_column( 'path',       $column_widths->{path} );
    $list_of_subs .= _make_column( 'size',       $column_widths->{lines} );
    $list_of_subs .= "\n";

    foreach my $sub (@$sorted_all_subs) {
        $list_of_subs .= _make_list_of_subs_line( $sub, $column_widths );
    }

    $list_of_subs .= "\n\n";
    return $list_of_subs;
}

# MARK: - Private

sub _make_list_of_subs_line {
    my ( $sub, $column_widths ) = @_;

    my $list_of_subs_line;

    foreach my $col ( 'mccabe_complexity', 'name', 'path', 'lines' ) {
        $list_of_subs_line
            .= _make_column( $sub->{$col}, $column_widths->{$col} );
    }

    $list_of_subs_line .= "\n";
    return $list_of_subs_line;
}

sub _get_column_widths {
    my ($main_from_each_file) = @_;

    my $column_widths = {
        mccabe_complexity => 10,
        name              => 3,
        path              => 4,
        lines             => 4,
    };

    foreach my $sub (@$main_from_each_file) {
        foreach my $col ( 'mccabe_complexity', 'name', 'path', 'lines' ) {
            if ( length( $sub->{$col} ) > $column_widths->{$col} ) {
                $column_widths->{$col} = length( $sub->{$col} );
            }
        }
    }

    return $column_widths;
}

sub _make_line {
    my ( $key, $value ) = @_;
    if ( !defined $value ) {
        $value = 'n/a';
    }
    my $line = $key . q{:};
    $line .= $ONE_SPACE x ( $MAX_PLAINTEXT_LABEL_LENGTH - length $key );
    $line .= $value . "\n";
    return $line;
}

sub _make_headline {
    my ($headline) = @_;
    my $formatted_headline = $headline . "\n";
    $formatted_headline .= q{-} x length $headline;
    $formatted_headline .= "\n";
    return $formatted_headline;
}

sub _make_column {
    my ( $value, $width ) = @_;

    my $column = $value;
    $column .= $ONE_SPACE x ( $width - length($value) + 2 );
    return $column;
}

1;    # Keep Perl happy, snuggy, and warm.

__END__

=pod

=head1 NAME

Perl::Metrics::Simple::Output::PlainText - Produce plain text report.

=head1 SYNOPSIS

    $analysis =  Perl::Metrics::Simple->new()->analyze_files(@files);
    $plain    = Perl::Metrics::Simple::Putput::PlainText->new($analysis);
    print $plain->make_report;

=cut
