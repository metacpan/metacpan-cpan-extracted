# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package OpenSearch::Client::Role::Client::Direct;
$OpenSearch::Client::Role::Client::Direct::VERSION = '3.007009';
use Moo::Role;
with 'OpenSearch::Client::Role::Client';
use OpenSearch::Client::Util qw(load_plugin is_compat throw);

use Try::Tiny;
use Package::Stash 0.34 ();
use Any::URI::Escape qw(uri_escape);
use namespace::clean;

#===================================
sub parse_request {
#===================================
    my $self   = shift;
    my $defn   = shift || {};
    my $params = { ref $_[0] ? %{ shift() } : @_ };

    my $request;
    try {
        $request = {
            ignore    => delete $params->{ignore} || [],
            method    => $self->_parse_method ( $defn, $params ),
            serialize => $defn->{serialize}       || 'std',
            path => $self->_parse_path( $defn,         $params ),
            body => $self->_parse_body( $defn->{body}, $params ),
            qs   => $self->_parse_qs( $defn->{qs},     $params ),
        };
    }
    catch {
        chomp $_;
        my $name = $defn->{name} || '<unknown method>';
        $self->logger->throw_error( 'Param', "$_ in ($name) request. " );
    };
    return $request;
}

#===================================
sub _parse_method {
#===================================
    my ( $self, $defn, $params ) = @_;
    
    my $method = $defn->{method} || 'GET';
    return $method unless( $method eq 'detect' );
    my $dp = $defn->{detect};
    $method = $dp->{method};
    
    return $method unless(defined($params) && ref($params) eq 'HASH');
    
    ## is there a body param
    if ( $dp->{check}->{body} ) {
        return $dp->{alternate} if(exists($params->{body}) && defined($params->{body}));
    }
    
    ## are there any optional params
    if ( $dp->{check}->{paths}
        && exists($defn->{parts})
        && defined($defn->{parts})
        && ref($defn->{parts}) eq 'HASH'
        ) {
        
        my @pathparts = keys %{ $defn->{parts} };
        
        for my $pathpart ( @pathparts ) {
            next if $defn->{parts}->{$pathpart}->{required};
            return $dp->{alternate} if(exists($params->{$pathpart}) && defined($params->{$pathpart}));
        }
    }
    
    return $method;

}


#===================================
sub _parse_path {
#===================================
    my ( $self, $defn, $params ) = @_;
    return delete $params->{path}
        if $params->{path};
    my $paths = $defn->{paths};
    my $parts = $defn->{parts};

    my %args;
    keys %$parts;
    no warnings 'uninitialized';
    while ( my ( $key, $req ) = each %$parts ) {
        my $val = delete $params->{$key};
        if ( ref $val eq 'ARRAY' ) {
            die "Param ($key) must contain a single value\n"
                if @$val > 1 and not $req->{multi};
            $val = join ",", @$val;
        }
        if ( !length $val ) {
            die "Missing required param ($key)\n"
                if $req->{required};
            next;
        }
        utf8::encode($val);
        $args{$key} = uri_escape($val);
    }
PATH: for my $path (@$paths) {
        my @keys = keys %{ $path->[0] };
        next PATH unless @keys == keys %args;
        for (@keys) {
            next PATH unless exists $args{$_};
        }
        my ( $pos, @parts ) = @$path;
        for ( keys %$pos ) {
            $parts[ $pos->{$_} ] = $args{$_};
        }
        return join "/", '', @parts;
    }

    throw(
        'Internal',
        "Couldn't determine path",
        { params => $params, defn => $defn }
    );
}

#===================================
sub _parse_body {
#===================================
    my ( $self, $defn, $params ) = @_;
    if ( defined $defn ) {
        die("Missing required param (body)\n")
            if $defn->{required} && !$params->{body};
        return delete $params->{body};
    }
    die("Unknown param (body)\n") if $params->{body};
    return undef;
}

