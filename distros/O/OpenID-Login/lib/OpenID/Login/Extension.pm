package OpenID::Login::Extension;
{
  $OpenID::Login::Extension::VERSION = '0.1.2';
}

# ABSTRACT: Storage and methods for OpenId extensions, both requesting information and receiving data.

use Moose 0.51;


has ns => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);


has uri => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);


has attributes => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
    trigger  => \&_flatten_attributes,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args;
    if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
        $args = $_[0];
    } else {
        $args = {@_};
    }
    if ( $args->{cgi} or $args->{cgi_params} ) {
        my $new_args;
        if ( $args->{uri} ) {
            $new_args = _extract_attributes_by_uri($args);
        } elsif ( $args->{ns} ) {
            $new_args = _extract_attributes_by_ns($args);
        } else {
            die 'Unable to determine extension details';
        }
        return $class->$orig($new_args);
    } else {
        return $class->$orig(@_);
    }
};

sub _extract_attributes_by_uri {
    my $args = shift;

    my $cgi        = $args->{cgi};
    my $cgi_params = $args->{cgi_params};
    my $uri        = $args->{uri};

    my @openid_params = grep {/^openid\./} $cgi ? $cgi->param() : keys %$cgi_params;
    ( my $ns_param ) = grep { ( $cgi ? $cgi->param($_) : $cgi_params->{$_} ) eq $uri } grep {/^openid\.ns\./} @openid_params;
    if ($ns_param) {
        $args->{ns} = substr( $ns_param, 10 );
        return _extract_attributes_by_ns($args);
    }

    return $args;
}

sub _extract_attributes_by_ns {
    my $args = shift;

    my $cgi        = $args->{cgi};
    my $cgi_params = $args->{cgi_params};
    my $ns         = $args->{ns};

    $args->{uri} ||= $cgi ? $cgi->param("openid.ns.$ns") : $cgi_params->{"openid.ns.$ns"};

    my $prefix     = "openid.$ns.";
    my $prefix_len = length($prefix);
    my %attributes;
    if ($cgi) {
        my %signed_params = map { ( "openid.$_" => 1 ) } split /,/, $cgi->param('openid.signed');
        %attributes = ( map { substr( $_, $prefix_len ) => scalar $cgi->param($_) } grep { /^\Q$prefix\E/ and $signed_params{$_} } $cgi->param() );
    } else {
        my %signed_params = map { ( "openid.$_" => 1 ) } split /,/, $cgi_params->{'openid.signed'};
        %attributes = ( map { substr( $_, $prefix_len ) => $cgi_params->{$_} } grep { /^\Q$prefix\E/ and $signed_params{$_} } keys %$cgi_params );
    }
    $args->{attributes} = \%attributes;

    return $args;
}


sub get_parameter_string {
    my $self = shift;
    my $ns   = $self->ns;

    my $params = sprintf 'openid.ns.%s=%s', $ns, $self->uri;

    my $attributes = $self->attributes;
    $params .= _parameterise_hash( "openid.$ns", $attributes );

    return $params;
}

sub _parameterise_hash {
    my $prefix = shift;
    my $hash   = shift;

    my $params = '';
    $params .= sprintf '&%s.%s=%s', $prefix, $_, $hash->{$_} foreach ( sort keys %$hash );
    return $params;
}


sub get_parameter {
    my $self  = shift;
    my $param = shift;

    die "$param is not an available parameter" unless exists $self->attributes->{$param};
    return $self->attributes->{$param};
}


sub set_parameter {
    my $self   = shift;
    my %params = @_;

    _flatten_hash( \%params );

    $self->attributes->{$_} = $params{$_} foreach keys %params;
}

sub _flatten_attributes {
    my $self       = shift;
    my $attributes = shift;

    _flatten_hash($attributes);
}

sub _flatten_hash {
    my $hash = shift;

    foreach my $key ( keys %$hash ) {
        my $value = $hash->{$key};
        if ( ref $value eq 'HASH' ) {
            _flatten_hash($value);
            $hash->{"$key.$_"} = $value->{$_} foreach keys %$value;
            delete $hash->{$key};
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

OpenID::Login::Extension - Storage and methods for OpenId extensions, both requesting information and receiving data.

=head1 VERSION

version 0.1.2

=head1 ATTRIBUTES

=head2 ns

The namespace to use for this extension (eg 'ax' is the one usually used in documentation about attribute exchange).

=head2 uri

The type URI for the extension (eg attribute exchange has L<http://openid.net/srv/ax/1.0>).

=head2 attributes

The attributes for the extension (everything under openid.[ns].*), stored as a hashref. Internally this
is flattened to a single hashref, but a tree structure can be passed in, and intermediate keys will be
linked together with '.'.

=head1 METHODS

=head2 get_parameter_string

Collect the internal attributes, and create a single string representing the query of this extension object,
usable for an OpenID request.

=head2 get_parameter

Get a single extension parameter, this is most likely to be used for extensions that are
the result of a request (rather than when creating a request).

=head2 set_parameter

Set an extension parameter (or several parameters). Nested parameters are allowed, i.e.

C<< $extension->set_parameter(type => {firstname => 'q1', lastname => 'q2'}); >>

is equivalent to:

C<< $extension->set_parameter('type.firstname' => 'q1', 'type.lastname' => 'q2'); >>

and neither approach will clear any other C<type.*> values that may already be set.

=head1 AUTHOR

Holger Eiboeck <realholgi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Holger Eiboeck.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


