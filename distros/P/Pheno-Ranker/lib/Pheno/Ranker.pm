package Pheno::Ranker;

use strict;
use warnings;
use autodie;
use feature qw(say);
use Data::Dumper;
use File::Basename        qw(dirname);
use Cwd                   qw(abs_path);
use File::Spec::Functions qw(catdir catfile);
use Term::ANSIColor       qw(:constants);
use Moo;
use Types::Standard qw(Str Int Num Enum ArrayRef HashRef Undef Bool);
use File::ShareDir::ProjectDistDir qw(dist_dir);
use List::Util                     qw(all);
use Hash::Util                     qw(lock_hash);
use Pheno::Ranker::IO;
use Pheno::Ranker::Compare;
use Pheno::Ranker::Metrics;
use Pheno::Ranker::Graph;

use Exporter 'import';
our @EXPORT_OK = qw($VERSION write_json);

# Personalize warn and die functions
$SIG{__WARN__} = sub { warn BOLD YELLOW "Warn: ", @_ };
$SIG{__DIE__}  = sub { die BOLD RED "Error: ", @_ };

# Global variables:
$Data::Dumper::Sortkeys = 1;
our $VERSION   = '1.03';
our $share_dir = dist_dir('Pheno-Ranker');

# Set development mode
use constant DEVEL_MODE => 0;

# Misc variables
my ( $config_sort_by, $config_similarity_metric_cohort,
    $config_max_out, $config_max_number_vars, $config_max_matrix_items_in_ram, @config_allowed_terms );
my $default_config_file = catfile( $share_dir, 'conf', 'config.yaml' );

############################################
# Start declaring attributes for the class #
############################################