#===================================
sub _parse_qs {
#===================================
    my ( $self, $handlers, $params ) = @_;
    die "No (qs) defined\n" unless $handlers;
    my %qs;

    if ( my $raw = delete $params->{params} ) {
        die("Arg (params) shoud be a hashref\n")
            unless ref $raw eq 'HASH';
        %qs = %$raw;
    }

    for my $key ( keys %$params ) {
        my $handler = $handlers->{$key}
            or die("Unknown param ($key)\n");
        $qs{$key} = $handler->( delete $params->{$key} );
    }
    return \%qs;
}

#===================================
sub _install_api {
#===================================
    my ( $class, $group ) = @_;
    my $defns = $class->api;
    my $stash = Package::Stash->new($class);
    
    my $_os_version_stash = {};
    
    my $group_qr = $group ? qr/$group\./ : qr//;
    for my $action ( keys %$defns ) {
        my ($name) = ( $action =~ /^$group_qr([^.]+)$/ )
            or next;
        next if $stash->has_symbol( '&' . $name );

        my %defn = ( name => $name, %{ $defns->{$action} } );
        if (exists($defn{os_version})) {
            $_os_version_stash->{$name} = $defn{os_version} || '1.000000';
        } else {
            $_os_version_stash->{$name} = '1.000000';
        }
        
        $stash->add_symbol(
            '&' . $name => sub {
                shift->perform_request( \%defn, @_ );
            }
        );
    }
    
    $stash->add_symbol( '%_api_method_supported_version_stash' => $_os_version_stash );
}

#===================================
sub _build_namespace {
#===================================
    my ( $self, $ns ) = @_;
    my $class = load_plugin( $self->_namespace, [$ns] );
    return $class->new(
        {   transport => $self->transport,
            logger    => $self->logger
        }
    );
}

#===================================
sub _build_helper {
#===================================
    my ( $self, $name, $sub_class ) = @_;
    my $class = load_plugin( 'OpenSearch::Client', $sub_class );
    is_compat( $name . '_helper_class', $self->transport, $class );
    return $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Role::Client::Direct - Request parsing for Direct clients

=head1 VERSION

version 3.007009

=head1 DESCRIPTION

This role provides the single C<parse_request()> method for classes
which need to parse an API definition from L<OpenSearch::Client::Role::API>
and convert it into a request which can be passed to
L<OpenSearch::Client::Transport/perform_request()>.

=head1 METHODS

=head2 C<perform_request()>

    $request = $client->parse_request(\%defn,\%params);

The C<%defn> is a definition returned by L<OpenSearch::Client::Role::API/api()>
with an extra key C<name> which should be the name of the method that
was called on the client.  For instance if the user calls C<< $client->search >>,
then the C<name> should be C<"search">.

C<parse_request()> will turn the parameters that have been passed in into
a C<path> (via L<OpenSearch::Client::Util::API::Path/path_init()>), a query-string
hash (via L<OpenSearch::Client::Util::API::QS/qs_init>) and will pass through a
C<body> value directly.

B<NOTE:> If a C<path> key is specified in the C<%params> then it will be used
directly, instead of trying to build path from the path template.  Similarly,
if a C<params> key is specified in the C<%params>, then it will be used
as a basis for the query string hash.  For instance:

    $client->perform_request(
        {
            method => 'GET',
            name   => 'new_method'
        },
        {
            path   => '/new/method',
            params => { foo => 'bar' },
            body   => \%body
        }
    );

This makes it easy to add support for custom plugins or new functionality
not yet supported by the released client.

=head1 MANUAL

Documentation index L<OpenSearch::Client::Manual>

=head1 HISTORY

This distribution is derived from L<Search::Elasticsearch> version 7.714.
All subsequent changes are unique to this distribution.

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt> ( current maintainer )

=head1 CREDITS

L<OpenSearch::Client> is based on L<Search::Elasticsearch> version 7.714
by Enrico Zimuel E<lt>enrico.zimuel@elastic.coE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson ( this distribution )

Copyright (C) 2021 by Elasticsearch BV ( original distribution ) 

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

