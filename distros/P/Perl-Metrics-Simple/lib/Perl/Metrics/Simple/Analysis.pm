package Perl::Metrics::Simple::Analysis;
use strict;
use warnings;

use Carp qw(confess);
use English qw(-no_match_vars);
use Readonly 1.03;
use Statistics::Basic::StdDev;
use Statistics::Basic::Mean;
use Statistics::Basic::Median;

our $VERSION = 'v1.0.3';

my %_ANALYSIS_DATA = ();
my %_FILES         = ();
my %_FILE_STATS    = ();
my %_LINES         = ();
my %_MAIN          = ();
my %_PACKAGES      = ();
my %_SUBS          = ();
my %_SUMMARY_STATS = ();

sub new {
    my ( $class, $analysis_data ) = @_;
    if ( !is_ref( $analysis_data, 'ARRAY' ) ) {
        confess 'Did not supply an arryref of analysis data.';
    }
    my $self = {};
    bless $self, $class;
    $self->_init($analysis_data);    # Load object properties
    return $self;
}

sub files {
    my ($self) = @_;
    return $_FILES{$self};
}

sub data {
    my $self = shift;
    return $_ANALYSIS_DATA{$self};
}

sub file_count {
    my $self = shift;
    return scalar @{ $self->files };
}

sub lines {
    my $self = shift;
    return $_LINES{$self};
}

sub packages {
    my ($self) = @_;
    return $_PACKAGES{$self};
}

sub package_count {
    my $self = shift;
    return scalar @{ $self->packages };
}

sub file_stats {
    my $self = shift;
    return $_FILE_STATS{$self};
}

sub main_stats {
    my $self = shift;
    return $_MAIN{$self};
}

sub summary_stats {
    my $self = shift;
    return $_SUMMARY_STATS{$self};
}

sub subs {
    my ($self) = @_;
    return $_SUBS{$self};
}

sub sub_count {
    my $self = shift;
    return scalar @{ $self->subs };
}

sub _get_min_max_values {
    my $nodes    = shift;
    my $hash_key = shift;
    if ( !is_ref( $nodes, 'ARRAY' ) ) {
        confess("Didn't get an ARRAY ref, got '$nodes' instead");
    }
    my @sorted_values = sort _numerically map { $_->{$hash_key} } @{$nodes};
    my $min           = $sorted_values[0];
    my $max           = $sorted_values[-1];
    return ( $min, $max, \@sorted_values );
}

sub _numerically {
    return $a <=> $b;
}

sub _init {
    my ( $self, $file_objects ) = @_;
    $_ANALYSIS_DATA{$self} = $file_objects;

    my @all_files  = ();
    my @packages   = ();
    my $lines      = 0;
    my @subs       = ();
    my @file_stats = ();
    my %main_stats = ( lines => 0, mccabe_complexity => 0 );

    foreach my $file ( @{ $self->data() } ) {
        $lines                         += $file->lines();
        $main_stats{lines}             += $file->main_stats()->{lines};
        $main_stats{mccabe_complexity} +=
          $file->main_stats()->{mccabe_complexity};
        push @all_files, $file->path();
        push @file_stats,
          { path => $file->path, main_stats => $file->main_stats };
        push @packages, @{ $file->packages };
        push @subs,     @{ $file->subs };
    }

    $_FILE_STATS{$self}    = \@file_stats;
    $_FILES{$self}        = \@all_files;
    $_MAIN{$self}         = \%main_stats;
    $_PACKAGES{$self}     = \@packages;
    $_LINES{$self}        = $lines;
    $_SUBS{$self}         = \@subs;
    $_SUMMARY_STATS{$self} = $self->_make_summary_stats();
    return 1;
}

sub _make_summary_stats {
    my $self          = shift;
    my $summary_stats = {
        sub_length      => $self->_summary_stats_sub_length,
        sub_complexity  => $self->_summary_stats_sub_complexity,
        main_complexity => $self->_summary_stats_main_complexity,
    };
    return $summary_stats;
}

sub _summary_stats_sub_length {
    my $self = shift;

    my %sub_length = ();

    @sub_length{ 'min', 'max', 'sorted_values' } =
      _get_min_max_values( $self->subs, 'lines' );

    @sub_length{ 'mean', 'median', 'standard_deviation' } =
      _get_mean_median_std_dev( $sub_length{sorted_values} );

    return \%sub_length;
}

sub _summary_stats_sub_complexity {
    my $self = shift;

    my %sub_complexity = ();

    @sub_complexity{ 'min', 'max', 'sorted_values' } =
      _get_min_max_values( $self->subs, 'mccabe_complexity' );

    @sub_complexity{ 'mean', 'median', 'standard_deviation' } =
      _get_mean_median_std_dev( $sub_complexity{sorted_values} );

    return \%sub_complexity;
}

sub _summary_stats_main_complexity {
    my $self = shift;

    my %main_complexity = ();

    my @main_stats = map { $_->{main_stats} } @{ $self->file_stats };
    @main_complexity{ 'min', 'max', 'sorted_values' } =
      _get_min_max_values( \@main_stats, 'mccabe_complexity' );

    @main_complexity{ 'mean', 'median', 'standard_deviation' } =
      _get_mean_median_std_dev( $main_complexity{sorted_values} );

    return \%main_complexity;
}

