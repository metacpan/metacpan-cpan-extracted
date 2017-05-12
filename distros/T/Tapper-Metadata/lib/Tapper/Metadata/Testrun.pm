package Tapper::Metadata::Testrun;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Metadata::Testrun::VERSION = '5.0.1';
use strict;
use warnings;
use base 'Tapper::Metadata';

sub get_default_config {
    return {
        tables => {
            main_table => {
                name    => 'testrun',
                primary => 'id',
            },
            stats_table => {
                name        => 'reportgrouptestrunstats',
                primary     => 'testrun_id',
                foreign_key => {
                    main_table              => 'id',
                },
            },
            headers_table => {
                name          => 'testrun_metadata_headers',
                primary       => 'testrun_metadata_header_id',
                foreign_key   => {
                    main_table             => 'testrun_id',
                },                
            },
            lines_table => {
                name          => 'testrun_metadata_lines',
                primary       => [ 'testrun_metadata_header_id', 'bench_additional_value_id' ],
                foreign_key   => {
                    headers_table          => 'testrun_metadata_header_id',
                    additional_value_table => 'bench_additional_value_id',
                },
            },
        },
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Metadata::Testrun

=head1 AUTHOR

Roberto Schaefer <schaefr@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Amazon.com, Inc. or its affiliates.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
