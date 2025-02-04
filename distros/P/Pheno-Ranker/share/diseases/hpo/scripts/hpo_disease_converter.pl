#!/usr/bin/perl
#
#   A script that creates a disease-based 
#   BFF/PXF JSON array from HPO CSV data
#
#   Last Modified: Jan/15/2024
#
#   $VERSION taken from Pheno::Ranker
#
#   Copyright (C) 2023-2025 Manuel Rueda - CNAG (manuel.rueda@cnag.eu)
#
#   License: Artistic License 2.0
#
#   If this program helps you in your research, please cite.

use strict;
use warnings;
use Text::CSV_XS;
use JSON::XS;
use Getopt::Long qw(:config no_ignore_case);

# Command-line arguments
GetOptions(
    'i|input=s'  => \my $input_file,
    'f|format=s' => \my $format,
) or die "Usage: $0 -i input.csv -f [pxf|bff]\n";

# Handles both: <genes_to_phenotype.txt>  <phenotype_to_genes.txt>
die "Input file is required.\nUsage: $0 -i input.csv -f [pxf|bff]\n" unless $input_file;
die "Format must be 'pxf' or 'bff'.\n" unless $format && ($format eq 'pxf' || $format eq 'bff');

# Set a fixed seed for reproducibility
srand(12345);

# Initialize CSV parser
my $csv = Text::CSV_XS->new({
    binary    => 1,
    sep_char  => "\t",
    auto_diag => 1,
});

# Open the input CSV file
open my $fh, '<', $input_file or die "Could not open '$input_file': $!";

# Read the header
my $header = $csv->getline($fh);
$csv->column_names(@$header);

# Data structures to hold diseases categorized by type
my %diseases = (
    OMIM  => {},
    ORPHA => {},
);

# Process each row in the CSV
while (my $row = $csv->getline_hr($fh)) {
    my $hpo_id     = $row->{'hpo_id'};
    my $hpo_name   = $row->{'hpo_name'};
    my $disease_id = $row->{'disease_id'};

    my ($disease_type, $disease_identifier) = split(':', $disease_id, 2);

    unless (exists $diseases{$disease_type}) {
        warn "Unknown disease type '$disease_type' for ID '$disease_id'. Skipping.\n";
        next;
    }

    unless (exists $diseases{$disease_type}{$disease_identifier}) {
        $diseases{$disease_type}{$disease_identifier} = initialize_entry($disease_id, $format);
    }

    add_feature($diseases{$disease_type}{$disease_identifier}, $hpo_id, $hpo_name, $format);
}

close $fh;

# Convert disease hashes to arrays for JSON encoding
my %output_data;
foreach my $type (keys %diseases) {
    $output_data{$type} = [ values %{ $diseases{$type} } ];
}

# Initialize JSON encoder
my $json = JSON::XS->new->utf8->pretty->canonical;

# Write JSON files
foreach my $type (keys %output_data) {
    my $filename = lc($type) . "." . lc($format) . ".json";
    write_json($output_data{$type}, $filename, $json);
}

print "Successfully wrote:\n" . (exists $output_data{'OMIM'} ? "omim.$format.json\n" : "") 
      . (exists $output_data{'ORPHA'} ? "orpha.$format.json\n" : "");

# Subroutine to initialize an entry
sub initialize_entry {
    my ($disease_id, $format) = @_;
    my $entry = {
        id => $disease_id,
    };
    if ($format eq 'pxf') {
        $entry->{subject} = {
            id          => $disease_id,
            sex         => get_random_sex_pxf(),
            vitalStatus => { status => "ALIVE" },
        };
    } elsif ($format eq 'bff') {
        $entry->{sex} = get_random_sex_bff();
    }
    $entry->{phenotypicFeatures} = [];
    return $entry;
}

# Subroutine to add a feature
sub add_feature {
    my ($entry, $hpo_id, $hpo_name, $format) = @_;
    foreach my $feature (@{ $entry->{phenotypicFeatures} }) {
        if ($format eq 'pxf' && $feature->{type}{id} eq $hpo_id) {
            return;
        }
        if ($format eq 'bff' && $feature->{featureType}{id} eq $hpo_id) {
            return;
        }
    }
    if ($format eq 'pxf') {
        push @{ $entry->{phenotypicFeatures} }, { type => { id => $hpo_id, label => $hpo_name } };
    } elsif ($format eq 'bff') {
        push @{ $entry->{phenotypicFeatures} }, { featureType => { id => $hpo_id, label => $hpo_name } };
    }
}

# Subroutine to get random sex for pxf
sub get_random_sex_pxf {
    my @sex_options = ("MALE", "FEMALE");
    return $sex_options[int(rand(@sex_options))];
}

# Subroutine to get random sex for bff
sub get_random_sex_bff {
    my @sex_options = (
        { id => "NCIT:C20197", label => "Male" },
        { id => "NCIT:C16576", label => "Female" }
    );
    return $sex_options[int(rand(@sex_options))];
}

# Subroutine to write JSON data to a file
sub write_json {
    my ($data_ref, $filename, $json_encoder) = @_;
    open my $out_fh, '>', $filename or die "Could not open '$filename' for writing: $!";
    print $out_fh $json_encoder->encode($data_ref);
    close $out_fh;
}
