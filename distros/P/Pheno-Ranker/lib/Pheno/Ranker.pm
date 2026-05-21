package Pheno::Ranker;

use strict;
use warnings;
use autodie;
use feature qw(say);
use File::Basename        qw(dirname);
use File::Spec::Functions qw(catfile);
use Term::ANSIColor       qw(:constants);
use Moo;
use Types::Standard qw(Int Enum Bool);
use File::ShareDir::ProjectDistDir qw(dist_dir);
use Pheno::Ranker::IO;
use Pheno::Ranker::Compare;
use Pheno::Ranker::Metrics;
use Pheno::Ranker::Graph;
use Pheno::Ranker::Config;
use Pheno::Ranker::Context;
use Pheno::Ranker::Options;

use Exporter 'import';
our @EXPORT_OK = qw($VERSION write_json);

# Personalize warn and die functions
$SIG{__WARN__} = sub { warn BOLD YELLOW "Warn: ", @_, RESET };
$SIG{__DIE__}  = sub { die BOLD RED "Error: ", @_, RESET };

our $VERSION   = '1.08';
our $share_dir = dist_dir('Pheno-Ranker');

# Set development mode
use constant DEVEL_MODE => 0;

my $default_config_file = catfile( $share_dir, 'conf', 'config.yaml' );

############################################
# Start declaring attributes for the class #
############################################

has 'config_file' => (
    is  => 'ro',
    isa =>
      sub { die "Config file '$_[0]' is not a valid file" unless -e $_[0] },
    default => $default_config_file,
);

has config => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Pheno::Ranker::Config->new( file => shift->config_file ) },
);

has options => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Pheno::Ranker::Options->new(
            config    => $self->config,
            share_dir => $share_dir,
        );
    },
);

has sort_by => (
    is  => 'ro',
    isa => Enum [qw(hamming jaccard)]
);

has similarity_metric_cohort => (
    is  => 'ro',
    isa => Enum [qw(hamming jaccard)]
);

has matrix_format => (
    is  => 'ro',
    isa => Enum [qw(dense mtx)]
);

has max_out => (
    is  => 'ro',
    isa => Int
);

has max_number_vars => (
    is  => 'ro',
    isa => Int
);

has max_matrix_records_in_ram => (
    is  => 'ro',
    isa => Int
);

has graph_min_weight => (
    is => 'ro',
);

has graph_max_weight => (
    is => 'ro',
);

has hpo_file => (
    is      => 'ro',
    isa     => sub { die "Error <$_[0]> is not a valid file" unless -e $_[0] },
);

has poi_out_dir => (
    is      => 'ro',
    isa     => sub { die "<$_[0]> dir does not exist" unless -d $_[0] },
);

has [qw/include_terms exclude_terms/] => (
    is  => 'ro',
    isa => sub {
        die "<--include_terms> and <--exclude_terms> must be an array ref\n"
          unless ref shift eq 'ARRAY';
    },
);

has cli => (
    is      => 'ro',
    isa     => Bool,
);

# Miscellaneous attributes
has [
    qw/target_file weights_file out_file include_hpo_ascendants
      retain_excluded_phenotypicFeatures align align_basename export export_basename
      log verbose age cytoscape_json graph_stats/
] => ( is => 'ro' );

has [qw/append_prefixes reference_files patients_of_interest/] => ( is => 'ro' );

has [qw/glob_hash_file ref_hash_file ref_binary_hash_file coverage_stats_file/]
  => ( is => 'ro' );

##########################################
# End declaring attributes for the class #
##########################################

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    my $args = $class->$orig(@args);
    return Pheno::Ranker::Options->defined_constructor_args($args);
};

