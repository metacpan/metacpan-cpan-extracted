package OpenAPI::PerlGenerator::Template::Mojo 0.02;
use 5.020;

=head1 NAME

OpenAPI::PerlGenerator::Template::Mojo - Mojolicious templates for OpenAPI clients

=head1 SYNOPSIS

  # override the 'foo' template
  $OpenAPI::PerlGenerator::Template::Mojo::template{'foo'} = <<__MY_TEMPLATE__;
  bar
  __MY_TEMPLATE__

=cut

our %template;

$template{required_parameters} = <<'__REQUIRED_PARAMETERS__';
%# Check that we received all required parameters:
% if( my $p = $elt->{parameters}) {
%     my @required = grep { $_->{required} } $elt->{parameters}->@*;
%     if( @required ) {
%         for my $p (@required) {
    croak "Missing required parameter '<%= $p->{name} %>'"
        unless exists $options{ '<%= $p->{name} %>' };
%         }

%     }
% } # parameter-required
__REQUIRED_PARAMETERS__

$template{path_parameters} = <<'__PATH_PARAMETERS__';
    my $template = URI::Template->new( '<%= $method->{path} %>' );
    my $path = $template->process(
%     for my $p ($params->@*) {
%         if( $p->{required} ) {
              '<%= $p->{name} %>' => delete $options{'<%= $p->{name} %>'},
%         } else {
        maybe '<%= $p->{name} %>' => delete $options{'<%= $p->{name} %>'},
%         }
%     }
    );
__PATH_PARAMETERS__

$template{generate_request_body} = <<'__REQUEST_BODY__';
%     for my $ct (sort keys $content->%*) {
%         if( exists $content->{$ct}->{schema}) {
%             if( $content->{$ct}->{schema}->{type} eq 'string' ) {
    my $body = delete $options{ body } // '';
%             } else {
    my $request = <%= $prefix %>::<%= $content->{$ct}->{schema}->{name} %>->new( \%options );
%             }
%         } elsif( $ct eq 'multipart/form-data' ) {
%             # nothing to do
%         } else {
              # don't know how to handle content type <%= $ct %>...
%         }
%     }
__REQUEST_BODY__

$template{inflated_response} = <<'__INFLATED_RESPONSE__';
% if( $type->{name} ) {
<%= $prefix %>::<%= $type->{name} %>->new(<%= $argname %>),
% } elsif( $type->{type} and $type->{type} eq 'array') {
%# use Data::Dumper; warn Dumper $type;
[ map { <%= include('inflated_response', { type => $type->{items}, prefix => $prefix, argname => '$_' }) %> } $payload->@* ],
% } else {
<%= $argname %>
% }
__INFLATED_RESPONSE__

$template{streaming_response} = <<'__STREAMING_RESPONSE__';
    use Future::Queue;
    my $res = Future::Queue->new( prototype => 'Future::Mojo' );
    our @store; # we should use ->retain() instead
    push @store, $r1->then( sub( $tx ) {
        my $resp = $tx->res;
        # Should we validate using OpenAPI::Modern here?!
%# Should this be its own subroutine instead?!
% for my $code (sort keys $elt->{responses}->%*) {                             # response code s
%     my $info = $elt->{responses}->{ $code };
%# XXX if streaming, we need to handle a non-streaming error response!
        <%= elsif_chain($name) %>( $resp->code <%= openapi_http_code_match( $code ) %> ) {
%     if( $info->{description} =~ /\S/ ) {
            # <%= single_line( $info->{description} ) %>
%     }
%       # Check the content type
%       # Will we always have a content type?!
%       if( keys $info->{content}->%* ) {
%           for my $ct (sort keys $info->{content}->%*) {
            my $ct = $resp->headers->content_type;
            return unless $ct;
            $ct =~ s/;\s+.*//;
            if( $ct eq '<%= $ct %>' ) {
                # we only handle ndjson currently
                my $handled_offset = 0;
                $resp->on(progress => sub($msg,@) {
                    my $fresh = substr( $msg->body, $handled_offset );
                    my $body = $msg->body;
                    $body =~ s/[^\r\n]+\z//; # Strip any unfinished line
                    $handled_offset = length $body;
                    my @lines = split /\n/, $fresh;
                    for (@lines) {
                        my $payload = decode_json( $_ );
                        $res->push(
% my $type = $info->{content}->{$ct}->{schema};
                            <%= include('inflated_response', { type => $type, prefix => $prefix, argname => '$payload' } ) %>
                        );
                    };
                    if( $msg->{state} eq 'finished' ) {
                        $res->finish();
                    }
                });
            }
%           }
%           } else { # we don't know how to handle this, so pass $res          # known content types?
%# XXX should we always use ->done or should we use ->fail for 4xx and 5xx ?!
            return Future::Mojo->done($resp);
%           }
% }
        } else {
            # An unknown/unhandled response, likely an error
            return Future::Mojo->fail($resp);
        }
    });

    my $_tx;
    $tx->res->once( progress => sub($msg, @) {
        $r1->resolve( $tx );
        undef $_tx;
        undef $r1;
    });
    $_tx = $self->ua->start_p($tx);
