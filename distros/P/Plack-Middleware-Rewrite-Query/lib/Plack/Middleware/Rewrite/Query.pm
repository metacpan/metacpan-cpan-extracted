use strict;
package Plack::Middleware::Rewrite::Query;
#ABSTRACT: Safely modify the QUERY_STRING of a PSGI request
our $VERSION = '0.1.1'; #VERSION

use parent qw(Plack::Middleware Exporter);
use Plack::Util::Accessor qw(map modify);
use Plack::Request ();
use URI::Escape ();
use Hash::MultiValue;

our @EXPORT_OK = qw(rewrite_query query_string);

sub call {
    my ($self, $env) = @_;
    rewrite_query($env, modify => $self->modify, map => $self->map);
    $self->app->($env);
}

sub rewrite_query {
    my ($env, %config) = @_;

    my $query  = Plack::Request->new($env)->query_parameters;
    my $map    = $config{map};
    my $modify = $config{modify};

    if ($map) {
        my @keys   = $query->keys;
        my @values = $query->values;
        $query->clear;
        $query->merge_flat(
            map { $map->($keys[$_], $values[$_]) } 0 .. $#keys
        );

    }

    if ($modify) {
        map { $modify->($_) } $query; # alias $_ to $query
    }

    # rebuild QUERY_STRING
    $env->{QUERY_STRING} = query_string($query);

    # this has become invalid if it existed
    delete $env->{'plack.request.merged'};
}

sub query_string {
    my ($query) = @_;
    my @values = map { URI::Escape::uri_escape($_) } $query->values;
    join '&', map {
         $_ . '=' . shift @values
    } map { URI::Escape::uri_escape($_) } $query->keys;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Rewrite::Query - Safely modify the QUERY_STRING of a PSGI request

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

    builder {
        enable 'Rewrite::Query', 
            # rename all 'foo' paramaters to 'bar'
            map => sub {
                my ($key, $value) = @_;
                (($key eq 'foo' ? 'bar' : $key), $value);
            },
            # add a query parameter 'doz' with value '1'
            modify => sub {
                $_->add('doz', 1);
            };
        $app;
    };

    
    use Plack::Middleware::Rewrite::Query qw(rewrite_query);

    builder {
        # http://example.org/path/123 => http://example.org/path?id=123
        enable 'Rewrite', rules => sub {
            if ( s{/([0-9]+)$}{} ) {
                my $id = $1;
                rewrite_query( $_[0], modify => sub { $_->set('id',$id) } );
            }    
        };
        $app;
    };

=head1 DESCRIPTION

This L<Plack::Middleware> can be used to rewrite the QUERY_STRING of a L<PSGI>
request. Simpliy modifying QUERY_STRING won't alway work because
L<Plack::Request> stores query parameters at multiple places in a PSGI request.
This middleware takes care for cleanup, except the PSGI variable REQUEST_URI,
including the original query string, is not modified because it should not be
used by applications, anyway.

=head1 CONFIGURATION

=over

=item modify

Reference to a function that will be called with a L<Hash::MultiValue> 
containing the query parameters. The query is also aliased to C<$_> for easy 
manipulation.

=item map

Reference to a function that can be used to modify or remove key-value pairs.
If both, C<modify> and C<map> are set then C<map> is applied first.

=back

=head1 FUNCTIONS

The following functions can be exportet on request:

=head2 rewrite_query( $env [, modify => $sub ] [, map => $sub ] )

Functional interface to the core of this middleware to be used in different
context (see SYNOPSIS for an example). 

=head2 query_string( $multihash )

Returns a QUERY_STRING, given a L<Hash::MultiValue>. This includes URI escaping
all keys and values.

=head1 SEE ALSO

L<Plack::Middleware::Rewrite>

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
