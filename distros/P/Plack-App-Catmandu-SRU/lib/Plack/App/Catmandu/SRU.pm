package Plack::App::Catmandu::SRU;

our $VERSION = '0.02';

use Catmandu::Sane;
use Catmandu;
use Catmandu::Fix;
use Catmandu::Exporter::Template;
use URI;
use SRU::Request;
use SRU::Response;
use Types::Standard qw(Str ArrayRef HashRef ConsumerOf);
use Types::Common::String qw(NonEmptyStr);
use Types::Common::Numeric qw(PositiveInt);
use Moo;
use Plack::Request;
use namespace::clean;
use feature qw(signatures);
no warnings qw(experimental::signatures);

has store_name => (
    is => 'ro',
    isa => Str,
    init_arg => 'store',
);

has bag_name => (
    is => 'ro',
    isa => Str,
    init_arg => 'bag',
);

has content_type => (
    is => 'ro',
    isa => Str,
    default => sub { 'text/xml'; },
);

has cql_filter => (
    is => 'ro',
    isa => NonEmptyStr,
);

has default_record_schema => (
    is => 'ro',
    isa => NonEmptyStr,
    required => 1,
);

has record_schemas => (
    is => 'ro',
    isa => ArrayRef[HashRef],
    default => sub { []; },
);

has title => (
    is => 'ro',
    isa => NonEmptyStr,
);

has description => (
    is => 'ro',
    isa => NonEmptyStr,
);

has template_options => (
    is => 'ro',
    isa => HashRef,
    default => sub { +{}; },
);

has default_search_params => (
    is => 'ro',
    isa => HashRef,
    default => sub { {}; },
);

has limit => (
    is => 'lazy',
    isa => PositiveInt,
);

has maximum_limit => (
    is => 'lazy',
    isa => PositiveInt,
);

has bag => (
    is => 'lazy',
    isa => ConsumerOf['Catmandu::CQLSearchable'],
    init_arg => undef,
);

sub _build_bag ($self) {
    Catmandu->store($self->store_name)->bag($self->bag_name);
}

sub _build_limit ($self) {
    $self->bag->default_limit;
}

sub _build_maximum_limit ($self) {
    $self->bag->maximum_limit;
}