__STREAMING_RESPONSE__

$template{synchronous_response} = <<'__SYNCHRONOUS_RESPONSE__';
    my $res = $r1->then( sub( $tx ) {
        my $resp = $tx->res;
        # Should we validate using OpenAPI::Modern here?!
%# Should this be its own subroutine instead?!
% my $first_code = 1;
% for my $code (sort keys $elt->{responses}->%*) {                             # response code s
%     my $info = $elt->{responses}->{ $code };
        <%= elsif_chain($name) %>( $resp->code <%= openapi_http_code_match( $code ) %> ) {
%     if( $info->{description} =~ /\S/ ) {
            # <%= single_line( $info->{description} ) %>
%     }
%       # Check the content type
%       # Will we always have a content type?!
%       if( keys $info->{content}->%* ) {
%           for my $ct (sort keys $info->{content}->%*) {
            my $ct = $resp->headers->content_type;
            $ct =~ s/;\s+.*//;
            if( $ct eq '<%= $ct %>' ) {
%# These handlers for content types should come from templates? Or maybe
%# from a subroutine?!
%               if( $ct eq 'application/json' ) {
                my $payload = $resp->json();
%               } elsif( $ct eq 'application/x-ndjson' ) {
                # code missing to hack up ndjson into hashes for a non-streaming response
                my $payload = $resp->body();
%               } else {
                my $payload = $resp->body();
%               }
                return Future::Mojo->done(
% my $type = $info->{content}->{$ct}->{schema};
                    <%= include('inflated_response', { type => $type, prefix => $prefix, argname => '$payload' } ) %>
                );
            }
%           }
%           } else { # we don't know how to handle this, so pass $res          # known content types?
            return Future::Mojo->done($resp);
%           }
% }
        } else {
            # An unknown/unhandled response, likely an error
            return Future::Mojo->fail($resp);
        }
    });

    # Start our transaction
    $tx = $self->ua->start_p($tx)->then(sub($tx) {
        $r1->resolve( $tx );
        undef $r1;
    })->catch(sub($err) {
        $r1->fail( $err => $tx );
        undef $r1;
    });
__SYNCHRONOUS_RESPONSE__

$template{object} = <<'__OBJECT__';
% my @subclasses;
% my @included_types;
% if( exists $elt->{allOf}) {
%     for my $item ($elt->{allOf}->@*) {
%         if( $item->{name} ) {
%             push @subclasses, $item;
%         } else {
%             push @included_types, $item;
%         }
%     }
% } else {
%     push @included_types, $elt;
% }
%
package <%= $prefix %>::<%= $name %> 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

<%= $prefix %>::<%= $name %> -

=head1 SYNOPSIS

  my $obj = <%= $prefix %>::<%= $name %>->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

% if( @subclasses ) {
%     for my $item (@subclasses) {
extends '<%= $prefix %>::<%= $item->{name} %>';
%     }

% }
=head1 PROPERTIES

