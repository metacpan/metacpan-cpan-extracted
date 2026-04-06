package Modern::OpenAPI::Generator;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.002';

use Modern::OpenAPI::Generator::Spec ();
use Modern::OpenAPI::Generator::Writer ();
use Modern::OpenAPI::Generator::CodeGen::Client ();
use Modern::OpenAPI::Generator::CodeGen::ClientModels ();
use Modern::OpenAPI::Generator::CodeGen::Server ();
use Modern::OpenAPI::Generator::CodeGen::StubData ();
use Modern::OpenAPI::Generator::CodeGen::Auth ();
use Modern::OpenAPI::Generator::CodeGen::Docs ();
use Modern::OpenAPI::Generator::CodeGen::Tests ();
use Path::Tiny qw(path);

sub new {
    my ( $class, %arg ) = @_;
    bless {
        spec_path => ( $arg{spec_path} // croak('spec_path required') ),
        output_dir => (
            length( $arg{output_dir} // '' )
            ? $arg{output_dir}
            : croak('output_dir required')
        ),
        name       => ( $arg{name} // croak('name required') ),
        client     => $arg{client}     // 1,
        server     => $arg{server}     // 1,
        ui         => $arg{ui}         // 1,
        sync       => $arg{sync}       // 1,
        async      => $arg{async}      // 1,
        skeleton   => $arg{skeleton}   // 0,
        force      => $arg{force}      // 0,
        merge       => $arg{merge}       // 0,
        signatures  => $arg{signatures}  // [],
        local_test  => $arg{local_test}  // 0,
    }, $class;
}

sub run {
    my ($self) = @_;

    my $spec = Modern::OpenAPI::Generator::Spec->load( $self->{spec_path} );
    my $writer = Modern::OpenAPI::Generator::Writer->new(
        root  => $self->{output_dir},
        force => $self->{force},
        merge => $self->{merge},
    );

    path( $self->{output_dir} )->mkpath( { mode => 0755 } );

    my $copy_spec = path( $self->{output_dir} )->child('share')->child('openapi.yaml');
    $copy_spec->parent->mkpath( { mode => 0755 } );
    if ( !( $self->{merge} && -e $copy_spec ) ) {
        path( $self->{spec_path} )->copy($copy_spec);
    }

    my $base = $self->{name};

    Modern::OpenAPI::Generator::CodeGen::Auth->emit_plugins(
        writer     => $writer,
        base       => $base,
        signatures => $self->{signatures},
    );

    if ( $self->{client} ) {
        Modern::OpenAPI::Generator::CodeGen::Client->generate(
            writer   => $writer,
            spec     => $spec,
            base     => $base,
            sync     => $self->{sync},
            async    => $self->{async},
            signatures => $self->{signatures},
        );
    }

    # Models are required for StubData when serving with --local-test without a generated HTTP client.
    if ( $self->{client} || ( $self->{server} && $self->{local_test} ) ) {
        Modern::OpenAPI::Generator::CodeGen::ClientModels->generate(
            writer => $writer,
            spec   => $spec,
            base   => $base,
        );
    }

    if ( $self->{server} ) {
        Modern::OpenAPI::Generator::CodeGen::Server->generate(
            writer     => $writer,
            spec       => $spec,
            base       => $base,
            skeleton   => $self->{skeleton},
            local_test => $self->{local_test},
            ui         => $self->{ui},
            signatures => $self->{signatures},
        );
        if ( $self->{local_test} ) {
            Modern::OpenAPI::Generator::CodeGen::StubData->generate(
                writer => $writer,
                base   => $base,
            );
        }
    }
    elsif ( $self->{ui} ) {
        Modern::OpenAPI::Generator::CodeGen::Server->generate_spec_ui_only(
            writer => $writer,
            spec   => $spec,
            base   => $base,
        );
    }

    my $ui_only = !$self->{server} && $self->{ui};

    Modern::OpenAPI::Generator::CodeGen::Docs->generate(
        writer     => $writer,
        spec       => $spec,
        base       => $base,
        client     => $self->{client},
        server     => $self->{server},
        ui         => $self->{ui},
        sync       => $self->{sync},
        async      => $self->{async},
        ui_only    => $ui_only,
        local_test => $self->{local_test},
    );

    Modern::OpenAPI::Generator::CodeGen::Tests->generate(
        writer      => $writer,
        base        => $base,
        client      => $self->{client},
        server      => $self->{server},
        ui          => $self->{ui},
        sync        => $self->{sync},
        async       => $self->{async},
        signatures  => $self->{signatures},
        ui_only     => $ui_only,
        local_test  => $self->{local_test},
    );

    $self->_write_root_cpanfile($writer);
    return $self;
}

sub _write_root_cpanfile {
    my ( $self, $writer ) = @_;
    my $txt = <<'CPAN';
requires 'perl', '5.026';
requires 'Mojolicious', '9.0';
requires 'Mojolicious::Plugin::OpenAPI', '5.00';
requires 'Mojolicious::Plugin::SwaggerUI', '0';
requires 'JSON::Validator', '5.0';
requires 'OpenAPI::Modern', '0.060';
requires 'Moo', '2.005';
requires 'Types::Standard', '2.000';
requires 'YAML::PP', '0.034';
requires 'JSON::MaybeXS', '1.004';
requires 'Modern::Perl::Prelude', '0';
requires 'Digest::SHA', '6.00';

on test => sub {
    requires 'Test::More', '0.96';
};
CPAN
    $writer->write( 'cpanfile', $txt );
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator - OpenAPI 3.x client/server generator for Mojolicious

=head1 SYNOPSIS

  perl bin/oapi-perl-gen --name MyApp::API --output ./out openapi.yaml

  # or from Perl:
  use Modern::OpenAPI::Generator;
  Modern::OpenAPI::Generator->new(
    spec_path  => 'openapi.yaml',
    output_dir => './generated',
    name       => 'MyApp::API',
  )->run;

=head1 DESCRIPTION

Generates:

=over 4

=item * C<::Client::Core>, C<::Client::Sync>, C<::Client::Async> (with C<< --client >>) and C<::Client::Result> — C<Result> holds C<tx> (L<Mojo::Transaction>) and C<data> (JSON or inflated C<::Model::*>). Shared C<::Model::*> (and C<::StubData> for local stubs) sit under the root package, usable from client or server. They are emitted with C<< --client >> or with C<< --server --local-test >> (even C<< --no-client >>). When C<openapi_schema_file> is set, L<OpenAPI::Modern> validates outgoing requests and incoming responses before inflation.

=item * Generated server controllers call C<< $c->openapi->valid_input >> so L<Mojolicious::Plugin::OpenAPI> validates each incoming request; responses are checked when you C<< render(openapi =E<gt> ...) >> per the plugin

=item * C<< oapi-perl-gen --local-test >> emits C<::StubData> and controller stubs that return random data from the response schema, inflated with C<::Model::*->from_json>, then serialized (C<TO_JSON>) instead of HTTP 501

=item * Mojolicious server with L<Mojolicious::Plugin::OpenAPI>

=item * L<Mojolicious::Plugin::SwaggerUI> at C</swagger> on the same server as the API when C<< --ui >> is on

=item * Optional auth helper modules (HMAC, Bearer) under C<::Auth::Plugin::*>

=item * F<README.md> in the output tree (usage, install, server/client/UI commands — OpenAPI Generator style)

=item * F<docs/*.md> per-tag API reference and C<components/schemas> model pages, linked from the README

=item * F<t/*.t> smoke tests for the generated modules

=back

See L<Modern::OpenAPI::Generator::CLI> (C<oapi-perl-gen --help>) for C<--client> / C<--server> / C<--ui> selection rules. For Swagger UI, the generated C<script/server.pl> prepends the request origin to C<servers> in the served YAML only when run with C<--local-test> (runtime) or C<OAPI_SWAGGER_LOCAL_ORIGIN=1> — this is separate from C<oapi-perl-gen --local-test> (codegen stubs).

=head1 METHODS

=head2 new

Builds a generator instance. Required: C<spec_path>, C<output_dir>, C<name>.
Optional boolean / list keys include C<client>, C<server>, C<ui>, C<sync>,
C<async>, C<skeleton>, C<force>, C<merge>, C<signatures>, C<local_test>.

=head2 run

Loads the OpenAPI document, emits files under C<output_dir>, writes a root
F<cpanfile>, and returns C<$self>.

=head1 INSTALLATION

After installing the distribution from CPAN (C<cpanm Modern::OpenAPI::Generator>)
or from a source tree (C<perl Makefile.PL && make && make install>), the
C<oapi-perl-gen> script is on your C<PATH>.

=head1 DEVELOPMENT

When running tests from a checkout, remove any stale F<blib/> directory first
so C<lib/> is used (see the project F<README.md> / F<CONTRIBUTING.md>).

=head1 SEE ALSO

L<OpenAPI::Modern>, L<Mojolicious::Plugin::OpenAPI>, L<Mojolicious::Plugin::SwaggerUI>,
L<YAML::PP>, L<Moo>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 by the Modern::OpenAPI::Generator authors. This library is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut
