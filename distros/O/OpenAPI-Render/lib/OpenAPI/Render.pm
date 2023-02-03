package OpenAPI::Render;

use strict;
use warnings;

use Clone qw( clone );
use JSON qw( decode_json );
use version;

# ABSTRACT: Render OpenAPI specifications as documents
our $VERSION = '0.3.0'; # VERSION

=head1 DESCRIPTION

C<OpenAPI::Render> is a class meant to be subclassed and used to render OpenAPI specifications.
Currently OpenAPI version 3.0.2 is the target version, but in principle all 3.* versions should work.
C<OpenAPI::Render> provides methods for representing OpenAPI definitions such as operations and parameters, and the base class performs the required traversal.
Thus it should be enough to subclass it and override the appropriate methods.
For examples see L<OpenAPI::Render::HTMLForms> and L<OpenAPI::Render::reStructuredText>.

=head1 MAIN METHODS

=head2 C<new( $openapi )>

Given an OpenAPI specification in raw JSON or parsed data structure, constructs a C<OpenAPI::Render> object.
Does not modify input values.

=cut

sub new
{
    my( $class, $api ) = @_;

    if( ref $api ) {
        # Parsed JSON given, need to make a copy as dereferencing will modify it.
        $api = clone $api;
    } else {
        # Raw JSON given, need to parse.
        $api = decode_json $api;
    }

    my $self = { api => _dereference( $api, $api ) };

    if( exists $self->{api}{openapi} ) {
        my $version = version->parse( $self->{api}{openapi} );
        if( $version < version->parse( '3' ) || $version > version->parse( '4' ) ) {
            warn "unsupported OpenAPI version $self->{api}{openapi}, " .
                 'results may be incorrect', "\n";
        }
    } else {
        warn 'top-level attribute "openapi" not found, cannot ensure ' .
             'this is OpenAPI, cannot check version', "\n";
    }

    my( $base_url ) = map { $_->{url} } @{$api->{servers} };
    $self->{base_url} = $base_url if $base_url;

    return bless $self, $class;
}

=head2 C<show()>

Main generating method (does not take any parameters).
Returns a string with rendered representation of an OpenAPI specification.

=cut

sub show
{
    my( $self ) = @_;

    my $html = $self->header;
    my $api = $self->api;

    for my $path (sort keys %{$api->{paths}}) {
        $html .= $self->path_header( $path );
        for my $operation ('get', 'post', 'patch', 'put', 'delete') {
            next if !$api->{paths}{$path}{$operation};
            my @parameters = $self->parameters( $path, $operation );
            my $responses = $api->{paths}{$path}{$operation}{responses};

            $html .= $self->operation_header( $path, $operation ) .

                     $self->parameters_header .
                     join( '', map { $self->parameter( $_ ) } @parameters ) .
                     $self->parameters_footer .

                     $self->responses_header .
                     join( '', map { $self->response( $_, $responses->{$_} ) }
                                   sort keys %$responses ) .
                     $self->responses_footer .

                     $self->operation_footer( $path, $operation );
        }
    }

    $html .= $self->footer;
    return $html;
}

=head1 RENDERING METHODS

=head2 C<header()>

Text added before everything else.
Empty in the base class.

=cut

sub header { return '' }

=head2 C<footer()>

Text added after everything else.
Empty in the base class.

=cut

sub footer { return '' }

=head2 C<path_header( $path )>

Text added before each path.
Empty in the base class.

=cut

sub path_header { return '' }

=head2 C<operation_header( $path, $operation )>

Text added before each operation.
Empty in the base class.

=cut

sub operation_header { return '' }

=head2 C<parameters_header()>

Text added before parameters list.
Empty in the base class.

=cut

sub parameters_header { return '' };

=head2 C<parameter( $parameter )>

Returns representation of a single parameter.
Empty in the base class.

=cut

sub parameter { return '' }

=head2 C<parameters_footer()>

Text added after parameters list.
Empty in the base class.

=cut

sub parameters_footer { return '' };

=head2 C<responses_header()>

Text added before responses list.
Empty in the base class.

=cut

sub responses_header { return '' };

=head2 C<response( $response )>

Returns representation of a single response.
Empty in the base class.

=cut

sub response { return '' };

=head2 C<responses_footer()>

Text added after responses list.
Empty in the base class.

=cut

sub responses_footer { return '' };

=head2 C<operation_footer( $path, $operation )>

Text added after each operation.
Empty in the base class.

=cut

sub operation_footer { return '' }

=head1 HELPER METHODS

=head2 C<api()>

Returns the parsed and dereferenced input OpenAPI specification.
Note that in the returned data structure all references are dereferenced, i.e., flat.

=cut

sub api
{
    my( $self ) = @_;
    return $self->{api};
}

=head2 C<parameters( $path, $operation )>

Returns the list of parameters.
Optionally, path and operation can be given to filter the parameters.
Note that object-typed schemas from C<multipart/form-data> are translated to parameters too.

=cut

sub parameters
{
    my( $self, $path_filter, $operation_filter ) = @_;

    my $api = $self->api;

    my @parameters;
    for my $path (sort keys %{$api->{paths}}) {
        next if $path_filter && $path ne $path_filter;
        for my $operation ('get', 'post', 'patch', 'put', 'delete') {
            next if $operation_filter && $operation ne $operation_filter;
            next if !$api->{paths}{$path}{$operation};

            if( exists $api->{paths}{$path}{parameters} ) {
                push @parameters, @{$api->{paths}{$path}{parameters}};
            }

            if( exists $api->{paths}{$path}{$operation}{parameters} ) {
                push @parameters, @{$api->{paths}{$path}{$operation}{parameters}};
            }

            if( exists $api->{paths}{$path}{$operation}{requestBody} ) {
                push @parameters,
                     _RequestBody2Parameters( $api->{paths}{$path}{$operation}{requestBody} );
            }
        }
    }

    return @parameters;
}

sub _dereference
{
    my( $node, $root ) = @_;

    if( ref $node eq 'ARRAY' ) {
        @$node = map { _dereference( $_, $root ) } @$node;
    } elsif( ref $node eq 'HASH' ) {
        my @keys = keys %$node;
        if( scalar @keys == 1 && $keys[0] eq '$ref' ) {
            my @path = split '/', $node->{'$ref'};
            shift @path;
            $node = $root;
            while( @path ) {
                $node = $node->{shift @path};
            }
        } else {
            %$node = map { $_ => _dereference( $node->{$_}, $root ) } @keys;
        }
    }
    return $node;
}

sub _RequestBody2Parameters
{
    my( $requestBody ) = @_;

    return if !exists $requestBody->{content} ||
              !exists $requestBody->{content}{'multipart/form-data'} ||
              !exists $requestBody->{content}{'multipart/form-data'}{schema};

    my $schema = $requestBody->{content}{'multipart/form-data'}{schema};

    return if $schema->{type} ne 'object';
    return ( map { {
                      in     => 'query',
                      name   => $_,
                      schema => $schema->{properties}{$_} } }
                 sort keys %{$schema->{properties}} ),
           ( map { {
                      in             => 'query',
                      name           => $_,
                      schema         => $schema->{patternProperties}{$_},
                      'x-is-pattern' => 1 } }
                 sort keys %{$schema->{patternProperties}} );
}

1;
