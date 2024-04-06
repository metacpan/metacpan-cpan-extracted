package main 0.01;
use 5.020;
use experimental 'signatures';
use Getopt::Long;
use Mojo::Template;
use JSON::Pointer;
use YAML::PP;

use OpenAPI::PerlGenerator;
use OpenAPI::PerlGenerator::Utils 'update_file';
use OpenAPI::PerlGenerator::Template::Mojo;

=head1 NAME

openapi-codegen.pl - create and maintain (client) libraries from OpenAPI / Swagger spec

=head1 SYNOPSIS

  openapi-codegen.pl -a openapi/petstore-expanded.yaml -o t/petstore -p OpenAPI::PetStore --compile

=head1 OPTIONS

=over 4

=item * B< prefix > - the class prefix

=item * B< force > - overwrite all files, even the stub client

=item * B< output > - name of the output directory

=item * B< api > - name of the OpenAPI file (YAML or JSON)

=item * B< tidy > - clean up the code using perltidy

=item * B< compile > - check that the generated code compiles

=back

=cut

GetOptions(
    'prefix|p=s' => \my $prefix,
    'force|f'     => \my $force,
    'output|o=s'  => \my $output_directory,
    'api|a=s'     => \my $api_file,
    'tidy'        => \my $run_perltidy,
    'compile'     => \my $check_compile,
);
$prefix //= 'My::API';
$api_file //= 'openapi/openapi.yaml';
$output_directory //= '.';

my $schema = YAML::PP->new( boolean => 'JSON::PP' )->load_file( $api_file );

my %template = %OpenAPI::PerlGenerator::Template::Mojo::template;

my $generator = OpenAPI::PerlGenerator->new(
    templates => \%template,
    tidy      => $run_perltidy,
);

my @packages = $generator->generate(
    schema => $schema,
    prefix => $prefix,
);

# This is not to be run online, as people could put Perl code into the Prefix
# or any OpenAPI method name for example
my $res;
if( $check_compile ) {
    # Compile things a second time ...
    $res = $generator->load_schema(
        packages => \@packages,
    );

    for my $err ($res->{errors}->@*) {
        warn $err->{name};
        warn $err->{filename};
        warn $err->{message};
    }
}

# Should we still rewrite things even if we had errors above?!
# overwriting the files is not nice, but makes for much easier debugging...
for my $package (@packages) {
    update_file( filename => $package->{filename},
                 output_directory => $output_directory,
                 keep_existing => (!!($package->{package} =~ /\bClient\z/)),
                 content => $package->{source},
                );
}

# If we compiled the stuff, exit with error code 1 if there are errors
if( $res ) {
    exit $res->{errors}->@* > 0;
}

=head1 SEE ALSO

The OpenAPI spec - L<https://spec.openapis.org/oas/v3.1.0#openapi-document>

=cut

__END__
[ ] Move common parts of POD generation into a subroutine / include()-able
    template
[ ] Split out the templates into separate files
[ ] Handle variables in servers (OpenAPI::Modern dislikes that field):
    servers:
      - url: https://{host}/api/v2
        variables:
          host:
            default: someserver.example
[ ] handle https://raw.githubusercontent.com/OAI/OpenAPI-Specification/master/examples/v3.0/uspto.yaml
[ ] move method call example invocation into a subroutine/subtemplate
[ ] Support "schema" part of parameter joining
[ ] Support multipart/form-data ( https://swagger.io/docs/specification/describing-request-body/ )
[ ] support parameters in cookies
[ ] Maybe handle allOf types? This is basically composition, a list of things
    that need to match ...
[ ] Can we qualify documentation for returns "on success" and "on error" from the HTTP codes?!
[ ] Convert the documentation markdown to Pod
[ ] handle response headers