sub BUILD {

    # BUILD: is an instance method that is called after the object has been constructed but before it is returned to the caller.
    # BUILDARGS is a class method that is responsible for processing the arguments passed to the constructor (new) and returning a hash reference of attributes that will be used to initialize the object.

    my $self = shift;
    $self->config->apply_to($self) unless exists $self->{primary_key};
    $self->options->apply_to($self);

    # Miscellaneous checks
    if ( @{ $self->{append_prefixes} } ) {
        die "<--append_prefixes> requires at least 2 cohort files!\n"
          unless @{ $self->{reference_files} } > 1;
        die "The number of items in <--r> and <--append-prefixes> must match!\n"
          unless @{ $self->{reference_files} } == @{ $self->{append_prefixes} };
    }
    if ( @{ $self->{patients_of_interest} } ) {
        die "<--patients-of-interest> must be used with <--r>\n"
          unless @{ $self->{reference_files} };
    }
    if ( $self->{matrix_format} eq 'mtx' ) {
        die "<--matrix-format mtx> only works in cohort mode\n"
          if $self->{target_file};
    }
}

# ============================================================
#  run method
# ============================================================
sub run {
    my $self = shift;

    $self->_validate_output_directories;

    my (
        $glob_hash, $ref_hash, $ref_binary_hash, $hash2serialize, $weight
    );

    if ( $self->_has_precomputed_data ) {
        ( $glob_hash, $ref_hash, $ref_binary_hash, $hash2serialize ) =
          $self->_load_precomputed_data;
    }
    else {
        my $ref_data = $self->_load_reference_cohort_data(
            $self->{reference_files},
            $self->{primary_key},
            $self->{append_prefixes}
        );

        return 1 if $self->_maybe_write_poi($ref_data);

        $weight = validate_json( $self->{weights_file} );
        $self->_maybe_load_hpo;

        my ( $coverage_stats, $glob_hash_computed, $ref_hash_computed,
            $ref_binary_hash_computed, $hash2serialize_computed )
          = $self->_compute_cohort_metrics(
            $ref_data,
            $weight,
            $self->{primary_key},
            $self->{target_file}
          );

        $glob_hash       = $glob_hash_computed;
        $ref_hash        = $ref_hash_computed;
        $ref_binary_hash = $ref_binary_hash_computed;
        $hash2serialize  = $hash2serialize_computed;
    }

    $self->_maybe_run_cohort_comparison($ref_binary_hash);
    $self->_maybe_write_graph($ref_binary_hash);
    $self->_maybe_process_patient(
        {
            weight          => $weight,
            glob_hash       => $glob_hash,
            ref_hash        => $ref_hash,
            ref_binary_hash => $ref_binary_hash,
        },
        \$hash2serialize
    );
    $self->_maybe_export_hashes($hash2serialize);

    return 1;
}

sub _validate_output_directories {
    my $self = shift;

    my $align_dir = defined $self->{align} ? dirname( $self->{align} ) : '.';
    die "Directory <$align_dir> does not exist (used with --align)\n"
      unless -d $align_dir;

    my $export_dir = defined $self->{export} ? dirname( $self->{export} ) : '.';
    die "Directory <$export_dir> does not exist (used with --export)\n"
      unless -d $export_dir;

    return 1;
}

sub _has_precomputed_data {
    my $self = shift;
    return defined $self->{glob_hash_file}
      && defined $self->{ref_hash_file}
      && defined $self->{ref_binary_hash_file}
      && defined $self->{coverage_stats_file};
}

sub _load_precomputed_data {
    my $self = shift;

    say "Using precomputed data" if $self->{verbose};

    my $glob_hash       = read_json( $self->{glob_hash_file} );
    my $ref_hash        = read_json( $self->{ref_hash_file} );
    my $ref_binary_hash = read_json( $self->{ref_binary_hash_file} );
    my $coverage_stats  = read_json( $self->{coverage_stats_file} );

    $self->_add_attribute( 'format', $coverage_stats->{format} );

    my $hash2serialize = {
        glob_hash       => $glob_hash,
        ref_hash        => $ref_hash,
        ref_binary_hash => $ref_binary_hash,
    };

    return ( $glob_hash, $ref_hash, $ref_binary_hash, $hash2serialize );
}

