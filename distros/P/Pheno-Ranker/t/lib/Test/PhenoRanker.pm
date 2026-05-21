package Test::PhenoRanker;

use strict;
use warnings;

use Exporter 'import';
use File::Spec;
use File::Spec::Functions qw(catdir catfile);
use File::Temp qw(tempfile);

our @EXPORT_OK = qw(data_dir fixture fixture_dir temp_output_file);

sub data_dir {
    return catdir( 't', 'data' );
}

sub fixture {
    return catfile( data_dir(), @_ );
}

sub fixture_dir {
    return catdir( data_dir(), @_ );
}

sub temp_output_file {
    my (%args) = @_;
    my $suffix = exists $args{suffix} ? $args{suffix} : '.json';
    my $dir    = exists $args{dir}    ? $args{dir}    : File::Spec->tmpdir();
    my ( undef, $file ) = tempfile( DIR => $dir, SUFFIX => $suffix, UNLINK => 1 );
    return $file;
}

1;
