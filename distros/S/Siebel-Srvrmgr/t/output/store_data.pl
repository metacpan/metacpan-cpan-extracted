#!/usr/bin/env perl
#===============================================================================
#
#         FILE: store_data.pl
#
#  DESCRIPTION: this small program is to help adding YAML serialized data into srvrmgr_mock program in the DATA handler
#
#       AUTHOR: arfreitas@cpan.org,
#      CREATED: 11/07/2013 17:17:37
#===============================================================================
use warnings;
use strict;
use utf8;
use YAML::XS 0.62 qw(DumpFile);
use File::Spec;
use Cwd;
use feature 'say';

my %data;
my @keys = (
    'load_preferences',
    'list_comp',
    'list_comp_types',
    'list_params',
    'list_comp_def',
    'list_comp_def_srproc',
    'list_params_for_srproc',
    'list_servers',
    'list_tasks',
    'list_tasks_for_server_siebfoobar_component_srproc',
    'load_preferences'
);

foreach my $key (@keys) {
    say "Processing $key";
    read_output( \%data, $key );
}

my $output_file = shift;
chomp($output_file);
unless ( defined($output_file) ) {
    die
"the filename parameter must be given a valid pathname to a srvrmgr output file";
}
DumpFile( $output_file, \%data );

sub read_output {
    my ( $data_ref, $key ) = @_;
    my $filename =
      File::Spec->catfile( getcwd(), 'output', 'mock', 'fixed_width',
        $key . '.txt' );
    open( my $in, '<:utf8', $filename ) or die "Cannot read $filename: $!\n";
    my @data = <$in>;
    close($in);
    $data_ref->{$key} = \@data;
    return 1;
}
