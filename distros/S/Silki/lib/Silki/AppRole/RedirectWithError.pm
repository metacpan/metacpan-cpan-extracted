package Silki::AppRole::RedirectWithError;
{
  $Silki::AppRole::RedirectWithError::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use HTTP::Status qw( RC_OK );
use JSON::XS;
use Scalar::Util qw( blessed );
use Silki::Types qw( ErrorForSession URIStr HashRef Bool Str );

use Moose::Role;
use MooseX::Params::Validate qw( validated_hash );

# These are not available yet?
#requires qw( redirect_and_detach session_object );

my $JSON = JSON::XS->new();
$JSON->pretty(1);
$JSON->utf8(1);

my %spec = (
    uri        => { isa => URIStr,          coerce   => 1 },
    error      => { isa => ErrorForSession, optional => 1 },
    form_data  => { isa => HashRef,         optional => 1 },
    force_json => { isa => Bool,            default  => 0 },
    json_content_type => { isa => Str, default => 'application/json' },
);

sub redirect_with_error {
    my $self = shift;
    my %p = validated_hash( \@_, %spec );

    die "Must provide a form or error" unless $p{error} || $p{form};

    $self->session_object()->add_error( $p{error} )
        if $p{error};
    $self->session_object()->set_form_data( $p{form_data} )
        if $p{form_data};

    if ( $self->request()->looks_like_browser() && !$p{force_json} ) {
        $self->redirect_and_detach( $p{uri} );
    }
    else {
        my $uri = $self->uri_with_sessionid( $p{uri} );

        $self->response()->status(RC_OK);
        $self->response()->content_type( $p{json_content_type} );

        # The URI could be a URI object, in which case we need to stringify it
        # for JSON::XS.
        $self->response()->body( $JSON->encode( { uri => $uri . q{} } ) );
        $self->detach();
    }
}

1;

# ABSTRACT: Adds $c->redirect_with_error() to the Catalyst object

__END__
=pod

=head1 NAME

Silki::AppRole::RedirectWithError - Adds $c->redirect_with_error() to the Catalyst object

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