sub to_app ($self) {
    my $default_limit   = $self->limit;
    my $maximum_limit   = $self->maximum_limit;
    my $template_options= $self->template_options;
    my $bag = $self->bag;

    my $record_schema_map = {};
    for my $schema (@{$self->record_schemas}) {
        $schema = {%$schema};
        my $identifier = $schema->{identifier};
        my $name = $schema->{name};
        if (my $fix = $schema->{fix}) {
            $schema->{fix} = Catmandu::Fix->new(fixes => $fix);
        }
        $record_schema_map->{$identifier} = $schema;
        $record_schema_map->{$name} = $schema;
    }

    my $database_info = "";
    if ($self->title || $self->description) {
        $database_info .= qq(<databaseInfo>\n);
        for my $key (qw(title description)) {
            $database_info .= qq(<$key lang="en" primary="true">).$self->$key.qq(</$key>\n) if $self->$key;
        }
        $database_info .= qq(</databaseInfo>);
    }

    my $index_info = "";
    if (my $indexes = $bag->cql_mapping->{indexes}) {
        $index_info .= qq(<indexInfo>\n);
        for my $key (keys %$indexes) {
            my $title = $indexes->{$key}{title} || $key;
            $index_info .= qq(<index><title>$title</title><map><name>$key</name></map></index>\n);
        }
        $index_info .= qq(</indexInfo>);
    }

    my $schema_info = qq(<schemaInfo>\n);
    for my $schema (@{$self->record_schemas}) {
        my $title = $schema->{title} || $schema->{name};
        $schema_info .= qq(<schema name="$schema->{name}" identifier="$schema->{identifier}"><title>$title</title></schema>\n);
    }
    $schema_info .= qq(</schemaInfo>);

    my $config_info = qq(<configInfo>\n);
    $config_info .= qq(<default type="numberOfRecords">$default_limit</default>\n);
    $config_info .= qq(<setting type="maximumRecords">$maximum_limit</setting>\n);
    $config_info .= qq(</configInfo>);

    sub {
        my $env = $_[0];

        my $req = Plack::Request->new($env);

        return not_found() if $req->method() ne "GET";

        my $params      = $req->query_parameters();
        my $operation   = $params->get('operation') // 'explain';

        if ($operation eq 'explain') {
            my $request     = SRU::Request::Explain->new($params->flatten);
            my $response    = SRU::Response->newFromRequest($request);
            my $transport   = $req->scheme;
            my $uri         = URI->new($req->base().$req->request_uri);
            my $host        = $uri->host;
            my $port        = $uri->port;
            my $database    = (split(/\//o, $uri->path))[-1];
            $response->record(SRU::Response::Record->new(
                recordSchema => 'http://explain.z3950.org/dtd/2.0/',
                recordData   => <<XML,
<explain xmlns="http://explain.z3950.org/dtd/2.0/">
    <serverInfo protocol="SRU" transport="$transport">
    <host>$host</host>
    <port>$port</port>
    <database>$database</database>
    </serverInfo>
    $database_info
    $index_info
    $schema_info
    $config_info
</explain>
XML
            ));
            return $self->render_sru_response($response);
        }
        elsif ($operation eq 'searchRetrieve') {
            my $request  = SRU::Request::SearchRetrieve->new($params->flatten);
            my $response = SRU::Response->newFromRequest($request);
            if (@{$response->diagnostics}) {
                return $self->render_sru_response($response);
            }

            my $schema = $record_schema_map->{$request->recordSchema || $self->default_record_schema};
            unless ($schema) {
                $response->addDiagnostic(SRU::Response::Diagnostic->newFromCode(66));
                return $self->render_sru_response($response);
            }
            my $identifier  = $schema->{identifier};
            my $fix         = $schema->{fix};
            my $template    = $schema->{template};
            my $layout      = $schema->{layout};
            my $cql         = $params->get('query');
            if ($self->cql_filter) {
                # space before the filter is to circumvent a bug in the Solr
                # 3.6 edismax parser
                $cql = "( ".$self->cql_filter.") and ( $cql)";
            }

            my $first = $request->startRecord // 1;
            my $limit = $request->maximumRecords // $default_limit;
            if ($limit > $maximum_limit) {
                $limit = $maximum_limit;
            }

            my $hits = eval {
                $bag->search(
                    %{$self->default_search_params},
                    cql_query    => $cql,
                    sru_sortkeys => $request->sortKeys,
                    limit        => $limit,
                    start        => $first - 1,
                );
            } or do {
                my $e = $@;
                if (index($e, 'cql error') == 0) {
                    $response->addDiagnostic(SRU::Response::Diagnostic->newFromCode(10));
                    return $self->render_sru_response($response);
                }
                Catmandu::Error->throw($e);
            };

            $hits->each(sub {
                my $data     = $_[0];
                my $metadata = "";
                my $exporter = Catmandu::Exporter::Template->new(
                    %$template_options,
                    template => $template,
                    file     => \$metadata
                );
                $exporter->add($fix ? $fix->fix($data) : $data);
                $exporter->commit;
                $response->addRecord(SRU::Response::Record->new(
                    recordSchema => $identifier,
                    recordData   => $metadata,
                ));
            });
            $response->numberOfRecords($hits->total);
            return $self->render_sru_response($response);
        }
        else {
            my $request  = SRU::Request::Explain->new($params->flatten);
            my $response = SRU::Response->newFromRequest($request);
            $response->addDiagnostic(SRU::Response::Diagnostic->newFromCode(6));
            return $self->render_sru_response($response);
        }
    };
}

sub render_sru_response ($self, $response) {
    my $body = $response->asXML;
    utf8::encode($body);
    [200, ['Content-Type' => $self->content_type], [$body]];
}

sub not_found ($self) {
    [404, ['Content-Type' => 'text/plain'], ['not found']];
}

1;

=head1 NAME

Plack::App::Catmandu::SRU - drop in replacement for Dancer::Plugin::Catmandu::SRU

=head1 SYNOPSIS

    use Plack::Builder;
    Plack::App::Catmandu::SRU;

    builder {
        enable 'ReverseProxy';
        enable '+Dancer::Middleware::Rebase', base  => Catmandu->config->{uri_base}, strip => 1;
        mount "/sru" => Plack::App::Catmandu::SRU->new(
            store => 'search',
            bag   => 'publication',
            cql_filter => 'type = dataset',
            limit  => 100,
            maximum_limit => 500,
            record_schemas => [
                {
                    identifier => "info:srw/schema/1/mods-v3.6",
                    title => "MODS",
                    name => "mods_36",
                    template => "views/export/mods_36.tt",
                    fix => 'fixes/pub.fix'
                },
            ],
        )->to_app;
    };

=head1 CONSTRUCTOR ARGUMENTS

=over

=item store

Name of Catmandu store in your catmandu store configuration

Default: C<default>

=item bag

Name of Catmandu bag in your catmandu store configuration

Default: C<data>

This must be a bag that implements L<Catmandu::CQLSearchable>, and that configures a C<cql_mapping>

=item cql_filter

A CQL query to find all records in the database that should be made available to SRU

=item default_record_schema

default metadata schema all records are shown in, when SRU parameter C<recordSchema> is not gi en . Should be one listed in C<record_schemas>

=item limit

The default number of records to be returned in each SRU request, when SRU parameter C<maximumRecords> is not given during a searchRetrieve request.

When not provided in the constructor, it is derived from the default limit of your catmandu bag (see L<Catmandu::Searchable#default_limit>)

=item maximum_limit

The maximum value allowed for request parameter C<maximumRecords>.

When not provided in the constructor, it is derived from the maximum limit of your catmandu bag (see L<Catmandu::Searchable#maximum_limit>)

=item record_schemas

An array of all supported record schemas. Each item in the array is an object with attributes:

* identifier - The SRU identifier for the schema (see L<http://www.loc.gov/standards/sru/recordSchemas/>)

* name - A short descriptive name for the schema

* fix - Optionally an array of fixes to apply to the records before they are transformed into XML

* template - The path to a Template Toolkit file to transform your records into this format

=item template_options

An optional hash of configuration options that will be passed to L<Catmandu::Exporter::Template> or L<Template>

=item content_type

Set a custom content type header, the default is C<text/xml>.

=item title

Title shown in databaseInfo

=item description

Description shown in databaseInfo

=item default_search_params

Extra search parameters added during search in your catmandu bag:

    $bag->search(
        %{$self->default_search_params},
        cql_query    => $cql,
        sru_sortkeys => $request->sortKeys,
        limit        => $limit,
        start        => $first - 1,
    );

Must be a hash reference

Note that search parameter C<cql_query>, C<sru_sortkeys>, C<limit> and C<start> are overwritten

=back

As this is meant as a drop in replacement for L<Dancer::Plugin::Catmandu::SRU> all arguments should be the same.

So all arguments can be taken from your previous dancer plugin configuration, if necessary:

    use Dancer;
    use Catmandu;
    use Plack::Builder;
    use Plack::App::Catmandu::SRU;

    my $dancer_app = sub {
        Dancer->dance(Dancer::Request->new(env => $_[0]));
    };

    builder {
        enable 'ReverseProxy';
        enable '+Dancer::Middleware::Rebase', base  => Catmandu->config->{uri_base}, strip => 1;
    
        mount "/sru" => Plack::App::Catmandu::SRU->new(
            %{config->{plugins}->{'Catmandu::SRU'}}
        )->to_app;

        mount "/" => builder {
            # only create session cookies for dancer application
            enable "Session";
            mount '/' => $dancer_app;
        };
    };

=head1 METHODS

=over 4

=item to_app

returns Plack application that can be mounted. Path rebasements are taken into account

=back

=head1 AUTHOR

=over 4
    
=item Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=back
    
=head1 IMPORTANT

This module is still a work in progress, and needs further testing before using it in a production system

=head1 LICENSE AND COPYRIGHT
    
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