% for my $t (@included_types) {
%     for my $prop (sort keys $t->{properties}->%*) {
%         my $p = $t->{properties}->{$prop};
=head2 C<< <%= property_name( $prop ) %> >>

% if( $p->{description} and $p->{description} =~ /\S/ ) {
<%= $p->{description} =~ s/\s*$//r %>

% }
=cut

has '<%= property_name( $prop ) %>' => (
    is       => 'ro',
% my $type = map_type( $p );
% if( $type ) {
    isa      => <%= $type %>,
% };
% if( grep {$_ eq $prop} $elt->{required}->@*) {
    required => 1,
% }
);

%     }
% }

1;
__OBJECT__

$template{return_types} = <<'__RETURN_TYPES__';
% for my $code (sort keys $elt->{responses}->%*) {
%     my $info = $elt->{responses}->{ $code };
%        if( my $content = $info->{content} ) {
%            for my $ct (sort keys $content->%*) {
%                if( $content->{$ct}->{schema}) {
%                    my $descriptor = 'a';
%                    my $class;
%                    if( $content->{$ct}->{schema}->{type} and $content->{$ct}->{schema}->{type} eq 'array' ) {
%                        $descriptor = 'an array of';
%                        $class = join "::", $prefix, $content->{$ct}->{schema}->{items}->{name};
%                    } elsif( $content->{$ct}->{schema}->{name}) {
%                        $class = join "::", $prefix, $content->{$ct}->{schema}->{name};
%                    } else {
%                        $class = $content->{$ct}->{schema}->{type};
%                    }
Returns <%= $descriptor %> L<< <%= $class %> >>.
%                }
%             }
%         }
%     }
__RETURN_TYPES__

$template{ build_request } = <<'__BUILD_REQUEST__';
sub _build_<%= $method->{name} %>_request( $self, %options ) {
<%= include( 'required_parameters', { elt => $elt }); =%>
%#
    my $method = '<%= uc $method->{http_method} %>';
%# Output the path parameters
% if( my $params = delete $parameters->{ path }) {
<%= include( 'path_parameters', { method => $method, params => $params }); =%>
% } else {
    my $path = '<%= $method->{path} %>';
% } # path parameters
    my $url = Mojo::URL->new( $self->server . $path );

%#------
%# Generate the (URL) parameters
%# This must happen before the remaining options are passed into an object
%# Output the query parameters
% if( my $params = delete $parameters->{ query }) {
    $url->query->merge(
%     for my $p ($params->@*) {
%         if( $p->{required} ) {
              '<%= $p->{name} %>' => delete $options{'<%= $p->{name} %>'},
%         } else {
        maybe '<%= $p->{name} %>' => delete $options{'<%= $p->{name} %>'},
%         }
%     }
    );

% };
%#------
%# Generate the header parameters
% my $custom_headers;
% if( my $params = delete $parameters->{ header }) {                             # header parameters
%     $custom_headers = [];
%     for my $p ($params->@*) {
%         if( $p->{required} ) {
%             push @$custom_headers, qq{      '$p->{name}' => delete \$options{'$p->{name}'}};
%         } else {
%             push @$custom_headers, qq{maybe '$p->{name}' => delete \$options{'$p->{name}'}};
%         }
%     }
% };                                                                           # header parameters
%#------
%# Output any parameter locations we didn't handle as comment
% for (sort keys $parameters->%* ) {
%     for my $p ($parameters->{$_}->@*) {
    # unhandled <%= $p->{in} %> parameter <%= $p->{name} %>;
%     }
% }                         # parameter-in
%
% my $is_json;
% my $content_type;
% my $has_body = exists $elt->{requestBody};
% if( $has_body ) {
%#    We assume we will only ever have one content type for the request we send:
%     ($content_type) = sort keys $elt->{requestBody}->{content}->%*;
%     $is_json = $ct && $ct eq 'application/json';
<%= include('generate_request_body', {
        content => $elt->{requestBody}->{content},
        prefix => $prefix,
        is_json => $is_json,
    } ); =%>
% }
%
    my $tx = $self->ua->build_tx(
        $method => $url,
        {
% my $known_response_types = join ",", openapi_response_content_types($elt);
% if( $known_response_types ) {
            'Accept' => '<%= $known_response_types %>',
% }
% if( $content_type ) {
            "Content-Type" => '<%= $content_type %>',
% }
% if( $custom_headers ) {
%     for my $h (@$custom_headers) {
             <%= $h %>
%     }
% }
%#------
%# Generate the header parameters
% if( my $params = delete $parameters->{ header }) {                             # header parameters
%     for my $p ($params->@*) {
%         if( $p->{required} ) {
              '<%= $p->{name} %>' => delete $options{'<%= $p->{name} %>'},
%         } else {
        maybe '<%= $p->{name} %>' => delete $options{'<%= $p->{name} %>'},
%         }
%     }
% };                                                                           # header parameters
        }
% if( ! $has_body ) {
%# nothing to do
% } elsif( $is_json ) {
        => json => $request->as_hash,
% } elsif( $content_type and $content_type eq 'multipart/form-data' ) {
        => form => $request->as_hash,
% } elsif( $content_type and $content_type eq 'application/octet-stream' ) {
        => $body,
% } else {
        # XXX Need to fill the body
        # => $body,
% }
    );

    return $tx
}
__BUILD_REQUEST__

