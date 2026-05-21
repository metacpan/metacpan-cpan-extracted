package Pheno::Ranker::CLI;

use strict;
use warnings;
use autodie;
use feature qw(say);

use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;
use POSIX           qw(strftime);
use Sys::Hostname   qw(hostname);
use Term::ANSIColor qw(:constants);

use Pheno::Ranker qw($VERSION write_json);
use Pheno::Ranker::Options;

Getopt::Long::Configure('no_ignore_case');

sub run {
    my ( $class, @argv ) = @_;
    my $self = ref $class ? $class : $class->new( pod_file => $0 );

    my $data = $self->parse_args(@argv);

    say BOLD CYAN program_header($VERSION), RESET if $data->{verbose};

    my $ranker = Pheno::Ranker->new($data);
    $ranker->run;

    write_log( $data->{log} ? $data->{log} : 'pheno-ranker-log.json', $data, $VERSION )
      if defined $data->{log};

    return 0;
}

sub new {
    my ( $class, %arg ) = @_;
    return bless { pod_file => $arg{pod_file} || $0 }, $class;
}

sub parse_args {
    my ( $self, @argv ) = @_;
    $self = __PACKAGE__->new unless ref $self;

    my $out_file_cohort      = 'matrix.txt';
    my $out_file_patient     = 'rank.txt';
    my $out_file_graph       = 'graph.json';
    my $out_file_graph_stats = 'graph_stats.txt';
    my $export_basename      = 'export';
    my $align_basename       = 'alignment';
    my $color                = 1;
    my $age                  = 0;
    my $cli                  = 1;

    GetOptionsFromArray(
        \@argv,
        'reference|r=s{1,}'                  => \my @reference_files,
        'target|t=s'                         => \my $target_file,
        'weights|w=s'                        => \my $weights_file,
        'append-prefixes=s{1,}'              => \my @append_prefixes,
        'out-file|o=s'                       => \my $out_file_arg,
        'max-out:i'                          => \my $max_out,
        'max-number-vars:i'                  => \my $max_number_vars,
        'include-hpo-ascendants'             => \my $include_hpo_ascendants,
        'export|e:s'                         => \my $export,
        'align|a:s'                          => \my $align,
        'cytoscape-json:s'                   => \my $cytoscape_json,
        'graph-stats:s'                      => \my $graph_stats,
        'graph-min-weight=f'                 => \my $graph_min_weight,
        'graph-max-weight=f'                 => \my $graph_max_weight,
        'sort-by=s'                          => \my $sort_by,
        'similarity-metric-cohort=s'         => \my $similarity_metric_cohort,
        'matrix-format=s'                    => \my $matrix_format,
        'patients-of-interest|poi=s{1,}'     => \my @patients_of_interest,
        'poi-out-dir=s'                      => \my $poi_out_dir,
        'include-terms=s{1,11}'              => \my @include_terms,
        'exclude-terms=s{1,11}'              => \my @exclude_terms,
        'retain-excluded-phenotypicFeatures' => \my $retain_excluded_phenotypicFeatures,
        'prp|precomputed-ref-prefix=s'       => \my $precomputed_ref_prefix,
        'max-matrix-records-in-ram=i'        => \my $max_matrix_records_in_ram,
        'config=s'                           => \my $config_file,
        'age!'                               => \$age,
        'help|?'                             => \my $help,
        'log:s'                              => \my $log,
        'man'                                => \my $man,
        'debug=i'                            => \my $debug,
        'verbose|v'                          => \my $verbose,
        'color!'                             => \$color,
        'version|V' => sub { say "$0 Version $VERSION"; exit; }
    ) or $self->_pod2usage(2);

    $self->_pod2usage(1) if $help;
    if ($man) {
        say "--man is deprecated. Please use --help or see the full documentation:";
        say "https://cnag-biomedical-informatics.github.io/pheno-ranker/usage/";
        exit 0;
    }

    $self->_pod2usage(
        -message => "Please specify a reference-cohort(s) with <--r>\n",
        -exitval => 1
    ) unless ( @reference_files || $precomputed_ref_prefix );

    $self->_pod2usage(
        -message => "<--graph-stats> only works in conjunction with <--cytoscape-json>\n",
        -exitval => 1
    ) if ( defined $graph_stats && !defined $cytoscape_json );

    $self->_pod2usage(
        -message => "Weights file <$weights_file> does not exist\n",
        -exitval => 1
    ) if ( defined $weights_file && !-f $weights_file );

    my $out_file = $out_file_arg
      // (
        $target_file ? $out_file_patient
        : ( defined $matrix_format && $matrix_format eq 'mtx' )
        ? 'matrix.mtx'
        : $out_file_cohort
      );

    my (
        $glob_hash_file,       $ref_hash_file,
        $ref_binary_hash_file, $coverage_stats_file
    );
    if ( defined $precomputed_ref_prefix ) {
        my $has_incompatible_options =
             @reference_files
          || @append_prefixes
          || $age
          || defined $include_hpo_ascendants
          || defined $retain_excluded_phenotypicFeatures
          || defined $weights_file;

        my @incompatible_flags = (
            '--reference',      '--age',
            '--hpo-ascendants', '--retain-excluded-phenotypicFeatures',
            '--weights',        '--append-prefixes'
        );

        if ($has_incompatible_options) {
            my $flags_str = join( "\n", @incompatible_flags );
            $self->_pod2usage(
                -message =>
"Sorry, but the options\n$flags_str\nare incompatible with --prp <$precomputed_ref_prefix>\n",
                -exitval => 1,
            );
        }

        $glob_hash_file       = resolve_file( $precomputed_ref_prefix . '.glob_hash.json' );
        $ref_hash_file        = resolve_file( $precomputed_ref_prefix . '.ref_hash.json' );
        $ref_binary_hash_file = resolve_file( $precomputed_ref_prefix . '.ref_binary_hash.json' );
        $coverage_stats_file  = resolve_file( $precomputed_ref_prefix . '.coverage_stats.json' );
    }

    handle_option(
        \$cytoscape_json,
        "<--cytoscape-json> only works in cohort-mode",
        $target_file, $out_file_graph, $self->{pod_file}
    );
    handle_option(
        \$graph_stats,
        "<--graph-stats> only works in cohort-mode",
        $target_file, $out_file_graph_stats, $self->{pod_file}
    );

    $ENV{'ANSI_COLORS_DISABLED'} = 1 unless $color;

    my $data = {
        reference_files                    => \@reference_files,
        target_file                        => $target_file,
        weights_file                       => $weights_file,
        include_hpo_ascendants             => $include_hpo_ascendants,
        align                              => $align,
        align_basename                     => $align_basename,
        export                             => $export,
        export_basename                    => $export_basename,
        out_file                           => $out_file,
        cytoscape_json                     => $cytoscape_json,
        graph_stats                        => $graph_stats,
        graph_min_weight                   => $graph_min_weight,
        graph_max_weight                   => $graph_max_weight,
        max_out                            => $max_out,
        max_number_vars                    => $max_number_vars,
        sort_by                            => $sort_by,
        similarity_metric_cohort           => $similarity_metric_cohort,
        matrix_format                      => $matrix_format,
        patients_of_interest               => \@patients_of_interest,
        poi_out_dir                        => $poi_out_dir,
        include_terms                      => \@include_terms,
        exclude_terms                      => \@exclude_terms,
        retain_excluded_phenotypicFeatures => $retain_excluded_phenotypicFeatures,
        precomputed_ref_prefix             => $precomputed_ref_prefix,
        max_matrix_records_in_ram          => $max_matrix_records_in_ram,
        glob_hash_file                     => $glob_hash_file,
        ref_hash_file                      => $ref_hash_file,
        ref_binary_hash_file               => $ref_binary_hash_file,
        coverage_stats_file                => $coverage_stats_file,
        config_file                        => $config_file,
        age                                => $age,
        cli                                => $cli,
        append_prefixes                    => \@append_prefixes,
        log                                => $log,
        debug                              => $debug,
        verbose                            => $verbose
    };

    return Pheno::Ranker::Options->defined_constructor_args($data);
}

