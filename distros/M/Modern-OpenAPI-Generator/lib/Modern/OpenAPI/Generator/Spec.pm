package Modern::OpenAPI::Generator::Spec;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Path::Tiny qw(path);
use Storable qw(dclone);

sub load {
    my ( $class, $file ) = @_;
    my $p = path($file);
    croak "Spec not found: $file" unless $p->is_file;

    my $data;
    if ( $p =~ /\.json\z/i ) {
        require JSON::MaybeXS;
        $data = JSON::MaybeXS::decode_json( $p->slurp_utf8 );
    }
    else {
        require YAML::PP;
        $data = YAML::PP->new( boolean => 'JSON::PP' )->load_file("$p");
    }
    croak 'Spec must be a hash' unless ref $data eq 'HASH';

    bless {
        raw  => $data,
        path => "$p",
    }, $class;
}

sub raw { $_[0]{raw} }

# Deep-clone spec and set x-mojo-to => "Controller#operationId" for Mojolicious::Plugin::OpenAPI
sub clone_with_mojo_to {
    my ( $self, $controller_short ) = @_;
    my $copy = dclone( $self->{raw} );
    my $paths = $copy->{paths} // return $copy;
    for my $p ( keys %$paths ) {
        my $item = $paths->{$p};
        next unless ref $item eq 'HASH';
        for my $m (qw(get put post delete patch options head trace)) {
            my $op = $item->{$m};
            next unless ref $op eq 'HASH';
            my $oid = $op->{operationId} or next;
            ( my $sub = $oid ) =~ s/[^A-Za-z0-9_]/_/g;
            $op->{'x-mojo-to'} = "$controller_short#$sub";
        }
    }
    return $copy;
}

sub openapi_version {
    my ($self) = @_;
    return $self->{raw}{openapi} // $self->{raw}{swagger} // '';
}

sub title {
    my ($self) = @_;
    return $self->{raw}{info}{title} // 'API';
}

# Returns list of hashrefs:
# operation_id, method, path, path_params, query_params, header_params,
# has_body, tags, operation_hash,
# response_schema_ref (e.g. #/components/schemas/Foo), response_is_array
sub operations {
    my ($self) = @_;
    my $paths = $self->{raw}{paths} // {};
    my @ops;
    for my $path ( sort keys %$paths ) {
        my $item = $paths->{$path};
        next unless ref $item eq 'HASH';
        my $path_level = $item->{parameters};
        for my $method (qw(get put post delete patch options head trace)) {
            my $op = $item->{$method};
            next unless ref $op eq 'HASH';
            my $oid = $op->{operationId} // _default_operation_id( $method, $path );
            my $merged = _merge_parameters( $path_level, $op->{parameters} );
            my ( $ref, $is_arr ) = _success_response_json_ref($op);
            push @ops,
              {
                operation_id   => $oid,
                method         => uc $method,
                path           => $path,
                path_params    => _params_in( $merged, 'path' ),
                query_params   => _params_in( $merged, 'query' ),
                header_params  => _params_in( $merged, 'header' ),
                has_body       => _has_json_body($op),
                tags           => $op->{tags} // [],
                operation_hash => $op,
                response_schema_ref => $ref,
                response_is_array   => $is_arr,
              };
        }
    }
    return \@ops;
}

# First 2xx response with application/json and a concrete schema $ref (object or array of $ref).
sub _success_response_json_ref {
    my ($op) = @_;
    my $responses = $op->{responses} // {};
    for my $code (qw(200 201 202 204)) {
        next unless exists $responses->{$code};
        my $content = $responses->{$code}{content} // {};
        for my $ct (qw(application/json application/problem+json)) {
            next unless exists $content->{$ct};
            my $sch = $content->{$ct}{schema};
            next unless ref $sch eq 'HASH';
            if ( my $r = $sch->{'$ref'} ) {
                return ( $r, 0 );
            }
            if ( ( $sch->{type} // '' ) eq 'array' && ref $sch->{items} eq 'HASH' ) {
                my $it = $sch->{items};
                if ( my $r = $it->{'$ref'} ) {
                    return ( $r, 1 );
                }
            }
        }
    }
    return ( undef, 0 );
}

sub _has_json_body {
    my ($op) = @_;
    my $rb = $op->{requestBody} // return 0;
    return 0 unless ref $rb eq 'HASH';
    my $c = $rb->{content} // {};
    return !!( $c->{'application/json'} );
}

sub _merge_parameters {
    my ( $a, $b ) = @_;
    my @m;
    push @m, @$a if ref $a eq 'ARRAY';
    push @m, @$b if ref $b eq 'ARRAY';
    return \@m;
}

sub _params_in {
    my ( $params, $in ) = @_;
    return [] unless ref $params eq 'ARRAY';
    my @names;
    for my $p (@$params) {
        next unless ref $p eq 'HASH';
        next unless ( $p->{in} // '' ) eq $in;
        push @names, $p->{name} if defined $p->{name};
    }
    return \@names;
}

sub _default_operation_id {
    my ( $m, $path ) = @_;
    ( my $s = $path ) =~ s{[^A-Za-z0-9]+}{_}g;
    return uc($m) . '_' . $s;
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator::Spec - Parsed OpenAPI document (YAML/JSON)

=head1 DESCRIPTION

Object holds the decoded spec in C<< $spec->raw >> and answers questions about
operations and metadata.

=head2 load

Class method. Reads a YAML or JSON OpenAPI file and returns a blessed instance.

=head2 raw

Accessor for the root hash reference of the document.

=head2 clone_with_mojo_to

Returns a deep-cloned hash with C<x-mojo-to> set on each operation for
L<Mojolicious::Plugin::OpenAPI>.

=head2 openapi_version

Returns the C<openapi> or C<swagger> version string from the document.

=head2 title

Returns C<info.title> or the string C<API>.

=head2 operations

Returns an arrayref of operation hashrefs (method, path, C<operationId>,
parameters, response schema hints, etc.).

=cut