$template{client_implementation} = <<'__CLIENT_IMPLEMENTATION__';
package <%= $prefix %>::<%= $name %> 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use PerlX::Maybe;
use Carp 'croak';

# These should go into a ::Role
use YAML::PP;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::JSON 'encode_json', 'decode_json';
use OpenAPI::Modern;

use Future::Mojo;

% my @submodules = openapi_submodules($schema);
% while (my($submodule,$info) = splice( @submodules, 0, 2 )) {
%     if( $info->{type} and $info->{type} eq 'object' ) {
use <%= $prefix %>::<%= $submodule %>;
%     }
% }

=head1 SYNOPSIS

=head1 PROPERTIES

=head2 B<< openapi >>

=head2 B<< ua >>

=head2 B<< server >>

=cut

# XXX this should be more configurable, and potentially you don't want validation?!
has 'schema' => (
    is => 'lazy',
    default => sub {
        YAML::PP->new( boolean => 'JSON::PP' )->load_file( 'ollama/ollama-curated.yaml' );
    },
);

has 'openapi' => (
    is => 'lazy',
    default => sub { OpenAPI::Modern->new( openapi_schema => $_[0]->schema, openapi_uri => '/api' )},
);

# The HTTP stuff should go into a ::Role I guess
has 'ua' => (
    is => 'lazy',
    default => sub { Mojo::UserAgent->new },
);

has 'server' => (
    is => 'lazy',
    default => sub { 'http://localhost:11434/api' }, # XXX pull from OpenAPI file instead
);

=head1 METHODS

