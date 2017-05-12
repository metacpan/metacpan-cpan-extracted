## no critic (RequireUseStrict)
package Plack::Middleware::SetAccept;
BEGIN {
  $Plack::Middleware::SetAccept::VERSION = '0.01';
}

## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Plack::Middleware';

use Carp;
use List::MoreUtils qw(any);
use URI;
use URI::QueryParam;

sub prepare_app {
    my ( $self ) = @_;

    my ( $from, $mapping, $param ) = @{$self}{qw/from mapping param/};

    unless($from) {
        croak "'from' parameter is required";
    }
    unless($mapping) {
        croak "'mapping' parameter is required";
    }
    $from = [ $from ] unless ref($from);
    unless(@$from) {
        croak "'from' parameter cannot be an empty array reference";
    }
    if(my ( $bad ) = grep { $_ ne 'suffix' && $_ ne 'param' } @$from) {
        croak "'$bad' is not a valid value for the 'from' parameter";
    }
    if(grep { $_ eq 'param' } @$from) {
        unless($param) {
            croak "'param' parameter is required when using 'param' for from";
        }
    }
    unless(exists $self->{'tolerant'}) {
        $self->{'tolerant'} = 1;
    }

    unless(ref($mapping) eq 'HASH') {
        croak "'mapping' parameter must be a hash reference";
    }
}

sub get_uri {
    my ( $self, $env ) = @_;

    my $host;
    unless($host = $env->{'HTTP_HOST'}) {
        $host = $env->{'SERVER_NAME'};
        unless($env->{'SERVER_PORT'} == 80) {
            $host .= ':' . $env->{'SERVER_PORT'};
        }
    }

    return URI->new(
        $env->{'psgi.url_scheme'} . '://' .
        $host .
        $env->{'REQUEST_URI'}
    );
}