sub _maybe_write_poi {
    my ( $self, $ref_data ) = @_;
    return 0 unless @{ $self->{patients_of_interest} };

    write_poi(
        {
            ref_data    => $ref_data,
            poi         => $self->{patients_of_interest},
            poi_out_dir => $self->{poi_out_dir},
            primary_key => $self->{primary_key},
            verbose     => $self->{verbose}
        }
    );

    return 1;
}

sub _maybe_load_hpo {
    my $self = shift;
    return 1 unless $self->{include_hpo_ascendants};

    my ( $nodes, $edges ) = parse_hpo_json( read_json( $self->{hpo_file} ) );
    $self->{nodes} = $nodes;
    $self->{edges} = $edges;

    return 1;
}

sub _maybe_run_cohort_comparison {
    my ( $self, $ref_binary_hash ) = @_;
    return 1 if $self->{target_file};

    cohort_comparison( $ref_binary_hash, $self->_context );
    return 1;
}

sub _maybe_write_graph {
    my ( $self, $ref_binary_hash ) = @_;

    $self->_perform_graph_calculations(
        $ref_binary_hash,
        $self->{cytoscape_json},
        $self->{graph_stats},
        $self->{similarity_metric_cohort},
        $self->{graph_min_weight},
        $self->{graph_max_weight}
    );

    return 1;
}

sub _maybe_process_patient {
    my ( $self, $computed, $hash2serialize_ref ) = @_;
    return 1 unless $self->{target_file};

    $self->_process_patient_data(
        {
            target_file     => $self->{target_file},
            primary_key     => $self->{primary_key},
            weight          => $computed->{weight},
            glob_hash       => $computed->{glob_hash},
            ref_hash        => $computed->{ref_hash},
            ref_binary_hash => $computed->{ref_binary_hash},
            align           => $self->{align},
            align_basename  => $self->{align_basename},
            out_file        => $self->{out_file},
            cli             => $self->{cli},
            verbose         => $self->{verbose},
        },
        $hash2serialize_ref
    );

    return 1;
}

sub _maybe_export_hashes {
    my ( $self, $hash2serialize ) = @_;
    return 1 unless defined $self->{export};

    serialize_hashes(
        {
            data            => $hash2serialize,
            export_basename =>
              $self->{export} ? $self->{export} : $self->{export_basename}
        }
    );

    return 1;
}

# ============================================================
# Private method: _load_reference_cohort_data
# ------------------------------------------------------------
# Loads each reference cohort file, validates the primary_key,
# and then appends prefixes if needed.
# ============================================================
sub _load_reference_cohort_data {
    my ( $self, $reference_files, $primary_key, $append_prefixes ) = @_;

    # *** IMPORTANT ***
    # $ref_data is an array array where each element is the content of the file (e.g, [] or {})

    my $ref_data = [];
    for my $cohort_file ( @{$reference_files} ) {
        die "<$cohort_file> does not exist\n" unless -f $cohort_file;
        my $json_data = io_yaml_or_json(
            {
                filepath => $cohort_file,
                mode     => 'read'
            }
        );

        # Check for existence of primary_key otherwise die
        # Expected cases:
        #  - A) BFF/PXF (default  config) exists primary_key('id')
        #  - B) JSON    (default  config) exists primary_key('id') - i.e., OpenEHR
        #  - C) JSON    (external config) exists primary_key

        my $msg =
"Sorry, <$cohort_file> does not contain primary_key <$primary_key>. Are you using the right configuration file?\n";
        if ( ref $json_data eq ref [] ) {
            die $msg unless exists $json_data->[0]->{$primary_key};
        }
        else {
            die $msg unless exists $json_data->{$primary_key};
        }
        push @$ref_data, $json_data;
    }

    # In <inter-cohort> we join --cohorts into one but we rename the values of primary_key
    # NB: Re-using $ref_data to save memory

    $ref_data = append_and_rename_primary_key(
        {
            ref_data        => $ref_data,
            append_prefixes => $append_prefixes,
            primary_key     => $primary_key
        }
    );
    return $ref_data;
}

