#!perl
use 5.020;
use Test2::V0 '-no_srand';

use HTTP::Request::Diff;

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
    #'ollama' => 'AI::Ollama',
    #'petstore' => 'OpenAPI::PetStore',
    #'more-testcases' => 'More::TestCases',
    'whisper.cpp' => 'Speech::Recognition::Whisper',
);

my @testcases = Mojo::File->new( 't/whisper.cpp' );
for my $known (@testcases) {
    (my $api_file_json) = Mojo::File->new( 't/whisper.cpp/openapi.json' );
    my $prefix = $prefix{ $known->basename };
    note "$prefix";
    my $schema = JSON::PP->new()->decode( $api_file_json->slurp());
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

    use Data::Dumper;
    my $tx = Speech::Recognition::Whisper::Client->new(
        server => 'http://example.com:8080',
        schema => $schema,
    )->_build_load_request( model => 'models/ggml-large-v3.bin' );

    my $form_params = <<'HTTP';
POST /load HTTP/1.1
Host: example.com:8080
User-Agent: curl/7.88.1
Accept: application/json,application/text
Content-Length: 164
Content-Type: multipart/form-data; boundary=------------------------6aefc0639f22d13e

--------------------------6aefc0639f22d13e
Content-Disposition: form-data; name="model"

models/ggml-large-v3.bin
--------------------------6aefc0639f22d13e--
HTTP
    # convert all forms of newlines into \r\n
    $form_params =~ s/\r?\n/\r\n/mg;

    my $diff = HTTP::Request::Diff->new(
        reference => $form_params,
        skip_headers => ['Accept-Encoding','User-Agent'],
        #ignore_headers => \@skip2,
        mode => 'semantic', # default is 'semantic'
    );

    my @differences = $diff->diff( $tx->req->to_string );

    if( ! is 0+@differences, 0, "No differences in HTTP request" ) {
        diag $diff->as_table(@differences);
    }
}

done_testing;