sub handle_option {
    my ( $option_ref, $message, $target_file, $default, $pod_file ) = @_;
    if ( defined $$option_ref ) {
        pod2usage( -input => $pod_file, -message => $message, -exitval => 1 )
          if $target_file;
        $$option_ref = $$option_ref ? $$option_ref : $default;
    }
    return 1;
}

sub resolve_file {
    my $base = shift;
    return $base if -e $base;

    my $gz = $base . '.gz';
    return $gz if -e $gz;

    return $base;
}

sub logical_cpu_count {
    my $os = $^O;
    my $out;

    if ( lc($os) eq 'darwin' ) {
        $out = qx{sysctl -n hw.logicalcpu 2>/dev/null};
    }
    elsif ( lc($os) eq 'freebsd' ) {
        $out = qx{sysctl -n hw.ncpu 2>/dev/null};
    }
    elsif ( $os eq 'MSWin32' ) {
        $out = $ENV{NUMBER_OF_PROCESSORS};
    }
    else {
        $out = qx{/usr/bin/nproc 2>/dev/null};
    }

    return $1 if defined $out && $out =~ /(\d+)/;
    return 1;
}

sub write_log {
    my ( $log, $data, $VERSION ) = @_;

    my $threadshost = logical_cpu_count();
    $threadshost = 0 + $threadshost;

    my $info = {
        date        => ( strftime "%a %b %e %H:%M:%S %Y", localtime ),
        threadshost => $threadshost,
        hostname    => hostname,
        id          => time . substr( "00000$$", -5 ),
        version     => $VERSION,
             user   => $ENV{'LOGNAME'}
          || $ENV{'USER'}
          || $ENV{'USERNAME'}
          || 'dummy-user'
    };

    say BOLD GREEN "Writing <$log> file\n", RESET if $data->{verbose};
    write_json(
        {
            filepath => $log,
            data     => { info => $info, data => $data }
        }
    );

    return 1;
}

sub program_header {
    my $VERSION = shift;
    my $str     = <<EOF;
****************************************
*   Rank against cohort(s) (BFF/PXF)   *
*          - PHENO-RANKER -            *
*          Version: $VERSION              *
*   (C) 2023-2025 Manuel Rueda, PhD    *
*       The Artistic License 2.0       *
****************************************
EOF
    return $str;
}

sub _pod2usage {
    my ( $self, @arg ) = @_;
    if ( @arg == 1 && !ref $arg[0] ) {
        return pod2usage( -input => $self->{pod_file}, -exitval => $arg[0] );
    }
    return pod2usage( -input => $self->{pod_file}, @arg );
}

1;
