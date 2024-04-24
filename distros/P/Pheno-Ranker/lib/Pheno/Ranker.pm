package Pheno::Ranker;

use strict;
use warnings;
use autodie;
use feature qw(say);
use Data::Dumper;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Spec::Functions qw(catdir catfile);
use Term::ANSIColor qw(:constants);
use Moo;
use Types::Standard qw(Str Int Num Enum ArrayRef HashRef Undef Bool);
use File::ShareDir::ProjectDistDir qw(dist_dir);
use List::Util qw(all);
use Pheno::Ranker::IO;
use Pheno::Ranker::Align;
use Pheno::Ranker::Stats;

use Exporter 'import';
our @EXPORT_OK = qw($VERSION write_json);

# Personalize warn and die functions
$SIG{__WARN__} = sub { warn BOLD YELLOW "Warn: ", @_ };
$SIG{__DIE__}  = sub { die BOLD RED "Error: ", @_ };

# Global variables:
$Data::Dumper::Sortkeys = 1;
our $VERSION   = '0.08';
our $share_dir = dist_dir('Pheno-Ranker');

# Set developoent mode
use constant DEVEL_MODE => 0;

# Misc variables
my ( $config_sort_by, $config_similarity_metric_cohort,
    $config_max_out, $config_max_number_var,
    $config_seed,    @config_allowed_terms );
my $default_config_file = catfile( $share_dir, 'conf', 'config.yaml' );

############################################
# Start declaring attributes for the class #
############################################

# Complex defaults here
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
    }
);

# Private Method: _set_basic_config
# Sets basic configuration parameters from the provided config.
sub _set_basic_config {
    my ( $self, $config ) = @_;
    $config_sort_by                  = $config->{sort_by} // 'hamming';
    $config_similarity_metric_cohort = $config->{similarity_metric_cohort}
      // 'hamming';
    $config_max_out        = $config->{max_out}        // 50;
    $config_max_number_var = $config->{max_number_var} // 10_000;
    $config_seed =
      ( defined $config->{seed} && Int->check( $config->{seed} ) )
      ? $config->{seed}
      : 123456789;
}

# Private Method: _validate_and_set_exclusive_config
# Validates and sets configuration parameters that are exclusive or conditional.
sub _validate_and_set_exclusive_config {
    my ( $self, $config, $config_file ) = @_;

    # Validate $config->{allowed_terms}
    unless ( exists $config->{allowed_terms}
        && ArrayRef->check( $config->{allowed_terms} )
        && @{ $config->{allowed_terms} } )
    {
        die "No <allowed terms> provided or not an array ref at $config_file\n";
    }
    @config_allowed_terms = @{ $config->{allowed_terms} };
}