sub is_ref {
    my $thing = shift;
    my $type  = shift;
    my $ref   = ref $thing;
    return if !$ref;
    return if ( $ref ne $type );
    return $ref;
}

sub _get_mean_median_std_dev {
    my $values = shift;
    my $count  = scalar @{$values};
    if ( $count < 1 ) {
        return;
    }
    my $mean = sprintf '%.2f', Statistics::Basic::Mean->new($values)->query;

    my $median = sprintf '%.2f', Statistics::Basic::Median->new($values)->query;

    my $standard_deviation = sprintf '%.2f',
      Statistics::Basic::StdDev->new( $values, $count )->query;

    return ( $mean, $median, $standard_deviation );
}

1;
__END__

#################### main pod documentation begin ###################

=head1 NAME

Perl::Metrics::Simple::Analysis - Contains anaylsis results.

=head1 SYNOPSIS

This is the class of objects returned by the I<analyze_files>
method of the B<Perl::Metrics::Simple> class.

Normally you would not create objects of this class directly, instead you
get them by calling the I<analyze_files> method on a B<Perl::Metrics::Simple>
object.

=head1 VERSION

This is VERSION 0.1

=head1 DESCRIPTION


=head1 USAGE

=head2 new

  $analysis = Perl::Metrics::Simple::Analsys->new( \@file_objects )

Takes an arrayref of B<Perl::Metrics::Simple::Analysis::File> objects
and returns a new Perl::Metrics::Simple::Analysis object.

=head2 data

The raw data for the analysis. This is the arrayref you passed
as the argument to new();

=head2 files

Arrayref of file paths, in the order they were encountered.

=head2 file_count

How many Perl files were found.

=head2 lines

Total lines in all files, excluding comments and pod.

=head2 main_stats

Returns a hashref of data based the I<main> code in all files, that is,
on the code minus all named subroutines.

  {
    lines             => 723,
    mccabe_complexity => 45
  }

=head2 file_stats

Returns an arrayref of hashrefs, each entry is for one analyzed file,
in the order they were encountered. The I<main_stats> slot in the hashref
is for all the code in the file B<outside of> any named subroutines.

   [
      {
        path => '/path/to/file',
        main_stats => {
                        lines             => 23,
                        mccabe_complexity => 3,
                        path              => '/path/to/file',
                        name              => '{code not in named subroutines}',
                       },
        },
        ...
   ]

=head2 packages

Arrayref of unique packages found in code.

=head2 package_count

How many unique packages found.

=head2 subs

Array ref containing hashrefs of all named subroutines,
in the order encounted.

Each hashref has the structure:

    {
         'lines' => 19,
         'mccabe_complexity' => 6,
         'name' => 'databaseRecords',
         'path' => '../path/to/File.pm',
    }

=head2 sub_count

How many subroutines found.

=head2 summary_stats

Returns a data structure of the summary counts for all the files examined:

    {
        sub_length      => {
            min           => $min_sub_length,
            max           => $max_sub_length,
            sorted_values => \@lengths_of_all_subs,
            mean          => $average_sub_length,
            median        => $median_sub_length,
            standard_deviation => $std_dev_for_sub_lengths,
         },
        sub_complexity  => {
            min           => $min_sub_complexity,
            max           => $max_sub_complexity,
            sorted_values => \@complexities_of_all_subs,
            mean          => $average_sub_complexity,
            median        => $median_sub_complexity,
            standard_deviation => $std_dev_for_sub_complexity,
        },
        main_complexity => {
            min           => $min_main_complexity,
            max           => $max_main_complexity,
            sorted_values => \@complexities_of_all_subs,
            mean          => $average_main_complexity,
            median        => $median_main_complexity,
            standard_deviation => $std_dev_for_main_complexity,
        },
    }


=head1 STATIC PACKAGE SUBROUTINES

Utility subs used internally, but no harm in exposing them for now.
Call these with a fully-qualified package name, e.g.

  Perl::Metrics::Simple::Analysis::is_ref($thing,'ARRAY')

=head2 is_ref

Takes a I<thing> and a I<type>. Returns true is I<thing> is a reference
of type I<type>, otherwise returns false.

=head1 BUGS AND LIMITATIONS

None reported yet ;-)

=head1 DEPENDENCIES

=over 4

=item L<Readonly|Readonly>

=item L<Statistics::Basic|Statistics::Basic>

=back

=head1 SUPPORT

Via CPAN:

=head2 Disussion Forum

http://www.cpanforum.com/dist/Perl-Metrics-Simple

=head2 Bug Reports

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Metrics-Simple

=head1 AUTHOR

    Matisse Enzer
    CPAN ID: MATISSE
    Eigenstate Consulting, LLC
    matisse@eigenstate.net
    http://www.eigenstate.net/

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2021 by Eigenstate Consulting, LLC.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