% for my $method ($methods->@*) {
% my $elt = $method->{elt};
% my $is_streaming =    exists $elt->{responses}->{200}
%                    && $elt->{responses}->{200}->{content}
%                    && [keys $elt->{responses}->{200}->{content}->%*]->[0] eq 'application/x-ndjson'
%                    ;
%
%# Sort the parameters according to where they go
% my %parameters;
% if( my $p = $elt->{parameters}) {
%     for my $p ($elt->{parameters}->@*) {
%         $parameters{ $p->{in} } //= [];
%         push $parameters{ $p->{in} }->@*, $p;
%     }
% }
%
=head2 C<< <%= $method->{name} %> >>

%# Generate the example invocation
% if( $is_streaming ) {
  use Future::Utils 'repeat';
  my $responses = $client-><%= $method->{name} %>();
  repeat {
      my ($res) = $responses->shift;
      if( $res ) {
          my $str = $res->get;
          say $str;
      }

      Future::Mojo->done( defined $res );
  } until => sub($done) { $done->get };
% } else {
  my $res = $client-><%= $method->{name} %>()->get;
% }

% if( $elt->{summary}  and $elt->{summary} =~ /\S/ ) {
<%= markdown_to_pod( $elt->{summary} =~ s/\s*$//r ) %>

%}
%# List/add the invocation parameters
% my $parameters = $elt->{parameters};
% if( $parameters ) { # parameters
=head3 Parameters

=over 4

%     for my $p ($parameters->@* ) {
=item B<< <%= $p->{name} %> >>

%     if( $p->{description} =~ /\S/ ) {
<%= markdown_to_pod( $p->{description} =~ s/\s*$//r ) %>

%     }
%     if( $p->{default}) {
Defaults to C<< <%= $p->{default} =%> >>

%         }
%     }
=back

% } # parameters
%#
%# Add the body/schema parameters:
% (my $ct) = exists $elt->{requestBody} ? keys $elt->{requestBody}->{content}->%* : ();
% my $type;
% if( $ct ) {
%     $type = $ct && $elt->{requestBody}->{content}->{$ct}->{schema};
% };
% if( $type ) {
%     my @properties = (sort keys $type->{properties}->%*);
%     if( @properties ) {

=head3 Options

=over 4

%         for my $prop (@properties) {
%             my $p = $type->{properties}->{$prop};
=item C<< <%= property_name( $prop ) %> >>

% if( $p->{description} ) {
<%= markdown_to_pod( $p->{description} =~ s/\s*$//r ) %>

% }
%         }
=back
%     }
% }

%=include('return_types', { prefix => $prefix, elt => $elt });
=cut

<%= include( 'build_request', { method => $method, parameters => \%parameters, elt => $elt, ct => $ct, prefix => $prefix, } ); %>

sub <%= $method->{name} %>( $self, %options ) {
    my $tx = $self->_build_<%= $method->{name} %>_request(%options);

    # validate our request while developing
    my $results = $self->openapi->validate_request($tx->req);
    if( $results->{error}) {
        say $results;
        say $tx->req->to_string;
    };

%# We want to handle both here, streaming (ndjson) and plain responses
%# Plain responses are easy, but for streamed, we want to register an ->on('progress')
%# handler instead of the plain part completely. In the ->on('progress') part,
%# we still run the handler, so maybe that is the same ?!

    my $r1 = Future::Mojo->new();
% if( $is_streaming ) {
<%= include('streaming_response', {
         name => $method->{name},
         elt => $elt,
         prefix => $prefix,
          }); =%>
% } else {
<%= include('synchronous_response', {
         name => $method->{name},
         elt => $elt,
         prefix => $prefix,
         });
=%>
% }

    return $res
}

% }

1;
__CLIENT_IMPLEMENTATION__

$template{client} = <<'__CLIENT__';
package <%= $prefix %>::<%= $name %> 0.01;
use 5.020;
use Moo 2;
use experimental 'signatures';

extends '<%= $prefix %>::<%= $name %>::Impl';

=head1 NAME

<%= $prefix %>::<%= $name %> - Client for <%= $prefix %>

=head1 SYNOPSIS

  use 5.020;
  use <%= $prefix %>::<%= $name %>;

  my $client = <%= $prefix %>::<%= $name %>->new(
      server => '<%= $schema->{servers}->[0]->{url} // "https://example.com/" %>',
  );
  my $res = $client->someMethod()->get;
  say $res;

=head1 METHODS

% for my $method ($methods->@*) {
% my $elt = $method->{elt};
=head2 C<< <%= $method->{name} %> >>

  my $res = $client-><%= $method->{name} %>()->get;

% if( $elt->{summary} and $elt->{summary} =~ /\S/ ) {
<%= $elt->{summary} =~ s/\s*$//r; %>

%}
%=include('return_types', { prefix => $prefix, elt => $elt });
=cut

% }
1;
__CLIENT__

1;

__END__

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/OpenAPI-PerlGenerator>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/OpenAPI-PerlGenerator/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2024- by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the Artistic License 2.0.

=cut