# Private Method: _set_additional_config
# Sets additional configuration parameters on $self.
sub _set_additional_config {
    my ( $self, $config, $config_file ) = @_;
    $self->{primary_key}              = $config->{primary_key} // 'id';       # setter
    $self->{exclude_properties_regex} = $config->{exclude_properties_regex}
      // undef;                                                               # setter
    $self->{exclude_properties_regex_qr} =
      defined $self->{exclude_properties_regex}
      ? qr/$self->{exclude_properties_regex}/
      : undef;                                                                # setter
    $self->{array_terms}    = $config->{array_terms} // ['foo'];              # setter (TBV)
    $self->{array_regex}    = $config->{array_regex} // '^([^:]+):(\d+)';       # setter (TBV)
    $self->{array_regex_qr} = qr/$self->{array_regex}/;                       # setter (TBV)
    $self->{array_terms_regex_str} =
      '^(' . join( '|', map { "\Q$_\E" } @{ $self->{array_terms} } ) . '):';   # setter (TBV)
    $self->{array_terms_regex_qr} = qr/$self->{array_terms_regex_str}/;        # setter (TBV)
    $self->{format}               = $config->{format};                         #setter

    # Validate $config->{id_correspondence} for "real" array_terms
    if ( $self->{array_terms}[0] ne 'foo' ) {
        unless ( exists $config->{id_correspondence}
            && HashRef->check( $config->{id_correspondence} ) )
        {
            die
"No <id_correspondence> provided or not a hash ref at $config_file\n";
        }
        $self->{id_correspondence} = $config->{id_correspondence};

        # Validate format and check match in config->{id_correspondence}
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
    default => $config_max_out,                    # Limit to speed up runtime
    is      => 'ro',
    coerce  => sub { $_[0] // $config_max_out },
    lazy    => 1,
    isa     => Int
);

has max_number_var => (
    default => $config_max_number_var,
    is      => 'ro',
    coerce  => sub { $_[0] // $config_max_number_var },
    lazy    => 1,
    isa     => Int
);

has hpo_file => (
    default => catfile( $share_dir, 'db', 'hp.json' ),
    coerce  => sub {
        $_[0] // catfile( $share_dir, 'db', 'hp.json' );
    },
    is  => 'ro',
    isa => sub { die "Error <$_[0]> is not a valid file" unless -e $_[0] },
);

has poi_out_dir => (
    default => catdir('./'),
    coerce  => sub {
        $_[0] // catdir('./');
    },
    is  => 'ro',
    isa => sub { die "<$_[0]> dir does not exist" unless -d $_[0] },
);

has [qw /include_terms exclude_terms/] => (
    is   => 'ro',
    lazy => 1,
    isa  => sub {
        my $value = shift;

        # Ensure the value is an array reference
        die "<--include_terms> and <--exclude_terms> must be an array ref\n"
          unless ref $value eq 'ARRAY';

        # Validate each term against allowed terms
        foreach my $term (@$value) {
            die
"Invalid term '$term' in <--include_terms> or <--exclude_terms>. Allowed values are: "
              . join( ', ', @config_allowed_terms ) . "\n"
              unless grep { $_ eq $term } @config_allowed_terms;
        }
    },
    default => sub { [] },
);

has 'cli' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,                     # Set the default value to 0
    coerce  => sub { $_[0] // 0 },    # Coerce to 0 if undefined
);

# Miscellanea atributes here
has [
    qw/target_file weights_file out_file include_hpo_ascendants align align_basename export export_basename log verbose age/
] => ( is => 'ro' );

has [qw /append_prefixes reference_files patients_of_interest/] =>
  ( default => sub { [] }, is => 'ro' );

##########################################
# End declaring attributes for the class #
##########################################

sub BUILD {

    # BUILD: is an instance method that is called after the object has been constructed but before it is returned to the caller.
    # BUILDARGS is a class method that is responsible for processing the arguments passed to the constructor (new) and returning a hash reference of attributes that will be used to initialize the object.
    my $self = shift;

    # ************************
    # Start Miscellanea checks
    # ************************

    # Check append_prefixes if provided
    if ( @{ $self->{append_prefixes} } ) {

        # Ensure there are more than one reference files
        die "<--append_prefixes> requires at least 2 cohort files!\n"
          unless @{ $self->{reference_files} } > 1;

        # Ensure numbers of cohorts and append-prefixes match
        die "The number of items in <--r> and <--append-prefixes> must match!\n"
          unless @{ $self->{reference_files} } == @{ $self->{append_prefixes} };
    }

    # Check patients_of_interest if provided
    if ( @{ $self->{patients_of_interest} } ) {

        # Ensure reference files are provided when using patients_of_interest
        die "<--patients-of-interest> must be used with <--r>\n"
          unless @{ $self->{reference_files} };
    }

    # **********************
    # End Miscellanea checks
    # **********************
}

sub run {

    my $self = shift;

    #print Dumper $self and die;

    # Load variables
    my $reference_files        = $self->{reference_files};
    my $target_file            = $self->{target_file};
    my $weights_file           = $self->{weights_file};
    my $export                 = $self->{export};
    my $export_basename        = $self->{export_basename};
    my $include_hpo_ascendants = $self->{include_hpo_ascendants};
    my $hpo_file               = $self->{hpo_file};
    my $align                  = $self->{align};
    my $align_basename         = $self->{align_basename};
    my $out_file               = $self->{out_file};
    my $cohort_files           = $self->{cohort_files};
    my $append_prefixes        = $self->{append_prefixes};
    my $primary_key            = $self->{primary_key};
    my $poi                    = $self->{patients_of_interest};
    my $poi_out_dir            = $self->{poi_out_dir};
    my $cli                    = $self->{cli};

    # die if --align dir does not exist
    my $align_dir = defined $align ? dirname($align) : '.';
    die "Directory <$align_dir> does not exist (used with --align)\n"
      unless -d $align_dir;

    my $export_dir = defined $export ? dirname($export) : '.';
    die "Directory <$export_dir> does not exist (used with --export)\n"
      unless -d $export_dir;

    # We assing weights if <--w>
    # NB: The user can exclude variables by using variable: 0
    my $weight = validate_json($weights_file);

    # Now we load $hpo_nodes, $hpo_edges if --include_hpo_ascendants
    # NB: we load them within $self to minimize the #args
    my $nodes = my $edges = undef;
    ( $nodes, $edges ) = parse_hpo_json( read_json($hpo_file) )
      if $include_hpo_ascendants;
    $self->{nodes} = $nodes;    # setter
    $self->{edges} = $edges;    # setter

    ###############################
    # START READING -r | -cohorts #
    ###############################

    # *** IMPORTANT ***
    # We have three modes of operation:
    # 1 - intra-cohort (--r) a.json
    # 2 - inter-cohort (--r) a.json b.json c.json
    # 3 - patient (assigned automatically if -t)

    # *** IMPORTANT ***
    # $ref_data is an array array where each element is the content of the file (e.g, [] or {})
    my $ref_data = [];
    for my $cohort_file ( @{$reference_files} ) {
        die "<$cohort_file> does not exist\n" unless -f $cohort_file;

        # Load JSON file as Perl data structure
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
        if ( ref $json_data eq ref [] ) {    # array - 1st element only
            die $msg unless exists $json_data->[0]->{$primary_key};
        }
        else {                               # hash
            die $msg unless exists $json_data->{$primary_key};
        }

        # Load data into array
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

    ##############################
    # ENDT READING -r | -cohorts #
    ##############################

    #-------------------------------
    # Write json for $poi if --poi |
    #-------------------------------
    # *** IMPORTANT ***
    # It will exit when done (dry-run)
    write_poi(
        {
            ref_data    => $ref_data,
            poi         => $poi,
            poi_out_dir => $poi_out_dir,
            primary_key => $primary_key,
            verbose     => $self->{verbose}
        }
      )
      and exit
      if @$poi;

    # We will process $ref_data to get stats on coverage
    my $coverage_stats = coverage_stats($ref_data);

    # Now check existance of include_terms within the data
    #print Dumper $self->{include_terms} and die;
    die
"--include-terms <@{$self->{include_terms}}> does not exist in the cohort(s)\n"
      unless check_existence_of_include_terms( $coverage_stats,
        $self->{include_terms} );

    # We have to check if we have BFF|PXF or others (unless defined at config)
    $self->add_attribute( 'format', check_format($ref_data) )
      unless defined $self->{format};    # setter via sub

    # First we create:
    # - $glob_hash => hash with all the COHORT keys possible
    # - $ref_hash  => BIG hash with all individiduals' keys "flattened"
    my ( $glob_hash, $ref_hash ) =
      create_glob_and_ref_hashes( $ref_data, $weight, $self );

    # Limit the number of variables if > $self-{max_number_var}
    # *** IMPORTANT ***
    # Change only performed in $glob_hash
    $glob_hash = randomize_variables( $glob_hash, $self )
      if keys %$glob_hash > $self->{max_number_var};

    # Second we peform one-hot encoding for each individual
    my $ref_binary_hash = create_binary_digit_string( $glob_hash, $ref_hash );

    # Hases to be serialized to JSON if <--export>
    my $hash2serialize = {
        glob_hash       => $glob_hash,
        ref_hash        => $ref_hash,
        ref_binary_hash => $ref_binary_hash,
        coverage_stats  => $coverage_stats
    };

    # Perform cohort comparison
    cohort_comparison( $ref_binary_hash, $self ) unless $target_file;

    # Perform patient-to-cohort comparison and rank if (-t)
    if ($target_file) {

        ####################
        # START READING -t #
        ####################

        # local $tar_data is for patient
        my $tar_data = array2object(
            io_yaml_or_json( { filepath => $target_file, mode => 'read' } ) );

        ##################
        # END READING -t #
        ##################

        # The target file has to have $_->{$primary_key} otherwise die
        die
"Sorry, <$target_file> does not contain primary_key <$primary_key>. Are you using the right config file?\n"
          unless exists $tar_data->{$primary_key};

        # We store {primary_key} as a variable as it might be deleted from $tar_data (--exclude-terms id)
        my $tar_data_id = $tar_data->{$primary_key};

        # Now we load the rest of the hashes
        my $tar_hash = {
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
        my $tar_binary_hash =
          create_binary_digit_string( $glob_hash, $tar_hash );
        my (
            $results_rank,        $results_align, $alignment_ascii,
            $alignment_dataframe, $alignment_csv
          )
          = compare_and_rank(
            {
                glob_hash       => $glob_hash,
                ref_binary_hash => $ref_binary_hash,
                tar_binary_hash => $tar_binary_hash,
                weight          => $weight,
                self            => $self
            }
          );

        # Print Ranked results to STDOUT only if CLI
        say join "\n", @$results_rank if $cli;

        # Write txt (
        write_array2txt( { filepath => $out_file, data => $results_rank } );

        # Write TXT for alignment (ALWAYS!!)
        write_alignment(
            {
                align     => $align ? $align : $align_basename,    # DON'T -- $align // $align_basename,
                ascii     => $alignment_ascii,
                dataframe => $alignment_dataframe,
                csv       => $alignment_csv
            }
        ) if defined $align;

        # Load keys into hash if <--e>
        if ( defined $export ) {
            $hash2serialize->{tar_hash}        = $tar_hash;
            $hash2serialize->{tar_binary_hash} = $tar_binary_hash;
            $hash2serialize->{alignment_hash}  = $results_align
              if defined $align;
        }
    }

    # Dump to JSON if <--export>
    # NB: Must work for -r and -t
    serialize_hashes(
        {
            data            => $hash2serialize,
            export_basename => $export ? $export : $export_basename
        }
    ) if defined $export;

    # Return
    return 1;
}

sub add_attribute {

    #  Bypassing the encapsulation provided by Moo
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value;
    return 1;
}

1;

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

There is only method named c<run>. See above the syntax.

For more information check the documentation:

L<https://cnag-biomedical-informatics.github.io/pheno-ranker>

=head1 COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.

=cut