has 'config_file' => (
    is  => 'ro',
    isa =>
      sub { die "Config file '$_[0]' is not a valid file" unless -e $_[0] },
    default => $default_config_file,
    coerce  => sub { $_[0] // $default_config_file },
    trigger => sub {
        my ( $self, $config_file ) = @_;
        my $config = read_yaml($config_file);

        # Set basic configuration parameters
        $self->_set_basic_config($config);

        # Validate and set exclusive configuration parameters
        $self->_validate_and_set_exclusive_config( $config, $config_file );

        # Set additional configuration parameters on $self
        $self->_set_additional_config( $config, $config_file );

        # Lock config data (keys+values)
        lock_hash(%$config);
    }
);

# Private Method: _set_basic_config
sub _set_basic_config {
    my ( $self, $config ) = @_;
    $config_sort_by                  = $config->{sort_by} // 'hamming';
    $config_similarity_metric_cohort = $config->{similarity_metric_cohort}
      // 'hamming';
    $config_max_out         = $config->{max_out}         // 50;
    $config_max_number_vars = $config->{max_number_vars} // 10_000;
    $config_max_matrix_items_in_ram  = $config->{max_matrix_items_in_ram} // 5_000;
}

# Private Method: _validate_and_set_exclusive_config
sub _validate_and_set_exclusive_config {
    my ( $self, $config, $config_file ) = @_;
    unless ( exists $config->{allowed_terms}
        && ArrayRef->check( $config->{allowed_terms} )
        && @{ $config->{allowed_terms} } )
    {
        die "No <allowed terms> provided or not an array ref at $config_file\n";
    }
    @config_allowed_terms = @{ $config->{allowed_terms} };
}

# Private Method: _set_additional_config
sub _set_additional_config {
    my ( $self, $config, $config_file ) = @_;

    # Setters
    $self->{primary_key}             = $config->{primary_key} // 'id';
    $self->{exclude_variables_regex} = $config->{exclude_variables_regex}
      // undef;
    $self->{exclude_variables_regex_qr} =
      defined $self->{exclude_variables_regex}
      ? qr/$self->{exclude_variables_regex}/
      : undef;
    $self->{array_terms}    = $config->{array_terms} // ['foo'];
    $self->{array_regex}    = $config->{array_regex} // '^([^:]+):(\d+)';
    $self->{array_regex_qr} = qr/$self->{array_regex}/;
    $self->{array_terms_regex_str} =
      '^(' . join( '|', map { "\Q$_\E" } @{ $self->{array_terms} } ) . '):';
    $self->{array_terms_regex_qr} = qr/$self->{array_terms_regex_str}/;
    $self->{format}               = $config->{format};
    $self->{seed} =
      ( defined $config->{seed} && Int->check( $config->{seed} ) )
      ? $config->{seed}
      : 123456789;

    if ( $self->{array_terms}[0] ne 'foo' ) {
        unless ( exists $config->{id_correspondence}
            && HashRef->check( $config->{id_correspondence} ) )
        {
            die
"No <id_correspondence> provided or not a hash ref at $config_file\n";
        }
        $self->{id_correspondence} = $config->{id_correspondence};
        if ( exists $config->{format} && Str->check( $config->{format} ) ) {
            die
"<$config->{format}> does not match any key from <id_correspondence>\n"
              unless exists $config->{id_correspondence}{ $config->{format} };
        }
    }
}

has sort_by => (
    default => $config_sort_by,
    is      => 'ro',
    coerce  => sub { $_[0] // $config_sort_by },
    lazy    => 1,
    isa     => Enum [qw(hamming jaccard)]
);

has similarity_metric_cohort => (
    default => $config_similarity_metric_cohort,
    is      => 'ro',
    coerce  => sub { $_[0] // $config_similarity_metric_cohort },
    lazy    => 1,
    isa     => Enum [qw(hamming jaccard)]
);

has max_out => (
    default => $config_max_out,
    is      => 'ro',
    coerce  => sub { $_[0] // $config_max_out },
    lazy    => 1,
    isa     => Int
);

has max_number_vars => (
    default => $config_max_number_vars,
    is      => 'ro',
    coerce  => sub { $_[0] // $config_max_number_vars },
    lazy    => 1,
    isa     => Int
);

has max_matrix_items_in_ram => (
    default => $config_max_matrix_items_in_ram,
    is      => 'ro',
    coerce  => sub { $_[0] // $config_max_matrix_items_in_ram },
    lazy    => 1,
    isa     => Int
);

has hpo_file => (
    default => catfile( $share_dir, 'db', 'hp.json' ),
    coerce  => sub { $_[0] // catfile( $share_dir, 'db', 'hp.json' ) },
    is      => 'ro',
    isa     => sub { die "Error <$_[0]> is not a valid file" unless -e $_[0] },
);

has poi_out_dir => (
    default => catdir('./'),
    coerce  => sub { $_[0] // catdir('./') },
    is      => 'ro',
    isa     => sub { die "<$_[0]> dir does not exist" unless -d $_[0] },
);

has [qw/include_terms exclude_terms/] => (
    is   => 'ro',
    lazy => 1,
    isa  => sub {
        my $value = shift;
        die "<--include_terms> and <--exclude_terms> must be an array ref\n"
          unless ref $value eq 'ARRAY';
        foreach my $term (@$value) {
            die
"Invalid term '$term' in <--include_terms> or <--exclude_terms>. Allowed values are: "
              . join( ', ', @config_allowed_terms ) . "\n"
              unless grep { $_ eq $term } @config_allowed_terms;
        }
    },
    default => sub { [] },
);

has cli => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    coerce  => sub { $_[0] // 0 },
);

# Miscellaneous attributes
has [
    qw/target_file weights_file out_file include_hpo_ascendants
      retain_excluded_phenotypicFeatures align align_basename export export_basename
      log verbose age cytoscape_json graph_stats/
] => ( is => 'ro' );

has [qw/append_prefixes reference_files patients_of_interest/] =>
  ( default => sub { [] }, is => 'ro' );

has [qw/glob_hash_file ref_hash_file ref_binary_hash_file/] => ( is => 'ro' );

##########################################
# End declaring attributes for the class #
##########################################

sub BUILD {

    # BUILD: is an instance method that is called after the object has been constructed but before it is returned to the caller.
    # BUILDARGS is a class method that is responsible for processing the arguments passed to the constructor (new) and returning a hash reference of attributes that will be used to initialize the object.

    my $self = shift;

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
}

# ============================================================
#  run method
# ============================================================
sub run {
    my $self = shift;

    # -----------------------------------------------------
    # Retrieve configuration parameters from the object
    # -----------------------------------------------------
    my $reference_files          = $self->{reference_files};
    my $target_file              = $self->{target_file};
    my $weights_file             = $self->{weights_file};
    my $export                   = $self->{export};
    my $export_basename          = $self->{export_basename};
    my $include_hpo_ascendants   = $self->{include_hpo_ascendants};
    my $hpo_file                 = $self->{hpo_file};
    my $align                    = $self->{align};
    my $align_basename           = $self->{align_basename};
    my $out_file                 = $self->{out_file};
    my $cytoscape_json           = $self->{cytoscape_json};
    my $graph_stats              = $self->{graph_stats};
    my $append_prefixes          = $self->{append_prefixes};
    my $primary_key              = $self->{primary_key};
    my $poi                      = $self->{patients_of_interest};
    my $poi_out_dir              = $self->{poi_out_dir};
    my $cli                      = $self->{cli};
    my $similarity_metric_cohort = $self->{similarity_metric_cohort};
    my $weight                   = undef;

    # -----------------------------------------------------
    # Check directories for --align and --export options
    # -----------------------------------------------------
    my $align_dir = defined $align ? dirname($align) : '.';
    die "Directory <$align_dir> does not exist (used with --align)\n"
      unless -d $align_dir;
    my $export_dir = defined $export ? dirname($export) : '.';
    die "Directory <$export_dir> does not exist (used with --export)\n"
      unless -d $export_dir;

    # -----------------------------------------------------
    # Check for precomputed data (glob_hash, ref_hash, ref_binary_hash)
    # -----------------------------------------------------
    my $has_precomputed =
         defined $self->{glob_hash_file}
      && defined $self->{ref_hash_file}
      && defined $self->{ref_binary_hash_file};

    my ( $glob_hash, $ref_hash, $ref_binary_hash, $hash2serialize );

    if ($has_precomputed) {

        say "Using precomputed data" if $self->{verbose};

        # Use precomputed data provided via Moo attributes
        $glob_hash       = read_json( $self->{glob_hash_file} );
        $ref_hash        = read_json( $self->{ref_hash_file} );
        $ref_binary_hash = read_json( $self->{ref_binary_hash_file} );

        # Set format explicitly (for example, to 'PXF')
        $self->add_attribute( 'format', 'PXF' );

        $hash2serialize = {
            glob_hash       => $glob_hash,
            ref_hash        => $ref_hash,
            ref_binary_hash => $ref_binary_hash,
        };
    }
    else {
        # -----------------------------------------------------
        # Part A: Load reference cohort data
        # -----------------------------------------------------
        my $ref_data =
          $self->_load_reference_cohort_data( $reference_files, $primary_key,
            $append_prefixes );

        # -----------------------------------------------------
        # Load weights file and HPO data if needed
        # -----------------------------------------------------
        # We assing weights if <--w>
        # NB: The user can exclude variables by using variable: 0
        $weight = validate_json($weights_file);

        # Now we load $hpo_nodes, $hpo_edges if --include_hpo_ascendants
        # NB: we load them within $self to minimize the #args

        if ($include_hpo_ascendants) {
            my ( $nodes, $edges ) = parse_hpo_json( read_json($hpo_file) );
            $self->{nodes} = $nodes;
            $self->{edges} = $edges;
        }

        # -----------------------------------------------------
        # Part B: Compute cohort metrics
        # -----------------------------------------------------
        my ( $coverage_stats, $glob_hash_computed, $ref_hash_computed,
            $ref_binary_hash_computed, $hash2serialize_computed )
          = $self->_compute_cohort_metrics( $ref_data, $weight, $primary_key,
            $target_file );

        $glob_hash       = $glob_hash_computed;
        $ref_hash        = $ref_hash_computed;
        $ref_binary_hash = $ref_binary_hash_computed;
        $hash2serialize  = $hash2serialize_computed;
    }

    # -----------------------------------------------------
    # If no target file is provided, perform cohort comparison
    # -----------------------------------------------------
    cohort_comparison( $ref_binary_hash, $self ) unless $target_file;

    # Create and write Cytoscape JSON if requested
    my $graph = $self->_perform_graph_calculations( $out_file, $cytoscape_json,
        $graph_stats, $similarity_metric_cohort );

    # -----------------------------------------------------
    # Part C: Process patient data (if target_file is provided)
    # -----------------------------------------------------
    if ($target_file) {
        $self->_process_patient_data(
            {
                target_file     => $target_file,
                primary_key     => $primary_key,
                weight          => $weight,
                glob_hash       => $glob_hash,
                ref_hash        => $ref_hash,
                ref_binary_hash => $ref_binary_hash,
                align           => $align,
                align_basename  => $align_basename,
                out_file        => $out_file,
                cli             => $cli,
                verbose         => $self->{verbose},
            },
            \$hash2serialize
        );
    }

    # -----------------------------------------------------
    # Export JSON if requested
    # -----------------------------------------------------
    if ( defined $export ) {
        serialize_hashes(
            {
                data            => $hash2serialize,
                export_basename => $export ? $export : $export_basename
            }
        );
    }

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
    my $coverage_stats = coverage_stats($ref_data);
    die
"--include-terms <@{$self->{include_terms}}> does not exist in the cohort(s)\n"
      unless check_existence_of_include_terms( $coverage_stats,
        $self->{include_terms} );

    # We have to check if we have BFF|PXF or others (unless defined at config)

    $self->add_attribute( 'format', check_format($ref_data) )
      unless defined $self->{format};
    restructure_pxf_interpretations( $ref_data, $self );

    # First we create:
    # - $glob_hash => hash with all the COHORT keys possible
    # - $ref_hash  => BIG hash with all individiduals' keys "flattened"

    my ( $glob_hash, $ref_hash ) =
      create_glob_and_ref_hashes( $ref_data, $weight, $self );

    # Limit the number of variables if > $self-{max_number_vars}
    # *** IMPORTANT ***
    # Change only performed in $glob_hash
    if ( keys %$glob_hash > $self->{max_number_vars} ) {
        $glob_hash = randomize_variables( $glob_hash, $self );
    }

    # Second we peform one-hot encoding for each individual
    my $ref_binary_hash = create_binary_digit_string( $glob_hash, $ref_hash );

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

    my $tar_data = array2object(
        io_yaml_or_json( { filepath => $target_file, mode => 'read' } ) );

    # The target file has to have $_->{$primary_key} otherwise die

    die
"Sorry, <$target_file> does not contain primary_key <$primary_key>. Are you using the right config file?\n"
      unless exists $tar_data->{$primary_key};
    restructure_pxf_interpretations( $tar_data, $self );

    # We store {primary_key} as a variable as it might be deleted from $tar_data (--exclude-terms id)

    my $tar_data_id = $tar_data->{$primary_key};
    my $tar_hash    = {
        $tar_data_id => remap_hash(
            {
                hash   => $tar_data,
                weight => $weight,
                self   => $self
            }
        )
    };

    # *** IMPORTANT ***
    # The target binary is created from matches to $glob_hash
    # Thus, it does not include variables ONLY present in TARGET

    my $tar_binary_hash = create_binary_digit_string( $glob_hash, $tar_hash );
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
            self            => $self
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
    my ( $self, $out_file, $cytoscape_json, $graph_stats,
        $similarity_metric_cohort )
      = @_;

    my $graph;
    if ($cytoscape_json) {
        $graph = matrix2graph(
            {
                matrix      => $out_file,
                json        => $cytoscape_json,
                graph_stats => 1,
                verbose     => $self->{verbose},
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

sub add_attribute {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value;
    return 1;
}

1;

=pod

=head1 NAME

Convert::Pheno - A module that performs semantic similarity in PXF/BFF data structures and beyond (JSON|YAML)
  
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

The author requests that any published work that utilizes C<Pheno-Ranker> includes a cite to the the following reference:

Leist, I.C. et al. "Advancing Semantic Similarity Analysis of Phenotypic Data Stored in GA4GH Standards and Beyond. (2024) I<Submitted>.

=head1 AUTHOR

Written by Manuel Rueda, PhD. Info about CNAG can be found at L<https://www.cnag.eu>.

=head1 METHODS

There is only method named C<run>. See above the syntax.

For more information check the documentation:

L<https://cnag-biomedical-informatics.github.io/pheno-ranker>

=head1 COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.

=cut
