package Pheno::Ranker::Options;

use strict;
use warnings;

use File::Spec::Functions qw(catdir catfile);
use Moo;

has config => (
    is       => 'ro',
    required => 1,
);

has share_dir => (
    is       => 'ro',
    required => 1,
);

sub defined_constructor_args {
    my ( $class, $args ) = @_;
    return { map { $_ => $args->{$_} } grep { defined $args->{$_} } keys %$args };
}

sub apply_to {
    my ( $self, $ranker ) = @_;

    $self->_apply_defaults($ranker);
    $self->_validate_array_options($ranker);
    $self->_validate_path_options($ranker);
    $self->_validate_terms($ranker);

    return 1;
}

sub _apply_defaults {
    my ( $self, $ranker ) = @_;

    my %defaults = (
        append_prefixes           => [],
        cli                       => 0,
        exclude_terms             => [],
        hpo_file                  => catfile( $self->share_dir, 'db', 'hp.json' ),
        include_terms             => [],
        max_matrix_records_in_ram => $self->config->max_matrix_records_in_ram,
        max_number_vars           => $self->config->max_number_vars,
        max_out                   => $self->config->max_out,
        matrix_format             => $self->config->matrix_format,
        patients_of_interest      => [],
        poi_out_dir               => catdir('./'),
        reference_files           => [],
        similarity_metric_cohort  => $self->config->similarity_metric_cohort,
        sort_by                   => $self->config->sort_by,
    );

    for my $attribute ( keys %defaults ) {
        $ranker->{$attribute} = $defaults{$attribute}
          unless exists $ranker->{$attribute};
    }

    return 1;
}

sub _validate_array_options {
    my ( $self, $ranker ) = @_;

    for my $attribute (
        qw(append_prefixes exclude_terms include_terms patients_of_interest reference_files)
      )
    {
        die "<$attribute> must be an array ref\n"
          unless ref $ranker->{$attribute} eq 'ARRAY';
    }

    return 1;
}

sub _validate_path_options {
    my ( $self, $ranker ) = @_;

    die "Error <$ranker->{hpo_file}> is not a valid file"
      unless -e $ranker->{hpo_file};
    die "<$ranker->{poi_out_dir}> dir does not exist"
      unless -d $ranker->{poi_out_dir};

    return 1;
}

sub _validate_terms {
    my ( $self, $ranker ) = @_;

    for my $attribute (qw(include_terms exclude_terms)) {
        $self->config->validate_terms( @{ $ranker->{$attribute} } );
    }

    return 1;
}

1;
