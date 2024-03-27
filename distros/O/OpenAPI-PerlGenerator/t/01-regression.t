#!perl
use Test2::V0 '-no_srand';

use OpenAPI::PerlGenerator;
use OpenAPI::PerlGenerator::Template::Mojo;
use File::Basename;
use Mojo::File 'curfile', 'path';
use YAML::PP;
use JSON::PP;
use File::Path 'make_path';

use Getopt::Long;
GetOptions(
    'update|u' => \my $update,
);

=head1 NAME

regression.t - test regressions against known-good OpenAPI specs

=cut

my $gen = OpenAPI::PerlGenerator->new(
    templates => \%OpenAPI::PerlGenerator::Template::Mojo::template,
    tidy => 0,
);

my %prefix = (
    'ollama' => 'AI::Ollama',
    'petstore' => 'OpenAPI::PetStore',
    'more-testcases' => 'More::TestCases',
    'whisper.cpp' => 'Speech::Recognition::Whisper',
);

my @testcases = grep { -d } curfile()->dirname->list({ dir => 1 })->@*;
for my $known (@testcases) {
    (my $api_file_yaml) = grep { /\.yaml$/ } $known->list->@*;
    (my $api_file_json) = grep { /\.json$/ } $known->list->@*;
    my $prefix = $prefix{ $known->basename };
    note "$prefix";
    my $schema = $api_file_yaml ? YAML::PP->new( boolean => 'JSON::PP' )->load_file( $api_file_yaml )
               : $api_file_json ? JSON::PP->new()->decode( $api_file_json->slurp())
               : die "No YAML or JSON OpenAPI file found for $known";
    my @files = $gen->generate(
        schema => $schema,
        prefix => "$prefix",
    );

    # Compile things a second time ...
    my $res = $gen->load_schema(
        packages => \@files,
    );

    is 0+$res->{errors}->@*, 0, "No errors when compiling the package";
    if( $res->{errors}->@* ) {

        for my $err ($res->{errors}->@*) {
            diag $err->{name};
            diag $err->{filename};
            diag $err->{message};
        }
    }


    for my $f (@files) {
        # Check that all files exist and have the same content
        my $file = Mojo::File->new($known, $f->{filename});
        if( ok -f $file, "$file exists" ) {
        my $known_content = $file->slurp(':raw:UTF-8');
            is $f->{source}, $known_content, "The content has not changed";
        } else {
            SKIP: {
                skip "File does not exist", 1;
            };
        }
        if( $update ) {
            make_path( $file->dirname );
            $file->spew( $f->{ source });
        }
    }
}

done_testing;
