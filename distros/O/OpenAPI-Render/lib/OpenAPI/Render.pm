package OpenAPI::Render;

use strict;
use warnings;

# ABSTRACT: Render OpenAPI specifications as documents
our $VERSION = '0.1.0'; # VERSION

sub new
{
    my( $class, $api ) = @_;

    my $self = { api => dereference( $api, $api ) };

    my( $base_url ) = map { $_->{url} } @{$api->{servers} };
    $self->{base_url} = $base_url if $base_url;

    return bless $self, $class;
}

sub show
{
    my( $self ) = @_;

    my $html = $self->header;

    my $api = $self->{api};

    for my $path (sort keys %{$api->{paths}}) {
        $html .= $self->path_header( $path );
        for my $operation ('get', 'post', 'patch', 'put', 'delete') {
            next if !$api->{paths}{$path}{$operation};
            my @parameters = (
                exists $api->{paths}{$path}{parameters}
                   ? @{$api->{paths}{$path}{parameters}} : (),
                exists $api->{paths}{$path}{$operation}{parameters}
                   ? @{$api->{paths}{$path}{$operation}{parameters}} : (),
                exists $api->{paths}{$path}{$operation}{requestBody}
                   ? RequestBody2Parameters( $api->{paths}{$path}{$operation}{requestBody} ) : (),
                );
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

sub header { return '' }
sub footer { return '' }
sub path_header { return '' }
sub operation_header { return '' }

sub parameters_header { return '' };
sub parameter { return '' }
sub parameters_footer { return '' };

sub responses_header { return '' };
sub response { return '' };
sub responses_footer { return '' };

sub operation_footer { return '' }

sub dereference
{
    my( $node, $root ) = @_;

    if( ref $node eq 'ARRAY' ) {
        @$node = map { dereference( $_, $root ) } @$node;
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
            %$node = map { $_ => dereference( $node->{$_}, $root ) } @keys;
        }
    }
    return $node;
}

sub RequestBody2Parameters
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
                      in          => 'query',
                      name        => $_,
                      schema      => $schema->{patternProperties}{$_},
                      _is_pattern => 1 } }
                 sort keys %{$schema->{patternProperties}} );
}

1;