# ============================================================
# Private method: _compute_cohort_metrics
# ------------------------------------------------------------
# Computes cohort coverage statistics, restructures the data
# (e.g. PXF interpretations), and then creates the global and
# per-individual hashes along with their one-hot encoded version.
# ============================================================
sub _compute_cohort_metrics {
    my ( $self, $ref_data, $weight, $primary_key, $target_file ) = @_;
    my $export = $self->{export};

    # We have to check if we have BFF|PXF or others (unless defined at config)
    $self->_add_attribute( 'format', check_format($ref_data) )
      unless defined $self->{format};

    my $context        = $self->_context;
    my $coverage_stats = coverage_stats(
        $ref_data,
        $context->{format},
        {
            retain_excluded_phenotypicFeatures =>
              $context->{retain_excluded_phenotypicFeatures}
        }
    );
    die
"--include-terms <@{$self->{include_terms}}> does not exist in the cohort(s)\n"
      unless check_existence_of_include_terms( $coverage_stats,
        $context->{include_terms} );

    # Restructure PXF
    restructure_pxf_interpretations( $ref_data, $context );

    # First we create:
    # - $glob_hash => hash with all the COHORT keys possible
    # - $ref_hash  => BIG hash with all individiduals' keys "flattened"

    my ( $glob_hash, $ref_hash ) =
      create_glob_and_ref_hashes( $ref_data, $weight, $context );

    # Limit the number of variables if > $self-{max_number_vars}
    # *** IMPORTANT ***
    # Change only performed in $glob_hash
    if ( keys %$glob_hash > $context->{max_number_vars} ) {
        $glob_hash = randomize_variables( $glob_hash, $context );
    }

    # Second we peform one-hot encoding for each individual
    my $ref_binary_hash =
      create_binary_digit_string( $export, $weight, $glob_hash, $ref_hash );

    # Hashes to be serialized to JSON if <--export>
    my $hash2serialize = {
        glob_hash       => $glob_hash,
        ref_hash        => $ref_hash,
        ref_binary_hash => $ref_binary_hash,
        coverage_stats  => $coverage_stats
    };
    return (
        $coverage_stats,  $glob_hash, $ref_hash,
        $ref_binary_hash, $hash2serialize
    );
}

# ============================================================
# Private method: _process_patient_data
# ------------------------------------------------------------
# Loads patient data from the target file, validates it,
# restructures interpretations, and then performs the patient
# to cohort comparison and ranking.
# ============================================================
sub _process_patient_data {
    my ( $self, $params, $hash2serialize_ref ) = @_;
    my $target_file     = $params->{target_file};
    my $primary_key     = $params->{primary_key};
    my $weight          = $params->{weight};
    my $glob_hash       = $params->{glob_hash};
    my $ref_hash        = $params->{ref_hash};
    my $ref_binary_hash = $params->{ref_binary_hash};
    my $align           = $params->{align};
    my $align_basename  = $params->{align_basename};
    my $out_file        = $params->{out_file};
    my $cli             = $params->{cli};
    my $verbose         = $params->{verbose};
    my $export          = $self->{export};
    my $context         = $self->_context;

    my $tar_data = array2object(
        io_yaml_or_json( { filepath => $target_file, mode => 'read' } ) );

    # The target file has to have $_->{$primary_key} otherwise die

    die
"Sorry, <$target_file> does not contain primary_key <$primary_key>. Are you using the right config file?\n"
      unless exists $tar_data->{$primary_key};
    restructure_pxf_interpretations( $tar_data, $context );

    # We store {primary_key} as a variable as it might be deleted from $tar_data (--exclude-terms id)

    my $tar_data_id = $tar_data->{$primary_key};
    my $tar_hash    = {
        $tar_data_id => remap_hash(
            {
                hash   => $tar_data,
                weight => $weight,
                self   => $context
            }
        )
    };

    # *** IMPORTANT ***
    # The target binary is created from matches to $glob_hash
    # Thus, it does not include variables ONLY present in TARGET

    my $tar_binary_hash =
      create_binary_digit_string( $export, $weight, $glob_hash, $tar_hash );
    my (
        $results_rank,        $results_align, $alignment_ascii,
        $alignment_dataframe, $alignment_csv
      )
      = compare_and_rank(
        {
            glob_hash       => $glob_hash,
            ref_hash        => $ref_hash,
            tar_hash        => $tar_hash,
            ref_binary_hash => $ref_binary_hash,
            tar_binary_hash => $tar_binary_hash,
            weight          => $weight,
            self            => $context
        }
      );
    say join "\n", @$results_rank if $cli;
    write_array2txt( { filepath => $out_file, data => $results_rank } );

    if ( defined $align ) {
        write_alignment(
            {
                align     => $align ? $align : $align_basename,
                ascii     => $alignment_ascii,
                dataframe => $alignment_dataframe,
                csv       => $alignment_csv
            }
        );
    }
    $$hash2serialize_ref->{tar_hash}        = $tar_hash;
    $$hash2serialize_ref->{tar_binary_hash} = $tar_binary_hash;
    $$hash2serialize_ref->{alignment_hash}  = $results_align if defined $align;
    return 1;
}