sub extract_format {
    my ( $self, $env ) = @_;

    my @format;
    my $from = $self->{'from'};

    $from = [ $from ] unless ref $from;

    my @reasons;

    my $uri = $self->get_uri($env);
    foreach (@$from) {
        if($_ eq 'suffix') {
            my $path = $uri->path;

            if($path =~ /\.([^.]+)$/) {
                push @format, $1;
                $path = $`;
                $uri->path($path);
                push @reasons, 'suffix';
            }
        } elsif($_ eq 'param') {
            my @values = $uri->query_param_delete($self->{'param'});
            if(@values) {
                push @format, @values;
                push @reasons, 'param';
            }
        }
    }
    if(@reasons) { # if there has been any modification
        $env->{'PATH_INFO'}    = $uri->path;
        $env->{'REQUEST_URI'}  = $uri->path_query;
        $env->{'QUERY_STRING'} = $uri->query;
    }
    return ( \@format, \@reasons );
}

sub acceptable {
    my ( $self, $accept ) = @_;

    my %acceptable = map { s/;.*$//; $_ => 1 } split /\s*,\s*/, $accept;
    return grep { $acceptable{$_} } values %{ $self->{'mapping'} };
}

sub unacceptable {
    my ( $self, $env, $reasons ) = @_;

    if($self->{'tolerant'}) {
        return $self->app->($env);
    }

    my $host;
    unless($host = $env->{'HTTP_HOST'}) {
        $host = $env->{'SERVER_NAME'};
        unless($env->{'SERVER_PORT'} == 80) {
            $host .= ':' . $env->{'SERVER_PORT'};
        }
    }
    my $path = $env->{'PATH_INFO'};

    my $content;

    if($env->{'REQUEST_METHOD'} eq 'GET') {
        $content = '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul>';

        my $from;

        if(@$reasons) {
            $from = $reasons->[0];
        } else {
            $from = $self->{'from'};
            $from = $from->[0] if ref $from;
        }

        if($from eq 'suffix') {
            foreach my $format (sort keys %{$self->{'mapping'}}) {
                my $type = $self->{'mapping'}{$format};
                $content .= "<li><a href='http://$host$path.$format'>$type</a></li>";
            }
        } elsif($from eq 'param') {
            my $param = $self->{'param'};

            foreach my $format (sort keys %{$self->{'mapping'}}) {
                my $type = $self->{'mapping'}{$format};
                $content .= "<li><a href='http://$host$path?$param=$format'>$type</a></li>";
            }
        }
        $content .= '</ul></body></html>';
    }
    return [
        406,
        ['Content-Type' => 'application/xhtml+xml'],
        [$content],
    ];
}

sub call {
    my ( $self, $env ) = @_;

    my $method = $env->{'REQUEST_METHOD'};
    if($method eq 'GET' || $method eq 'HEAD') {
        my ( $format, $reasons ) = $self->extract_format($env);

        if(@$format) {
            my $accept = $env->{'HTTP_ACCEPT'} || '';
            if((any { exists $self->{'mapping'}{$_} } @$format) || $self->acceptable($accept)) {
                @$format = grep { exists $self->{'mapping'}{$_} } @$format;
            } else {
                return $self->unacceptable($env, $reasons);
            }

            my @accept = split /\s*,\s*/, $accept;
            foreach my $f (@$format) {
                my $mapping = $self->{'mapping'}{$f};
                my $mapping_noparams = $mapping;
                $mapping_noparams =~ s/;.*$//;
                my ( $mapping_type ) = split /\//, $mapping;
                foreach my $accept (@accept) {
                    my $accept_noparams = $accept;
                    $accept_noparams =~ s/;.*$//;
                    if($accept_noparams eq $mapping_noparams) {
                        undef $accept;
                        last;
                    }
                    next unless defined($accept) && $accept =~ /\*/;
                    my ( $type ) = split /\//, $accept;

                    if($type eq '*' || $type eq $mapping_type) {
                        undef $accept;
                    }
                }
                push @accept, $mapping if defined $mapping;
            }
            $env->{'HTTP_ACCEPT'} = join(', ', grep { defined } @accept);
        } else {
            if(exists $env->{'HTTP_ACCEPT'}) {
                my $accept = $env->{'HTTP_ACCEPT'};
                unless($self->acceptable($accept)) {
                    return $self->unacceptable($env, $reasons);
                }
            } else {
                $env->{'HTTP_ACCEPT'} = '*/*'
            }
        }
    }
    return $self->app->($env);
}

1;



=pod

=head1 NAME

Plack::Middleware::SetAccept - Sets the Accept header based on the suffix or query params of a request

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Plack::Builder;

  my %map = (
    json => 'application/json',
    xml  => 'application/xml',
  );

  builder {
    enable 'SetAccept', from => 'suffix', mapping => \%map;
    $app;
  };
  # now /foo.json behaves as /foo, with Accept: application/json

  # or

  builder {
    enable 'SetAccept', from => 'param', param => 'format', mapping => \%map;
    $app;
  };
  # now /foo?format=xml behaves as /foo, with Accept: application/xml

  # or
  
  builder {
    enable 'SetAccept', from => ['suffix', 'param'], param => 'format', mapping => \%map;
    $app;
  };

=head1 DESCRIPTION

This middleware sets the Accept header by extracting a piece of the request
URI.  It can extract from either the suffix of the path (ex. /foo.json) or
from the query string (ex. /foo?format=json) for HEAD and GET requests.  The
value is looked up in a mapping table and is added to the Accept header.

=head1 PARAMETERS

=head2 from

Specifies from where the middleware is to extract the accept string.  Valid
values for this are 'suffix', 'param', or an array reference containing
either/both of those values.  The order in the array reference doesn't really
matter, except for when the middleware generates XHTML links on a 406 error.

=head2 param

Only required when using 'param' for from.  Specifies the query string
parameter that specifies the lookup value for the mapping table.

=head2 mapping

A hash table containing Accept mappings.  The keys should be the possible
values extracted from the URI, and the values should be the mime types
associated with the keys.

=head2 tolerant

If this option is falsy (defaults to 1), a 406 response code will be
generated for "unacceptable" values.  The body of the response will
contain an XHTML document with a list of alternative links.

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware>

=begin comment

=over

=item prepare_app

=item get_uri

=item extract_format

=item acceptable

=item unacceptable

=item call

=back

=end comment

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://github.com/hoelzro/plack-middleware-setaccept/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut


__END__

# ABSTRACT: Sets the Accept header based on the suffix or query params of a request