sub _perform_graph_calculations {
    my ( $self, $ref_binary_hash, $cytoscape_json, $graph_stats,
        $similarity_metric_cohort, $graph_min_weight, $graph_max_weight )
      = @_;

    my $graph;
    if ($cytoscape_json) {
        $graph = binary_hash2graph(
            {
                ref_binary_hash  => $ref_binary_hash,
                json             => $cytoscape_json,
                metric           => $similarity_metric_cohort,
                graph_stats      => 1,
                graph_min_weight => $graph_min_weight,
                graph_max_weight => $graph_max_weight,
                verbose          => $self->{verbose},
            }
        );
    }

    if ( defined $graph_stats ) {
        cytoscape2graph(
            {
                graph   => $graph,
                output  => $graph_stats,
                metric  => $similarity_metric_cohort,
                verbose => $self->{verbose},
            }
        );
    }

    return $graph;
}

sub _add_attribute {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value;
    return 1;
}

sub _context {
    my $self = shift;
    return Pheno::Ranker::Context->from_ranker($self);
}

1;

=pod

=head1 NAME

Pheno::Ranker - A module that performs semantic similarity in PXF/BFF data structures and beyond (JSON|YAML)
  
=head1 SYNOPSIS

 use Pheno::Ranker;

 # Create object
 my $ranker = Pheno::Ranker->new(
     {
         reference_files  => ['individuals.json'],
         out_file => 'matrix.txt'
     }
 );

 # Run it (output are text files)
 $ranker->run;

=head1 DESCRIPTION

We recommend using the included L<command-line interface|https://metacpan.org/dist/Pheno-Ranker/view/bin/pheno-ranker>.

For a better description, please read the following documentation:

=over

=item General:

L<https://cnag-biomedical-informatics.github.io/pheno-ranker>

=item Command-Line Interface:

L<https://github.com/CNAG-Biomedical-Informatics/pheno-ranker#readme>

=back

=head1 CITATION

The author requests that any published work that utilizes `Pheno-Ranker` includes a cite to the following reference:

Leist, I.C. et al., (2024). Pheno-Ranker: a toolkit for comparison of phenotypic data stored in GA4GH standards and beyond. _BMC Bioinformatics_. DOI: 10.1186/s12859-024-05993-2

=head1 AUTHOR

Written by Manuel Rueda, PhD. Info about CNAG can be found at L<https://www.cnag.eu>.

=head1 METHODS

There is only method named C<run>. See above the syntax.

For more information check the documentation:

L<https://cnag-biomedical-informatics.github.io/pheno-ranker>

=head1 COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.

=cut
